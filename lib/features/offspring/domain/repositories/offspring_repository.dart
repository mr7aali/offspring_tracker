import '../entities/admin_snapshot.dart';
import '../entities/alert_notification.dart';
import '../entities/child_device.dart';
import '../entities/dashboard_summary.dart';
import '../entities/subscription_plan.dart';
import '../entities/tracked_app.dart';
import '../entities/website_rule.dart';

abstract class OffspringRepository {
  Future<List<ChildDevice>> getDevices();

  Future<ChildDevice> pairDevice({
    required String childName,
    required String deviceName,
    required String pairingCode,
  });

  Future<List<TrackedApp>> getApps(String deviceId);

  Future<TrackedApp> updateAppRule({
    required String appId,
    bool? isBlocked,
    int? dailyLimitMinutes,
  });

  Future<List<WebsiteRule>> getWebsiteRules(String deviceId);

  Future<WebsiteRule> addWebsiteRule({
    required String deviceId,
    required String domain,
    required bool includesSubdomains,
  });

  Future<WebsiteRule> updateWebsiteRule({
    required String ruleId,
    required bool isBlocked,
  });

  Future<void> removeWebsiteRule(String ruleId);

  Future<List<AlertNotification>> getNotifications();

  Future<void> markNotificationsRead();

  Future<DashboardSummary> getSummary();

  Future<AdminSnapshot> getAdminSnapshot();

  Future<List<SubscriptionPlan>> getSubscriptionPlans();

  Future<SubscriptionPlan> selectPlan(String planId);
}
