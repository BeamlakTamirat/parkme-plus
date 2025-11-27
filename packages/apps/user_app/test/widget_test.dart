import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/src/app.dart';

void main() {
  testWidgets('ParkMe+ app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ParkMePlusApp(),
      ),
    );

    expect(find.text('ParkMe+'), findsOneWidget);
  });
}
