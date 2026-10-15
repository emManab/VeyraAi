package com.assessment.ai_chat_assistant

import android.app.Activity
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
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
    private var pendingOcrText: String = ""


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
                        events?.success(mapOf("type" to "capture", "path" to path, "ocrText" to pendingOcrText))
                        pendingCapturePath = null
                        pendingOcrText = ""
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun cacheCaptureIntent(intent: Intent?) {
        val path = intent?.getStringExtra("wingman_capture_path").orEmpty()
        if (path.isBlank()) return
        val ocrText = intent?.getStringExtra("wingman_ocr_text").orEmpty()
        val payload = mapOf("type" to "capture", "path" to path, "ocrText" to ocrText)
        if (eventSink == null) {
            pendingCapturePath = path
            pendingOcrText = ocrText
        } else {
            eventSink?.success(payload)
        }
        intent?.removeExtra("wingman_capture_path")
        intent?.removeExtra("wingman_ocr_text")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        cacheCaptureIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        cacheCaptureIntent(intent)
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

}
