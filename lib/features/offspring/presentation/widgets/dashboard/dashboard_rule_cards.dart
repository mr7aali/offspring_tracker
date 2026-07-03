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
    final color = app.isBlocked
        ? AppColors.danger
        : _categoryColor(app.category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final title = Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                  child: Icon(_categoryIcon(app.category), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        app.packageName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final controls = Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(
                  label: app.category.label,
                  icon: _categoryIcon(app.category),
                  color: _categoryColor(app.category),
                ),
                StatusPill(
                  label: app.isBlocked ? 'Blocked' : 'Allowed',
                  icon: app.isBlocked ? Icons.block : Icons.check_circle,
                  color: app.isBlocked ? AppColors.danger : AppColors.secondary,
                ),
                OutlinedButton.icon(
                  onPressed: onLimitTap,
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(
                    app.hasLimit
                        ? '${app.dailyLimitMinutes} min limit'
                        : 'No limit',
                  ),
                ),
                Switch(value: app.isBlocked, onChanged: onBlockChanged),
              ],
            );

            final usage = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        app.hasLimit
                            ? '${_formatMinutes(app.usageTodayMinutes)} used, ${_formatMinutes(app.remainingMinutes)} left'
                            : '${_formatMinutes(app.usageTodayMinutes)} used today',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    Text(
                      'Week ${_formatMinutes(app.weeklyUsageMinutes)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: app.hasLimit ? progress : null,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  color: progress >= 1 ? AppColors.danger : color,
                  backgroundColor: AppColors.border,
                ),
                const SizedBox(height: 8),
                Text(
                  'Blocked attempts: ${app.blockedAttempts} - Last opened ${DateFormatter.relative(app.lastOpenedAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 14),
                  usage,
                  const SizedBox(height: 14),
                  controls,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: title),
                const SizedBox(width: 18),
                Expanded(flex: 4, child: usage),
                const SizedBox(width: 18),
                Expanded(flex: 3, child: controls),
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
