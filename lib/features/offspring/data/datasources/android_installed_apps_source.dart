import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/installed_app.dart';
import '../../domain/entities/tracked_app.dart';
import '../../domain/repositories/installed_apps_source.dart';

class AndroidInstalledAppsSource implements InstalledAppsSource {
  static const channel = MethodChannel('offspring_tracker/installed_apps');
  static const events = EventChannel(
    'offspring_tracker/installed_apps/changes',
  );

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  late final Stream<void> _changes = events.receiveBroadcastStream().map(
    (_) {},
  );

  @override
  Stream<void> get changes => isSupported ? _changes : const Stream.empty();

  @override
  Future<Uint8List?> loadIcon(String packageName) async {
    if (!isSupported) return null;
    try {
      return await channel.invokeMethod<Uint8List>('getAppIcon', {
        'packageName': packageName,
      });
    } catch (_) {
      // Missing icons fall back to the category symbol.
      return null;
    }
  }

  @override
  Future<List<InstalledApp>> discover() async {
    if (!isSupported) throw UnsupportedError('Android is required');
    final rows = await channel.invokeListMethod<Object?>('getInstalledApps');
    if (rows == null) throw const FormatException('Missing app inventory');
    return rows.map((row) {
      final data = Map<String, dynamic>.from(row as Map);
      final package = data['packageName'] as String;
      final name = data['name'] as String;
      if (package.isEmpty || name.isEmpty) {
        throw const FormatException('Invalid app metadata');
      }
      return InstalledApp(
        packageName: package,
        name: name,
        category: AppCategory.values.firstWhere(
          (category) => category.name == data['category'],
          orElse: () => AppCategory.other,
        ),
      );
    }).toList();
  }
}
