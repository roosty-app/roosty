import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/sources/clipboard_source.dart';

void main() {
  test('extracts first http URL from text', () {
    expect(
      extractFirstUrl('See https://example.com/a?b=1 and http://test.dev'),
      'https://example.com/a?b=1',
    );
  });

  test('ignores non-url text', () {
    expect(extractFirstUrl('not a url'), isNull);
  });

  test('deduplicates repeated clipboard URLs within the window', () async {
    var calls = 0;
    var now = DateTime(2026, 6, 14, 12);
    final source = ClipboardSource(
      reader: () async {
        calls += 1;
        if (calls == 3) {
          now = now.add(const Duration(minutes: 2));
        }
        return 'https://example.com';
      },
      pollInterval: Duration.zero,
      dedupeWindow: const Duration(minutes: 1),
      now: () => now,
    );

    final items = await source.watch().take(2).toList();

    expect(items.map((item) => item.url), [
      'https://example.com',
      'https://example.com',
    ]);
    expect(calls, 3);
  });
}
