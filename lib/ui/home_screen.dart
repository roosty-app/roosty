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
import '../theme/tokens.dart';
import 'desktop_lifecycle.dart';
import 'desktop_mini_card_window_host.dart';
import 'desktop_tray_bridge.dart';
import 'mini_card_window.dart';
import 'nest/nest_footer.dart';
import 'nest/nest_header.dart';
import 'nest/nest_settings.dart';
import 'nest/nest_stage.dart';

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

    final tokens = context.roostyTokens;

    return Stack(
      children: [
        Scaffold(
          body: Column(
            children: [
              const NestHeader(),
              Expanded(
                child: appConfig.when(
                  data: (config) {
                    _syncVaultController(config, isAndroid: isAndroid);
                    _syncLlmControllers(config.llm);
                    final showVaultDiscovery =
                        !isAndroid &&
                        (_forceShowVaultDiscovery ||
                            (config.vaultPath?.trim().isEmpty ?? true));
                    return _NestBody(
                      config: config,
                      effectiveClipboardWatching: effectiveClipboardWatching,
                      showVaultDiscovery: showVaultDiscovery,
                      vaultCandidates: vaultCandidates,
                      captureState: captureState,
                      vaultPathController: _vaultPathController,
                      llmBaseUrlController: _llmBaseUrlController,
                      llmApiKeyController: _llmApiKeyController,
                      llmModelController: _llmModelController,
                      manualUrlController: _manualUrlController,
                      tokens: tokens,
                      onChooseVault: () => _chooseVault(config),
                      onSaveVault: _saveVaultPath,
                      onRediscoverVaults: _rediscoverVaults,
                      onUseDiscoveredVault: _useDiscoveredVault,
                      onSaveLlm: _saveLlmConfig,
                      onRemoveBlockedDomain: _removeBlockedDomain,
                      onToggleClipboard: (enabled) {
                        ref
                            .read(
                              clipboardWatchingSessionOverrideProvider.notifier,
                            )
                            .clear();
                        ref
                            .read(appConfigControllerProvider.notifier)
                            .updateClipboardWatchingEnabled(enabled);
                      },
                      onManualArchive: _archiveManualUrl,
                      onExitApp: () => confirmExitRoosty(context),
                      onConfirmPending: () {
                        ref
                            .read(captureControllerProvider.notifier)
                            .archivePending();
                      },
                      onDismissPending: () {
                        ref
                            .read(captureControllerProvider.notifier)
                            .dismissPending();
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(child: Text('配置加载失败')),
                ),
              ),
            ],
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

  Future<void> _chooseVault(AppConfig config) async {
    // Android branch was removed in Phase 3 (brand visual reframe): the
    // desktop UI no longer surfaces the Android SAF flow. Mobile entry is
    // frozen per DECISIONS.md §移动端暂缓决策记录.
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

  Future<void> _saveVaultPath() async {
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

class _NestBody extends StatelessWidget {
  const _NestBody({
    required this.config,
    required this.effectiveClipboardWatching,
    required this.showVaultDiscovery,
    required this.vaultCandidates,
    required this.captureState,
    required this.vaultPathController,
    required this.llmBaseUrlController,
    required this.llmApiKeyController,
    required this.llmModelController,
    required this.manualUrlController,
    required this.tokens,
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
  final bool showVaultDiscovery;
  final AsyncValue<List<VaultCandidate>> vaultCandidates;
  final CaptureState captureState;
  final TextEditingController vaultPathController;
  final TextEditingController llmBaseUrlController;
  final TextEditingController llmApiKeyController;
  final TextEditingController llmModelController;
  final TextEditingController manualUrlController;
  final RoostyTokens tokens;
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
    final settingsForceExpanded =
        showVaultDiscovery || (config.vaultPath?.trim().isEmpty ?? true);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space6,
          vertical: tokens.space6,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: tokens.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NestStage(history: captureState.history),
                if (showVaultDiscovery) ...[
                  SizedBox(height: tokens.space6),
                  _VaultDiscoveryCard(
                    candidates: vaultCandidates,
                    onUseVault: onUseDiscoveredVault,
                    onChooseOther: onChooseVault,
                  ),
                ],
                if (captureState.pendingItem != null) ...[
                  SizedBox(height: tokens.space6),
                  _PendingCapture(
                    item: captureState.pendingItem!,
                    isArchiving: captureState.isArchiving,
                    onConfirm: onConfirmPending,
                    onDismiss: onDismissPending,
                  ),
                ],
                if (captureState.message != null) ...[
                  SizedBox(height: tokens.space3),
                  Text(
                    captureState.message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.success,
                        ),
                  ),
                ],
                SizedBox(height: tokens.space6),
                NestSettings(
                  config: config,
                  effectiveClipboardWatching: effectiveClipboardWatching,
                  captureState: captureState,
                  vaultPathController: vaultPathController,
                  llmBaseUrlController: llmBaseUrlController,
                  llmApiKeyController: llmApiKeyController,
                  llmModelController: llmModelController,
                  manualUrlController: manualUrlController,
                  forceExpanded: settingsForceExpanded,
                  onChooseVault: onChooseVault,
                  onSaveVault: onSaveVault,
                  onRediscoverVaults: onRediscoverVaults,
                  onSaveLlm: onSaveLlm,
                  onRemoveBlockedDomain: onRemoveBlockedDomain,
                  onToggleClipboard: onToggleClipboard,
                  onManualArchive: onManualArchive,
                ),
                SizedBox(height: tokens.space4),
                NestFooter(onExitApp: onExitApp),
              ],
            ),
          ),
        ),
      ),
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
    final tokens = context.roostyTokens;
    if (items.isEmpty) {
      return _VaultDiscoveryFrame(
        title: '未检测到 Obsidian',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('请选择一个目录作为归档库。'),
            SizedBox(height: tokens.space3),
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
                padding: EdgeInsets.symmetric(vertical: tokens.space2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check),
                    SizedBox(width: tokens.space2),
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
            SizedBox(height: tokens.space2),
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
    final tokens = context.roostyTokens;
    return Material(
      color: tokens.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        side: BorderSide(color: tokens.divider),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree_outlined, color: tokens.primary),
                SizedBox(width: tokens.space2),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space3),
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
    final tokens = context.roostyTokens;
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
        SizedBox(height: tokens.space2),
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
    final tokens = context.roostyTokens;
    return Material(
      color: tokens.primarySubtle,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Padding(
        padding: EdgeInsets.all(tokens.space4),
        child: Row(
          children: [
            Icon(Icons.link, color: tokens.primary),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Text(
                item.url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: tokens.space2),
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
