part of '../../screens/dashboard_screen.dart';

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
