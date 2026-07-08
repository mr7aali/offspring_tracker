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
    expect(find.text('Child access'), findsOneWidget);
  });

  testWidgets('demo parent can open dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const OffspringTrackerApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    final parentButton = find.text('Continue as parent');
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

    final childButton = find.text('Continue as child');
    await tester.ensureVisible(childButton);
    await tester.pumpAndSettle();
    await tester.tap(childButton);
    await tester.pumpAndSettle();

    final demoButton = find.text('Use demo child');
    await tester.ensureVisible(demoButton);
    await tester.pumpAndSettle();
    await tester.tap(demoButton);
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
}
