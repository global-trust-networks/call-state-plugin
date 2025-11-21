import 'package:flutter/foundation.dart';
import 'call_state_plugin_platform_interface.dart';

export 'call_state_plugin_platform_interface.dart' show ErrorHandler;

class CallStatePlugin {
  Future<dynamic> setTestMode(double seconds) {
    return CallStatePluginPlatform.instance.setTestMode(seconds);
  }

  void setIncomingHandler(VoidCallback callback) {
    CallStatePluginPlatform.instance.setIncomingHandler(callback);
  }

  void setDialingHandler(VoidCallback callback) {
    CallStatePluginPlatform.instance.setDialingHandler(callback);
  }

  void setConnectedHandler(VoidCallback callback) {
    CallStatePluginPlatform.instance.setConnectedHandler(callback);
  }

  void setDisconnectedHandler(VoidCallback callback) {
    CallStatePluginPlatform.instance.setDisconnectedHandler(callback);
  }

  void setErrorHandler(ErrorHandler handler) {
    CallStatePluginPlatform.instance.setErrorHandler(handler);
  }

  Future<bool> checkPermission() {
    return CallStatePluginPlatform.instance.checkPermission();
  }

  Future<bool> requestPermission() {
    return CallStatePluginPlatform.instance.requestPermission();
  }
}
