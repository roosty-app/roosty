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
    this.clipboardWatchingEnabled = false,
    this.llm = const LlmConfig(),
  });

  final String? vaultPath;
  final bool clipboardWatchingEnabled;
  final LlmConfig llm;

  AppConfig copyWith({
    String? vaultPath,
    bool? clipboardWatchingEnabled,
    LlmConfig? llm,
    bool clearVaultPath = false,
  }) {
    return AppConfig(
      vaultPath: clearVaultPath ? null : vaultPath ?? this.vaultPath,
      clipboardWatchingEnabled:
          clipboardWatchingEnabled ?? this.clipboardWatchingEnabled,
      llm: llm ?? this.llm,
    );
  }
}
