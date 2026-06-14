import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roosty/config/app_config.dart';
import 'package:roosty/processors/llm_client.dart';

void main() {
  test('posts OpenAI compatible chat completions requests', () async {
    late http.Request capturedRequest;
    final client = LlmClient(
      config: const LlmConfig(
        baseUrl: 'https://api.deepseek.com/',
        apiKey: 'secret-key',
        model: 'deepseek-chat',
      ),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': '{"summary":"一句话摘要"}'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final content = await client.complete([
      {'role': 'system', 'content': 'system'},
      {'role': 'user', 'content': 'user'},
    ]);

    expect(content, '{"summary":"一句话摘要"}');
    expect(capturedRequest.method, 'POST');
    expect(
      capturedRequest.url.toString(),
      'https://api.deepseek.com/chat/completions',
    );
    expect(capturedRequest.headers['Authorization'], 'Bearer secret-key');
    expect(capturedRequest.headers['Content-Type'], 'application/json');

    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(body['model'], 'deepseek-chat');
    expect(body['messages'], [
      {'role': 'system', 'content': 'system'},
      {'role': 'user', 'content': 'user'},
    ]);
  });
}
