import 'package:flutter_test/flutter_test.dart';
import 'package:chapgo_app/main.dart';

void main() {
  testWidgets('App renders welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ChapgoApp());
    expect(find.text('Chapgo'), findsWidgets);
  });
}
