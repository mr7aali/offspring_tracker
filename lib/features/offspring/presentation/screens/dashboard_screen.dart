import 'package:flutter/material.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/entities/alert_notification.dart';
import '../../domain/entities/child_device.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/tracked_app.dart';
import '../../domain/entities/website_rule.dart';
import '../controllers/dashboard_controller.dart';

final List<_SupportTicket> _demoSupportTickets = [
  _SupportTicket(
    id: 'SUP-1002',
    subject: 'Pairing code expired for Leo phone',
    description:
        'The child device shows the old pairing code and does not connect after refresh.',
    category: _SupportTicketCategory.pairing,
    priority: _SupportTicketPriority.high,
    status: _SupportTicketStatus.open,
    requesterEmail: AppStrings.demoEmail,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  _SupportTicket(
    id: 'SUP-1001',
    subject: 'Need help reviewing website rules',
    description:
        'Some blocked domains still appear in browser search results. Please confirm if this is expected.',
    category: _SupportTicketCategory.webRules,
    priority: _SupportTicketPriority.normal,
    status: _SupportTicketStatus.waitingParent,
    requesterEmail: AppStrings.demoEmail,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardController get _controller => appDependencies.dashboardController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.load();
    });
  }

  Future<void> _logout() async {
    await appDependencies.authController.logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(RouteNames.auth);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isWide = MediaQuery.sizeOf(context).width >= 900;
        final summary = _controller.summary;
        return Scaffold(
          drawer: _DashboardDrawer(controller: _controller, onLogout: _logout),
          appBar: AppBar(
            titleSpacing: 16,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    AppStrings.appName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            actions: [
              if (isWide && summary != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: StatusPill(
                      label: '${summary.currentPlanName} plan',
                      icon: Icons.workspace_premium,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              Builder(
                builder: (context) {
                  return IconButton(
                    tooltip: 'Account and settings',
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.manage_accounts_outlined),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              if (isWide)
                Row(
                  children: [
                    _DashboardRail(controller: _controller),
                    const VerticalDivider(width: 1),
                    Expanded(child: _DashboardBody(controller: _controller)),
                  ],
                )
              else
                _DashboardBody(controller: _controller),
              if (_controller.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _controller.section.index,
                  onDestinationSelected: (index) {
                    _controller.showSection(DashboardSection.values[index]);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.apps_outlined),
                      selectedIcon: Icon(Icons.apps),
                      label: 'Apps',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.public_off_outlined),
                      selectedIcon: Icon(Icons.public_off),
                      label: 'Sites',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: 'Reports',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.notifications_outlined),
                      selectedIcon: Icon(Icons.notifications),
                      label: 'Alerts',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.admin_panel_settings_outlined),
                      selectedIcon: Icon(Icons.admin_panel_settings),
                      label: 'Admin',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({required this.controller, required this.onLogout});

  final DashboardController controller;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final user = appDependencies.authController.currentUser;
    final summary = controller.summary;
    final childCount = summary?.totalDevices ?? controller.devices.length;
    final onlineCount =
        summary?.onlineDevices ??
        controller.devices.where((device) => device.isOnline).length;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _DrawerProfileHeader(
              name: user?.name ?? 'Parent account',
              email: user?.email ?? AppStrings.demoEmail,
              planName: summary?.currentPlanName ?? user?.planName ?? 'Free',
              childCount: childCount,
              onlineCount: onlineCount,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerSectionLabel(label: 'Account'),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Profile'),
                    subtitle: const Text('Parent account and plan'),
                    onTap: () {
                      _runAfterDrawerClose(
                        context,
                        (context) => _openProfileScreen(context, controller),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text(
                      'How parent and child data is handled',
                    ),
                    onTap: () {
                      _runAfterDrawerClose(context, _openPrivacyPolicyScreen);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms & Conditions'),
                    subtitle: const Text('Rules for using the service'),
                    onTap: () {
                      _runAfterDrawerClose(context, _openTermsScreen);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Data & permissions'),
                    subtitle: const Text('Device access used for protection'),
                    onTap: () {
                      _runAfterDrawerClose(context, _openDataPermissionsScreen);
                    },
                  ),
                  const Divider(height: 20),
                  _DrawerSectionLabel(label: 'Support'),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text('Support tickets'),
                    subtitle: const Text('Create and manage help requests'),
                    onTap: () {
                      _runAfterDrawerClose(context, _openSupportScreen);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    iconColor: AppColors.danger,
                    textColor: AppColors.danger,
                    title: const Text('Delete account'),
                    subtitle: const Text('Request removal of account data'),
                    onTap: () {
                      _runAfterDrawerClose(context, _openDeleteAccountScreen);
                    },
                  ),
                  const Divider(height: 20),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    subtitle: const Text('Version and app information'),
                    onTap: () {
                      _runAfterDrawerClose(context, _openAboutScreen);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await onLogout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerProfileHeader extends StatelessWidget {
  const _DrawerProfileHeader({
    required this.name,
    required this.email,
    required this.planName,
    required this.childCount,
    required this.onlineCount,
  });

  final String name;
  final String email;
  final String planName;
  final int childCount;
  final int onlineCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(
              _initialsFor(name),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: '$planName plan',
                icon: Icons.workspace_premium_outlined,
                color: AppColors.accent,
              ),
              StatusPill(
                label: '$onlineCount/$childCount online',
                icon: Icons.devices_other,
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DashboardRail extends StatelessWidget {
  const _DashboardRail({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: MediaQuery.sizeOf(context).width >= 1120,
      selectedIndex: controller.section.index,
      minExtendedWidth: 210,
      onDestinationSelected: (index) {
        controller.showSection(DashboardSection.values[index]);
      },
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Overview'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps),
          label: Text('Apps'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.public_off_outlined),
          selectedIcon: Icon(Icons.public_off),
          label: Text('Websites'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Reports'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: Text('Alerts'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: Text('Admin & plans'),
        ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _sectionFor(controller.section),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionFor(DashboardSection section) {
    switch (section) {
      case DashboardSection.overview:
        return _OverviewSection(controller: controller);
      case DashboardSection.apps:
        return _AppsSection(controller: controller);
      case DashboardSection.websites:
        return _WebsitesSection(controller: controller);
      case DashboardSection.reports:
        return _ReportsSection(controller: controller);
      case DashboardSection.alerts:
        return _AlertsSection(controller: controller);
      case DashboardSection.admin:
        return _AdminPlansSection(controller: controller);
    }
  }
}

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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * AppSizes.cardGap)) /
            columns;
        return Wrap(
          spacing: AppSizes.cardGap,
          runSpacing: AppSizes.cardGap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _DeviceSelector extends StatelessWidget {
  const _DeviceSelector({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.devices.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.devices_other,
        title: 'No devices paired',
        message: 'Pair a child Android device to start monitoring apps.',
        action: FilledButton.icon(
          onPressed: () => _showPairDeviceDialog(context, controller),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Pair device'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final menu = _DeviceMenu(controller: controller, expanded: true);
            final details = Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OnlineStatusPill(
                  isOnline: controller.selectedDevice?.isOnline ?? false,
                ),
                StatusPill(
                  label:
                      '${controller.selectedDevice?.enabledProtectionCount ?? 0}/4 protections',
                  icon: Icons.verified_user_outlined,
                  color: AppColors.primary,
                ),
                StatusPill(
                  label:
                      'Code ${controller.selectedDevice?.pairingCode ?? '-'}',
                  icon: Icons.qr_code_2,
                  color: AppColors.accent,
                ),
              ],
            );
            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [menu, const SizedBox(height: 12), details],
              );
            }
            return Row(
              children: [
                Expanded(child: menu),
                const SizedBox(width: 16),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeviceMenu extends StatelessWidget {
  const _DeviceMenu({required this.controller, this.expanded = false});

  final DashboardController controller;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final selectedId = controller.selectedDevice?.id;
    final selectedDeviceExists = controller.devices.any(
      (device) => device.id == selectedId,
    );
    final effectiveSelectedId = selectedDeviceExists ? selectedId : null;
    final canSelect = !controller.isLoading && controller.devices.isNotEmpty;

    final menu = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return DropdownButtonFormField<String>(
          key: ValueKey(effectiveSelectedId),
          initialValue: effectiveSelectedId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Child device',
            hintText: canSelect ? 'Select a device' : 'No devices paired',
            prefixIcon: const Icon(Icons.smartphone),
            contentPadding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 12 : 16,
            ),
          ),
          items: [
            for (final device in controller.devices)
              DropdownMenuItem(
                value: device.id,
                child: _DeviceMenuItem(device: device),
              ),
          ],
          selectedItemBuilder: (context) => [
            for (final device in controller.devices)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  compact
                      ? device.childName
                      : '${device.childName} - ${device.deviceName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: canSelect
              ? (value) {
                  if (value != null) {
                    controller.selectDevice(value);
                  }
                }
              : null,
        );
      },
    );

    if (expanded) {
      return menu;
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: menu,
    );
  }
}

class _DeviceMenuItem extends StatelessWidget {
  const _DeviceMenuItem({required this.device});

  final ChildDevice device;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OnlineStatusPill(isOnline: device.isOnline),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.childName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                device.deviceName,
                maxLines: 1,
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
  }
}

class _ProtectionStatusCard extends StatelessWidget {
  const _ProtectionStatusCard({required this.device});

  final ChildDevice? device;

  @override
  Widget build(BuildContext context) {
    final currentDevice = device;
    if (currentDevice == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Child device protection',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${currentDevice.deviceName} last synced ${DateFormatter.relative(currentDevice.lastSyncAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            _ProtectionRow(
              label: 'Usage access',
              enabled: currentDevice.usageAccessEnabled,
              icon: Icons.query_stats,
            ),
            _ProtectionRow(
              label: 'VPN/domain filter',
              enabled: currentDevice.vpnFilterEnabled,
              icon: Icons.vpn_lock_outlined,
            ),
            _ProtectionRow(
              label: 'Background service',
              enabled: currentDevice.backgroundServiceRunning,
              icon: Icons.sync,
            ),
            _ProtectionRow(
              label: 'Protected mode',
              enabled: currentDevice.protectedModeEnabled,
              icon: Icons.admin_panel_settings,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtectionRow extends StatelessWidget {
  const _ProtectionRow({
    required this.label,
    required this.enabled,
    required this.icon,
  });

  final String label;
  final bool enabled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final title = Row(
            children: [
              Icon(
                icon,
                color: enabled ? AppColors.secondary : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
          final status = StatusPill(
            label: enabled ? 'Active' : 'Needs setup',
            icon: enabled ? Icons.check_circle : Icons.info_outline,
            color: enabled ? AppColors.secondary : AppColors.accent,
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 8), status],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 10),
              status,
            ],
          );
        },
      ),
    );
  }
}

class _DeviceListCard extends StatelessWidget {
  const _DeviceListCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paired devices',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            for (final device in controller.devices) ...[
              InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radius),
                onTap: () => controller.selectDevice(device.id),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 360;
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.childName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${device.deviceName} - ${device.platform}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: isCompact
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: device.id == controller.selectedDevice?.id
                                  ? 0.18
                                  : 0.08,
                            ),
                            child: Text(
                              device.childName.isEmpty
                                  ? '?'
                                  : device.childName[0],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: isCompact
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      details,
                                      const SizedBox(height: 8),
                                      OnlineStatusPill(
                                        isOnline: device.isOnline,
                                      ),
                                    ],
                                  )
                                : details,
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 10),
                            OnlineStatusPill(isOnline: device.isOnline),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (device != controller.devices.last)
                const Divider(height: 12, color: AppColors.border),
            ],
          ],
        ),
      ),
    );
  }
}

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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

