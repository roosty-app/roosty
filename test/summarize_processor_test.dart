import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roosty/config/app_config.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/processors/llm_client.dart';
import 'package:roosty/processors/summarize_processor.dart';

void main() {
  test('summarizes content and namespaces generated tags', () async {
    final processor = SummarizeProcessor(
      config: const LlmConfig(
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'secret-key',
        model: 'deepseek-chat',
      ),
      client: LlmClient(
        config: const LlmConfig(
          baseUrl: 'https://api.deepseek.com',
          apiKey: 'secret-key',
          model: 'deepseek-chat',
        ),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': jsonEncode({
                      'summary': '这篇文章讲的是摘要接入。',
                      'highlights': ['先总结主旨', '再列要点', '最后给标签'],
                      'tags': ['AI', '摘要', 'Inbox'],
                    }),
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
    );

    final item = Item(
      url: 'https://example.com',
      title: '示例文章',
      rawText: '正文内容\n\n第二段',
      tags: ['roosty/inbox', 'roosty/existing'],
    );

    final result = await processor.process(item);

    expect(result.summary, contains('这篇文章讲的是摘要接入。'));
    expect(result.summary, contains('- 先总结主旨'));
    expect(result.summary, contains('- 再列要点'));
    expect(result.summary, contains('- 最后给标签'));
    expect(result.tags, [
      'roosty/inbox',
      'roosty/existing',
      'roosty/ai',
      'roosty/摘要',
    ]);
  });

  test('skips when raw text is empty or config is not ready', () async {
    var called = false;
    final processor = SummarizeProcessor(
      config: const LlmConfig(),
      client: LlmClient(
        config: const LlmConfig(),
        client: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
      ),
    );

    final item = Item(url: 'https://example.com', rawText: '');

    final result = await processor.process(item);

    expect(called, isFalse);
    expect(result.summary, isNull);
    expect(result.tags, ['roosty/inbox']);
  });

  test('logs and keeps going when the LLM call fails', () async {
    final processor = SummarizeProcessor(
      config: const LlmConfig(
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'secret-key',
        model: 'deepseek-chat',
      ),
      client: LlmClient(
        config: const LlmConfig(
          baseUrl: 'https://api.deepseek.com',
          apiKey: 'secret-key',
          model: 'deepseek-chat',
        ),
        client: MockClient((_) async => throw Exception('boom')),
      ),
    );

    final item = Item(url: 'https://example.com', rawText: '正文内容');

    final result = await processor.process(item);

    expect(result.summary, isNull);
    expect(result.tags, ['roosty/inbox']);
  });
}
