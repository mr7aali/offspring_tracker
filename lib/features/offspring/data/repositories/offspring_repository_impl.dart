import '../../domain/entities/admin_snapshot.dart';
import '../../domain/entities/alert_notification.dart';
import '../../domain/entities/child_device.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/tracked_app.dart';
import '../../domain/entities/website_rule.dart';
import '../../domain/repositories/offspring_repository.dart';
import '../datasources/offspring_local_datasource.dart';

class OffspringRepositoryImpl implements OffspringRepository {
  const OffspringRepositoryImpl(this._localDataSource);

  final OffspringLocalDataSource _localDataSource;

  @override
  Future<List<ChildDevice>> getDevices() {
    return _localDataSource.getDevices();
  }

  @override
  Future<ChildDevice> pairDevice({
    required String childName,
    required String deviceName,
    required String pairingCode,
  }) {
    return _localDataSource.pairDevice(
      childName: childName,
      deviceName: deviceName,
      pairingCode: pairingCode,
    );
  }

  @override
  Future<List<TrackedApp>> getApps(String deviceId) {
    return _localDataSource.getApps(deviceId);
  }

  @override
  Future<TrackedApp> updateAppRule({
    required String appId,
    bool? isBlocked,
    int? dailyLimitMinutes,
  }) {
    return _localDataSource.updateAppRule(
      appId: appId,
      isBlocked: isBlocked,
      dailyLimitMinutes: dailyLimitMinutes,
    );
  }

  @override
  Future<List<WebsiteRule>> getWebsiteRules(String deviceId) {
    return _localDataSource.getWebsiteRules(deviceId);
  }

  @override
  Future<WebsiteRule> addWebsiteRule({
    required String deviceId,
    required String domain,
    required bool includesSubdomains,
  }) {
    return _localDataSource.addWebsiteRule(
      deviceId: deviceId,
      domain: domain,
      includesSubdomains: includesSubdomains,
    );
  }

  @override
  Future<WebsiteRule> updateWebsiteRule({
    required String ruleId,
    required bool isBlocked,
  }) {
    return _localDataSource.updateWebsiteRule(
      ruleId: ruleId,
      isBlocked: isBlocked,
    );
  }

  @override
  Future<void> removeWebsiteRule(String ruleId) {
    return _localDataSource.removeWebsiteRule(ruleId);
  }

  @override
  Future<List<AlertNotification>> getNotifications() {
    return _localDataSource.getNotifications();
  }

  @override
  Future<void> markNotificationsRead() {
    return _localDataSource.markNotificationsRead();
  }

  @override
  Future<DashboardSummary> getSummary() {
    return _localDataSource.getSummary();
  }

  @override
  Future<AdminSnapshot> getAdminSnapshot() {
    return _localDataSource.getAdminSnapshot();
  }

  @override
  Future<List<SubscriptionPlan>> getSubscriptionPlans() {
    return _localDataSource.getSubscriptionPlans();
  }

  @override
  Future<SubscriptionPlan> selectPlan(String planId) {
    return _localDataSource.selectPlan(planId);
  }
}
