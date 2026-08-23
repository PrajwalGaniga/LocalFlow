import 'package:flutter_test/flutter_test.dart';
import 'package:localflow_mobile/main.dart';

void main() {
  testWidgets('App loads splash loader and transitions to role selection', (WidgetTester tester) async {
    await tester.pumpWidget(const LocalFlowApp());
    expect(find.text('LOCALFLOW'), findsOneWidget);
    expect(find.text('Connecting to Local Grid...'), findsOneWidget);

    // Advance time past splash timer
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Synchronizing Services...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Ready ⚡'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Instant Local Services'), findsOneWidget);
    expect(find.text("I'm a Service Provider"), findsOneWidget);
    expect(find.text("I'm a Customer"), findsOneWidget);
  });
}
