import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'call_state_plugin_method_channel.dart';

typedef ErrorHandler = void Function(String message);

abstract class CallStatePluginPlatform extends PlatformInterface {
  /// Constructs a CallStatePluginPlatform.
  CallStatePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static CallStatePluginPlatform _instance = MethodChannelCallStatePlugin();

  /// The default instance of [CallStatePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelCallStatePlugin].
  static CallStatePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CallStatePluginPlatform] when
  /// they register themselves.
  static set instance(CallStatePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<dynamic> setTestMode(double seconds) {
    throw UnimplementedError('setTestMode() has not been implemented.');
  }

  void setIncomingHandler(VoidCallback callback) {
    throw UnimplementedError('setIncomingHandler() has not been implemented.');
  }

  void setDialingHandler(VoidCallback callback) {
    throw UnimplementedError('setDialingHandler() has not been implemented.');
  }

  void setConnectedHandler(VoidCallback callback) {
    throw UnimplementedError('setConnectedHandler() has not been implemented.');
  }

  void setDisconnectedHandler(VoidCallback callback) {
    throw UnimplementedError(
      'setDisconnectedHandler() has not been implemented.',
    );
  }

  void setErrorHandler(ErrorHandler handler) {
    throw UnimplementedError('setErrorHandler() has not been implemented.');
  }

  Future<bool> checkPermission() {
    throw UnimplementedError('checkPermission() has not been implemented.');
  }

  Future<bool> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }
}
