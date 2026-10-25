package com.example.offspring_tracker

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager
import java.util.concurrent.Executors

/**
 * Watches which app comes to the foreground and closes it when it is blocked
 * or has used up its daily limit. Must be turned on by the user in
 * Settings > Accessibility.
 */
class AppBlockerService : AccessibilityService() {
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private var foregroundPackage: String? = null
    private var lastBlockedPackage: String? = null
    private var lastBlockedAt = 0L
    private var ignoredPackages: Set<String> = emptySet()

    // Re-checks the open app so a limit that runs out mid-session is enforced.
    private val limitCheck = object : Runnable {
        override fun run() {
            foregroundPackage?.let { check(it) }
            main.postDelayed(this, LIMIT_CHECK_MS)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        ignoredPackages = systemPackages()
        main.postDelayed(limitCheck, LIMIT_CHECK_MS)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg in ignoredPackages) return
        foregroundPackage = pkg
        check(pkg)
    }

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        main.removeCallbacksAndMessages(null)
        worker.shutdownNow()
        super.onDestroy()
    }

    private fun check(pkg: String) {
        val rules = BlockingRules.load(this)
        if (pkg in rules.blockedApps) {
            block(pkg, BlockedActivity.REASON_BLOCKED)
            return
        }
        val limit = rules.appLimitMinutes[pkg] ?: 0
        if (limit <= 0) return
        // Reading usage events can take a moment; keep it off the main thread.
        worker.execute {
            val used = UsageReader.todayMinutes(this, pkg)
            if (used >= limit) {
                main.post {
                    if (foregroundPackage == pkg) block(pkg, BlockedActivity.REASON_LIMIT)
                }
            }
        }
    }

    private fun block(pkg: String, reason: String) {
        val now = System.currentTimeMillis()
        if (pkg == lastBlockedPackage && now - lastBlockedAt < 1500) return
        lastBlockedPackage = pkg
        lastBlockedAt = now
        foregroundPackage = null
        BlockingRules.recordBlockedAttempt(this, pkg)

        performGlobalAction(GLOBAL_ACTION_HOME)
        startActivity(
            Intent(this, BlockedActivity::class.java)
                .putExtra(BlockedActivity.EXTRA_APP_NAME, appLabel(pkg))
                .putExtra(BlockedActivity.EXTRA_REASON, reason)
                .addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TASK or
                        Intent.FLAG_ACTIVITY_NO_ANIMATION,
                ),
        )
    }

    private fun appLabel(pkg: String): String = try {
        val info = packageManager.getApplicationInfo(pkg, 0)
        packageManager.getApplicationLabel(info).toString()
    } catch (_: PackageManager.NameNotFoundException) {
        pkg
    }

    /** This app, the system UI, home screens and keyboards are never blocked. */
    private fun systemPackages(): Set<String> {
        val packages = mutableSetOf(packageName, "com.android.systemui", "com.android.settings")
        val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        @Suppress("DEPRECATION")
        packageManager.queryIntentActivities(home, 0).forEach {
            packages.add(it.activityInfo.packageName)
        }
        val keyboards = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        keyboards.enabledInputMethodList.forEach { packages.add(it.packageName) }
        return packages
    }

    companion object {
        private const val LIMIT_CHECK_MS = 30_000L

        /** Whether the user turned this service on in Accessibility settings. */
        fun isEnabled(context: Context): Boolean {
            val expected = ComponentName(context, AppBlockerService::class.java)
            val enabled = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            ) ?: return false
            return enabled.split(':').any {
                ComponentName.unflattenFromString(it) == expected
            }
        }
    }
}
