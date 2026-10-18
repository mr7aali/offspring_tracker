import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offspring_tracker/features/offspring/data/datasources/android_installed_apps_source.dart';
import 'package:offspring_tracker/features/offspring/data/datasources/offspring_local_datasource.dart';
import 'package:offspring_tracker/features/offspring/data/repositories/offspring_repository_impl.dart';
import 'package:offspring_tracker/features/offspring/domain/entities/installed_app.dart';
import 'package:offspring_tracker/features/offspring/domain/entities/tracked_app.dart';
import 'package:offspring_tracker/features/offspring/domain/usecases/refresh_installed_apps_usecase.dart';

const chrome = InstalledApp(
  packageName: 'com.android.chrome',
  name: 'Chrome',
  category: AppCategory.browser,
);
const notes = InstalledApp(
  packageName: 'example.notes',
  name: 'Notes',
  category: AppCategory.productivity,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(
      AndroidInstalledAppsSource.channel,
      null,
    );
  });

  test(
    'inventory replaces seeds only for target device and clears fake telemetry',
    () async {
      final source = OffspringLocalDataSource();
      final other = await source.getApps('device-2');
      final notifications = await source.getNotifications();
      await source.syncInstalledApps('device-1', [chrome, notes, notes]);
      final apps = await source.getApps('device-1');
      expect(apps.map((app) => app.packageName), [
        chrome.packageName,
        notes.packageName,
      ]);
      expect(
        apps.every(
          (app) => app.usageTodayMinutes == 0 && app.lastOpenedAt == null,
        ),
        isTrue,
      );
      expect(await source.getApps('device-2'), other);
      expect(await source.getNotifications(), notifications);
    },
  );

  test(
    'updates preserve IDs and rules; uninstall removes app; new install alerts once',
    () async {
      final source = OffspringLocalDataSource();
      await source.syncInstalledApps('device-1', [chrome]);
      final app = (await source.getApps('device-1')).single;
      await source.updateAppRule(
        appId: app.id,
        isBlocked: true,
        dailyLimitMinutes: 17,
      );
      const renamed = InstalledApp(
        packageName: 'com.android.chrome',
        name: 'Chrome updated',
        category: AppCategory.other,
      );
      await source.syncInstalledApps('device-1', [renamed, notes]);
      final updated = (await source.getApps('device-1')).first;
      expect(updated.id, app.id);
      expect(updated.name, renamed.name);
      expect(updated.category, AppCategory.other);
      expect(updated.isBlocked, isTrue);
      expect(updated.dailyLimitMinutes, 17);
      final count = (await source.getNotifications()).length;
      await source.syncInstalledApps('device-1', [renamed, notes]);
      expect((await source.getNotifications()).length, count);
      await source.syncInstalledApps('device-1', [notes]);
      expect(
        (await source.getApps('device-1')).single.packageName,
        notes.packageName,
      );
      await source.syncInstalledApps('device-1', []);
      expect(await source.getApps('device-1'), isEmpty);
    },
  );

  test(
    'channel maps metadata and unknown category without inventing categories',
    () async {
      messenger.setMockMethodCallHandler(AndroidInstalledAppsSource.channel, (
        call,
      ) async {
        expect(call.method, 'getInstalledApps');
        return [
          {
            'packageName': 'example.app',
            'name': 'Example',
            'category': 'unknown',
          },
        ];
      });
      final apps = await AndroidInstalledAppsSource().discover();
      expect(apps.single.packageName, 'example.app');
      expect(apps.single.category, AppCategory.other);
    },
  );

  test(
    'failed or malformed native scan preserves previous inventory',
    () async {
      final local = OffspringLocalDataSource();
      final refresh = RefreshInstalledAppsUseCase(
        AndroidInstalledAppsSource(),
        OffspringRepositoryImpl(local),
      );
      final before = await local.getApps('device-1');
      messenger.setMockMethodCallHandler(AndroidInstalledAppsSource.channel, (
        _,
      ) async {
        throw PlatformException(code: 'inventory_failed');
      });
      await expectLater(refresh('device-1'), throwsA(isA<PlatformException>()));
      expect(await local.getApps('device-1'), before);
      messenger.setMockMethodCallHandler(
        AndroidInstalledAppsSource.channel,
        (_) async => null,
      );
      await expectLater(refresh('device-1'), throwsFormatException);
      expect(await local.getApps('device-1'), before);
    },
  );

  test(
    'unsupported platforms retain demo inventory without calling native channel',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      messenger.setMockMethodCallHandler(
        AndroidInstalledAppsSource.channel,
        (_) async => fail('Unexpected platform call'),
      );
      final local = OffspringLocalDataSource();
      final before = await local.getApps('device-1');
      await RefreshInstalledAppsUseCase(
        AndroidInstalledAppsSource(),
        OffspringRepositoryImpl(local),
      )('device-1');
      expect(await local.getApps('device-1'), before);
    },
  );
}
