class DashboardSummary {
  const DashboardSummary({
    required this.totalDevices,
    required this.onlineDevices,
    required this.totalUsageTodayMinutes,
    required this.blockedAttemptsToday,
    required this.unreadAlerts,
    required this.currentPlanName,
  });

  final int totalDevices;
  final int onlineDevices;
  final int totalUsageTodayMinutes;
  final int blockedAttemptsToday;
  final int unreadAlerts;
  final String currentPlanName;
}
