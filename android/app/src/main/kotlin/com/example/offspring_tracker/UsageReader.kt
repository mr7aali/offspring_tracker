package com.example.offspring_tracker

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Process
import java.util.Calendar

/** Reads per-app foreground time from Android's usage statistics. */
object UsageReader {
    private const val DAY_MS = 24L * 60 * 60 * 1000

    /** Whether the user allowed Usage access for this app in Settings. */
    fun hasAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= 29) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Foreground milliseconds per package since midnight.
     *
     * Only one app is treated as on screen at a time, and time stops when the
     * screen turns off or locks, so the total can never exceed the time since
     * midnight.
     */
    fun todayMillis(context: Context): Map<String, Long> {
        if (!hasAccess(context)) return emptyMap()
        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val midnight = startOfToday()
        // Look back a little so an app opened before midnight is counted from midnight.
        val events = manager.queryEvents(midnight - LOOKBACK_MS, now)
        val totals = HashMap<String, Long>()
        var current: String? = null
        var startedAt = 0L

        fun close(at: Long) {
            val pkg = current ?: return
            val from = maxOf(startedAt, midnight)
            if (at > from) totals[pkg] = (totals[pkg] ?: 0L) + (at - from)
            current = null
        }

        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            when (event.eventType) {
                ACTIVITY_RESUMED -> if (pkg != current) {
                    close(event.timeStamp)
                    current = pkg
                    startedAt = event.timeStamp
                }
                ACTIVITY_PAUSED, ACTIVITY_STOPPED -> if (pkg == current) close(event.timeStamp)
                SCREEN_NON_INTERACTIVE, KEYGUARD_SHOWN, DEVICE_SHUTDOWN -> close(event.timeStamp)
            }
        }
        close(now) // the app on screen right now
        return totals
    }

    // UsageEvents.Event type values (stable across Android versions).
    private const val ACTIVITY_RESUMED = 1
    private const val ACTIVITY_PAUSED = 2
    private const val SCREEN_NON_INTERACTIVE = 16
    private const val KEYGUARD_SHOWN = 17
    private const val ACTIVITY_STOPPED = 23
    private const val DEVICE_SHUTDOWN = 26
    private const val LOOKBACK_MS = 3L * 60 * 60 * 1000

    /** Foreground milliseconds per package over the last 7 days. */
    fun weekMillis(context: Context): Map<String, Long> {
        if (!hasAccess(context)) return emptyMap()
        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        return manager.queryAndAggregateUsageStats(now - 7 * DAY_MS, now)
            .mapValues { it.value.totalTimeInForeground }
    }

    fun todayMinutes(context: Context, packageName: String): Int =
        ((todayMillis(context)[packageName] ?: 0L) / 60_000L).toInt()

    private fun startOfToday(): Long = Calendar.getInstance().apply {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis
}
