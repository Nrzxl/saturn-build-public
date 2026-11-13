import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_card_couple_scores.dart';
import 'package:saturn_app/saturn_personal_score.dart';

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
    // Restore the approved The Office styling: two bordered gold badges
    // side by side even in a narrow poster; never vertically stacked.
    final horizontal = find.byKey(
        const Key('saturn-horizontal-scores-$coraline'));
    expect(horizontal, findsOneWidget);
    expect(find.descendant(
        of: horizontal, matching: find.byType(SaturnPersonalScore)),
        findsNWidgets(2));
    final row = tester.widget<Row>(horizontal);
    expect(row.mainAxisSize, MainAxisSize.min);
    expect(find.text('Você 5.0 ★'), findsOneWidget);
    expect(find.text('Ela 5.0 ★'), findsOneWidget);
    expect(find.textContaining('5.0 ★'), findsNWidgets(2));
    for (final chip in tester.widgetList<SaturnPersonalScore>(
        find.descendant(
          of: horizontal, matching: find.byType(SaturnPersonalScore)))) {
      expect(chip.record, isNotNull);
    }
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

  testWidgets('Badge border and star follow gold, silver and bronze tiers',
      (tester) async {
    for (final row in [
      (rating: 10.0, color: const Color(0xFFE3BF70)),
      (rating: 6.0, color: const Color(0xFFBDC8D4)),
      (rating: 2.0, color: const Color(0xFFC38A62)),
    ]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: SizedBox(width: 140, height: 34,
          child: SaturnCardCoupleScores(
            workId: coraline, viewerProfile: 0,
            profileNames: const ['Eu', 'Ela'],
            records: {
              '0:$coraline': {'rating': row.rating},
              '1:$coraline': {'rating': row.rating},
            },
          ),
        ),
      )));
      final badge = find.byKey(Key('saturn-library-person-0-$coraline'));
      expect(badge, findsOneWidget);
      final label = tester.widget<Text>(
        find.descendant(of: badge, matching: find.byType(Text)));
      expect(label.style!.color, row.color);
      final box = tester.widget<Container>(
        find.descendant(of: badge, matching: find.byType(Container)).first);
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.border!.top.color,
          row.color.withValues(alpha: .68));
      expect(tester.takeException(), isNull);
    }
  });
}
