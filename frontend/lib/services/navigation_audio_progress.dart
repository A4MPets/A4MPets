import 'package:latlong2/latlong.dart';

import '../models/route_navigation_instruction.dart';

enum NavigationAudioCueType { farApproach, approach, immediate }

class NavigationAudioCue {
  const NavigationAudioCue({
    required this.instruction,
    required this.type,
    required this.distanceMeters,
  });

  final RouteNavigationInstruction instruction;
  final NavigationAudioCueType type;
  final double distanceMeters;
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
    required Set<String> spokenFarApproachIds,
    required Set<String> spokenApproachIds,
    required Set<String> spokenImmediateIds,
    required Distance distanceCalculator,
  }) {
    for (final RouteNavigationInstruction instruction in instructions) {
      if (!instruction.isAudibleTurn) {
        continue;
      }
      if (instruction.pointStartIndex < 0 ||
          instruction.pointStartIndex >= polyline.length) {
        continue;
      }

      final LatLng maneuverPoint = polyline[instruction.pointStartIndex];
      final double distanceMeters = distanceCalculator.distance(
        currentLocation,
        maneuverPoint,
      );

      if (distanceMeters <= immediateThresholdMeters &&
          !spokenImmediateIds.contains(instruction.id)) {
        return NavigationAudioCue(
          instruction: instruction,
          type: NavigationAudioCueType.immediate,
          distanceMeters: distanceMeters,
        );
      }
      if (distanceMeters <= approachThresholdMeters &&
          !spokenApproachIds.contains(instruction.id) &&
          !spokenImmediateIds.contains(instruction.id)) {
        return NavigationAudioCue(
          instruction: instruction,
          type: NavigationAudioCueType.approach,
          distanceMeters: distanceMeters,
        );
      }

      if (distanceMeters <= farApproachThresholdMeters &&
          !spokenFarApproachIds.contains(instruction.id) &&
          !spokenApproachIds.contains(instruction.id) &&
          !spokenImmediateIds.contains(instruction.id)) {
        return NavigationAudioCue(
          instruction: instruction,
          type: NavigationAudioCueType.farApproach,
          distanceMeters: distanceMeters,
        );
      }
    }

    return null;
  }
}
