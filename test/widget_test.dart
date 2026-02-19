import 'package:flutter_test/flutter_test.dart';

import 'package:carlog/main.dart';

void main() {
  testWidgets('shows auth screen in local mock mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(firebaseEnabled: false));

    expect(find.text('CarLog'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });
}