void _runAfterDrawerClose(
  BuildContext context,
  void Function(BuildContext context) action,
) {
  final navigator = Navigator.of(context);
  final rootContext = navigator.context;
  navigator.pop();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (rootContext.mounted) {
      action(rootContext);
    }
  });
}

void _openProfileScreen(BuildContext context, DashboardController controller) {
  final user = appDependencies.authController.currentUser;
  final summary = controller.summary;
  final createdAt = user?.createdAt;

  _openDashboardInfoScreen(
    context: context,
    icon: Icons.person_outline,
    title: 'Profile',
    subtitle: 'Parent account',
    children: [
      _ProfileHero(
        name: user?.name ?? 'Parent account',
        email: user?.email ?? AppStrings.demoEmail,
        planName: summary?.currentPlanName ?? user?.planName ?? 'Free',
      ),
      const SizedBox(height: 16),
      _InfoRow(
        icon: Icons.devices_other,
        title: 'Child devices',
        value: '${summary?.totalDevices ?? controller.devices.length}',
      ),
      _InfoRow(
        icon: Icons.wifi,
        title: 'Online now',
        value:
            '${summary?.onlineDevices ?? controller.devices.where((device) => device.isOnline).length}',
      ),
      _InfoRow(
        icon: Icons.notifications_active_outlined,
        title: 'Unread alerts',
        value: '${summary?.unreadAlerts ?? controller.notifications.length}',
      ),
      _InfoRow(
        icon: Icons.calendar_today_outlined,
        title: 'Member since',
        value: createdAt == null
            ? 'Not available'
            : DateFormatter.compact(createdAt),
      ),
    ],
  );
}

