import 'package:flutter_test/flutter_test.dart';
import 'package:english_vocab_test/main.dart';

void main() {
  testWidgets('App starts and shows home', (WidgetTester tester) async {
    await tester.pumpWidget(const VocabApp());
    await tester.pumpAndSettle();
    expect(find.text('English Test'), findsOneWidget);
  });
}
