import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('EstateVerify app initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EstateVerifyApp());
    expect(find.text('EstateVerify'), findsOneWidget);
    expect(find.text('VERIFIED'), findsOneWidget);
  });
}
