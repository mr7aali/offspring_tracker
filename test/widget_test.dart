import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offspring_tracker/app.dart';
import 'package:offspring_tracker/config/dependency_injection.dart';

void main() {
  setUp(setupDependencies);

  testWidgets('shows parent auth entry point', (WidgetTester tester) async {
    await tester.pumpWidget(const OffspringTrackerApp());
    expect(find.text('Family safety, calmly connected'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Offspring Tracker'), findsOneWidget);
    expect(find.text('Choose how you want to continue'), findsOneWidget);
    expect(find.text('Parent access'), findsOneWidget);
    expect(find.text('Child device setup'), findsOneWidget);
  });

  testWidgets('demo parent can open dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const OffspringTrackerApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    final parentButton = find.text('Parent sign in');
    await tester.ensureVisible(parentButton);
    await tester.pumpAndSettle();
    await tester.tap(parentButton);
    await tester.pumpAndSettle();

    final demoButton = find.text('Use demo parent');
    await tester.ensureVisible(demoButton);
    await tester.pumpAndSettle();
    await tester.tap(demoButton);
    await tester.pumpAndSettle();

    expect(find.text('Parent dashboard'), findsOneWidget);
    expect(find.text('Maya'), findsWidgets);
    expect(find.text('Pair device'), findsOneWidget);
  });

  testWidgets('demo child can open child dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OffspringTrackerApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    final childButton = find.text('Connect child device');
    await tester.ensureVisible(childButton);
    await tester.pumpAndSettle();
    await tester.tap(childButton);
    await tester.pumpAndSettle();

    final demoButton = find.text('Try demo connection');
    await tester.ensureVisible(demoButton);
    await tester.pumpAndSettle();
    await tester.tap(demoButton);
    await tester.pumpAndSettle();

    expect(find.text('Device connected'), findsOneWidget);
    await tester.tap(find.text('Continue to my device'));
    await tester.pumpAndSettle();
    expect(find.text('Hi, Maya'), findsOneWidget);

    await tester.tap(find.text('Apps').last);
    await tester.pumpAndSettle();
    expect(find.text('My app rules'), findsOneWidget);

    await tester.tap(find.text('Sites').last);
    await tester.pumpAndSettle();
    expect(find.text('Website rules'), findsWidgets);

    await tester.tap(find.text('Alerts').last);
    await tester.pumpAndSettle();
    expect(find.text('Recent alerts'), findsOneWidget);

    await tester.tap(find.text('Device').last);
    await tester.pumpAndSettle();
    expect(find.text('Device & help'), findsWidgets);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets('child setup has only a code field and rejects invalid codes', (
    tester,
  ) async {
    await tester.pumpWidget(const OffspringTrackerApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Connect child device');
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Password'), findsNothing);
    await tapVisible(tester, 'Connect this device');
    expect(
      find.text('Enter the code shown on the parent phone'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'INVALID1');
    await tapVisible(tester, 'Connect this device');
    expect(
      find.text(
        'Pairing code not found. Check the code on the parent dashboard.',
      ),
      findsOneWidget,
    );
    expect(find.text('Device connected'), findsNothing);
  });

  testWidgets('parent generates a code and child connects without an account', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const OffspringTrackerApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Parent sign in');
    await tapVisible(tester, 'Use demo parent');
    await tapVisible(tester, 'Pair device');
    expect(find.text('Pairing code'), findsNothing);
    await tapVisible(tester, 'Generate pairing code');
    expect(find.text('Child name is required'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Child name'),
      'Robin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Device name'),
      'Robin phone',
    );
    await tapVisible(tester, 'Generate pairing code');
    final code = tester
        .widget<SelectableText>(
          find.byKey(const ValueKey('generated-pairing-code')),
        )
        .data!;
    expect(code, matches(RegExp(r'^[A-Z2-9]{8}$')));
    await tapVisible(tester, 'Done');
    await tester.tap(find.byTooltip('Account and settings'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Sign out');
    await tapVisible(tester, 'Connect child device');
    await tester.enterText(find.byType(TextFormField), code.toLowerCase());
    await tapVisible(tester, 'Connect this device');
    expect(find.text('Device connected'), findsOneWidget);
    expect(find.text('Robin \u2022 Robin phone'), findsOneWidget);
    await tapVisible(tester, 'Continue to my device');
    expect(find.text('Hi, Robin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> tapVisible(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
