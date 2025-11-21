import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'call_state_plugin_platform_interface.dart';

/// An implementation of [CallStatePluginPlatform] that uses method channels.
class MethodChannelCallStatePlugin extends CallStatePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('call_state_plugin');

  VoidCallback? incomingHandler;
  VoidCallback? dialingHandler;
  VoidCallback? connectedHandler;
  VoidCallback? disconnectedHandler;
  ErrorHandler? errorHandler;

  MethodChannelCallStatePlugin() {
    print("MethodChannelCallStatePlugin: Initializing method channel handler");
    methodChannel.setMethodCallHandler(platformCallHandler);
    print(
      "MethodChannelCallStatePlugin: Method channel handler set successfully",
    );
  }

  @override
  Future<dynamic> setTestMode(double seconds) =>
      methodChannel.invokeMethod('phoneTest.PhoneIncoming', seconds);

  @override
  void setIncomingHandler(VoidCallback callback) {
    print("Setting incomingHandler callback");
    incomingHandler = callback;
  }

  @override
  void setDialingHandler(VoidCallback callback) {
    print("Setting dialingHandler callback");
    dialingHandler = callback;
  }

  @override
  void setConnectedHandler(VoidCallback callback) {
    print("Setting connectedHandler callback");
    connectedHandler = callback;
  }

  @override
  void setDisconnectedHandler(VoidCallback callback) {
    print("Setting disconnectedHandler callback");
    disconnectedHandler = callback;
  }

  @override
  void setErrorHandler(ErrorHandler handler) {
    print("Setting errorHandler callback");
    errorHandler = handler;
  }

  @override
  Future<bool> checkPermission() async {
    final result = await methodChannel.invokeMethod<bool>('checkPermission');
    return result ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    final result = await methodChannel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  }

  Future platformCallHandler(MethodCall call) async {
    print("=== MethodChannelCallStatePlugin: Received method call ===");
    print("Method: ${call.method}");
    print("Arguments: ${call.arguments}");
    print(
      "Handler status - incoming: ${incomingHandler != null}, dialing: ${dialingHandler != null}, connected: ${connectedHandler != null}, disconnected: ${disconnectedHandler != null}",
    );

    // Method channel handlers are already called on the main thread
    // Execute callbacks directly to avoid any delays
    switch (call.method) {
      case "phone.incoming":
        print(
          "Processing phone.incoming - handler exists: ${incomingHandler != null}",
        );
        if (incomingHandler != null) {
          incomingHandler!();
          print("incomingHandler called successfully");
        } else {
          print("ERROR: incomingHandler is null!");
        }
        break;
      case "phone.dialing":
        print(
          "Processing phone.dialing - handler exists: ${dialingHandler != null}",
        );
        if (dialingHandler != null) {
          dialingHandler!();
          print("dialingHandler called successfully");
        } else {
          print("ERROR: dialingHandler is null!");
        }
        break;
      case "phone.connected":
        print(
          "Processing phone.connected - handler exists: ${connectedHandler != null}",
        );
        if (connectedHandler != null) {
          connectedHandler!();
          print("connectedHandler called successfully");
        } else {
          print("ERROR: connectedHandler is null!");
        }
        break;
      case "phone.disconnected":
        print(
          "Processing phone.disconnected - handler exists: ${disconnectedHandler != null}",
        );
        if (disconnectedHandler != null) {
          disconnectedHandler!();
          print("disconnectedHandler called successfully");
        } else {
          print("ERROR: disconnectedHandler is null!");
        }
        break;
      case "phone.onError":
        print(
          "Processing phone.onError - handler exists: ${errorHandler != null}",
        );
        if (errorHandler != null) {
          errorHandler!(call.arguments);
          print("errorHandler called successfully");
        } else {
          print("ERROR: errorHandler is null!");
        }
        break;
      default:
        print('WARNING: Unknown method ${call.method}');
    }
    print("=== MethodChannelCallStatePlugin: Finished processing ===");
  }
}
