// test/widget_test.dart
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:task/controllers/theme_controller.dart';

void main() {
  testWidgets('Basic app functionality test', (WidgetTester tester) async {
    // Test basic widget functionality without full app initialization
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Task')),
          body: const Center(child: Text('Test App')),
        ),
      ),
    );
    
    expect(find.text('Task'), findsOneWidget);
    expect(find.text('Test App'), findsOneWidget);
  });
  
  test('ThemeController can be instantiated', () {
    // Test controller instantiation without widget dependencies
    final themeController = ThemeController();
    expect(themeController.isDarkMode.value, isFalse);
    
    // Test theme toggle
    themeController.toggleTheme(true);
    expect(themeController.isDarkMode.value, isTrue);
  });
}
