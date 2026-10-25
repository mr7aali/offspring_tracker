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

    /** Foreground milliseconds per package since midnight. */
    fun todayMillis(context: Context): Map<String, Long> {
        if (!hasAccess(context)) return emptyMap()
        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = manager.queryEvents(startOfToday(), now)
        val totals = HashMap<String, Long>()
        val openedAt = HashMap<String, Long>()
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            when (event.eventType) {
                // Same values as ACTIVITY_RESUMED / ACTIVITY_PAUSED on newer Android.
                UsageEvents.Event.MOVE_TO_FOREGROUND -> openedAt.putIfAbsent(pkg, event.timeStamp)
                UsageEvents.Event.MOVE_TO_BACKGROUND -> openedAt.remove(pkg)?.let { start ->
                    totals[pkg] = (totals[pkg] ?: 0L) + (event.timeStamp - start)
                }
            }
        }
        // Apps still open right now.
        for ((pkg, start) in openedAt) totals[pkg] = (totals[pkg] ?: 0L) + (now - start)
        return totals
    }

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
