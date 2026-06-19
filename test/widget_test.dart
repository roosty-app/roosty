import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/config/config_providers.dart';
import 'package:roosty/config/vault_discovery.dart';
import 'package:roosty/core/core_providers.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/main.dart';
import 'package:roosty/sinks/obsidian_sink.dart';
import 'package:roosty/sources/share_intent_source.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the Roosty desktop loop shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
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

    expect(find.text('Roosty'), findsOneWidget);
    expect(find.text('未检测到 Obsidian'), findsOneWidget);
    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('AI 摘要'), findsOneWidget);
    expect(find.text('Base URL'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('模型'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('剪贴板监听'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
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
            vaultDiscoveryProvider.overrideWithValue(
              VaultDiscovery(platform: VaultDiscoveryPlatform.other),
            ),
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

  testWidgets('shows and removes blocked domains from the ignore list', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vaultPath': 'C:\\test-vault',
      'domainBlocklist': ['block-test.example.com'],
    });
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

    await tester.dragUntilVisible(
      find.text('block-test.example.com'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.text('忽略列表'), findsOneWidget);
    expect(find.text('block-test.example.com'), findsOneWidget);

    await tester.tap(find.byTooltip('移除'));
    await tester.pumpAndSettle();

    expect(find.text('block-test.example.com'), findsNothing);
    expect(find.text('暂无忽略域名'), findsOneWidget);
    expect(preferences.getStringList('domainBlocklist'), isEmpty);
  });

  testWidgets(
    'uses discovered desktop vault and hides discovery after restart',
    (WidgetTester tester) async {
      final temp = Directory(
        p.join(
          Directory.current.path,
          '.dart_tool',
          'test_temp',
          'roosty_widget_vault_${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      temp.createSync(recursive: true);
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });
      final vault = Directory(p.join(temp.path, 'Vault'))
        ..createSync(recursive: true);
      final obsidianJson = File(p.join(temp.path, 'obsidian.json'));
      obsidianJson.writeAsStringSync(
        jsonEncode({
          'vault-a': {'path': vault.path, 'ts': 10, 'open': true},
        }),
      );
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            isAndroidProvider.overrideWithValue(false),
            vaultDiscoveryProvider.overrideWithValue(
              VaultDiscovery(
                platform: VaultDiscoveryPlatform.windows,
                obsidianJsonPath: obsidianJson.path,
              ),
            ),
          ],
          child: const RoostyApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('检测到 Obsidian 库'), findsOneWidget);

      await tester.tap(find.textContaining(vault.path));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        Directory(p.join(vault.path, roostyVaultDirectoryName)).existsSync(),
        isTrue,
      );
      expect(preferences.getString('vaultPath'), vault.path);
      expect(find.text('检测到 Obsidian 库'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            isAndroidProvider.overrideWithValue(false),
            vaultDiscoveryProvider.overrideWithValue(
              VaultDiscovery(
                platform: VaultDiscoveryPlatform.windows,
                obsidianJsonPath: obsidianJson.path,
              ),
            ),
          ],
          child: const RoostyApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('检测到 Obsidian 库'), findsNothing);
    },
  );
}

class _EmptyShareIntentSource extends ShareIntentSource {
  @override
  Stream<Item> watch() => const Stream<Item>.empty();
}
