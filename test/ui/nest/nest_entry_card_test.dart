import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/theme/light_theme.dart';
import 'package:roosty/ui/nest/nest_entry_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: lightRoostyTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('renders title, summary and source icon for a web item', (
    tester,
  ) async {
    final item = Item(
      url: 'https://example.com/post',
      title: '一篇示例文章',
      summary: '这是文章的摘要内容，用来验证卡片是否正确展示。',
      source: 'web',
      capturedAt: DateTime(2026, 6, 22, 14, 30),
    );

    await tester.pumpWidget(wrap(NestEntryCard(item: item)));
    await tester.pumpAndSettle();

    expect(find.text('一篇示例文章'), findsOneWidget);
    expect(find.text('这是文章的摘要内容，用来验证卡片是否正确展示。'), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
    expect(find.text('06-22 14:30'), findsOneWidget);
  });

  testWidgets('falls back to url when title is missing', (tester) async {
    final item = Item(
      url: 'https://example.com/no-title',
      source: 'web',
      capturedAt: DateTime(2026, 6, 22, 9, 5),
    );

    await tester.pumpWidget(wrap(NestEntryCard(item: item)));
    await tester.pumpAndSettle();

    expect(find.text('https://example.com/no-title'), findsWidgets);
  });
}