void _openPrivacyPolicyScreen(BuildContext context) {
  _openDashboardInfoScreen(
    context: context,
    icon: Icons.privacy_tip_outlined,
    title: 'Privacy Policy',
    subtitle: 'Clear handling of family data',
    children: const [
      _PolicyParagraph(
        title: 'What this app stores',
        body:
            'Offspring Tracker stores parent account details, paired child device names, app usage summaries, website rules, alerts, and subscription state needed to run parental controls.',
      ),
      _PolicyParagraph(
        title: 'Why it is used',
        body:
            'Data is used to show reports, sync rules to child devices, notify parents about important events, and keep protection settings working across devices.',
      ),
      _PolicyParagraph(
        title: 'Child data',
        body:
            'Child-related data should be treated as sensitive. The app should collect only what is needed for protection features and should make deletion and support requests easy for parents.',
      ),
      _PolicyParagraph(
        title: 'Sharing',
        body:
            'This local demo does not send data to third-party services. A production version should disclose hosting, analytics, notifications, payment processors, and any SDKs used.',
      ),
    ],
  );
}

void _openTermsScreen(BuildContext context) {
  _openDashboardInfoScreen(
    context: context,
    icon: Icons.description_outlined,
    title: 'Terms & Conditions',
    subtitle: 'Responsible use of parental controls',
    children: const [
      _PolicyParagraph(
        title: 'Parent responsibility',
        body:
            'Use this app only on devices you own or are legally allowed to manage. Parents are responsible for explaining monitoring and protection rules where required.',
      ),
      _PolicyParagraph(
        title: 'Service behavior',
        body:
            'Reports, rules, alerts, and protection status depend on device permissions, network state, and child-device sync health.',
      ),
      _PolicyParagraph(
        title: 'Limitations',
        body:
            'No parental-control tool can guarantee complete protection. The app is designed to support family safety decisions, not replace supervision.',
      ),
    ],
  );
}

