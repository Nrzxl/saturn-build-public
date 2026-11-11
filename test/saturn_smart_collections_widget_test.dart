import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';

void main() {
  testWidgets('Favoritos inteligentes e criação de coleção preservam os dados',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1080);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const film = Work('tmdb:movie:8523', 'Meu filme favorito',
        'Filme', 'Aventura da minha coleção', 2026);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({film.id: film.toJson()}),
      'records': jsonEncode({
        '0:' + film.id: {
          'status': 'Concluído',
          'rating': 10,
          'notes': 'Nunca vou esquecer',
        },
      }),
      'saturn_favorite_ops_v1': jsonEncode({
        '0:' + film.id: {'present': true, 'updatedAt': 100},
      }),
      'watchlist_v1': jsonEncode({'0': [film.id], '1': []}),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saturn-smart-collection-shelf')),
        findsOneWidget);
    expect(find.byKey(const Key('saturn-smart-collection-favorites')),
        findsOneWidget);
    expect(find.byKey(const Key('saturn-smart-collection-watchlist')),
        findsOneWidget);
    await tester.tap(find.byKey(
      const Key('saturn-smart-collection-favorites')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('saturn-ranked-card-' + film.id)), findsOneWidget);

    await tester.tap(find.byKey(const Key('saturn-new-collection')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('saturn-new-collection-name')),
      'Histórias inesquecíveis');
    await tester.tap(find.byKey(
      const Key('saturn-create-collection-confirm')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final defs = jsonDecode(
      prefs.getString('saturn_collection_ops_v1')!) as Map;
    expect(defs, hasLength(1));
    expect((defs.values.first as Map)['name'],
      'Histórias inesquecíveis');
    final original = jsonDecode(
      prefs.getString('records')!) as Map;
    expect((original['0:' + film.id] as Map)['rating'], 10);

    // The original film remains saved even while a new empty collection
    // is selected. User data is never moved or rewritten by collections.
    final works = jsonDecode(
      prefs.getString('catalog_saved')!) as Map;
    expect(works.containsKey(film.id), isTrue);
  });
}
