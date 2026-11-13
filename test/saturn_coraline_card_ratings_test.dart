import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_card_couple_scores.dart';

void main() {
  const coraline = 'tmdb:movie:14836';

  testWidgets('Coraline: both real 5-star scores survive without sharedOps',
      (tester) async {
    // The actual SATURN data shape: both profiles independently saved ten
    // points (five stars). The title has not been added to Nossa Órbita.
    final records = <String, dynamic>{
      '0:$coraline': {
        'rating': 10, 'notes': 'Resenha pessoal',
        'status': 'Concluído',
      },
      '1:$coraline': {
        'rating': 10, 'notes': 'Resenha da parceira',
        'status': 'Quero conhecer',
      },
    };
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Center(child: SizedBox(width: 138, height: 34,
        child: SaturnCardCoupleScores(
          workId: coraline, records: records, viewerProfile: 0,
          profileNames: const ['Eu', 'Ela'],
        ),
      )),
    )));
    expect(find.byKey(const Key('saturn-library-person-0-$coraline')),
        findsOneWidget);
    expect(find.byKey(const Key('saturn-library-person-1-$coraline')),
        findsOneWidget);
    expect(find.text('Você'), findsOneWidget);
    expect(find.text('Ela'), findsOneWidget);
    expect(find.text('5.0 ★'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('One unrated profile never gets a fabricated score',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(width: 150, height: 34,
        child: SaturnCardCoupleScores(
          workId: coraline, viewerProfile: 0,
          profileNames: const ['Eu', 'Ela'],
          records: {
            '0:$coraline': {'notes': ''},
            '1:$coraline': {'rating': 8, 'notes': 'Gostei'},
          },
        ),
      ),
    )));
    expect(find.text('Ela 4.0 ★'), findsOneWidget);
    expect(find.textContaining('Você'), findsNothing);
    expect(find.textContaining('Sem nota'), findsNothing);
  });

  testWidgets('Desktop displays two score pills with individual colors',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(width: 300, height: 34,
        child: SaturnCardCoupleScores(
          workId: coraline, viewerProfile: 1,
          profileNames: const ['Eu', 'Ela'],
          records: {
            '0:$coraline': {'rating': 8},
            '1:$coraline': {'rating': 10},
          },
        ),
      ),
    )));
    expect(find.text('Eu 4.0 ★'), findsOneWidget);
    expect(find.text('Você 5.0 ★'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('No rating results in no score widget',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SizedBox(width: 150, height: 34,
        child: SaturnCardCoupleScores(
          workId: coraline, viewerProfile: 0,
          profileNames: ['Eu', 'Ela'], records: {},
        ),
      ),
    )));
    expect(find.textContaining('★'), findsNothing);
    expect(find.textContaining('Sem nota'), findsNothing);
  });
}
