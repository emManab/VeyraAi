package com.assessment.ai_chat_assistant

import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.view.Gravity
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import org.json.JSONArray

/**
 * Veyra Keyboard is an explicit user-invoked IME. It never reads the chat field
 * or screen in the background. The user copies the messages, taps Paste chat,
 * then Analyze to send that selected text to Veyra AI.
 */
class VeyraKeyboardService : InputMethodService() {
    private val purple = Color.rgb(109, 53, 181)
    private var root: LinearLayout? = null
    private var clipboardText: String = ""
    private var preview: TextView? = null
    private var suggestions: LinearLayout? = null

    override fun onCreateInputView(): View {
        val shell = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(8), dp(8), dp(8), dp(8))
            background = solid(Color.rgb(242, 239, 248), 18)
        }
        root = shell

        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        header.addView(TextView(this).apply {
            text = "Veyra"
            textSize = 17f
            setTypeface(null, Typeface.BOLD)
            setTextColor(purple)
        }, LinearLayout.LayoutParams(0, dp(42), 1f))
        header.addView(actionButton("Paste chat") { pasteClipboard() })
        header.addView(actionButton("Analyze ↗") { analyzeClipboard() })
        shell.addView(header)

        preview = TextView(this).apply {
            text = "Copy the recent messages, then tap Paste chat."
            textSize = 12f
            setTextColor(Color.DKGRAY)
            maxLines = 2
            setPadding(dp(8), dp(5), dp(8), dp(5))
            background = solid(Color.WHITE, 10)
        }
        val previewParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(42))
        previewParams.bottomMargin = dp(6)
        shell.addView(preview, previewParams)

        suggestions = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        shell.addView(suggestions)

        addKeyRow(shell, listOf("q","w","e","r","t","y","u","i","o","p"))
        addKeyRow(shell, listOf("a","s","d","f","g","h","j","k","l"))
        addKeyRow(shell, listOf("⇧","z","x","c","v","b","n","m","⌫"))
        val bottom = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        bottom.addView(keyButton("?123", weight = 1f) { commit("123") })
        bottom.addView(keyButton(",", weight = .7f) { commit(",") })
        bottom.addView(keyButton("English · V", weight = 3.4f) { commit(" ") })
        bottom.addView(keyButton(".", weight = .7f) { commit(".") })
        bottom.addView(keyButton("↵", weight = 1f) { commit("\n") })
        shell.addView(bottom)
        refreshSuggestions()
        return shell
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        refreshSuggestions()
    }

    private fun pasteClipboard() {
        val manager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboardText = if (manager.hasPrimaryClip()) {
            manager.primaryClip?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.coerceToText(this)?.toString().orEmpty()
        } else ""
        preview?.text = if (clipboardText.isBlank()) {
            "Clipboard is empty. Copy the chat messages first."
        } else {
            clipboardText.take(220)
        }
        if (clipboardText.isBlank()) Toast.makeText(this, "Copy the conversation first, then tap Paste chat.", Toast.LENGTH_SHORT).show()
    }

    private fun analyzeClipboard() {
        if (clipboardText.isBlank()) pasteClipboard()
        if (clipboardText.isBlank()) return
        val launch = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        launch.putExtra("wingman_keyboard_text", clipboardText)
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        requestHideSelf(0)
        startActivity(launch)
    }

    private fun refreshSuggestions() {
        val host = suggestions ?: return
        host.removeAllViews()
        val json = getSharedPreferences("veyra_wingman_keyboard", Context.MODE_PRIVATE)
            .getString("replies_json", "[]") ?: "[]"
        val items = try {
            val array = JSONArray(json)
            (0 until array.length()).mapNotNull { array.optString(it).takeIf { value -> value.isNotBlank() } }.take(3)
        } catch (_: Exception) { emptyList() }
        if (items.isEmpty()) {
            host.addView(TextView(this).apply {
                text = "Your AI replies will appear here after Analyze."
                textSize = 11f
                setTextColor(Color.DKGRAY)
                setPadding(dp(4), dp(4), dp(4), dp(6))
            })
            return
        }
        host.addView(TextView(this).apply {
            text = "Tap a suggestion to insert it into the message box:"
            textSize = 11f
            setTextColor(Color.DKGRAY)
            setPadding(dp(2), dp(2), dp(2), dp(4))
        })
        items.forEachIndexed { index, reply ->
            val button = actionButton("${index + 1}. ${reply.take(88)}") {
                currentInputConnection?.commitText(reply, 1)
                requestHideSelf(0)
            }
            val params = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            params.bottomMargin = dp(4)
            host.addView(button, params)
        }
    }

    private fun addKeyRow(parent: LinearLayout, keys: List<String>) {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        keys.forEach { key ->
            val weight = if (key == "⇧" || key == "⌫") 1.35f else 1f
            row.addView(keyButton(key, weight) {
                when (key) {
                    "⌫" -> currentInputConnection?.deleteSurroundingText(1, 0)
                    "⇧" -> { /* This compact IME leaves case control to the app; standard IME remains switchable. */ }
                    else -> commit(key)
                }
            })
        }
        val params = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(42))
        params.bottomMargin = dp(4)
        parent.addView(row, params)
    }

    private fun actionButton(label: String, action: () -> Unit): Button =
        Button(this).apply {
            text = label
            textSize = 11f
            isAllCaps = false
            setTextColor(Color.WHITE)
            background = solid(purple, 10)
            setPadding(dp(7), 0, dp(7), 0)
            setOnClickListener { action() }
        }

    private fun keyButton(label: String, weight: Float, action: () -> Unit): Button =
        Button(this).apply {
            text = label
            textSize = if (label.length == 1) 17f else 12f
            isAllCaps = false
            setTextColor(Color.rgb(35, 30, 45))
            background = solid(Color.WHITE, 8)
            val params = LinearLayout.LayoutParams(0, dp(38), weight)
            params.setMargins(dp(2), 0, dp(2), 0)
            layoutParams = params
            setPadding(0, 0, 0, 0)
            setOnClickListener { action() }
        }

    private fun commit(text: String) {
        if (text == "\n") {
            val info = currentInputEditorInfo
            val action = info?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: EditorInfo.IME_ACTION_NONE
            if (action != EditorInfo.IME_ACTION_NONE) currentInputConnection?.performEditorAction(action)
            else currentInputConnection?.commitText("\n", 1)
        } else currentInputConnection?.commitText(text, 1)
    }

    private fun solid(color: Int, radius: Int) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(radius).toFloat()
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
