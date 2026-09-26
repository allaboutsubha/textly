package app.textly.com

import android.database.Cursor
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.textly.app/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInboxSms") {
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
                    result.success(smsList)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "SMS reading failed: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}