package com.example.offspring_tracker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** Flutter bridge for app blocking, website filtering and usage access. */
class ProtectionPlugin(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "offspring_tracker/protection")
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pendingVpnResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                handle(call, result)
            } catch (error: Exception) {
                result.error("protection_failed", error.message, null)
            }
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> result.success(status())
            "syncRules" -> {
                BlockingRules.save(activity, parseRules(call))
                result.success(null)
            }
            "openAppBlockingSettings" -> {
                open(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                result.success(null)
            }
            "openUsageAccessSettings" -> {
                val forThisApp = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    .setData(Uri.parse("package:${activity.packageName}"))
                if (!open(forThisApp)) open(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                result.success(null)
            }
            "startWebFilter" -> startWebFilter(result)
            "stopWebFilter" -> {
                activity.startService(
                    Intent(activity, WebFilterVpnService::class.java)
                        .setAction(WebFilterVpnService.ACTION_STOP),
                )
                result.success(null)
            }
            "getUsage" -> executor.execute {
                val usage = usage()
                main.post { result.success(usage) }
            }
            else -> result.notImplemented()
        }
    }

    private fun status(): Map<String, Boolean> = mapOf(
        "appBlockingEnabled" to AppBlockerService.isEnabled(activity),
        "usageAccessGranted" to UsageReader.hasAccess(activity),
        "webFilterActive" to WebFilterVpnService.isRunning,
    )

    @Suppress("UNCHECKED_CAST")
    private fun parseRules(call: MethodCall): BlockingRules {
        val apps = call.argument<List<String>>("blockedApps") ?: emptyList()
        val limits = call.argument<Map<String, Int>>("appLimitMinutes") ?: emptyMap()
        val sites = call.argument<List<Map<String, Any>>>("blockedSites") ?: emptyList()
        return BlockingRules(
            blockedApps = apps.toSet(),
            appLimitMinutes = limits.filterValues { it > 0 },
            blockedSites = sites.mapNotNull { site ->
                val domain = (site["domain"] as? String)?.trim()?.lowercase()
                if (domain.isNullOrEmpty()) null
                else SiteRule(domain, site["includesSubdomains"] as? Boolean ?: true)
            },
        )
    }

    private fun usage(): Map<String, Map<String, Int>> {
        val today = UsageReader.todayMillis(activity)
        val week = UsageReader.weekMillis(activity)
        val attempts = BlockingRules.blockedAttempts(activity)
        return (today.keys + week.keys + attempts.keys).associateWith { pkg ->
            mapOf(
                "todayMinutes" to ((today[pkg] ?: 0L) / 60_000L).toInt(),
                "weekMinutes" to ((week[pkg] ?: 0L) / 60_000L).toInt(),
                "blockedAttempts" to (attempts[pkg] ?: 0),
            )
        }
    }

    private fun startWebFilter(result: MethodChannel.Result) {
        val consent = VpnService.prepare(activity)
        if (consent == null) {
            launchVpn()
            result.success(true)
            return
        }
        pendingVpnResult?.success(false)
        pendingVpnResult = result
        activity.startActivityForResult(consent, VPN_REQUEST_CODE)
    }

    /** Called by MainActivity with the result of the VPN consent dialog. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != VPN_REQUEST_CODE) return false
        val granted = resultCode == Activity.RESULT_OK
        if (granted) launchVpn()
        pendingVpnResult?.success(granted)
        pendingVpnResult = null
        return true
    }

    private fun launchVpn() {
        activity.startService(
            Intent(activity, WebFilterVpnService::class.java)
                .setAction(WebFilterVpnService.ACTION_START),
        )
    }

    private fun open(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (_: Exception) {
        false
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pendingVpnResult?.success(false)
        pendingVpnResult = null
        executor.shutdown()
    }

    companion object {
        private const val VPN_REQUEST_CODE = 4107
    }
}
