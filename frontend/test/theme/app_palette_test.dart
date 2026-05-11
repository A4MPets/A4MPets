import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/app_palette.dart';

void main() {
  group('AppPalette (F2-025-extra-theme)', () {
    test('helpers devuelven colores esperados por modo claro y oscuro', () {
      expect(AppPalette.border(true), equals(AppPalette.borderLight));
      expect(AppPalette.border(false), equals(AppPalette.charcoal));
      expect(AppPalette.textPrimary(true), equals(AppPalette.textMutedDark));
      expect(AppPalette.textPrimary(false), equals(AppPalette.charcoal));
      expect(AppPalette.cardBackground(true), equals(AppPalette.cardDark));
      expect(AppPalette.cardBackground(false), equals(AppPalette.cardLight));
      expect(AppPalette.fieldBackground(true), equals(AppPalette.fieldDark));
      expect(AppPalette.fieldBackground(false), equals(AppPalette.white));
      expect(AppPalette.dialogBackground(true).toARGB32(), equals(0xFF2A2A2A));
      expect(AppPalette.dialogBackground(false), equals(AppPalette.white));
      expect(AppPalette.dialogTitle(true), equals(AppPalette.textMutedDark));
      expect(AppPalette.dialogBody(false), equals(AppPalette.charcoal));
      expect(AppPalette.dialogCancel(true), equals(AppPalette.textMutedDark));
      expect(AppPalette.routeSegmentBlueVariants, hasLength(4));
    });
  });
}
