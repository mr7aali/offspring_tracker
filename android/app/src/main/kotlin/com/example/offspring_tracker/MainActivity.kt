package com.example.offspring_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var installedApps: InstalledAppsPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        installedApps = InstalledAppsPlugin(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        installedApps?.dispose()
        installedApps = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
