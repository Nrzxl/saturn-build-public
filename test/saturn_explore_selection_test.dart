import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/catalog_client.dart';
import 'package:saturn_app/main.dart';

void main() {
  testWidgets('Explorar selects unsaved catalog titles and chooses a collection',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const saved = Work('tmdb:movie:1011', 'Título já na coleção',
        'Filme', 'Um filme salvo.', 2026, tmdbScore: 8.1);
    const discover = Work('tmdb:movie:1012', 'Título ainda não salvo',
        'Filme', 'Outro filme.', 2026, tmdbScore: 8.2);
    List<String> additions = [];

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
        onAddToCollections: (works) async {
          additions = works.map((w) => w.id).toList(growable: false);
          return true;
        },
      )),
    ));
    await tester.pumpAndSettle();

    final savedCheck = find.byKey(
      const Key('saturn-explore-saved-check-tmdb:movie:1011'));
    final newCheck = find.byKey(
      const Key('saturn-explore-saved-check-tmdb:movie:1012'));
    expect(savedCheck, findsOneWidget);
    expect(newCheck, findsNothing);
    expect(tester.widget<Icon>(savedCheck).icon, Icons.check_rounded);
    expect(find.textContaining('Descobrir ·'), findsNothing);
    expect(find.byKey(
      const Key('saturn-explore-tmdb-score-tmdb:movie:1011')),
      findsOneWidget);

    final selector = find.byKey(
      const Key('saturn-explore-select-to-collection'));
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();

    // The shortcut must select the unsaved title, not the already-saved one.
    final selectUnsaved = find.byKey(
      const Key('saturn-explore-select-unsaved'));
    await tester.tap(selectUnsaved);
    await tester.pumpAndSettle();
    expect(find.text('1 selecionados'), findsOneWidget);
    expect(tester.widget<Icon>(newCheck).icon, Icons.check_box_rounded);
    expect(tester.widget<Icon>(savedCheck).icon, Icons.check_rounded);

    final add = find.byKey(
      const Key('saturn-explore-add-to-collections'));
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(additions, [discover.id]);
    expect(find.text('1 selecionados'), findsNothing);
  });
}
