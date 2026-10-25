package com.example.offspring_tracker

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/** Full-screen notice shown when a blocked app is opened. */
class BlockedActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val appName = intent.getStringExtra(EXTRA_APP_NAME) ?: "This app"
        val reason = intent.getStringExtra(EXTRA_REASON)

        val title = if (reason == REASON_LIMIT) "Daily limit reached" else "App blocked"
        val message = if (reason == REASON_LIMIT) {
            "You have used all of today's time for $appName. It will open again tomorrow."
        } else {
            "$appName is blocked on this phone. You can change this in Offspring Tracker."
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(32), dp(32), dp(32), dp(32))
            background = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(Color.parseColor("#1D4ED8"), Color.parseColor("#4F46E5")),
            )
        }
        root.addView(TextView(this).apply {
            text = if (reason == REASON_LIMIT) "⏳" else "⛔"
            textSize = 56f
            gravity = Gravity.CENTER
        })
        root.addView(TextView(this).apply {
            text = title
            textSize = 26f
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, dp(20), 0, dp(10))
        })
        root.addView(TextView(this).apply {
            text = message
            textSize = 16f
            setTextColor(Color.argb(220, 255, 255, 255))
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.25f)
        })
        root.addView(Button(this).apply {
            text = "Go to home screen"
            isAllCaps = false
            textSize = 16f
            setTextColor(Color.parseColor("#1D4ED8"))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(16).toFloat()
            }
            setPadding(dp(28), dp(14), dp(28), dp(14))
            setOnClickListener { goHome() }
        }, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply { topMargin = dp(32) })
        setContentView(root)
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() = goHome()

    private fun goHome() {
        startActivity(
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
        finish()
    }

    private fun dp(value: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), resources.displayMetrics,
    ).toInt()

    companion object {
        const val EXTRA_APP_NAME = "appName"
        const val EXTRA_REASON = "reason"
        const val REASON_BLOCKED = "blocked"
        const val REASON_LIMIT = "limit"
    }
}
