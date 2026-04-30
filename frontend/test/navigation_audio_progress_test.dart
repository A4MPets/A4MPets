import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/route_navigation_instruction.dart';
import 'package:frontend/services/navigation_audio_progress.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const Distance distanceCalculator = Distance();
  const List<LatLng> polyline = <LatLng>[
    LatLng(3.451600, -76.532000),
    LatLng(3.451780, -76.532000),
    LatLng(3.451900, -76.531820),
  ];
  const RouteNavigationInstruction rightTurnInstruction =
      RouteNavigationInstruction(
        sequence: 0,
        sign: 2,
        text: 'Gira a la derecha',
        streetName: 'Calle 5',
        distanceMeters: 30,
        durationSeconds: 12,
        pointStartIndex: 1,
        pointEndIndex: 2,
      );

  test('returns 100m cue before 30m and immediate cues for unseen turn', () {
    final NavigationAudioCue? farCue = NavigationAudioProgress.nextCue(
      currentLocation: const LatLng(3.450900, -76.532000),
      polyline: polyline,
      instructions: const <RouteNavigationInstruction>[rightTurnInstruction],
      spokenFarApproachIds: <String>{},
      spokenApproachIds: <String>{},
      spokenImmediateIds: <String>{},
      distanceCalculator: distanceCalculator,
    );

    expect(farCue, isNotNull);
    expect(farCue!.type, NavigationAudioCueType.farApproach);

    final NavigationAudioCue? cue = NavigationAudioProgress.nextCue(
      currentLocation: const LatLng(3.451610, -76.532000),
      polyline: polyline,
      instructions: const <RouteNavigationInstruction>[rightTurnInstruction],
      spokenFarApproachIds: <String>{},
      spokenApproachIds: <String>{},
      spokenImmediateIds: <String>{},
      distanceCalculator: distanceCalculator,
    );

    expect(cue, isNotNull);
    expect(cue!.type, NavigationAudioCueType.approach);
  });

  test('returns immediate cue when user is already at the maneuver', () {
    final NavigationAudioCue? cue = NavigationAudioProgress.nextCue(
      currentLocation: const LatLng(3.451780, -76.532000),
      polyline: polyline,
      instructions: const <RouteNavigationInstruction>[rightTurnInstruction],
      spokenFarApproachIds: <String>{},
      spokenApproachIds: <String>{},
      spokenImmediateIds: <String>{},
      distanceCalculator: distanceCalculator,
    );

    expect(cue, isNotNull);
    expect(cue!.type, NavigationAudioCueType.immediate);
  });

  test('skips cues that were already spoken and ignores non-turn signs', () {
    const RouteNavigationInstruction continueInstruction =
        RouteNavigationInstruction(
          sequence: 1,
          sign: 0,
          text: 'Continua recto',
          streetName: '',
          distanceMeters: 15,
          durationSeconds: 5,
          pointStartIndex: 1,
          pointEndIndex: 2,
        );

    final NavigationAudioCue? cue = NavigationAudioProgress.nextCue(
      currentLocation: const LatLng(3.451780, -76.532000),
      polyline: polyline,
      instructions: const <RouteNavigationInstruction>[
        rightTurnInstruction,
        continueInstruction,
      ],
      spokenFarApproachIds: <String>{rightTurnInstruction.id},
      spokenApproachIds: <String>{rightTurnInstruction.id},
      spokenImmediateIds: <String>{rightTurnInstruction.id},
      distanceCalculator: distanceCalculator,
    );

    expect(cue, isNull);
  });
}
