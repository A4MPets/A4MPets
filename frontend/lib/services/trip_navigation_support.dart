import 'package:latlong2/latlong.dart';

class WaypointProgressResult {
  const WaypointProgressResult({
    required this.remainingWaypoints,
    required this.removedWaypoints,
  });

  final List<LatLng> remainingWaypoints;
  final int removedWaypoints;

  bool get hasChanges => removedWaypoints > 0;
  bool get reachedDestination => remainingWaypoints.isEmpty;
}

class TripWaypointProgressor {
  const TripWaypointProgressor._();

  static WaypointProgressResult consumeReachedWaypoints({
    required LatLng currentLocation,
    required List<LatLng> currentWaypoints,
    required double waypointArrivalMeters,
    required Distance distanceCalculator,
  }) {
    final List<LatLng> nextRemaining = List<LatLng>.from(currentWaypoints);
    int removed = 0;

    while (nextRemaining.isNotEmpty) {
      final double distanceToNext = distanceCalculator.distance(
        currentLocation,
        nextRemaining.first,
      );

      if (distanceToNext > waypointArrivalMeters) {
        break;
      }

      nextRemaining.removeAt(0);
      removed += 1;
    }

    return WaypointProgressResult(
      remainingWaypoints: nextRemaining,
      removedWaypoints: removed,
    );
  }
}

class QueuedTripReroute {
  const QueuedTripReroute({required this.location, required this.waypoints});

  final LatLng location;
  final List<LatLng> waypoints;
}

class TripRerouteController {
  TripRerouteController({
    required Distance distanceCalculator,
    required double minDistanceMeters,
    required Duration minInterval,
  }) : _distanceCalculator = distanceCalculator,
       _minDistanceMeters = minDistanceMeters,
       _minInterval = minInterval;

  final Distance _distanceCalculator;
  final double _minDistanceMeters;
  final Duration _minInterval;

  LatLng? _lastRerouteLocation;
  DateTime? _lastRerouteAt;
  bool _inFlight = false;
  LatLng? _queuedLocation;
  List<LatLng>? _queuedWaypoints;

  bool get isInFlight => _inFlight;

  void reset() {
    _lastRerouteLocation = null;
    _lastRerouteAt = null;
    _inFlight = false;
    _queuedLocation = null;
    _queuedWaypoints = null;
  }

  bool shouldTrigger({required LatLng location, required bool force}) {
    if (force || _lastRerouteLocation == null || _lastRerouteAt == null) {
      return true;
    }

    final double movedMeters = _distanceCalculator.distance(
      location,
      _lastRerouteLocation!,
    );
    final Duration elapsed = DateTime.now().difference(_lastRerouteAt!);

    return movedMeters >= _minDistanceMeters || elapsed >= _minInterval;
  }

  void queue({required LatLng location, required List<LatLng> waypoints}) {
    _queuedLocation = location;
    _queuedWaypoints = List<LatLng>.from(waypoints);
  }

  void markStarted(LatLng location) {
    _inFlight = true;
    _lastRerouteLocation = location;
    _lastRerouteAt = DateTime.now();
  }

  QueuedTripReroute? completeAndTakeQueued() {
    _inFlight = false;

    final LatLng? location = _queuedLocation;
    final List<LatLng>? waypoints = _queuedWaypoints;
    _queuedLocation = null;
    _queuedWaypoints = null;

    if (location == null || waypoints == null || waypoints.isEmpty) {
      return null;
    }

    return QueuedTripReroute(location: location, waypoints: waypoints);
  }
}
