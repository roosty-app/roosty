import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/config/config_providers.dart';
import 'package:roosty/core/core_providers.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/core/mini_card.dart';
import 'package:roosty/core/pipeline.dart';
import 'package:roosty/sinks/sink.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ignores the same URL for 30 minutes after ignore once', () async {
    var now = DateTime(2026, 6, 20, 12);
    final container = await _container(now: () => now);
    addTearDown(container.dispose);
    final controller = container.read(miniCardControllerProvider.notifier);

    controller.show(Item(url: 'https://example.com/a'));
    await Future<void>.delayed(Duration.zero);
    final cardId = container.read(miniCardControllerProvider).cards.single.id;

    controller.ignoreOnce(cardId);
    controller.show(Item(url: 'https://example.com/a'));

    expect(container.read(miniCardControllerProvider).cards, isEmpty);
    expect(controller.isUrlIgnored('https://example.com/a'), isTrue);

    now = now.add(const Duration(minutes: 31));
    controller.show(Item(url: 'https://example.com/a'));

    expect(container.read(miniCardControllerProvider).cards, hasLength(1));
  });

  test(
    'keeps at most three cards and treats overflow as ignore once',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final controller = container.read(miniCardControllerProvider.notifier);

      for (var index = 1; index <= 4; index += 1) {
        controller.show(Item(url: 'https://example.com/$index'));
      }

      final cards = container.read(miniCardControllerProvider).cards;
      expect(cards, hasLength(3));
      expect(cards.map((card) => card.item.url), [
        'https://example.com/2',
        'https://example.com/3',
        'https://example.com/4',
      ]);
      expect(controller.isUrlIgnored('https://example.com/1'), isTrue);
    },
  );

  test('skips cards for blocked domains', () async {
    final container = await _container();
    addTearDown(container.dispose);
    await container
        .read(appConfigControllerProvider.notifier)
        .addDomainToBlocklist('example.com');

    container
        .read(miniCardControllerProvider.notifier)
        .show(Item(url: 'https://example.com/a'));

    expect(container.read(miniCardControllerProvider).cards, isEmpty);
  });

  test('enriches a card without writing to sinks', () async {
    final container = await _container();
    addTearDown(container.dispose);

    container
        .read(miniCardControllerProvider.notifier)
        .show(Item(url: 'https://example.com/a'));
    await Future<void>.delayed(Duration.zero);

    final card = container.read(miniCardControllerProvider).cards.single;
    expect(card.status, MiniCardStatus.ready);
    expect(card.item.title, 'https://example.com/a');
  });

  test('archives a mini card by writing the enriched item to sinks', () async {
    final sink = _RecordingSink();
    final container = await _container(pipeline: Pipeline(sinks: [sink]));
    addTearDown(container.dispose);
    await container
        .read(appConfigControllerProvider.notifier)
        .updateVaultPath('C:\\test-vault');

    container
        .read(miniCardControllerProvider.notifier)
        .show(Item(url: 'https://example.com/a'));
    await Future<void>.delayed(Duration.zero);

    final cardId = container.read(miniCardControllerProvider).cards.single.id;

    await container
        .read(captureControllerProvider.notifier)
        .archiveMiniCard(cardId);

    expect(sink.items.map((item) => item.url), ['https://example.com/a']);
    expect(container.read(miniCardControllerProvider).cards, isEmpty);
    expect(
      container.read(captureControllerProvider).history.single.url,
      'https://example.com/a',
    );
  });

  test('serializes mini card window arguments for child windows', () {
    final arguments = MiniCardWindowArguments(
      indexFromBottom: 2,
      card: MiniCardModel(
        id: 'card-1',
        item: Item(
          url: 'https://example.com/a',
          title: 'Title',
          source: 'web',
          capturedAt: DateTime(2026, 6, 20, 12),
          summary: 'Summary',
        ),
        createdAt: DateTime(2026, 6, 20, 12, 1),
        status: MiniCardStatus.ready,
      ),
    );

    final decoded = MiniCardWindowArguments.fromJson(arguments.toJson());

    expect(decoded.indexFromBottom, 2);
    expect(decoded.card.id, 'card-1');
    expect(decoded.card.item.url, 'https://example.com/a');
    expect(decoded.card.item.title, 'Title');
    expect(decoded.card.item.summary, 'Summary');
    expect(decoded.card.status, MiniCardStatus.ready);
  });
}

Future<ProviderContainer> _container({
  DateTime Function()? now,
  Pipeline pipeline = const Pipeline(),
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      pipelineProvider.overrideWithValue(pipeline),
      if (now != null) nowProvider.overrideWithValue(now),
    ],
  );
  await container.read(appConfigControllerProvider.future);
  return container;
}

class _RecordingSink implements Sink {
  final items = <Item>[];

  @override
  Future<void> write(Item item) async {
    items.add(item);
  }
}
