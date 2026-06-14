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

  Future<Item> run(Item item) {
    throw UnimplementedError('Pipeline is implemented in M1.');
  }
}
