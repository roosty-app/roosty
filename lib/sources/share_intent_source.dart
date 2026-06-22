// v1: deferred — mobile/Android features are frozen but preserved.
// See DECISIONS.md §移动端暂缓决策记录 for restoration conditions.

import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../core/item.dart';
import '../core/source_platform.dart';
import 'clipboard_source.dart';
import 'source.dart';

class ShareIntentSource implements Source {
  ShareIntentSource({ReceiveSharingIntent? receiveSharingIntent})
    : _receiveSharingIntent =
          receiveSharingIntent ?? ReceiveSharingIntent.instance;

  final ReceiveSharingIntent _receiveSharingIntent;

  @override
  Stream<Item> watch() {
    late StreamController<Item> controller;
    StreamSubscription<List<SharedMediaFile>>? subscription;

    Future<void> emitFiles(List<SharedMediaFile> files) async {
      for (final item in itemsFromSharedMedia(files)) {
        if (!controller.isClosed) {
          controller.add(item);
        }
      }
    }

    controller = StreamController<Item>(
      onListen: () {
        subscription = _receiveSharingIntent.getMediaStream().listen(
          emitFiles,
          onError: controller.addError,
        );
        unawaited(_emitInitialMedia(controller, emitFiles));
      },
      onCancel: () => subscription?.cancel(),
    );

    return controller.stream;
  }

  Future<void> _emitInitialMedia(
    StreamController<Item> controller,
    Future<void> Function(List<SharedMediaFile> files) emitFiles,
  ) async {
    try {
      final files = await _receiveSharingIntent.getInitialMedia();
      await emitFiles(files);
      if (files.isNotEmpty) {
        await _receiveSharingIntent.reset();
      }
    } catch (error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    }
  }
}

List<Item> itemsFromSharedMedia(List<SharedMediaFile> files) {
  return files
      .map(itemFromSharedMedia)
      .whereType<Item>()
      .toList(growable: false);
}

Item? itemFromSharedMedia(SharedMediaFile file) {
  final text = [file.path, file.message]
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .join('\n')
      .trim();
  if (text.isEmpty) {
    return null;
  }

  final url = extractFirstUrl(text);
  if (url != null) {
    return Item(url: url, source: detectSourcePlatform(url));
  }

  final capturedAt = DateTime.now();
  return Item(
    url: 'roosty://shared-text/${capturedAt.microsecondsSinceEpoch}',
    title: _titleFromText(text),
    source: 'web',
    rawText: text,
    capturedAt: capturedAt,
  );
}

String _titleFromText(String text) {
  final firstLine = text
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '分享文本');
  return firstLine.length <= 40
      ? firstLine
      : '${firstLine.substring(0, 40)}...';
}
