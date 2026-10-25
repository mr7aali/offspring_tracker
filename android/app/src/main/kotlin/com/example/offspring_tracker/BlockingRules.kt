package com.example.offspring_tracker

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** A website the user wants blocked. */
data class SiteRule(val domain: String, val includesSubdomains: Boolean) {
    /** True when [host] (lower case, no trailing dot) is covered by this rule. */
    fun matches(host: String): Boolean {
        val bare = host.removePrefix("www.")
        val target = domain.removePrefix("www.")
        if (bare == target) return true
        return includesSubdomains && host.endsWith(".$target")
    }
}

/**
 * Blocking rules for this phone, saved so they keep working after the app
 * closes or the phone restarts. Written by Flutter, read by the services.
 */
data class BlockingRules(
    val blockedApps: Set<String> = emptySet(),
    val appLimitMinutes: Map<String, Int> = emptyMap(),
    val blockedSites: List<SiteRule> = emptyList(),
) {
    fun isSiteBlocked(host: String): Boolean {
        val normalized = host.trimEnd('.').lowercase()
        return blockedSites.any { it.matches(normalized) }
    }

    companion object {
        private const val PREFS = "offspring_blocking"
        private const val KEY_RULES = "rules"
        private const val KEY_ATTEMPTS = "blocked_attempts"

        @Volatile private var cached: BlockingRules? = null

        fun load(context: Context): BlockingRules {
            cached?.let { return it }
            val raw = prefs(context).getString(KEY_RULES, null)
            val rules = raw?.let { parse(it) } ?: BlockingRules()
            cached = rules
            return rules
        }

        fun save(context: Context, rules: BlockingRules) {
            prefs(context).edit().putString(KEY_RULES, encode(rules)).apply()
            cached = rules
        }

        fun recordBlockedAttempt(context: Context, packageName: String) {
            val prefs = prefs(context)
            val attempts = JSONObject(prefs.getString(KEY_ATTEMPTS, "{}") ?: "{}")
            attempts.put(packageName, attempts.optInt(packageName, 0) + 1)
            prefs.edit().putString(KEY_ATTEMPTS, attempts.toString()).apply()
        }

        fun blockedAttempts(context: Context): Map<String, Int> {
            val attempts = JSONObject(prefs(context).getString(KEY_ATTEMPTS, "{}") ?: "{}")
            return attempts.keys().asSequence().associateWith { attempts.optInt(it, 0) }
        }

        private fun prefs(context: Context) =
            context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        private fun encode(rules: BlockingRules): String = JSONObject().apply {
            put("blockedApps", JSONArray(rules.blockedApps.toList()))
            put("appLimitMinutes", JSONObject(rules.appLimitMinutes as Map<*, *>))
            put("blockedSites", JSONArray(rules.blockedSites.map {
                JSONObject().put("domain", it.domain).put("includesSubdomains", it.includesSubdomains)
            }))
        }.toString()

        private fun parse(raw: String): BlockingRules? = try {
            val json = JSONObject(raw)
            val apps = json.optJSONArray("blockedApps") ?: JSONArray()
            val limits = json.optJSONObject("appLimitMinutes") ?: JSONObject()
            val sites = json.optJSONArray("blockedSites") ?: JSONArray()
            BlockingRules(
                blockedApps = (0 until apps.length()).map { apps.getString(it) }.toSet(),
                appLimitMinutes = limits.keys().asSequence().associateWith { limits.getInt(it) },
                blockedSites = (0 until sites.length()).map {
                    val site = sites.getJSONObject(it)
                    SiteRule(site.getString("domain"), site.optBoolean("includesSubdomains", true))
                },
            )
        } catch (_: Exception) {
            null
        }
    }
}
