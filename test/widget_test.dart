import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/config/config_providers.dart';
import 'package:roosty/config/vault_discovery.dart';
import 'package:roosty/core/core_providers.dart';
import 'package:roosty/main.dart';
import 'package:roosty/sinks/obsidian_sink.dart';
import 'package:roosty/ui/nest/nest_settings.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the Roosty nest shell with header and settings', (
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

    // Brand block on NestHeader.
    expect(find.text('Roosty'), findsOneWidget);
    // Empty-state copy from NestStage.
    expect(find.text('还没有内容飞回来'), findsOneWidget);
    // Unconfigured vault force-expands NestSettings, so vault/AI fields are visible.
    expect(find.text('Obsidian vault 目录'), findsOneWidget);
    expect(find.text('Base URL'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('模型'), findsOneWidget);
    // Capture switch lives inside NestSettings.
    expect(find.text('剪贴板监听'), findsOneWidget);
    // Vault discovery card lives above NestSettings when vault is empty.
    expect(find.text('未检测到 Obsidian'), findsOneWidget);
    // Exit button stays in NestFooter.
    expect(find.text('退出 Roosty'), findsOneWidget);
  });

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

    // Vault is configured, NestSettings is collapsed by default; expand it.
    await tester.tap(find.byKey(NestSettings.headerKey));
    await tester.pumpAndSettle();

    expect(find.text('block-test.example.com'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('移除'));
    await tester.pumpAndSettle();
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
