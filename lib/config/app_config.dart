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
    this.domainBlocklist = const [],
    this.llm = const LlmConfig(),
  });

  final String? vaultPath;
  // v1: deferred — androidVaultUri is for mobile/SAF; kept for future restoration.
  // See DECISIONS.md §移动端暂缓决策记录.
  final String? androidVaultUri;
  final bool clipboardWatchingEnabled;
  final List<String> domainBlocklist;
  final LlmConfig llm;

  AppConfig copyWith({
    String? vaultPath,
    String? androidVaultUri,
    bool? clipboardWatchingEnabled,
    List<String>? domainBlocklist,
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
      domainBlocklist: domainBlocklist ?? this.domainBlocklist,
      llm: llm ?? this.llm,
    );
  }
}
