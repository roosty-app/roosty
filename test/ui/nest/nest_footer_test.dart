import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/theme/light_theme.dart';
import 'package:roosty/ui/nest/nest_footer.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: lightRoostyTheme,
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders 退出 Roosty label and power icon', (tester) async {
    await tester.pumpWidget(wrap(NestFooter(onExitApp: () {})));
    await tester.pumpAndSettle();

    expect(find.text(NestFooter.exitLabel), findsOneWidget);
    expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    expect(find.byKey(NestFooter.exitButtonKey), findsOneWidget);
  });

  testWidgets('tapping the exit button invokes onExitApp', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(NestFooter(onExitApp: () => calls++)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(NestFooter.exitButtonKey));
    await tester.pumpAndSettle();

    expect(calls, 1);
  });
}
