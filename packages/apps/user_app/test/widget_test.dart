import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/src/app.dart';

void main() {
  testWidgets('WePark app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WeParkApp(),
      ),
    );

    expect(find.text('WePark'), findsOneWidget);
  });
}
