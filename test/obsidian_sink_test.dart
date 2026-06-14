import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/core/pipeline.dart';
import 'package:roosty/sinks/android_saf_vault.dart';
import 'package:roosty/sinks/obsidian_sink.dart';

void main() {
  test('sanitizes Windows-invalid characters while keeping Chinese text', () {
    expect(sanitizeFileName('标题: A/B*C? "x" <y>|'), '标题-ABC-x-y');
  });

  test('renders markdown schema with fallback body', () {
    final item = Item(
      url: 'https://example.com/a',
      title: 'Example "Title"',
      author: 'Author',
      capturedAt: DateTime.utc(2026, 6, 14, 4, 30),
    );

    final markdown = renderMarkdown(item);

    expect(markdown, contains('title: "Example \\"Title\\""'));
    expect(markdown, contains('source: web'));
    expect(markdown, contains('url: https://example.com/a'));
    expect(markdown, contains('summary: ""'));
    expect(markdown, contains('tags: [roosty/inbox]'));
    expect(markdown, contains('status: unread'));
    expect(markdown, contains('# Example "Title"'));
    expect(markdown, contains(fallbackBody));
  });

  test(
    'keeps frontmatter summary on one line while body can stay detailed',
    () {
      final item = Item(
        url: 'https://example.com/a',
        title: 'Example Title',
        summary: '一句话摘要\n\n- 要点一\n- 要点二',
      );

      final markdown = renderMarkdown(item);

      expect(markdown, contains('summary: "一句话摘要"'));
      expect(markdown, contains('## 摘要'));
      expect(markdown, contains('- 要点一'));
      expect(markdown, contains('- 要点二'));
    },
  );

  test(
    'writes markdown under Roosty and appends suffix on duplicate',
    () async {
      final temp = await Directory.systemTemp.createTemp('roosty_sink_test_');
      addTearDown(() => temp.delete(recursive: true));
      final sink = ObsidianSink(vaultPath: temp.path);
      final item = Item(
        url: 'https://example.com',
        title: '中文 标题',
        rawText: 'Body',
        capturedAt: DateTime(2026, 6, 14),
      );

      await sink.write(item);
      await sink.write(item);

      final outputDir = Directory(
        '${temp.path}${Platform.pathSeparator}Roosty',
      );
      final names = outputDir
          .listSync()
          .map((entity) => entity.uri.pathSegments.last)
          .toList();
      names.sort();

      expect(names, ['2026-06-14-中文-标题-2.md', '2026-06-14-中文-标题.md']);
    },
  );

  test('writes markdown through Android SAF vault writer', () async {
    final saf = _RecordingAndroidSafVault();
    final sink = ObsidianSink.android(
      vaultUri: 'content://tree/vault',
      androidSaf: saf,
    );
    final item = Item(
      url: 'https://example.com',
      title: 'Example',
      rawText: 'Body',
      capturedAt: DateTime(2026, 6, 14),
    );

    await sink.write(item);

    expect(saf.treeUri, 'content://tree/vault');
    expect(saf.directoryName, roostyVaultDirectoryName);
    expect(saf.fileName, '2026-06-14-Example.md');
    expect(saf.content, contains('url: https://example.com'));
  });
}

class _RecordingAndroidSafVault extends AndroidSafVault {
  String? treeUri;
  String? directoryName;
  String? fileName;
  String? content;

  @override
  Future<String?> pickDirectory() async => null;

  @override
  Future<String> writeTextFile({
    required String treeUri,
    required String directoryName,
    required String fileName,
    required String content,
  }) async {
    this.treeUri = treeUri;
    this.directoryName = directoryName;
    this.fileName = fileName;
    this.content = content;
    return fileName;
  }
}
