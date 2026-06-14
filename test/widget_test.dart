import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/config/config_providers.dart';
import 'package:roosty/core/core_providers.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/main.dart';
import 'package:roosty/sources/share_intent_source.dart';
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

  testWidgets(
    'shows Android vault authorization and disables clipboard toggle',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            isAndroidProvider.overrideWithValue(true),
            shareIntentSourceProvider.overrideWithValue(
              _EmptyShareIntentSource(),
            ),
          ],
          child: const RoostyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('授权目录 URI'), findsOneWidget);
      expect(find.byTooltip('授权目录'), findsOneWidget);
      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.onChanged, isNull);
    },
  );
}

class _EmptyShareIntentSource extends ShareIntentSource {
  @override
  Stream<Item> watch() => const Stream<Item>.empty();
}
