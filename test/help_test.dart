import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

void main() {
  testWidgets('a ajuda explica a ordem das operações e o cursor',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Ajuda'));
    await settle(tester);

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    Finder inDialog(Finder f) => find.descendant(of: dialog, matching: f);
    expect(inDialog(find.text('Ordem das operações')), findsOneWidget);
    expect(
      inDialog(find.textContaining('−3**2 = (−3)**2 = 9')),
      findsOneWidget,
    );
    expect(inDialog(find.textContaining('√9! = (√9)! = 6')), findsOneWidget);
    expect(inDialog(find.textContaining('pôr o cursor')), findsOneWidget);
    expect(inDialog(find.textContaining('Backspace apaga')), findsOneWidget);
  });
}
