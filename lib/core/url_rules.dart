String? extractDomain(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !_isHttpUri(uri)) {
    return null;
  }
  return normalizeDomain(Uri.decodeComponent(uri.host));
}

String? normalizeDomain(String value) {
  final normalized = value.trim().toLowerCase().replaceFirst(
    RegExp(r'\.$'),
    '',
  );
  return normalized.isEmpty ? null : normalized;
}

bool isDomainBlocked(String url, Iterable<String> blockedDomains) {
  final domain = extractDomain(url);
  if (domain == null) {
    return false;
  }
  return blockedDomains
      .map((blocked) => normalizeDomain(blocked))
      .whereType<String>()
      .contains(domain);
}

bool _isHttpUri(Uri uri) {
  return uri.scheme == 'http' || uri.scheme == 'https';
}
