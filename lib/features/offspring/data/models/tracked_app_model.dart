import '../../domain/entities/tracked_app.dart';

class TrackedAppModel extends TrackedApp {
  const TrackedAppModel({
    required super.id,
    required super.deviceId,
    required super.name,
    required super.packageName,
    required super.category,
    required super.isBlocked,
    required super.dailyLimitMinutes,
    required super.usageTodayMinutes,
    required super.weeklyUsageMinutes,
    required super.blockedAttempts,
    required super.lastOpenedAt,
  });

  factory TrackedAppModel.fromEntity(TrackedApp app) {
    return TrackedAppModel(
      id: app.id,
      deviceId: app.deviceId,
      name: app.name,
      packageName: app.packageName,
      category: app.category,
      isBlocked: app.isBlocked,
      dailyLimitMinutes: app.dailyLimitMinutes,
      usageTodayMinutes: app.usageTodayMinutes,
      weeklyUsageMinutes: app.weeklyUsageMinutes,
      blockedAttempts: app.blockedAttempts,
      lastOpenedAt: app.lastOpenedAt,
    );
  }
}
