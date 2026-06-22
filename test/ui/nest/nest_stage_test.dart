import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/theme/light_theme.dart';
import 'package:roosty/ui/nest/empty_nest.dart';
import 'package:roosty/ui/nest/nest_entry_card.dart';
import 'package:roosty/ui/nest/nest_entry_grid.dart';
import 'package:roosty/ui/nest/nest_stage.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: lightRoostyTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  Item sampleItem(int i) => Item(
        url: 'https://example.com/$i',
        title: 'Item $i',
        summary: 'Summary $i',
        source: 'web',
        capturedAt: DateTime(2026, 6, 22, 10, i % 60),
      );

  testWidgets('history empty shows EmptyNest', (tester) async {
    await tester.pumpWidget(wrap(const NestStage(history: [])));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyNest), findsOneWidget);
    expect(find.byType(NestEntryGrid), findsNothing);
  });

  testWidgets('history non-empty shows NestEntryGrid with cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(NestStage(history: [sampleItem(1), sampleItem(2)])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NestEntryGrid), findsOneWidget);
    expect(find.byType(NestEntryCard), findsNWidgets(2));
    expect(find.byType(EmptyNest), findsNothing);
  });

  testWidgets('switching from empty to non-empty updates the tree', (
    tester,
  ) async {
    final items = <Item>[];
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: lightRoostyTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SingleChildScrollView(child: NestStage(history: items));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EmptyNest), findsOneWidget);

    rebuild(() {
      items.add(sampleItem(1));
    });
    await tester.pumpAndSettle();

    expect(find.byType(NestEntryGrid), findsOneWidget);
    expect(find.byType(EmptyNest), findsNothing);
  });
}
