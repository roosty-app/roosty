import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roosty/config/config_providers.dart';
import 'package:roosty/config/vault_discovery.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/core/mini_card.dart';
import 'package:roosty/main.dart';
import 'package:roosty/theme/dark_theme.dart';
import 'package:roosty/theme/light_theme.dart';
import 'package:roosty/theme/tokens.dart';
import 'package:roosty/ui/mini_card_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme source does not use seed-generated Material colors', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains('ColorScheme.fromSeed'),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  testWidgets('RoostyApp follows platform brightness with token themes', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(binding.platformDispatcher.clearPlatformBrightnessTestValue);

    SharedPreferences.setMockInitialValues({'vaultPath': 'C:\\test-vault'});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          vaultDiscoveryProvider.overrideWithValue(
            VaultDiscovery(platform: VaultDiscoveryPlatform.other),
          ),
        ],
        child: const RoostyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);

    expect(theme.brightness, Brightness.dark);
    expect(theme.extension<RoostyTokens>()?.bgBase, const Color(0xFF1F1B17));
    expect(theme.colorScheme.primary, const Color(0xFFD89968));
  });

  testWidgets('mini card renders token card surface in light and dark themes', (
    tester,
  ) async {
    final card = MiniCardModel(
      id: 'card-1',
      item: Item(
        url: 'https://example.com/article',
        title: '温暖手作标题',
        summary: '一段适合双主题检查的摘要。',
      ),
      createdAt: DateTime(2026, 6, 20),
    );

    Future<Color?> pumpAndFindCardColor(ThemeMode mode) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightRoostyTheme,
          darkTheme: darkRoostyTheme,
          themeMode: mode,
          home: Scaffold(
            body: Center(
              child: MiniCardWindow(
                card: card,
                isArchiving: false,
                onArchive: () {},
                onIgnoreOnce: () {},
                onBlockDomain: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final decorations = tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      );
      for (final decorated in decorations) {
        final decoration = decorated.decoration;
        if (decoration is BoxDecoration && decoration.boxShadow != null) {
          return decoration.color;
        }
      }
      return null;
    }

    expect(
      await pumpAndFindCardColor(ThemeMode.light),
      RoostyTokens.light.bgCard,
    );
    expect(
      await pumpAndFindCardColor(ThemeMode.dark),
      RoostyTokens.dark.bgCard,
    );
  });
}
