import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/audio_feedback_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('audio feedback setting defaults to enabled and persists updates', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(audioFeedbackEnabledProvider), isTrue);

    await container.read(audioFeedbackEnabledProvider.notifier).setEnabled(false);
    expect(container.read(audioFeedbackEnabledProvider), isFalse);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('audio_feedback_enabled'), isFalse);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'audio_feedback_enabled': false,
    });
    final ProviderContainer reloadedContainer = ProviderContainer();
    addTearDown(reloadedContainer.dispose);
    reloadedContainer.read(audioFeedbackEnabledProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(reloadedContainer.read(audioFeedbackEnabledProvider), isFalse);
  });
}
