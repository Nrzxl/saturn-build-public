import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';
import 'package:saturn_app/saturn_metallic_halo.dart';

void main() {
  testWidgets('A Watchlist e a estante viram prateleiras horizontais completas',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1024);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final films = [
      for (var i = 0; i < 9; i++)
        Work('tmdb:movie:' + (20001 + i).toString(),
          'Filme da minha lista ' + i.toString(), 'Filme',
          'Sinopse de teste.', 2026, provider: 'TMDB'),
    ];
    final book = Work('openlibrary:/books/OL222M',
      'Volume da minha estante', 'Livro',
      'Descrição editorial.', 2020, provider: 'Open Library');
    final all = [...films, book];
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        for (final work in all) work.id: work.toJson(),
      }),
      'watchlist_v1': jsonEncode({
        '0': [for (final work in all) work.id],
        '1': [],
      }),
      'records': jsonEncode({
        '0:' + book.id: {
          'status': 'Em andamento', 'notes': 'Minha leitura',
        },
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    final rail = find.byKey(const Key('saturn-home-watchlist-shelf'));
    await tester.scrollUntilVisible(rail, 220,
      scrollable: find.byType(Scrollable).first, maxScrolls: 15);
    final railWidget = tester.widget<ListView>(rail);
    expect(railWidget.scrollDirection, Axis.horizontal);
    // ListView.separated adds one separator between each of the 9 covers.
    expect(railWidget.childrenDelegate.estimatedChildCount, 17);

    final books = find.byKey(const Key('saturn-home-bookshelf-shelf'));
    await tester.scrollUntilVisible(books, 270,
      scrollable: find.byType(Scrollable).first, maxScrolls: 18);
    expect(tester.widget<ListView>(books).scrollDirection, Axis.horizontal);
    expect(find.text('Livros • Minha estante'), findsOneWidget);
  });

  testWidgets('Ouro, prata e bronze só brilham com nota e resenha pessoal',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gold = Work('tmdb:movie:9001', 'Filme Ouro',
        'Filme', 'Sinopse.', 2026, provider: 'TMDB');
    final silver = Work('tmdb:movie:9002', 'Filme Prata',
        'Filme', 'Sinopse.', 2025, provider: 'TMDB');
    final bronze = Work('tmdb:movie:9003', 'Filme Bronze',
        'Filme', 'Sinopse.', 2024, provider: 'TMDB');
    final withoutReview = Work('tmdb:movie:9004', 'Filme sem resenha',
        'Filme', 'Sinopse importada do catálogo.', 2023,
        provider: 'TMDB');
    final works = [gold, silver, bronze, withoutReview];

    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        for (final item in works) item.id: item.toJson(),
      }),
      'records': jsonEncode({
        '0:' + gold.id: {'status': 'Concluído', 'rating': 9.0,
          'notes': 'Maravilhoso, vou rever!'},
        '0:' + silver.id: {'status': 'Concluído', 'rating': 6.0,
          'notes': 'Gostei de algumas partes.'},
        '0:' + bronze.id: {'status': 'Concluído', 'rating': 2.0,
          'notes': 'Poderia ser melhor.'},
        '0:' + withoutReview.id: {'status': 'Concluído', 'rating': 10.0,
          'notes': '   '},
      }),
      'shared': '[]',
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('saturn-review-halo-' + gold.id)), findsOneWidget);
    expect(find.byKey(Key('saturn-review-halo-' + silver.id)), findsOneWidget);
    expect(find.byKey(Key('saturn-review-halo-' + bronze.id)), findsOneWidget);
    expect(find.byKey(Key('saturn-review-halo-' + withoutReview.id)),
      findsNothing);
    // One seamless grid, sorted gold -> silver -> bronze -> unreviewed,
    // without status headings, badges, or tier names rendered as text.
    expect(find.byKey(Key('saturn-ranked-gallery-' + gold.id)),
        findsOneWidget);
    expect(find.text('SEM CLASSIFICAÇÃO · SEM HALO'), findsNothing);
    expect(find.text('BRONZE'), findsNothing);
    expect(find.text('PRATA'), findsNothing);
    expect(find.text('OURO'), findsNothing);
    // Review text accompanies glowing cards; imported synopsis alone does not.
    expect(find.textContaining('Maravilhoso, vou rever!'), findsWidgets);
    expect(find.byType(GridView), findsWidgets);
  });

  testWidgets('Coleção usa grade de duas capas mesmo em celular',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final film = Work('tmdb:movie:93001', 'Filme no celular',
        'Filme', 'Sinopse importada.', 2026, provider: 'TMDB');
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({film.id: film.toJson()}),
      'records': jsonEncode({
        '0:' + film.id: {'status': 'Concluído', 'rating': 8.0,
          'notes': 'Minha crítica do filme.'},
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();
    final grid = find.byKey(Key('saturn-ranked-gallery-' + film.id));
    final scroller = find.descendant(
      of: find.byKey(const PageStorageKey('saturn_personal_collection')),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(grid, 240,
      scrollable: scroller, maxScrolls: 20);
    await tester.pumpAndSettle();
    expect(grid, findsOneWidget);
    final delegate = tester.widget<GridView>(grid).gridDelegate
      as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(find.byKey(Key('saturn-review-halo-' + film.id)), findsOneWidget);
  });
  testWidgets('Nossa Órbita divide ouro e prata por perfil no mesmo poster',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1150);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const film = Work('tmdb:movie:99901', 'Filme em comum',
        'Filme', 'Uma história que vimos juntos.', 2026);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({film.id: film.toJson()}),
      'records': jsonEncode({
        '0:' + film.id: {
          'status': 'Concluído', 'rating': 9.0, 'notes': '',
        },
        '1:' + film.id: {
          'status': 'Concluído', 'rating': 6.0, 'notes': '',
        },
      }),
      'shared': jsonEncode([film.id]),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();
    final halo = tester.widget<SaturnMetallicHalo>(
      find.byKey(Key('saturn-review-halo-' + film.id)));
    expect(halo.color, const Color(0xFFE3BF70));
    expect(halo.partnerColor, const Color(0xFFBDC8D4));
  });

}
