// This is a basic Flutter widget test for ChatMeal app.

import 'package:flutter_test/flutter_test.dart';

import 'package:chatmeal/main.dart';

void main() {
  testWidgets('ChatMeal app launches with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChatMealApp());

    // Verify that the splash screen is displayed.
    expect(find.text('ChatMeal'), findsOneWidget);
    expect(find.text('Order food with your voice'), findsOneWidget);
  });
}
