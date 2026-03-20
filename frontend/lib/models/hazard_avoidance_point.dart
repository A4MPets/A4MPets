import 'package:latlong2/latlong.dart';

/// Representa un punto auxiliar para evasión de peligros
class HazardAvoidancePoint {
  final LatLng point;
  final String direction; // 'N', 'S', 'E', 'O'
  final double hazardId;
  final double distanceFromHazard;

  const HazardAvoidancePoint({
    required this.point,
    required this.direction,
    required this.hazardId,
    required this.distanceFromHazard,
  });
}
