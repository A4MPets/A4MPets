import 'package:latlong2/latlong.dart';

import 'route_navigation_instruction.dart';

class PlannedRouteResult {
  const PlannedRouteResult({
    required this.polyline,
    required this.navigationInstructions,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.profile,
    required this.hazardsConsidered,
  });

  final List<LatLng> polyline;
  final List<RouteNavigationInstruction> navigationInstructions;
  final double distanceMeters;
  final double durationSeconds;
  final String profile;
  final int hazardsConsidered;
}
