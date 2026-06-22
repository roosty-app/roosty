import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/theme/light_theme.dart';
import 'package:roosty/theme/tokens.dart';
import 'package:roosty/ui/nest/nest_status_strip.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: lightRoostyTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  Color watchDotColor(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.byKey(NestStatusStrip.watchDotKey),
    );
    final decoration = container.decoration! as BoxDecoration;
    return decoration.color!;
  }

  testWidgets('watching=true uses success color for the watch dot', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const NestStatusStrip(
          vaultName: 'MyVault',
          isWatching: true,
          todayCount: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(watchDotColor(tester), RoostyTokens.light.success);
    expect(find.text('监听中'), findsOneWidget);
    expect(find.text('MyVault'), findsOneWidget);
  });

  testWidgets('watching=false uses disabled color for the watch dot', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const NestStatusStrip(
          vaultName: 'MyVault',
          isWatching: false,
          todayCount: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(watchDotColor(tester), RoostyTokens.light.textDisabled);
    expect(find.text('未监听'), findsOneWidget);
  });

  testWidgets('renders today count text', (tester) async {
    await tester.pumpWidget(
      wrap(
        const NestStatusStrip(
          vaultName: 'MyVault',
          isWatching: true,
          todayCount: 7,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日 7 条归巢'), findsOneWidget);
  });

  testWidgets('empty vault name falls back to placeholder', (tester) async {
    await tester.pumpWidget(
      wrap(
        const NestStatusStrip(
          vaultName: '',
          isWatching: false,
          todayCount: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('未连接'), findsOneWidget);
  });
}
