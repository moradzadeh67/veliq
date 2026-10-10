import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/main.dart';

void main() {
  testWidgets('Veliq app shows placeholder text', (WidgetTester tester) async {
    await tester.pumpWidget(const VeliqApp());
    expect(find.text('Veliq - Ready for development'), findsOneWidget);
  });
}
