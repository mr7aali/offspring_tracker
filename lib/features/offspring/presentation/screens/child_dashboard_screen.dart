import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/entities/alert_notification.dart';
import '../../domain/entities/child_device.dart';
import '../../domain/entities/tracked_app.dart';
import '../../domain/entities/website_rule.dart';
import '../controllers/dashboard_controller.dart';

enum ChildDashboardSection { overview, apps, websites, alerts, device }

const List<_ChildDestination> _childDestinations = [
  _ChildDestination(
    section: ChildDashboardSection.overview,
    label: 'Home',
    railLabel: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  _ChildDestination(
    section: ChildDashboardSection.apps,
    label: 'Apps',
    railLabel: 'App limits',
    icon: Icons.apps_outlined,
    selectedIcon: Icons.apps_rounded,
  ),
  _ChildDestination(
    section: ChildDashboardSection.websites,
    label: 'Sites',
    railLabel: 'Website rules',
    icon: Icons.public_outlined,
    selectedIcon: Icons.public_rounded,
  ),
  _ChildDestination(
    section: ChildDashboardSection.alerts,
    label: 'Alerts',
    railLabel: 'Alerts',
    icon: Icons.notifications_none_rounded,
    selectedIcon: Icons.notifications_active_rounded,
  ),
  _ChildDestination(
    section: ChildDashboardSection.device,
    label: 'Device',
    railLabel: 'Device & help',
    icon: Icons.phone_android_outlined,
    selectedIcon: Icons.phone_android_rounded,
  ),
];

class ChildDashboardScreen extends StatefulWidget {
  const ChildDashboardScreen({super.key});

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen> {
  DashboardController get _dashboardController =>
      appDependencies.dashboardController;

  ChildDashboardSection _section = ChildDashboardSection.overview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildDevice();
    });
  }

  Future<void> _loadChildDevice() async {
    final device = appDependencies.childSessionController.currentDevice;
    if (device != null) {
      await _dashboardController.load(selectedDeviceId: device.id);
    }
  }

  void _showSection(ChildDashboardSection section) {
    setState(() => _section = section);
  }

  void _logout() {
    appDependencies.childSessionController.logout();
    Navigator.of(context).pushReplacementNamed(RouteNames.auth);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        appDependencies.childSessionController,
        _dashboardController,
      ]),
      builder: (context, _) {
        final sessionDevice =
            appDependencies.childSessionController.currentDevice;

        if (sessionDevice == null) {
          return _ChildSignedOutScaffold(onGoToSignIn: _logout);
        }

        final data = _ChildDashboardData.fromController(
          sessionDevice: sessionDevice,
          controller: _dashboardController,
        );
        final isWide = MediaQuery.sizeOf(context).width >= 900;

        return Scaffold(
          extendBody: !isWide,
          drawer: _ChildDashboardDrawer(
            data: data,
            section: _section,
            onSectionSelected: (section) {
              Navigator.of(context).pop();
              _showSection(section);
            },
            onRefresh: () {
              Navigator.of(context).pop();
              _loadChildDevice();
            },
            onLogout: () {
              Navigator.of(context).pop();
              _logout();
            },
          ),
          appBar: AppBar(
            titleSpacing: 16,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogoMark(
                  size: 38,
                  padding: 0,
                  backgroundColor: Colors.white,
                  borderRadius: AppSizes.radius,
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
              if (isWide)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: StatusPill(
                      label: data.device.childName,
                      icon: Icons.child_care,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Refresh child device',
                onPressed: _dashboardController.isLoading
                    ? null
                    : _loadChildDevice,
                icon: const Icon(Icons.refresh),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: OnlineStatusPill(isOnline: data.device.isOnline),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              if (isWide)
                Row(
                  children: [
                    _ChildNavigationRail(
                      section: _section,
                      onSectionSelected: _showSection,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _ChildDashboardBody(
                        data: data,
                        section: _section,
                        isWide: isWide,
                      ),
                    ),
                  ],
                )
              else
                _ChildDashboardBody(
                  data: data,
                  section: _section,
                  isWide: isWide,
                ),
              if (_dashboardController.isLoading)
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
              : _ChildBottomNav(
                  section: _section,
                  onSectionSelected: _showSection,
                ),
        );
      },
    );
  }
}

class _ChildDashboardData {
  const _ChildDashboardData({
    required this.device,
    required this.apps,
    required this.websiteRules,
    required this.notifications,
    required this.hasLoadedDevice,
  });

