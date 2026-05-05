import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/route_navigation_instruction.dart';
import 'package:frontend/services/navigation_audio_message_builder.dart';

void main() {
  const RouteNavigationInstruction rightTurnInstruction =
      RouteNavigationInstruction(
        sequence: 0,
        sign: 2,
        text: 'Gira a la derecha hacia Calle 5',
        streetName: 'Calle 5',
        distanceMeters: 24,
        durationSeconds: 8,
        pointStartIndex: 1,
        pointEndIndex: 2,
      );

  test('builds Spanish 100m, 30m, and immediate messages for known signs', () {
    expect(
      NavigationAudioMessageBuilder.buildFarApproachMessage(
        rightTurnInstruction,
      ),
      'En 100 metros, gira a la derecha',
    );
    expect(
      NavigationAudioMessageBuilder.buildImmediateMessage(rightTurnInstruction),
      'Gira ahora a la derecha',
    );
  });

  test('falls back to backend text for unknown instruction signs', () {
    const RouteNavigationInstruction unknownInstruction =
        RouteNavigationInstruction(
          sequence: 2,
          sign: 42,
          text: 'Mantente sobre la via de servicio',
          streetName: '',
          distanceMeters: 12,
          durationSeconds: 4,
          pointStartIndex: 3,
          pointEndIndex: 4,
        );

    expect(
      NavigationAudioMessageBuilder.buildFarApproachMessage(unknownInstruction),
      'Mantente sobre la via de servicio',
    );
    expect(
      NavigationAudioMessageBuilder.buildApproachMessage(unknownInstruction),
      'Mantente sobre la via de servicio',
    );
    expect(
      NavigationAudioMessageBuilder.buildImmediateMessage(unknownInstruction),
      'Mantente sobre la via de servicio',
    );
  });

  test('announces roundabout exit number when GraphHopper provides it', () {
    const RouteNavigationInstruction roundaboutInstruction =
        RouteNavigationInstruction(
          sequence: 3,
          sign: 6,
          text: 'Entra a la rotonda',
          streetName: '',
          exitNumber: 2,
          distanceMeters: 55,
          durationSeconds: 16,
          pointStartIndex: 5,
          pointEndIndex: 8,
        );

    expect(
      NavigationAudioMessageBuilder.buildFarApproachMessage(
        roundaboutInstruction,
      ),
      'En 100 metros, entra a la rotonda y toma la segunda salida',
    );
    expect(
      NavigationAudioMessageBuilder.buildApproachMessage(roundaboutInstruction),
      'En 30 metros, entra a la rotonda y toma la segunda salida',
    );
    expect(
      NavigationAudioMessageBuilder.buildImmediateMessage(
        roundaboutInstruction,
      ),
      'Entra ahora a la rotonda y toma la segunda salida',
    );
  });

  test('extracts roundabout exit number from backend instruction text', () {
    const RouteNavigationInstruction roundaboutInstruction =
        RouteNavigationInstruction(
          sequence: 4,
          sign: 6,
          text: 'En la rotonda toma la 3 salida hacia Avenida Central',
          streetName: 'Avenida Central',
          distanceMeters: 40,
          durationSeconds: 12,
          pointStartIndex: 7,
          pointEndIndex: 9,
        );

    expect(
      NavigationAudioMessageBuilder.buildImmediateMessage(
        roundaboutInstruction,
      ),
      'Entra ahora a la rotonda y toma la tercera salida',
    );
  });
}
