class Item {
  Item({
    required this.url,
    this.title,
    this.source = 'web',
    this.author,
    DateTime? capturedAt,
    this.rawText,
    this.summary,
    List<String>? tags,
    this.status = 'unread',
  }) : capturedAt = capturedAt ?? DateTime.now(),
       tags = List<String>.of(tags ?? const ['roosty/inbox']);

  String url;
  String? title;
  String source;
  String? author;
  DateTime capturedAt;
  String? rawText;
  String? summary;
  List<String> tags;
  String status;
}
