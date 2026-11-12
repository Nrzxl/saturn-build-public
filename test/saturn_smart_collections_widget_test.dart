import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';

void main() {
  testWidgets('Coleção mantém o filtro ativo em um único menu compacto',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1080);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const film = Work('tmdb:movie:731', 'Um filme de teste',
        'Filme', 'Sinopse.', 2026);
    const book = Work('openlibrary:/books/OL731M', 'Um livro de teste',
        'Livro', 'Sinopse.', 2026);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        film.id: film.toJson(),
        book.id: book.toJson(),
      }),
      'records': jsonEncode({
        '0:' + film.id: {'status': 'Concluído'},
        '0:' + book.id: {'status': 'Em andamento'},
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();

    final filter = find.byKey(const Key('saturn-collection-filter-menu'));
    expect(filter, findsOneWidget);
    expect(find.text('Filtros: Tudo'), findsOneWidget);
    // Selection moved to Explorar; Coleção keeps its compact type filter.
    expect(find.text('Selecionar vários'), findsNothing);
    expect(find.byKey(Key('saturn-ranked-card-' + film.id)), findsOneWidget);
    expect(find.byKey(Key('saturn-ranked-card-' + book.id)), findsOneWidget);

    await tester.ensureVisible(filter);
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filmes').last);
    await tester.pumpAndSettle();
    expect(find.text('Filtros: Filmes'), findsOneWidget);
    expect(find.byKey(Key('saturn-ranked-card-' + film.id)), findsOneWidget);
    expect(find.byKey(Key('saturn-ranked-card-' + book.id)), findsNothing);
  });

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

  testWidgets('Sugestões mostra indicações reais sem alterar Em andamento',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1080);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const suggested = Work('tmdb:movie:90111', 'Título sugerido para nós',
        'Filme', 'Sinopse.', 2026);
    const ongoing = Work('tmdb:movie:90112', 'Título em andamento',
        'Filme', 'Sinopse.', 2026);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        suggested.id: suggested.toJson(),
        ongoing.id: ongoing.toJson(),
      }),
      'records': jsonEncode({
        '0:' + suggested.id: {'status': 'Em andamento'},
        '0:' + ongoing.id: {'status': 'Em andamento'},
      }),
      'saturn_ritual_ops_v1': jsonEncode({
        'suggestion:1:100': {
          'workId': suggested.id,
          'from': 1, 'to': 0,
          'status': 'pending', 'updatedAt': 100,
        },
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();

    final suggestions =
        find.byKey(const Key('saturn-smart-collection-suggestions'));
    expect(suggestions, findsOneWidget);
    await tester.ensureVisible(suggestions);
    await tester.tap(suggestions);
    await tester.pumpAndSettle();

    expect(find.byKey(Key('saturn-ranked-card-' + suggested.id)),
        findsOneWidget);
    expect(find.byKey(Key('saturn-ranked-card-' + ongoing.id)),
        findsNothing);

    final prefs = await SharedPreferences.getInstance();
    final persisted = jsonDecode(prefs.getString('records')!) as Map;
    expect((persisted['0:' + suggested.id] as Map)['status'],
        'Em andamento');
    expect((persisted['0:' + ongoing.id] as Map)['status'],
        'Em andamento');
  });
}
