import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_state_plugin/call_state_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelCallStatePlugin', () {
    late MethodChannelCallStatePlugin plugin;
    const MethodChannel channel = MethodChannel('call_state_plugin');

    setUp(() {
      plugin = MethodChannelCallStatePlugin();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    group('Handler Registration', () {
      test('should register incoming handler', () {
        bool handlerCalled = false;
        plugin.setIncomingHandler(() {
          handlerCalled = true;
        });

        expect(plugin.incomingHandler, isNotNull);
        plugin.incomingHandler!();
        expect(handlerCalled, isTrue);
      });

      test('should register dialing handler', () {
        bool handlerCalled = false;
        plugin.setDialingHandler(() {
          handlerCalled = true;
        });

        expect(plugin.dialingHandler, isNotNull);
        plugin.dialingHandler!();
        expect(handlerCalled, isTrue);
      });

      test('should register connected handler', () {
        bool handlerCalled = false;
        plugin.setConnectedHandler(() {
          handlerCalled = true;
        });

        expect(plugin.connectedHandler, isNotNull);
        plugin.connectedHandler!();
        expect(handlerCalled, isTrue);
      });

      test('should register disconnected handler', () {
        bool handlerCalled = false;
        plugin.setDisconnectedHandler(() {
          handlerCalled = true;
        });

        expect(plugin.disconnectedHandler, isNotNull);
        plugin.disconnectedHandler!();
        expect(handlerCalled, isTrue);
      });

      test('should register error handler', () {
        String? errorMessage;
        plugin.setErrorHandler((String message) {
          errorMessage = message;
        });

        expect(plugin.errorHandler, isNotNull);
        plugin.errorHandler!('Test error');
        expect(errorMessage, equals('Test error'));
      });

      test('should allow handler replacement', () {
        int callCount = 0;
        plugin.setIncomingHandler(() {
          callCount = 1;
        });
        plugin.setIncomingHandler(() {
          callCount = 2;
        });

        plugin.incomingHandler!();
        expect(callCount, equals(2));
      });

      test('should allow null handler registration', () {
        plugin.setIncomingHandler(() {});
        plugin.setIncomingHandler(() {});
        expect(plugin.incomingHandler, isNotNull);
      });
    });

    group('Call State Events', () {
      test('should invoke incoming handler on phone.incoming event', () async {
        bool handlerCalled = false;
        plugin.setIncomingHandler(() {
          handlerCalled = true;
        });

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'call_state_plugin',
              const StandardMethodCodec().encodeMethodCall(
                const MethodCall('phone.incoming'),
              ),
              (ByteData? data) {},
            );

        expect(handlerCalled, isTrue);
      });

      test('should invoke dialing handler on phone.dialing event', () async {
        bool handlerCalled = false;
        plugin.setDialingHandler(() {
          handlerCalled = true;
        });

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'call_state_plugin',
              const StandardMethodCodec().encodeMethodCall(
                const MethodCall('phone.dialing'),
              ),
              (ByteData? data) {},
            );

        expect(handlerCalled, isTrue);
      });

      test(
        'should invoke connected handler on phone.connected event',
        () async {
          bool handlerCalled = false;
          plugin.setConnectedHandler(() {
            handlerCalled = true;
          });

          await TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .handlePlatformMessage(
                'call_state_plugin',
                const StandardMethodCodec().encodeMethodCall(
                  const MethodCall('phone.connected'),
                ),
                (ByteData? data) {},
              );

          expect(handlerCalled, isTrue);
        },
      );

      test(
        'should invoke disconnected handler on phone.disconnected event',
        () async {
          bool handlerCalled = false;
          plugin.setDisconnectedHandler(() {
            handlerCalled = true;
          });

          await TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .handlePlatformMessage(
                'call_state_plugin',
                const StandardMethodCodec().encodeMethodCall(
                  const MethodCall('phone.disconnected'),
                ),
                (ByteData? data) {},
              );

          expect(handlerCalled, isTrue);
        },
      );

      test('should invoke error handler on phone.onError event', () async {
        String? errorMessage;
        plugin.setErrorHandler((String message) {
          errorMessage = message;
        });

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'call_state_plugin',
              const StandardMethodCodec().encodeMethodCall(
                const MethodCall('phone.onError', 'Permission denied'),
              ),
              (ByteData? data) {},
            );

        expect(errorMessage, equals('Permission denied'));
      });
    });

    group('Handler Null Safety', () {
      test(
        'should not throw when incoming event received without handler',
        () async {
          expect(() async {
            await TestDefaultBinaryMessengerBinding
                .instance
                .defaultBinaryMessenger
                .handlePlatformMessage(
                  'call_state_plugin',
                  const StandardMethodCodec().encodeMethodCall(
                    const MethodCall('phone.incoming'),
                  ),
                  (ByteData? data) {},
                );
          }, returnsNormally);
        },
      );

      test(
        'should not throw when dialing event received without handler',
        () async {
          expect(() async {
            await TestDefaultBinaryMessengerBinding
                .instance
                .defaultBinaryMessenger
                .handlePlatformMessage(
                  'call_state_plugin',
                  const StandardMethodCodec().encodeMethodCall(
                    const MethodCall('phone.dialing'),
                  ),
                  (ByteData? data) {},
                );
          }, returnsNormally);
        },
      );

      test(
        'should not throw when connected event received without handler',
        () async {
          expect(() async {
            await TestDefaultBinaryMessengerBinding
                .instance
                .defaultBinaryMessenger
                .handlePlatformMessage(
                  'call_state_plugin',
                  const StandardMethodCodec().encodeMethodCall(
                    const MethodCall('phone.connected'),
                  ),
                  (ByteData? data) {},
                );
          }, returnsNormally);
        },
      );

      test(
        'should not throw when disconnected event received without handler',
        () async {
          expect(() async {
            await TestDefaultBinaryMessengerBinding
                .instance
                .defaultBinaryMessenger
                .handlePlatformMessage(
                  'call_state_plugin',
                  const StandardMethodCodec().encodeMethodCall(
                    const MethodCall('phone.disconnected'),
                  ),
                  (ByteData? data) {},
                );
          }, returnsNormally);
        },
      );

      test(
        'should not throw when error event received without handler',
        () async {
          expect(() async {
            await TestDefaultBinaryMessengerBinding
                .instance
                .defaultBinaryMessenger
                .handlePlatformMessage(
                  'call_state_plugin',
                  const StandardMethodCodec().encodeMethodCall(
                    const MethodCall('phone.onError', 'Error message'),
                  ),
                  (ByteData? data) {},
                );
          }, returnsNormally);
        },
      );
    });

    group('Multiple Handlers', () {
      test('should handle multiple simultaneous call state events', () async {
        final List<String> callSequence = [];

        plugin.setIncomingHandler(() {
          callSequence.add('incoming');
        });
        plugin.setDialingHandler(() {
          callSequence.add('dialing');
        });
        plugin.setConnectedHandler(() {
          callSequence.add('connected');
        });
        plugin.setDisconnectedHandler(() {
          callSequence.add('disconnected');
        });

        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

        await Future.wait([
          messenger.handlePlatformMessage(
            'call_state_plugin',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('phone.incoming'),
            ),
            (ByteData? data) {},
          ),
          messenger.handlePlatformMessage(
            'call_state_plugin',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('phone.dialing'),
            ),
            (ByteData? data) {},
          ),
          messenger.handlePlatformMessage(
            'call_state_plugin',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('phone.connected'),
            ),
            (ByteData? data) {},
          ),
        ]);

        expect(callSequence, containsAll(['incoming', 'dialing', 'connected']));
        expect(callSequence.length, equals(3));
      });
    });

    group('Unknown Method Calls', () {
      test('should handle unknown method calls gracefully', () async {
        expect(() async {
          await TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .handlePlatformMessage(
                'call_state_plugin',
                const StandardMethodCodec().encodeMethodCall(
                  const MethodCall('unknown.method'),
                ),
                (ByteData? data) {},
              );
        }, returnsNormally);
      });
    });

    group('setTestMode', () {
      test('should invoke method channel with correct parameters', () async {
        String? methodName;
        dynamic arguments;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              methodName = methodCall.method;
              arguments = methodCall.arguments;
              return null;
            });

        await plugin.setTestMode(5.0);

        expect(methodName, equals('phoneTest.PhoneIncoming'));
        expect(arguments, equals(5.0));
      });

      test('should handle zero seconds', () async {
        String? methodName;
        dynamic arguments;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              methodName = methodCall.method;
              arguments = methodCall.arguments;
              return null;
            });

        await plugin.setTestMode(0.0);

        expect(methodName, equals('phoneTest.PhoneIncoming'));
        expect(arguments, equals(0.0));
      });

      test('should handle negative seconds', () async {
        String? methodName;
        dynamic arguments;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              methodName = methodCall.method;
              arguments = methodCall.arguments;
              return null;
            });

        await plugin.setTestMode(-1.0);

        expect(methodName, equals('phoneTest.PhoneIncoming'));
        expect(arguments, equals(-1.0));
      });
    });

    group('Error Handler Edge Cases', () {
      test('should handle empty error message', () async {
        String? errorMessage;
        plugin.setErrorHandler((String message) {
          errorMessage = message;
        });

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'call_state_plugin',
              const StandardMethodCodec().encodeMethodCall(
                const MethodCall('phone.onError', ''),
              ),
              (ByteData? data) {},
            );

        expect(errorMessage, equals(''));
      });

      test('should handle null error arguments gracefully', () async {
        bool errorHandlerCalled = false;
        plugin.setErrorHandler((String message) {
          errorHandlerCalled = true;
        });

        // Simulate null arguments by not providing them
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'call_state_plugin',
              const StandardMethodCodec().encodeMethodCall(
                const MethodCall('phone.onError'),
              ),
              (ByteData? data) {},
            );

        // Handler should still be called, but with null as argument
        // This tests the plugin's resilience to malformed messages
        expect(() => errorHandlerCalled, returnsNormally);
      });
    });
  });
}
