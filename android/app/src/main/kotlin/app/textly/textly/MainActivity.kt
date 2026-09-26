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
            when (call.method) {
                "getGroupedSms" -> {
                    result.success(fetchGroupedSms())
                }
                "deleteSms" -> {
                    val id = call.argument<String>("id")
                    if (id != null) {
                        val deleted = deleteSmsById(id)
                        result.success(deleted)
                    } else {
                        result.error("INVALID_ID", "SMS ID missing", null)
                    }
                }
                "setDefaultSmsApp" -> {
                    try {
                        val intent = android.content.Intent(android.provider.Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
                        intent.putExtra(android.provider.Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DEFAULT_ERROR", "Failed to set default app: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val handler = Handler(Looper.getMainLooper())
                    smsObserver = object : ContentObserver(handler) {
                        override fun onChange(selfChange: Boolean, uri: Uri?) {
                            super.onChange(selfChange, uri)
                            events?.success(fetchGroupedSms())
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

    private fun fetchGroupedSms(): List<Map<String, Any>> {
        val groupedMap = mutableMapOf<String, MutableMap<String, Any>>()
        try {
            val uri: Uri = Uri.parse("content://sms/inbox")
            val cursor: Cursor? = contentResolver.query(uri, null, null, null, "date DESC")
            cursor?.use {
                val idIndex = it.getColumnIndex("_id")
                val addressIndex = it.getColumnIndex("address")
                val bodyIndex = it.getColumnIndex("body")
                val dateIndex = it.getColumnIndex("date")

                while (it.moveToNext()) {
                    val id = if (idIndex != -1) it.getString(idIndex) else ""
                    val address = if (addressIndex != -1) it.getString(addressIndex) else "Unknown"
                    val body = if (bodyIndex != -1) it.getString(bodyIndex) else ""
                    val date = if (dateIndex != -1) it.getString(dateIndex) else ""

                    val smsItem = mapOf("id" to id, "body" to body, "date" to date)

                    if (!groupedMap.containsKey(address)) {
                        groupedMap[address] = mutableMapOf(
                            "sender" to address,
                            "lastMessage" to body,
                            "date" to date,
                            "messages" to mutableListOf<Map<String, String>>()
                        )
                    }
                    val messagesList = groupedMap[address]?.get("messages") as MutableList<Map<String, String>>
                    messagesList.add(smsItem)
                }
            }
        } catch (e: Exception) {
            // Error handling
        }
        return groupedMap.values.toList()
    }

    private fun deleteSmsById(id: String): Boolean {
        return try {
            val uri = Uri.parse("content://sms/$id")
            contentResolver.delete(uri, null, null) > 0
        } catch (e: Exception) {
            false
        }
    }
}