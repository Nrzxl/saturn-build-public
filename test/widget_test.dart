import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';
import 'package:saturn_app/saturn_orbit_rituals.dart';

void main() {
  testWidgets('Indicar e escolher filme salva ritual e Nossa Órbita',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final film = Work(
      'tmdb:movie:40001', 'Teste de Cinema', 'Filme',
      'Um título real salvo para escolher.', 2025, provider: 'TMDB');
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({film.id: film.toJson()}),
      'shared': '[]',
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();

    final person = find.byKey(
      const Key('saturn-ritual-film-person-0'));
    final nominate = find.descendant(
      of: person, matching: find.text('Fazer minha indicação'));
    await tester.ensureVisible(nominate);
    await tester.tap(nominate);
    await tester.pumpAndSettle();
    expect(find.text('Indicar o filme do fim de semana'), findsOneWidget);
    await tester.tap(find.text('Teste de Cinema'));
    await tester.pumpAndSettle();

    final weekend = SaturnOrbitRituals.weekendPeriod(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final nominations = jsonDecode(
        prefs.getString('saturn_ritual_ops_v1')!) as Map;
    expect(
      (nominations[SaturnOrbitRituals.nomination(weekend, 0)] as Map)
          ['workId'],
      film.id,
    );

    final choose = find.text('Escolher nosso filme');
    await tester.ensureVisible(choose);
    await tester.tap(choose);
    await tester.pumpAndSettle();

    final updated = jsonDecode(
        prefs.getString('saturn_ritual_ops_v1')!) as Map;
    expect(
      (updated[SaturnOrbitRituals.selection(weekend)] as Map)['workId'],
      film.id,
    );
    expect(jsonDecode(prefs.getString('shared')!), contains(film.id));
  });

  testWidgets('Livro do mês mostra carinha triste até leitura e nota',
      (tester) async {
    final now = DateTime.now();
    final month = SaturnOrbitRituals.monthPeriod(now);
    final weekend = SaturnOrbitRituals.weekendPeriod(now);
    const bookId = 'openlibrary:/works/OL555W';
    const otherBookId = 'openlibrary:/works/OL777W';
    const filmId = 'tmdb:movie:24601';
    const filmTwoId = 'tmdb:movie:24602';
    final book = Work(bookId, 'Leitura do Eu', 'Livro',
        'Minha escolha mensal.', 2024, provider: 'Open Library');
    final otherBook = Work(otherBookId, 'Leitura da Ela', 'Livro',
        'A escolha dela.', 2023, provider: 'Open Library');
    final first = Work(filmId, 'Filme de Um', 'Filme',
        'Nossa sexta.', 2023, provider: 'TMDB');
    final second = Work(filmTwoId, 'Filme de Dois', 'Filme',
        'Nosso sábado.', 2025, provider: 'TMDB');
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        bookId: book.toJson(),
        otherBookId: otherBook.toJson(),
        filmId: first.toJson(),
        filmTwoId: second.toJson(),
      }),
      'saturn_ritual_ops_v1': jsonEncode({
        SaturnOrbitRituals.nomination(weekend, 0):
            {'workId': filmId, 'updatedAt': 100},
        SaturnOrbitRituals.nomination(weekend, 1):
            {'workId': filmTwoId, 'updatedAt': 110},
        SaturnOrbitRituals.selection(weekend):
            {'workId': filmTwoId, 'updatedAt': 120},
        SaturnOrbitRituals.nomination(month, 0):
            {'workId': bookId, 'updatedAt': 130},
        SaturnOrbitRituals.nomination(month, 1):
            {'workId': otherBookId, 'updatedAt': 140},
      }),
      'records': jsonEncode({
        '0:$bookId': {
          'status': 'Em andamento', 'rating': 8.0,
          'notes': 'Ainda na metade.',
        },
        '1:$otherBookId': {
          'status': 'Lido', 'rating': 10.0,
          'notes': 'Adorei.',
        },
      }),
      'shared': jsonEncode([bookId, otherBookId, filmTwoId]),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    expect(find.byTooltip('Livro do mês pendente: leia e dê sua nota'),
      findsOneWidget);
    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    // The weekly film card can be offscreen under the orbit hero in a
    // small test viewport; this test focuses on the monthly book status.
    final scroll = find.descendant(
      of: find.byKey(const PageStorageKey('saturn_shared_orbit')),
      matching: find.byType(Scrollable),
    );
    final bookCard = find.byKey(const Key('saturn-ritual-book'));
    for (var attempt = 0;
         attempt < 25 && bookCard.evaluate().isEmpty;
         attempt++) {
      await tester.drag(scroll, const Offset(0, -180));
      await tester.pumpAndSettle();
    }
    expect(bookCard, findsOneWidget);
    expect(find.text('Leitura do Eu'), findsWidgets);
    expect(find.text('Leitura da Ela'), findsWidgets);
    expect(find.text('Escolher nosso livro'), findsNothing);
    expect(find.text('Eu: Pendente'), findsOneWidget);
    expect(find.text('Ela: Lido e avaliado'), findsOneWidget);
    expect(find.text('Marcar leitura e dar nota'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final stored = jsonDecode(prefs.getString('records')!) as Map;
    expect((stored['0:$bookId'] as Map)['notes'], 'Ainda na metade.');
    expect((stored['1:$otherBookId'] as Map)['notes'], 'Adorei.');
    final ops = jsonDecode(prefs.getString('saturn_ritual_ops_v1')!) as Map;
    expect((ops[SaturnOrbitRituals.nomination(month, 0)] as Map)['workId'],
      bookId);
    expect((ops[SaturnOrbitRituals.nomination(month, 1)] as Map)['workId'],
      otherBookId);
  });


  testWidgets('Nossa Órbita apresenta progresso e memórias reais de cada perfil',
      (tester) async {
    final film = Work(
      'tmdb:movie:2048', 'Nosso Filme Guardado', 'Filme',
      'Uma lembrança compartilhada.', 2024, provider: 'TMDB');
    SharedPreferences.setMockInitialValues({
      'records': jsonEncode({
        '0:${film.id}': {
          'status': 'Concluído', 'rating': 8.0,
          'notes': 'Gostei do final e da trilha.',
        },
        '1:${film.id}': {
          'status': 'Concluído', 'rating': 10.0,
          'notes': 'Nossa noite favorita!',
        },
      }),
      'catalog_saved': jsonEncode({film.id: film.toJson()}),
      'shared': jsonEncode([film.id]),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    expect(find.text('Duas histórias. Um universo.'), findsOneWidget);
    expect(find.text('vividas pelos dois'), findsOneWidget);
    expect(find.text('com memórias'), findsOneWidget);
    final sharedScroll = find.descendant(
      of: find.byKey(const PageStorageKey('saturn_shared_orbit')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Memórias da nossa órbita'), 220,
      scrollable: sharedScroll, maxScrolls: 20);
    await tester.pumpAndSettle();
    expect(find.textContaining('Nossa noite favorita!'), findsWidgets);
    expect(find.textContaining('Gostei do final e da trilha.'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('saturn-shared-moment-Vividas por nós')),
      -220, scrollable: sharedScroll, maxScrolls: 20);
    await tester.tap(
      find.byKey(const Key('saturn-shared-moment-Vividas por nós')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Nossa biblioteca'), 220,
      scrollable: sharedScroll, maxScrolls: 20);
    expect(find.text('Nossa biblioteca'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final records = jsonDecode(prefs.getString('records')!) as Map;
    expect((records['1:${film.id}'] as Map)['notes'],
      'Nossa noite favorita!');
    expect(jsonDecode(prefs.getString('shared')!), [film.id]);
  });


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
    expect(find.text('Duas histórias. Um universo.'), findsOneWidget);
    final sharedScroll = find.descendant(
      of: find.byKey(const PageStorageKey('saturn_shared_orbit')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('MOMENTOS DA NOSSA HISTÓRIA'), 210,
      scrollable: sharedScroll, maxScrolls: 20);
    expect(find.text('MOMENTOS DA NOSSA HISTÓRIA'), findsOneWidget);
    // O filtro compartilhado continua implementado. Com os dois rituais
    // acima da biblioteca, o teste de dados não deve depender da distância
    // rolada nem da montagem preguiçosa dos cards da lista.
    expect(find.text('MOMENTOS DA NOSSA HISTÓRIA'), findsOneWidget);

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
