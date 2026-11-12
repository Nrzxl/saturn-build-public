import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_personal_score.dart';

void main() {
  testWidgets('Legacy stored ratings render as the unified five-star score',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body:
      SaturnPersonalScore(name: 'Você',
        record: {'rating': 9.0, 'notes': 'Adorei'}))));
    expect(find.text('Você 4.5 ★'), findsOneWidget);
  });

  testWidgets('Unrated partner produces no pill or fake placeholder',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Column(
      children: [
        SaturnPersonalScore(name: 'Você', record: {'rating': 10.0}),
        SaturnPersonalScore(name: 'Ela', record: {'notes': ''}),
      ],
    ))));
    expect(find.text('Você 5.0 ★'), findsOneWidget);
    expect(find.textContaining('Ela'), findsNothing);
    expect(find.textContaining('Sem nota'), findsNothing);
  });
}
