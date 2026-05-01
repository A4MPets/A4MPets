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

  static NavigationAudioCue? nextCue({
    required LatLng currentLocation,
    required List<LatLng> polyline,
    required List<RouteNavigationInstruction> instructions,
    required Set<String> spokenFarApproachKeys,
    required Set<String> spokenApproachKeys,
    required Set<String> spokenImmediateKeys,
    required Distance distanceCalculator,
  }) {
    if (polyline.isEmpty) {
      return null;
    }

    final int userPolylineIndex = _nearestPolylineIndex(
      currentLocation: currentLocation,
      polyline: polyline,
      distanceCalculator: distanceCalculator,
    );
    final RouteNavigationInstruction? primaryInstruction =
        _nextPrimaryInstruction(
          instructions: instructions,
          minPointStartIndex: userPolylineIndex - 2,
        );
    if (primaryInstruction == null) {
      return null;
    }

    final LatLng maneuverPoint = polyline[primaryInstruction.pointStartIndex];
    final double distanceMeters = distanceCalculator.distance(
      currentLocation,
      maneuverPoint,
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
    required int minPointStartIndex,
  }) {
    for (final RouteNavigationInstruction instruction in instructions) {
      if (!instruction.isAudibleTurn) {
        continue;
      }
      if (instruction.pointStartIndex < minPointStartIndex) {
        continue;
      }
      return instruction;
    }
    return null;
  }

  static int _nearestPolylineIndex({
    required LatLng currentLocation,
    required List<LatLng> polyline,
    required Distance distanceCalculator,
  }) {
    int bestIndex = 0;
    double bestDistance = double.infinity;

    for (int index = 0; index < polyline.length; index++) {
      final double candidateDistance = distanceCalculator.distance(
        currentLocation,
        polyline[index],
      );
      if (candidateDistance < bestDistance) {
        bestDistance = candidateDistance;
        bestIndex = index;
      }
    }

    return bestIndex;
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
