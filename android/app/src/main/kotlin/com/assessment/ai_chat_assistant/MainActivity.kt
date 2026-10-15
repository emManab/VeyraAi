package com.assessment.ai_chat_assistant

import android.app.Activity
import android.app.AppOpsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.app.usage.UsageStatsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "ai.veyra.wingman"
    private val eventChannelName = "ai.veyra.wingman/events"
    private val requestMediaProjection = 7013
    private var pendingStartResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var pendingCapturePath: String? = null
    private var receiverRegistered = false

    private val captureReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != WingmanOverlayService.ACTION_CAPTURED) return
            val path = intent.getStringExtra(WingmanOverlayService.EXTRA_PATH).orEmpty()
            if (path.isBlank()) {
                eventSink?.error("CAPTURE_NOT_READY", "Screen capture is not ready. Stop Wingman and start it again, approving screen capture.", null)
                return
            }
            pendingCapturePath = path
            eventSink?.success(mapOf("type" to "capture", "path" to path))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isOverlayEnabled" -> result.success(
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)
                )
                "hasUsageAccess" -> result.success(hasUsageAccess())
                "startWingman" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                        result.success(false)
                    } else if (!hasUsageAccess()) {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(false)
                    } else {
                        pendingStartResult = result
                        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        startActivityForResult(manager.createScreenCaptureIntent(), requestMediaProjection)
                    }
                }
                "stopWingman" -> {
                    stopService(Intent(this, WingmanOverlayService::class.java))
                    result.success(true)
                }
                "showSuggestions" -> {
                    val replies = call.argument<List<String>>("replies") ?: emptyList()
                    val reasons = call.argument<List<String>>("reasons") ?: emptyList()
                    val intent = Intent(this, WingmanOverlayService::class.java)
                        .setAction(WingmanOverlayService.ACTION_SHOW_SUGGESTIONS)
                        .putStringArrayListExtra(WingmanOverlayService.EXTRA_REPLIES, ArrayList(replies))
                        .putStringArrayListExtra(WingmanOverlayService.EXTRA_REASONS, ArrayList(reasons))
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    pendingCapturePath?.let { path ->
                        events?.success(mapOf("type" to "capture", "path" to path))
                        pendingCapturePath = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
        if (!receiverRegistered) {
            val filter = IntentFilter(WingmanOverlayService.ACTION_CAPTURED)
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(captureReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(captureReceiver, filter)
            }
            receiverRegistered = true
        }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    @Deprecated("Deprecated by Android, retained for MediaProjection consent compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != requestMediaProjection) return
        val result = pendingStartResult
        pendingStartResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result?.success(false)
            return
        }
        val serviceIntent = Intent(this, WingmanOverlayService::class.java)
            .putExtra(WingmanOverlayService.EXTRA_RESULT_CODE, resultCode)
            .putExtra(WingmanOverlayService.EXTRA_RESULT_DATA, data)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(serviceIntent) else startService(serviceIntent)
            result?.success(true)
        } catch (error: Exception) {
            result?.error("WINGMAN_START_FAILED", error.message ?: "Could not start the Wingman service.", null)
        }
    }

    override fun onDestroy() {
        if (receiverRegistered) {
            try { unregisterReceiver(captureReceiver) } catch (_: Throwable) { }
            receiverRegistered = false
        }
        super.onDestroy()
    }
}
