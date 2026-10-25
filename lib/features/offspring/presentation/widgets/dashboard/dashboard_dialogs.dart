part of '../../screens/dashboard_screen.dart';

Future<void> _showPairDeviceDialog(
  BuildContext context,
  DashboardController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PairChildDeviceDialog(controller: controller),
  );
}

Future<void> _showLimitDialog(
  BuildContext context,
  DashboardController controller,
  TrackedApp app,
) async {
  final minutes = await showAppLimitSheet(
    context,
    app: app,
    icon: _categoryIcon(app.category),
    color: _categoryColor(app.category),
  );
  if (minutes != null) {
    await controller.updateAppLimit(app, minutes);
  }
}

Future<void> _showWebsiteDialog(
  BuildContext context,
  DashboardController controller,
) async {
  final draft = await showAddWebsiteSheet(context);
  if (draft != null) {
    await controller.addWebsiteRule(
      domain: draft.domain,
      includesSubdomains: draft.includesSubdomains,
    );
  }
}
