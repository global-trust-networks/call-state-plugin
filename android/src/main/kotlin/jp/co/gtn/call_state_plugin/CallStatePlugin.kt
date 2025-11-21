package jp.co.gtn.call_state_plugin

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** CallStatePlugin */
class CallStatePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    var tm: TelephonyManager? = null
    private var previousCallState: Int = TelephonyManager.CALL_STATE_IDLE
    private val TAG = "CallStatePlugin"
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private var telephonyCallback: TelephonyCallback? = null
    private var phoneStateListener: PhoneStateListener? = null
    private var pendingPermissionResult: Result? = null
    private val PERMISSION_REQUEST_CODE = 1001

    companion object {
        private const val READ_PHONE_STATE_PERMISSION = Manifest.permission.READ_PHONE_STATE
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "call_state_plugin")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
            onRequestPermissionsResult(requestCode, permissions, grantResults)
            true
        }
        setupPhoneStateListener()
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
            onRequestPermissionsResult(requestCode, permissions, grantResults)
            true
        }
        setupPhoneStateListener()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    private fun setupPhoneStateListener() {
        val context = this.context ?: return
        val tm: TelephonyManager =
            context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        this.tm = tm
        
        // Check permission before setting up listener
        if (!hasPermission()) {
            Log.w(TAG, "READ_PHONE_STATE permission not granted. Call state monitoring will not work.")
            return
        }
        
        Log.d(TAG, "Setting up phone state listener")
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Use modern TelephonyCallback API (API 31+)
            telephonyCallback = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                override fun onCallStateChanged(state: Int) {
                    handleCallStateChanged(state, null)
                }
            }
            tm.registerTelephonyCallback(
                context.mainExecutor,
                telephonyCallback!!
            )
            Log.d(TAG, "TelephonyCallback registered successfully (API 31+)")
        } else {
            // Use deprecated PhoneStateListener for older APIs (API < 31)
            @Suppress("DEPRECATION")
            phoneStateListener = mPhoneListener
            @Suppress("DEPRECATION")
            tm.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
            Log.d(TAG, "PhoneStateListener registered successfully (API < 31)")
        }
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "phoneTest.PhoneIncoming" -> {
                val seconds = call.arguments as? Double ?: 5.0
                // Simulate call states for test mode
                simulateTestCall(seconds)
                result.success(null)
            }
            "checkPermission" -> {
                val hasPermission = hasPermission()
                result.success(hasPermission)
            }
            "requestPermission" -> {
                requestPermission(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun hasPermission(): Boolean {
        val context = this.context ?: return false
        return ContextCompat.checkSelfPermission(
            context,
            READ_PHONE_STATE_PERMISSION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermission(result: Result) {
        val activity = this.activity
        if (activity == null) {
            result.error(
                "NO_ACTIVITY",
                "No activity available to request permission",
                null
            )
            return
        }

        if (hasPermission()) {
            result.success(true)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(READ_PHONE_STATE_PERMISSION),
            PERMISSION_REQUEST_CODE
        )
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            
            if (granted) {
                Log.d(TAG, "Permission granted, setting up phone state listener")
                setupPhoneStateListener()
            } else {
                Log.w(TAG, "Permission denied")
            }
            
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun simulateTestCall(seconds: Double) {
        // Simulate incoming call
        channel.invokeMethod("phone.incoming", true)
        
        // After a short delay, simulate connected
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            channel.invokeMethod("phone.connected", true)
        }, 1000)
        
        // After the specified duration, simulate disconnected
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            channel.invokeMethod("phone.disconnected", true)
        }, (seconds * 1000).toLong())
    }

    private fun handleCallStateChanged(state: Int, incomingNumber: String?) {
        try {
            Log.d(TAG, "onCallStateChanged called: state=$state, incomingNumber=$incomingNumber, previousState=$previousCallState")
            // Capture previous state before posting to main thread
            val prevState = previousCallState
            // Ensure method channel calls are made on the main thread
            mainHandler.post {
                try {
                    when (state) {
                        TelephonyManager.CALL_STATE_IDLE -> {
                            Log.d(TAG, "Call state: IDLE -> Disconnected")
                            channel.invokeMethod(
                                "phone.disconnected",
                                true,
                                object : MethodChannel.Result {
                                    override fun success(result: Any?) {
                                        Log.d(TAG, "Successfully sent phone.disconnected")
                                    }
                                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                        Log.e(TAG, "Error sending phone.disconnected: $errorCode - $errorMessage")
                                    }
                                    override fun notImplemented() {
                                        Log.e(TAG, "phone.disconnected not implemented")
                                    }
                                }
                            )
                            previousCallState = TelephonyManager.CALL_STATE_IDLE
                        }

                        TelephonyManager.CALL_STATE_RINGING -> {
                            Log.d(TAG, "Call state: RINGING -> Incoming")
                            channel.invokeMethod(
                                "phone.incoming",
                                true,
                                object : MethodChannel.Result {
                                    override fun success(result: Any?) {
                                        Log.d(TAG, "Successfully sent phone.incoming")
                                    }
                                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                        Log.e(TAG, "Error sending phone.incoming: $errorCode - $errorMessage")
                                    }
                                    override fun notImplemented() {
                                        Log.e(TAG, "phone.incoming not implemented")
                                    }
                                }
                            )
                            previousCallState = TelephonyManager.CALL_STATE_RINGING
                        }

                        TelephonyManager.CALL_STATE_OFFHOOK -> {
                            // Detect outgoing call: if previous state was IDLE (not RINGING), it's an outgoing call
                            if (prevState == TelephonyManager.CALL_STATE_IDLE) {
                                Log.d(TAG, "Call state: OFFHOOK (from IDLE) -> Dialing")
                                channel.invokeMethod(
                                    "phone.dialing",
                                    true,
                                    object : MethodChannel.Result {
                                        override fun success(result: Any?) {
                                            Log.d(TAG, "Successfully sent phone.dialing")
                                        }
                                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                            Log.e(TAG, "Error sending phone.dialing: $errorCode - $errorMessage")
                                        }
                                        override fun notImplemented() {
                                            Log.e(TAG, "phone.dialing not implemented")
                                        }
                                    }
                                )
                            } else {
                                // Previous state was RINGING, so this is an incoming call being answered
                                Log.d(TAG, "Call state: OFFHOOK (from RINGING) -> Connected")
                                channel.invokeMethod(
                                    "phone.connected",
                                    true,
                                    object : MethodChannel.Result {
                                        override fun success(result: Any?) {
                                            Log.d(TAG, "Successfully sent phone.connected")
                                        }
                                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                            Log.e(TAG, "Error sending phone.connected: $errorCode - $errorMessage")
                                        }
                                        override fun notImplemented() {
                                            Log.e(TAG, "phone.connected not implemented")
                                        }
                                    }
                                )
                            }
                            previousCallState = TelephonyManager.CALL_STATE_OFFHOOK
                        }

                        else -> Log.d(TAG, "Unknown phone state=" + state.toString())
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Exception in mainHandler.post: ${e.message}", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception in handleCallStateChanged: ${e.message}", e)
        }
    }

    @Suppress("DEPRECATION")
    private val mPhoneListener: PhoneStateListener = object : PhoneStateListener() {
        override fun onCallStateChanged(state: Int, incomingNumber: String?) {
            handleCallStateChanged(state, incomingNumber)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        
        // Unregister callbacks
        tm?.let { telephonyManager ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                telephonyCallback?.let { callback ->
                    telephonyManager.unregisterTelephonyCallback(callback)
                    telephonyCallback = null
                }
            } else {
                @Suppress("DEPRECATION")
                phoneStateListener?.let { listener ->
                    @Suppress("DEPRECATION")
                    telephonyManager.listen(listener, PhoneStateListener.LISTEN_NONE)
                    phoneStateListener = null
                }
            }
        }
    }
}
