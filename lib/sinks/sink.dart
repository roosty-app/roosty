import '../core/item.dart';

abstract class Sink {
  Future<void> write(Item item);
}
