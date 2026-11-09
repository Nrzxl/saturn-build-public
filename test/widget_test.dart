import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';

void main() {

  testWidgets('Filtros das coleções não alteram notas ou lista do casal',
      (tester) async {
    final film = Work('tmdb:movie:891', 'Filme em Conjunto',
        'Filme', 'Uma história do casal.', 2024, provider: 'TMDB');
    final book = Work('openlibrary:/works/OL345W', 'Livro em Conjunto',
        'Livro', 'Uma leitura do casal.', 2018, provider: 'Open Library');
    SharedPreferences.setMockInitialValues({
      'records': jsonEncode({
        '0:${film.id}': {
          'status': 'Concluído', 'rating': 9.0,
          'notes': 'Nossa memória favorita',
        },
        '0:${book.id}': {
          'status': 'Em andamento', 'rating': 8.0,
          'notes': 'Não perder esta resenha',
        },
      }),
      'catalog_saved': jsonEncode({
        film.id: film.toJson(), book.id: book.toJson(),
      }),
      'shared': jsonEncode([film.id, book.id]),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();
    expect(find.text('Filme em Conjunto'), findsOneWidget);
    expect(find.text('Livro em Conjunto'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('saturn-collection-filter-Livros')));
    await tester.pumpAndSettle();
    expect(find.text('Livro em Conjunto'), findsOneWidget);
    expect(find.text('Filme em Conjunto'), findsNothing);

    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    expect(find.text('Filme em Conjunto'), findsOneWidget);
    expect(find.text('Livro em Conjunto'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saturn-shared-filter-Filmes')));
    await tester.pumpAndSettle();
    expect(find.text('Filme em Conjunto'), findsOneWidget);
    expect(find.text('Livro em Conjunto'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    final records = jsonDecode(prefs.getString('records')!) as Map;
    expect((records['0:${book.id}'] as Map)['notes'],
      'Não perder esta resenha');
    expect(jsonDecode(prefs.getString('shared')!),
      containsAll([film.id, book.id]));
  });

  testWidgets('Home preserva entrada de descoberta em vitrine cinematográfica',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    expect(find.text('EVERY STORY HAS ITS ORBIT'), findsOneWidget);
    expect(find.text('Descobrir histórias'), findsOneWidget);
    expect(find.text('Minha Watchlist'), findsOneWidget);
  });

  testWidgets('Web desktop usa navegação lateral sem barra inferior',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    expect(find.text('Filtros: tipos, gêneros e streaming'), findsOneWidget);
  });

  testWidgets('Obra salva abre ficha com capa e streamings', (tester) async {
    final saved = Work(
      'anilist:30',
      'Anime da Nossa Órbita',
      'Anime',
      'Um anime para assistir juntos.',
      2002,
      provider: 'AniList',
      streamingLinks: const {
        'crunchyroll':
            'https://www.crunchyroll.com/series/G12345/exemplo',
      },
    );
    SharedPreferences.setMockInitialValues({
      'records': jsonEncode({
        '0:anilist:30': {
          'status': 'Em andamento',
          'rating': 8.5,
          'notes': 'Uma história especial',
        },
      }),
      'catalog_saved': jsonEncode({saved.id: saved.toJson()}),
      'shared': '[]',
      'streaming_services': ['netflix', 'crunchyroll', 'primeVideo'],
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();
    expect(find.text('Anime da Nossa Órbita'), findsOneWidget);

    await tester.tap(find.text('Anime da Nossa Órbita'));
    await tester.pumpAndSettle();
    expect(find.text('ONDE ASSISTIR · BRASIL'), findsOneWidget);
    expect(find.text('Crunchyroll'), findsWidgets);
    expect(find.text('Link específico fornecido pela fonte'), findsOneWidget);
    expect(find.text('Disponibilidade não confirmada'), findsWidgets);
    expect(find.text('Uma história especial'), findsOneWidget);
  });

  testWidgets('Livro em Quero ler vira Lido sem apagar resenha', (tester) async {
    final book = Work(
      'openlibrary:/works/OL12W',
      'Livro para Teste',
      'Livro',
      'Uma leitura para a estante.',
      2010,
      provider: 'Open Library',
    );
    SharedPreferences.setMockInitialValues({
      'records': jsonEncode({
        '0:openlibrary:/works/OL12W': {
          'status': 'Quero conhecer',
          'rating': 8.5,
          'notes': 'Uma resenha que deve permanecer',
        },
      }),
      'catalog_saved': jsonEncode({book.id: book.toJson()}),
      'shared': '[]',
      'watchlist_v1': jsonEncode({'0': [book.id], '1': []}),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Livros • Minha estante'), 350,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    expect(find.text('Livros • Minha estante'), findsOneWidget);
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Livro para Teste').first);
    await tester.pumpAndSettle();
    expect(find.text('MINHAS ESTRELAS'), findsOneWidget);
    expect(find.text('Quero ler ✓'), findsOneWidget);
    expect(find.text('Marcar como lido'), findsOneWidget);
    expect(find.text('Compartilhar avaliação no Instagram'), findsOneWidget);

    await tester.ensureVisible(find.text('Marcar como lido'));
    await tester.tap(find.text('Marcar como lido'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('records')!) as Map;
    final current = saved['0:openlibrary:/works/OL12W'] as Map;
    expect(current['status'], 'Concluído');
    expect(current['rating'], 8.5);
    expect(current['notes'], 'Uma resenha que deve permanecer');
    final savedLists = jsonDecode(prefs.getString('watchlist_v1')!) as Map;
    expect(savedLists['0'], isEmpty);
  });

  testWidgets('Coleção: seleção em massa arquiva sem apagar a resenha',
      (tester) async {
    final film = Work(
      'tmdb:movie:550', 'Filme da Minha Coleção', 'Filme',
      'Uma história de teste.', 1999, provider: 'TMDB',
    );
    SharedPreferences.setMockInitialValues({
      'records': jsonEncode({
        '0:tmdb:movie:550': {
          'status': 'Concluído', 'rating': 9.0,
          'notes': 'Não podemos perder este comentário!',
        },
      }),
      'catalog_saved': jsonEncode({film.id: film.toJson()}),
      'shared': '[]',
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();
    expect(find.text('Filme da Minha Coleção'), findsOneWidget);

    await tester.tap(find.text('Selecionar vários'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ações em massa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover da minha coleção').last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final archived = prefs.getStringList('saturn_archived_v1') ?? [];
    expect(archived, contains('0:tmdb:movie:550'));
    final saved = jsonDecode(prefs.getString('records')!) as Map;
    expect((saved['0:tmdb:movie:550'] as Map)['notes'],
      'Não podemos perder este comentário!');
    expect(find.text('Filme da Minha Coleção'), findsNothing);
  });

  testWidgets('A outra pessoa tem nota e comentário na ficha',
      (tester) async {
    final film = Work(
      'tmdb:movie:777', 'Nossa Série', 'Série',
      'Sinopse de nossa série.', 2025, provider: 'TMDB',
      externalRatings: const {
        'imdb': '8.4/10', 'rottenTomatoes': '92%',
        'metacritic': '79/100',
      },
    );
    SharedPreferences.setMockInitialValues({
      'records': jsonEncode({
        '0:tmdb:movie:777': {
          'status': 'Em andamento', 'rating': 8.0,
          'notes': 'Gostei da fotografia!',
        },
        '1:tmdb:movie:777': {
          'status': 'Concluído', 'rating': 9.0,
          'notes': 'Eu amei a história!',
        },
      }),
      'catalog_saved': jsonEncode({film.id: film.toJson()}),
      'shared': '[]',
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nossa Série'));
    await tester.pumpAndSettle();
    expect(find.text('O QUE NÓS ACHAMOS'), findsOneWidget);
    expect(find.textContaining('Eu amei a história!'), findsWidgets);
    expect(find.text('8.4/10'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('79/100'), findsOneWidget);
  });

  testWidgets('Catálogo apresenta filtro único e modal por tipo/gênero',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    expect(find.text('Filtros: tipos, gêneros e streaming'), findsOneWidget);
    await tester.tap(find.text('Filtros: tipos, gêneros e streaming'));
    await tester.pumpAndSettle();
    expect(find.text('TIPO DE HISTÓRIA'), findsOneWidget);
    expect(find.text('STREAMING NO BRASIL'), findsOneWidget);
    await tester.tap(find.text('Livros').last);
    await tester.pumpAndSettle();
    expect(find.text('GÊNERO LITERÁRIO'), findsOneWidget);
  });

  testWidgets('SATURN inicializa com navegação', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();

    expect(find.text('SATURN'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Coleção'), findsOneWidget);
    expect(find.text('Nós dois'), findsOneWidget);
    expect(find.byTooltip('Atualizar SATURN'), findsOneWidget);
    expect(find.text('Nossos streamings'), findsNothing);
    expect(find.text('Minha Watchlist'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Livros • Minha estante'), 350,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    expect(find.text('Livros • Minha estante'), findsOneWidget);
  });
}
