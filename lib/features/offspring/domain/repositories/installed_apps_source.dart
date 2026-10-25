import 'dart:typed_data';

import '../entities/installed_app.dart';

abstract class InstalledAppsSource {
  bool get isSupported;
  Stream<void> get changes;
  Future<List<InstalledApp>> discover();

  /// The app's icon as PNG bytes, or null when unavailable.
  Future<Uint8List?> loadIcon(String packageName);
}