void _openDataPermissionsScreen(BuildContext context) {
  _openDashboardInfoScreen(
    context: context,
    icon: Icons.security_outlined,
    title: 'Data & permissions',
    subtitle: 'Access used by protection features',
    children: const [
      _InfoRow(
        icon: Icons.query_stats,
        title: 'Usage access',
        value: 'App usage reports and limits',
      ),
      _InfoRow(
        icon: Icons.vpn_lock_outlined,
        title: 'VPN/domain filter',
        value: 'Website blocking rules',
      ),
      _InfoRow(
        icon: Icons.sync,
        title: 'Background service',
        value: 'Rule sync and status updates',
      ),
      _InfoRow(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        value: 'Alerts for limits and events',
      ),
      SizedBox(height: 10),
      _PolicyParagraph(
        title: 'Production checklist',
        body:
            'Before release, connect this screen to your final privacy policy URL, permission disclosures, account deletion flow, and data export process.',
      ),
    ],
  );
}

void _openSupportScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => const _SupportTicketsScreen(),
    ),
  );
}

void _openAboutScreen(BuildContext context) {
  _openDashboardInfoScreen(
    context: context,
    icon: Icons.info_outline,
    title: 'About',
    subtitle: AppStrings.appName,
    children: const [
      _InfoRow(
        icon: Icons.verified_outlined,
        title: 'Version',
        value: '1.0.0+1',
      ),
      _InfoRow(
        icon: Icons.family_restroom,
        title: 'Purpose',
        value: 'Parent dashboard for child device safety',
      ),
      _PolicyParagraph(
        title: 'Built for',
        body:
            'Managing child devices, app limits, website rules, usage reports, alerts, and account trust controls from one parent experience.',
      ),
    ],
  );
}

