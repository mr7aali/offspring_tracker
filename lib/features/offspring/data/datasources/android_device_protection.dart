import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/tracked_app.dart';
import '../../domain/entities/website_rule.dart';
import '../../domain/repositories/device_protection.dart';

/// Talks to the native blocker, website filter and usage reader on Android.
class AndroidDeviceProtection implements DeviceProtection {
  static const channel = MethodChannel('offspring_tracker/protection');

  /// Reads should never hold up the dashboard if the native side is missing.
  static const _readTimeout = Duration(seconds: 3);

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<ProtectionStatus> status() async {
    if (!isSupported) return ProtectionStatus.unsupported;
    try {
      final data = await channel
          .invokeMapMethod<String, Object?>('getStatus')
          .timeout(_readTimeout);
      if (data == null) return ProtectionStatus.unsupported;
      return ProtectionStatus(
        isSupported: true,
        appBlockingEnabled: data['appBlockingEnabled'] == true,
        usageAccessGranted: data['usageAccessGranted'] == true,
        webFilterActive: data['webFilterActive'] == true,
      );
    } on MissingPluginException {
      return ProtectionStatus.unsupported;
    } on PlatformException {
      return ProtectionStatus.unsupported;
    } on TimeoutException {
      return ProtectionStatus.unsupported;
    }
  }

  @override
  Future<void> applyRules({
    required List<TrackedApp> apps,
    required List<WebsiteRule> websites,
  }) {
    return _invoke('syncRules', {
      'blockedApps': [
        for (final app in apps)
          if (app.isBlocked) app.packageName,
      ],
      'appLimitMinutes': {
        for (final app in apps)
          if (app.hasLimit) app.packageName: app.dailyLimitMinutes,
      },
      'blockedSites': [
        for (final rule in websites)
          if (rule.isBlocked)
            {
              'domain': rule.domain,
              'includesSubdomains': rule.includesSubdomains,
            },
      ],
    });
  }

  @override
  Future<void> clearRules() => applyRules(apps: const [], websites: const []);

  @override
  Future<void> openAppBlockingSettings() => _invoke('openAppBlockingSettings');

  @override
  Future<void> openUsageAccessSettings() => _invoke('openUsageAccessSettings');

  @override
  Future<bool> startWebFilter() async {
    if (!isSupported) return false;
    try {
      return await channel.invokeMethod<bool>('startWebFilter') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> stopWebFilter() => _invoke('stopWebFilter');

  @override
  Future<Map<String, AppUsage>> usage() async {
    if (!isSupported) return const {};
    try {
      final data = await channel
          .invokeMapMethod<String, Object?>('getUsage')
          .timeout(_readTimeout);
      if (data == null) return const {};
      return {
        for (final entry in data.entries)
          if (entry.value is Map)
            entry.key: _toUsage(Map<String, Object?>.from(entry.value as Map)),
      };
    } on MissingPluginException {
      return const {};
    } on PlatformException {
      return const {};
    } on TimeoutException {
      return const {};
    }
  }

  AppUsage _toUsage(Map<String, Object?> row) {
    int read(String key) => (row[key] as num?)?.toInt() ?? 0;
    return AppUsage(
      todayMinutes: read('todayMinutes'),
      weekMinutes: read('weekMinutes'),
      blockedAttempts: read('blockedAttempts'),
    );
  }

  /// Calls the native side, ignoring platforms or builds without it.
  Future<void> _invoke(String method, [Object? arguments]) async {
    if (!isSupported) return;
    try {
      await channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      return;
    } on PlatformException catch (error) {
      debugPrint('Device protection "$method" failed: ${error.message}');
    }
  }
}
