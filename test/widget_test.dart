import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:freshveggie/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('Login page renders key UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('VeggieFresh Market'), findsOneWidget);
    expect(find.text('Welcome back! Sign in to continue.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Or sign in with'), findsOneWidget);
    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });
}
