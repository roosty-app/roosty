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
import 'pipeline.dart';

final isAndroidProvider = Provider<bool>((ref) {
  return Platform.isAndroid;
});

final clipboardSourceProvider = Provider<ClipboardSource>((ref) {
  return ClipboardSource();
});

final shareIntentSourceProvider = Provider<ShareIntentSource>((ref) {
  return ShareIntentSource();
});

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
    ref.listen(appConfigControllerProvider, (_, next) {
      _syncClipboardWatching(next.value?.clipboardWatchingEnabled ?? false);
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
    final config = ref.read(appConfigControllerProvider).value;
    if (!_hasWritableVault(config)) {
      state = state.copyWith(message: '请先设置 Obsidian vault 目录');
      return;
    }

    state = state.copyWith(isArchiving: true, message: '正在归巢...');
    try {
      final archived = await ref.read(pipelineProvider).run(item);
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

  void _syncClipboardWatching(bool enabled) {
    if (!enabled) {
      _clipboardSubscription?.cancel();
      _clipboardSubscription = null;
      return;
    }
    _clipboardSubscription ??= ref
        .read(clipboardSourceProvider)
        .watch()
        .listen(queue);
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
