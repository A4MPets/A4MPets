import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/trip_navigation_support.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const Distance distanceCalculator = Distance();

  test('consumeReachedWaypoints removes reached waypoints in order', () {
    final WaypointProgressResult result =
        TripWaypointProgressor.consumeReachedWaypoints(
          currentLocation: const LatLng(3.4516, -76.5320),
          currentWaypoints: const <LatLng>[
            LatLng(3.4516, -76.5320),
            LatLng(3.45161, -76.53201),
            LatLng(3.4600, -76.5400),
          ],
          waypointArrivalMeters: 25,
          distanceCalculator: distanceCalculator,
        );

    expect(result.removedWaypoints, 2);
    expect(result.remainingWaypoints, hasLength(1));
    expect(result.reachedDestination, isFalse);
  });

  test('trip reroute controller stores queued reroutes while in flight', () {
    final TripRerouteController controller = TripRerouteController(
      distanceCalculator: distanceCalculator,
      minDistanceMeters: 20,
      minInterval: const Duration(seconds: 5),
    );
    const LatLng currentLocation = LatLng(3.4516, -76.5320);
    const List<LatLng> nextWaypoints = <LatLng>[
      LatLng(3.4600, -76.5400),
      LatLng(3.4700, -76.5500),
    ];

    expect(
      controller.shouldTrigger(location: currentLocation, force: false),
      isTrue,
    );

    controller.markStarted(currentLocation);
    controller.queue(location: currentLocation, waypoints: nextWaypoints);

    final QueuedTripReroute? queued = controller.completeAndTakeQueued();

    expect(controller.isInFlight, isFalse);
    expect(queued, isNotNull);
    expect(queued!.waypoints, nextWaypoints);
    expect(queued.location, currentLocation);
  });
}
