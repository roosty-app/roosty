import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../core/item.dart';
import 'fetcher.dart';

class WebFetcher implements Fetcher {
  WebFetcher({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void close() {
    _client.close();
  }

  @override
  bool canHandle(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Future<Item> fetch(Item item) async {
    final response = await _client.get(
      Uri.parse(item.url),
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/126.0 Safari/537.36 Roosty/1.0',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Unexpected status code ${response.statusCode}',
        Uri.parse(item.url),
      );
    }

    final document = html_parser.parse(response.body);
    final title = _firstNonEmpty([
      _meta(document, 'property', 'og:title'),
      _meta(document, 'name', 'twitter:title'),
      document.querySelector('title')?.text,
    ]);
    final author = _firstNonEmpty([
      _meta(document, 'name', 'author'),
      _meta(document, 'property', 'article:author'),
      _meta(document, 'name', 'byline'),
    ]);

    item.title = title ?? item.title ?? item.url;
    item.author = author ?? item.author;
    item.rawText = _extractBody(document) ?? item.rawText;
    return item;
  }

  String? _extractBody(Document document) {
    document
        .querySelectorAll(
          'script, style, noscript, nav, header, footer, aside, form',
        )
        .forEach((element) => element.remove());

    for (final selector in const [
      'article',
      'main',
      '[role="main"]',
      '.article',
      '.post',
      '.entry-content',
      '.content',
      'body',
    ]) {
      final element = document.querySelector(selector);
      final text = _extractReadableText(element);
      if (text != null && text.length >= 80) {
        return text;
      }
    }
    return _extractReadableText(document.body);
  }

  String? _meta(Document document, String attribute, String value) {
    return document
        .querySelector('meta[$attribute="$value"]')
        ?.attributes['content'];
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final cleaned = _cleanText(value);
      if (cleaned != null) {
        return cleaned;
      }
    }
    return null;
  }

  String? _cleanText(String? value) {
    final cleaned = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  String? _extractReadableText(Element? element) {
    if (element == null) {
      return null;
    }
    final blocks = <String>[];
    for (final block in element.querySelectorAll(
      'h1, h2, h3, h4, h5, h6, p, li, blockquote',
    )) {
      final text = _cleanText(block.text);
      if (text != null) {
        blocks.add(text);
      }
    }
    if (blocks.isNotEmpty) {
      return blocks.join('\n\n');
    }
    return _cleanText(element.text);
  }
}
