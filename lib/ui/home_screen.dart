import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../config/config_providers.dart';
import '../config/vault_discovery.dart';
import '../core/core_providers.dart';
import '../core/item.dart';
import '../sinks/obsidian_sink.dart';
import '../sources/clipboard_source.dart';
import 'desktop_lifecycle.dart';
import 'desktop_mini_card_window_host.dart';
import 'desktop_tray_bridge.dart';
import 'mini_card_window.dart';

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
  bool _forceShowVaultDiscovery = false;

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
    final vaultCandidates = ref.watch(vaultCandidatesProvider);
    final captureState = ref.watch(captureControllerProvider);
    final miniCardState = ref.watch(miniCardControllerProvider);
    final effectiveClipboardWatching = ref.watch(
      effectiveClipboardWatchingProvider,
    );
    final isAndroid = ref.watch(isAndroidProvider);
    final isWindows = ref.watch(isWindowsProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Roosty')),
          body: appConfig.when(
            data: (config) {
              _syncVaultController(config, isAndroid: isAndroid);
              _syncLlmControllers(config.llm);
              final showVaultDiscovery =
                  !isAndroid &&
                  (_forceShowVaultDiscovery ||
                      (config.vaultPath?.trim().isEmpty ?? true));
              return _HomeContent(
                config: config,
                effectiveClipboardWatching: effectiveClipboardWatching,
                isAndroid: isAndroid,
                showVaultDiscovery: showVaultDiscovery,
                vaultCandidates: vaultCandidates,
                captureState: captureState,
                vaultPathController: _vaultPathController,
                llmBaseUrlController: _llmBaseUrlController,
                llmApiKeyController: _llmApiKeyController,
                llmModelController: _llmModelController,
                manualUrlController: _manualUrlController,
                onChooseVault: () => _chooseVault(config, isAndroid: isAndroid),
                onSaveVault: () => _saveVaultPath(isAndroid: isAndroid),
                onRediscoverVaults: _rediscoverVaults,
                onUseDiscoveredVault: _useDiscoveredVault,
                onSaveLlm: _saveLlmConfig,
                onRemoveBlockedDomain: _removeBlockedDomain,
                onToggleClipboard: (enabled) {
                  ref
                      .read(clipboardWatchingSessionOverrideProvider.notifier)
                      .clear();
                  ref
                      .read(appConfigControllerProvider.notifier)
                      .updateClipboardWatchingEnabled(enabled);
                },
                onManualArchive: _archiveManualUrl,
                onExitApp: () => confirmExitRoosty(context),
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
        ),
        if (!isAndroid && !isWindows && miniCardState.cards.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: MiniCardDeck(
              cards: miniCardState.cards,
              isArchiving: captureState.isArchiving,
              onArchive: (id) {
                unawaited(
                  ref
                      .read(captureControllerProvider.notifier)
                      .archiveMiniCard(id),
                );
              },
              onIgnoreOnce: (id) {
                ref.read(miniCardControllerProvider.notifier).ignoreOnce(id);
              },
              onBlockDomain: (id) {
                unawaited(
                  ref.read(miniCardControllerProvider.notifier).blockDomain(id),
                );
              },
            ),
          ),
        const DesktopMiniCardWindowHost(),
        const DesktopWindowLifecycleBridge(),
        const DesktopTrayBridge(),
      ],
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
      await _saveAndroidVaultUri(uri);
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
    await _saveDesktopVaultPath(path);
  }

  Future<void> _saveVaultPath({required bool isAndroid}) async {
    if (isAndroid) {
      await _saveAndroidVaultUri(_vaultPathController.text);
      return;
    }
    await _saveDesktopVaultPath(_vaultPathController.text);
  }

  Future<void> _saveDesktopVaultPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      await ref.read(appConfigControllerProvider.notifier).updateVaultPath('');
      return;
    }

    try {
      await ensureRoostyDirectory(trimmed);
      await ref
          .read(appConfigControllerProvider.notifier)
          .updateVaultPath(trimmed);
      if (!mounted) {
        return;
      }
      _vaultPathController.text = trimmed;
      setState(() {
        _forceShowVaultDiscovery = false;
      });
      ref
          .read(captureControllerProvider.notifier)
          .showMessage('已连接 Obsidian vault：$trimmed');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ref
          .read(captureControllerProvider.notifier)
          .showMessage('创建 Roosty 目录失败：$error');
    }
  }

  Future<void> _saveAndroidVaultUri(String uri) async {
    final trimmed = uri.trim();
    if (trimmed.isEmpty) {
      await ref
          .read(appConfigControllerProvider.notifier)
          .updateAndroidVaultUri('');
      return;
    }

    try {
      await ref
          .read(androidSafVaultProvider)
          .ensureDirectory(
            treeUri: trimmed,
            directoryName: roostyVaultDirectoryName,
          );
      await ref
          .read(appConfigControllerProvider.notifier)
          .updateAndroidVaultUri(trimmed);
      if (!mounted) {
        return;
      }
      _vaultPathController.text = trimmed;
      ref.read(captureControllerProvider.notifier).showMessage('已授权归巢目录');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ref
          .read(captureControllerProvider.notifier)
          .showMessage('创建 Roosty 目录失败：$error');
    }
  }

  void _rediscoverVaults() {
    setState(() {
      _forceShowVaultDiscovery = true;
    });
    ref.invalidate(vaultCandidatesProvider);
  }

  Future<void> _useDiscoveredVault(String path) async {
    _vaultPathController.text = path;
    await _saveDesktopVaultPath(path);
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

  Future<void> _removeBlockedDomain(String domain) async {
    await ref
        .read(appConfigControllerProvider.notifier)
        .removeDomainFromBlocklist(domain);
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
    required this.effectiveClipboardWatching,
    required this.isAndroid,
    required this.showVaultDiscovery,
    required this.vaultCandidates,
    required this.captureState,
    required this.vaultPathController,
    required this.llmBaseUrlController,
    required this.llmApiKeyController,
    required this.llmModelController,
    required this.manualUrlController,
    required this.onChooseVault,
    required this.onSaveVault,
    required this.onRediscoverVaults,
    required this.onUseDiscoveredVault,
    required this.onSaveLlm,
    required this.onRemoveBlockedDomain,
    required this.onToggleClipboard,
    required this.onManualArchive,
    required this.onExitApp,
    required this.onConfirmPending,
    required this.onDismissPending,
  });

  final AppConfig config;
  final bool effectiveClipboardWatching;
  final bool isAndroid;
  final bool showVaultDiscovery;
  final AsyncValue<List<VaultCandidate>> vaultCandidates;
  final CaptureState captureState;
  final TextEditingController vaultPathController;
  final TextEditingController llmBaseUrlController;
  final TextEditingController llmApiKeyController;
  final TextEditingController llmModelController;
  final TextEditingController manualUrlController;
  final VoidCallback onChooseVault;
  final VoidCallback onSaveVault;
  final VoidCallback onRediscoverVaults;
  final ValueChanged<String> onUseDiscoveredVault;
  final VoidCallback onSaveLlm;
  final ValueChanged<String> onRemoveBlockedDomain;
  final ValueChanged<bool> onToggleClipboard;
  final VoidCallback onManualArchive;
  final VoidCallback onExitApp;
  final VoidCallback onConfirmPending;
  final VoidCallback onDismissPending;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (showVaultDiscovery) ...[
            _VaultDiscoveryCard(
              candidates: vaultCandidates,
              onUseVault: onUseDiscoveredVault,
              onChooseOther: onChooseVault,
            ),
            const SizedBox(height: 20),
          ],
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
                if (!isAndroid) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: '重新检测 Obsidian 库',
                    onPressed: onRediscoverVaults,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
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
                  value: effectiveClipboardWatching,
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
          const SizedBox(height: 20),
          _Section(
            title: '应用',
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: onExitApp,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('退出 Roosty'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: '忽略列表',
            child: config.domainBlocklist.isEmpty
                ? const Text('暂无忽略域名')
                : Column(
                    children: config.domainBlocklist
                        .map(
                          (domain) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.block),
                            title: Text(
                              domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip: '移除',
                              onPressed: () => onRemoveBlockedDomain(domain),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        )
                        .toList(),
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

class _VaultDiscoveryCard extends StatelessWidget {
  const _VaultDiscoveryCard({
    required this.candidates,
    required this.onUseVault,
    required this.onChooseOther,
  });

  final AsyncValue<List<VaultCandidate>> candidates;
  final ValueChanged<String> onUseVault;
  final VoidCallback onChooseOther;

  @override
  Widget build(BuildContext context) {
    return candidates.when(
      data: (items) => _buildData(context, items),
      loading: () => _VaultDiscoveryFrame(
        title: '正在检测 Obsidian 库',
        child: const LinearProgressIndicator(),
      ),
      error: (_, _) => _buildData(context, const []),
    );
  }

  Widget _buildData(BuildContext context, List<VaultCandidate> items) {
    if (items.isEmpty) {
      return _VaultDiscoveryFrame(
        title: '未检测到 Obsidian',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('请选择一个目录作为归档库。'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onChooseOther,
              icon: const Icon(Icons.folder_open),
              label: const Text('选择目录'),
            ),
          ],
        ),
      );
    }

    if (items.length == 1) {
      final candidate = items.single;
      return _VaultDiscoveryFrame(
        title: '检测到 Obsidian 库',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () => onUseVault(candidate.path),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '使用 ${candidate.path}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onChooseOther,
              icon: const Icon(Icons.folder_open),
              label: const Text('选其他目录'),
            ),
          ],
        ),
      );
    }

    return _VaultDiscoveryFrame(
      title: '检测到多个 Obsidian 库',
      child: _VaultCandidateList(candidates: items, onUseVault: onUseVault),
    );
  }
}

