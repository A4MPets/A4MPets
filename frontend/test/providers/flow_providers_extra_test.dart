import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/audio_feedback_settings_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/providers/trip_transport_preference_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  ProviderContainer container() {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('theme y preferencias persistidas (F2-009/F2-019/F2-025-extra)', () {
    test('themeModeProvider alterna modo', () {
      final ProviderContainer c = container();
      final ThemeModeController controller = c.read(themeModeProvider.notifier);

      expect(c.read(themeModeProvider), isTrue);
      controller.setThemeMode(false);
      expect(c.read(themeModeProvider), isFalse);
      controller.toggle();
      expect(c.read(themeModeProvider), isTrue);
    });

    test('tripTransportPreferenceProvider normaliza y persiste modo', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'trip_transport_method': 'vehicle',
      });
      final ProviderContainer c = container();

      expect(c.read(tripTransportPreferenceProvider), equals('walking'));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(tripTransportPreferenceProvider), equals('vehicle'));

      await c
          .read(tripTransportPreferenceProvider.notifier)
          .setTransportName('bike');
      expect(c.read(tripTransportPreferenceProvider), equals('walking'));
      await c
          .read(tripTransportPreferenceProvider.notifier)
          .setTransportName('vehicle');
      expect(c.read(tripTransportPreferenceProvider), equals('vehicle'));
    });

    test(
      'audioFeedbackEnabledProvider carga default y persiste cambios',
      () async {
        final ProviderContainer c = container();

        expect(c.read(audioFeedbackEnabledProvider), isTrue);
        await c.read(audioFeedbackEnabledProvider.notifier).setEnabled(false);
        expect(c.read(audioFeedbackEnabledProvider), isFalse);

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('audio_feedback_enabled'), isFalse);
      },
    );
  });
}
