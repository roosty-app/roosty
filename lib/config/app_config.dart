class LlmConfig {
  const LlmConfig({
    this.baseUrl = 'https://api.deepseek.com',
    this.apiKey = '',
    this.model = 'deepseek-chat',
  });

  final String baseUrl;
  final String apiKey;
  final String model;

  bool get isConfigured =>
      baseUrl.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      model.trim().isNotEmpty;

  LlmConfig copyWith({String? baseUrl, String? apiKey, String? model}) {
    return LlmConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }
}

class AppConfig {
  const AppConfig({
    this.vaultPath,
    this.androidVaultUri,
    this.clipboardWatchingEnabled = false,
    this.llm = const LlmConfig(),
  });

  final String? vaultPath;
  final String? androidVaultUri;
  final bool clipboardWatchingEnabled;
  final LlmConfig llm;

  AppConfig copyWith({
    String? vaultPath,
    String? androidVaultUri,
    bool? clipboardWatchingEnabled,
    LlmConfig? llm,
    bool clearVaultPath = false,
    bool clearAndroidVaultUri = false,
  }) {
    return AppConfig(
      vaultPath: clearVaultPath ? null : vaultPath ?? this.vaultPath,
      androidVaultUri: clearAndroidVaultUri
          ? null
          : androidVaultUri ?? this.androidVaultUri,
      clipboardWatchingEnabled:
          clipboardWatchingEnabled ?? this.clipboardWatchingEnabled,
      llm: llm ?? this.llm,
    );
  }
}
