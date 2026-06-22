import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/theme/dark_theme.dart';
import 'package:roosty/theme/light_theme.dart';
import 'package:roosty/ui/nest/empty_nest.dart';

void main() {
  Widget wrap(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      home: const Scaffold(body: Center(child: EmptyNest())),
    );
  }

  testWidgets('EmptyNest builds in light theme and shows guidance text', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(lightRoostyTheme));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(EmptyNest.mainText), findsOneWidget);
    expect(find.text(EmptyNest.subText), findsOneWidget);
  });

  testWidgets('EmptyNest builds in dark theme and shows guidance text', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(darkRoostyTheme));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(EmptyNest.mainText), findsOneWidget);
    expect(find.text(EmptyNest.subText), findsOneWidget);
  });
}
