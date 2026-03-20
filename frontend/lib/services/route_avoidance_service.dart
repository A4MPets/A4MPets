import 'package:latlong2/latlong.dart';
import 'dart:math';

import '../models/hazard_avoidance_point.dart';
import '../models/hazard_report_record.dart';
import 'route_hazard_visualizer_service.dart';

class RouteAvoidanceService {
  static const double _earthRadiusInMeters = 6371000;

  /// Calcula puntos auxiliares (N, S, E, O) alrededor de un peligro
  static List<HazardAvoidancePoint> calculateAvoidancePoints({
    required LatLng hazardCenter,
    required double hazardRadiusMeters,
    required double hazardId,
  }) {
    final double avoidanceDistanceMeters = hazardRadiusMeters * 1.25;
    final List<HazardAvoidancePoint> points = <HazardAvoidancePoint>[];

    // Norte (N): latitud +
    final LatLng north = _movePoint(
      origin: hazardCenter,
      distanceMeters: avoidanceDistanceMeters,
      bearing: 0.0, // norte
    );
    points.add(
      HazardAvoidancePoint(
        point: north,
        direction: 'N',
        hazardId: hazardId,
        distanceFromHazard: avoidanceDistanceMeters,
      ),
    );

    // Sur (S): latitud -
    final LatLng south = _movePoint(
      origin: hazardCenter,
      distanceMeters: avoidanceDistanceMeters,
      bearing: 180.0, // sur
    );
    points.add(
      HazardAvoidancePoint(
        point: south,
        direction: 'S',
        hazardId: hazardId,
        distanceFromHazard: avoidanceDistanceMeters,
      ),
    );

    // Este (E): longitud +
    final LatLng east = _movePoint(
      origin: hazardCenter,
      distanceMeters: avoidanceDistanceMeters,
      bearing: 90.0, // este
    );
    points.add(
      HazardAvoidancePoint(
        point: east,
        direction: 'E',
        hazardId: hazardId,
        distanceFromHazard: avoidanceDistanceMeters,
      ),
    );

    // Oeste (O): longitud -
    final LatLng west = _movePoint(
      origin: hazardCenter,
      distanceMeters: avoidanceDistanceMeters,
      bearing: 270.0, // oeste
    );
    points.add(
      HazardAvoidancePoint(
        point: west,
        direction: 'O',
        hazardId: hazardId,
        distanceFromHazard: avoidanceDistanceMeters,
      ),
    );

    return points;
  }

  /// Mueve un punto desde un origen a una distancia y bearing dados
  /// bearing: 0=N, 90=E, 180=S, 270=O
  static LatLng _movePoint({
    required LatLng origin,
    required double distanceMeters,
    required double bearing,
  }) {
    final double lat1Rad = _toRadians(origin.latitude);
    final double lon1Rad = _toRadians(origin.longitude);
    final double bearingRad = _toRadians(bearing);
    final double angularDistance = distanceMeters / _earthRadiusInMeters;

    final double lat2Rad = asin(
      sin(lat1Rad) * cos(angularDistance) +
          cos(lat1Rad) * sin(angularDistance) * cos(bearingRad),
    );

    final double lon2Rad = lon1Rad +
        atan2(
          sin(bearingRad) * sin(angularDistance) * cos(lat1Rad),
          cos(angularDistance) - sin(lat1Rad) * sin(lat2Rad),
        );

    return LatLng(
      _toDegrees(lat2Rad),
      _toDegrees(lon2Rad),
    );
  }

  static double _toRadians(double degrees) => degrees * (3.141592653589793 / 180);
  static double _toDegrees(double radians) => radians * (180 / 3.141592653589793);

  /// Obtiene los peligros que interceptan la ruta actual
  static List<HazardReportRecord> getInterceptingHazards({
    required List<LatLng> routePolyline,
    required List<HazardReportRecord> allHazards,
  }) {
    final List<HazardReportRecord> intercepting = <HazardReportRecord>[];

    for (final HazardReportRecord hazard in allHazards) {
      final LatLng hazardPoint = LatLng(
        hazard.incidentLatitude.toDouble(),
        hazard.incidentLongitude.toDouble(),
      );
      final double hazardRadiusMeters = hazard.impactRadiusMeters.toDouble();

      // Verificar si algún segmento de la ruta intercepta este peligro
      for (int i = 0; i < routePolyline.length - 1; i++) {
        final LatLng start = routePolyline[i];
        final LatLng end = routePolyline[i + 1];

        final double distanceToSegment =
            RouteHazardVisualizerService.distancePointToLineSegment(
          point: hazardPoint,
          lineStart: start,
          lineEnd: end,
        );

        if (distanceToSegment <= hazardRadiusMeters) {
          intercepting.add(hazard);
          break; // No agregar duplicados
        }
      }
    }

    return intercepting;
  }

  /// Calcula la distancia total de una ruta
  static double calculateRouteDistance(List<LatLng> polyline) {
    if (polyline.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < polyline.length - 1; i++) {
      final LatLng start = polyline[i];
      final LatLng end = polyline[i + 1];
      totalDistance += _haversineDistance(start, end);
    }
    return totalDistance;
  }

  /// Distancia Haversine entre dos puntos en metros
  static double _haversineDistance(LatLng start, LatLng end) {
    final double lat1Rad = _toRadians(start.latitude);
    final double lat2Rad = _toRadians(end.latitude);
    final double deltaLat = _toRadians(end.latitude - start.latitude);
    final double deltaLon = _toRadians(end.longitude - start.longitude);

    final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusInMeters * c;
  }
}
