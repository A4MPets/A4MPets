import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the global theme mode used by the app shell.
class ThemeModeController extends Notifier<bool> {
  @override
  bool build() => true;

  /// Replaces the current theme mode state.
  void setThemeMode(bool isDarkMode) {
    state = isDarkMode;
  }

  /// Flips the current theme mode state.
  void toggle() {
    state = !state;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, bool>(
  ThemeModeController.new,
);
