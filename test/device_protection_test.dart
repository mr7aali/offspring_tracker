import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offspring_tracker/app.dart';
import 'package:offspring_tracker/config/dependency_injection.dart';
import 'package:offspring_tracker/features/offspring/data/datasources/android_device_protection.dart';
import 'package:offspring_tracker/features/offspring/domain/entities/tracked_app.dart';
import 'package:offspring_tracker/features/offspring/domain/entities/website_rule.dart';

/// Records calls to the native protection channel and answers like Android.
class FakeProtectionPlatform {
  final calls = <MethodCall>[];
  bool appBlockingEnabled = true;
  bool usageAccessGranted = true;
  bool webFilterActive = false;
  Map<String, Map<String, int>> usage = {};

  List<MethodCall> callsTo(String method) =>
      calls.where((call) => call.method == method).toList();

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'getStatus':
        return {
          'appBlockingEnabled': appBlockingEnabled,
          'usageAccessGranted': usageAccessGranted,
          'webFilterActive': webFilterActive,
        };
      case 'getUsage':
        return usage;
      case 'startWebFilter':
        webFilterActive = true;
        return true;
      case 'stopWebFilter':
        webFilterActive = false;
        return null;
      default:
        return null;
    }
  }
}

TrackedApp _app(String package, {bool blocked = false, int limit = 0}) =>
    TrackedApp(
      id: package,
      deviceId: 'device',
      name: package,
      packageName: package,
      category: AppCategory.other,
      isBlocked: blocked,
      dailyLimitMinutes: limit,
      usageTodayMinutes: 0,
      weeklyUsageMinutes: 0,
      blockedAttempts: 0,
      lastOpenedAt: null,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeProtectionPlatform platform;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    setupDependencies();
    platform = FakeProtectionPlatform();
    messenger.setMockMethodCallHandler(
      AndroidDeviceProtection.channel,
      platform.handle,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('offspring_tracker/installed_apps'),
      (_) async => [
        {
          'packageName': 'example.game',
          'name': 'Space Game',
          'category': 'games',
        },
        {
          'packageName': 'example.notes',
          'name': 'My Notes',
          'category': 'productivity',
        },
      ],
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('offspring_tracker/installed_apps/changes'),
      (_) async => null,
    );
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(AndroidDeviceProtection.channel, null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('offspring_tracker/installed_apps'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('offspring_tracker/installed_apps/changes'),
      null,
    );
  });

  test('sends only active rules to the phone', () async {
    await AndroidDeviceProtection().applyRules(
      apps: [
        _app('blocked.app', blocked: true),
        _app('limited.app', limit: 30),
        _app('free.app'),
      ],
      websites: [
        WebsiteRule(
          id: '1',
          deviceId: 'device',
          domain: 'blocked.com',
          includesSubdomains: true,
          isBlocked: true,
          blockedAttempts: 0,
          createdAt: DateTime(2026),
        ),
        WebsiteRule(
          id: '2',
          deviceId: 'device',
          domain: 'allowed.com',
          includesSubdomains: false,
          isBlocked: false,
          blockedAttempts: 0,
          createdAt: DateTime(2026),
        ),
      ],
    );

    final args = platform.callsTo('syncRules').single.arguments as Map;
    expect(args['blockedApps'], ['blocked.app']);
    expect(args['appLimitMinutes'], {'limited.app': 30});
    expect(args['blockedSites'], [
      {'domain': 'blocked.com', 'includesSubdomains': true},
    ]);
  });

  testWidgets('self mode enforces rule changes and clears them on sign out', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    platform.usage = {
      'example.game': {
        'todayMinutes': 42,
        'weekMinutes': 180,
        'blockedAttempts': 3,
      },
    };

    await tester.pumpWidget(const OffspringTrackerApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start self mode'));
    await tester.tap(find.text('Start self mode'));
    await tester.pumpAndSettle();

    // Real screen time from the phone replaces the placeholder values.
    final game = appDependencies.dashboardController.apps.firstWhere(
      (app) => app.packageName == 'example.game',
    );
    expect(game.usageTodayMinutes, 42);
    expect(game.weeklyUsageMinutes, 180);
    expect(game.blockedAttempts, 3);

    // Apps tab shows the blocking setup as active.
    await tester.tap(find.text('Apps').last);
    await tester.pumpAndSettle();
    expect(find.text('Blocking on this phone'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    // Blocking an app sends it to the phone.
    platform.calls.clear();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    final synced = platform.callsTo('syncRules').last.arguments as Map;
    expect(synced['blockedApps'], isNotEmpty);

    // Sites tab: turn the website filter on.
    await tester.tap(find.text('Sites').last);
    await tester.pumpAndSettle();
    expect(find.text('Filter is off'), findsOneWidget);
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(platform.callsTo('startWebFilter'), hasLength(1));
    expect(find.text('Filter is on'), findsOneWidget);

    // Signing out of self mode removes the blocks from the phone.
    platform.calls.clear();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    final cleared = platform.callsTo('syncRules').last.arguments as Map;
    expect(cleared['blockedApps'], isEmpty);
    expect(cleared['blockedSites'], isEmpty);
    expect(platform.callsTo('stopWebFilter'), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('setup card asks for permissions that are missing', (
    tester,
  ) async {
    platform.appBlockingEnabled = false;
    platform.usageAccessGranted = false;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const OffspringTrackerApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start self mode'));
    await tester.tap(find.text('Start self mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apps').last);
    await tester.pumpAndSettle();

    expect(find.text('Setup needed'), findsOneWidget);
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(platform.callsTo('openAppBlockingSettings'), hasLength(1));
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(platform.callsTo('openUsageAccessSettings'), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
