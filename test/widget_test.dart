import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:after_hours/screens/auth/login_screen.dart';

void main() {
  testWidgets('login screen shows email and password fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('login screen shows login button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('Sign In'), findsOneWidget);  });
}