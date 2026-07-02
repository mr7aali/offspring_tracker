import '../../../../core/errors/failures.dart';
import '../../domain/entities/admin_snapshot.dart';
import '../../domain/entities/alert_notification.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/tracked_app.dart';
import '../models/alert_notification_model.dart';
import '../models/child_device_model.dart';
import '../models/tracked_app_model.dart';
import '../models/website_rule_model.dart';

class OffspringLocalDataSource {
  OffspringLocalDataSource() {
    _seed();
  }

  final List<ChildDeviceModel> _devices = [];
  final List<TrackedAppModel> _apps = [];
  final List<WebsiteRuleModel> _websiteRules = [];
  final List<AlertNotificationModel> _notifications = [];
  String _currentPlanId = 'premium';

  Future<List<ChildDeviceModel>> getDevices() async {
    return List.unmodifiable(_devices);
  }

  Future<ChildDeviceModel> pairDevice({
    required String childName,
    required String deviceName,
    required String pairingCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final normalizedCode = pairingCode.trim().toUpperCase();
    if (normalizedCode.length < 5) {
      throw const AppFailure('Pairing code must be at least 5 characters');
    }

    final id = 'device-${_devices.length + 1}';
    final now = DateTime.now();
    final device = ChildDeviceModel(
      id: id,
      childName: childName.trim(),
      deviceName: deviceName.trim(),
      platform: 'Android',
      pairingCode: normalizedCode,
      isOnline: true,
      usageAccessEnabled: true,
      vpnFilterEnabled: false,
      backgroundServiceRunning: true,
      protectedModeEnabled: false,
      lastSyncAt: now,
      lastOnlineAt: now,
    );
    _devices.add(device);
    _apps.addAll(_starterAppsFor(id, now));
    _notifications.insert(
      0,
      AlertNotificationModel(
        id: 'notification-${_notifications.length + 1}',
        deviceId: id,
        title: '${device.childName} device paired',
        message: '${device.deviceName} is ready for remote rules.',
        type: AlertType.ruleSync,
        createdAt: now,
        isRead: false,
      ),
    );
    return device;
  }

  Future<List<TrackedAppModel>> getApps(String deviceId) async {
    return List.unmodifiable(_apps.where((app) => app.deviceId == deviceId));
  }

  Future<TrackedAppModel> updateAppRule({
    required String appId,
    bool? isBlocked,
    int? dailyLimitMinutes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _apps.indexWhere((app) => app.id == appId);
    if (index == -1) {
      throw const AppFailure('App was not found');
    }

    final updated = TrackedAppModel.fromEntity(
      _apps[index].copyWith(
        isBlocked: isBlocked,
        dailyLimitMinutes: dailyLimitMinutes,
      ),
    );
    _apps[index] = updated;

    final title = isBlocked == null
        ? '${updated.name} limit updated'
        : '${updated.name} ${isBlocked ? 'blocked' : 'unblocked'}';
    _notifications.insert(
      0,
      AlertNotificationModel(
        id: 'notification-${_notifications.length + 1}',
        deviceId: updated.deviceId,
        title: title,
        message: 'The child device will sync this rule automatically.',
        type: AlertType.ruleSync,
        createdAt: DateTime.now(),
        isRead: false,
      ),
    );
    return updated;
  }

  Future<List<WebsiteRuleModel>> getWebsiteRules(String deviceId) async {
    return List.unmodifiable(
      _websiteRules.where((rule) => rule.deviceId == deviceId),
    );
  }

  Future<WebsiteRuleModel> addWebsiteRule({
    required String deviceId,
    required String domain,
    required bool includesSubdomains,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final normalizedDomain = domain.trim().toLowerCase();
    final exists = _websiteRules.any(
      (rule) => rule.deviceId == deviceId && rule.domain == normalizedDomain,
    );
    if (exists) {
      throw const AppFailure('This domain is already in the rule list');
    }

    final rule = WebsiteRuleModel(
      id: 'website-${_websiteRules.length + 1}',
      deviceId: deviceId,
      domain: normalizedDomain,
      includesSubdomains: includesSubdomains,
      isBlocked: true,
      blockedAttempts: 0,
      createdAt: DateTime.now(),
    );
    _websiteRules.add(rule);
    _notifications.insert(
      0,
      AlertNotificationModel(
        id: 'notification-${_notifications.length + 1}',
        deviceId: deviceId,
        title: 'Website rule added',
        message: '$normalizedDomain is now blocked on the selected device.',
        type: AlertType.ruleSync,
        createdAt: DateTime.now(),
        isRead: false,
      ),
    );
    return rule;
  }

  Future<WebsiteRuleModel> updateWebsiteRule({
    required String ruleId,
    required bool isBlocked,
  }) async {
    final index = _websiteRules.indexWhere((rule) => rule.id == ruleId);
    if (index == -1) {
      throw const AppFailure('Website rule was not found');
    }

    final updated = WebsiteRuleModel.fromEntity(
      _websiteRules[index].copyWith(isBlocked: isBlocked),
    );
    _websiteRules[index] = updated;
    return updated;
  }

  Future<void> removeWebsiteRule(String ruleId) async {
    _websiteRules.removeWhere((rule) => rule.id == ruleId);
  }

  Future<List<AlertNotificationModel>> getNotifications() async {
    return List.unmodifiable(_notifications);
  }

  Future<void> markNotificationsRead() async {
    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = AlertNotificationModel.fromEntity(
        _notifications[index].copyWith(isRead: true),
      );
    }
  }

  Future<DashboardSummary> getSummary() async {
    final blockedAttempts =
        _apps.fold<int>(0, (total, app) => total + app.blockedAttempts) +
        _websiteRules.fold<int>(
          0,
          (total, rule) => total + rule.blockedAttempts,
        );

    return DashboardSummary(
      totalDevices: _devices.length,
      onlineDevices: _devices.where((device) => device.isOnline).length,
      totalUsageTodayMinutes: _apps.fold<int>(
        0,
        (total, app) => total + app.usageTodayMinutes,
      ),
      blockedAttemptsToday: blockedAttempts,
      unreadAlerts: _notifications.where((alert) => !alert.isRead).length,
      currentPlanName: (await getSubscriptionPlans())
          .firstWhere((plan) => plan.isCurrent)
          .name,
    );
  }

  Future<AdminSnapshot> getAdminSnapshot() async {
    final blockedAttempts =
        _apps.fold<int>(0, (total, app) => total + app.blockedAttempts) +
        _websiteRules.fold<int>(
          0,
          (total, rule) => total + rule.blockedAttempts,
        );

    return AdminSnapshot(
      parentUsers: 128,
      childDevices: 342 + _devices.length,
      activeSubscriptions: 93,
      openSupportIssues: 7,
      blockedAttemptsToday: blockedAttempts,
    );
  }

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    return [
      SubscriptionPlan(
        id: 'free',
        name: 'Free',
        priceLabel: '\$0/mo',
        deviceLimit: 1,
        advancedReports: false,
        websiteBlocking: false,
        protectedMode: false,
        isCurrent: _currentPlanId == 'free',
      ),
      SubscriptionPlan(
        id: 'premium',
        name: 'Premium',
        priceLabel: '\$8/mo',
        deviceLimit: 3,
        advancedReports: true,
        websiteBlocking: true,
        protectedMode: true,
        isCurrent: _currentPlanId == 'premium',
      ),
      SubscriptionPlan(
        id: 'family',
        name: 'Family',
        priceLabel: '\$14/mo',
        deviceLimit: 8,
        advancedReports: true,
        websiteBlocking: true,
        protectedMode: true,
        isCurrent: _currentPlanId == 'family',
      ),
    ];
  }

  Future<SubscriptionPlan> selectPlan(String planId) async {
    final plans = await getSubscriptionPlans();
    if (!plans.any((plan) => plan.id == planId)) {
      throw const AppFailure('Subscription plan was not found');
    }
    _currentPlanId = planId;
    return (await getSubscriptionPlans()).firstWhere((plan) => plan.isCurrent);
  }

  void _seed() {
    final now = DateTime.now();
    _devices.addAll([
      ChildDeviceModel(
        id: 'device-1',
        childName: 'Maya',
        deviceName: "Maya's Pixel 7",
        platform: 'Android',
        pairingCode: 'MAYA7',
        isOnline: true,
        usageAccessEnabled: true,
        vpnFilterEnabled: true,
        backgroundServiceRunning: true,
        protectedModeEnabled: true,
        lastSyncAt: now.subtract(const Duration(minutes: 8)),
        lastOnlineAt: now.subtract(const Duration(minutes: 2)),
      ),
      ChildDeviceModel(
        id: 'device-2',
        childName: 'Leo',
        deviceName: "Leo's Galaxy Tab",
        platform: 'Android',
        pairingCode: 'LEO42',
        isOnline: false,
        usageAccessEnabled: true,
        vpnFilterEnabled: false,
        backgroundServiceRunning: false,
        protectedModeEnabled: false,
        lastSyncAt: now.subtract(const Duration(hours: 6)),
        lastOnlineAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);

    _apps.addAll([
      TrackedAppModel(
        id: 'app-1',
        deviceId: 'device-1',
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        category: AppCategory.streaming,
        isBlocked: false,
        dailyLimitMinutes: 120,
        usageTodayMinutes: 86,
        weeklyUsageMinutes: 518,
        blockedAttempts: 0,
        lastOpenedAt: now.subtract(const Duration(minutes: 16)),
      ),
      TrackedAppModel(
        id: 'app-2',
        deviceId: 'device-1',
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        category: AppCategory.social,
        isBlocked: true,
        dailyLimitMinutes: 30,
        usageTodayMinutes: 30,
        weeklyUsageMinutes: 144,
        blockedAttempts: 4,
        lastOpenedAt: now.subtract(const Duration(hours: 1)),
      ),
      TrackedAppModel(
        id: 'app-3',
        deviceId: 'device-1',
        name: 'Chrome',
        packageName: 'com.android.chrome',
        category: AppCategory.browser,
        isBlocked: false,
        dailyLimitMinutes: 45,
        usageTodayMinutes: 18,
        weeklyUsageMinutes: 101,
        blockedAttempts: 1,
        lastOpenedAt: now.subtract(const Duration(minutes: 40)),
      ),
      TrackedAppModel(
        id: 'app-4',
        deviceId: 'device-1',
        name: 'Khan Academy',
        packageName: 'org.khanacademy.android',
        category: AppCategory.education,
        isBlocked: false,
        dailyLimitMinutes: 0,
        usageTodayMinutes: 42,
        weeklyUsageMinutes: 212,
        blockedAttempts: 0,
        lastOpenedAt: now.subtract(const Duration(minutes: 9)),
      ),
      TrackedAppModel(
        id: 'app-5',
        deviceId: 'device-2',
        name: 'Roblox',
        packageName: 'com.roblox.client',
        category: AppCategory.games,
        isBlocked: false,
        dailyLimitMinutes: 60,
        usageTodayMinutes: 64,
        weeklyUsageMinutes: 391,
        blockedAttempts: 2,
        lastOpenedAt: now.subtract(const Duration(hours: 3)),
      ),
      TrackedAppModel(
        id: 'app-6',
        deviceId: 'device-2',
        name: 'Google Classroom',
        packageName: 'com.google.android.apps.classroom',
        category: AppCategory.education,
        isBlocked: false,
        dailyLimitMinutes: 0,
        usageTodayMinutes: 24,
        weeklyUsageMinutes: 155,
        blockedAttempts: 0,
        lastOpenedAt: now.subtract(const Duration(hours: 4)),
      ),
    ]);

    _websiteRules.addAll([
      WebsiteRuleModel(
        id: 'website-1',
        deviceId: 'device-1',
        domain: 'example.com',
        includesSubdomains: true,
        isBlocked: true,
        blockedAttempts: 3,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      WebsiteRuleModel(
        id: 'website-2',
        deviceId: 'device-1',
        domain: 'games.example.net',
        includesSubdomains: false,
        isBlocked: true,
        blockedAttempts: 5,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      WebsiteRuleModel(
        id: 'website-3',
        deviceId: 'device-2',
        domain: 'video.example.org',
        includesSubdomains: true,
        isBlocked: false,
        blockedAttempts: 1,
        createdAt: now.subtract(const Duration(days: 18)),
      ),
    ]);

    _notifications.addAll([
      AlertNotificationModel(
        id: 'notification-1',
        deviceId: 'device-1',
        title: 'TikTok limit reached',
        message: 'Maya used the full 30 minute allowance today.',
        type: AlertType.appLimit,
        createdAt: now.subtract(const Duration(minutes: 28)),
        isRead: false,
      ),
      AlertNotificationModel(
        id: 'notification-2',
        deviceId: 'device-1',
        title: 'Blocked website attempt',
        message: 'A blocked domain was attempted in Chrome.',
        type: AlertType.blockedWebsite,
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      AlertNotificationModel(
        id: 'notification-3',
        deviceId: 'device-2',
        title: "Leo's tablet went offline",
        message: 'Last online time was more than 2 hours ago.',
        type: AlertType.offlineDevice,
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      AlertNotificationModel(
        id: 'notification-4',
        deviceId: 'device-1',
        title: 'New app installed',
        message: 'Khan Academy was detected and added to monitoring.',
        type: AlertType.newApp,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ]);
  }

  List<TrackedAppModel> _starterAppsFor(String deviceId, DateTime now) {
    return [
      TrackedAppModel(
        id: 'app-${_apps.length + 1}',
        deviceId: deviceId,
        name: 'Chrome',
        packageName: 'com.android.chrome',
        category: AppCategory.browser,
        isBlocked: false,
        dailyLimitMinutes: 60,
        usageTodayMinutes: 0,
        weeklyUsageMinutes: 0,
        blockedAttempts: 0,
        lastOpenedAt: now,
      ),
      TrackedAppModel(
        id: 'app-${_apps.length + 2}',
        deviceId: deviceId,
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        category: AppCategory.streaming,
        isBlocked: false,
        dailyLimitMinutes: 90,
        usageTodayMinutes: 0,
        weeklyUsageMinutes: 0,
        blockedAttempts: 0,
        lastOpenedAt: now,
      ),
    ];
  }
}
