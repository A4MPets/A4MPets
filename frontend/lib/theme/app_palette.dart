import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette._();

  static const Color primaryBlue = Color(0xFF5984BC);
  static const Color dangerYellow = Color(0xFFD9B400);
  static const Color dangerOrange = Color(0xFFDB7A00);
  static const Color dangerRed = Color(0xFFA12121);
  static const Color dangerYellow40 = Color(0x66D9B400);
  static const Color dangerOrange40 = Color(0x66DB7A00);
  static const Color dangerRed40 = Color(0x66A12121);

  static const Color white = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF404040);
  static const Color textMutedDark = Color(0xFFAAAAAA);
  static const Color borderLight = Color(0xFFD9D9D9);

  static const Color cardDark = Color(0xFF2D2D2D);
  static const Color cardLight = Color(0xFFF4F4F4);
  static const Color placeholderGray = Color(0xFFD6D6D6);
  static const Color iconGray = Color(0xFF666666);

  static const Color fieldDark = Color(0xFF404040);

  static Color border(bool isDarkMode) {
    return isDarkMode ? borderLight : charcoal;
  }

  static Color textPrimary(bool isDarkMode) {
    return isDarkMode ? textMutedDark : charcoal;
  }

  static Color cardBackground(bool isDarkMode) {
    return isDarkMode ? cardDark : cardLight;
  }

  static Color fieldBackground(bool isDarkMode) {
    return isDarkMode ? fieldDark : white;
  }

  static Color dialogBackground(bool isDarkMode) {
    return isDarkMode ? const Color(0xFF2A2A2A) : white;
  }

  static Color dialogTitle(bool isDarkMode) {
    return isDarkMode ? textMutedDark : charcoal;
  }

  static Color dialogBody(bool isDarkMode) {
    return isDarkMode ? const Color(0xFFBEBEBE) : charcoal;
  }

  static Color dialogCancel(bool isDarkMode) {
    return isDarkMode ? textMutedDark : charcoal;
  }
}
