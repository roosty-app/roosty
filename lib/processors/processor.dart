import '../core/item.dart';

abstract class Processor {
  Future<Item> process(Item item);
}
