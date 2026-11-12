import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/catalog_client.dart';
import 'package:saturn_app/main.dart';

void main() {
  testWidgets('Explorar shows only a clean check for saved titles and '
      'selects them in bulk without touching catalog-only titles',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const saved = Work('tmdb:movie:1011', 'Título já na coleção',
        'Filme', 'Um filme salvo.', 2026, tmdbScore: 8.1);
    const discover = Work('tmdb:movie:1012', 'Título não salvo',
        'Filme', 'Outro filme.', 2026, tmdbScore: 8.2);
    List<String> appliedIds = [];
    String appliedAction = '';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CatalogExplore(
        active: false,
        requestedFilter: CatalogFilter.all,
        initialResults: const [saved, discover],
        onOpen: (_) async {},
        onToggleShared: (_) {},
        isShared: (_) => false,
        onToggleWatchlist: (_) {},
        isWatchlisted: (_) => false,
        isInAnyCollection: (work) => work.id == saved.id,
        onToggleCompleted: (_) {},
        isCompleted: (_) => false,
        onBatchAction: (works, action) {
          appliedIds = works.map((w) => w.id).toList();
          appliedAction = action;
        },
      )),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(
      const Key('saturn-explore-saved-check-tmdb:movie:1011')),
      findsOneWidget);
    expect(find.byKey(
      const Key('saturn-explore-saved-check-tmdb:movie:1012')),
      findsNothing);
    final check = tester.widget<Icon>(find.byKey(
      const Key('saturn-explore-saved-check-tmdb:movie:1011')));
    expect(check.icon, Icons.check_rounded);
    expect(find.textContaining('Descobrir ·'), findsNothing);
    expect(find.byKey(
      const Key('saturn-explore-tmdb-score-tmdb:movie:1011')),
      findsOneWidget);

    final selectButton = find.byKey(
      const Key('saturn-explore-select-collected'));
    await tester.ensureVisible(selectButton);
    await tester.tap(selectButton);
    await tester.pumpAndSettle();

    final savedCover = find.byKey(
      const Key('saturn-cinematic-cover-tmdb:movie:1011'));
    await tester.ensureVisible(savedCover);
    await tester.tap(savedCover);
    await tester.pumpAndSettle();

    expect(find.text('1 selecionados'), findsOneWidget);
    expect(tester.widget<Icon>(find.byKey(
      const Key('saturn-explore-saved-check-tmdb:movie:1011'))).icon,
      Icons.check_box_rounded);

    final bulk = find.byKey(
      const Key('saturn-explore-batch-actions'));
    await tester.ensureVisible(bulk);
    await tester.tap(bulk);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar à Watchlist').last);
    await tester.pumpAndSettle();

    expect(appliedAction, 'watchlist');
    expect(appliedIds, [saved.id]);
    expect(find.text('1 selecionados'), findsNothing);
  });
}
