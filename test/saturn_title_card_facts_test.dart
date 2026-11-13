import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';
import 'package:saturn_app/catalog_client.dart';

void main() {
  testWidgets('Old saved film and series show verified metadata without '
      'rewriting personal records', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1120, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const movie = Work('tmdb:movie:8999', 'Filme antigo',
        'Filme', 'Uma história real.', 2018);
    const show = Work('tmdb:tv:9777', 'Série antiga',
        'Série', 'Uma série real.', 2020);
    final personal = {
      '0:tmdb:movie:8999': {'rating': 10, 'notes': 'Ainda lembro desta história.',
        'status': 'Concluído'},
      '0:tmdb:tv:9777': {'status': 'Em andamento'},
    };
    final now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        movie.id: movie.toJson(), show.id: show.toJson(),
      }),
      'records': jsonEncode(personal),
      'saturn_technical_v1': jsonEncode({
        'schema': 1, 'country': 'BR',
        'values': {movie.id: [111, 0], show.id: [0, 3]},
      }),
      'saturn_technical_checked_at_v1': now,
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('saturn-ranked-technical-' + movie.id)),
        findsOneWidget);
    expect(find.text('111 min'), findsWidgets);
    expect(find.textContaining('3 temporadas'), findsWidgets);

    final prefs = await SharedPreferences.getInstance();
    final unchanged = jsonDecode(prefs.getString('records')!) as Map;
    expect(unchanged, personal);
    final catalog = jsonDecode(prefs.getString('catalog_saved')!) as Map;
    expect(catalog[movie.id]['runtimeMinutes'], isNull);
    expect(catalog[show.id]['seasonCount'], isNull);
  });

  testWidgets('Explore card uses one shared technical lookup for metadata',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1300);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const movie = Work('tmdb:movie:81', 'Filme do catálogo',
        'Filme', 'Sinopse.', 2026);
    const show = Work('tmdb:tv:82', 'Série do catálogo',
        'Série', 'Sinopse.', 2026);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CatalogExplore(
      active: false,
      requestedFilter: CatalogFilter.all,
      initialResults: const [movie, show],
      onOpen: (_) async {},
      onToggleShared: (_) {},
      isShared: (_) => false,
      onToggleWatchlist: (_) {},
      isWatchlisted: (_) => false,
      isInAnyCollection: (_) => false,
      onAddToCollections: (_) async => false,
      onToggleCompleted: (_) {},
      isCompleted: (_) => false,
      technicalLabel: (w) => w.id == movie.id
          ? '102 min' : '2 temporadas',
    ))));
    await tester.pumpAndSettle();

    expect(find.textContaining('102 min'), findsWidgets);
    expect(find.textContaining('2 temporadas'), findsWidgets);
  });
}
