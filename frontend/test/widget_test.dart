import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Auth page shows Curamind brand and mode toggle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CuramindApp());
    await tester.pump();

    expect(find.text('Curamind'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Daftar'), findsOneWidget);
  });
}
