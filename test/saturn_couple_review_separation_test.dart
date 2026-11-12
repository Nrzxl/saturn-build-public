import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_premium_details.dart';

void main() {
  testWidgets('Notas individuais ouro/prata mostram cores e nomes distintos',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: SaturnCoupleReview(
          selfName: 'Eu',
          otherName: 'Ela',
          self: {
            'rating': 9.0, 'notes': 'Minha resenha',
            'status': 'Concluído',
          },
          other: {
            'rating': 6.0, 'notes': 'A resenha dela',
            'status': 'Concluído',
          },
          cloudConnected: true,
        ),
      )),
    ));
    await tester.pumpAndSettle();
    final mine = find.byKey(const Key('saturn-couple-review-self'));
    final hers = find.byKey(const Key('saturn-couple-review-other'));
    expect(mine, findsOneWidget);
    expect(hers, findsOneWidget);
    expect(find.text('SUA NOTA'), findsOneWidget);
    expect(find.text('NOTA DA OUTRA PESSOA'), findsOneWidget);
    expect(find.text('Eu'), findsOneWidget);
    expect(find.text('Ela'), findsOneWidget);

    final myScore = tester.widget<Text>(
      find.byKey(const Key('saturn-review-self-score')));
    final herScore = tester.widget<Text>(
      find.byKey(const Key('saturn-review-partner-score')));
    expect(myScore.data, '4.5 ★');
    expect(herScore.data, '3.0 ★');
    expect(myScore.style!.color, const Color(0xFFE3BF70));
    expect(herScore.style!.color, const Color(0xFFBDC8D4));
    expect(find.textContaining('Minha resenha'), findsOneWidget);
    expect(find.textContaining('A resenha dela'), findsOneWidget);
  });

  testWidgets('Parceira sem avaliação não cria cartão de nota vazio',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SaturnCoupleReview(
        selfName: 'Eu',
        otherName: 'Ela',
        self: {'rating': 8.0, 'notes': 'Gostei'},
        other: {'notes': '', 'status': 'Quero conhecer'},
        cloudConnected: true,
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saturn-couple-review-self')),
        findsOneWidget);
    expect(find.byKey(const Key('saturn-couple-review-other')),
        findsNothing);
    expect(find.text('Sem nota'), findsNothing);
    expect(find.text('4.0 ★'), findsOneWidget);
  });

  testWidgets('Notas inexistentes não herdam cor ou valor do outro perfil',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SaturnCoupleReview(
        selfName: 'Eu',
        otherName: 'Ela',
        self: {},
        other: {'rating': 2.0, 'notes': ''},
        cloudConnected: false,
      )),
    ));
    await tester.pumpAndSettle();
    final myScore = tester.widget<Text>(
      find.byKey(const Key('saturn-review-self-score')));
    final herScore = tester.widget<Text>(
      find.byKey(const Key('saturn-review-partner-score')));
    expect(myScore.data, 'Sem nota');
    expect(herScore.data, '1.0 ★');
    expect(herScore.style!.color, const Color(0xFFC38A62));
  });
}
