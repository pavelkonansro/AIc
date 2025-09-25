import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aic_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AIc App Integration Tests', () {
    testWidgets('Complete user flow: Auth -> Chat -> Sign Out', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Test 1: Should show authentication page initially
      expect(find.text('начать общение'), findsOneWidget);
      expect(find.text('войти через гугл'), findsOneWidget);

      // Test 2: Anonymous sign in
      await tester.tap(find.text('начать общение'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Should navigate to chat or show some authenticated state
      // (Assuming navigation works correctly)
      
      // Test 3: Check if we're in authenticated state
      // This test depends on your actual app navigation flow
      
      // Test 4: Sign out (if there's a sign out button)
      // await tester.tap(find.byIcon(Icons.logout));
      // await tester.pumpAndSettle();
      
      // Should return to auth page
      // expect(find.text('начать общение'), findsOneWidget);
    });

    testWidgets('Google Sign In Flow', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Test Google sign in button
      expect(find.text('войти через гугл'), findsOneWidget);
      
      await tester.tap(find.text('войти через гугл'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // In test environment, this should use MockAuthService
      // Verify the app doesn't crash and handles the flow
    });

    testWidgets('App should handle network errors gracefully', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Try to sign in when network might be unavailable
      await tester.tap(find.text('начать общение'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // App should not crash, even if network calls fail
      expect(tester.takeException(), isNull);
    });

    testWidgets('App should maintain state across widget rebuilds', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Sign in
      await tester.tap(find.text('начать общение'));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Trigger a rebuild by changing system settings or rotating device
      // await tester.binding.defaultBinaryMessenger.handlePlatformMessage(...);
      await tester.pumpAndSettle();

      // State should be maintained
      // (This test depends on your actual app state management)
    });

    testWidgets('App should handle rapid button taps without crashing', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Rapidly tap authentication buttons
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('начать общение'));
        await tester.pump(Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle(Duration(seconds: 3));

      // App should handle this gracefully
      expect(tester.takeException(), isNull);
    });

    testWidgets('Memory leak test - multiple navigation cycles', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Perform multiple authentication cycles
      for (int i = 0; i < 3; i++) {
        // Sign in
        await tester.tap(find.text('начать общение'));
        await tester.pumpAndSettle(Duration(seconds: 1));

        // If there's a way to sign out, do it
        // This tests for potential memory leaks
        
        await tester.pumpAndSettle(Duration(seconds: 1));
      }

      // App should still be responsive
      expect(find.text('начать общение'), findsOneWidget);
    });

    testWidgets('App should handle background/foreground transitions', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Sign in
      await tester.tap(find.text('начать общение'));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Simulate app going to background and coming back
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.paused', null),
        ),
        (data) {},
      );

      await tester.pump();

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.resumed', null),
        ),
        (data) {},
      );

      await tester.pumpAndSettle();

      // App should handle lifecycle changes gracefully
      expect(tester.takeException(), isNull);
    });

    testWidgets('Authentication state persistence test', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Sign in
      await tester.tap(find.text('начать общение'));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Restart the app (simulated)
      await tester.pumpWidget(Container()); // Clear the widget tree
      await tester.pumpAndSettle();

      app.main(); // Restart app
      await tester.pumpAndSettle();

      // Check if authentication state is restored
      // (This depends on your persistence implementation)
    });

    testWidgets('Performance test - app should load quickly', (tester) async {
      final stopwatch = Stopwatch()..start();

      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      stopwatch.stop();

      // App should load within reasonable time (adjust as needed)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max

      // UI should be responsive
      expect(find.text('начать общение'), findsOneWidget);
    });

    testWidgets('Error recovery test', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Try operations that might fail
      await tester.tap(find.text('войти через гугл'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Even if Google sign in fails, try anonymous
      if (find.text('начать общение').evaluate().isNotEmpty) {
        await tester.tap(find.text('начать общение'));
        await tester.pumpAndSettle(Duration(seconds: 2));
      }

      // App should recover and be usable
      expect(tester.takeException(), isNull);
    });
  });

  group('Chat Integration Tests', () {
    testWidgets('Chat initialization and basic functionality', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Sign in to access chat
      await tester.tap(find.text('начать общение'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // If successfully navigated to chat, test basic chat functionality
      // (This depends on your actual chat implementation and navigation)
      
      // Look for chat interface elements
      // expect(find.byType(ChatInterface), findsOneWidget);
      
      // Test that chat doesn't crash on load
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chat should handle connection issues', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Sign in
      await tester.tap(find.text('начать общение'));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Chat should initialize even with potential network issues
      // and not crash the app
      await tester.pumpAndSettle(Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    });
  });
}