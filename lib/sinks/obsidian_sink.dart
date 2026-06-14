import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/item.dart';
import '../core/pipeline.dart';
import 'sink.dart';

class ObsidianSink implements Sink {
  ObsidianSink({required this.vaultPath});

  final String vaultPath;

  @override
  Future<void> write(Item item) async {
    final directory = Directory(p.join(vaultPath, 'Roosty'));
    await directory.create(recursive: true);

    final file = await _nextAvailableFile(directory, item);
    await file.writeAsString(renderMarkdown(item));
  }

  Future<File> _nextAvailableFile(Directory directory, Item item) async {
    final title = sanitizeFileName(item.title ?? item.url);
    final date = _formatDate(item.capturedAt);
    final baseName = '$date-$title';
    var candidate = File(p.join(directory.path, '$baseName.md'));
    var suffix = 2;
    while (await candidate.exists()) {
      candidate = File(p.join(directory.path, '$baseName-$suffix.md'));
      suffix += 1;
    }
    return candidate;
  }
}

String renderMarkdown(Item item) {
  final title = item.title?.trim().isNotEmpty == true
      ? item.title!.trim()
      : item.url;
  final author = item.author?.trim() ?? '';
  final summary = item.summary?.trim() ?? '';
  final body = item.rawText?.trim().isNotEmpty == true
      ? item.rawText!.trim()
      : fallbackBody;

  return '''
---
title: "${_yamlDoubleQuoted(title)}"
source: ${item.source}
url: ${item.url}
author: "${_yamlDoubleQuoted(author)}"
captured: ${formatDateTimeWithOffset(item.capturedAt)}
summary: "${_yamlDoubleQuoted(summary)}"
tags: [${item.tags.join(', ')}]
status: ${item.status}
---

# $title

> 来源：网页 · [原文链接](${item.url})

## 摘要
$summary

## 原文
$body
''';
}

String sanitizeFileName(String value) {
  final sanitized = value
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .trim();
  return sanitized.isEmpty ? 'untitled' : sanitized;
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String formatDateTimeWithOffset(DateTime value) {
  final local = value.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final absoluteOffset = offset.abs();
  final offsetHours = absoluteOffset.inHours.toString().padLeft(2, '0');
  final offsetMinutes = (absoluteOffset.inMinutes % 60).toString().padLeft(
    2,
    '0',
  );
  return '${local.toIso8601String()}$sign$offsetHours:$offsetMinutes';
}

String _yamlDoubleQuoted(String value) {
  return value.replaceAll('\\', r'\\').replaceAll('"', r'\"');
}
