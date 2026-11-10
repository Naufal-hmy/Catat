import 'package:flutter_test/flutter_test.dart';
import 'package:my_task_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyTaskApp());
    expect(find.byType(MyTaskApp), findsOneWidget);
  });
}
