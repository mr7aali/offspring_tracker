part of 'dashboard_screen.dart';

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
