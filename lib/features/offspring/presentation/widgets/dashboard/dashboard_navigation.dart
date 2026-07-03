part of '../../screens/dashboard_screen.dart';

const List<_DashboardDestination> _dashboardDestinations = [
  _DashboardDestination(
    section: DashboardSection.overview,
    label: 'Home',
    railLabel: 'Overview',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  _DashboardDestination(
    section: DashboardSection.apps,
    label: 'Apps',
    railLabel: 'Apps',
    icon: Icons.apps_outlined,
    selectedIcon: Icons.apps,
  ),
  _DashboardDestination(
    section: DashboardSection.websites,
    label: 'Sites',
    railLabel: 'Websites',
    icon: Icons.public_off_outlined,
    selectedIcon: Icons.public_off,
  ),
  _DashboardDestination(
    section: DashboardSection.reports,
    label: 'Reports',
    railLabel: 'Reports',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
  _DashboardDestination(
    section: DashboardSection.alerts,
    label: 'Alerts',
    railLabel: 'Alerts',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
  ),
  _DashboardDestination(
    section: DashboardSection.admin,
    label: 'Admin',
    railLabel: 'Admin & plans',
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings,
  ),
];

class _DashboardDestination {
  const _DashboardDestination({
    required this.section,
    required this.label,
    required this.railLabel,
    required this.icon,
    required this.selectedIcon,
  });

  final DashboardSection section;
  final String label;
  final String railLabel;
  final IconData icon;
  final IconData selectedIcon;
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
        controller.showSection(_dashboardDestinations[index].section);
      },
      destinations: [
        for (final destination in _dashboardDestinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.railLabel),
          ),
      ],
    );
  }
}

class _AnimatedDashboardBottomNav extends StatelessWidget {
  const _AnimatedDashboardBottomNav({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 280);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final selectedIndex = _dashboardDestinations.indexWhere(
              (destination) => destination.section == controller.section,
            );
            final itemWidth =
                constraints.maxWidth / _dashboardDestinations.length;

            return SizedBox(
              height: 56,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    left: itemWidth * selectedIndex,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final destination in _dashboardDestinations)
                        Expanded(
                          child: _AnimatedDashboardBottomNavItem(
                            destination: destination,
                            selected: controller.section == destination.section,
                            onTap: () =>
                                controller.showSection(destination.section),
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
    );
  }
}

class _AnimatedDashboardBottomNavItem extends StatelessWidget {
  const _AnimatedDashboardBottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _DashboardDestination destination;
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
          borderRadius: BorderRadius.circular(18),
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      child: Icon(
                        destination.selectedIcon,
                        size: 30,
                        color: Colors.white,
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
