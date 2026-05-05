import 'package:latlong2/latlong.dart';
import '../models/colored_route_segment.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import 'package:flutter/material.dart';
import 'hazard_risk_filtering.dart';

/// Servicio para analizar rutas y marcar segmentos peligrosos
/// Solo pinta, sin modificar la ruta
class RouteHazardVisualizerService {
  static const Color _safeColor = Color(0xFF4A90E2); // Azul - seguro
  static const Color _hazardColor = Color(0xFFE74C3C); // Rojo - peligroso

  /// Verifica qué partes de una ruta intersectan con hazards
  /// Retorna segmentos coloreados de la ruta
  ///
  /// La polilinea se divide en pequeños segmentos, cada uno se verifica
  /// si está dentro del radio de algún hazard
  static List<ColoredRouteSegment> analyzeRouteHazards({
    required List<LatLng> routePolyline,
    List<LatLng> routeWaypoints = const <LatLng>[],
    List<Color> segmentColors = const <Color>[Color(0xFF4A90E2)],
    required List<HazardReportRecord> hazards,
    List<GenericReportRecord> genericReports = const <GenericReportRecord>[],
    List<String> hazardRiskFilters = HazardRiskFiltering.allRoutingFilters,
  }) {
    final Set<String> selectedRiskFilters =
        HazardRiskFiltering.normalizeSelectedFilters(hazardRiskFilters);
    final List<_RouteAvoidanceZone> avoidanceZones = <_RouteAvoidanceZone>[
      ...hazards
          .where((HazardReportRecord hazard) {
            return HazardRiskFiltering.shouldConsiderRisk(
              riskLevelCode: hazard.riskLevelCode,
              selectedFilters: selectedRiskFilters,
            );
          })
          .map(
            (HazardReportRecord hazard) => _RouteAvoidanceZone(
              latitude: hazard.incidentLatitude,
              longitude: hazard.incidentLongitude,
              radiusMeters: hazard.impactRadiusMeters.toDouble(),
            ),
          ),
      ...genericReports
          .where((GenericReportRecord report) {
            return report.impactRadiusMeters > 0 &&
                HazardRiskFiltering.shouldConsiderOtherReports(
                  selectedFilters: selectedRiskFilters,
                );
          })
          .map(
            (GenericReportRecord report) => _RouteAvoidanceZone(
              latitude: report.latitude,
              longitude: report.longitude,
              radiusMeters: report.impactRadiusMeters.toDouble(),
            ),
          ),
    ];

    if (routePolyline.length < 2) {
      return <ColoredRouteSegment>[];
    }

    final List<ColoredRouteSegment> segments = [];
    final List<Color> resolvedSegmentColors = segmentColors.isEmpty
        ? <Color>[_safeColor]
        : segmentColors;
    final List<int> waypointBreakIndices = _resolveWaypointBreakIndices(
      routePolyline: routePolyline,
      routeWaypoints: routeWaypoints,
    );

    // Iteramos sobre cada par de puntos consecutivos en la polilinea
    for (int i = 0; i < routePolyline.length - 1; i++) {
      final LatLng start = routePolyline[i];
      final LatLng end = routePolyline[i + 1];
      final int legIndex = _resolveLegIndex(
        polylineIndex: i,
        waypointBreakIndices: waypointBreakIndices,
      );
      final Color legColor =
          resolvedSegmentColors[legIndex % resolvedSegmentColors.length];

      final bool segmentHasHazard = _segmentIntersectsHazard(
        start: start,
        end: end,
        avoidanceZones: avoidanceZones,
      );

      segments.add(
        ColoredRouteSegment(
          points: [start, end],
          color: segmentHasHazard ? _hazardColor : legColor,
          hasHazard: segmentHasHazard,
        ),
      );
    }

    return segments;
  }

