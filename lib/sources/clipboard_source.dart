import 'dart:async';

import 'package:super_clipboard/super_clipboard.dart';

import '../core/item.dart';
import 'source.dart';

typedef ClipboardTextReader = Future<String?> Function();

class ClipboardSource implements Source {
  ClipboardSource({
    ClipboardTextReader? reader,
    this.pollInterval = const Duration(seconds: 1),
    this.dedupeWindow = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _reader = reader ?? _readSystemClipboardText,
       _now = now ?? DateTime.now;

  final ClipboardTextReader _reader;
  final Duration pollInterval;
  final Duration dedupeWindow;
  final DateTime Function() _now;

  final Map<String, DateTime> _seenUrls = {};

  @override
  Stream<Item> watch() async* {
    while (true) {
      final text = await _safeReadText();
      final url = extractFirstUrl(text);
      if (url != null && _shouldEmit(url)) {
        yield Item(url: url);
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  Future<String?> _safeReadText() async {
    try {
      return await _reader();
    } catch (_) {
      return null;
    }
  }

  bool _shouldEmit(String url) {
    final now = _now();
    _seenUrls.removeWhere((_, seenAt) => now.difference(seenAt) > dedupeWindow);
    final seenAt = _seenUrls[url];
    if (seenAt != null && now.difference(seenAt) <= dedupeWindow) {
      return false;
    }
    _seenUrls[url] = now;
    return true;
  }
}

String? extractFirstUrl(String? text) {
  if (text == null || text.trim().isEmpty) {
    return null;
  }
  final match = RegExp(r'https?://[^\s<>"\]\)]+').firstMatch(text);
  return match?.group(0);
}

Future<String?> _readSystemClipboardText() async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    return null;
  }
  final reader = await clipboard.read();
  final uri = await reader.readValue(Formats.uri);
  if (uri != null) {
    return uri.uri.toString();
  }
  return reader.readValue(Formats.plainText);
}
