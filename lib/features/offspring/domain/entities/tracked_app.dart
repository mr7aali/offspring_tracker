enum AppCategory {
  social,
  games,
  browser,
  education,
  streaming,
  productivity,
  system,
}

extension AppCategoryLabel on AppCategory {
  String get label {
    switch (this) {
      case AppCategory.social:
        return 'Social';
      case AppCategory.games:
        return 'Games';
      case AppCategory.browser:
        return 'Browser';
      case AppCategory.education:
        return 'Education';
      case AppCategory.streaming:
        return 'Streaming';
      case AppCategory.productivity:
        return 'Productivity';
      case AppCategory.system:
        return 'System';
    }
  }
}

class TrackedApp {
  const TrackedApp({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.packageName,
    required this.category,
    required this.isBlocked,
    required this.dailyLimitMinutes,
    required this.usageTodayMinutes,
    required this.weeklyUsageMinutes,
    required this.blockedAttempts,
    required this.lastOpenedAt,
  });

  final String id;
  final String deviceId;
  final String name;
  final String packageName;
  final AppCategory category;
  final bool isBlocked;
  final int dailyLimitMinutes;
  final int usageTodayMinutes;
  final int weeklyUsageMinutes;
  final int blockedAttempts;
  final DateTime lastOpenedAt;

  int get remainingMinutes {
    if (dailyLimitMinutes <= 0) {
      return 0;
    }
    final remaining = dailyLimitMinutes - usageTodayMinutes;
    return remaining < 0 ? 0 : remaining;
  }

  bool get hasLimit => dailyLimitMinutes > 0;

  TrackedApp copyWith({
    String? id,
    String? deviceId,
    String? name,
    String? packageName,
    AppCategory? category,
    bool? isBlocked,
    int? dailyLimitMinutes,
    int? usageTodayMinutes,
    int? weeklyUsageMinutes,
    int? blockedAttempts,
    DateTime? lastOpenedAt,
  }) {
    return TrackedApp(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      category: category ?? this.category,
      isBlocked: isBlocked ?? this.isBlocked,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      usageTodayMinutes: usageTodayMinutes ?? this.usageTodayMinutes,
      weeklyUsageMinutes: weeklyUsageMinutes ?? this.weeklyUsageMinutes,
      blockedAttempts: blockedAttempts ?? this.blockedAttempts,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}