class _VaultDiscoveryFrame extends StatelessWidget {
  const _VaultDiscoveryFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _VaultCandidateList extends StatefulWidget {
  const _VaultCandidateList({
    required this.candidates,
    required this.onUseVault,
  });

  final List<VaultCandidate> candidates;
  final ValueChanged<String> onUseVault;

  @override
  State<_VaultCandidateList> createState() => _VaultCandidateListState();
}

class _VaultCandidateListState extends State<_VaultCandidateList> {
  String? _selectedPath;

  @override
  void initState() {
    super.initState();
    _syncSelectedPath();
  }

  @override
  void didUpdateWidget(covariant _VaultCandidateList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedPath();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioGroup<String>(
          groupValue: _selectedPath,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPath = value;
              });
            }
          },
          child: Column(
            children: widget.candidates
                .map(
                  (candidate) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: candidate.path,
                    title: Text(candidate.path),
                    subtitle: candidate.isOpen ? const Text('当前打开') : null,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _selectedPath == null
              ? null
              : () => widget.onUseVault(_selectedPath!),
          icon: const Icon(Icons.check),
          label: const Text('使用此库'),
        ),
      ],
    );
  }

  void _syncSelectedPath() {
    final current = _selectedPath;
    if (current != null &&
        widget.candidates.any((candidate) => candidate.path == current)) {
      return;
    }
    _selectedPath = widget.candidates.firstOrNull?.path;
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
