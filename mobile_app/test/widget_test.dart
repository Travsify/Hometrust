import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('HomeVerify app initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HomeVerifyApp());
    expect(find.text('HomeVerify'), findsOneWidget);
  });
}
