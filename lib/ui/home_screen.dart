import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../config/config_providers.dart';
import '../core/core_providers.dart';
import '../core/item.dart';
import '../sources/clipboard_source.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _vaultPathController = TextEditingController();
  final _llmBaseUrlController = TextEditingController();
  final _llmApiKeyController = TextEditingController();
  final _llmModelController = TextEditingController();
  final _manualUrlController = TextEditingController();
  String? _syncedVaultPath;
  LlmConfig? _syncedLlmConfig;

  @override
  void dispose() {
    _vaultPathController.dispose();
    _llmBaseUrlController.dispose();
    _llmApiKeyController.dispose();
    _llmModelController.dispose();
    _manualUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigControllerProvider);
    final captureState = ref.watch(captureControllerProvider);
    final isAndroid = ref.watch(isAndroidProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Roosty')),
      body: appConfig.when(
        data: (config) {
          _syncVaultController(config, isAndroid: isAndroid);
          _syncLlmControllers(config.llm);
          return _HomeContent(
            config: config,
            isAndroid: isAndroid,
            captureState: captureState,
            vaultPathController: _vaultPathController,
            llmBaseUrlController: _llmBaseUrlController,
            llmApiKeyController: _llmApiKeyController,
            llmModelController: _llmModelController,
            manualUrlController: _manualUrlController,
            onChooseVault: () => _chooseVault(config, isAndroid: isAndroid),
            onSaveVault: () => _saveVaultPath(isAndroid: isAndroid),
            onSaveLlm: _saveLlmConfig,
            onToggleClipboard: (enabled) {
              ref
                  .read(appConfigControllerProvider.notifier)
                  .updateClipboardWatchingEnabled(enabled);
            },
            onManualArchive: _archiveManualUrl,
            onConfirmPending: () {
              ref.read(captureControllerProvider.notifier).archivePending();
            },
            onDismissPending: () {
              ref.read(captureControllerProvider.notifier).dismissPending();
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('配置加载失败')),
      ),
    );
  }

  void _syncVaultController(AppConfig config, {required bool isAndroid}) {
    final vaultPath = isAndroid
        ? config.androidVaultUri ?? ''
        : config.vaultPath ?? '';
    if (_syncedVaultPath != vaultPath &&
        _vaultPathController.text == (_syncedVaultPath ?? '')) {
      _vaultPathController.text = vaultPath;
    }
    _syncedVaultPath = vaultPath;
  }

  void _syncLlmControllers(LlmConfig llm) {
    final previous = _syncedLlmConfig;
    if (previous == null || _llmBaseUrlController.text == previous.baseUrl) {
      _llmBaseUrlController.text = llm.baseUrl;
    }
    if (previous == null || _llmApiKeyController.text == previous.apiKey) {
      _llmApiKeyController.text = llm.apiKey;
    }
    if (previous == null || _llmModelController.text == previous.model) {
      _llmModelController.text = llm.model;
    }
    _syncedLlmConfig = llm;
  }

  Future<void> _chooseVault(AppConfig config, {required bool isAndroid}) async {
    if (isAndroid) {
      final uri = await ref.read(androidSafVaultProvider).pickDirectory();
      if (uri == null || !mounted) {
        return;
      }
      _vaultPathController.text = uri;
      await ref
          .read(appConfigControllerProvider.notifier)
          .updateAndroidVaultUri(uri);
      return;
    }

    final path = await getDirectoryPath(
      initialDirectory: config.vaultPath,
      confirmButtonText: '选择',
      canCreateDirectories: true,
    );
    if (path == null || !mounted) {
      return;
    }
    _vaultPathController.text = path;
    await _saveVaultPath(isAndroid: isAndroid);
  }

  Future<void> _saveVaultPath({required bool isAndroid}) async {
    if (isAndroid) {
      await ref
          .read(appConfigControllerProvider.notifier)
          .updateAndroidVaultUri(_vaultPathController.text);
      return;
    }
    await ref
        .read(appConfigControllerProvider.notifier)
        .updateVaultPath(_vaultPathController.text);
  }

  Future<void> _saveLlmConfig() async {
    await ref
        .read(appConfigControllerProvider.notifier)
        .updateLlmConfig(
          LlmConfig(
            baseUrl: _llmBaseUrlController.text.trim(),
            apiKey: _llmApiKeyController.text.trim(),
            model: _llmModelController.text.trim(),
          ),
        );
  }

  Future<void> _archiveManualUrl() async {
    final url = extractFirstUrl(_manualUrlController.text);
    if (url == null) {
      ref
          .read(captureControllerProvider.notifier)
          .showMessage('请输入 http(s) URL');
      return;
    }
    _manualUrlController.clear();
    await ref.read(captureControllerProvider.notifier).archive(Item(url: url));
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.config,
    required this.isAndroid,
    required this.captureState,
    required this.vaultPathController,
    required this.llmBaseUrlController,
    required this.llmApiKeyController,
    required this.llmModelController,
    required this.manualUrlController,
    required this.onChooseVault,
    required this.onSaveVault,
    required this.onSaveLlm,
    required this.onToggleClipboard,
    required this.onManualArchive,
    required this.onConfirmPending,
    required this.onDismissPending,
  });

  final AppConfig config;
  final bool isAndroid;
  final CaptureState captureState;
  final TextEditingController vaultPathController;
  final TextEditingController llmBaseUrlController;
  final TextEditingController llmApiKeyController;
  final TextEditingController llmModelController;
  final TextEditingController manualUrlController;
  final VoidCallback onChooseVault;
  final VoidCallback onSaveVault;
  final VoidCallback onSaveLlm;
  final ValueChanged<bool> onToggleClipboard;
  final VoidCallback onManualArchive;
  final VoidCallback onConfirmPending;
  final VoidCallback onDismissPending;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(
            title: 'Vault',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: vaultPathController,
                    decoration: InputDecoration(
                      labelText: isAndroid ? '授权目录 URI' : 'Obsidian vault 目录',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => onSaveVault(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: isAndroid ? '授权目录' : '选择目录',
                  onPressed: onChooseVault,
                  icon: const Icon(Icons.folder_open),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: '保存',
                  onPressed: onSaveVault,
                  icon: const Icon(Icons.save),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'AI 摘要',
            child: Column(
              children: [
                TextField(
                  controller: llmBaseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.deepseek.com',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onSaveLlm(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: llmApiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onSaveLlm(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: llmModelController,
                        decoration: const InputDecoration(
                          labelText: '模型',
                          hintText: 'deepseek-chat',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => onSaveLlm(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: '保存 AI 设置',
                      onPressed: onSaveLlm,
                      icon: const Icon(Icons.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: '捕获',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('剪贴板监听'),
                  value: config.clipboardWatchingEnabled,
                  onChanged: isAndroid ? null : onToggleClipboard,
                  secondary: const Icon(Icons.content_paste_search),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: manualUrlController,
                        decoration: const InputDecoration(
                          labelText: '手动粘贴 URL',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => onManualArchive(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: '归巢',
                      onPressed: captureState.isArchiving
                          ? null
                          : onManualArchive,
                      icon: const Icon(Icons.archive),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (captureState.pendingItem != null) ...[
            const SizedBox(height: 20),
            _PendingCapture(
              item: captureState.pendingItem!,
              isArchiving: captureState.isArchiving,
              onConfirm: onConfirmPending,
              onDismiss: onDismissPending,
            ),
          ],
          if (captureState.message != null) ...[
            const SizedBox(height: 12),
            Text(
              captureState.message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          _Section(
            title: '归巢历史',
            child: captureState.history.isEmpty
                ? const Text('暂无归巢记录')
                : Column(
                    children: captureState.history
                        .map((item) => _HistoryTile(item: item))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _PendingCapture extends StatelessWidget {
  const _PendingCapture({
    required this.item,
    required this.isArchiving,
    required this.onConfirm,
    required this.onDismiss,
  });

  final Item item;
  final bool isArchiving;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.link),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '忽略',
              onPressed: isArchiving ? null : onDismiss,
              icon: const Icon(Icons.close),
            ),
            IconButton.filled(
              tooltip: '确认归巢',
              onPressed: isArchiving ? null : onConfirm,
              icon: const Icon(Icons.check),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.article_outlined),
      title: Text(
        item.title ?? item.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
