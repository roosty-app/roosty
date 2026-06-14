import '../core/item.dart';
import 'processor.dart';

class PassThroughProcessor implements Processor {
  const PassThroughProcessor();

  @override
  Future<Item> process(Item item) async => item;
}
