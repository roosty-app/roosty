import 'dart:convert';
import 'dart:developer' as developer;

import '../config/app_config.dart';
import '../core/item.dart';
import 'llm_client.dart';
import 'processor.dart';

class SummarizeProcessor implements Processor {
  SummarizeProcessor({
    required this.config,
    required LlmClient client,
    this.maxContentLength = 12000,
  }) : _client = client;

  final LlmConfig config;
  final int maxContentLength;
  final LlmClient _client;

  @override
  Future<Item> process(Item item) async {
    final rawText = item.rawText?.trim();
    if (!config.isConfigured || rawText == null || rawText.isEmpty) {
      return item;
    }

    try {
      final content = await _client.complete([
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': _buildUserPrompt(item, rawText)},
      ]);
      final summary = _parseSummary(content);
      item.summary = _formatSummary(summary);
      item.tags = _mergeTags(item.tags, summary.tags);
    } catch (error, stackTrace) {
      developer.log(
        'SummarizeProcessor skipped.',
        name: 'roosty.processors',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return item;
  }

  void close() {
    _client.close();
  }

  String _buildUserPrompt(Item item, String rawText) {
    final content = rawText.length <= maxContentLength
        ? rawText
        : '${rawText.substring(0, maxContentLength)}\n\n[Content truncated]';
    return '''
Title: ${item.title ?? ''}
URL: ${item.url}

Content:
$content
''';
  }

  _SummaryResult _parseSummary(String content) {
    final jsonText = _extractJsonObject(content);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Summary response must be a JSON object.');
    }

    final summary = decoded['summary'];
    if (summary is! String || summary.trim().isEmpty) {
      throw const FormatException('Summary response has no summary.');
    }

    return _SummaryResult(
      summary: summary.trim(),
      highlights: _stringList(
        decoded['highlights'] ?? decoded['points'] ?? decoded['bullet_points'],
      ),
      tags: _stringList(decoded['tags']),
    );
  }

  String _extractJsonObject(String value) {
    final trimmed = value.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('Summary response has no JSON object.');
    }
    return trimmed.substring(start, end + 1);
  }

  List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  String _formatSummary(_SummaryResult summary) {
    final highlights = summary.highlights.take(5).toList();
    if (highlights.isEmpty) {
      return summary.summary;
    }
    return [
      summary.summary,
      '',
      ...highlights.map((highlight) => '- $highlight'),
    ].join('\n');
  }

  List<String> _mergeTags(
    List<String> currentTags,
    List<String> generatedTags,
  ) {
    final result = <String>[];
    void addTag(String tag) {
      if (tag.isNotEmpty && !result.contains(tag)) {
        result.add(tag);
      }
    }

    if (!currentTags.contains('roosty/inbox')) {
      addTag('roosty/inbox');
    }
    for (final tag in currentTags) {
      addTag(tag);
    }
    for (final tag in generatedTags.take(4)) {
      addTag(_normalizeTag(tag));
    }
    return result;
  }

  String _normalizeTag(String tag) {
    var normalized = tag
        .trim()
        .replaceFirst(RegExp(r'^#+'), '')
        .replaceFirst(RegExp(r'^roosty/'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[\[\],]'), '')
        .toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'^/+|/+$'), '');
    return normalized.isEmpty ? '' : 'roosty/$normalized';
  }
}

class _SummaryResult {
  const _SummaryResult({
    required this.summary,
    required this.highlights,
    required this.tags,
  });

  final String summary;
  final List<String> highlights;
  final List<String> tags;
}

const _systemPrompt = '''
You are Roosty's summarization processor.
Return only one JSON object with this exact shape:
{"summary":"one sentence","highlights":["point 1","point 2","point 3"],"tags":["tag1","tag2"]}

Rules:
- Use the same language as the source content.
- summary must be one concise sentence.
- highlights must contain 3 to 5 concise points.
- tags must contain 2 to 4 short labels without the roosty/ prefix.
''';
