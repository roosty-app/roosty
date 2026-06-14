import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/core/pipeline.dart';
import 'package:roosty/fetchers/fetcher.dart';
import 'package:roosty/processors/processor.dart';
import 'package:roosty/sinks/sink.dart';

void main() {
  test('runs fetcher, processor, and sink in order', () async {
    final events = <String>[];
    final sink = _RecordingSink(events);
    final pipeline = Pipeline(
      fetchers: [_RecordingFetcher(events)],
      processors: [_RecordingProcessor(events)],
      sinks: [sink],
    );

    final item = await pipeline.run(Item(url: 'https://example.com'));

    expect(events, ['fetch', 'process', 'sink']);
    expect(item.title, 'Fetched title');
    expect(item.tags, contains('processed'));
    expect(sink.item, same(item));
  });

  test('writes fallback body when fetcher fails', () async {
    final sink = _RecordingSink([]);
    final pipeline = Pipeline(fetchers: [_FailingFetcher()], sinks: [sink]);

    final item = await pipeline.run(Item(url: 'https://example.com'));

    expect(item.rawText, fallbackBody);
    expect(item.title, 'https://example.com');
    expect(sink.item, same(item));
  });
}

class _RecordingFetcher implements Fetcher {
  _RecordingFetcher(this.events);

  final List<String> events;

  @override
  bool canHandle(String url) => true;

  @override
  Future<Item> fetch(Item item) async {
    events.add('fetch');
    item.title = 'Fetched title';
    return item;
  }
}

class _FailingFetcher implements Fetcher {
  @override
  bool canHandle(String url) => true;

  @override
  Future<Item> fetch(Item item) {
    throw Exception('network failed');
  }
}

class _RecordingProcessor implements Processor {
  _RecordingProcessor(this.events);

  final List<String> events;

  @override
  Future<Item> process(Item item) async {
    events.add('process');
    item.tags.add('processed');
    return item;
  }
}

class _RecordingSink implements Sink {
  _RecordingSink(this.events);

  final List<String> events;
  Item? item;

  @override
  Future<void> write(Item item) async {
    events.add('sink');
    this.item = item;
  }
}