  factory _ChildDashboardData.fromController({
    required ChildDevice sessionDevice,
    required DashboardController controller,
  }) {
    final selectedDevice = controller.selectedDevice;
    final hasLoadedDevice = selectedDevice?.id == sessionDevice.id;
    final device = hasLoadedDevice ? selectedDevice! : sessionDevice;

    return _ChildDashboardData(
      device: device,
      apps: hasLoadedDevice ? controller.apps : const <TrackedApp>[],
      websiteRules: hasLoadedDevice
          ? controller.websiteRules
          : const <WebsiteRule>[],
      notifications: controller.notifications
          .where((notification) => notification.deviceId == device.id)
          .toList(),
      hasLoadedDevice: hasLoadedDevice,
    );
  }

  final ChildDevice device;
  final List<TrackedApp> apps;
  final List<WebsiteRule> websiteRules;
  final List<AlertNotification> notifications;
  final bool hasLoadedDevice;

  int get totalUsageToday {
    return apps.fold<int>(0, (total, app) => total + app.usageTodayMinutes);
  }

  int get totalWeeklyUsage {
    return apps.fold<int>(0, (total, app) => total + app.weeklyUsageMinutes);
  }

  int get blockedApps => apps.where((app) => app.isBlocked).length;

  int get activeWebsiteRules {
    return websiteRules.where((rule) => rule.isBlocked).length;
  }

  int get blockedAttempts {
    return apps.fold<int>(0, (total, app) => total + app.blockedAttempts) +
        websiteRules.fold<int>(
          0,
          (total, rule) => total + rule.blockedAttempts,
        );
  }

  int get unreadAlerts {
    return notifications.where((notification) => !notification.isRead).length;
  }

  List<TrackedApp> get limitedApps {
    return apps.where((app) => app.hasLimit).toList()
      ..sort((a, b) => a.remainingMinutes.compareTo(b.remainingMinutes));
  }
}

class _ChildDestination {
  const _ChildDestination({
    required this.section,
    required this.label,
    required this.railLabel,
    required this.icon,
    required this.selectedIcon,
  });

  final ChildDashboardSection section;
  final String label;
  final String railLabel;
  final IconData icon;
  final IconData selectedIcon;
}

class _ChildSignedOutScaffold extends StatelessWidget {
  const _ChildSignedOutScaffold({required this.onGoToSignIn});

