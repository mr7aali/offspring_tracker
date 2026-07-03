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

part '../widgets/dashboard/dashboard_drawer.dart';
part '../widgets/dashboard/dashboard_navigation.dart';
part '../widgets/dashboard/dashboard_sections.dart';
part '../widgets/dashboard/dashboard_common_widgets.dart';
part '../widgets/dashboard/dashboard_device_widgets.dart';
part '../widgets/dashboard/dashboard_rule_cards.dart';
part '../widgets/dashboard/dashboard_admin_widgets.dart';
part 'dashboard_settings_screens.dart';
part '../widgets/dashboard/settings_info_widgets.dart';
part 'support_tickets_screen.dart';
part '../widgets/support/support_ticket_form.dart';
part '../widgets/support/support_ticket_list.dart';
part '../widgets/support/support_ticket_card.dart';
part '../widgets/dashboard/dashboard_dialogs.dart';
part '../widgets/dashboard/dashboard_helpers.dart';

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
