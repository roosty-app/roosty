import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../config/config_providers.dart';
import '../fetchers/web_fetcher.dart';
import '../processors/llm_client.dart';
import '../processors/summarize_processor.dart';
import '../sinks/android_saf_vault.dart';
import '../sinks/obsidian_sink.dart';
import '../sources/clipboard_source.dart';
import '../sources/share_intent_source.dart';
import 'item.dart';
import 'mini_card.dart';
import 'pipeline.dart';
import 'source_platform.dart';
import 'url_rules.dart';

// v1: deferred — isAndroidProvider always returns false on desktop builds.
// Mobile branch is preserved for future restoration; see DECISIONS.md §移动端暂缓决策记录.
final isAndroidProvider = Provider<bool>((ref) {
  return Platform.isAndroid;
});

final isWindowsProvider = Provider<bool>((ref) {
  return Platform.isWindows;
});

final nowProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final clipboardSourceProvider = Provider<ClipboardSource>((ref) {
  return ClipboardSource();
});

// v1: deferred — share-intent is a mobile-only entrypoint, never instantiated on desktop.
final shareIntentSourceProvider = Provider<ShareIntentSource>((ref) {
  return ShareIntentSource();
});

// v1: deferred — Android SAF vault provider; desktop ObsidianSink never calls this.
final androidSafVaultProvider = Provider<AndroidSafVault>((ref) {
  return const AndroidSafVault();
});

final webFetcherProvider = Provider<WebFetcher>((ref) {
  final fetcher = WebFetcher();
  ref.onDispose(fetcher.close);
  return fetcher;
});

final summarizeProcessorProvider = Provider<SummarizeProcessor>((ref) {
  final llmConfig =
      ref.watch(appConfigControllerProvider).value?.llm ?? const LlmConfig();
  final processor = SummarizeProcessor(
    config: llmConfig,
    client: LlmClient(config: llmConfig),
  );
  ref.onDispose(processor.close);
  return processor;
});

final pipelineProvider = Provider<Pipeline>((ref) {
  final config = ref.watch(appConfigControllerProvider).value;
  final isAndroid = ref.watch(isAndroidProvider);
  final sink = _buildObsidianSink(
    config: config,
    isAndroid: isAndroid,
    androidSaf: ref.watch(androidSafVaultProvider),
  );
  return Pipeline(
    fetchers: [ref.watch(webFetcherProvider)],
    processors: [ref.watch(summarizeProcessorProvider)],
    sinks: sink == null ? const [] : [sink],
  );
});

ObsidianSink? _buildObsidianSink({
  required AppConfig? config,
  required bool isAndroid,
  required AndroidSafVault androidSaf,
}) {
  if (config == null) {
    return null;
  }
  if (isAndroid) {
    final vaultUri = config.androidVaultUri;
    return vaultUri == null || vaultUri.trim().isEmpty
        ? null
        : ObsidianSink.android(vaultUri: vaultUri, androidSaf: androidSaf);
  }
  final vaultPath = config.vaultPath;
  return vaultPath == null || vaultPath.trim().isEmpty
      ? null
      : ObsidianSink(vaultPath: vaultPath);
}

final captureControllerProvider =
    NotifierProvider<CaptureController, CaptureState>(CaptureController.new);

final historyProvider = Provider<List<Item>>((ref) {
  return ref.watch(captureControllerProvider).history;
});

final miniCardControllerProvider =
    NotifierProvider<MiniCardController, MiniCardState>(MiniCardController.new);

final clipboardWatchingSessionOverrideProvider =
    NotifierProvider<ClipboardWatchingSessionOverrideController, bool?>(
      ClipboardWatchingSessionOverrideController.new,
    );

final effectiveClipboardWatchingProvider = Provider<bool>((ref) {
  final configured =
      ref.watch(appConfigControllerProvider).value?.clipboardWatchingEnabled ??
      false;
  return ref.watch(clipboardWatchingSessionOverrideProvider) ?? configured;
});

class ClipboardWatchingSessionOverrideController extends Notifier<bool?> {
  @override
  bool? build() => null;