  final VoidCallback onGoToSignIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Child dashboard')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: EmptyStateWidget(
              icon: Icons.phone_android,
              title: 'Child sign in required',
              message:
                  'Use a paired child device name and pairing code to open this dashboard.',
              action: FilledButton.icon(
                onPressed: onGoToSignIn,
                icon: const Icon(Icons.login),
                label: const Text('Go to sign in'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _runAfterChildDrawerClose(
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

void _openChildProfileScreen(BuildContext context, _ChildDashboardData data) {
  final device = data.device;

  _openChildDashboardInfoScreen(
    context: context,
    icon: Icons.person_outline,
    title: 'Profile',
    subtitle: 'Child device account',
    children: [
      _DeviceProfileCard(device: device),
      const SizedBox(height: 16),
      _ChildInfoRow(
        icon: Icons.apps,
        title: 'Tracked apps',
        value: '${data.apps.length}',
      ),
      _ChildInfoRow(
        icon: Icons.public_off_outlined,
        title: 'Website rules',
        value: '${data.websiteRules.length}',
      ),
      _ChildInfoRow(
        icon: Icons.notifications_active_outlined,
        title: 'Alerts',
        value: '${data.notifications.length}',
      ),
      _ChildInfoRow(
        icon: Icons.verified_user_outlined,
        title: 'Protections active',
        value: '${device.enabledProtectionCount}/4',
      ),
    ],
  );
}

void _openChildPrivacyPolicyScreen(BuildContext context) {
  _openChildDashboardInfoScreen(
    context: context,
    icon: Icons.privacy_tip_outlined,
    title: 'Privacy Policy',
    subtitle: 'Clear handling of family data',
    children: const [
      _ChildPolicyParagraph(
        title: 'What this app stores',
        body:
            'Offspring Tracker stores parent account details, paired child device names, app usage summaries, website rules, alerts, and subscription state needed to run parental controls.',
      ),
      _ChildPolicyParagraph(
        title: 'Why it is used',
        body:
            'Data is used to show reports, sync rules to child devices, notify parents about important events, and keep protection settings working across devices.',
      ),
      _ChildPolicyParagraph(
        title: 'Child data',
        body:
            'Child-related data should be treated as sensitive. The app should collect only what is needed for protection features and should make deletion and support requests easy for parents.',
      ),
      _ChildPolicyParagraph(
        title: 'Sharing',
        body:
            'This local demo does not send data to third-party services. A production version should disclose hosting, analytics, notifications, payment processors, and any SDKs used.',
      ),
    ],
  );
}

void _openChildTermsScreen(BuildContext context) {
  _openChildDashboardInfoScreen(
    context: context,
    icon: Icons.description_outlined,
    title: 'Terms & Conditions',
    subtitle: 'Responsible use of parental controls',
    children: const [
      _ChildPolicyParagraph(
        title: 'Parent responsibility',
        body:
            'Use this app only on devices you own or are legally allowed to manage. Parents are responsible for explaining monitoring and protection rules where required.',
      ),
      _ChildPolicyParagraph(
        title: 'Service behavior',
        body:
            'Reports, rules, alerts, and protection status depend on device permissions, network state, and child-device sync health.',
      ),
      _ChildPolicyParagraph(
        title: 'Limitations',
        body:
            'No parental-control tool can guarantee complete protection. The app is designed to support family safety decisions, not replace supervision.',
      ),
    ],
  );
}

void _openChildDataPermissionsScreen(BuildContext context) {
  _openChildDashboardInfoScreen(
    context: context,
    icon: Icons.security_outlined,
    title: 'Data & permissions',
    subtitle: 'Access used by protection features',
    children: const [
      _ChildInfoRow(
        icon: Icons.query_stats,
        title: 'Usage access',
        value: 'App usage reports and limits',
      ),
      _ChildInfoRow(
        icon: Icons.vpn_lock_outlined,
        title: 'VPN/domain filter',
        value: 'Website blocking rules',
      ),
      _ChildInfoRow(
        icon: Icons.sync,
        title: 'Background service',
        value: 'Rule sync and status updates',
      ),
      _ChildInfoRow(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        value: 'Alerts for limits and events',
      ),
      _ChildInfoRow(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Protected mode',
        value: 'Stronger device protection',
      ),
      SizedBox(height: 10),
      _ChildPolicyParagraph(
        title: 'Production checklist',
        body:
            'Before release, connect this screen to your final privacy policy URL, permission disclosures, account deletion flow, and data export process.',
      ),
    ],
  );
}

void _openChildAboutScreen(BuildContext context) {
  _openChildDashboardInfoScreen(
    context: context,
    icon: Icons.info_outline,
    title: 'About',
    subtitle: AppStrings.appName,
    children: const [
      _ChildInfoRow(
        icon: Icons.verified_outlined,
        title: 'Version',
        value: '1.0.0+1',
      ),
      _ChildInfoRow(
        icon: Icons.phone_android_outlined,
        title: 'Purpose',
        value: 'Child dashboard for device safety',
      ),
      _ChildPolicyParagraph(
        title: 'Built for',
        body:
            'Viewing app limits, website rules, protection status, usage reports, alerts, and rule guidance from one child-safe experience.',
      ),
    ],
  );
}

void _openChildDashboardInfoScreen({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required List<Widget> children,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) {
        return _ChildDashboardInfoScreen(
          icon: icon,
          title: title,
          subtitle: subtitle,
          children: children,
        );
      },
    ),
  );
}

class _ChildDashboardInfoScreen extends StatelessWidget {
  const _ChildDashboardInfoScreen({
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
                  _ChildSettingsPageHeader(
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

class _ChildSettingsPageHeader extends StatelessWidget {
  const _ChildSettingsPageHeader({
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

class _ChildInfoRow extends StatelessWidget {
  const _ChildInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(value),
      ),
    );
  }
}

class _ChildPolicyParagraph extends StatelessWidget {
  const _ChildPolicyParagraph({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ChildDashboardDrawer extends StatelessWidget {
  const _ChildDashboardDrawer({
    required this.data,
    required this.section,
    required this.onSectionSelected,
    required this.onRefresh,
    required this.onLogout,
  });

  final _ChildDashboardData data;
  final ChildDashboardSection section;
  final ValueChanged<ChildDashboardSection> onSectionSelected;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _ChildDrawerHeader(data: data),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _ChildDrawerSectionLabel(label: 'Account'),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Profile'),
                    subtitle: const Text('Child device account'),
                    onTap: () {
                      _runAfterChildDrawerClose(
                        context,
                        (context) => _openChildProfileScreen(context, data),
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
                      _runAfterChildDrawerClose(
                        context,
                        _openChildPrivacyPolicyScreen,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms & Conditions'),
                    subtitle: const Text('Rules for using the service'),
                    onTap: () {
                      _runAfterChildDrawerClose(context, _openChildTermsScreen);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Data & permissions'),
                    subtitle: const Text('Device access used for protection'),
                    onTap: () {
                      _runAfterChildDrawerClose(
                        context,
                        _openChildDataPermissionsScreen,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    subtitle: const Text('Version and app information'),
                    onTap: () {
                      _runAfterChildDrawerClose(context, _openChildAboutScreen);
                    },
                  ),
                  const Divider(height: 20),
                  const _ChildDrawerSectionLabel(label: 'Child dashboard'),
                  for (final destination in _childDestinations)
                    ListTile(
                      selected: section == destination.section,
                      leading: Icon(
                        section == destination.section
                            ? destination.selectedIcon
                            : destination.icon,
                      ),
                      title: Text(destination.railLabel),
                      onTap: () => onSectionSelected(destination.section),
                    ),
                  const Divider(height: 20),
                  const _ChildDrawerSectionLabel(label: 'Device actions'),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Refresh data'),
                    subtitle: const Text('Sync the latest parent rules'),
                    onTap: onRefresh,
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Need a rule changed?'),
                    subtitle: const Text('Ask your parent from Device & help'),
                    onTap: () =>
                        onSectionSelected(ChildDashboardSection.device),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
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

class _ChildDrawerHeader extends StatelessWidget {
  const _ChildDrawerHeader({required this.data});

  final _ChildDashboardData data;

  @override
  Widget build(BuildContext context) {
    final device = data.device;
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
              device.childName.isEmpty ? '?' : device.childName[0],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            device.childName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            device.deviceName,
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
              OnlineStatusPill(isOnline: device.isOnline),
              StatusPill(
                label: '${device.enabledProtectionCount}/4 active',
                icon: Icons.verified_user_outlined,
                color: _protectionColor(device),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildDrawerSectionLabel extends StatelessWidget {
  const _ChildDrawerSectionLabel({required this.label});

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

class _ChildNavigationRail extends StatelessWidget {
  const _ChildNavigationRail({
    required this.section,
    required this.onSectionSelected,
  });

  final ChildDashboardSection section;
  final ValueChanged<ChildDashboardSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: MediaQuery.sizeOf(context).width >= 1120,
      selectedIndex: _childDestinations.indexWhere(
        (destination) => destination.section == section,
      ),
      minExtendedWidth: 210,
      onDestinationSelected: (index) {
        onSectionSelected(_childDestinations[index].section);
      },
      destinations: [
        for (final destination in _childDestinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.railLabel),
          ),
      ],
    );
  }
}

class _ChildBottomNav extends StatelessWidget {
  const _ChildBottomNav({
    required this.section,
    required this.onSectionSelected,
  });

  final ChildDashboardSection section;
  final ValueChanged<ChildDashboardSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 280);
    final selectedIndex = _childDestinations.indexWhere(
      (destination) => destination.section == section,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.1),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Material(
                      type: MaterialType.transparency,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth =
                              constraints.maxWidth / _childDestinations.length;
                          final indicatorWidth = itemWidth < 52
                              ? itemWidth - 4
                              : 52.0;
                          final indicatorLeft =
                              (itemWidth * selectedIndex) +
                              ((itemWidth - indicatorWidth) / 2);

                          return SizedBox(
                            height: 58,
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: duration,
                                  curve: Curves.easeOutCubic,
                                  left: indicatorLeft,
                                  top: 3,
                                  bottom: 3,
                                  width: indicatorWidth,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF3B82F6),
                                          AppColors.primary,
                                          Color(0xFF1D4ED8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.32,
                                          ),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    for (final destination
                                        in _childDestinations)
                                      Expanded(
                                        child: _AnimatedChildBottomNavItem(
                                          destination: destination,
                                          selected:
                                              section == destination.section,
                                          onTap: () => onSectionSelected(
                                            destination.section,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedChildBottomNavItem extends StatelessWidget {
  const _AnimatedChildBottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ChildDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: const BoxDecoration(color: Colors.transparent),
            child: AnimatedSwitcher(
              duration: duration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: selected
                  ? Center(
                      key: const ValueKey('selected'),
                      child: _ChildActiveNavIcon(
                        icon: destination.selectedIcon,
                      ),
                    )
                  : Column(
                      key: const ValueKey('unselected'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          destination.icon,
                          size: 21,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
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

class _ChildActiveNavIcon extends StatelessWidget {
  const _ChildActiveNavIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
          ),
          Icon(icon, size: 25, color: Colors.white),
          Positioned(
            right: 3,
            top: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildDashboardBody extends StatelessWidget {
  const _ChildDashboardBody({
    required this.data,
    required this.section,
    required this.isWide,
  });

  final _ChildDashboardData data;
  final ChildDashboardSection section;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.pagePadding,
        AppSizes.pagePadding,
        isWide ? AppSizes.pagePadding : 112,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _sectionFor(section),
          ),
        ),
      ),
    );
  }

  Widget _sectionFor(ChildDashboardSection section) {
    switch (section) {
      case ChildDashboardSection.overview:
        return _ChildOverviewSection(data: data);
      case ChildDashboardSection.apps:
        return _ChildAppsSection(data: data);
      case ChildDashboardSection.websites:
        return _ChildWebsitesSection(data: data);
      case ChildDashboardSection.alerts:
        return _ChildAlertsSection(data: data);
      case ChildDashboardSection.device:
        return _ChildDeviceSection(data: data);
    }
  }
}

class _ChildOverviewSection extends StatelessWidget {
  const _ChildOverviewSection({required this.data});

  final _ChildDashboardData data;

  @override
  Widget build(BuildContext context) {
    final device = data.device;
    final limitedApps = data.limitedApps.take(3).toList();

    return Column(
      key: const ValueKey('child-overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Hi, ${device.childName}',
          subtitle:
              'This is your child dashboard for ${device.deviceName}. Your parent manages the rules.',
          action: StatusPill(
            label: '${device.enabledProtectionCount}/4 protections',
            icon: Icons.verified_user_outlined,
            color: _protectionColor(device),
          ),
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _ChildMetricGrid(
          children: [
            MetricCard(
              label: 'Usage today',
              value: _formatMinutes(data.totalUsageToday),
              icon: Icons.timelapse,
              color: AppColors.primary,
              caption: '${data.apps.length} apps tracked',
            ),
            MetricCard(
              label: 'This week',
              value: _formatMinutes(data.totalWeeklyUsage),
              icon: Icons.date_range,
              color: AppColors.secondary,
              caption: 'Tracked apps',
            ),
            MetricCard(
              label: 'Blocked apps',
              value: '${data.blockedApps}',
              icon: Icons.block,
              color: AppColors.danger,
              caption: 'Set by parent',
            ),
            MetricCard(
              label: 'Alerts',
              value: '${data.unreadAlerts}',
              icon: Icons.notifications_active_outlined,
              color: AppColors.accent,
              caption: 'Unread',
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _ChildResponsiveRow(
          children: [
            _ProtectionStatusCard(device: device),
            _DeviceSyncCard(device: device),
          ],
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _ParentRulesNoticeCard(data: data),
        const SizedBox(height: AppSizes.sectionGap),
        SectionHeader(
          title: 'Today at a glance',
          subtitle: limitedApps.isEmpty
              ? 'No app limits are active for this device yet.'
              : 'Apps closest to their daily limit appear first.',
        ),
        const SizedBox(height: AppSizes.cardGap),
        if (limitedApps.isEmpty)
          const EmptyStateWidget(
            icon: Icons.timer_off_outlined,
            title: 'No daily app limits',
            message: 'Your parent can add app limits from their dashboard.',
          )
        else
          Column(
            children: [
              for (final app in limitedApps) ...[
                _CompactLimitTile(app: app),
                const SizedBox(height: AppSizes.cardGap),
              ],
            ],
          ),
      ],
    );
  }
}

class _ChildAppsSection extends StatelessWidget {
  const _ChildAppsSection({required this.data});

  final _ChildDashboardData data;

  @override
  Widget build(BuildContext context) {
    final apps = [...data.apps]
      ..sort((a, b) {
        if (a.isBlocked != b.isBlocked) {
          return a.isBlocked ? -1 : 1;
        }
        return b.usageTodayMinutes.compareTo(a.usageTodayMinutes);
      });

    return Column(
      key: const ValueKey('child-apps'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'My app rules',
          subtitle:
              'See daily limits, usage, blocked apps, and remaining time for this device.',
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _ChildMetricGrid(
          children: [
            MetricCard(
              label: 'Tracked apps',
              value: '${data.apps.length}',
              icon: Icons.apps,
              color: AppColors.primary,
            ),
            MetricCard(
              label: 'With limits',
              value: '${data.limitedApps.length}',
              icon: Icons.timer_outlined,
              color: AppColors.accent,
            ),
            MetricCard(
              label: 'Blocked',
              value: '${data.blockedApps}',
              icon: Icons.lock_outline,
              color: AppColors.danger,
            ),
            MetricCard(
              label: 'Blocked attempts',
              value: '${data.blockedAttempts}',
              icon: Icons.shield_outlined,
              color: AppColors.secondary,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sectionGap),
        if (apps.isEmpty)
          const EmptyStateWidget(
            icon: Icons.apps,
            title: 'No apps loaded yet',
            message: 'App rules will appear after this device syncs.',
          )
        else
          Column(
            children: [
              for (final app in apps) ...[
                _ChildAppRuleTile(app: app),
                const SizedBox(height: AppSizes.cardGap),
              ],
            ],
          ),
      ],
    );
  }
}

class _ChildWebsitesSection extends StatelessWidget {
  const _ChildWebsitesSection({required this.data});

  final _ChildDashboardData data;

  @override
  Widget build(BuildContext context) {
    final rules = [...data.websiteRules]
      ..sort((a, b) {
        if (a.isBlocked != b.isBlocked) {
          return a.isBlocked ? -1 : 1;
        }
        return a.domain.compareTo(b.domain);
      });

    return Column(
      key: const ValueKey('child-websites'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Website rules',
          subtitle:
              'Domains your parent has added for website filtering on this device.',
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _ChildMetricGrid(
          children: [
            MetricCard(
              label: 'Total rules',
              value: '${data.websiteRules.length}',
              icon: Icons.public,
              color: AppColors.primary,
            ),
            MetricCard(
              label: 'Active blocks',
              value: '${data.activeWebsiteRules}',
              icon: Icons.public_off_outlined,
              color: AppColors.danger,
            ),
            MetricCard(
              label: 'Subdomain rules',
              value:
                  '${data.websiteRules.where((rule) => rule.includesSubdomains).length}',
              icon: Icons.account_tree_outlined,
              color: AppColors.secondary,
            ),
            MetricCard(
              label: 'Site attempts',
              value:
                  '${data.websiteRules.fold<int>(0, (total, rule) => total + rule.blockedAttempts)}',
              icon: Icons.shield_outlined,
              color: AppColors.accent,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sectionGap),
        if (rules.isEmpty)
          const EmptyStateWidget(
            icon: Icons.public,
            title: 'No website rules',
            message: 'Website rules will show here when your parent adds them.',
          )
        else
          Column(
            children: [
              for (final rule in rules) ...[
                _ChildWebsiteRuleTile(rule: rule),
                const SizedBox(height: AppSizes.cardGap),
              ],
            ],
          ),
      ],
    );
  }
}

class _ChildAlertsSection extends StatelessWidget {
  const _ChildAlertsSection({required this.data});

  final _ChildDashboardData data;

  @override
  Widget build(BuildContext context) {
    final notifications = [...data.notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      key: const ValueKey('child-alerts'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Recent alerts',
          subtitle:
              'Device events related to limits, blocks, sync, and online status.',
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _ChildMetricGrid(
          children: [
            MetricCard(
              label: 'All alerts',
              value: '${notifications.length}',
              icon: Icons.notifications_none_rounded,
              color: AppColors.primary,
            ),
            MetricCard(
              label: 'Unread',
              value: '${data.unreadAlerts}',
              icon: Icons.notifications_active_outlined,
              color: AppColors.accent,
            ),
            MetricCard(
              label: 'Blocked events',
              value:
                  '${notifications.where((item) => item.type == AlertType.blockedApp || item.type == AlertType.blockedWebsite).length}',
              icon: Icons.block,
              color: AppColors.danger,
            ),
            MetricCard(
              label: 'Sync events',
              value:
                  '${notifications.where((item) => item.type == AlertType.ruleSync).length}',
              icon: Icons.sync,
              color: AppColors.secondary,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sectionGap),
        if (notifications.isEmpty)
          const EmptyStateWidget(
            icon: Icons.notifications_none,
            title: 'No alerts for this device',
            message: 'Important device events will appear here.',
          )
        else
          Column(
            children: [
              for (final notification in notifications) ...[
                _ChildAlertTile(notification: notification),
                const SizedBox(height: AppSizes.cardGap),
              ],
            ],
          ),
      ],
    );
  }
}

class _ChildDeviceSection extends StatelessWidget {
  const _ChildDeviceSection({required this.data});

  final _ChildDashboardData data;

  @override
  Widget build(BuildContext context) {
    final device = data.device;

    return Column(
      key: const ValueKey('child-device'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Device & help',
          subtitle:
              'Review this device, protection status, pairing details, and what to do when a rule needs changing.',
          action: OnlineStatusPill(isOnline: device.isOnline),
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _ChildResponsiveRow(
          children: [
            _DeviceProfileCard(device: device),
            _DeviceSyncCard(device: device),
          ],
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _ChildResponsiveRow(
          children: [
            _ProtectionStatusCard(device: device),
            _PairingInfoCard(device: device),
          ],
        ),
        const SizedBox(height: AppSizes.sectionGap),
        _NeedHelpCard(data: data),
      ],
    );
  }
}

class _ChildMetricGrid extends StatelessWidget {
  const _ChildMetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 980
            ? 4
            : width >= 560
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.cardGap,
          crossAxisSpacing: AppSizes.cardGap,
          childAspectRatio: width < 420 ? 2.55 : 3.25,
          children: children,
        );
      },
    );
  }
}

class _ChildResponsiveRow extends StatelessWidget {
  const _ChildResponsiveRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                if (child != children.last)
                  const SizedBox(height: AppSizes.cardGap),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final child in children) ...[
              Expanded(child: child),
              if (child != children.last)
                const SizedBox(width: AppSizes.cardGap),
            ],
          ],
        );
      },
    );
  }
}

class _ParentRulesNoticeCard extends StatelessWidget {
  const _ParentRulesNoticeCard({required this.data});

  final _ChildDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: const Icon(
                Icons.supervisor_account_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rules are managed by your parent',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can view app limits, website rules, and alerts here. If something needs changing, ask your parent from their dashboard.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(
                        label: '${data.blockedApps} blocked apps',
                        icon: Icons.block,
                        color: AppColors.danger,
                      ),
                      StatusPill(
                        label: '${data.activeWebsiteRules} website rules',
                        icon: Icons.public_off_outlined,
                        color: AppColors.secondary,
                      ),
                    ],
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

class _ProtectionStatusCard extends StatelessWidget {
  const _ProtectionStatusCard({required this.device});

  final ChildDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protection status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _ProtectionLine(
              icon: Icons.query_stats,
              label: 'Usage access',
              enabled: device.usageAccessEnabled,
            ),
            _ProtectionLine(
              icon: Icons.vpn_lock_outlined,
              label: 'Website filter',
              enabled: device.vpnFilterEnabled,
            ),
            _ProtectionLine(
              icon: Icons.sync,
              label: 'Background sync',
              enabled: device.backgroundServiceRunning,
            ),
            _ProtectionLine(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Protected mode',
              enabled: device.protectedModeEnabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceProfileCard extends StatelessWidget {
  const _DeviceProfileCard({required this.device});

  final ChildDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: Text(
                device.childName.isEmpty ? '?' : device.childName[0],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.childName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.deviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(
                        label: device.platform,
                        icon: Icons.android,
                        color: AppColors.secondary,
                      ),
                      OnlineStatusPill(isOnline: device.isOnline),
                    ],
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

class _DeviceSyncCard extends StatelessWidget {
  const _DeviceSyncCard({required this.device});

  final ChildDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _InfoLine(
              icon: Icons.smartphone,
              label: 'Device',
              value: device.deviceName,
            ),
            _InfoLine(
              icon: Icons.android,
              label: 'Platform',
              value: device.platform,
            ),
            _InfoLine(
              icon: Icons.sync,
              label: 'Last sync',
              value: DateFormatter.relative(device.lastSyncAt),
            ),
            _InfoLine(
              icon: device.isOnline ? Icons.wifi : Icons.wifi_off,
              label: 'Last online',
              value: DateFormatter.relative(device.lastOnlineAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _PairingInfoCard extends StatelessWidget {
  const _PairingInfoCard({required this.device});

  final ChildDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pairing details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Use this code only with your parent or guardian.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      device.pairingCode,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  StatusPill(
                    label: 'Paired',
                    icon: Icons.link,
                    color: AppColors.secondary,
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

class _NeedHelpCard extends StatelessWidget {
  const _NeedHelpCard({required this.data});

  final _ChildDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need a rule changed?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This child role is view-only. Ask your parent to update app limits, unblock apps, or change website rules from the parent dashboard.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: '${data.apps.length} apps visible',
                  icon: Icons.apps,
                  color: AppColors.primary,
                ),
                StatusPill(
                  label: '${data.websiteRules.length} site rules',
                  icon: Icons.public,
                  color: AppColors.secondary,
                ),
                StatusPill(
                  label: '${data.notifications.length} alerts',
                  icon: Icons.notifications_none,
                  color: AppColors.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtectionLine extends StatelessWidget {
  const _ProtectionLine({
    required this.icon,
    required this.label,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.secondary : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          StatusPill(
            label: enabled ? 'Active' : 'Off',
            icon: enabled ? Icons.check : Icons.close,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
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

class _CompactLimitTile extends StatelessWidget {
  const _CompactLimitTile({required this.app});

  final TrackedApp app;

  @override
  Widget build(BuildContext context) {
    final progress = app.dailyLimitMinutes <= 0
        ? 0.0
        : (app.usageTodayMinutes / app.dailyLimitMinutes).clamp(0.0, 1.0);
    final color = app.isBlocked
        ? AppColors.danger
        : _categoryColor(app.category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          app.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatMinutes(app.remainingMinutes)} left',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: AppColors.border,
                    color: color,
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

class _ChildAppRuleTile extends StatelessWidget {
  const _ChildAppRuleTile({required this.app});

  final TrackedApp app;

  @override
  Widget build(BuildContext context) {
    final hasLimit = app.hasLimit;
    final progress = hasLimit
        ? (app.usageTodayMinutes / app.dailyLimitMinutes).clamp(0.0, 1.0)
        : 0.0;
    final color = app.isBlocked
        ? AppColors.danger
        : _categoryColor(app.category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
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
                const SizedBox(width: 8),
                StatusPill(
                  label: app.isBlocked ? 'Blocked' : app.category.label,
                  icon: app.isBlocked ? Icons.lock : Icons.category_outlined,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: AppColors.border,
              color: color,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: 'Today ${_formatMinutes(app.usageTodayMinutes)}',
                  icon: Icons.today,
                  color: AppColors.primary,
                ),
                StatusPill(
                  label: hasLimit
                      ? 'Limit ${_formatMinutes(app.dailyLimitMinutes)}'
                      : 'No daily limit',
                  icon: Icons.timer_outlined,
                  color: hasLimit ? AppColors.accent : AppColors.muted,
                ),
                StatusPill(
                  label: hasLimit
                      ? '${_formatMinutes(app.remainingMinutes)} left'
                      : 'Open use',
                  icon: Icons.hourglass_bottom,
                  color: hasLimit ? AppColors.secondary : AppColors.muted,
                ),
                StatusPill(
                  label: '${app.blockedAttempts} attempts',
                  icon: Icons.shield_outlined,
                  color: app.blockedAttempts > 0
                      ? AppColors.danger
                      : AppColors.muted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildWebsiteRuleTile extends StatelessWidget {
  const _ChildWebsiteRuleTile({required this.rule});

  final WebsiteRule rule;

  @override
  Widget build(BuildContext context) {
    final color = rule.isBlocked ? AppColors.danger : AppColors.muted;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.public_off_outlined, color: color),
        ),
        title: Text(
          rule.domain,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          rule.includesSubdomains ? 'Includes subdomains' : 'Exact domain only',
        ),
        trailing: StatusPill(
          label: rule.isBlocked ? 'Blocked' : 'Allowed',
          icon: rule.isBlocked ? Icons.lock : Icons.lock_open,
          color: color,
        ),
      ),
    );
  }
}

class _ChildAlertTile extends StatelessWidget {
  const _ChildAlertTile({required this.notification});

  final AlertNotification notification;

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(notification.type);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_alertIcon(notification.type), color: color),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(notification.message),
        trailing: Text(
          DateFormatter.relative(notification.createdAt),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _formatMinutes(int minutes) {
  if (minutes < 60) {
    return '${minutes}m';
  }
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (remainder == 0) {
    return '${hours}h';
  }
  return '${hours}h ${remainder}m';
}

Color _protectionColor(ChildDevice device) {
  if (device.enabledProtectionCount >= 3) {
    return AppColors.secondary;
  }
  if (device.enabledProtectionCount >= 2) {
    return AppColors.accent;
  }
  return AppColors.danger;
}

Color _categoryColor(AppCategory category) {
  switch (category) {
    case AppCategory.social:
      return AppColors.accent;
    case AppCategory.games:
      return AppColors.danger;
    case AppCategory.browser:
      return AppColors.primary;
    case AppCategory.education:
      return AppColors.secondary;
    case AppCategory.streaming:
      return const Color(0xFF7C3AED);
    case AppCategory.productivity:
      return const Color(0xFF0F766E);
    case AppCategory.system:
      return AppColors.muted;
  }
}

IconData _categoryIcon(AppCategory category) {
  switch (category) {
    case AppCategory.social:
      return Icons.groups_outlined;
    case AppCategory.games:
      return Icons.sports_esports_outlined;
    case AppCategory.browser:
      return Icons.language;
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

IconData _alertIcon(AlertType type) {
  switch (type) {
    case AlertType.appLimit:
      return Icons.timer_outlined;
    case AlertType.blockedApp:
      return Icons.block;
    case AlertType.blockedWebsite:
      return Icons.public_off_outlined;
    case AlertType.offlineDevice:
      return Icons.wifi_off;
    case AlertType.newApp:
      return Icons.new_releases_outlined;
    case AlertType.ruleSync:
      return Icons.sync;
  }
}
