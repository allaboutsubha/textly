package app.textly.com

import android.database.Cursor
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val METHOD_CHANNEL = "com.textly.app/sms"
    private val EVENT_CHANNEL = "com.textly.app/sms_stream"
    private var smsObserver: ContentObserver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInboxSms") {
                result.success(fetchSmsList())
            } else if (call.method == "setDefaultSmsApp") {
                try {
                    val intent = android.content.Intent(android.provider.Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
                    intent.putExtra(android.provider.Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("DEFAULT_ERROR", "Failed to set default app: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // মূল content://sms/ ইউআরআই ব্যবহার করা হয়েছে যাতে যেকোনো নতুন মেসেজ আসা মাত্রই ইনস্ট্যান্ট ট্রিগার করে
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val handler = Handler(Looper.getMainLooper())
                    smsObserver = object : ContentObserver(handler) {
                        override fun onChange(selfChange: Boolean, uri: Uri?) {
                            super.onChange(selfChange, uri)
                            events?.success(fetchSmsList())
                        }
                    }
                    contentResolver.registerContentObserver(
                        Uri.parse("content://sms/"),
                        true,
                        smsObserver!!
                    )
                }

                override fun onCancel(arguments: Any?) {
                    if (smsObserver != null) {
                        contentResolver.unregisterContentObserver(smsObserver!!)
                        smsObserver = null
                    }
                }
            }
        )
    }

    private fun fetchSmsList(): List<Map<String, String>> {
        val smsList = mutableListOf<Map<String, String>>()
        try {
            val uri: Uri = Uri.parse("content://sms/inbox")
            val cursor: Cursor? = contentResolver.query(uri, null, null, null, "date DESC")
            cursor?.use {
                val addressIndex = it.getColumnIndex("address")
                val bodyIndex = it.getColumnIndex("body")
                while (it.moveToNext()) {
                    val address = if (addressIndex != -1) it.getString(addressIndex) else "Unknown"
                    val body = if (bodyIndex != -1) it.getString(bodyIndex) else ""
                    smsList.add(mapOf("address" to address, "body" to body))
                }
            }
        } catch (e: Exception) {
            // Error handling
        }
        return smsList
    }
}