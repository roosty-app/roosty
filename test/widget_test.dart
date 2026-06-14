import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/config/config_providers.dart';
import 'package:roosty/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the Roosty desktop loop shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const RoostyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Roosty'), findsOneWidget);
    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('AI 摘要'), findsOneWidget);
    expect(find.text('Base URL'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('模型'), findsOneWidget);
    expect(find.text('剪贴板监听'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('归巢历史'), findsOneWidget);
  });
}