void _openDeleteAccountScreen(BuildContext context) {
  _openDashboardInfoScreen(
    context: context,
    icon: Icons.delete_outline,
    title: 'Delete account',
    subtitle: 'Request removal of account data',
    children: [
      const _PolicyParagraph(
        title: 'What will happen',
        body:
            'Account deletion is not connected to a backend in this demo. In production, this screen should submit a verified deletion request and explain what parent and child-device data will be removed.',
      ),
      const _PolicyParagraph(
        title: 'Before deleting',
        body:
            'Parents should be able to export important records, review paired devices, and understand whether child-device rules will stop syncing.',
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deletion request noted for demo.'),
            ),
          );
        },
        icon: const Icon(Icons.delete_outline),
        label: const Text('Request deletion'),
      ),
    ],
  );
}

void _openDashboardInfoScreen({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required List<Widget> children,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) {
        return _DashboardInfoScreen(
          icon: icon,
          title: title,
          subtitle: subtitle,
          children: children,
        );
      },
    ),
  );
}

class _DashboardInfoScreen extends StatelessWidget {
  const _DashboardInfoScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsPageHeader(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                  ),
                  const SizedBox(height: AppSizes.sectionGap),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsPageHeader extends StatelessWidget {
  const _SettingsPageHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _SupportTicketStatus { open, waitingParent, resolved }

enum _SupportTicketPriority { low, normal, high, urgent }

enum _SupportTicketCategory { pairing, appRules, webRules, billing, bug }

enum _SupportTicketFilter { all, open, waitingParent, resolved }

class _SupportTicket {
  const _SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.requesterEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subject;
  final String description;
  final _SupportTicketCategory category;
  final _SupportTicketPriority priority;
  final _SupportTicketStatus status;
  final String requesterEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  _SupportTicket copyWith({_SupportTicketStatus? status, DateTime? updatedAt}) {
    return _SupportTicket(
      id: id,
      subject: subject,
      description: description,
      category: category,
      priority: priority,
      status: status ?? this.status,
      requesterEmail: requesterEmail,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension _SupportTicketStatusUi on _SupportTicketStatus {
  String get label {
    switch (this) {
      case _SupportTicketStatus.open:
        return 'Open';
      case _SupportTicketStatus.waitingParent:
        return 'Waiting parent';
      case _SupportTicketStatus.resolved:
        return 'Resolved';
    }
  }

  String get actionLabel {
    switch (this) {
      case _SupportTicketStatus.open:
        return 'Mark open';
      case _SupportTicketStatus.waitingParent:
        return 'Mark waiting parent';
      case _SupportTicketStatus.resolved:
        return 'Mark resolved';
    }
  }

  IconData get icon {
    switch (this) {
      case _SupportTicketStatus.open:
        return Icons.mark_email_unread_outlined;
      case _SupportTicketStatus.waitingParent:
        return Icons.pending_actions_outlined;
      case _SupportTicketStatus.resolved:
        return Icons.check_circle_outline;
    }
  }

  Color get color {
    switch (this) {
      case _SupportTicketStatus.open:
        return AppColors.accent;
      case _SupportTicketStatus.waitingParent:
        return AppColors.secondary;
      case _SupportTicketStatus.resolved:
        return AppColors.muted;
    }
  }
}

extension _SupportTicketPriorityUi on _SupportTicketPriority {
  String get label {
    switch (this) {
      case _SupportTicketPriority.low:
        return 'Low';
      case _SupportTicketPriority.normal:
        return 'Normal';
      case _SupportTicketPriority.high:
        return 'High';
      case _SupportTicketPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case _SupportTicketPriority.low:
        return AppColors.muted;
      case _SupportTicketPriority.normal:
        return AppColors.primary;
      case _SupportTicketPriority.high:
        return AppColors.accent;
      case _SupportTicketPriority.urgent:
        return AppColors.danger;
    }
  }
}

extension _SupportTicketCategoryUi on _SupportTicketCategory {
  String get label {
    switch (this) {
      case _SupportTicketCategory.pairing:
        return 'Device pairing';
      case _SupportTicketCategory.appRules:
        return 'App rules';
      case _SupportTicketCategory.webRules:
        return 'Website rules';
      case _SupportTicketCategory.billing:
        return 'Billing';
      case _SupportTicketCategory.bug:
        return 'Bug report';
    }
  }

  IconData get icon {
    switch (this) {
      case _SupportTicketCategory.pairing:
        return Icons.qr_code_scanner;
      case _SupportTicketCategory.appRules:
        return Icons.apps_outlined;
      case _SupportTicketCategory.webRules:
        return Icons.public_off_outlined;
      case _SupportTicketCategory.billing:
        return Icons.receipt_long_outlined;
      case _SupportTicketCategory.bug:
        return Icons.bug_report_outlined;
    }
  }
}

extension _SupportTicketFilterUi on _SupportTicketFilter {
  String get label {
    switch (this) {
      case _SupportTicketFilter.all:
        return 'All';
      case _SupportTicketFilter.open:
        return 'Open';
      case _SupportTicketFilter.waitingParent:
        return 'Waiting';
      case _SupportTicketFilter.resolved:
        return 'Resolved';
    }
  }

  IconData get icon {
    switch (this) {
      case _SupportTicketFilter.all:
        return Icons.inbox_outlined;
      case _SupportTicketFilter.open:
        return Icons.mark_email_unread_outlined;
      case _SupportTicketFilter.waitingParent:
        return Icons.pending_actions_outlined;
      case _SupportTicketFilter.resolved:
        return Icons.check_circle_outline;
    }
  }
}

class _SupportTicketsScreen extends StatefulWidget {
  const _SupportTicketsScreen();

  @override
  State<_SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<_SupportTicketsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  _SupportTicketCategory _category = _SupportTicketCategory.pairing;
  _SupportTicketPriority _priority = _SupportTicketPriority.normal;
  _SupportTicketFilter _filter = _SupportTicketFilter.all;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<_SupportTicket> get _filteredTickets {
    return _demoSupportTickets.where((ticket) {
      switch (_filter) {
        case _SupportTicketFilter.all:
          return true;
        case _SupportTicketFilter.open:
          return ticket.status == _SupportTicketStatus.open;
        case _SupportTicketFilter.waitingParent:
          return ticket.status == _SupportTicketStatus.waitingParent;
        case _SupportTicketFilter.resolved:
          return ticket.status == _SupportTicketStatus.resolved;
      }
    }).toList();
  }

  void _submitTicket() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = appDependencies.authController.currentUser;
    final now = DateTime.now();
    final ticket = _SupportTicket(
      id: 'SUP-${1001 + _demoSupportTickets.length}',
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      priority: _priority,
      status: _SupportTicketStatus.open,
      requesterEmail: user?.email ?? AppStrings.demoEmail,
      createdAt: now,
      updatedAt: now,
    );

    setState(() {
      _demoSupportTickets.insert(0, ticket);
      _filter = _SupportTicketFilter.all;
      _subjectController.clear();
      _descriptionController.clear();
      _category = _SupportTicketCategory.pairing;
      _priority = _SupportTicketPriority.normal;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${ticket.id} created.')));
  }

  void _updateTicketStatus(_SupportTicket ticket, _SupportTicketStatus status) {
    final index = _demoSupportTickets.indexWhere(
      (item) => item.id == ticket.id,
    );
    if (index == -1) {
      return;
    }

    setState(() {
      _demoSupportTickets[index] = ticket.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final openTickets = _demoSupportTickets
        .where((ticket) => ticket.status == _SupportTicketStatus.open)
        .length;
    final waitingTickets = _demoSupportTickets
        .where((ticket) => ticket.status == _SupportTicketStatus.waitingParent)
        .length;
    final resolvedTickets = _demoSupportTickets
        .where((ticket) => ticket.status == _SupportTicketStatus.resolved)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Support tickets')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SettingsPageHeader(
                    icon: Icons.support_agent_outlined,
                    title: 'Support tickets',
                    subtitle:
                        'Create requests, track progress, and manage parent support issues.',
                  ),
                  const SizedBox(height: AppSizes.sectionGap),
                  _MetricGrid(
                    children: [
                      MetricCard(
                        label: 'All tickets',
                        value: '${_demoSupportTickets.length}',
                        icon: Icons.confirmation_number_outlined,
                        color: AppColors.primary,
                      ),
                      MetricCard(
                        label: 'Open',
                        value: '$openTickets',
                        icon: Icons.mark_email_unread_outlined,
                        color: AppColors.accent,
                      ),
                      MetricCard(
                        label: 'Waiting parent',
                        value: '$waitingTickets',
                        icon: Icons.pending_actions_outlined,
                        color: AppColors.secondary,
                      ),
                      MetricCard(
                        label: 'Resolved',
                        value: '$resolvedTickets',
                        icon: Icons.check_circle_outline,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sectionGap),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 920;
                      final form = _SupportTicketForm(
                        formKey: _formKey,
                        subjectController: _subjectController,
                        descriptionController: _descriptionController,
                        category: _category,
                        priority: _priority,
                        onCategoryChanged: (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                        onPriorityChanged: (value) {
                          if (value != null) {
                            setState(() => _priority = value);
                          }
                        },
                        onSubmit: _submitTicket,
                      );
                      final tickets = _SupportTicketList(
                        filter: _filter,
                        tickets: _filteredTickets,
                        onFilterChanged: (filter) {
                          setState(() => _filter = filter);
                        },
                        onStatusChanged: _updateTicketStatus,
                      );

                      if (!isWide) {
                        return Column(
                          children: [
                            form,
                            const SizedBox(height: AppSizes.sectionGap),
                            tickets,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 360, child: form),
                          const SizedBox(width: AppSizes.sectionGap),
                          Expanded(child: tickets),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportTicketForm extends StatelessWidget {
  const _SupportTicketForm({
    required this.formKey,
    required this.subjectController,
    required this.descriptionController,
    required this.category,
    required this.priority,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController subjectController;
  final TextEditingController descriptionController;
  final _SupportTicketCategory category;
  final _SupportTicketPriority priority;
  final ValueChanged<_SupportTicketCategory?> onCategoryChanged;
  final ValueChanged<_SupportTicketPriority?> onPriorityChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create ticket',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: subjectController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (value) => Validators.requiredText(value, 'Subject'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_SupportTicketCategory>(
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final item in _SupportTicketCategory.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: onCategoryChanged,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_SupportTicketPriority>(
                initialValue: priority,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: [
                  for (final item in _SupportTicketPriority.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: onPriorityChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                minLines: 4,
                maxLines: 7,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (value) =>
                    Validators.requiredText(value, 'Description'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.add),
                label: const Text('Create ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTicketList extends StatelessWidget {
  const _SupportTicketList({
    required this.filter,
    required this.tickets,
    required this.onFilterChanged,
    required this.onStatusChanged,
  });

  final _SupportTicketFilter filter;
  final List<_SupportTicket> tickets;
  final ValueChanged<_SupportTicketFilter> onFilterChanged;
  final void Function(_SupportTicket ticket, _SupportTicketStatus status)
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tickets',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${tickets.length} shown',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_SupportTicketFilter>(
            segments: [
              for (final item in _SupportTicketFilter.values)
                ButtonSegment(
                  value: item,
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
            selected: {filter},
            onSelectionChanged: (values) {
              onFilterChanged(values.first);
            },
          ),
        ),
        const SizedBox(height: 14),
        if (tickets.isEmpty)
          const EmptyStateWidget(
            icon: Icons.confirmation_number_outlined,
            title: 'No tickets found',
            message: 'Create a ticket or switch filters to see requests.',
          )
        else
          for (final ticket in tickets) ...[
            _SupportTicketCard(
              ticket: ticket,
              onStatusChanged: (status) => onStatusChanged(ticket, status),
            ),
            const SizedBox(height: AppSizes.cardGap),
          ],
      ],
    );
  }
}

class _SupportTicketCard extends StatelessWidget {
  const _SupportTicketCard({
    required this.ticket,
    required this.onStatusChanged,
  });

  final _SupportTicket ticket;
  final ValueChanged<_SupportTicketStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.subject,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket.id} - Updated ${DateFormatter.relative(ticket.updatedAt)}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_SupportTicketStatus>(
                  tooltip: 'Change status',
                  onSelected: onStatusChanged,
                  itemBuilder: (context) => [
                    for (final status in _SupportTicketStatus.values)
                      PopupMenuItem(
                        value: status,
                        child: Text(status.actionLabel),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: ticket.status.label,
                  icon: ticket.status.icon,
                  color: ticket.status.color,
                ),
                StatusPill(
                  label: ticket.priority.label,
                  icon: Icons.flag_outlined,
                  color: ticket.priority.color,
                ),
                StatusPill(
                  label: ticket.category.label,
                  icon: ticket.category.icon,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.mail_outline,
              title: 'Requester',
              value: ticket.requesterEmail,
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              title: 'Created',
              value: DateFormatter.compact(ticket.createdAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.planName,
  });

  final String name;
  final String email;
  final String planName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              _initialsFor(name),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusPill(
            label: planName,
            icon: Icons.workspace_premium_outlined,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  const _PolicyParagraph({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

String _initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'P';
  }
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

Future<void> _showPairDeviceDialog(
  BuildContext context,
  DashboardController controller,
) async {
  final formKey = GlobalKey<FormState>();
  final childController = TextEditingController();
  final deviceController = TextEditingController();
  final codeController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Pair child device'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: childController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Child name',
                    prefixIcon: Icon(Icons.child_care),
                  ),
                  validator: (value) =>
                      Validators.requiredText(value, 'Child name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deviceController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Device name',
                    prefixIcon: Icon(Icons.smartphone),
                  ),
                  validator: (value) =>
                      Validators.requiredText(value, 'Device name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Pairing code',
                    prefixIcon: Icon(Icons.qr_code_2),
                  ),
                  validator: (value) =>
                      Validators.requiredText(value, 'Pairing code'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(Icons.link),
            label: const Text('Pair'),
          ),
        ],
      );
    },
  );

  if (result == true) {
    await controller.pairDevice(
      childName: childController.text,
      deviceName: deviceController.text,
      pairingCode: codeController.text,
    );
  }

  childController.dispose();
  deviceController.dispose();
  codeController.dispose();
}

Future<void> _showLimitDialog(
  BuildContext context,
  DashboardController controller,
  TrackedApp app,
) async {
  final textController = TextEditingController(
    text: app.dailyLimitMinutes.toString(),
  );
  final formKey = GlobalKey<FormState>();

  final minutes = await showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Set ${app.name} limit'),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily minutes',
                prefixIcon: Icon(Icons.timer_outlined),
                helperText: 'Use 0 for no limit',
              ),
              validator: (value) {
                final minutes = int.tryParse(value ?? '');
                if (minutes == null || minutes < 0 || minutes > 1440) {
                  return 'Enter 0 to 1440 minutes';
                }
                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(int.parse(textController.text));
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      );
    },
  );

  if (minutes != null) {
    await controller.updateAppLimit(app, minutes);
  }
  textController.dispose();
}

Future<void> _showWebsiteDialog(
  BuildContext context,
  DashboardController controller,
) async {
  final formKey = GlobalKey<FormState>();
  final domainController = TextEditingController();
  var includesSubdomains = true;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add blocked domain'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: domainController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Domain',
                        hintText: 'example.com',
                        prefixIcon: Icon(Icons.public),
                      ),
                      validator: Validators.domain,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: includesSubdomains,
                      onChanged: (value) {
                        setState(() => includesSubdomains = value ?? true);
                      },
                      title: const Text('Block subdomains'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(true);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == true) {
    await controller.addWebsiteRule(
      domain: domainController.text,
      includesSubdomains: includesSubdomains,
    );
  }
  domainController.dispose();
}

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
