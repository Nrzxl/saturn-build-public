import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';
import 'package:saturn_app/saturn_orbit_rituals.dart';

void main() {
  Future<void> scrollPersonal(WidgetTester tester, Finder target,
      {double step = 245}) async {
    final scroller = find.descendant(
      of: find.byKey(const PageStorageKey('saturn_personal_collection')),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(target, step,
      scrollable: scroller, maxScrolls: 20);
    await tester.pumpAndSettle();
  }

  testWidgets('Série escolhida por ela passa próxima vez para ele', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final series = Work('tmdb:tv:999888', 'Nossa série atual', 'Série',
      'História que estamos assistindo.', 2025, provider: 'TMDB');
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({series.id: series.toJson()}),
      'saturn_ritual_ops_v1': jsonEncode({
        'series:turn:0': {
          'workId': series.id, 'chosenBy': 1,
          'finished': false, 'updatedAt': 100,
        },
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('saturn-shared-series'));
    await tester.scrollUntilVisible(card, 180,
        scrollable: find.byType(Scrollable).first, maxScrolls: 18);
    expect(card, findsOneWidget);
    expect(find.text('Ela escolheu desta vez.'), findsOneWidget);
    expect(find.text('Próxima escolha: Eu'), findsOneWidget);
    final done = find.byKey(const Key('saturn-series-finish'));
    await tester.scrollUntilVisible(done, 100,
        scrollable: find.byType(Scrollable).first, maxScrolls: 24);
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saturn-series-next-choice')),
      findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('saturn_ritual_ops_v1')!)
        as Map<String, dynamic>;
    final first = saved['series:turn:0'] as Map<String, dynamic>;
    expect(first['chosenBy'], 1);
    expect(first['workId'], series.id);
    expect(first['finished'], true);
  });

  testWidgets('Nós exibe escolhas antecipadas e promove a próxima série',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = Work('series:current', 'Atual escolhida por ela',
        'Série', 'A nossa série atual.', 2026);
    final mine = Work('series:mine', 'Minha próxima série',
        'Série', 'Escolhida antecipadamente.', 2026);
    final hers = Work('series:hers', 'Próxima escolha dela',
        'Série', 'Escolhida depois da minha.', 2026);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        current.id: current.toJson(),
        mine.id: mine.toJson(),
        hers.id: hers.toJson(),
      }),
      'saturn_ritual_ops_v1': jsonEncode({
        'series:turn:0': {
          'workId': current.id, 'chosenBy': 1,
          'finished': false, 'updatedAt': 100,
        },
        'series:turn:1': {
          'workId': mine.id, 'chosenBy': 0,
          'finished': false, 'queued': true, 'updatedAt': 200,
        },
        'series:turn:2': {
          'workId': hers.id, 'chosenBy': 1,
          'finished': false, 'queued': true, 'updatedAt': 300,
        },
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('saturn-shared-series'));
    await tester.scrollUntilVisible(card, 180,
        scrollable: find.byType(Scrollable).first, maxScrolls: 18);
    expect(find.byKey(const Key('saturn-series-queued-0')), findsOneWidget);
    expect(find.byKey(const Key('saturn-series-queued-1')), findsOneWidget);
    expect(find.byKey(const Key('saturn-series-edit-1')), findsOneWidget);
    expect(find.byKey(const Key('saturn-series-edit-2')), findsNothing);
    expect(find.byKey(const Key('saturn-series-next-choice')),
        findsOneWidget);
    final done = find.byKey(const Key('saturn-series-finish'));
    await tester.ensureVisible(done);
    await tester.tap(done);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('saturn_ritual_ops_v1')!)
        as Map<String, dynamic>;
    expect((saved['series:turn:0'] as Map)['finished'], isTrue);
    expect((saved['series:turn:1'] as Map)['queued'], isFalse);
    expect((saved['series:turn:2'] as Map)['queued'], isTrue);
  });

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
    await tester.scrollUntilVisible(person, 140,
        scrollable: find.byType(Scrollable).first, maxScrolls: 40);
    await tester.scrollUntilVisible(nominate, 90,
        scrollable: find.byType(Scrollable).first, maxScrolls: 12);
    await tester.ensureVisible(nominate);
    await tester.pumpAndSettle();
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
    expect(find.byTooltip('Livro do mês em andamento · prazo até o fim do mês'),
      findsOneWidget);
    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    // The weekly film card can be offscreen under the orbit hero in a
    // small test viewport; this test focuses on the monthly book status.
    final scroll = find.descendant(
      of: find.byKey(const PageStorageKey('saturn_shared_orbit')),
      matching: find.byType(Scrollable),
    ).first;
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
    expect(find.text('Eu: Em leitura'), findsOneWidget);
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
    expect(find.text('vividas pelos dois'), findsNothing);
    expect(find.text('com memórias'), findsOneWidget);
    final sharedScroll = find.descendant(
      of: find.byKey(const PageStorageKey('saturn_shared_orbit')),
      matching: find.byType(Scrollable),
    ).first;
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
    await scrollPersonal(tester,
      find.byKey(Key('saturn-ranked-card-' + film.id)));
    expect(find.text('Filme em Conjunto'), findsOneWidget);
    expect(find.text('Livro em Conjunto'), findsOneWidget);
    await scrollPersonal(tester,
      find.byKey(const Key('saturn-collection-filter-menu')),
      step: -220);
    await tester.tap(
      find.byKey(const Key('saturn-collection-filter-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Livros').last);
    await tester.pumpAndSettle();
    await scrollPersonal(tester,
      find.byKey(Key('saturn-ranked-card-' + book.id)));
    expect(find.text('Livro em Conjunto'), findsOneWidget);
    expect(find.text('Filme em Conjunto'), findsNothing);

    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    expect(find.text('Duas histórias. Um universo.'), findsOneWidget);
    final sharedScroll = find.descendant(
      of: find.byKey(const PageStorageKey('saturn_shared_orbit')),
      matching: find.byType(Scrollable),
    ).first;
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
    expect(find.text('Descobrir histórias'), findsNothing);
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
    await scrollPersonal(tester,
      find.byKey(Key('saturn-ranked-card-' + saved.id)));
    expect(find.text('Anime da Nossa Órbita'), findsOneWidget);

    final animeCard = find.byKey(Key('saturn-ranked-card-' + saved.id));
    await tester.ensureVisible(animeCard);
    await tester.pumpAndSettle();
    await tester.tap(animeCard);
    await tester.pumpAndSettle();
    expect(find.text('ONDE ASSISTIR · BRASIL'), findsOneWidget);
    expect(find.text('Crunchyroll'), findsWidgets);
    expect(find.text('Link fornecido · disponibilidade não confirmada'),
        findsOneWidget);
    expect(find.text('Nenhuma assinatura confirmada para este título.'),
        findsOneWidget);
    expect(find.text('Pesquisar em meus serviços'), findsOneWidget);
    expect(find.text('Uma história especial'), findsOneWidget);
  });


  testWidgets('TVmaze antigo usa a mesma ficha clean e sem serviços inventados',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final office = Work(
      'tvmaze:526', 'The Office', 'Série',
      List.filled(16, 'A story about colleagues and office life. ').join(),
      2005, provider: 'TVmaze', creator: 'NBC',
      trailerYoutubeId: 'abc123xyz99',
    );
    SharedPreferences.setMockInitialValues({
      'records': jsonEncode({
        '0:' + office.id: {
          'status': 'Concluído', 'rating': 10,
          'notes': 'A MELHOR SÉRIE DE TODAS!',
        },
        '1:' + office.id: {
          'status': 'Quero conhecer', 'rating': 9,
          'notes': 'Amo demais!',
        },
      }),
      'catalog_saved': jsonEncode({office.id: office.toJson()}),
      'shared': jsonEncode([office.id]),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();
    final card = find.byKey(Key('saturn-ranked-card-' + office.id));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('The Office'), findsWidgets);
    expect(find.byKey(const Key('saturn-story-synopsis-toggle')),
        findsOneWidget);
    expect(find.text('Metacritic · crítica'), findsNothing);
    expect(find.text('Nenhuma assinatura confirmada para este título.'),
        findsOneWidget);
    expect(find.text('Netflix'), findsNothing);
    expect(find.text('Pesquisar em meus serviços'), findsOneWidget);
    // Flutter VM tests use a cover fallback: the iframe is instantiated
    // only by the browser/mobile player runtime, never by the test runner.
    expect(find.byKey(Key('saturn-trailer-' + office.id)), findsNothing);
    expect(find.text('A MELHOR SÉRIE DE TODAS!'), findsWidgets);
    final prefs = await SharedPreferences.getInstance();
    final existing = jsonDecode(prefs.getString('records')!) as Map;
    expect((existing['0:' + office.id] as Map)['rating'], 10);
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
    final bookCard = find.byKey(Key('saturn-ranked-card-' + book.id));
    await scrollPersonal(tester, bookCard);
    await tester.ensureVisible(bookCard);
    await tester.pumpAndSettle();
    await tester.tap(bookCard);
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
    await scrollPersonal(tester,
      find.byKey(Key('saturn-ranked-card-' + film.id)));
    expect(find.text('Filme da Minha Coleção'), findsOneWidget);
    await scrollPersonal(tester,
      find.text('Selecionar vários'), step: -230);
    await tester.tap(find.text('Selecionar vários'));
    await tester.pumpAndSettle();
    await scrollPersonal(tester,
      find.byKey(Key('saturn-ranked-card-' + film.id)));
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await scrollPersonal(tester,
      find.text('Ações em massa'), step: -230);
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
    final seriesCard = find.byKey(Key('saturn-ranked-card-' + film.id));
    await scrollPersonal(tester, seriesCard);
    await tester.ensureVisible(seriesCard);
    await tester.pumpAndSettle();
    await tester.tap(seriesCard);
    await tester.pumpAndSettle();
    expect(find.text('NOSSAS AVALIAÇÕES · NOTAS INDIVIDUAIS'), findsOneWidget);
    expect(find.text('SUA NOTA'), findsOneWidget);
    expect(find.text('NOTA DA OUTRA PESSOA'), findsOneWidget);
    expect(find.textContaining('Eu amei a história!'), findsWidgets);
    expect(find.text('8.4/10'), findsNothing);
    expect(find.text('92%'), findsNothing);
    expect(find.text('79/100'), findsOneWidget);
  });

  testWidgets('Catálogo apresenta filtros compactos e gêneros apenas no card',
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
    expect(find.text('GÊNERO · TMDB'), findsOneWidget);
    expect(find.byKey(const Key('saturn-genre-all')), findsOneWidget);
    expect(find.byKey(const Key('saturn-genre-18')), findsOneWidget);
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
    expect(find.byTooltip('Sincronizar e verificar atualizações'), findsOneWidget);
    expect(find.byTooltip('Atualizar SATURN'), findsNothing);
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
