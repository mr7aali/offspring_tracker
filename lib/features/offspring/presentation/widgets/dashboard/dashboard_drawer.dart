part of '../../screens/dashboard_screen.dart';

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
