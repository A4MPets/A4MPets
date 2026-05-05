import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/route_navigation_instruction.dart';

enum NavigationAudioCueType { farApproach, approach, immediate }

class NavigationAudioCue {
  const NavigationAudioCue({
    required this.instruction,
    required this.type,
    required this.distanceMeters,
    required this.maneuverKey,
  });

  final RouteNavigationInstruction instruction;
  final NavigationAudioCueType type;
  final double distanceMeters;
  final String maneuverKey;
}

class NavigationAudioProgress {
  const NavigationAudioProgress._();

  static const double farApproachThresholdMeters = 100;
  static const double approachThresholdMeters = 30;
  static const double immediateThresholdMeters = 8;
  static const double offRouteToleranceMeters = 24;
  static const double passedManeuverToleranceMeters = 10;

  static NavigationAudioCue? nextCue({
    required LatLng currentLocation,
    required List<LatLng> polyline,
    required List<RouteNavigationInstruction> instructions,
    required Set<String> spokenFarApproachKeys,
    required Set<String> spokenApproachKeys,
    required Set<String> spokenImmediateKeys,
    required Distance distanceCalculator,
  }) {
    if (polyline.length < 2) {
      return null;
    }

    final List<double> cumulativeDistances = _cumulativeRouteDistances(
      polyline: polyline,
      distanceCalculator: distanceCalculator,
    );
    final _RouteMatch userRouteMatch = _matchLocationToRoute(
      currentLocation: currentLocation,
      polyline: polyline,
      cumulativeDistances: cumulativeDistances,
      distanceCalculator: distanceCalculator,
    );
    if (userRouteMatch.offRouteMeters > offRouteToleranceMeters) {
      return null;
    }

    final RouteNavigationInstruction? primaryInstruction =
        _nextPrimaryInstruction(
          instructions: instructions,
          cumulativeDistances: cumulativeDistances,
          minRouteMeters:
              userRouteMatch.alongRouteMeters - passedManeuverToleranceMeters,
        );
    if (primaryInstruction == null) {
      return null;
    }

    final int maneuverIndex = primaryInstruction.pointStartIndex.clamp(
      0,
      polyline.length - 1,
    );
    final LatLng maneuverPoint = polyline[maneuverIndex];
    final double maneuverRouteMeters = cumulativeDistances[maneuverIndex];
    final double distanceMeters = math.max(
      0,
      maneuverRouteMeters - userRouteMatch.alongRouteMeters,
    );
    final String maneuverKey = _buildManeuverKey(
      instruction: primaryInstruction,
      maneuverPoint: maneuverPoint,
    );

    if (distanceMeters <= immediateThresholdMeters &&
        !spokenImmediateKeys.contains(maneuverKey)) {
      return NavigationAudioCue(
        instruction: primaryInstruction,
        type: NavigationAudioCueType.immediate,
        distanceMeters: distanceMeters,
        maneuverKey: maneuverKey,
      );
    }

    if (distanceMeters <= approachThresholdMeters &&
        !spokenApproachKeys.contains(maneuverKey) &&
        !spokenImmediateKeys.contains(maneuverKey)) {
      return NavigationAudioCue(
        instruction: primaryInstruction,
        type: NavigationAudioCueType.approach,
        distanceMeters: distanceMeters,
        maneuverKey: maneuverKey,
      );
    }

    if (distanceMeters <= farApproachThresholdMeters &&
        !spokenFarApproachKeys.contains(maneuverKey) &&
        !spokenApproachKeys.contains(maneuverKey) &&
        !spokenImmediateKeys.contains(maneuverKey)) {
      return NavigationAudioCue(
        instruction: primaryInstruction,
        type: NavigationAudioCueType.farApproach,
        distanceMeters: distanceMeters,
        maneuverKey: maneuverKey,
      );
    }

    return null;
  }

