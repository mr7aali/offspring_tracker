import '../entities/tracked_app.dart';
import '../entities/website_rule.dart';

/// What the phone has allowed for blocking.
class ProtectionStatus {
  const ProtectionStatus({
    required this.isSupported,
    required this.appBlockingEnabled,
    required this.usageAccessGranted,
    required this.webFilterActive,
  });

  static const unsupported = ProtectionStatus(
    isSupported: false,
    appBlockingEnabled: false,
    usageAccessGranted: false,
    webFilterActive: false,
  );

  /// False off Android, where blocking is not available.
  final bool isSupported;

  /// The app blocker (Android accessibility service) is turned on.
  final bool appBlockingEnabled;

  /// Usage access is allowed, so daily limits and screen time work.
  final bool usageAccessGranted;

  /// The website filter (local VPN) is running.
  final bool webFilterActive;
}

/// Real screen time for one app, read from the phone.
class AppUsage {
  const AppUsage({
    required this.todayMinutes,
    required this.weekMinutes,
    required this.blockedAttempts,
  });

  final int todayMinutes;
  final int weekMinutes;
  final int blockedAttempts;
}

/// Enforces app and website rules on this phone.
abstract class DeviceProtection {
  bool get isSupported;

  Future<ProtectionStatus> status();

  /// Sends the current rules to the phone's blocker and website filter.
  Future<void> applyRules({
    required List<TrackedApp> apps,
    required List<WebsiteRule> websites,
  });

  /// Removes all rules from the phone.
  Future<void> clearRules();

  Future<void> openAppBlockingSettings();

  Future<void> openUsageAccessSettings();

  /// Asks for VPN permission if needed. Returns false if the user declines.
  Future<bool> startWebFilter();

  Future<void> stopWebFilter();

  /// Usage per package name. Empty when usage access is not allowed.
  Future<Map<String, AppUsage>> usage();
}
