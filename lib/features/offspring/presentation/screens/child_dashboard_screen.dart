import 'dart:ui';
import 'dart:async';

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
import '../../../auth/presentation/screens/child_pairing_screen.dart';
import '../../domain/entities/alert_notification.dart';
import '../../domain/entities/child_device.dart';
import '../../domain/entities/tracked_app.dart';
import '../../domain/entities/website_rule.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/rule_editor_sheets.dart';
import '../../domain/repositories/device_protection.dart';

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

class _ChildDashboardScreenState extends State<ChildDashboardScreen>
    with WidgetsBindingObserver {
  DashboardController get _dashboardController =>
      appDependencies.dashboardController;

  ChildDashboardSection _section = ChildDashboardSection.overview;
  final _protection = _ProtectionController();

  /// Rules last sent to the phone, so unchanged rules are not re-sent.
  String? _appliedRulesKey;
  StreamSubscription<void>? _inventorySubscription;
  bool _refreshing = false;
  bool _refreshPending = false;
  String? _inventoryError;

  bool get _discoverApps =>
      appDependencies.refreshInstalledApps.source.isSupported;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardController.addListener(_syncRulesToPhone);
    appDependencies.childSessionController.addListener(_syncRulesToPhone);
    if (_discoverApps) {
      _inventorySubscription = appDependencies
          .refreshInstalledApps
          .source
          .changes
          .listen(
            (_) => _loadChildDevice(),
            onError: (Object error) {
              if (mounted) {
                setState(() {
                  _inventoryError =
                      'Automatic app updates are unavailable. Use refresh to try again.';
                });
              }
            },
          );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadChildDevice();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadChildDevice();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dashboardController.removeListener(_syncRulesToPhone);
    appDependencies.childSessionController.removeListener(_syncRulesToPhone);
    _protection.dispose();
    _inventorySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadChildDevice() async {
    if (!mounted) return;
    if (_refreshing) {
      _refreshPending = true;
      return;
    }
    final device = appDependencies.childSessionController.currentDevice;
    if (device == null) return;
    setState(() => _refreshing = true);
    try {
      do {
        _refreshPending = false;
        if (_discoverApps) {
          try {
            await appDependencies.refreshInstalledApps(device.id);
            if (mounted) setState(() => _inventoryError = null);
          } catch (_) {
            if (mounted) {
              setState(() {
                _inventoryError =
                    'Could not read installed apps. The previous list is shown. Tap refresh to retry.';
              });
            }
          }
        }
        if (!mounted ||
            appDependencies.childSessionController.currentDevice?.id !=
                device.id) {
          return;
        }
        await _protection.refresh();
        try {
          await appDependencies.refreshAppUsage(device.id);
        } catch (_) {
          // Screen time is optional; keep the last known values.
        }
        await _dashboardController.load(selectedDeviceId: device.id);
      } while (mounted && _refreshPending);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _showSection(ChildDashboardSection section) {
    setState(() => _section = section);
  }

  /// Sends self-mode rules to the phone's blocker whenever they change, and
  /// clears them when this phone leaves self mode.
  void _syncRulesToPhone() {
    final protection = appDependencies.deviceProtection;
    final session = appDependencies.childSessionController;
    if (!session.isSelfMode) {
      if (_appliedRulesKey != null) {
        _appliedRulesKey = null;
        protection.clearRules();
      }
      return;
    }
    final controller = _dashboardController;
    if (controller.isLoading ||
        controller.selectedDevice?.id != session.currentDevice?.id) {
      return;
    }
    final key = _rulesKey(controller.apps, controller.websiteRules);
    if (key == _appliedRulesKey) return;
    _appliedRulesKey = key;
    protection.applyRules(
      apps: controller.apps,
      websites: controller.websiteRules,
    );
  }

  void _logout() {
    if (appDependencies.childSessionController.isSelfMode) {
      // Leaving self mode removes this phone's blocks.
      _appliedRulesKey = null;
      appDependencies.deviceProtection.clearRules();
      appDependencies.deviceProtection.stopWebFilter();
    }
    appDependencies.childSessionController.logout();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.auth, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        appDependencies.childSessionController,
        _dashboardController,
        _protection,
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
          protection: _protection,
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
                onPressed: _dashboardController.isLoading || _refreshing
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
          body: Column(
            children: [
              if (_inventoryError != null)
                MaterialBanner(
                  content: Text(_inventoryError!),
                  actions: [
                    TextButton(
                      onPressed: _refreshing ? null : _loadChildDevice,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              if (_discoverApps && !_protection.status.usageAccessGranted)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    data.canManage
                        ? 'Screen time is not tracked yet. Allow usage access on the Apps tab to see it.'
                        : 'Apps installed on this phone. Usage tracking is not active yet.',
                  ),
                ),
              Expanded(
                child: Stack(
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
                    if (_dashboardController.isLoading || _refreshing)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
                ),
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
    required this.canManage,
    required this.protection,
  });

  factory _ChildDashboardData.fromController({
    required ChildDevice sessionDevice,
    required DashboardController controller,
    required _ProtectionController protection,
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
      canManage: appDependencies.childSessionController.isSelfMode,
      protection: protection,
    );
  }

  final ChildDevice device;
  final List<TrackedApp> apps;
  final List<WebsiteRule> websiteRules;
  final List<AlertNotification> notifications;
  final bool hasLoadedDevice;

  /// True in self mode: the user manages this phone's rules themselves.
  final bool canManage;

  /// Blocking setup on this phone (self mode).
  final _ProtectionController protection;

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
              title: 'Connect this child device',
              message:
                  'Enter the pairing code from your parent to connect this phone. No child account is needed.',
              action: FilledButton.icon(
                onPressed: onGoToSignIn,
                icon: const Icon(Icons.login),
                label: const Text('Choose device setup'),
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
                  if (appDependencies.childSessionController.isSelfMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: Material(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: const Icon(
                            Icons.link_rounded,
                            color: AppColors.primary,
                          ),
                          title: const Text(
                            'Connect to a parent',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Link this phone using a parent pairing code',
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ChildPairingScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
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
                    subtitle: Text(
                      appDependencies.childSessionController.isSelfMode
                          ? 'Rescan the apps on this phone'
                          : 'Sync the latest parent rules',
                    ),
                    onTap: onRefresh,
                  ),
                  if (!appDependencies.childSessionController.isSelfMode)
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Need a rule changed?'),
                      subtitle: const Text(
                        'Ask your parent from Device & help',
                      ),
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
          title: appDependencies.childSessionController.isSelfMode
              ? 'Hi there'
              : 'Hi, ${device.childName}',
          subtitle: appDependencies.childSessionController.isSelfMode
              ? 'You are in self mode on ${device.deviceName}. It is not connected to a parent.'
              : 'This is your child dashboard for ${device.deviceName}. Your parent manages the rules.',
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
              showShadow: true,
              value: _formatMinutes(data.totalUsageToday),
              icon: Icons.timelapse,
              color: AppColors.primary,
              caption: '${data.apps.length} apps tracked',
            ),
            MetricCard(
              label: 'This week',
              showShadow: true,
              value: _formatMinutes(data.totalWeeklyUsage),
              icon: Icons.date_range,
              color: AppColors.secondary,
              caption: 'Tracked apps',
            ),
            MetricCard(
              label: 'Blocked apps',
              showShadow: true,
              value: '${data.blockedApps}',
              icon: Icons.block,
              color: AppColors.danger,
              caption: data.canManage ? 'Set by you' : 'Set by parent',
            ),
            MetricCard(
              label: 'Alerts',
              showShadow: true,
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

        SectionHeader(
          title: 'Today at a glance',
          subtitle: limitedApps.isEmpty
              ? 'No app limits are active for this device yet.'
              : 'Apps closest to their daily limit appear first.',
        ),
        const SizedBox(height: AppSizes.cardGap),
        if (limitedApps.isEmpty)
          EmptyStateWidget(
            icon: Icons.timer_off_outlined,
            title: 'No daily app limits',
            message: data.canManage
                ? 'Open Apps to set a daily limit for any app.'
                : 'Your parent can add app limits from their dashboard.',
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
        if (data.canManage && data.apps.isNotEmpty) ...[
          const SizedBox(height: AppSizes.sectionGap),
          _ChildUsageReportCard(apps: data.apps),
        ],
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
        SectionHeader(
          title: 'My app rules',
          subtitle: data.canManage
              ? 'Block apps and set daily limits for this phone.'
              : 'See daily limits, usage, blocked apps, and remaining time for this device.',
        ),
        if (data.canManage) ...[
          const SizedBox(height: AppSizes.sectionGap),
          _AppBlockingSetupCard(protection: data.protection),
        ],
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
                _ChildAppRuleTile(
                  app: app,
                  onBlockChanged: data.canManage
                      ? (value) => _runRuleChange(
                          context,
                          () => _rules.toggleAppBlock(app, value),
                        )
                      : null,
                  onLimitTap: data.canManage
                      ? () => _editAppLimit(context, app)
                      : null,
                ),
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
        SectionHeader(
          title: 'Website rules',
          subtitle: data.canManage
              ? 'Block or allow websites on this phone.'
              : 'Domains your parent has added for website filtering on this device.',
          action: data.canManage
              ? FilledButton.icon(
                  onPressed: () => _addWebsite(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add site'),
                )
              : null,
        ),
        if (data.canManage) ...[
          const SizedBox(height: AppSizes.sectionGap),
          _WebFilterSetupCard(protection: data.protection),
        ],
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
          EmptyStateWidget(
            icon: Icons.public,
            title: 'No website rules',
            message: data.canManage
                ? 'Tap Add site to block a website on this phone.'
                : 'Website rules will show here when your parent adds them.',
          )
        else
          Column(
            children: [
              for (final rule in rules) ...[
                _ChildWebsiteRuleTile(
                  rule: rule,
                  onBlockChanged: data.canManage
                      ? (value) => _runRuleChange(
                          context,
                          () => _rules.toggleWebsiteRule(rule, value),
                        )
                      : null,
                  onDelete: data.canManage
                      ? () => _runRuleChange(
                          context,
                          () => _rules.removeWebsiteRule(rule),
                        )
                      : null,
                ),
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
        SectionHeader(
          title: 'Recent alerts',
          subtitle:
              'Device events related to limits, blocks, sync, and online status.',
          action: data.canManage && data.unreadAlerts > 0
              ? TextButton.icon(
                  onPressed: () =>
                      _runRuleChange(context, _rules.markNotificationsRead),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark all read'),
                )
              : null,
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
            _PairingInfoCard(device: device, isSelfMode: data.canManage),
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
        final columns = constraints.maxWidth >= 960
            ? 4
            : constraints.maxWidth >= 320
            ? 2
            : 1;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
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

class _ProtectionStatusCard extends StatelessWidget {
  const _ProtectionStatusCard({required this.device});

  final ChildDevice device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabledCount = device.enabledProtectionCount;
    final protections = [
      ('Usage access', device.usageAccessEnabled, Icons.query_stats_rounded),
      ('VPN / filter', device.vpnFilterEnabled, Icons.vpn_lock_outlined),
      ('Background sync', device.backgroundServiceRunning, Icons.sync_rounded),
      ('Protected mode', device.protectedModeEnabled, Icons.shield_outlined),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Protection status',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: '$enabledCount of 4 protections enabled',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$enabledCount/4',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= 260 &&
                        MediaQuery.textScalerOf(context).scale(12) <= 18
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final protection in protections)
                      SizedBox(
                        width:
                            (constraints.maxWidth - (columns - 1) * 8) /
                            columns,
                        child: _DashboardTile(
                          label: protection.$1,
                          value: protection.$2 ? 'Active' : 'Needs setup',
                          icon: protection.$3,
                          statusIcon: protection.$2
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          statusColor: protection.$2
                              ? colors.secondary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                );
              },
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final details = [
      ('Device', device.deviceName, Icons.smartphone),
      ('Platform', device.platform, Icons.android),
      ('Last sync', DateFormatter.relative(device.lastSyncAt), Icons.sync),
      (
        'Last online',
        DateFormatter.relative(device.lastOnlineAt),
        device.isOnline ? Icons.wifi : Icons.wifi_off,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.perm_device_information_outlined,
                  color: colors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Device details',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= 260 &&
                        MediaQuery.textScalerOf(context).scale(12) <= 18
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final detail in details)
                      SizedBox(
                        width:
                            (constraints.maxWidth - (columns - 1) * 8) /
                            columns,
                        child: _DashboardTile(
                          label: detail.$1,
                          value: detail.$2,
                          icon: detail.$3,
                        ),
                      ),
                  ],
                );
              },
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

class _PairingInfoCard extends StatelessWidget {
  const _PairingInfoCard({required this.device, required this.isSelfMode});

  final ChildDevice device;
  final bool isSelfMode;

  @override
  Widget build(BuildContext context) {
    if (isSelfMode) return const _SelfModeConnectionCard();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parent connection',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Your parent manages the rules for this device. No child email or password is needed.',
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
                      device.deviceName,
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
                        appDependencies.childSessionController.isSelfMode
                            ? 'Not connected to a parent'
                            : 'Need a rule changed?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appDependencies.childSessionController.isSelfMode
                            ? 'You manage this phone yourself: block apps and set limits in Apps, and block websites in Sites. Choose Connect to a parent in the menu if you want a parent to manage it.'
                            : 'This child role is view-only. Ask your parent to update app limits, unblock apps, or change website rules from the parent dashboard.',
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

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.label,
    required this.value,
    required this.icon,
    this.statusColor,
    this.statusIcon,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color? statusColor;
  final IconData? statusIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (statusIcon != null) ...[
                      Icon(
                        statusIcon,
                        size: 12,
                        color: statusColor ?? colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        value,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor ?? colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
  const _ChildAppRuleTile({
    required this.app,
    this.onBlockChanged,
    this.onLimitTap,
  });

  final TrackedApp app;

  /// Set in self mode, where the user manages their own rules.
  final ValueChanged<bool>? onBlockChanged;
  final VoidCallback? onLimitTap;

  bool get _canManage => onBlockChanged != null;

  @override
  Widget build(BuildContext context) {
    final hasLimit = app.hasLimit;
    final progress = hasLimit
        ? (app.usageTodayMinutes / app.dailyLimitMinutes).clamp(0.0, 1.0)
        : 0.0;
    final color = app.isBlocked
        ? AppColors.danger
        : _categoryColor(app.category);
    final isBlocked = app.isBlocked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isBlocked
            ? AppColors.danger.withValues(alpha: 0.04)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked
              ? AppColors.danger.withValues(alpha: 0.3)
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
            child: Icon(
              isBlocked ? Icons.lock : _categoryIcon(app.category),
              color: color,
              size: 24,
            ),
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
                      hasLimit
                          ? '${_formatMinutes(app.usageTodayMinutes)} / ${_formatMinutes(app.dailyLimitMinutes)}'
                          : _formatMinutes(app.usageTodayMinutes),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isBlocked
                            ? AppColors.danger
                            : AppColors.ink.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (hasLimit) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      color: progress >= 1 || isBlocked
                          ? AppColors.danger
                          : color,
                      backgroundColor: isBlocked
                          ? AppColors.danger.withValues(alpha: 0.1)
                          : AppColors.border,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                // Wraps onto a second line on narrow screens.
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isBlocked
                          ? (_canManage ? 'Blocked' : 'Blocked by parent')
                          : app.category.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (onLimitTap != null)
                      _LimitLink(hasLimit: hasLimit, onTap: onLimitTap!),
                    if (app.blockedAttempts > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 10,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${app.blockedAttempts} blocked',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (onBlockChanged != null) ...[
            const SizedBox(width: 8),
            Switch(
              value: isBlocked,
              onChanged: onBlockChanged,
              activeThumbColor: AppColors.danger,
            ),
          ],
        ],
      ),
    );
  }
}

class _LimitLink extends StatelessWidget {
  const _LimitLink({required this.hasLimit, required this.onTap});

  final bool hasLimit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = hasLimit ? AppColors.secondary : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              hasLimit ? 'Edit Limit' : 'Set Limit',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildWebsiteRuleTile extends StatelessWidget {
  const _ChildWebsiteRuleTile({
    required this.rule,
    this.onBlockChanged,
    this.onDelete,
  });

  final WebsiteRule rule;

  /// Set in self mode, where the user manages their own rules.
  final ValueChanged<bool>? onBlockChanged;
  final VoidCallback? onDelete;

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
        trailing: onBlockChanged == null
            ? StatusPill(
                label: rule.isBlocked ? 'Blocked' : 'Allowed',
                icon: rule.isBlocked ? Icons.lock : Icons.lock_open,
                color: color,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: rule.isBlocked,
                    onChanged: onBlockChanged,
                    activeThumbColor: AppColors.danger,
                  ),
                  IconButton(
                    tooltip: 'Remove domain',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.muted,
                  ),
                ],
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

// ---------------------------------------------------------------------------
// Self mode: rule editing for this phone
// ---------------------------------------------------------------------------

DashboardController get _rules => appDependencies.dashboardController;

/// Saves a rule change and shows a message if it fails.
Future<void> _runRuleChange(
  BuildContext context,
  Future<void> Function() change,
) async {
  if (_rules.isLoading) return;
  final messenger = ScaffoldMessenger.of(context);
  await change();
  final error = _rules.errorMessage;
  if (error != null) {
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }
}

Future<void> _editAppLimit(BuildContext context, TrackedApp app) async {
  final minutes = await showAppLimitSheet(
    context,
    app: app,
    icon: _categoryIcon(app.category),
    color: _categoryColor(app.category),
  );
  if (minutes == null || !context.mounted) return;
  await _runRuleChange(context, () => _rules.updateAppLimit(app, minutes));
}

Future<void> _addWebsite(BuildContext context) async {
  final draft = await showAddWebsiteSheet(context);
  if (draft == null || !context.mounted) return;
  await _runRuleChange(
    context,
    () => _rules.addWebsiteRule(
      domain: draft.domain,
      includesSubdomains: draft.includesSubdomains,
    ),
  );
}

/// Weekly usage by app, shown on the self-mode overview.
class _ChildUsageReportCard extends StatelessWidget {
  const _ChildUsageReportCard({required this.apps});

  final List<TrackedApp> apps;

  @override
  Widget build(BuildContext context) {
    final sorted = [...apps]
      ..sort((a, b) => b.weeklyUsageMinutes.compareTo(a.weeklyUsageMinutes));
    final top = sorted.take(6).toList();
    final maxWeekly = top.isEmpty ? 0 : top.first.weeklyUsageMinutes;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage report',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              maxWeekly == 0
                  ? 'No usage recorded this week yet.'
                  : 'Most used this week: ${top.first.name}',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            for (final app in top) ...[
              Row(
                children: [
                  Icon(
                    _categoryIcon(app.category),
                    size: 18,
                    color: _categoryColor(app.category),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      app.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatMinutes(app.weeklyUsageMinutes),
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: maxWeekly == 0 ? 0 : app.weeklyUsageMinutes / maxWeekly,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: AppColors.border,
                color: _categoryColor(app.category),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// Device & help card shown in self mode instead of the parent pairing card.
class _SelfModeConnectionCard extends StatelessWidget {
  const _SelfModeConnectionCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                    'Parent connection',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const StatusPill(
                  label: 'Self mode',
                  icon: Icons.link_off,
                  color: AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You manage the rules on this phone. Connect to a parent if you want them to manage it instead.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChildPairingScreen(),
                ),
              ),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect to a parent'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Self mode: blocking setup on this phone
// ---------------------------------------------------------------------------

/// Signature of the rules the phone enforces; used to skip unchanged syncs.
String _rulesKey(List<TrackedApp> apps, List<WebsiteRule> websites) {
  final blocked = [
    for (final app in apps)
      if (app.isBlocked) app.packageName,
  ]..sort();
  final limits = [
    for (final app in apps)
      if (app.hasLimit) '${app.packageName}=${app.dailyLimitMinutes}',
  ]..sort();
  final sites = [
    for (final rule in websites)
      if (rule.isBlocked) '${rule.domain}:${rule.includesSubdomains}',
  ]..sort();
  return '${blocked.join(',')}|${limits.join(',')}|${sites.join(',')}';
}

/// Tracks what the phone allows for blocking and turns features on or off.
class _ProtectionController extends ChangeNotifier {
  ProtectionStatus status = ProtectionStatus.unsupported;
  bool isBusy = false;
  bool _disposed = false;

  DeviceProtection get _protection => appDependencies.deviceProtection;

  Future<void> refresh() async {
    final next = await _protection.status();
    if (_disposed) return;
    status = next;
    notifyListeners();
  }

  Future<void> openAppBlockingSettings() =>
      _protection.openAppBlockingSettings();

  Future<void> openUsageAccessSettings() =>
      _protection.openUsageAccessSettings();

  /// Returns false if the user declined the VPN permission.
  Future<bool> setWebFilter(bool enabled) async {
    if (isBusy) return true;
    isBusy = true;
    notifyListeners();
    var accepted = true;
    try {
      if (enabled) {
        accepted = await _protection.startWebFilter();
      } else {
        await _protection.stopWebFilter();
      }
      // The VPN starts in the background; give it a moment before checking.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await refresh();
    } finally {
      isBusy = false;
      if (!_disposed) notifyListeners();
    }
    return accepted;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Apps tab: app blocker and usage access.
class _AppBlockingSetupCard extends StatelessWidget {
  const _AppBlockingSetupCard({required this.protection});

  final _ProtectionController protection;

  @override
  Widget build(BuildContext context) {
    final status = protection.status;
    if (!status.isSupported) {
      return const _ProtectionUnsupportedCard(
        message:
            'App blocking works on Android phones. Rules you set here are saved and shown, but not enforced on this device.',
      );
    }
    final ready = status.appBlockingEnabled && status.usageAccessGranted;
    return _ProtectionCard(
      title: 'Blocking on this phone',
      isReady: ready,
      rows: [
        _ProtectionRow(
          icon: Icons.block_rounded,
          title: 'App blocking',
          description: status.appBlockingEnabled
              ? 'Blocked apps are closed as soon as they open.'
              : 'Opens Accessibility settings. Choose "Offspring Tracker app blocking" and turn it on.',
          isOn: status.appBlockingEnabled,
          actionLabel: 'Turn on',
          onAction: protection.openAppBlockingSettings,
        ),
        _ProtectionRow(
          icon: Icons.timer_outlined,
          title: 'Usage access',
          description: status.usageAccessGranted
              ? 'Daily limits are enforced and screen time is shown.'
              : 'Needed for daily limits and real screen time. Allow it for Offspring Tracker.',
          isOn: status.usageAccessGranted,
          actionLabel: 'Allow',
          onAction: protection.openUsageAccessSettings,
        ),
      ],
    );
  }
}

/// Sites tab: the website filter.
class _WebFilterSetupCard extends StatelessWidget {
  const _WebFilterSetupCard({required this.protection});

  final _ProtectionController protection;

  Future<void> _toggle(BuildContext context, bool enable) async {
    final messenger = ScaffoldMessenger.of(context);
    final accepted = await protection.setWebFilter(enable);
    if (!accepted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'The website filter needs VPN permission to block sites.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = protection.status;
    if (!status.isSupported) {
      return const _ProtectionUnsupportedCard(
        message:
            'Website blocking works on Android phones. Rules you set here are saved and shown, but not enforced on this device.',
      );
    }
    final isOn = status.webFilterActive;
    return _ProtectionCard(
      title: 'Website filter',
      isReady: isOn,
      rows: [
        _ProtectionRow(
          icon: Icons.public_off_rounded,
          title: isOn ? 'Filter is on' : 'Filter is off',
          description: isOn
              ? 'Blocked sites below will not load in any browser on this phone.'
              : 'Turn it on to block the sites below in every browser. It runs only on this phone and does not send your browsing anywhere.',
          isOn: isOn,
          actionLabel: protection.isBusy
              ? 'Please wait'
              : isOn
              ? 'Turn off'
              : 'Turn on',
          showActionWhenOn: true,
          onAction: protection.isBusy ? null : () => _toggle(context, !isOn),
        ),
      ],
      footnote:
          'Uses a VPN on this phone. If Private DNS is set to a specific provider in Android settings, sites may still load.',
    );
  }
}

class _ProtectionCard extends StatelessWidget {
  const _ProtectionCard({
    required this.title,
    required this.isReady,
    required this.rows,
    this.footnote,
  });

  final String title;
  final bool isReady;
  final List<Widget> rows;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusPill(
                  label: isReady ? 'Active' : 'Setup needed',
                  icon: isReady
                      ? Icons.verified_user_outlined
                      : Icons.warning_amber_rounded,
                  color: isReady ? AppColors.secondary : AppColors.accent,
                ),
              ],
            ),
            for (final row in rows) ...[const SizedBox(height: 14), row],
            if (footnote != null) ...[
              const SizedBox(height: 14),
              Text(
                footnote!,
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProtectionRow extends StatelessWidget {
  const _ProtectionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.isOn,
    required this.actionLabel,
    required this.onAction,
    this.showActionWhenOn = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isOn;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool showActionWhenOn;

  @override
  Widget build(BuildContext context) {
    final color = isOn ? AppColors.secondary : AppColors.muted;
    final showAction = !isOn || showActionWhenOn;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (isOn) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              if (showAction) ...[
                const SizedBox(height: 8),
                isOn
                    ? OutlinedButton(
                        onPressed: onAction,
                        child: Text(actionLabel),
                      )
                    : FilledButton(
                        onPressed: onAction,
                        child: Text(actionLabel),
                      ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProtectionUnsupportedCard extends StatelessWidget {
  const _ProtectionUnsupportedCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ),
          ],
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
    case AppCategory.other:
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
    case AppCategory.other:
      return Icons.apps_outlined;
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
