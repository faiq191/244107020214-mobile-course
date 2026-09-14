import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('adds a new task', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.text('No tasks yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Do week 3 homework');
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.text('Do week 3 homework'), findsOneWidget);
  });
}
