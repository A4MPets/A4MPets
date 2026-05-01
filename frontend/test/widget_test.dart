import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/providers/theme_provider.dart';

void main() {
  testWidgets('MyApp boots inside ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  });

  test('theme controller updates and toggles state', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final ThemeModeController controller = container.read(
      themeModeProvider.notifier,
    );

    expect(container.read(themeModeProvider), isTrue);

    controller.setThemeMode(false);
    expect(container.read(themeModeProvider), isFalse);

    controller.toggle();
    expect(container.read(themeModeProvider), isTrue);
  });
}
