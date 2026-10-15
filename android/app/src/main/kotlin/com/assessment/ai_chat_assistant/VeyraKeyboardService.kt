package com.assessment.ai_chat_assistant

import android.content.ClipboardManager
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * Full-height, Gboard-inspired Veyra IME. AI analysis runs in a background
 * FlutterEngine and replies are rendered here; Analyze never launches MainActivity.
 * Clipboard content is read only after the user explicitly taps Paste chat.
 */
class VeyraKeyboardService : InputMethodService() {
    private val purple = Color.rgb(111, 55, 190)
    private val purpleDark = Color.rgb(75, 35, 135)
    private val ink = Color.rgb(36, 31, 43)
    private val muted = Color.rgb(111, 105, 120)
    private val panel = Color.rgb(238, 235, 244)
    private val white = Color.WHITE
    private val categories = listOf("Best", "Playful", "Flirty", "Funny", "Casual", "Confident", "Romantic")
    private val handler = Handler(Looper.getMainLooper())

    private var root: LinearLayout? = null
    private var conversationText = ""
    private var shifted = false
    private var symbolsMode = false
    private var selectedCategory = "Best"
    private var aiEngine: FlutterEngine? = null
    private var aiChannel: MethodChannel? = null
    private var aiReady = false
    private var pendingAnalysis: String? = null
    private var isAnalyzing = false

    private var conversationPreview: TextView? = null
    private var statusText: TextView? = null
    private var progress: ProgressBar? = null
    private var categoryRow: LinearLayout? = null
    private var replyText: TextView? = null
    private var replyCard: LinearLayout? = null
    private var insertButton: TextView? = null
    private var keyRows: LinearLayout? = null
    private var replyOptions: List<ReplyOption> = emptyList()

    override fun onCreate() {
        super.onCreate()
        loadSavedReplies()
        ensureAiEngine()
    }

