import 'tracked_app.dart';

/// Inventory metadata only; discovery does not measure usage or enforce rules.
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.name,
    required this.category,
  });

  final String packageName;
  final String name;
  final AppCategory category;
}
