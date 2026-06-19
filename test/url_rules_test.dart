import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/core/url_rules.dart';

void main() {
  test('extracts normalized domain from http URLs with ports', () {
    expect(extractDomain('https://Example.com:8443/path'), 'example.com');
  });

  test('keeps IDN host when extracting domain', () {
    expect(extractDomain('https://例子.测试/path'), '例子.测试');
  });

  test('rejects non-http URLs for domain extraction', () {
    expect(extractDomain('mailto:test@example.com'), isNull);
  });

  test('blocks only exact normalized domains', () {
    expect(isDomainBlocked('https://example.com/a', ['EXAMPLE.com.']), isTrue);
    expect(
      isDomainBlocked('https://sub.example.com/a', ['example.com']),
      isFalse,
    );
  });
}
