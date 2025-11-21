import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_state_plugin/call_state_plugin.dart';
import 'package:call_state_plugin/call_state_plugin_platform_interface.dart';
import 'package:call_state_plugin/call_state_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCallStatePluginPlatform
    with MockPlatformInterfaceMixin
    implements CallStatePluginPlatform {
  @override
  void setConnectedHandler(VoidCallback callback) {}

  @override
  void setDialingHandler(VoidCallback callback) {}

  @override
  void setDisconnectedHandler(VoidCallback callback) {}

  @override
  void setErrorHandler(ErrorHandler handler) {}

  @override
  void setIncomingHandler(VoidCallback callback) {}

  @override
  Future setTestMode(double seconds) async {}

  @override
  Future<bool> checkPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CallStatePlugin', () {
    test('$MethodChannelCallStatePlugin is the default instance', () {
      final CallStatePluginPlatform initialPlatform =
          CallStatePluginPlatform.instance;
      expect(initialPlatform, isInstanceOf<MethodChannelCallStatePlugin>());
    });

    test('checkPermission returns a Future<bool>', () async {
      final plugin = CallStatePlugin();
      final result = plugin.checkPermission();
      expect(result, isA<Future<bool>>());
    });

    test('requestPermission returns a Future<bool>', () async {
      final plugin = CallStatePlugin();
      final result = plugin.requestPermission();
      expect(result, isA<Future<bool>>());
    });

    test('setTestMode returns a Future', () async {
      final plugin = CallStatePlugin();
      final result = plugin.setTestMode(5.0);
      expect(result, isA<Future>());
    });

    test('setIncomingHandler accepts a VoidCallback', () {
      final plugin = CallStatePlugin();
      expect(() => plugin.setIncomingHandler(() {}), returnsNormally);
    });

    test('setDialingHandler accepts a VoidCallback', () {
      final plugin = CallStatePlugin();
      expect(() => plugin.setDialingHandler(() {}), returnsNormally);
    });

    test('setConnectedHandler accepts a VoidCallback', () {
      final plugin = CallStatePlugin();
      expect(() => plugin.setConnectedHandler(() {}), returnsNormally);
    });

    test('setDisconnectedHandler accepts a VoidCallback', () {
      final plugin = CallStatePlugin();
      expect(() => plugin.setDisconnectedHandler(() {}), returnsNormally);
    });

    test('setErrorHandler accepts an ErrorHandler', () {
      final plugin = CallStatePlugin();
      expect(
        () => plugin.setErrorHandler((String message) {}),
        returnsNormally,
      );
    });
  });

  group('MockCallStatePluginPlatform', () {
    test('checkPermission returns true', () async {
      final mockPlatform = MockCallStatePluginPlatform();
      final result = await mockPlatform.checkPermission();
      expect(result, isTrue);
    });

    test('requestPermission returns true', () async {
      final mockPlatform = MockCallStatePluginPlatform();
      final result = await mockPlatform.requestPermission();
      expect(result, isTrue);
    });
  });
}
