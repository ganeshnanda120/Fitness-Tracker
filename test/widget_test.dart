// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_tracker_internship/main.dart';

void main() {
  testWidgets('Fitness tracker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FitnessTrackerApp());

    // Verify that the title 'Fitness Tracker' is displayed.
    expect(find.text('Fitness Tracker'), findsOneWidget);

    // Verify that it starts with the empty state message.
    expect(find.text('Keep Up the Momentum!'), findsOneWidget);
  });
}
