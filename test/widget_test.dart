import 'package:flutter_test/flutter_test.dart';
import 'package:aura_fit/app.dart';

void main() {
  testWidgets('AuraFit smoke test — app launches without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AuraFitApp());
    expect(find.byType(AuraFitApp), findsOneWidget);
  });
}