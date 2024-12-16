// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// Platform  Firebase App Id
// web       1:1069161031261:web:a5883b0e660e112b198fb4
// android   1:1069161031261:android:f250335c932401f1198fb4
// ios       1:1069161031261:ios:cb7965afacda2949198fb4
// macos     1:1069161031261:ios:cb7965afacda2949198fb4
// windows   1:1069161031261:web:174324635b5e4de7198fb4

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anon_chat/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
