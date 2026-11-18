import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_anniversary.dart';

void main() {
  test('Celebration is monthly, in the local device calendar', () {
    expect(SaturnAnniversary.isActive(DateTime(2026, 11, 18)), isTrue);
    expect(SaturnAnniversary.isActive(DateTime(2026, 12, 18, 23, 59)), isTrue);
    expect(SaturnAnniversary.isActive(DateTime(2027, 1, 18)), isTrue);
    expect(SaturnAnniversary.isActive(DateTime(2026, 11, 17, 23, 59)), isFalse);
    expect(SaturnAnniversary.isActive(DateTime(2026, 11, 19)), isFalse);
  });

  testWidgets('Premium cosmic day-18 theme renders in both sections',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: Column(children: [
        SaturnAnniversaryBanner(),
        SaturnAnniversaryBanner(compact: true),
      ]),
    )));
    expect(find.byKey(const Key('saturn-anniversary-home')), findsOneWidget);
    expect(find.byKey(const Key('saturn-anniversary-shared')), findsOneWidget);
    expect(find.text('Mais um capítulo na nossa órbita.'), findsOneWidget);
    expect(find.text('Feliz dia 18, meu amor.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
