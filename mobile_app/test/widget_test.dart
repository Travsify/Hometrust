import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('Hometrust app initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HometrustApp());
    expect(find.text('Hometrust'), findsOneWidget);
  });
}
