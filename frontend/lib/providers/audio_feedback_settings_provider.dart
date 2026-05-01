import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioFeedbackSettingsController extends Notifier<bool> {
  static const String _audioFeedbackEnabledKey = 'audio_feedback_enabled';

  SharedPreferences? _prefs;

  @override
  bool build() {
    _loadPersistedValue();
    return true;
  }

  Future<void> setEnabled(bool isEnabled) async {
    state = isEnabled;
    final SharedPreferences prefs =
        _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(_audioFeedbackEnabledKey, isEnabled);
  }

  Future<void> _loadPersistedValue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final bool persistedValue =
        prefs.getBool(_audioFeedbackEnabledKey) ?? true;
    if (state != persistedValue) {
      state = persistedValue;
    }
  }
}

final audioFeedbackEnabledProvider =
    NotifierProvider<AudioFeedbackSettingsController, bool>(
      AudioFeedbackSettingsController.new,
    );
