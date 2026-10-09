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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isBlocked ? AppColors.danger.withValues(alpha: 0.03) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked ? AppColors.danger.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isBlocked ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            
            final titleRow = Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_categoryIcon(app.category), color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.packageName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isWide) ...[
                  const SizedBox(width: 12),
                  Switch(
                    value: isBlocked,
                    onChanged: onBlockChanged,
                    activeColor: AppColors.danger,
                  ),
                ],
              ],
            );

            final usageInfo = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      app.hasLimit
                          ? '${_formatMinutes(app.usageTodayMinutes)} used • ${_formatMinutes(app.remainingMinutes)} left'
                          : '${_formatMinutes(app.usageTodayMinutes)} used today',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isBlocked ? AppColors.danger.withValues(alpha: 0.8) : AppColors.ink.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      'Week: ${_formatMinutes(app.weeklyUsageMinutes)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: app.hasLimit ? progress : (isBlocked ? 0 : null),
                    minHeight: 10,
                    color: progress >= 1 || isBlocked ? AppColors.danger : color,
                    backgroundColor: isBlocked ? AppColors.danger.withValues(alpha: 0.1) : AppColors.border,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.block, size: 12, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${app.blockedAttempts} blocks',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const Spacer(),
                    Text(
                      'Active ${DateFormatter.relative(app.lastOpenedAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            );

            final badgesAndActions = Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _categoryColor(app.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _categoryColor(app.category).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_categoryIcon(app.category), size: 14, color: _categoryColor(app.category)),
                      const SizedBox(width: 6),
                      Text(
                        app.category.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _categoryColor(app.category),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isBlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, size: 14, color: AppColors.danger),
                        SizedBox(width: 6),
                        Text(
                          'Blocked',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ActionChip(
                  onPressed: onLimitTap,
                  backgroundColor: app.hasLimit ? AppColors.secondary.withValues(alpha: 0.1) : Colors.transparent,
                  side: BorderSide(
                    color: app.hasLimit ? AppColors.secondary.withValues(alpha: 0.3) : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: app.hasLimit ? AppColors.secondary : AppColors.muted,
                  ),
                  avatar: Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: app.hasLimit ? AppColors.secondary : AppColors.muted,
                  ),
                  label: Text(
                    app.hasLimit ? '${app.dailyLimitMinutes}m limit' : 'Set limit',
                  ),
                ),
              ],
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleRow,
                  const SizedBox(height: 18),
                  usageInfo,
                  const SizedBox(height: 18),
                  badgesAndActions,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleRow,
                      const SizedBox(height: 12),
                      badgesAndActions,
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: usageInfo,
                ),
                const SizedBox(width: 16),
                Switch(
                  value: isBlocked,
                  onChanged: onBlockChanged,
                  activeColor: AppColors.danger,
                ),
              ],
            );
          },
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final leading = Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                  child: const Icon(Icons.public_off, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.domain,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        rule.includesSubdomains
                            ? 'Includes subdomains'
                            : 'Exact domain only',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(
                  label: rule.isBlocked ? 'Blocked' : 'Allowed',
                  icon: rule.isBlocked ? Icons.block : Icons.check_circle,
                  color: rule.isBlocked
                      ? AppColors.danger
                      : AppColors.secondary,
                ),
                StatusPill(
                  label: '${rule.blockedAttempts} attempts',
                  icon: Icons.warning_amber,
                  color: AppColors.accent,
                ),
                Switch(value: rule.isBlocked, onChanged: onToggle),
                IconButton(
                  tooltip: 'Remove domain',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [leading, const SizedBox(height: 12), actions],
              );
            }
            return Row(
              children: [
                Expanded(child: leading),
                const SizedBox(width: 14),
                actions,
              ],
            );
          },
        ),
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
  });

  final String label;
  final String valueLabel;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 9,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          color: color,
          backgroundColor: AppColors.border,
        ),
      ],
    );
  }
}
