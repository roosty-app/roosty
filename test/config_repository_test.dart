import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/config/app_config.dart';
import 'package:roosty/config/config_repository.dart';
import 'package:roosty/core/item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads default config when preferences are empty', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SharedPreferencesConfigRepository(
      await SharedPreferences.getInstance(),
    );

    final config = await repository.load();

    expect(config.vaultPath, isNull);
    expect(config.clipboardWatchingEnabled, isFalse);
    expect(config.llm.baseUrl, 'https://api.deepseek.com');
    expect(config.llm.apiKey, isEmpty);
    expect(config.llm.model, 'deepseek-chat');
  });

  test('persists vault path, clipboard toggle, and LLM settings', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SharedPreferencesConfigRepository(
      await SharedPreferences.getInstance(),
    );

    await repository.save(
      const AppConfig(
        vaultPath: r'D:\Vault',
        clipboardWatchingEnabled: true,
        llm: LlmConfig(
          baseUrl: 'https://example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ),
      ),
    );

    final config = await repository.load();

    expect(config.vaultPath, r'D:\Vault');
    expect(config.clipboardWatchingEnabled, isTrue);
    expect(config.llm.baseUrl, 'https://example.com');
    expect(config.llm.apiKey, 'test-key');
    expect(config.llm.model, 'test-model');
  });

  test('item default tags can be extended by processors', () {
    final item = Item(url: 'https://example.com');

    item.tags.add('roosty/test');

    expect(item.tags, ['roosty/inbox', 'roosty/test']);
  });
}
