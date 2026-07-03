part of '../../screens/dashboard_screen.dart';

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final AlertNotification notification;

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(notification.type);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: Icon(_alertIcon(notification.type), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (!notification.isRead)
                        const StatusPill(
                          label: 'Unread',
                          icon: Icons.circle,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${notification.type.label} - ${DateFormatter.relative(notification.createdAt)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onSelect});

  final SubscriptionPlan plan;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (plan.isCurrent)
                  const StatusPill(
                    label: 'Current',
                    icon: Icons.check_circle,
                    color: AppColors.secondary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.priceLabel,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            _PlanFeature(
              label:
                  '${plan.deviceLimit} child device${plan.deviceLimit == 1 ? '' : 's'}',
              enabled: true,
            ),
            _PlanFeature(
              label: 'Advanced usage reports',
              enabled: plan.advancedReports,
            ),
            _PlanFeature(
              label: 'Website blocking',
              enabled: plan.websiteBlocking,
            ),
            _PlanFeature(
              label: 'Protected mode support',
              enabled: plan.protectedMode,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: plan.isCurrent
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check),
                      label: const Text('Selected'),
                    )
                  : FilledButton.icon(
                      onPressed: onSelect,
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text('Select plan'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: enabled ? AppColors.secondary : AppColors.muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: enabled ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminToolsCard extends StatelessWidget {
  const _AdminToolsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin tools',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            const _AdminToolRow(
              icon: Icons.manage_accounts,
              title: 'Manage parent users',
              subtitle: 'Review accounts, roles, and support state.',
            ),
            const _AdminToolRow(
              icon: Icons.devices_other,
              title: 'Manage child devices',
              subtitle: 'Audit pairing status and protection health.',
            ),
            const _AdminToolRow(
              icon: Icons.receipt_long,
              title: 'Monitor subscriptions',
              subtitle: 'Track plan usage and billing state.',
            ),
            const _AdminToolRow(
              icon: Icons.analytics_outlined,
              title: 'Platform activity',
              subtitle: 'Watch rule syncs, reports, and blocked attempts.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminToolRow extends StatelessWidget {
  const _AdminToolRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