  static RouteNavigationInstruction? _nextPrimaryInstruction({
    required List<RouteNavigationInstruction> instructions,
    required List<double> cumulativeDistances,
    required double minRouteMeters,
  }) {
    for (final RouteNavigationInstruction instruction in instructions) {
      if (!instruction.isAudibleTurn) {
        continue;
      }
      final int index = instruction.pointStartIndex.clamp(
        0,
        cumulativeDistances.length - 1,
      );
      if (cumulativeDistances[index] < minRouteMeters) {
        continue;
      }
      return instruction;
    }
    return null;
  }

  static List<double> _cumulativeRouteDistances({
    required List<LatLng> polyline,
    required Distance distanceCalculator,
  }) {
    final List<double> cumulative = <double>[0];
    for (int index = 1; index < polyline.length; index += 1) {
      cumulative.add(
        cumulative.last +
            distanceCalculator.distance(polyline[index - 1], polyline[index]),
      );
    }
    return cumulative;
  }

  static _RouteMatch _matchLocationToRoute({
    required LatLng currentLocation,
    required List<LatLng> polyline,
    required List<double> cumulativeDistances,
    required Distance distanceCalculator,
  }) {
    final _MetricPoint current = _MetricPoint.fromLatLng(
      currentLocation,
      origin: currentLocation,
    );
    double bestOffRouteMeters = double.infinity;
    double bestAlongRouteMeters = 0;

    for (int index = 0; index < polyline.length - 1; index += 1) {
      final LatLng start = polyline[index];
      final LatLng end = polyline[index + 1];
      final _MetricPoint a = _MetricPoint.fromLatLng(
        start,
        origin: currentLocation,
      );
      final _MetricPoint b = _MetricPoint.fromLatLng(
        end,
        origin: currentLocation,
      );
      final double dx = b.x - a.x;
      final double dy = b.y - a.y;
      final double segmentLengthSquared = (dx * dx) + (dy * dy);
      if (segmentLengthSquared == 0) {
        continue;
      }

      final double rawT =
          (((current.x - a.x) * dx) + ((current.y - a.y) * dy)) /
          segmentLengthSquared;
      final double t = rawT.clamp(0.0, 1.0);
      final double projectedX = a.x + (dx * t);
      final double projectedY = a.y + (dy * t);
      final double offRouteDx = current.x - projectedX;
      final double offRouteDy = current.y - projectedY;
      final double offRouteMeters = math.sqrt(
        (offRouteDx * offRouteDx) + (offRouteDy * offRouteDy),
      );

      if (offRouteMeters < bestOffRouteMeters) {
        final double segmentMeters = distanceCalculator.distance(start, end);
        bestOffRouteMeters = offRouteMeters;
        bestAlongRouteMeters = cumulativeDistances[index] + segmentMeters * t;
      }
    }

    return _RouteMatch(
      alongRouteMeters: bestAlongRouteMeters,
      offRouteMeters: bestOffRouteMeters,
    );
  }

  static String _buildManeuverKey({
    required RouteNavigationInstruction instruction,
    required LatLng maneuverPoint,
  }) {
    final String lat = maneuverPoint.latitude.toStringAsFixed(4);
    final String lng = maneuverPoint.longitude.toStringAsFixed(4);
    return '${instruction.sign}-$lat-$lng';
  }
}

class _RouteMatch {
  const _RouteMatch({
    required this.alongRouteMeters,
    required this.offRouteMeters,
  });

  final double alongRouteMeters;
  final double offRouteMeters;
}

class _MetricPoint {
  const _MetricPoint({required this.x, required this.y});

  final double x;
  final double y;

  static _MetricPoint fromLatLng(LatLng point, {required LatLng origin}) {
    const double metersPerDegreeLatitude = 111320;
    final double metersPerDegreeLongitude =
        metersPerDegreeLatitude * math.cos(origin.latitude * math.pi / 180);

    return _MetricPoint(
      x: (point.longitude - origin.longitude) * metersPerDegreeLongitude,
      y: (point.latitude - origin.latitude) * metersPerDegreeLatitude,
    );
  }
}
