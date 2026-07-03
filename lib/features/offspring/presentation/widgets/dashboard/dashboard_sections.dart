part of '../../screens/dashboard_screen.dart';

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary;
    if (summary == null && controller.isLoading) {
      return const _SectionLoader();
    }

    return Column(
      key: const ValueKey('overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Parent dashboard',
          subtitle:
              'Manage child devices, remote rules, protection status, and reports.',
          action: FilledButton.icon(
            onPressed: () => _showPairDeviceDialog(context, controller),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Pair device'),
          ),
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _MetricGrid(
          children: [
            MetricCard(
              label: 'Child devices',
              value: '${summary?.totalDevices ?? 0}',
              icon: Icons.devices,
              color: AppColors.primary,
              caption: '${summary?.onlineDevices ?? 0} online',
            ),
            MetricCard(
              label: 'Screen usage today',
              value: _formatMinutes(summary?.totalUsageTodayMinutes ?? 0),
              icon: Icons.timelapse,
              color: AppColors.secondary,
              caption: 'All devices',
            ),
            MetricCard(
              label: 'Blocked attempts',
              value: '${summary?.blockedAttemptsToday ?? 0}',
              icon: Icons.shield_outlined,
              color: AppColors.danger,
              caption: 'Today',
            ),
            MetricCard(
              label: 'Unread alerts',
              value: '${summary?.unreadAlerts ?? 0}',
              icon: Icons.notifications_active_outlined,
              color: AppColors.accent,
              caption: summary?.currentPlanName ?? 'Plan',
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _DeviceSelector(controller: controller),
        const SizedBox(height: AppSizes.sectionGap),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            final device = controller.selectedDevice;
            final children = [
              _ProtectionStatusCard(device: device),
              _DeviceListCard(controller: controller),
            ];
            if (!isWide) {
              return Column(
                children: [
                  children[0],
                  const SizedBox(height: AppSizes.cardGap),
                  children[1],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: children[0]),
                const SizedBox(width: AppSizes.cardGap),
                Expanded(child: children[1]),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AppsSection extends StatelessWidget {
  const _AppsSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final device = controller.selectedDevice;
    return Column(
      key: const ValueKey('apps'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Installed app monitoring',
          subtitle:
              'Review package names, usage, limits, and block status per device.',
          action: _DeviceMenu(controller: controller),
        ),
        const SizedBox(height: AppSizes.sectionGap),
        if (device == null)
          EmptyStateWidget(
            icon: Icons.devices_other,
            title: 'No child device paired',
            message: 'Pair an Android device before adding app rules.',
            action: FilledButton.icon(
              onPressed: () => _showPairDeviceDialog(context, controller),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Pair device'),
            ),
          )
        else if (controller.apps.isEmpty)
          const EmptyStateWidget(
            icon: Icons.apps,
            title: 'No apps detected',
            message: 'Installed apps will appear after the child device syncs.',
          )
        else
          Column(
            children: [
              for (final app in controller.apps) ...[
                _AppRuleCard(
                  app: app,
                  onBlockChanged: (value) =>
                      controller.toggleAppBlock(app, value),
                  onLimitTap: () => _showLimitDialog(context, controller, app),
                ),
                const SizedBox(height: AppSizes.cardGap),
              ],
            ],
          ),
      ],
    );
  }
}

class _WebsitesSection extends StatelessWidget {
  const _WebsitesSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('websites'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Website and domain blocking',
          subtitle:
              'Block domains, include subdomains, and sync filtering rules remotely.',
          action: FilledButton.icon(
            onPressed: controller.selectedDevice == null
                ? null
                : () => _showWebsiteDialog(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Add domain'),
          ),
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _DeviceSelector(controller: controller),
        const SizedBox(height: AppSizes.sectionGap),
        if (controller.selectedDevice == null)
          const EmptyStateWidget(
            icon: Icons.public_off,
            title: 'No selected device',
            message: 'Pair and select a device to manage domain rules.',
          )
        else if (controller.websiteRules.isEmpty)
          EmptyStateWidget(
            icon: Icons.public_off,
            title: 'No domain rules yet',
            message: 'Add a domain to block websites on the child device.',
            action: FilledButton.icon(
              onPressed: () => _showWebsiteDialog(context, controller),
              icon: const Icon(Icons.add),
              label: const Text('Add domain'),
            ),
          )
        else
          Column(
            children: [
              for (final rule in controller.websiteRules) ...[
                _WebsiteRuleCard(
                  rule: rule,
                  onToggle: (value) =>
                      controller.toggleWebsiteRule(rule, value),
                  onDelete: () => controller.removeWebsiteRule(rule),
                ),
                const SizedBox(height: AppSizes.cardGap),
              ],
            ],
          ),
      ],
    );
  }
}

class _ReportsSection extends StatelessWidget {
  const _ReportsSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final apps = [...controller.apps]
      ..sort((a, b) => b.weeklyUsageMinutes.compareTo(a.weeklyUsageMinutes));
    final maxWeekly = apps.isEmpty ? 1 : apps.first.weeklyUsageMinutes;
    final totalToday = apps.fold<int>(
      0,
      (total, app) => total + app.usageTodayMinutes,
    );
    final totalWeekly = apps.fold<int>(
      0,
      (total, app) => total + app.weeklyUsageMinutes,
    );
    final blockedAttempts =
        apps.fold<int>(0, (total, app) => total + app.blockedAttempts) +
        controller.websiteRules.fold<int>(
          0,
          (total, rule) => total + rule.blockedAttempts,
        );

    return Column(
      key: const ValueKey('reports'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Usage reports',
          subtitle:
              'Daily and weekly app usage, most-used apps, and blocked attempts.',
          action: _DeviceMenu(controller: controller),
        ),
        const SizedBox(height: AppSizes.sectionGap),
        if (controller.selectedDevice == null)
          const EmptyStateWidget(
            icon: Icons.bar_chart,
            title: 'No report available',
            message: 'Usage history appears after a child device is paired.',
          )
        else ...[
          _MetricGrid(
            children: [
              MetricCard(
                label: 'Today',
                value: _formatMinutes(totalToday),
                icon: Icons.today,
                color: AppColors.primary,
                caption: controller.selectedDevice?.childName,
              ),
              MetricCard(
                label: 'This week',
                value: _formatMinutes(totalWeekly),
                icon: Icons.date_range,
                color: AppColors.secondary,
                caption: '7 days',
              ),
              MetricCard(
                label: 'Most used',
                value: apps.isEmpty ? 'None' : apps.first.name,
                icon: Icons.trending_up,
                color: AppColors.accent,
                caption: apps.isEmpty
                    ? null
                    : _formatMinutes(apps.first.usageTodayMinutes),
              ),
              MetricCard(
                label: 'Blocked attempts',
                value: '$blockedAttempts',
                icon: Icons.block,
                color: AppColors.danger,
                caption: 'Apps + sites',
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sectionGap),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App-wise weekly usage',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final app in apps) ...[
                    _UsageBar(
                      label: app.name,
                      valueLabel: _formatMinutes(app.weeklyUsageMinutes),
                      progress: app.weeklyUsageMinutes / maxWeekly,
                      color: _categoryColor(app.category),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('alerts'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Notifications',
          subtitle:
              'Alerts for limits, blocked attempts, new apps, offline devices, and syncs.',
          action: OutlinedButton.icon(
            onPressed: controller.notifications.any((alert) => !alert.isRead)
                ? controller.markNotificationsRead
                : null,
            icon: const Icon(Icons.done_all),
            label: const Text('Mark read'),
          ),
        ),
        const SizedBox(height: AppSizes.sectionGap),
        if (controller.notifications.isEmpty)
          const EmptyStateWidget(
            icon: Icons.notifications_none,
            title: 'No alerts yet',
            message: 'Important device and rule events will appear here.',
          )
        else
          Column(
            children: [
              for (final notification in controller.notifications) ...[
                _NotificationCard(notification: notification),
                const SizedBox(height: AppSizes.cardGap),
              ],
            ],
          ),
      ],
    );
  }
}

class _AdminPlansSection extends StatelessWidget {
  const _AdminPlansSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.adminSnapshot;
    return Column(
      key: const ValueKey('admin'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Admin panel and subscriptions',
          subtitle:
              'Platform management snapshot plus local subscription controls.',
        ),
        const SizedBox(height: AppSizes.sectionGap),
        if (snapshot != null)
          _MetricGrid(
            children: [
              MetricCard(
                label: 'Parent users',
                value: '${snapshot.parentUsers}',
                icon: Icons.people_alt_outlined,
                color: AppColors.primary,
              ),
              MetricCard(
                label: 'Child devices',
                value: '${snapshot.childDevices}',
                icon: Icons.devices_other,
                color: AppColors.secondary,
              ),
              MetricCard(
                label: 'Subscriptions',
                value: '${snapshot.activeSubscriptions}',
                icon: Icons.credit_card,
                color: AppColors.accent,
              ),
              MetricCard(
                label: 'Support issues',
                value: '${snapshot.openSupportIssues}',
                icon: Icons.support_agent,
                color: AppColors.danger,
              ),
            ],
          ),
        const SizedBox(height: AppSizes.sectionGap),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;
            final planCards = controller.subscriptionPlans
                .map(
                  (plan) => _PlanCard(
                    plan: plan,
                    onSelect: () => controller.selectSubscriptionPlan(plan.id),
                  ),
                )
                .toList();
            if (!isWide) {
              return Column(
                children: [
                  for (final card in planCards) ...[
                    card,
                    const SizedBox(height: AppSizes.cardGap),
                  ],
                  const _AdminToolsCard(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final card in planCards) ...[
                  Expanded(child: card),
                  const SizedBox(width: AppSizes.cardGap),
                ],
                const Expanded(child: _AdminToolsCard()),
              ],
            );
          },
        ),
      ],
    );
  }
}