    override fun onCreateInputView(): View {
        val shell = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(7), dp(7), dp(7), dp(8))
            background = rounded(panel, 22)
        }
        root = shell

        // Toolbar, sized for thumb-friendly use.
        val toolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val brand = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        brand.addView(TextView(this).apply {
            text = "V"
            textSize = 19f
            gravity = Gravity.CENTER
            setTextColor(white)
            setTypeface(typeface, Typeface.BOLD)
            background = rounded(purple, 12)
        }, LinearLayout.LayoutParams(dp(34), dp(34)))
        brand.addView(TextView(this).apply {
            text = "Veyra"
            textSize = 16f
            setTextColor(ink)
            setTypeface(typeface, Typeface.BOLD)
            setPadding(dp(7), 0, 0, 0)
        })
        toolbar.addView(brand, LinearLayout.LayoutParams(0, dp(38), 1f))
        toolbar.addView(topAction("Paste chat", false) { pasteClipboard() })
        toolbar.addView(topAction("Analyze", true) { analyzeConversation() })
        shell.addView(toolbar)

        conversationPreview = TextView(this).apply {
            text = "Copy recent messages, then tap Paste chat."
            textSize = 12f
            setTextColor(muted)
            maxLines = 2
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(10), dp(5), dp(10), dp(5))
            background = rounded(white, 12)
        }
        val previewParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(32))
        previewParams.topMargin = dp(4)
        shell.addView(conversationPreview, previewParams)

        val replyHeader = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        statusText = TextView(this).apply {
            text = "Choose a style, then insert a reply."
            textSize = 11f
            setTextColor(muted)
            maxLines = 1
        }
        replyHeader.addView(statusText, LinearLayout.LayoutParams(0, dp(21), 1f))
        progress = ProgressBar(this).apply {
            isIndeterminate = true
            visibility = View.GONE
        }
        replyHeader.addView(progress, LinearLayout.LayoutParams(dp(18), dp(18)))
        shell.addView(replyHeader)

        val categoryScroll = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            overScrollMode = View.OVER_SCROLL_NEVER
        }
        categoryRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        categoryScroll.addView(categoryRow)
        val categoryParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(38))
        categoryParams.bottomMargin = dp(4)
        shell.addView(categoryScroll, categoryParams)
        renderCategories()

        replyCard = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(11), dp(7), dp(7), dp(7))
            background = rounded(white, 14)
        }
        replyText = TextView(this).apply {
            text = "Your suggestions will appear here."
            textSize = 13f
            setTextColor(ink)
            maxLines = 3
            gravity = Gravity.CENTER_VERTICAL
        }
        replyCard!!.addView(replyText, LinearLayout.LayoutParams(0, dp(49), 1f))
        insertButton = TextView(this).apply {
            text = "Insert"
            textSize = 12f
            gravity = Gravity.CENTER
            setTextColor(white)
            setTypeface(typeface, Typeface.BOLD)
            background = rounded(purple, 12)
            setPadding(dp(13), 0, dp(13), 0)
            setOnClickListener { insertSelectedReply() }
        }
        replyCard!!.addView(insertButton, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(40)))
        val replyParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(60))
        replyParams.bottomMargin = dp(5)
        shell.addView(replyCard, replyParams)

        keyRows = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        shell.addView(keyRows, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(170)))
        renderKeyboardRows()
        renderSelectedReply()
        return shell
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        loadSavedReplies()
        renderCategories()
        renderSelectedReply()
        ensureAiEngine()
    }

    override fun onDestroy() {
        aiEngine?.destroy()
        aiEngine = null
        aiChannel = null
        super.onDestroy()
    }

    private fun ensureAiEngine() {
        if (aiEngine != null) return
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            val engine = FlutterEngine(applicationContext)
            aiEngine = engine
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "ai.veyra.keyboard_ai")
            aiChannel = channel
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "ready" -> {
                        aiReady = true
                        result.success(null)
                        val pending = pendingAnalysis
                        if (pending != null) {
                            pendingAnalysis = null
                            runAnalysis(pending)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "wingmanKeyboardMain", "package:ai_chat_assistant/keyboard_background.dart")
            )
        } catch (error: Exception) {
            updateStatus("AI engine could not start. Reopen Veyra Keyboard.", error = true)
        }
    }

    private fun pasteClipboard() {
        // Clipboard access happens only as a direct result of this user action.
        val manager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        conversationText = if (manager.hasPrimaryClip()) {
            manager.primaryClip?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.coerceToText(this)?.toString().orEmpty()
        } else ""
        conversationPreview?.text = when {
            conversationText.isBlank() -> "Clipboard is empty. Copy messages in the chat first."
            else -> conversationText.take(210)
        }
        if (conversationText.isBlank()) {
            updateStatus("Copy the chat first, then tap Paste chat.", error = true)
        } else {
            updateStatus("Chat ready · choose a reply style.")
        }
    }

    private fun analyzeConversation() {
        if (isAnalyzing) return
        if (conversationText.isBlank()) pasteClipboard()
        if (conversationText.isBlank()) return
        ensureAiEngine()
        isAnalyzing = true
        pendingAnalysis = conversationText
        setLoading(true)
        updateStatus("Analyzing conversation…")
        if (aiReady) {
            val pending = pendingAnalysis
            pendingAnalysis = null
            if (pending != null) runAnalysis(pending)
        } else {
            // The background engine sends "ready" when its Dart entry point is initialized.
            handler.postDelayed({
                if (isAnalyzing && !aiReady) {
                    isAnalyzing = false
                    pendingAnalysis = null
                    setLoading(false)
                    updateStatus("AI is still starting. Tap Analyze again in a moment.", error = true)
                }
            }, 20000)
        }
    }

    private fun runAnalysis(text: String) {
        val channel = aiChannel
        if (channel == null || !aiReady) {
            isAnalyzing = false
            setLoading(false)
            updateStatus("AI is unavailable. Try reopening the keyboard.", error = true)
            return
        }
        channel.invokeMethod("analyze", mapOf("conversation" to text), object : MethodChannel.Result {
            override fun success(result: Any?) {
                isAnalyzing = false
                setLoading(false)
                try {
                    val payload = result as? Map<*, *> ?: error("The AI returned an invalid response.")
                    val items = payload["replies"] as? List<*> ?: emptyList<Any>()
                    replyOptions = items.mapNotNull { item ->
                        val map = item as? Map<*, *> ?: return@mapNotNull null
                        val category = map["category"]?.toString().orEmpty()
                        val reply = map["text"]?.toString().orEmpty()
                        if (category.isBlank() || reply.isBlank()) null else ReplyOption(category, reply)
                    }
                    if (replyOptions.isEmpty()) error("No usable replies were returned.")
                    selectedCategory = if (replyOptions.any { it.category == selectedCategory }) selectedCategory else "Best"
                    saveReplies()
                    renderCategories()
                    renderSelectedReply()
                    updateStatus("Ready · tap Insert to use the selected reply.")
                } catch (error: Exception) {
                    updateStatus(error.message ?: "Could not read AI replies.", error = true)
                }
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                isAnalyzing = false
                setLoading(false)
                updateStatus(errorMessage ?: "AI request failed. Try again.", error = true)
            }

            override fun notImplemented() {
                isAnalyzing = false
                setLoading(false)
                updateStatus("Keyboard AI is not available in this build.", error = true)
            }
        })
    }

    private fun renderCategories() {
        val row = categoryRow ?: return
        row.removeAllViews()
        categories.forEach { category ->
            val selected = category == selectedCategory
            val chip = TextView(this).apply {
                text = category
                textSize = 12f
                gravity = Gravity.CENTER
                setTypeface(typeface, if (selected) Typeface.BOLD else Typeface.NORMAL)
                setTextColor(if (selected) white else ink)
                background = rounded(if (selected) purple else white, 18)
                setPadding(dp(13), 0, dp(13), 0)
                setOnClickListener {
                    selectedCategory = category
                    renderCategories()
                    renderSelectedReply()
                }
            }
            val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(32))
            params.setMargins(0, 0, dp(6), 0)
            row.addView(chip, params)
        }
    }

    private fun renderSelectedReply() {
        val option = replyOptions.firstOrNull { it.category == selectedCategory }
        replyText?.text = when {
            isAnalyzing -> "Reading the conversation and writing replies…"
            option != null -> option.text
            replyOptions.isNotEmpty() -> "No ${selectedCategory.lowercase()} reply was returned. Choose another style."
            else -> "Your suggestions will appear here."
        }
        insertButton?.apply {
            isEnabled = option != null && !isAnalyzing
            alpha = if (isEnabled) 1f else .45f
        }
    }

    private fun insertSelectedReply() {
        val option = replyOptions.firstOrNull { it.category == selectedCategory } ?: return
        currentInputConnection?.commitText(option.text, 1)
        updateStatus("${option.category} reply inserted · review before sending.")
    }

    private fun setLoading(loading: Boolean) {
        isAnalyzing = loading
        progress?.visibility = if (loading) View.VISIBLE else View.GONE
        renderCategories()
        renderSelectedReply()
    }

    private fun updateStatus(message: String, error: Boolean = false) {
        statusText?.text = message
        statusText?.setTextColor(if (error) Color.rgb(176, 36, 57) else muted)
    }

    private fun saveReplies() {
        val array = JSONArray()
        replyOptions.forEach { option ->
            array.put(JSONObject().put("category", option.category).put("text", option.text))
        }
        getSharedPreferences("veyra_wingman_keyboard", Context.MODE_PRIVATE)
            .edit().putString("categorized_replies_json", array.toString()).apply()
    }

    private fun loadSavedReplies() {
        val json = getSharedPreferences("veyra_wingman_keyboard", Context.MODE_PRIVATE)
            .getString("categorized_replies_json", "[]") ?: "[]"
        replyOptions = try {
            val array = JSONArray(json)
            (0 until array.length()).mapNotNull { index ->
                val item = array.optJSONObject(index) ?: return@mapNotNull null
                val category = item.optString("category")
                val text = item.optString("text")
                if (category.isBlank() || text.isBlank()) null else ReplyOption(category, text)
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun renderKeyboardRows() {
        val host = keyRows ?: return
        host.removeAllViews()
        val rows = if (!symbolsMode) {
            listOf(
                listOf("q","w","e","r","t","y","u","i","o","p"),
                listOf("a","s","d","f","g","h","j","k","l"),
                listOf("SHIFT","z","x","c","v","b","n","m","DELETE"),
            )
        } else {
            listOf(
                listOf("1","2","3","4","5","6","7","8","9","0"),
                listOf("@","#","$","%","&","-","+","(",")","/"),
                listOf("=<>","*","\"",'",":",";","!","?","DELETE"),
            )
        }
        rows.forEachIndexed { index, labels ->
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
            }
            labels.forEach { label ->
                val special = label == "SHIFT" || label == "DELETE" || label == "=<>"
                val key = keyView(keyLabel(label), special)
                val weight = when (label) {
                    "SHIFT", "DELETE", "=<>" -> 1.45f
                    else -> 1f
                }
                row.addView(key, LinearLayout.LayoutParams(0, dp(if (index == 2) 39 else 38), weight).apply {
                    setMargins(dp(2), dp(2), dp(2), dp(2))
                })
                key.setOnClickListener { handleKey(label) }
                if (label == "DELETE") {
                    key.setOnLongClickListener {
                        currentInputConnection?.deleteSurroundingText(20, 0)
                        true
                    }
                }
            }
            host.addView(row, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(42)))
        }

        val bottom = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        val bottomKeys = listOf(
            Triple("🌐", .9f, { switchToNextInputMethod(false) }),
            Triple(if (symbolsMode) "ABC" else "?123", 1.15f, { symbolsMode = !symbolsMode; renderKeyboardRows() }),
            Triple(",", .7f, { commit(",") }),
            Triple("English · V", 4.2f, { commit(" ") }),
            Triple(".", .7f, { commit(".") }),
            Triple("↵", 1.15f, { commit("\n") }),
        )
        bottomKeys.forEach { (label, weight, action) ->
            val key = keyView(label, label == "?123" || label == "ABC" || label == "↵")
            bottom.addView(key, LinearLayout.LayoutParams(0, dp(40), weight).apply {
                setMargins(dp(2), dp(2), dp(2), dp(2))
            })
            key.setOnClickListener { action() }
        }
        host.addView(bottom, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44)))
    }

    private fun keyLabel(label: String): String = when (label) {
        "SHIFT" -> if (shifted) "⬆" else "⇧"
        "DELETE" -> "⌫"
        else -> if (shifted && label.length == 1 && label[0].isLetter()) label.uppercase() else label
    }

    private fun handleKey(label: String) {
        when (label) {
            "SHIFT" -> {
                shifted = !shifted
                renderKeyboardRows()
            }
            "DELETE" -> currentInputConnection?.deleteSurroundingText(1, 0)
            "=<>" -> {
                symbolsMode = true
                renderKeyboardRows()
            }
            else -> {
                val text = if (shifted && label.length == 1 && label[0].isLetter()) label.uppercase() else label
                commit(text)
                if (shifted) {
                    shifted = false
                    renderKeyboardRows()
                }
            }
        }
    }

    private fun commit(text: String) {
        if (text == "\n") {
            val info = currentInputEditorInfo
            val action = info?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: EditorInfo.IME_ACTION_NONE
            if (action != EditorInfo.IME_ACTION_NONE) currentInputConnection?.performEditorAction(action)
            else currentInputConnection?.commitText("\n", 1)
        } else currentInputConnection?.commitText(text, 1)
    }

    private fun topAction(label: String, primary: Boolean, action: () -> Unit): TextView =
        TextView(this).apply {
            text = label
            textSize = 12f
            gravity = Gravity.CENTER
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(if (primary) white else purpleDark)
            background = rounded(if (primary) purple else Color.rgb(225, 216, 241), 12)
            setPadding(dp(11), 0, dp(11), 0)
            val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(36))
            params.setMargins(dp(3), 0, 0, 0)
            layoutParams = params
            setOnClickListener { action() }
        }

    private fun keyView(label: String, special: Boolean): TextView = TextView(this).apply {
        text = label
        textSize = when {
            label == "English · V" -> 12f
            label.length == 1 -> 18f
            else -> 13f
        }
        gravity = Gravity.CENTER
        setTextColor(if (special) ink else Color.rgb(45, 40, 52))
        setTypeface(typeface, if (special) Typeface.BOLD else Typeface.NORMAL)
        background = rounded(if (special) Color.rgb(218, 212, 229) else white, 8)
        elevation = dp(1).toFloat()
        isClickable = true
        isFocusable = true
    }

    private fun rounded(color: Int, radius: Int) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(radius).toFloat()
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    private data class ReplyOption(val category: String, val text: String)
}
