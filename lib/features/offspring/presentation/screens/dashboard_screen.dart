import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/entities/alert_notification.dart';
import '../../domain/entities/child_device.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/tracked_app.dart';
import '../../domain/entities/website_rule.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/pair_child_device_dialog.dart';

part '../widgets/dashboard/dashboard_drawer.dart';
part '../widgets/dashboard/dashboard_navigation.dart';
part '../widgets/dashboard/dashboard_sections.dart';
part '../widgets/dashboard/dashboard_common_widgets.dart';
part '../widgets/dashboard/dashboard_device_widgets.dart';
part '../widgets/dashboard/dashboard_rule_cards.dart';
part '../widgets/dashboard/dashboard_admin_widgets.dart';
part 'dashboard_settings_screens.dart';
part 'child_devices_screen.dart';
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
          extendBody: !isWide,
          drawer: _DashboardDrawer(controller: _controller, onLogout: _logout),
          appBar: AppBar(
            titleSpacing: 16,
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                height: 1.0,
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const AppLogoMark(
                    size: 36,
                    padding: 0,
                    backgroundColor: Colors.white,
                    borderRadius: AppSizes.radius,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    AppStrings.appName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              if (isWide && summary != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.15),
                            AppColors.accent.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            '${summary.currentPlanName} Plan',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_controller.devices.isNotEmpty)
                _GlobalDeviceButton(controller: _controller, compact: !isWide),
              Builder(
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                    child: Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
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
              : _AnimatedDashboardBottomNav(controller: _controller),
        );
      },
    );
  }
}
