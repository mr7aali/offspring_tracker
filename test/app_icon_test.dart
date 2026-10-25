import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offspring_tracker/config/dependency_injection.dart';
import 'package:offspring_tracker/features/offspring/presentation/widgets/app_icon_image.dart';

// A 1x1 transparent PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('offspring_tracker/installed_apps');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    setupDependencies();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'getAppIcon') return null;
      final package = (call.arguments as Map)['packageName'];
      return package == 'example.withicon' ? _png : null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Widget host(String packageName) => MaterialApp(
    home: Scaffold(
      body: AppIconImage(
        packageName: packageName,
        fallbackIcon: Icons.apps,
        color: Colors.blue,
      ),
    ),
  );

  testWidgets('shows the real icon when the phone provides one', (
    tester,
  ) async {
    await tester.pumpWidget(host('example.withicon'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.apps), findsNothing);
  });

  testWidgets('falls back to the category symbol without an icon', (
    tester,
  ) async {
    await tester.pumpWidget(host('example.noicon'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.apps), findsOneWidget);
  });
}
