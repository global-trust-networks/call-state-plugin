import Flutter
import UIKit
import CallKit

public class CallStatePlugin: NSObject, FlutterPlugin, CXCallObserverDelegate {
    var callObserver: CXCallObserver!
    var _channel: FlutterMethodChannel
    static var instance: CallStatePlugin?

    var testTimer: Timer?
    var counter = 0
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "call_state_plugin", binaryMessenger: registrar.messenger())
    let instance = CallStatePlugin(channel: channel)
    CallStatePlugin.instance = instance // Retain the instance
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
  init(channel: FlutterMethodChannel){
    _channel = channel
    super.init()
    setupCallObserver()
  }


  @objc func timerAction() {
    counter += 1
    _channel.invokeMethod("phone.incoming", arguments: nil)
    print("Timer!")
    //testTimer.invalidate()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  @available(iOS 10.0,*)
  func setupCallObserver(){
    callObserver = CXCallObserver()
    callObserver.setDelegate(self, queue: nil)
  }


  @available(iOS 10.0,*)
  public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
    // Ensure method channel calls are made on the main thread
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      if call.hasEnded == true {
        print("CXCallState :Disconnected")
        self._channel.invokeMethod("phone.disconnected", arguments: nil)
      }
      if call.isOutgoing == true && call.hasConnected == false {
        print("CXCallState :Dialing")
        self._channel.invokeMethod("phone.dialing", arguments: nil)
      }
      if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false {
        print("CXCallState :Incoming")
        self._channel.invokeMethod("phone.incoming", arguments: nil)
      }

      if call.hasConnected == true && call.hasEnded == false {
        print("CXCallState : Connected")
        self._channel.invokeMethod("phone.connected", arguments: nil)
      }
    }
  }
}
