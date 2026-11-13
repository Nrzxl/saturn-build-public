import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';

void main() {
  final cases = <({Work work, String label})>[
    (work: const Work('tmdb:movie:101', 'O Filme', 'Filme',
        'Sinopse.', 2020, runtimeMinutes: 117), label: '117 MIN'),
    (work: const Work('tmdb:tv:202', 'A Série', 'Série',
        'Sinopse.', 2005, seasonCount: 12), label: '12 TEMPORADAS'),
    (work: const Work('googlebooks:abc123', 'Mangá volume 1', 'Livro',
        'Sinopse.', 2024, pageCount: 216), label: '216 PÁGINAS'),
  ];

  for (final testCase in cases) {
    testWidgets('Cinematic detail shows ${testCase.label} in top header',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 1440);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final work = testCase.work;
      SharedPreferences.setMockInitialValues({
        'catalog_saved': jsonEncode({work.id: work.toJson()}),
        'records': jsonEncode({
          '0:${work.id}': {'status': 'Concluído'},
        }),
      });
      await tester.pumpWidget(const SaturnApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coleção'));
      await tester.pumpAndSettle();
      final card = find.byKey(Key('saturn-ranked-card-${work.id}'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      final header = find.byKey(Key('saturn-detail-facts-${work.id}'));
      expect(header, findsOneWidget);
      expect(tester.widget<Text>(header).data, testCase.label);
      expect(find.text('FICHA DA HISTÓRIA'), findsNothing);
    });
  }

  testWidgets('Library covers stay identical height with and without review',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 1450);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const reviewed = Work('tmdb:movie:31', 'Um filme com bastante texto',
        'Filme', 'Sinopse.', 2015, runtimeMinutes: 135);
    const plain = Work('tmdb:movie:32', 'Outro filme',
        'Filme', 'Sinopse.', 2015, runtimeMinutes: 106);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        reviewed.id: reviewed.toJson(), plain.id: plain.toJson(),
      }),
      'records': jsonEncode({
        '0:${reviewed.id}': {'status': 'Concluído', 'rating': 9,
          'notes': 'Uma resenha que ocupa uma linha inteira. Muito bom!'},
        '0:${plain.id}': {'status': 'Concluído'},
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();
    final first = find.byKey(Key('saturn-ranked-cover-area-${reviewed.id}'));
    final second = find.byKey(Key('saturn-ranked-cover-area-${plain.id}'));
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    final sizeA = tester.getSize(first);
    final sizeB = tester.getSize(second);
    expect(sizeA.width, closeTo(sizeB.width, 0.01));
    expect(sizeA.height, closeTo(sizeB.height, 0.01));
    expect(sizeA.height / sizeA.width, closeTo(1.5, .01));
    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    final delegate = grid.gridDelegate
        as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.mainAxisExtent!, greaterThan(337));
    // The old card reserved 205 px after the artwork, leaving a large
    // empty strip beneath the controls. The new footer uses only the
    // exact fixed slots and ends immediately after the button row.
    expect(delegate.mainAxisExtent!, lessThan(sizeA.height + 190));

    final actionsA = find.byKey(Key('saturn-ranked-actions-${reviewed.id}'));
    final actionsB = find.byKey(Key('saturn-ranked-actions-${plain.id}'));
    final cardA = find.byKey(Key('saturn-ranked-card-${reviewed.id}'));
    final cardB = find.byKey(Key('saturn-ranked-card-${plain.id}'));
    expect(tester.getTopLeft(actionsA).dy,
        closeTo(tester.getTopLeft(actionsB).dy, 0.01));
    expect(tester.getBottomRight(cardA).dy -
        tester.getBottomRight(actionsA).dy, lessThan(25));
    expect(tester.getBottomRight(cardB).dy -
        tester.getBottomRight(actionsB).dy, lessThan(25));

    for (final work in [reviewed, plain]) {
      expect(tester.getSize(find.byKey(
          Key('saturn-ranked-title-slot-${work.id}'))).height, 36);
      expect(tester.getSize(find.byKey(
          Key('saturn-ranked-score-slot-${work.id}'))).height, 34);
      expect(tester.getSize(find.byKey(
          Key('saturn-ranked-technical-slot-${work.id}'))).height, 17);
      expect(tester.getSize(find.byKey(
          Key('saturn-ranked-review-slot-${work.id}'))).height, 29);
      expect(tester.getSize(find.byKey(
          Key('saturn-ranked-actions-${work.id}'))).height, 40);
    }
    expect(find.byKey(Key('saturn-ranked-completed-${reviewed.id}')),
        findsOneWidget);
    expect(find.byKey(Key('saturn-ranked-completed-${plain.id}')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
