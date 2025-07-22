// test/widget_test.dart
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:task/my_app.dart';
import 'package:isar/isar.dart';

void main() {
  testWidgets('App shows expected title', (WidgetTester tester) async {
    // Create a test Isar instance (replace [] with your schemas if needed)
    final isar = await Isar.open([], directory: '');

    await tester.pumpWidget(MyApp(isar: isar));
    expect(find.text('Task'), findsOneWidget); // Replace 'Task' with your app's title
  });
}
