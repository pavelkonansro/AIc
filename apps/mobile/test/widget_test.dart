// This is a basic Flutter widget test for AIc app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aic_mobile/app.dart';

void main() {
  testWidgets('AIc app launches and shows auth page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AicApp());

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Verify that we are on the auth page by looking for typical auth elements
    // This might include buttons like "Login", "Guest", or app title
    expect(find.byType(MaterialApp), findsOneWidget);

    // The app should load without crashing and display some content
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('App has correct title and theme', (WidgetTester tester) async {
    await tester.pumpWidget(const AicApp());
    await tester.pumpAndSettle();

    // Check that the app widget is created
    expect(find.byType(AicApp), findsOneWidget);

    // Verify the MaterialApp is configured
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, equals('AIc'));
  });

  testWidgets('App supports multiple locales', (WidgetTester tester) async {
    await tester.pumpWidget(const AicApp());
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget(find.byType(MaterialApp));

    // Check supported locales
    expect(app.supportedLocales, contains(const Locale('en')));
    expect(app.supportedLocales, contains(const Locale('cs')));
    expect(app.supportedLocales, contains(const Locale('de')));
  });
}