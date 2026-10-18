package com.example.offspring_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** Inventory of launchable apps in the current Android user/profile. */
class InstalledAppsPlugin(context: Context, messenger: BinaryMessenger) {
    private val context = context.applicationContext
    private val methods = MethodChannel(messenger, "offspring_tracker/installed_apps")
    private val events = EventChannel(messenger, "offspring_tracker/installed_apps/changes")
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var receiver: BroadcastReceiver? = null
    @Volatile private var disposed = false

    init {
        methods.setMethodCallHandler { call, result ->
            if (call.method != "getInstalledApps") {
                result.notImplemented()
            } else {
                executor.execute {
                    try {
                        val apps = discover()
                        main.post { if (!disposed) result.success(apps) }
                    } catch (error: Exception) {
                        main.post {
                            if (!disposed) result.error("inventory_failed", "Unable to read installed apps", null)
                        }
                    }
                }
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                unregister()
                val listener = object : BroadcastReceiver() {
                    override fun onReceive(context: Context?, intent: Intent?) {
                        // Replacements emit remove/add; wait until the new package is installed.
                        if (intent?.action == Intent.ACTION_PACKAGE_REMOVED &&
                            intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)) return
                        sink.success(null)
                    }
                }
                val filter = IntentFilter().apply {
                    addAction(Intent.ACTION_PACKAGE_ADDED)
                    addAction(Intent.ACTION_PACKAGE_REMOVED)
                    addAction(Intent.ACTION_PACKAGE_REPLACED)
                    addAction(Intent.ACTION_PACKAGE_CHANGED)
                    addDataScheme("package")
                }
                if (Build.VERSION.SDK_INT >= 33) {
                    context.registerReceiver(listener, filter, Context.RECEIVER_NOT_EXPORTED)
                } else {
                    @Suppress("DEPRECATION")
                    context.registerReceiver(listener, filter)
                }
                receiver = listener
            }

            override fun onCancel(arguments: Any?) = unregister()
        })
    }

    private fun discover(): List<Map<String, String>> {
        val manager = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val activities = if (Build.VERSION.SDK_INT >= 33) {
            manager.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            manager.queryIntentActivities(intent, 0)
        }
        return activities.map { it.activityInfo.applicationInfo }
            .filter { it.packageName != context.packageName }
            .distinctBy { it.packageName }
            .map { info ->
                mapOf(
                    "packageName" to info.packageName,
                    "name" to manager.getApplicationLabel(info).toString(),
                    "category" to category(info)
                )
            }.sortedBy { it["name"]?.lowercase() }
    }

    private fun category(info: ApplicationInfo): String {
        if (Build.VERSION.SDK_INT >= 26) {
            when (info.category) {
                ApplicationInfo.CATEGORY_GAME -> return "games"
                ApplicationInfo.CATEGORY_SOCIAL -> return "social"
                ApplicationInfo.CATEGORY_AUDIO, ApplicationInfo.CATEGORY_VIDEO -> return "streaming"
                ApplicationInfo.CATEGORY_PRODUCTIVITY -> return "productivity"
            }
        }
        return if (info.flags and ApplicationInfo.FLAG_SYSTEM != 0) "system" else "other"
    }

    private fun unregister() {
        receiver?.let { context.unregisterReceiver(it) }
        receiver = null
    }

    fun dispose() {
        disposed = true
        unregister()
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        executor.shutdown()
    }
}
