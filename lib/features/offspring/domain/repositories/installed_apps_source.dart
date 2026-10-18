import '../entities/installed_app.dart';

abstract class InstalledAppsSource {
  bool get isSupported;
  Stream<void> get changes;
  Future<List<InstalledApp>> discover();
}
