package com.assessment.ai_chat_assistant

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.provider.Settings
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import android.content.pm.ServiceInfo
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

/**
 * User-started overlay service. It only watches which package is foreground and
 * captures a screenshot after the user taps the visible V bubble.
 */
class WingmanOverlayService : Service() {
    companion object {
        const val ACTION_CAPTURED = "com.assessment.ai_chat_assistant.WINGMAN_CAPTURED"
        const val ACTION_SHOW_SUGGESTIONS = "com.assessment.ai_chat_assistant.WINGMAN_SHOW_SUGGESTIONS"
        const val ACTION_STOP = "com.assessment.ai_chat_assistant.WINGMAN_STOP"
        const val EXTRA_PATH = "capture_path"
        const val EXTRA_RESULT_CODE = "projection_result_code"
        const val EXTRA_RESULT_DATA = "projection_result_data"
        const val EXTRA_REPLIES = "replies"
        const val EXTRA_REASONS = "reasons"
        private const val NOTIFICATION_ID = 7012
        private const val CHANNEL_ID = "veyra_wingman_running"
        private const val POLL_MS = 1200L

        val supportedPackages = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
            "com.instagram.android",
            "com.tinder",
            "com.bumble.app",
            "co.hinge.app"
        )
    }

    private lateinit var windowManager: WindowManager
    private lateinit var handlerThread: HandlerThread
    private lateinit var worker: Handler
    private val mainHandler = Handler()
    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var bubble: View? = null
    private var panel: View? = null
    private var bubbleParams: WindowManager.LayoutParams? = null
    private var panelParams: WindowManager.LayoutParams? = null
    private var currentTarget: String? = null
    private var currentForegroundPackage: String? = null
    private var lastUsageQueryTime = System.currentTimeMillis() - 86_400_000L
    private var captureRequested = AtomicBoolean(false)
    private var replies: List<String> = emptyList()
    private var reasons: List<String> = emptyList()
    private var isCaptureReady = false
    private var overlayAdded = false
    private var lastCaptureAt = 0L

    private val pollForeground = object : Runnable {
        override fun run() {
            try {
                val target = foregroundTargetPackage()
                currentTarget = target
                if (target != null && canDrawOverlays()) {
                    if (replies.isNotEmpty()) showSuggestionsPanel() else showBubble()
                } else {
                    hideOverlayViews()
                }
            } catch (_: Throwable) {
                hideOverlayViews()
            }
            mainHandler.postDelayed(this, POLL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        handlerThread = HandlerThread("VeyraWingmanCapture").apply { start() }
        worker = Handler(handlerThread.looper)
        createNotificationChannel()
        startForegroundSafely()
        mainHandler.post(pollForeground)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_SHOW_SUGGESTIONS -> {
                // A MediaProjection session cannot be silently recreated after Android kills it.
                if (projection == null) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                replies = intent.getStringArrayListExtra(EXTRA_REPLIES) ?: emptyList()
                reasons = intent.getStringArrayListExtra(EXTRA_REASONS) ?: emptyList()
                if (currentTarget != null) showSuggestionsPanel()
                return START_NOT_STICKY
            }
        }

        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, 0) ?: 0
        val resultData = if (Build.VERSION.SDK_INT >= 33) {
            intent?.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent?.getParcelableExtra(EXTRA_RESULT_DATA)
        }
        if (resultCode != 0 && resultData != null && projection == null) {
            startProjection(resultCode, resultData)
        }
        return START_NOT_STICKY
    }

    private fun startForegroundSafely() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pending = PendingIntent.getActivity(
            this, 7012, launchIntent ?: Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val notification = builder
            .setContentTitle("Veyra Wingman is active")
            .setContentText("A floating bubble appears in supported chat apps. Tap it to analyze a screenshot.")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setContentIntent(pending)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Wingman session", NotificationManager.IMPORTANCE_LOW)
            )
        }
    }

    private fun startProjection(resultCode: Int, data: Intent) {
        try {
            val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            projection = manager.getMediaProjection(resultCode, data)
            val metrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getRealMetrics(metrics)
            val width = metrics.widthPixels.coerceAtLeast(1)
            val height = metrics.heightPixels.coerceAtLeast(1)
            val density = metrics.densityDpi
            imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            imageReader?.setOnImageAvailableListener({ reader ->
                val image = try { reader.acquireLatestImage() } catch (_: Throwable) { null }
                if (image != null) {
                    if (captureRequested.compareAndSet(true, false)) {
                        saveImage(image)
                    }
                    image.close()
                }
            }, worker)
            projection?.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    isCaptureReady = false
                    stopSelf()
                }
            }, worker)
            virtualDisplay = projection?.createVirtualDisplay(
                "VeyraWingmanCapture", width, height, density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface, null, worker
            )
            isCaptureReady = virtualDisplay != null
        } catch (_: Throwable) {
            isCaptureReady = false
        }
    }

    private fun saveImage(image: Image) {
        try {
            val plane = image.planes[0]
            val buffer: ByteBuffer = plane.buffer
            val pixelStride = plane.pixelStride
            val rowStride = plane.rowStride
            val rowPadding = rowStride - pixelStride * image.width
            val paddedWidth = image.width + rowPadding / pixelStride
            val padded = Bitmap.createBitmap(paddedWidth, image.height, Bitmap.Config.ARGB_8888)
            padded.copyPixelsFromBuffer(buffer)
            val bitmap = Bitmap.createBitmap(padded, 0, 0, image.width, image.height)
            val file = File(cacheDir, "wingman_capture_${System.currentTimeMillis()}.jpg")
            FileOutputStream(file).use { output -> bitmap.compress(Bitmap.CompressFormat.JPEG, 88, output) }
            padded.recycle()
            bitmap.recycle()
            lastCaptureAt = System.currentTimeMillis()
            // OCR runs on-device. Only the extracted text is sent to the selected
            // AI provider when Flutter starts analysis; the image remains in cache.
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            val input = InputImage.fromFilePath(this, Uri.fromFile(file))
            recognizer.process(input)
                .addOnSuccessListener { recognized ->
                    recognizer.close()
                    deliverCapture(file.absolutePath, recognized.text)
                }
                .addOnFailureListener {
                    recognizer.close()
                    deliverCapture(file.absolutePath, "")
                }
        } catch (_: Throwable) {
            captureRequested.set(false)
        }
    }

    private fun deliverCapture(path: String, recognizedText: String) {
        val event = Intent(ACTION_CAPTURED).setPackage(packageName)
            .putExtra(EXTRA_PATH, path)
            .putExtra("ocr_text", recognizedText)
        sendBroadcast(event)
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(launch)
        }
    }

    private fun foregroundTargetPackage(): String? {
        val usage = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        // Query the whole day once to establish the current foreground app, then
        // overlap the last few seconds so lifecycle events aren't lost between polls.
        val begin = if (lastUsageQueryTime < now - 80_000L) now - 86_400_000L else now - 5_000L
        val events = usage.queryEvents(begin, now)
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val resumed = if (Build.VERSION.SDK_INT >= 29) {
                event.eventType == UsageEvents.Event.ACTIVITY_RESUMED
            } else {
                @Suppress("DEPRECATION")
                event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND
            }
            if (resumed) {
                currentForegroundPackage = event.packageName
            }
        }
        lastUsageQueryTime = now
        return currentForegroundPackage?.takeIf { it in supportedPackages }
    }

    private fun showBubble() {
        if (bubble != null || !canDrawOverlays()) return
        val button = TextView(this).apply {
            text = "V"
            textSize = 22f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
            background = rounded(0xFF6D35B5.toInt(), 100)
            elevation = dp(8).toFloat()
            contentDescription = "Veyra Wingman. Tap to analyze this screen."
        }
        val params = WindowManager.LayoutParams(
            dp(58), dp(58),
            if (Build.VERSION.SDK_INT >= 26) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = dp(12)
            y = dp(210)
        }
        attachDragAndTap(button, params) { requestCapture() }
        try {
            windowManager.addView(button, params)
            bubble = button
            bubbleParams = params
            overlayAdded = true
        } catch (_: Throwable) { }
    }

    private fun attachDragAndTap(view: View, params: WindowManager.LayoutParams, onTap: () -> Unit) {
        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        var dragged = false
        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX; downY = event.rawY
                    startX = params.x; startY = params.y
                    dragged = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - downX).toInt()
                    val dy = (event.rawY - downY).toInt()
                    if (kotlin.math.abs(dx) > dp(6) || kotlin.math.abs(dy) > dp(6)) dragged = true
                    params.x = startX + dx
                    params.y = startY + dy
                    try { windowManager.updateViewLayout(view, params) } catch (_: Throwable) { }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!dragged) onTap()
                    true
                }
                else -> false
            }
        }
    }

    private fun requestCapture() {
        if (!isCaptureReady || imageReader == null) {
            val event = Intent(ACTION_CAPTURED).setPackage(packageName).putExtra(EXTRA_PATH, "")
            sendBroadcast(event)
            return
        }
        if (System.currentTimeMillis() - lastCaptureAt < 1200L) return
        // Remove the bubble from the frame so it does not cover conversation text.
        hideOverlayViews()
        mainHandler.postDelayed({ captureRequested.set(true) }, 180L)
    }

    private fun showSuggestionsPanel() {
        if (!Settings.canDrawOverlays(this)) return
        if (replies.isEmpty()) { showBubble(); return }
        if (panel != null) return
        hideBubbleOnly()
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(14), dp(12), dp(14), dp(12))
            background = rounded(0xF21C1826.toInt(), 20)
            elevation = dp(12).toFloat()
        }
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val title = TextView(this).apply {
            text = "Veyra replies"
            textSize = 15f
            setTextColor(0xFFFFFFFF.toInt())
            typeface = Typeface.DEFAULT_BOLD
        }
        val close = TextView(this).apply {
            text = "×"
            textSize = 25f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(dp(12), 0, dp(4), 0)
            setOnClickListener { replies = emptyList(); hideOverlayViews() }
        }
        header.addView(title, LinearLayout.LayoutParams(0, dp(36), 1f))
        header.addView(close)
        container.addView(header)
        replies.take(3).forEachIndexed { index, reply ->
            val copy = Button(this).apply {
                text = "${index + 1}. ${reply.take(100)}  ·  COPY"
                textSize = 12f
                isAllCaps = false
                setTextColor(0xFFFFFFFF.toInt())
                background = rounded(0xFF6D35B5.toInt(), 12)
                setOnClickListener {
                    val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    clipboard.setPrimaryClip(ClipData.newPlainText("Veyra suggested reply", reply))
                    text = "Copied ✓"
                }
            }
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            lp.topMargin = dp(7)
            container.addView(copy, lp)
        }
        val note = TextView(this).apply {
            text = "Review and send it yourself"
            textSize = 10f
            setTextColor(0xFFCBC3D7.toInt())
            setPadding(0, dp(8), 0, 0)
        }
        container.addView(note)
        val params = WindowManager.LayoutParams(
            dp(300), WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= 26) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = dp(8)
            y = dp(150)
        }
        try {
            windowManager.addView(container, params)
            panel = container
            panelParams = params
            overlayAdded = true
        } catch (_: Throwable) { }
    }

    private fun hideBubbleOnly() {
        bubble?.let { try { windowManager.removeView(it) } catch (_: Throwable) { } }
        bubble = null
        bubbleParams = null
    }

    private fun hideOverlayViews() {
        hideBubbleOnly()
        panel?.let { try { windowManager.removeView(it) } catch (_: Throwable) { } }
        panel = null
        panelParams = null
        overlayAdded = false
    }

    private fun canDrawOverlays(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)

    private fun rounded(color: Int, radius: Int): GradientDrawable =
        GradientDrawable().apply { setColor(color); cornerRadius = dp(radius).toFloat() }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    override fun onDestroy() {
        mainHandler.removeCallbacks(pollForeground)
        hideOverlayViews()
        try { virtualDisplay?.release() } catch (_: Throwable) { }
        try { imageReader?.close() } catch (_: Throwable) { }
        try { projection?.stop() } catch (_: Throwable) { }
        try { handlerThread.quitSafely() } catch (_: Throwable) { }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
