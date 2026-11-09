import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_star_rating.dart';

void main() {
  test('Notas antigas continuam em 0-10 sem perda de precisão', () {
    expect(starsFromLegacy(8.5), 4.25);
    expect(starsFromLegacy(null), 0);
    expect(legacyFromStars(4.5), 9);
    expect(legacyFromStars(0.5), 1);
    expect(starsFromLegacy(20), 5);
  });

  testWidgets('Zero estrelas explícito não é confundido com sem nota',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SaturnStarRating(stars: 0, zeroIsRating: true),
    )));
    expect(find.text('0.0 / 5'), findsOneWidget);
    expect(find.text('Sem nota'), findsNothing);
  });

  testWidgets('Cinco estrelas permitem tocar em meia estrela', (tester) async {
    double result = -1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SaturnStarRating(
          stars: 0,
          onChanged: (rating) => result = rating,
          showValue: false,
        ),
      ),
    ));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));
    final first = find.byIcon(Icons.star_outline_rounded).first;
    final position = tester.getTopLeft(first);
    await tester.tapAt(position + const Offset(5, 15));
    expect(result, 0.5);
    final last = find.byIcon(Icons.star_outline_rounded).last;
    final p = tester.getTopLeft(last);
    await tester.tapAt(p + const Offset(29, 15));
    expect(result, 5);
  });
}
