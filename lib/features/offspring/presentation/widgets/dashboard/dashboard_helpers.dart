part of '../../screens/dashboard_screen.dart';

String _formatMinutes(int minutes) {
  if (minutes <= 0) {
    return '0m';
  }
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) {
    return '${remaining}m';
  }
  if (remaining == 0) {
    return '${hours}h';
  }
  return '${hours}h ${remaining}m';
}

IconData _categoryIcon(AppCategory category) {
  switch (category) {
    case AppCategory.social:
      return Icons.groups_outlined;
    case AppCategory.games:
      return Icons.sports_esports_outlined;
    case AppCategory.browser:
      return Icons.travel_explore;
    case AppCategory.education:
      return Icons.school_outlined;
    case AppCategory.streaming:
      return Icons.play_circle_outline;
    case AppCategory.productivity:
      return Icons.task_alt;
    case AppCategory.system:
      return Icons.settings_outlined;
  }
}

Color _categoryColor(AppCategory category) {
  switch (category) {
    case AppCategory.social:
      return const Color(0xFF7C3AED);
    case AppCategory.games:
      return AppColors.danger;
    case AppCategory.browser:
      return AppColors.primary;
    case AppCategory.education:
      return AppColors.secondary;
    case AppCategory.streaming:
      return AppColors.accent;
    case AppCategory.productivity:
      return const Color(0xFF0891B2);
    case AppCategory.system:
      return AppColors.muted;
  }
}

IconData _alertIcon(AlertType type) {
  switch (type) {
    case AlertType.appLimit:
      return Icons.timer_off_outlined;
    case AlertType.blockedApp:
      return Icons.block;
    case AlertType.blockedWebsite:
      return Icons.public_off;
    case AlertType.offlineDevice:
      return Icons.wifi_off;
    case AlertType.newApp:
      return Icons.fiber_new;
    case AlertType.ruleSync:
      return Icons.sync;
  }
}

Color _alertColor(AlertType type) {
  switch (type) {
    case AlertType.appLimit:
      return AppColors.accent;
    case AlertType.blockedApp:
    case AlertType.blockedWebsite:
      return AppColors.danger;
    case AlertType.offlineDevice:
      return AppColors.muted;
    case AlertType.newApp:
      return AppColors.primary;
    case AlertType.ruleSync:
      return AppColors.secondary;
  }
}
