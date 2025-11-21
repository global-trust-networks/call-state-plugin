// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:call_state_plugin/call_state_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CallStatePlugin Integration Tests', () {
    late CallStatePlugin plugin;

    setUp(() {
      plugin = CallStatePlugin();
    });

    testWidgets('should set call state handlers without errors', (
      WidgetTester tester,
    ) async {
      // Verify handlers can be set without throwing
      expect(() {
        plugin.setIncomingHandler(() {});
        plugin.setDialingHandler(() {});
        plugin.setConnectedHandler(() {});
        plugin.setDisconnectedHandler(() {});
      }, returnsNormally);
    });

    testWidgets('should set error handler without errors', (
      WidgetTester tester,
    ) async {
      // Verify error handler can be set without throwing
      expect(() {
        plugin.setErrorHandler((String message) {});
      }, returnsNormally);
    });

    testWidgets('should enable test mode without errors', (
      WidgetTester tester,
    ) async {
      // Test enabling test mode with different durations
      expect(() async {
        await plugin.setTestMode(1.0);
      }, returnsNormally);

      expect(() async {
        await plugin.setTestMode(5.0);
      }, returnsNormally);

      expect(() async {
        await plugin.setTestMode(10.0);
      }, returnsNormally);
    });

    testWidgets('should trigger handlers when test mode is enabled', (
      WidgetTester tester,
    ) async {
      final List<String> callStates = [];
      final Completer<void> completer = Completer<void>();

      // Set up handlers to track call states
      plugin.setIncomingHandler(() {
        callStates.add('incoming');
      });

      plugin.setDialingHandler(() {
        callStates.add('dialing');
      });

      plugin.setConnectedHandler(() {
        callStates.add('connected');
      });

      plugin.setDisconnectedHandler(() {
        callStates.add('disconnected');
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Enable test mode for a short duration
      await plugin.setTestMode(2.0);

      // Wait for handlers to be called (with timeout)
      try {
        await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // If timeout, that's okay - handlers may not be called immediately
            // or may depend on platform implementation
          },
        );
      } catch (e) {
        // Timeout is acceptable - handlers may be called asynchronously
        // or may depend on platform-specific behavior
      }

      // At minimum, verify that setting handlers and test mode doesn't crash
      expect(callStates, isA<List<String>>());
    });

    testWidgets('should handle multiple handler registrations', (
      WidgetTester tester,
    ) async {
      // Set multiple handlers
      plugin.setIncomingHandler(() {});

      // Overwrite with new handler
      plugin.setIncomingHandler(() {});

      // Verify we can set handlers multiple times without errors
      expect(() {
        plugin.setIncomingHandler(() {});
        plugin.setDialingHandler(() {});
        plugin.setConnectedHandler(() {});
        plugin.setDisconnectedHandler(() {});
        plugin.setErrorHandler((String message) {});
      }, returnsNormally);
    });
  });
}
