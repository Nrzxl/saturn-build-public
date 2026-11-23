import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_anniversary.dart';
import 'package:saturn_app/saturn_metallic_halo.dart';

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
    // The day-18 effect must finish; infinite tickers break the full app UI tests.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.byKey(const Key('saturn-anniversary-home')), findsOneWidget);
    expect(find.byKey(const Key('saturn-anniversary-shared')), findsOneWidget);
    expect(find.text('Mais um capítulo na nossa órbita.'), findsOneWidget);
    expect(find.text('Feliz aniversário, meu amor.'), findsOneWidget);
    expect(find.text('ANIVERSÁRIO  ·  A NOSSA CONSTELAÇÃO'),
        findsOneWidget);
    expect(find.text('DIA 18  ·  A NOSSA CONSTELAÇÃO'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  
  testWidgets('Accessibility reduced motion remains static and settles',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MediaQuery(
      data: MediaQueryData(disableAnimations: true, reduceMotion: true),
      child: Scaffold(body: Center(
        child: SaturnAnniversaryBanner(compact: true),
      )),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Feliz aniversário, meu amor.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Relationship duration uses completed calendar months', () {
    expect(SaturnAnniversary.completedMonths(DateTime(2025, 1, 17)), 0);
    expect(SaturnAnniversary.relationshipDuration(DateTime(2025, 1, 18)),
        '0 meses');
    expect(SaturnAnniversary.relationshipDuration(DateTime(2025, 2, 17)),
        '0 meses');
    expect(SaturnAnniversary.relationshipDuration(DateTime(2025, 2, 18)),
        '1 mês');
    expect(SaturnAnniversary.relationshipDuration(DateTime(2026, 1, 18)),
        '1 ano');
    expect(SaturnAnniversary.relationshipDuration(DateTime(2026, 11, 17)),
        '1 ano e 9 meses');
    expect(SaturnAnniversary.relationshipDuration(DateTime(2026, 11, 18)),
        '1 ano e 10 meses');
    expect(SaturnAnniversary.relationshipDuration(DateTime(2027, 1, 18)),
        '2 anos');
  });

  test('Only authored, rated and watched film memories glow on day 18', () {
    final now = DateTime(2026, 11, 18);
    final watched = <String, dynamic>{
      'status': 'Concluído', 'rating': 8, 'notes': 'Nosso filme!',
      'completedOn': '2026-11-18',
    };
    bool eligible(DateTime date, String kind, Object? mine,
        [Object? partner]) => SaturnAnniversary.isMemoryFilm(
          localDate: date, kind: kind, mine: mine, partner: partner);
    expect(eligible(now, 'Filme', watched), isTrue);
    // Bug regression: older watched/rated/commented movies must NOT turn blue.
    expect(eligible(now, 'Filme', {
      'status': 'Concluído', 'rating': 8, 'notes': 'Comentário antigo',
      'updatedAt': DateTime(2026, 11, 18).millisecondsSinceEpoch,
    }), isFalse);
    expect(eligible(now, 'Filme', {
      'status': 'Concluído', 'rating': 9, 'notes': 'Outra data',
      'completedOn': '2026-11-17',
    }), isFalse);
    expect(eligible(DateTime(2026, 12, 18), 'Filme', watched), isFalse);
    expect(eligible(DateTime(2026, 11, 23), 'Filme', watched), isFalse);
    expect(eligible(now, 'Filme', null, watched), isTrue);
    expect(eligible(now, 'Filme', {
      'status': 'Assistido', 'rating': 0, 'notes': 'Não gostei!',
      'completedOn': '2026-11-18',
    }), isTrue);
    expect(eligible(now, 'Filme', {
      'status': 'Visto', 'rating': 10, 'notes': 'Favorito',
      'completedOn': '2026-11-18',
    }), isTrue);
    expect(eligible(DateTime(2026, 11, 17), 'Filme', watched), isFalse);
    expect(eligible(DateTime(2026, 11, 19), 'Filme', watched), isFalse);
    expect(eligible(now, 'Série', watched), isFalse);
    expect(eligible(now, 'Anime', watched), isFalse);
    expect(eligible(now, 'Livro', watched), isFalse);
    expect(eligible(now, 'Filme', {
      'status': 'Em andamento', 'rating': 8, 'notes': 'Quero ver',
    }), isFalse);
    expect(eligible(now, 'Filme', {
      'status': 'Concluído', 'rating': 8, 'notes': '  ',
    }), isFalse);
    expect(eligible(now, 'Filme', {
      'status': 'Concluído', 'notes': 'Uma resenha',
    }), isFalse);
    expect(eligible(now, 'Filme', {
      'status': 'Concluído', 'rating': 14, 'notes': 'Inválida',
    }), isFalse);
    // No mixing a watched-only record with the partner's unrated review.
    expect(eligible(now, 'Filme',
      {'status': 'Concluído', 'rating': 7},
      {'status': 'Em andamento', 'rating': 7, 'notes': 'Nota escrita'}),
      isFalse);
    // An imported synopsis is not an authored review.
    expect(eligible(now, 'Filme', {
      'status': 'Concluído', 'rating': 9,
      'description': 'Sinopse vinda do TMDB',
    }), isFalse);
  });

  testWidgets('The couple timeline is visible even outside the anniversary',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: Center(child: SaturnRelationshipTime()),
    )));
    expect(find.byKey(const Key('saturn-relationship-time')), findsOneWidget);
    expect(find.text('Desde 18 de janeiro de 2025'), findsOneWidget);
    expect(find.textContaining('juntos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Only eligible posters paint the cosmic purple-blue aura',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: Column(children: [
        SaturnAnniversaryAura(active: true, child: SizedBox(width: 40,
          height: 60)),
        SaturnAnniversaryAura(active: false, child: SizedBox(width: 40,
          height: 60)),
        SaturnMetallicHalo(
          color: Color(0xFFE3BF70),
          anniversaryMemory: true,
          child: SizedBox(width: 50, height: 70),
        ),
      ]),
    )));
    expect(find.byKey(const Key('saturn-anniversary-memory-aura')),
        findsOneWidget);
    final animated = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer));
    final decorations = animated.map((w) => w.decoration)
        .whereType<BoxDecoration>().toList();
    expect(decorations.any((d) => (d.boxShadow?.length ?? 0) >= 3),
        isTrue);
    expect(tester.takeException(), isNull);
  });

  test('CompletedOn is only assigned when status really becomes watched', () {
    final day18 = DateTime(2026, 11, 18);
    final day19 = DateTime(2026, 11, 19);
    expect(SaturnAnniversary.calendarDay(day18), '2026-11-18');
    expect(SaturnAnniversary.completedOnAfter(
      previous: {}, nextStatus: 'Concluído', localNow: day18,
    ), '2026-11-18');
    expect(SaturnAnniversary.completedOnAfter(
      previous: {'status': 'Em andamento'}, nextStatus: 'Assistido',
      localNow: day18,
    ), '2026-11-18');
    // Reviewing an old completed title is not a new "watched" event.
    expect(SaturnAnniversary.completedOnAfter(
      previous: {'status': 'Concluído', 'updatedAt': 123456789},
      nextStatus: 'Concluído', localNow: day18,
    ), isNull);
    // Later edits preserve the ORIGINAL completion date.
    expect(SaturnAnniversary.completedOnAfter(
      previous: {'status': 'Concluído', 'completedOn': '2026-11-18'},
      nextStatus: 'Concluído', localNow: day19,
    ), '2026-11-18');
    // Unwatching resets the date; marking watched again gets a new date.
    expect(SaturnAnniversary.completedOnAfter(
      previous: {'status': 'Concluído', 'completedOn': '2026-11-18'},
      nextStatus: 'Em andamento', localNow: day19,
    ), isNull);
    expect(SaturnAnniversary.completedOnAfter(
      previous: {'status': 'Em andamento', 'completedOn': null},
      nextStatus: 'Concluído', localNow: day19,
    ), '2026-11-19');
  });

}