  void setEnabledForSession(bool enabled) {
    state = enabled;
  }

  void clear() {
    state = null;
  }
}

class CaptureState {
  const CaptureState({
    this.pendingItem,
    this.history = const [],
    this.isArchiving = false,
    this.message,
  });

  final Item? pendingItem;
  final List<Item> history;
  final bool isArchiving;
  final String? message;

  CaptureState copyWith({
    Item? pendingItem,
    List<Item>? history,
    bool? isArchiving,
    String? message,
    bool clearPendingItem = false,
    bool clearMessage = false,
  }) {
    return CaptureState(
      pendingItem: clearPendingItem ? null : pendingItem ?? this.pendingItem,
      history: history ?? this.history,
      isArchiving: isArchiving ?? this.isArchiving,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class CaptureController extends Notifier<CaptureState> {
  StreamSubscription<Item>? _clipboardSubscription;
  StreamSubscription<Item>? _shareIntentSubscription;

  @override
  CaptureState build() {
    ref.onDispose(() {
      _clipboardSubscription?.cancel();
      _shareIntentSubscription?.cancel();
    });
    ref.listen(effectiveClipboardWatchingProvider, (_, enabled) {
      _syncClipboardWatching(enabled);
    }, fireImmediately: true);
    _syncShareIntentWatching(ref.watch(isAndroidProvider));
    return const CaptureState();
  }

  void queue(Item item) {
    state = state.copyWith(pendingItem: item, message: '捕获到链接，确认后归巢');
  }

  void dismissPending() {
    state = state.copyWith(clearPendingItem: true, clearMessage: true);
  }

  void showMessage(String message) {
    state = state.copyWith(message: message);
  }

  Future<void> archivePending() async {
    final item = state.pendingItem;
    if (item == null) {
      return;
    }
    await archive(item);
  }

  Future<void> archive(Item item) async {
    await _archiveWith(() => ref.read(pipelineProvider).run(item));
  }

  Future<void> archiveMiniCard(String cardId) async {
    final item = ref
        .read(miniCardControllerProvider.notifier)
        .takeForArchive(cardId);
    if (item == null) {
      return;
    }
    await _archiveWith(() async {
      final archived = await item;
      await ref.read(pipelineProvider).write(archived);
      return archived;
    });
  }

  Future<void> _archiveWith(Future<Item> Function() archiveAction) async {
    final config = ref.read(appConfigControllerProvider).value;
    if (!_hasWritableVault(config)) {
      state = state.copyWith(message: '请先设置 Obsidian vault 目录');
      return;
    }

    state = state.copyWith(isArchiving: true, message: '正在归巢...');
    try {
      final archived = await archiveAction();
      state = state.copyWith(
        history: [archived, ...state.history],
        isArchiving: false,
        clearPendingItem: true,
        message: '已归巢：${archived.title ?? archived.url}',
      );
    } catch (error) {
      state = state.copyWith(isArchiving: false, message: '归巢失败：$error');
    }
  }

  Future<void> archiveShared(Item item) async {
    await archive(item);
  }

  void handleClipboardCapture(Item item) {
    if (ref.read(isWindowsProvider)) {
      ref.read(miniCardControllerProvider.notifier).show(item);
      return;
    }
    queue(item);
  }

  void _syncClipboardWatching(bool enabled) {
    if (!enabled) {
      _clipboardSubscription?.cancel();
      _clipboardSubscription = null;
      return;
    }
    _clipboardSubscription ??= ref
        .read(clipboardSourceProvider)
        .watch()
        .listen(handleClipboardCapture);
  }

  void _syncShareIntentWatching(bool enabled) {
    if (!enabled) {
      _shareIntentSubscription?.cancel();
      _shareIntentSubscription = null;
      return;
    }
    _shareIntentSubscription ??= ref
        .read(shareIntentSourceProvider)
        .watch()
        .listen(archiveShared);
  }

  bool _hasWritableVault(AppConfig? config) {
    if (config == null) {
      return false;
    }
    if (ref.read(isAndroidProvider)) {
      return config.androidVaultUri?.trim().isNotEmpty == true;
    }
    return config.vaultPath?.trim().isNotEmpty == true;
  }
}

class MiniCardController extends Notifier<MiniCardState> {
  static const maxCards = 3;
  static const ignoreTtl = Duration(minutes: 30);

  final Map<String, DateTime> _ignoredUrls = {};
  final Map<String, Future<Item>> _enrichedItems = {};

  @override
  MiniCardState build() {
    ref.onDispose(() {
      _ignoredUrls.clear();
      _enrichedItems.clear();
    });
    return const MiniCardState();
  }

  void show(Item item) {
    _cleanupIgnoredUrls();
    final config = ref.read(appConfigControllerProvider).value;
    if (_isIgnored(item.url) ||
        isDomainBlocked(item.url, config?.domainBlocklist ?? const [])) {
      return;
    }

    item.source = detectSourcePlatform(item.url);
    final now = ref.read(nowProvider)();
    final id = 'mini-${now.microsecondsSinceEpoch}-${state.cards.length}';
    final card = MiniCardModel(id: id, item: item, createdAt: now);
    final cards = [...state.cards];
    if (cards.length >= maxCards) {
      final overflow = cards.removeAt(0);
      _rememberIgnored(overflow.item.url);
      _enrichedItems.remove(overflow.id);
    }
    state = state.copyWith(cards: [...cards, card]);
    _enrichedItems[id] = _enrich(id, item);
  }

  Future<Item>? takeForArchive(String cardId) {
    final card = _cardById(cardId);
    if (card == null) {
      return null;
    }
    _removeCard(cardId);
    return _enrichedItems.remove(cardId) ?? Future<Item>.value(card.item);
  }

  void ignoreOnce(String cardId) {
    final card = _cardById(cardId);
    if (card == null) {
      return;
    }
    _rememberIgnored(card.item.url);
    _enrichedItems.remove(cardId);
    _removeCard(cardId);
  }

  Future<void> blockDomain(String cardId) async {
    final card = _cardById(cardId);
    if (card == null) {
      return;
    }
    final domain = extractDomain(card.item.url);
    _enrichedItems.remove(cardId);
    _removeCard(cardId);
    if (domain != null) {
      await ref
          .read(appConfigControllerProvider.notifier)
          .addDomainToBlocklist(domain);
    }
  }

  bool isUrlIgnored(String url) {
    _cleanupIgnoredUrls();
    return _isIgnored(url);
  }

  Future<Item> _enrich(String cardId, Item item) async {
    try {
      final enriched = await ref.read(pipelineProvider).enrich(item);
      _updateCard(
        cardId,
        (card) => card.copyWith(item: enriched, status: MiniCardStatus.ready),
      );
      return enriched;
    } catch (error) {
      _updateCard(
        cardId,
        (card) =>
            card.copyWith(status: MiniCardStatus.failed, message: '预览失败，仍可归巢'),
      );
      return item;
    }
  }

  void _updateCard(
    String cardId,
    MiniCardModel Function(MiniCardModel card) update,
  ) {
    final cards = [
      for (final card in state.cards) card.id == cardId ? update(card) : card,
    ];
    state = state.copyWith(cards: cards);
  }

  MiniCardModel? _cardById(String cardId) {
    for (final card in state.cards) {
      if (card.id == cardId) {
        return card;
      }
    }
    return null;
  }

  void _removeCard(String cardId) {
    state = state.copyWith(
      cards: state.cards.where((card) => card.id != cardId).toList(),
    );
  }

  void _rememberIgnored(String url) {
    _ignoredUrls[url] = ref.read(nowProvider)();
  }

  bool _isIgnored(String url) {
    final ignoredAt = _ignoredUrls[url];
    if (ignoredAt == null) {
      return false;
    }
    return ref.read(nowProvider)().difference(ignoredAt) < ignoreTtl;
  }

  void _cleanupIgnoredUrls() {
    final now = ref.read(nowProvider)();
    _ignoredUrls.removeWhere(
      (_, ignoredAt) => now.difference(ignoredAt) >= ignoreTtl,
    );
  }
}
