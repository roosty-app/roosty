import '../core/item.dart';

abstract class Fetcher {
  bool canHandle(String url);

  Future<Item> fetch(Item item);
}
