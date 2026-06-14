import '../core/item.dart';

abstract class Source {
  Stream<Item> watch();
}
