part of '../../screens/dashboard_screen.dart';

class _StickyPairDeviceDelegate extends SliverPersistentHeaderDelegate {
  _StickyPairDeviceDelegate({required this.controller, required this.padding});
  
  final DashboardController controller;
  final EdgeInsets padding;
  
  @override
  double get minExtent => 88.0; 
  @override
  double get maxExtent => 88.0;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.transparent, // Transparent to act like a floating button
      padding: EdgeInsets.symmetric(horizontal: padding.left),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: Material(
              elevation: overlapsContent ? 12 : 4,
              shadowColor: colors.primary.withValues(alpha: overlapsContent ? 0.5 : 0.35),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      colors.primary,
                      Color.lerp(colors.primary, colors.secondary, 0.45)!,
                    ],
                  ),
                ),
                child: TextButton.icon(
                  onPressed: () => _showPairDeviceDialog(context, controller),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onPrimary,
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  icon: const Icon(Icons.add_link_rounded, size: 24),
                  label: const Text('Pair device'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyPairDeviceDelegate oldDelegate) => true;
}

class _StickyAddDomainDelegate extends SliverPersistentHeaderDelegate {
  _StickyAddDomainDelegate({required this.controller, required this.padding});
  
  final DashboardController controller;
  final EdgeInsets padding;
  
  @override
  double get minExtent => 88.0; 
  @override
  double get maxExtent => 88.0;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.transparent, // Transparent to act like a floating button
      padding: EdgeInsets.symmetric(horizontal: padding.left),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: Material(
              elevation: overlapsContent ? 12 : 4,
              shadowColor: colors.primary.withValues(alpha: overlapsContent ? 0.5 : 0.35),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      colors.primary,
                      Color.lerp(colors.primary, colors.secondary, 0.45)!,
                    ],
                  ),
                ),
                child: TextButton.icon(
                  onPressed: controller.selectedDevice == null
                      ? null
                      : () => _showWebsiteDialog(context, controller),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onPrimary,
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 24),
                  label: const Text('Add domain'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyAddDomainDelegate oldDelegate) => true;
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({super.key, required this.controller, required this.padding});

  final DashboardController controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary;
    if (summary == null && controller.isLoading) {
      return const Center(child: _SectionLoader());
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: padding.copyWith(bottom: 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.errorMessage != null) ...[
                      _InlineError(message: controller.errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    const SectionHeader(
                      title: 'Parent dashboard',
                      subtitle: 'Manage child devices, remote rules, protection status, and reports.',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyPairDeviceDelegate(controller: controller, padding: padding),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: padding.copyWith(top: 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.sectionGap - 16),
                    _MetricGrid(
                      children: [
                        MetricCard(
                          label: 'Child devices',
                          showShadow: true,
                          value: '${summary?.totalDevices ?? 0}',
                          icon: Icons.devices,
                          color: AppColors.primary,
                          caption: '${summary?.onlineDevices ?? 0} online',
                        ),
                        MetricCard(
                          label: 'Screen usage today',
                          showShadow: true,
                          value: _formatMinutes(summary?.totalUsageTodayMinutes ?? 0),
                          icon: Icons.timelapse,
                          color: AppColors.secondary,
                          caption: 'All devices',
                        ),
                        MetricCard(
                          label: 'Blocked attempts',
                          showShadow: true,
                          value: '${summary?.blockedAttemptsToday ?? 0}',
                          icon: Icons.shield_outlined,
                          color: AppColors.danger,
                          caption: 'Today',
                        ),
                        MetricCard(
                          label: 'Unread alerts',
                          showShadow: true,
                          value: '${summary?.unreadAlerts ?? 0}',
                          icon: Icons.notifications_active_outlined,
                          color: AppColors.accent,
                          caption: summary?.currentPlanName ?? 'Plan',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sectionGap),
                    if (controller.devices.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.devices_other,
                        title: 'No devices paired',
                        message: 'Pair a child Android device to start monitoring apps.',
                        action: FilledButton.icon(
                          onPressed: () => _showPairDeviceDialog(context, controller),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Pair device'),
                        ),
                      )
                    else ...[
                      _ActiveDeviceBanner(
                        controller: controller,
                        compact: true,
                        message: 'Overview, rules, and reports use this active device.',
                      ),
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
                  ],
                ),
              ),
            ),
          ),
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
        else ...[
          _ActiveDeviceBanner(
            controller: controller,
            message: 'App rules are shown for the active child device.',
          ),
          const SizedBox(height: AppSizes.cardGap),
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
      ],
    );
  }
}

class _WebsitesSection extends StatelessWidget {
  const _WebsitesSection({super.key, required this.controller, required this.padding});

  final DashboardController controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: padding.copyWith(bottom: 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.errorMessage != null) ...[
                      _InlineError(message: controller.errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    const SectionHeader(
                      title: 'Website and domain blocking',
                      subtitle: 'Block domains, include subdomains, and sync filtering rules remotely.',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyAddDomainDelegate(controller: controller, padding: padding),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: padding.copyWith(top: 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.sectionGap - 16),
                    if (controller.selectedDevice == null)
                      const EmptyStateWidget(
                        icon: Icons.public_off,
                        title: 'No selected device',
                        message: 'Pair and select a device to manage domain rules.',
                      )
                    else if (controller.websiteRules.isEmpty)
                      Container(
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.asset(
                                'assets/images/sites_empty.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                              child: Column(
                                children: [
                                  Text(
                                    'No domain rules yet',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the "Add domain" button above to start blocking websites. Keep your child’s web browsing safe and secure.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.muted,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      for (final rule in controller.websiteRules) ...[
                        _WebsiteRuleCard(
                          rule: rule,
                          onToggle: (value) => controller.toggleWebsiteRule(rule, value),
                          onDelete: () => controller.removeWebsiteRule(rule),
                        ),
                        const SizedBox(height: AppSizes.cardGap),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App-wise weekly usage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                for (final app in apps) ...[
                  _UsageBar(
                    label: app.name,
                    valueLabel: _formatMinutes(app.weeklyUsageMinutes),
                    progress: app.weeklyUsageMinutes / maxWeekly,
                    color: _categoryColor(app.category),
                    icon: _categoryIcon(app.category),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
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
