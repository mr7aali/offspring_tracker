import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offspring_tracker/config/dependency_injection.dart';
import 'package:offspring_tracker/features/offspring/data/datasources/android_installed_apps_source.dart';
import 'package:offspring_tracker/features/offspring/presentation/screens/child_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const eventMethod = MethodChannel('offspring_tracker/installed_apps/changes');
  var scans = 0;
  var failScan = false;
  var rows = <Map<String, String>>[];
  setUp(() {
    setupDependencies();
    scans = 0;
    failScan = false;
    rows = [
      {
        'packageName': 'example.notes',
        'name': 'My Notes',
        'category': 'productivity',
      },
    ];
    messenger.setMockMethodCallHandler(eventMethod, (_) async => null);
    messenger.setMockMethodCallHandler(AndroidInstalledAppsSource.channel, (
      _,
    ) async {
      scans++;
      if (failScan) throw PlatformException(code: 'inventory_failed');
      return rows;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(eventMethod, null);
    messenger.setMockMethodCallHandler(
      AndroidInstalledAppsSource.channel,
      null,
    );
  });

  testWidgets('child scans on entry, package change, resume and manual retry', (
    tester,
  ) async {
    await appDependencies.childSessionController.connect(pairingCode: 'MAYA7');
    await tester.pumpWidget(const MaterialApp(home: ChildDashboardScreen()));
    await tester.pumpAndSettle();
    expect(scans, 1);
    expect(appDependencies.dashboardController.apps.single.name, 'My Notes');
    rows = [
      {'packageName': 'example.reader', 'name': 'Reader', 'category': 'other'},
    ];
    await messenger.handlePlatformMessage(
      'offspring_tracker/installed_apps/changes',
      const StandardMethodCodec().encodeSuccessEnvelope(null),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(scans, 2);
    expect(appDependencies.dashboardController.apps.single.name, 'Reader');
    failScan = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(scans, 3);
    expect(
      find.textContaining('Could not read installed apps'),
      findsOneWidget,
    );
    expect(appDependencies.dashboardController.apps.single.name, 'Reader');
    failScan = false;
    rows = [];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(scans, 4);
    expect(appDependencies.dashboardController.apps, isEmpty);
    expect(find.textContaining('Could not read installed apps'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit demo connection never scans local apps', (
    tester,
  ) async {
    await appDependencies.childSessionController.connect(
      pairingCode: 'MAYA7',
      isDemo: true,
    );
    await tester.pumpWidget(const MaterialApp(home: ChildDashboardScreen()));
    await tester.pumpAndSettle();
    expect(scans, 0);
    expect(appDependencies.dashboardController.apps.length, 4);
    await tester.pumpWidget(const SizedBox());
  });
}
