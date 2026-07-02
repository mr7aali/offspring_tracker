class AdminSnapshot {
  const AdminSnapshot({
    required this.parentUsers,
    required this.childDevices,
    required this.activeSubscriptions,
    required this.openSupportIssues,
    required this.blockedAttemptsToday,
  });

  final int parentUsers;
  final int childDevices;
  final int activeSubscriptions;
  final int openSupportIssues;
  final int blockedAttemptsToday;
}
