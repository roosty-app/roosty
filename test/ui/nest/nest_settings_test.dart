import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/config/app_config.dart';
import 'package:roosty/core/core_providers.dart';
import 'package:roosty/theme/light_theme.dart';
import 'package:roosty/ui/nest/nest_settings.dart';

void main() {
  late TextEditingController vaultPathController;
  late TextEditingController llmBaseUrlController;
  late TextEditingController llmApiKeyController;
  late TextEditingController llmModelController;
  late TextEditingController manualUrlController;

  setUp(() {
    vaultPathController = TextEditingController();
    llmBaseUrlController = TextEditingController();
    llmApiKeyController = TextEditingController();
    llmModelController = TextEditingController();
    manualUrlController = TextEditingController();
  });

  tearDown(() {
    vaultPathController.dispose();
    llmBaseUrlController.dispose();
    llmApiKeyController.dispose();
    llmModelController.dispose();
    manualUrlController.dispose();
  });

  Widget pump({
    required AppConfig config,
    required bool forceExpanded,
  }) {
    return MaterialApp(
      theme: lightRoostyTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: NestSettings(
            config: config,
            effectiveClipboardWatching: false,
            captureState: const CaptureState(),
            vaultPathController: vaultPathController,
            llmBaseUrlController: llmBaseUrlController,
            llmApiKeyController: llmApiKeyController,
            llmModelController: llmModelController,
            manualUrlController: manualUrlController,
            forceExpanded: forceExpanded,
            onChooseVault: () {},
            onSaveVault: () {},
            onRediscoverVaults: () {},
            onSaveLlm: () {},
            onRemoveBlockedDomain: (_) {},
            onToggleClipboard: (_) {},
            onManualArchive: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('collapsed by default hides the settings body', (tester) async {
    await tester.pumpWidget(
      pump(
        config: const AppConfig(vaultPath: '/some/path'),
        forceExpanded: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(NestSettings.headerKey), findsOneWidget);
    expect(find.text('Obsidian vault 目录'), findsNothing);
    expect(find.text('Base URL'), findsNothing);
  });

  testWidgets('tapping header expands and shows the vault input', (
    tester,
  ) async {
    await tester.pumpWidget(
      pump(
        config: const AppConfig(vaultPath: '/some/path'),
        forceExpanded: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(NestSettings.headerKey));
    await tester.pumpAndSettle();

    expect(find.text('Obsidian vault 目录'), findsOneWidget);
    expect(find.text('Base URL'), findsOneWidget);
    expect(find.text('剪贴板监听'), findsOneWidget);
    expect(find.text('暂无忽略域名'), findsOneWidget);
  });

  testWidgets('forceExpanded=true keeps the body open initially', (
    tester,
  ) async {
    await tester.pumpWidget(
      pump(config: const AppConfig(), forceExpanded: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Obsidian vault 目录'), findsOneWidget);
    expect(find.text('Base URL'), findsOneWidget);
  });

  testWidgets('blocklist renders configured domains with remove buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      pump(
        config: const AppConfig(
          vaultPath: '/some/path',
          domainBlocklist: ['example.com'],
        ),
        forceExpanded: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('example.com'), findsOneWidget);
    expect(find.byTooltip('移除'), findsOneWidget);
  });
}
