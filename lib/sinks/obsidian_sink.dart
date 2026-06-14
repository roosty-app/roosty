import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/item.dart';
import '../core/pipeline.dart';
import 'android_saf_vault.dart';
import 'sink.dart';

class ObsidianSink implements Sink {
  ObsidianSink({required String vaultPath})
    : _fileSystemWriter = _FileSystemVaultWriter(vaultPath),
      _androidWriter = null;

  ObsidianSink.android({
    required String vaultUri,
    AndroidSafVault androidSaf = const AndroidSafVault(),
  }) : _fileSystemWriter = null,
       _androidWriter = _AndroidSafVaultWriter(
         vaultUri: vaultUri,
         androidSaf: androidSaf,
       );

  final _FileSystemVaultWriter? _fileSystemWriter;
  final _AndroidSafVaultWriter? _androidWriter;

  @override
  Future<void> write(Item item) async {
    final fileName = buildMarkdownFileName(item);
    final content = renderMarkdown(item);
    final androidWriter = _androidWriter;
    if (androidWriter != null) {
      await androidWriter.write(fileName: fileName, content: content);
      return;
    }

    await _fileSystemWriter!.write(fileName: fileName, content: content);
  }
}

class _FileSystemVaultWriter {
  _FileSystemVaultWriter(this.vaultPath);

  final String vaultPath;

  Future<void> write({
    required String fileName,
    required String content,
  }) async {
    final directory = Directory(p.join(vaultPath, roostyVaultDirectoryName));
    await directory.create(recursive: true);

    final file = await _nextAvailableFile(directory, fileName);
    await file.writeAsString(content);
  }

  Future<File> _nextAvailableFile(Directory directory, String fileName) async {
    final extension = p.extension(fileName);
    final baseName = p.basenameWithoutExtension(fileName);
    var candidate = File(p.join(directory.path, fileName));
    var suffix = 2;
    while (await candidate.exists()) {
      candidate = File(p.join(directory.path, '$baseName-$suffix$extension'));
      suffix += 1;
    }
    return candidate;
  }
}

class _AndroidSafVaultWriter {
  _AndroidSafVaultWriter({required this.vaultUri, required this.androidSaf});

  final String vaultUri;
  final AndroidSafVault androidSaf;

  Future<void> write({
    required String fileName,
    required String content,
  }) async {
    await androidSaf.writeTextFile(
      treeUri: vaultUri,
      directoryName: roostyVaultDirectoryName,
      fileName: fileName,
      content: content,
    );
  }
}

const roostyVaultDirectoryName = 'Roosty';

String buildMarkdownFileName(Item item) {
  final title = sanitizeFileName(item.title ?? item.url);
  final date = _formatDate(item.capturedAt);
  return '$date-$title.md';
}

String renderMarkdown(Item item) {
  final title = item.title?.trim().isNotEmpty == true
      ? item.title!.trim()
      : item.url;
  final author = item.author?.trim() ?? '';
  final summary = item.summary?.trim() ?? '';
  final frontmatterSummary = _frontmatterSummary(summary);
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
summary: "${_yamlDoubleQuoted(frontmatterSummary)}"
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

String _frontmatterSummary(String value) {
  for (final line in value.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.replaceFirst(RegExp(r'^-\s*'), '');
    }
  }
  return '';
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
