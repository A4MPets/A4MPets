import 'package:latlong2/latlong.dart';
import '../models/hazard_report_record.dart';
import '../models/colored_route_segment.dart';
import 'package:flutter/material.dart';

/// Servicio para analizar rutas y marcar segmentos peligrosos
/// Solo pinta, sin modificar la ruta
class RouteHazardVisualizerService {
  static const Color _safeColor = Color(0xFF4A90E2);     // Azul - seguro
  static const Color _hazardColor = Color(0xFFE74C3C);   // Rojo - peligroso

  /// Verifica qué partes de una ruta intersectan con hazards
  /// Retorna segmentos coloreados de la ruta
  ///
  /// La polilinea se divide en pequeños segmentos, cada uno se verifica
  /// si está dentro del radio de algún hazard
  static List<ColoredRouteSegment> analyzeRouteHazards({
    required List<LatLng> routePolyline,
    required List<HazardReportRecord> hazards,
  }) {
    if (routePolyline.length < 2 || hazards.isEmpty) {
      // Sin hazards o ruta muy corta, retorna como seguro
      return [
        ColoredRouteSegment(
          points: routePolyline,
          color: _safeColor,
          hasHazard: false,
        ),
      ];
    }

    final List<ColoredRouteSegment> segments = [];
    
    // Iteramos sobre cada par de puntos consecutivos en la polilinea
    for (int i = 0; i < routePolyline.length - 1; i++) {
      final LatLng start = routePolyline[i];
      final LatLng end = routePolyline[i + 1];
      
      final bool segmentHasHazard = _segmentIntersectsHazard(
        start: start,
        end: end,
        hazards: hazards,
      );

      segments.add(
        ColoredRouteSegment(
          points: [start, end],
          color: segmentHasHazard ? _hazardColor : _safeColor,
          hasHazard: segmentHasHazard,
        ),
      );
    }

    return segments;
  }

  /// Verifica si un segmento de línea (start-end) intersecta con algún hazard
  static bool _segmentIntersectsHazard({
    required LatLng start,
    required LatLng end,
    required List<HazardReportRecord> hazards,
  }) {
    for (final HazardReportRecord hazard in hazards) {
      final LatLng hazardPoint = LatLng(
        hazard.incidentLatitude,
        hazard.incidentLongitude,
      );

      // Calcular distancia del hazard al segmento de línea
      final double distanceToSegment = _distancePointToLineSegment(
        point: hazardPoint,
        lineStart: start,
        lineEnd: end,
      );

      // Si la distancia es menor que el radio del hazard, intersecta
      if (distanceToSegment <= hazard.impactRadiusMeters) {
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
    final double t = ((point.longitude - lineStart.longitude) * dx +
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

      return distanceCalculator.as(
        LengthUnit.Meter,
        point,
        projection,
      );
    }
  }
}
