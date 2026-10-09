part of '../../screens/dashboard_screen.dart';

class _AppRuleCard extends StatelessWidget {
  const _AppRuleCard({
    required this.app,
    required this.onBlockChanged,
    required this.onLimitTap,
  });

  final TrackedApp app;
  final ValueChanged<bool> onBlockChanged;
  final VoidCallback onLimitTap;

  @override
  Widget build(BuildContext context) {
    final progress = app.hasLimit
        ? (app.usageTodayMinutes / app.dailyLimitMinutes).clamp(0.0, 1.0)
        : 0.0;
    final color = app.isBlocked ? AppColors.danger : _categoryColor(app.category);
    final isBlocked = app.isBlocked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isBlocked ? AppColors.danger.withValues(alpha: 0.04) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked ? AppColors.danger.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          if (!isBlocked)
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // App Icon (Squircle)
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcon(app.category), color: color, size: 24),
          ),
          const SizedBox(width: 14),
          // Titles and Minimal Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        app.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      app.hasLimit
                          ? '${_formatMinutes(app.usageTodayMinutes)} / ${_formatMinutes(app.dailyLimitMinutes)}'
                          : _formatMinutes(app.usageTodayMinutes),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isBlocked ? AppColors.danger : AppColors.ink.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (app.hasLimit) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      color: progress >= 1 || isBlocked ? AppColors.danger : color,
                      backgroundColor: isBlocked ? AppColors.danger.withValues(alpha: 0.1) : AppColors.border,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      app.category.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onLimitTap,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: app.hasLimit ? AppColors.secondary : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              app.hasLimit ? 'Edit Limit' : 'Set Limit',
                              style: TextStyle(
                                fontSize: 12,
                                color: app.hasLimit ? AppColors.secondary : AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Block Switch
          Switch(
            value: isBlocked,
            onChanged: onBlockChanged,
            activeColor: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _WebsiteRuleCard extends StatelessWidget {
  const _WebsiteRuleCard({
    required this.rule,
    required this.onToggle,
    required this.onDelete,
  });

  final WebsiteRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isBlocked = rule.isBlocked;
    final color = isBlocked ? AppColors.danger : AppColors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isBlocked ? AppColors.danger.withValues(alpha: 0.04) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked ? AppColors.danger.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          if (!isBlocked)
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.public_off, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          // Domain Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        rule.domain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (rule.blockedAttempts > 0) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(Icons.warning_amber, size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '${rule.blockedAttempts}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rule.includesSubdomains ? 'Includes subdomains' : 'Exact domain only',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isBlocked,
                onChanged: onToggle,
                activeColor: AppColors.danger,
              ),
              IconButton(
                tooltip: 'Remove domain',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.muted,
                iconSize: 22,
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.label,
    required this.valueLabel,
    required this.progress,
    required this.color,
    this.icon,
  });

  final String label;
  final String valueLabel;
  final double progress;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4,
            color: color,
            backgroundColor: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}
