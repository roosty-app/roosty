import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/fetchers/web_fetcher.dart';

void main() {
  test('handles ordinary http and https URLs', () {
    final fetcher = WebFetcher(
      client: MockClient((_) async => http.Response('', 200)),
    );

    expect(fetcher.canHandle('https://example.com'), isTrue);
    expect(fetcher.canHandle('http://example.com'), isTrue);
    expect(fetcher.canHandle('file:///tmp/a'), isFalse);
  });

  test('extracts title, author, and article body', () async {
    final fetcher = WebFetcher(
      client: MockClient(
        (_) async => http.Response('''
<html>
  <head>
    <meta property="og:title" content="OG title">
    <meta name="author" content="Alice">
  </head>
  <body>
    <article>
      ${'This is article body. ' * 10}
    </article>
  </body>
</html>
''', 200),
      ),
    );

    final item = await fetcher.fetch(Item(url: 'https://example.com'));

    expect(item.title, 'OG title');
    expect(item.author, 'Alice');
    expect(item.rawText, contains('This is article body.'));
  });

  test('keeps readable block spacing when extracting body fallback', () async {
    final fetcher = WebFetcher(
      client: MockClient(
        (_) async => http.Response('''
<html>
  <head><title>Example Domain</title></head>
  <body>
    <h1>Example Domain</h1>
    <p>This domain is for use in documentation examples without needing permission.</p>
    <p>${'More readable body. ' * 6}</p>
  </body>
</html>
''', 200),
      ),
    );

    final item = await fetcher.fetch(Item(url: 'https://example.com'));

    expect(item.rawText, contains('Example Domain\n\nThis domain'));
  });
}
