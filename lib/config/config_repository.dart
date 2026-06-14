import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

abstract class ConfigRepository {
  Future<AppConfig> load();

  Future<void> save(AppConfig config);
}

class SharedPreferencesConfigRepository implements ConfigRepository {
  SharedPreferencesConfigRepository(this._preferences);

  static const _vaultPathKey = 'vaultPath';
  static const _androidVaultUriKey = 'androidVaultUri';
  static const _clipboardWatchingEnabledKey = 'clipboardWatchingEnabled';
  static const _llmBaseUrlKey = 'llmBaseUrl';
  static const _llmApiKeyKey = 'llmApiKey';
  static const _llmModelKey = 'llmModel';

  final SharedPreferences _preferences;

  @override
  Future<AppConfig> load() async {
    return AppConfig(
      vaultPath: _preferences.getString(_vaultPathKey),
      androidVaultUri: _preferences.getString(_androidVaultUriKey),
      clipboardWatchingEnabled:
          _preferences.getBool(_clipboardWatchingEnabledKey) ?? false,
      llm: LlmConfig(
        baseUrl:
            _preferences.getString(_llmBaseUrlKey) ?? const LlmConfig().baseUrl,
        apiKey: _preferences.getString(_llmApiKeyKey) ?? '',
        model: _preferences.getString(_llmModelKey) ?? const LlmConfig().model,
      ),
    );
  }

  @override
  Future<void> save(AppConfig config) async {
    final vaultPath = config.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) {
      await _preferences.remove(_vaultPathKey);
    } else {
      await _preferences.setString(_vaultPathKey, vaultPath);
    }

    final androidVaultUri = config.androidVaultUri;
    if (androidVaultUri == null || androidVaultUri.isEmpty) {
      await _preferences.remove(_androidVaultUriKey);
    } else {
      await _preferences.setString(_androidVaultUriKey, androidVaultUri);
    }

    await _preferences.setBool(
      _clipboardWatchingEnabledKey,
      config.clipboardWatchingEnabled,
    );
    await _preferences.setString(_llmBaseUrlKey, config.llm.baseUrl);
    await _preferences.setString(_llmApiKeyKey, config.llm.apiKey);
    await _preferences.setString(_llmModelKey, config.llm.model);
  }
}