  static List<int> _resolveWaypointBreakIndices({
    required List<LatLng> routePolyline,
    required List<LatLng> routeWaypoints,
  }) {
    if (routeWaypoints.length < 2) {
      return <int>[0, routePolyline.length - 1];
    }

    final Distance distanceCalculator = const Distance();
    final List<int> breakIndices = <int>[0];
    int searchStartIndex = 0;

    for (
      int waypointIndex = 1;
      waypointIndex < routeWaypoints.length - 1;
      waypointIndex++
    ) {
      final LatLng waypoint = routeWaypoints[waypointIndex];
      int bestPolylineIndex = searchStartIndex;
      double bestDistance = double.infinity;

      for (
        int polylineIndex = searchStartIndex;
        polylineIndex < routePolyline.length;
        polylineIndex++
      ) {
        final double candidateDistance = distanceCalculator.distance(
          waypoint,
          routePolyline[polylineIndex],
        );
        if (candidateDistance < bestDistance) {
          bestDistance = candidateDistance;
          bestPolylineIndex = polylineIndex;
        }
      }

      breakIndices.add(bestPolylineIndex);
      searchStartIndex = bestPolylineIndex;
    }

    breakIndices.add(routePolyline.length - 1);
    return breakIndices;
  }

  static int _resolveLegIndex({
    required int polylineIndex,
    required List<int> waypointBreakIndices,
  }) {
    if (waypointBreakIndices.length < 2) {
      return 0;
    }

    for (
      int legIndex = 0;
      legIndex < waypointBreakIndices.length - 1;
      legIndex++
    ) {
      final int start = waypointBreakIndices[legIndex];
      final int end = waypointBreakIndices[legIndex + 1];
      if (polylineIndex >= start && polylineIndex < end) {
        return legIndex;
      }
    }

    return waypointBreakIndices.length - 2;
  }

  /// Verifica si un segmento de línea (start-end) intersecta con algún hazard
  static bool _segmentIntersectsHazard({
    required LatLng start,
    required LatLng end,
    required List<_RouteAvoidanceZone> avoidanceZones,
  }) {
    for (final _RouteAvoidanceZone zone in avoidanceZones) {
      final LatLng hazardPoint = LatLng(zone.latitude, zone.longitude);

      // Calcular distancia del hazard al segmento de línea
      final double distanceToSegment = _distancePointToLineSegment(
        point: hazardPoint,
        lineStart: start,
        lineEnd: end,
      );

      // Si la distancia es menor que el radio del hazard, intersecta
      if (distanceToSegment <= zone.radiusMeters) {
        return true;
      }
    }
    return false;
  }

  /// Calcula la distancia mínima entre un punto y un segmento de línea
  /// Usando la fórmula de distancia de punto a línea
  static double _distancePointToLineSegment({
    required LatLng point,
    required LatLng lineStart,
    required LatLng lineEnd,
  }) {
    // Distancias Haversine a los extremos
    const Distance distanceCalculator = Distance();

    final double distToStart = distanceCalculator.as(
      LengthUnit.Meter,
      point,
      lineStart,
    );

    final double distToEnd = distanceCalculator.as(
      LengthUnit.Meter,
      point,
      lineEnd,
    );

    // Proyección del punto en la línea
    // Si la proyección cae fuera del segmento, usa la distancia a los endpoints
    final double dx = lineEnd.longitude - lineStart.longitude;
    final double dy = lineEnd.latitude - lineStart.latitude;

    if (dx == 0 && dy == 0) {
      return distToStart;
    }

    // Parámetro t representa la posición del punto proyectado en la línea
    // t=0 es el inicio, t=1 es el final, 0<t<1 significa dentro del segmento
    final double t =
        ((point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy) /
        (dx * dx + dy * dy);

    if (t < 0) {
      // Proyección está antes del inicio
      return distToStart;
    } else if (t > 1) {
      // Proyección está después del final
      return distToEnd;
    } else {
      // Proyección está dentro del segmento
      final LatLng projection = LatLng(
        lineStart.latitude + t * (lineEnd.latitude - lineStart.latitude),
        lineStart.longitude + t * (lineEnd.longitude - lineStart.longitude),
      );

      return distanceCalculator.as(LengthUnit.Meter, point, projection);
    }
  }
}

class _RouteAvoidanceZone {
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const _RouteAvoidanceZone({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });
}
