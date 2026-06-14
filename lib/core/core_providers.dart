import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config_providers.dart';
import '../fetchers/web_fetcher.dart';
import '../processors/pass_through_processor.dart';
import '../sinks/obsidian_sink.dart';
import '../sources/clipboard_source.dart';
import 'item.dart';
import 'pipeline.dart';

final clipboardSourceProvider = Provider<ClipboardSource>((ref) {
  return ClipboardSource();
});

final webFetcherProvider = Provider<WebFetcher>((ref) {
  final fetcher = WebFetcher();
  ref.onDispose(fetcher.close);
  return fetcher;
});

final pipelineProvider = Provider<Pipeline>((ref) {
  final config = ref.watch(appConfigControllerProvider).value;
  final vaultPath = config?.vaultPath;
  return Pipeline(
    fetchers: [ref.watch(webFetcherProvider)],
    processors: const [PassThroughProcessor()],
    sinks: vaultPath == null || vaultPath.trim().isEmpty
        ? const []
        : [ObsidianSink(vaultPath: vaultPath)],
  );
});

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

  @override
  CaptureState build() {
    ref.onDispose(() {
      _clipboardSubscription?.cancel();
    });
    ref.listen(appConfigControllerProvider, (_, next) {
      _syncClipboardWatching(next.value?.clipboardWatchingEnabled ?? false);
    }, fireImmediately: true);
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
    if (config?.vaultPath == null || config!.vaultPath!.trim().isEmpty) {
      state = state.copyWith(message: '请先设置 Obsidian vault 路径');
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
}
