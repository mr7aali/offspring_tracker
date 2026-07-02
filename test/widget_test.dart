import 'package:flutter_test/flutter_test.dart';
import 'package:offspring_tracker/app.dart';
import 'package:offspring_tracker/config/dependency_injection.dart';

void main() {
  setUp(setupDependencies);

  testWidgets('shows parent auth entry point', (WidgetTester tester) async {
    await tester.pumpWidget(const OffspringTrackerApp());

    expect(find.text('Offspring Tracker'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Use demo parent'), findsOneWidget);
  });

  testWidgets('demo parent can open dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const OffspringTrackerApp());

    final demoButton = find.text('Use demo parent');
    await tester.ensureVisible(demoButton);
    await tester.pumpAndSettle();
    await tester.tap(demoButton);
    await tester.pumpAndSettle();

    expect(find.text('Parent dashboard'), findsOneWidget);
    expect(find.text('Maya'), findsWidgets);
    expect(find.text('Pair device'), findsOneWidget);
  });
}
