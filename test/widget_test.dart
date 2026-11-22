import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ucb_perdidos/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('La app abre con las pestañas', (WidgetTester tester) async {
    await tester.pumpWidget(const PerdidosApp());

    expect(find.text('UCB Perdidos'), findsOneWidget);
    expect(find.text('Perdidos'), findsOneWidget);
    expect(find.text('Encontrados'), findsOneWidget);
  });
}
