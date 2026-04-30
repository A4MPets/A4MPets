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
      NavigationAudioMessageBuilder.buildApproachMessage(rightTurnInstruction),
      'En 30 metros, gira a la derecha',
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
}
