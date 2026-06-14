import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class LlmClient {
  LlmClient({
    required this.config,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  final LlmConfig config;
  final Duration timeout;
  final http.Client _client;

  Future<String> complete(List<Map<String, String>> messages) async {
    final baseUrl = config.baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/chat/completions');
    final response = await _client
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ${config.apiKey.trim()}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': config.model.trim(),
            'messages': messages,
          }),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Unexpected status code ${response.statusCode}',
        uri,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('LLM response must be a JSON object.');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('LLM response has no choices.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      throw const FormatException('LLM choice must be a JSON object.');
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw const FormatException('LLM choice has no message.');
    }

    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const FormatException('LLM message content is empty.');
    }
    return content;
  }

  void close() {
    _client.close();
  }
}
