import '../fetchers/fetcher.dart';
import '../processors/processor.dart';
import '../sinks/sink.dart';
import 'item.dart';

class Pipeline {
  const Pipeline({
    this.fetchers = const [],
    this.processors = const [],
    this.sinks = const [],
  });

  final List<Fetcher> fetchers;
  final List<Processor> processors;
  final List<Sink> sinks;

  Future<Item> run(Item item) async {
    final current = await enrich(item);
    await write(current);
    return current;
  }

  Future<Item> enrich(Item item) async {
    var current = item;

    Fetcher? fetcher;
    for (final candidate in fetchers) {
      if (candidate.canHandle(item.url)) {
        fetcher = candidate;
        break;
      }
    }
    if (fetcher != null) {
      try {
        current = await fetcher.fetch(current);
      } catch (_) {
        current.rawText ??= fallbackBody;
        current.title ??= current.url;
      }
    } else {
      current.rawText ??= fallbackBody;
      current.title ??= current.url;
    }

    for (final processor in processors) {
      try {
        current = await processor.process(current);
      } catch (_) {
        continue;
      }
    }

    return current;
  }

  Future<void> write(Item item) async {
    for (final sink in sinks) {
      await sink.write(item);
    }
  }
}

const fallbackBody = '> ⚠️ 正文未抓取，点击上方链接查看原文';
