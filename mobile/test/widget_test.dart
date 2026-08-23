import 'package:flutter_test/flutter_test.dart';
import 'package:localflow_mobile/main.dart';

void main() {
  testWidgets('App loads role selection smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LocalFlowApp());
    expect(find.text('Instant Local Services'), findsOneWidget);
    expect(find.text("I'm a Service Provider"), findsOneWidget);
    expect(find.text("I'm a Customer"), findsOneWidget);
  });
}
