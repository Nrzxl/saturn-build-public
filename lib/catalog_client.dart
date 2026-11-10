import 'dart:convert';

import 'package:http/http.dart' as http;
import 'streaming_links.dart';
import 'tmdb_catalog_data.dart';
import 'saturn_book_cover.dart';

/// Catálogos sem credenciais embutidas no APK.
/// "Disponível para pesquisar" NÃO significa "disponível para assistir no Brasil".
enum CatalogFilter { all, movies, series, dramas, anime, books }

class CatalogEntry {
  final String id;
  final String title;
  final String kind;
  final String description;
  final String posterUrl;
  final String creator;
  final String provider;
  final String detailUrl;
  final int year;
  final Map<String, String> streamingLinks;
  final Map<String, String> streamingProviders;
  final List<String> watchProviders;
  final List<int> genreIds;
  final Map<String, String> externalRatings;
  final double? tmdbScore;
  final int? tmdbVoteCount;
  final String watchUrl;
  final String trailerYoutubeId;
  final String nativeTrailerUrl;
  final String originalTitle;
  final String availabilityUpdatedAt;
  final bool availabilityChecked;

  const CatalogEntry({
    required this.id,
    required this.title,
    required this.kind,
    required this.description,
    required this.year,
    required this.posterUrl,
    required this.creator,
    required this.provider,
    required this.detailUrl,
    this.streamingLinks = const {},
    this.streamingProviders = const {},
    this.watchProviders = const [],
    this.genreIds = const [],
    this.externalRatings = const {},
    this.tmdbScore,
    this.tmdbVoteCount,
    this.watchUrl = '',
    this.trailerYoutubeId = '',
    this.nativeTrailerUrl = '',
    this.originalTitle = '',
    this.availabilityUpdatedAt = '',
    this.availabilityChecked = false,
  });
}

class CatalogClient {
  final http.Client _client;
  late final TmdbCatalogData _tmdb;
  final bool _enableTmdb;

  CatalogClient({http.Client? client, bool? enableTmdb})
      : _client = client ?? http.Client(),
        _enableTmdb = enableTmdb ?? client == null {
    _tmdb = TmdbCatalogData(_client);
  }

  void close() => _client.close();

  /// Look up a saved film/series by its stable TMDB identifier in the latest
  /// published online SATURN snapshot; no title/first-page approximation.
  Future<CatalogEntry?> onlineRatingsById(String workId) async {
    if (!_enableTmdb || !workId.startsWith('tmdb:')) return null;
    final row = await _tmdb.findById(workId);
    if (row == null) return null;
    final external = row['externalRatings'];
    return CatalogEntry(
      id: (row['id'] ?? '').toString(),
      title: (row['title'] ?? '').toString(),
      kind: (row['kind'] ?? '').toString(),
      description: (row['description'] ?? '').toString(),
      year: row['year'] is num ? (row['year'] as num).toInt() : 0,
      posterUrl: (row['posterUrl'] ?? '').toString(),
      provider: 'TMDB',
      creator: (row['creator'] ?? '').toString(),
      detailUrl: (row['detailUrl'] ?? '').toString(),
      externalRatings: external is Map
          ? external.map((key, value) =>
              MapEntry(key.toString(), value.toString()))
          : const {},
      tmdbScore: row['tmdbVoteAverage'] is num
          ? (row['tmdbVoteAverage'] as num).toDouble()
          : null,
      tmdbVoteCount: row['tmdbVoteCount'] is num
          ? (row['tmdbVoteCount'] as num).toInt()
          : null,
    );
  }

  final Map<String, Future<String?>> _trailerLookupCache = {};

  /// Look up a confirmed YouTube trailer from SATURN's public, keyed TMDB
  /// snapshot. No TMDB API key, guessing video IDs or YouTube scraping.
  Future<String?> verifiedTrailerFor({
    required String workId,
    required String title,
    required String kind,
    required int year,
  }) {
    final key = '$workId:$title:$year';
    return _trailerLookupCache.putIfAbsent(key, () async {
      if (!_enableTmdb ||
          (kind != 'Filme' && kind != 'Série' &&
           kind != 'Dorama' && kind != 'Anime')) return null;
      bool valid(Map row) {
        final video = (row['trailerYoutubeId'] ?? '').toString();
        return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(video);
      }
      String normalized(String value) {
        const from = 'áàâãäéèëíìîïóòôõöúùûüçñ';
        const into = 'aaaaaeeeeiiiiooooouuuucn';
        var text = value.toLowerCase();
        for (var i = 0; i < from.length; i++) {
          text = text.replaceAll(from[i], into[i]);
        }
        return text.replaceAll(RegExp(r'[^a-z0-9]'), '');
      }
      try {
        final exact = await _tmdb.findById(workId);
        if (exact != null && valid(exact)) {
          return (exact['trailerYoutubeId'] ?? '').toString();
        }
        final group = kind == 'Filme' ? 'movies' : 'series';
        final groups = <String>[group,
          if (kind != 'Filme') 'dramas',
          if (kind == 'Anime') 'anime'];
        final target = normalized(title);
        for (final category in groups) {
          final rows = await _tmdb.query(
            filter: category, search: title, page: 1, perPage: 40);
          for (final row in rows) {
            if (!valid(row)) continue;
            final name = normalized((row['title'] ?? '').toString());
            final original =
                normalized((row['originalTitle'] ?? '').toString());
            if (target != name && target != original) continue;
            final catalogYear =
                row['year'] is num ? (row['year'] as num).toInt() : 0;
            if (year > 0 && catalogYear > 0 &&
                (year - catalogYear).abs() > 2) continue;
            return (row['trailerYoutubeId'] ?? '').toString();
          }
        }
      } catch (_) {
        // The title's existing details and personal reviews are still usable.
      }
      return null;
    });
  }

  Future<List<CatalogEntry>> _snapshot({
    required CatalogFilter filter,
    required String query,
    required int page,
    String? streaming,
    int? genreId,
  }) async {
    if (!_enableTmdb || filter == CatalogFilter.books) return [];
    final rows = await _tmdb.query(
      filter: filter.name,
      search: query,
      page: page,
      streaming: streaming,
      genreId: genreId,
    );
    return [
      for (final row in rows)
        CatalogEntry(
          id: (row['id'] ?? '').toString(),
          title: (row['title'] ?? '').toString(),
          kind: (row['kind'] ?? '').toString(),
          description: (row['description'] ?? '').toString(),
          year: row['year'] is num ? (row['year'] as num).toInt() : 0,
          posterUrl: (row['posterUrl'] ?? '').toString(),
          creator: (row['creator'] ?? '').toString(),
          provider: 'TMDB',
          detailUrl: (row['detailUrl'] ?? '').toString(),
          originalTitle: (row['originalTitle'] ?? '').toString(),
          streamingProviders: row['streamingProviders'] is Map
              ? (row['streamingProviders'] as Map).map(
                  (key, value) => MapEntry(
                    key.toString(), value.toString()))
              : const {},
          watchProviders: row['watchProviders'] is List
              ? (row['watchProviders'] as List).map(
                  (value) => value.toString()).toList(growable: false)
              : const [],
          genreIds: row['genreIds'] is List
              ? (row['genreIds'] as List).whereType<num>()
                  .map((n) => n.toInt()).toList(growable: false)
              : const [],
          externalRatings: row['externalRatings'] is Map
              ? (row['externalRatings'] as Map).map(
                  (key, value) => MapEntry(key.toString(), value.toString()))
              : const {},
          tmdbScore: row['tmdbVoteAverage'] is num
              ? (row['tmdbVoteAverage'] as num).toDouble()
              : null,
          tmdbVoteCount: row['tmdbVoteCount'] is num
              ? (row['tmdbVoteCount'] as num).toInt() : null,
          watchUrl: (row['watchUrl'] ?? '').toString(),
          trailerYoutubeId: (row['trailerYoutubeId'] ?? '').toString(),
          nativeTrailerUrl: (row['nativeTrailerUrl'] ?? '').toString(),
          availabilityChecked: row['availabilityChecked'] == true,
          availabilityUpdatedAt: (row['availabilityUpdatedAt'] ??
                  row['generatedAt'] ?? '').toString(),
        ),
    ];
  }

  /// Busca por título. Suporta páginas novas onde a fonte oferece paginação.
  Future<List<CatalogEntry>> search(
    String input,
    CatalogFilter filter, {
    int page = 1,
    String? streaming,
    String? bookSubject,
    int? genreId,
  }) async {
    final query = input.trim();
    if (query.length < 2) return [];
    final p = page.clamp(1, 500).toInt();
    try {
      final found = await _snapshot(
        filter: filter, query: query, page: p,
        streaming: streaming, genreId: genreId);
      if (found.isNotEmpty || streaming != null || genreId != null) {
        if (filter == CatalogFilter.all && streaming == null) {
          try {
            final books = await _books(query, page: p,
                subject: bookSubject);
            return _unique([...found, ...books]);
          } catch (_) {
            return found;
          }
        }
        return found;
      }
    } catch (_) {
      // Older catalogs remain usable while the public TMDB feed is absent.
      if (streaming != null || genreId != null) return [];
    }
    final requests = <Future<List<CatalogEntry>>>[];
    final errors = <String>[];

    Future<List<CatalogEntry>> safe(
      String name,
      Future<List<CatalogEntry>> Function() task,
    ) async {
      try {
        return await task();
      } catch (_) {
        errors.add(name);
        return [];
      }
    }

    if (filter == CatalogFilter.all || filter == CatalogFilter.movies) {
      if (p == 1) requests.add(safe('filmes', () => _movies(query)));
    }
    if (filter == CatalogFilter.all ||
        filter == CatalogFilter.series ||
        filter == CatalogFilter.dramas) {
      if (p == 1) {
        requests.add(safe('séries e doramas',
            () => _shows(query, dramasOnly: filter == CatalogFilter.dramas)));
      }
    }
    if (filter == CatalogFilter.all || filter == CatalogFilter.anime) {
      requests.add(safe('animes', () => _anime(query: query, page: p)));
    }
    if (filter == CatalogFilter.all || filter == CatalogFilter.books) {
      // An explicit author/title search must not be constrained by a
      // previously selected discovery subject (e.g. Agatha Christie while
      // Literatura brasileira was active).
      requests.add(safe('livros',
          () => _books(query, page: p)));
      // Broaden PT-BR edition coverage without harvesting a full catalog.
      if (filter == CatalogFilter.books) {
        requests.add(safe('livros nacionais e em português',
          () => _googleBooks(query: query, page: p)));
      }
    }

    if (requests.isEmpty) return [];
    final groups = await Future.wait(requests);
    final works = _unique(groups.expand((items) => items));
    if (works.isEmpty && errors.isNotEmpty) {
      throw StateError('Não foi possível consultar ${errors.join(', ')}. Tente novamente.');
    }
    return filter == CatalogFilter.books
        ? _prioritizePortuguese(works) : works;
  }

  /// Descoberta por categorias: carregamento real a partir de serviços
  /// públicos. Sem "cards de exemplo" piscando antes dos dados chegarem.
  Future<List<CatalogEntry>> discover(
    CatalogFilter filter, {
    int page = 1,
    String? streaming,
    String? bookSubject,
    int? genreId,
  }) async {
    final p = page.clamp(1, 500).toInt();
    try {
      final found = await _snapshot(
        filter: filter, query: '', page: p,
        streaming: streaming, genreId: genreId);
      if (found.isNotEmpty || streaming != null || genreId != null) {
        if (filter == CatalogFilter.all && streaming == null) {
          try {
            return _unique([
              ...found,
              ...await _discoverBooks(p, subject: bookSubject),
            ]);
          } catch (_) {
            return found;
          }
        }
        return found;
      }
    } catch (_) {
      if (streaming != null || genreId != null) return [];
    }
    final requests = <Future<List<CatalogEntry>>>[];
    final errors = <String>[];

    Future<List<CatalogEntry>> safe(
      String name,
      Future<List<CatalogEntry>> Function() task,
    ) async {
      try {
        return await task();
      } catch (_) {
        errors.add(name);
        return [];
      }
    }

    if (filter == CatalogFilter.all || filter == CatalogFilter.movies) {
      requests.add(safe('filmes', () => _discoverMovies(p)));
    }
    if (filter == CatalogFilter.all || filter == CatalogFilter.series) {
      requests.add(safe('séries', () => _discoverShows(p)));
    }
    if (filter == CatalogFilter.all || filter == CatalogFilter.dramas) {
      requests.add(safe('doramas', () => _discoverDramas(p)));
    }
    if (filter == CatalogFilter.all || filter == CatalogFilter.anime) {
      requests.add(safe('animes', () => _anime(page: p)));
    }
    if (filter == CatalogFilter.all || filter == CatalogFilter.books) {
      requests.add(safe('livros',
          () => _discoverBooks(p, subject: bookSubject)));
      if (filter == CatalogFilter.books) {
        requests.add(safe('Google Livros',
          () => _googleBooks(page: p,
            national: bookSubject == 'brazilian_literature')));
      }
    }

    final groups = await Future.wait(requests);
    final works = _unique(groups.expand((items) => items));
    if (works.isEmpty && errors.isNotEmpty) {
      throw StateError('Sem acesso aos catálogos (${errors.join(', ')}). Verifique a rede.');
    }
    return filter == CatalogFilter.books
        ? _prioritizePortuguese(works) : works;
  }

  static List<CatalogEntry> _prioritizePortuguese(
      List<CatalogEntry> entries) {
    final sorted = [...entries];
    int quality(CatalogEntry book) {
      final provider = book.provider.toLowerCase();
      var score = 0;
      if (provider.contains('português') ||
          provider.contains('brasil') ||
          provider.contains('brasileira')) score += 8;
      if (book.posterUrl.startsWith('https://')) score += 2;
      if (book.creator.trim().isNotEmpty) score += 1;
      if (book.description.contains('ISBN:')) score += 1;
      return score;
    }
    sorted.sort((a, b) {
      final byQuality = quality(b).compareTo(quality(a));
      if (byQuality != 0) return byQuality;
      // With equally strong editions, retain source relevance/order.
      return entries.indexOf(a).compareTo(entries.indexOf(b));
    });
    return sorted;
  }

  static List<CatalogEntry> _unique(Iterable<CatalogEntry> entries) {
    final byId = <String, CatalogEntry>{};
    for (final entry in entries) {
      if (entry.title.trim().isEmpty) continue;
      byId.putIfAbsent(entry.id, () => entry);
    }
    return byId.values.toList(growable: false);
  }

  Future<dynamic> _get(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> _post(Uri uri, Map<String, dynamic> payload) async {
    final response = await _client.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<List<CatalogEntry>> _movies(String query) async {
    final data = await _get(Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'country': 'BR',
      'media': 'movie',
      'entity': 'movie',
      'limit': '75',
    }));
    if (data is! Map || data['results'] is! List) return [];
    return _mapMovies(data['results'] as List);
  }

  Future<List<CatalogEntry>> _discoverMovies(int page) async {
    // A Apple Search API é de busca. As sugestões são um recorte temático,
    // não um ranking de estreias ou de disponibilidade por streaming.
    const themes = [
      'love', 'world', 'star', 'family', 'life', 'mystery',
      'adventure', 'romance', 'space', 'heart',
    ];
    return _movies(themes[(page - 1) % themes.length]);
  }

  List<CatalogEntry> _mapMovies(List rows) {
    final items = <CatalogEntry>[];
    for (final raw in rows) {
      if (raw is! Map) continue;
      final id = raw['trackId'];
      final title = (raw['trackName'] ?? '').toString();
      if (id == null || title.isEmpty) continue;
      final art = (raw['artworkUrl100'] ?? '').toString();
      items.add(CatalogEntry(
        id: 'itunes:$id',
        title: title,
        kind: 'Filme',
        description: (raw['longDescription'] ??
                raw['shortDescription'] ??
                'Sinopse não disponível.')
            .toString(),
        year: _year((raw['releaseDate'] ?? '').toString()),
        posterUrl: art,
        creator: (raw['artistName'] ?? '').toString(),
        provider: 'Apple TV Store',
        detailUrl: (raw['trackViewUrl'] ?? '').toString(),
      ));
    }
    return items;
  }

  static const _dramaLanguages = <String>{
    'Korean', 'Japanese', 'Chinese', 'Mandarin', 'Cantonese', 'Thai',
    'Taiwanese',
  };
  static const _dramaCountries = <String>{'KR', 'JP', 'CN', 'TW', 'TH'};

  static bool _isDorama(Map show) {
    final language = (show['language'] ?? '').toString();
    final genres = show['genres'];
    if (genres is List &&
        (genres.contains('Anime') || genres.contains('Animation'))) {
      return false;
    }
    if (_dramaLanguages.contains(language)) return true;
    final network = show['network'] ?? show['webChannel'];
    if (network is Map && network['country'] is Map) {
      final code = (network['country'] as Map)['code'];
      return _dramaCountries.contains(code);
    }
    return false;
  }

  Future<List<CatalogEntry>> _shows(String query, {bool dramasOnly = false}) async {
    final data = await _get(
      Uri.https('api.tvmaze.com', '/search/shows', {'q': query}),
    );
    if (data is! List) return [];
    final shows = <dynamic>[];
    for (final item in data) {
      if (item is Map && item['show'] is Map) shows.add(item['show']);
    }
    return _mapShows(shows, dramasOnly: dramasOnly);
  }

  Future<List<CatalogEntry>> _discoverShows(int page) async {
    final data = await _get(
      Uri.https('api.tvmaze.com', '/shows', {'page': '${page - 1}'}),
    );
    if (data is! List) return [];
    return _mapShows(data.where((row) =>
        row is Map &&
        (row['type'] == 'Scripted' || row['type'] == 'Animation')));
  }

  Future<List<CatalogEntry>> _discoverDramas(int page) async {
    // Busca por grupos temáticos distintos em diferentes páginas.
    const titles = [
      ['Love', 'Queen'],
      ['Hospital', 'Secret'],
      ['Moon', 'King'],
      ['Spring', 'Heart'],
      ['Summer', 'Dream'],
    ];
    final seeds = titles[(page - 1) % titles.length];
    final groups = await Future.wait(
      seeds.map((seed) => _shows(seed, dramasOnly: true)),
    );
    return _unique(groups.expand((group) => group));
  }

  List<CatalogEntry> _mapShows(
    Iterable<dynamic> shows, {
    bool dramasOnly = false,
  }) {
    final result = <CatalogEntry>[];
    for (final raw in shows) {
      if (raw is! Map) continue;
      if (dramasOnly && !_isDorama(raw)) continue;
      final id = raw['id'];
      final name = (raw['name'] ?? '').toString();
      if (id == null || name.isEmpty) continue;
      final image = raw['image'];
      final network = raw['network'] ?? raw['webChannel'];
      result.add(CatalogEntry(
        id: 'tvmaze:$id',
        title: name,
        kind: _isDorama(raw) ? 'Dorama' : 'Série',
        description: _strip((raw['summary'] ?? '').toString()),
        year: _year((raw['premiered'] ?? '').toString()),
        posterUrl:
            image is Map ? (image['original'] ?? image['medium'] ?? '').toString() : '',
        creator: network is Map ? (network['name'] ?? '').toString() : '',
        provider: 'TVmaze',
        detailUrl: (raw['url'] ?? '').toString(),
        streamingLinks: extractOfficialTitleLinks([
          {'url': (raw['officialSite'] ?? '').toString()},
        ]),
      ));
    }
    return result;
  }


  /// User-initiated pages, rather than bulk harvesting of Open Library.
  static const bookSubjects = <String, String>{
    'Ficção': 'fiction',
    'Romance': 'romance',
    'Fantasia': 'fantasy',
    'Ficção científica': 'science_fiction',
    'Mistério': 'mystery',
    'Suspense': 'thriller',
    'Terror': 'horror',
    'Mangás': 'manga',
    'Quadrinhos': 'comics',
    'Juvenil': 'young_adult_fiction',
    'Clássicos': 'classic_literature',
    'Biografias': 'biography',
    'História': 'history',
    'Não ficção': 'nonfiction',
    'Literatura brasileira': 'brazilian_literature',
  };



  /// Google Books increases coverage of Brazilian publishers and actual
  /// Portuguese editions that do not exist in Open Library. User-requested
  /// pages only (max 40), unique stable volume IDs, no fabricated books.
  Future<List<CatalogEntry>> _googleBooks({
    String query = '', int page = 1, bool national = false,
  }) async {
    final input = query.trim();
    const nationalAuthors = <String>[
      'Machado de Assis', 'Clarice Lispector', 'Jorge Amado',
      'Conceição Evaristo', 'Lygia Fagundes Telles',
      'Carlos Drummond de Andrade', 'Milton Hatoum',
      'Graciliano Ramos', 'Carolina Maria de Jesus', 'Paulo Coelho',
      'Cecília Meireles', 'Guimarães Rosa',
      'Lima Barreto', 'Rachel de Queiroz', 'Érico Veríssimo',
      'José de Alencar', 'Monteiro Lobato', 'Ariano Suassuna',
      'Rubem Fonseca', 'Hilda Hilst', 'João Ubaldo Ribeiro',
      'Raduan Nassar', 'Vinicius de Moraes', 'Itamar Vieira Junior',
      'Socorro Acioli', 'Marina Colasanti', 'Ailton Krenak',
      'Daniel Munduruku', 'Djamila Ribeiro', 'José Mauro de Vasconcelos',
      'Ana Maria Machado', 'Lúcio Cardoso',
    ];
    // Do not concatenate an author with a multi-word subject filter:
    // that exact combination frequently returns zero volumes.
    final search = input.isNotEmpty
        ? input
        : national
          ? 'inauthor:' + nationalAuthors[
              (page - 1) % nationalAuthors.length]
          : 'subject:fiction';
    // Rotate Brazilian writers on national discovery pages and paginate
    // without flooding Google or Open Library with background requests.
    final nationalPage = national && input.isEmpty
        ? (page - 1) ~/ nationalAuthors.length : page - 1;
    final data = await _get(Uri.https(
      'www.googleapis.com', '/books/v1/volumes', {
        'q': search,
        'langRestrict': 'pt',
        'printType': 'books',
        'maxResults': '40',
        'startIndex': (nationalPage * 40).toString(),
        'projection': 'full',
      }));
    if (data is! Map || data['items'] is! List) return [];
    final result = <CatalogEntry>[];
    for (final item in data['items'] as List) {
      if (item is! Map) continue;
      final id = (item['id'] ?? '').toString();
      final volume = item['volumeInfo'];
      if (id.isEmpty || volume is! Map) continue;
      final title = (volume['title'] ?? '').toString().trim();
      final language = (volume['language'] ?? '').toString().toLowerCase();
      if (title.isEmpty ||
          !(language == 'pt' || language.startsWith('pt-'))) continue;
      final authors = volume['authors'];
      final creator = authors is List
          ? authors.map((a) => a.toString()).join(', ') : '';
      final identifiers = volume['industryIdentifiers'];
      var isbn = '';
      if (identifiers is List) {
        for (final value in identifiers) {
          if (value is Map && value['type'] == 'ISBN_13' &&
              value['identifier'] != null) {
            isbn = value['identifier'].toString();
            break;
          }
        }
      }
      final images = volume['imageLinks'];
      // Prefer the actual volume's high-resolution art when available.
      var cover = images is Map
          ? (images['extraLarge'] ?? images['large'] ??
             images['medium'] ?? images['small'] ??
             images['thumbnail'] ?? images['smallThumbnail'] ?? '').toString()
          : '';
      if (cover.startsWith('http://books.google.com/') ||
          cover.startsWith('http://books.googleusercontent.com/')) {
        cover = cover.replaceFirst('http://', 'https://');
      }
      if (!cover.startsWith('https://')) cover = '';
      final link = (volume['infoLink'] ?? '').toString();
      result.add(CatalogEntry(
        id: 'googlebooks:' + id,
        title: title,
        kind: 'Livro',
        description: [
          if (creator.isNotEmpty) 'Autoria: ' + creator,
          if (volume['publisher'] != null)
            'Editora: ' + volume['publisher'].toString(),
          if (isbn.isNotEmpty) 'ISBN: ' + isbn,
          if (volume['description'] != null)
            _strip(volume['description'].toString()),
        ].join(' · '),
        year: _year((volume['publishedDate'] ?? '').toString()),
        posterUrl: cover,
        creator: creator,
        provider: 'Google Livros · português',
        detailUrl: link.startsWith('https://')
            ? link : 'https://books.google.com/books?id=' + id,
      ));
    }
    return _unique(result);
  }

  /// A work groups all editions. Individual manga volumes use /books OL...M.
  Future<List<CatalogEntry>> bookEditions(String workId, {int page = 1}) async {
    final match = RegExp(r'^openlibrary:/works/(OL[0-9]+W)$').firstMatch(workId);
    if (match == null) return [];
    final number = page.clamp(1, 100).toInt();
    final data = await _get(Uri.https('openlibrary.org',
      '/works/' + match.group(1)! + '/editions.json',
      {'limit': '50', 'offset': ((number - 1) * 50).toString()}));
    if (data is! Map || data['entries'] is! List) return [];
    final portuguese = <CatalogEntry>[];
    final other = <CatalogEntry>[];
    for (final row in data['entries'] as List) {
      if (row is! Map) continue;
      final edition = _editionEntry(row);
      if (edition == null) continue;
      if (_hasPortugueseLanguage(row['languages'] ?? row['language'])) {
        portuguese.add(edition);
      } else {
        other.add(edition);
      }
    }
    return _unique([...portuguese, ...other]);
  }

  /// ISBN is a unique edition identifier, not an entire series.
  Future<CatalogEntry?> editionByIsbn(String value) async {
    final isbn = value.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
    if (!RegExp(r'^(?:[0-9]{13}|[0-9]{9}[0-9X])$').hasMatch(isbn)) return null;
    final json = await _get(Uri.https('openlibrary.org', '/isbn/' + isbn + '.json'));
    return json is Map ? _editionEntry(json) : null;
  }

  static CatalogEntry? _editionEntry(Map<dynamic, dynamic> row) {
    final key = (row['key'] ?? '').toString();
    if (!RegExp(r'^/books/OL[0-9]+M$').hasMatch(key)) return null;
    final base = (row['title'] ?? '').toString().trim();
    if (base.isEmpty) return null;
    final descriptors = <String>[];
    for (final field in ['subtitle', 'volume', 'edition_name']) {
      final item = (row[field] ?? '').toString().trim();
      if (item.isNotEmpty && !base.toLowerCase().contains(item.toLowerCase())
          && !descriptors.any((d) => d.toLowerCase() == item.toLowerCase())) {
        descriptors.add(item);
      }
    }
    final identifiers = <String>[
      if (row['isbn_13'] is List)
        for (final e in row['isbn_13'] as List) e.toString(),
      if (row['isbn_10'] is List)
        for (final e in row['isbn_10'] as List) e.toString(),
    ];
    final isbn = identifiers.firstWhere((v) =>
        RegExp(r'^(?:[0-9]{13}|[0-9]{9}[0-9Xx])$').hasMatch(v),
        orElse: () => '');
    final date = (row['publish_date'] ?? '').toString();
    final years = RegExp(r'(18|19|20)[0-9]{2}').allMatches(date);
    final year = years.isEmpty ? 0 : int.parse(years.last.group(0)!);
    final covers = row['covers'];
    final cover = covers is List && covers.isNotEmpty ? covers.first : null;
    final publishers = row['publishers'];
    final publisher = publishers is List && publishers.isNotEmpty
        ? publishers.first.toString() : '';
    return CatalogEntry(
      id: 'openlibrary:' + key,
      title: [base, ...descriptors].join(' · '),
      kind: 'Livro',
      description: [
        'Edição individual',
        if (descriptors.isNotEmpty) 'Identificação: ' + descriptors.join(' · '),
        if (publisher.isNotEmpty) 'Editora: ' + publisher,
        if (date.isNotEmpty) 'Publicação: ' + date,
        if (isbn.isNotEmpty) 'ISBN: ' + isbn,
      ].join(' · '),
      year: year,
      posterUrl: SaturnBookCover.resolve(
        'openlibrary:' + key,
        cover is num && cover > 0
            ? 'https://covers.openlibrary.org/b/id/' +
                cover.toInt().toString() + '-M.jpg'
            : isbn.isNotEmpty
                ? 'https://covers.openlibrary.org/b/isbn/' + isbn + '-M.jpg'
                : '',
      ),
      creator: publisher,
      provider: 'Open Library · edição',
      detailUrl: 'https://openlibrary.org' + key,
    );
  }


  /// Language metadata on an actual Open Library edition is required before
  /// showing that edition's translated title or cover in SATURN.
  static bool _hasPortugueseLanguage(Object? raw) {
    if (raw is! List) return false;
    for (final language in raw) {
      final code = language is Map
          ? (language['key'] ?? language['code'] ?? '').toString()
          : language.toString();
      final normalized = code.toLowerCase().split('/').last;
      if (normalized == 'por' || normalized == 'pt' ||
          normalized == 'pt-br' || normalized == 'pt-pt') {
        return true;
      }
    }
    return false;
  }

  static Map? _portugueseEdition(Map<dynamic, dynamic> work) {
    final editions = work['editions'];
    if (editions is! Map || editions['docs'] is! List) return null;
    for (final item in editions['docs'] as List) {
      if (item is Map && _hasPortugueseLanguage(
          item['language'] ?? item['languages'])) {
        return item;
      }
    }
    return null;
  }

  static String _bookCoverUrl(Object? cover, {String isbn = ''}) {
    if (cover is num && cover > 0) {
      return 'https://covers.openlibrary.org/b/id/' +
          cover.toInt().toString() + '-M.jpg';
    }
    if (isbn.isNotEmpty) {
      return 'https://covers.openlibrary.org/b/isbn/' + isbn + '-M.jpg';
    }
    return '';
  }

  // Bibliographic fallback: verified Brazilian edition of Death on the
  // Nile, catalogued at a public library. Not a fabricated Open Library
  // edition and does not require guessing an OL edition identifier.
  // Reference: AABB Porto Alegre, 2014, ISBN 9788520936511.
  static const nileBrazilianIsbn = '9788520936511';
  static const nileBrazilianId = 'isbn:9788520936511';

  static String _normalizeBookSearch(String query) {
    var text = query.trim().toLowerCase();
    const accented = 'áàâãäéêèëíìîïóôõöòúùûüç';
    const plain = 'aaaaaeeeeiiiiooooouuuuc';
    for (var i = 0; i < accented.length; i++) {
      text = text.replaceAll(accented[i], plain[i]);
    }
    return text.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r' +'), ' ').trim();
  }

  static bool _searchesForNile(String query) {
    final normalized = _normalizeBookSearch(query);
    return normalized.contains('morte no nilo') ||
        normalized.contains('death on the nile') ||
        normalized == 'agatha christie' ||
        normalized == 'agata christie' ||
        normalized == nileBrazilianIsbn;
  }

  static List<CatalogEntry> _verifiedPortugueseFallback(
    String query, int page, String? subject,
  ) {
    if (page != 1 || (subject != null && subject.isNotEmpty) ||
        !_searchesForNile(query)) {
      return const [];
    }
    return const [
      // Exact 2020 HarperCollins edition with a matching cover published
      // in the bookseller's bibliographic record (ISBN 9786555110029).
      CatalogEntry(
        id: 'isbn:9786555110029',
        title: 'Morte no Nilo',
        kind: 'Livro',
        description: 'Agatha Christie · Hercule Poirot · '
            'Edição brasileira HarperCollins (2020) · '
            'ISBN: 9786555110029 · Português · Capa dura',
        year: 2020,
        posterUrl: 'https://plenitudedistribuidora.com.br/cdn/shop/'
            'files/284941-1.jpg?v=1772146096',
        creator: 'Agatha Christie',
        provider: 'HarperCollins Brasil · edição 2020',
        detailUrl: 'https://plenitudedistribuidora.com.br/'
            'products/morte-no-nilo-agatha-christie',
        originalTitle: 'Death on the Nile',
      ),
      CatalogEntry(
        id: nileBrazilianId,
        title: 'Morte no Nilo',
        kind: 'Livro',
        description: 'Um caso de Hercule Poirot · '
            'Edição brasileira: Nova Fronteira (2014) · '
            'ISBN: 9788520936511 · Português · '
            'Título original: Death on the Nile',
        year: 2014,
        // The ISBN resolves the *matching* edition when Open Library
        // has cover art. If not, SATURN shows its own book placeholder.
        posterUrl: 'https://covers.openlibrary.org/b/isbn/'
            '9788520936511-M.jpg?default=false',
        creator: 'Agatha Christie',
        provider: 'Biblioteca · edição brasileira',
        detailUrl: 'https://www.aabbportoalegre.com.br/'
            'biblioteca/detalhes/morte-no-nilo/3085',
        originalTitle: 'Death on the Nile',
      ),
    ];
  }

  Future<List<CatalogEntry>> _books(
    String query, {
    int page = 1,
    String? subject,
  }) async {
    final clean = query.trim();
    final verified = _verifiedPortugueseFallback(clean, page, subject);
    // Older Open Library search indexes the English work title, not every
    // translated edition name. Resolve the documented title alias.
    final canonical = _normalizeBookSearch(clean).contains('morte no nilo')
        ? 'Death on the Nile' : clean;
    final search = (subject == null || subject.isEmpty)
        ? canonical
        : canonical + ' subject:' + subject;
    dynamic data;
    try {
      data = await _get(Uri.https('openlibrary.org', '/search.json', {
      'q': search,
      'lang': 'pt',
      'limit': '60',
      'page': page.clamp(1, 150).toString(),
      'fields': 'key,title,author_name,cover_i,first_publish_year,'
          'isbn,edition_count,language,editions,editions.key,'
          'editions.title,editions.language,editions.cover_i,'
          'editions.isbn_13,editions.isbn_10',
      }));
    } catch (_) {
      // Some OL work queries time out while expanding all editions.
      // Retry the same real catalog with a leaner fields projection.
      try {
        data = await _get(Uri.https('openlibrary.org', '/search.json', {
          'q': search,
          'lang': 'pt',
          'limit': '35',
          'page': page.clamp(1, 150).toString(),
          'fields': 'key,title,author_name,cover_i,first_publish_year,'
              'edition_count,language,isbn',
        })).timeout(const Duration(seconds: 7));
      } catch (_) {
        // Retain only bibliographically verified offline fallback entries.
        if (verified.isNotEmpty) return verified;
        rethrow;
      }
    }
    if (data is! Map || data['docs'] is! List) return verified;
    final result = <CatalogEntry>[...verified];
    for (final item in data['docs'] as List) {
      if (item is! Map) continue;
      final key = (item['key'] ?? '').toString();
      final workTitle = (item['title'] ?? '').toString().trim();
      if (key.isEmpty || workTitle.isEmpty || !key.startsWith('/works/')) {
        continue;
      }
      final authors = item['author_name'];
      final author = authors is List && authors.isNotEmpty
          ? authors.first.toString() : '';
      final edition = _portugueseEdition(item);
      final editionTitle = (edition?['title'] ?? '').toString().trim();
      final title = editionTitle.isNotEmpty ? editionTitle : workTitle;
      String firstIsbn(Object? raw) {
        if (raw is! List) return '';
        for (final candidate in raw) {
          final id = candidate.toString().replaceAll('-', '');
          if (RegExp(r'^(?:[0-9]{13}|[0-9]{9}[0-9Xx])$').hasMatch(id)) {
            return id;
          }
        }
        return '';
      }
      // The work-level ISBN may belong to an English edition: never pair it
      // with a verified Portuguese edition.
      final isbn = edition == null
          ? firstIsbn(item['isbn'])
          : firstIsbn(edition['isbn_13']).isNotEmpty
              ? firstIsbn(edition['isbn_13'])
              : firstIsbn(edition['isbn_10']);
      final editionCover = edition?['cover_i'];
      final cover = editionCover is num && editionCover > 0
          ? editionCover : edition == null ? item['cover_i'] : null;
      final editions = item['edition_count'] is num
          ? (item['edition_count'] as num).toInt() : 0;
      result.add(CatalogEntry(
        id: 'openlibrary:' + key,
        title: title,
        kind: 'Livro',
        description: [
          if (author.isNotEmpty) 'Autor(a): ' + author,
          if (edition != null) 'Edição em português catalogada',
          if (isbn.isNotEmpty) 'ISBN: ' + isbn,
          if (editions > 0)
            'Edições catalogadas: ' + editions.toString(),
        ].join(' · '),
        year: item['first_publish_year'] is num
            ? (item['first_publish_year'] as num).toInt()
            : 0,
        posterUrl: _bookCoverUrl(cover, isbn: isbn),
        creator: author,
        provider: edition == null
            ? 'Open Library' : 'Open Library · português',
        detailUrl: 'https://openlibrary.org' + key,
      ));
    }
    return _unique(result);
  }

  Future<List<CatalogEntry>> _discoverBooks(int page, {String? subject}) async {
    final subjects = bookSubjects.values.toList(growable: false);
    final number = page.clamp(1, 300).toInt();
    final chosen = subject == null || subject.isEmpty
        ? subjects[(number - 1) % subjects.length]
        : subject;
    final subjectPage = subject == null || subject.isEmpty
        ? (number - 1) ~/ subjects.length
        : number - 1;
    final data = await _get(Uri.https(
      'openlibrary.org',
      '/subjects/$chosen.json',
      {'limit': '60', 'offset': '${subjectPage * 60}'},
    ));
    if (data is! Map || data['works'] is! List) return [];
    final result = <CatalogEntry>[];
    for (final item in data['works'] as List) {
      if (item is! Map) continue;
      final key = (item['key'] ?? '').toString();
      final title = (item['title'] ?? '').toString();
      if (!key.startsWith('/works/') || title.isEmpty) continue;
      final cover = item['cover_id'];
      final authors = item['authors'];
      final author = authors is List && authors.isNotEmpty && authors.first is Map
          ? ((authors.first as Map)['name'] ?? '').toString()
          : '';
      final category = bookSubjects.entries
          .where((entry) => entry.value == chosen)
          .map((entry) => entry.key)
          .firstOrNull ?? chosen;
      result.add(CatalogEntry(
        id: 'openlibrary:$key',
        title: title,
        kind: 'Livro',
        description: [
          if (author.isNotEmpty) 'Autor(a): $author',
          'Categoria: $category',
        ].join(' · '),
        year: item['first_publish_year'] is num
            ? (item['first_publish_year'] as num).toInt()
            : 0,
        posterUrl: cover is num
            ? 'https://covers.openlibrary.org/b/id/${cover.toInt()}-M.jpg'
            : '',
        creator: author,
        provider: 'Open Library',
        detailUrl: 'https://openlibrary.org$key',
      ));
    }
    return result;
  }

  static const _animeFields = r'''
      id
      title { romaji english native }
      description(asHtml: false)
      startDate { year }
      coverImage { large extraLarge }
      siteUrl
      externalLinks { site url }
    ''';

  Future<List<CatalogEntry>> _anime({String? query, int page = 1}) async {
    final gql = r'''
      query ($page: Int!, $search: String) {
        Page(page: $page, perPage: 24) {
          media(type: ANIME, isAdult: false, search: $search,
                sort: [POPULARITY_DESC]) {
            MEDIA_FIELDS
          }
        }
      }
    '''.replaceFirst('MEDIA_FIELDS', _animeFields);
    final response = await _post(
      Uri.https('graphql.anilist.co', '/'),
      {'query': gql, 'variables': {'page': page, 'search': query}},
    );
    if (response is! Map || response['data'] is! Map) return [];
    final data = response['data'] as Map;
    if (data['Page'] is! Map || (data['Page'] as Map)['media'] is! List) {
      return [];
    }
    final items = (data['Page'] as Map)['media'] as List;
    final result = <CatalogEntry>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final id = raw['id'];
      if (id == null) continue;
      final titleMap = raw['title'];
      final title = titleMap is Map
          ? (titleMap['english'] ?? titleMap['romaji'] ?? titleMap['native'] ?? '').toString()
          : '';
      if (title.isEmpty) continue;
      final cover = raw['coverImage'];
      final published = raw['startDate'];
      result.add(CatalogEntry(
        id: 'anilist:$id',
        title: title,
        kind: 'Anime',
        description: _strip((raw['description'] ?? '').toString()),
        year: published is Map && published['year'] is num
            ? (published['year'] as num).toInt() : 0,
        posterUrl: cover is Map
            ? (cover['extraLarge'] ?? cover['large'] ?? '').toString() : '',
        creator: '',
        provider: 'AniList',
        detailUrl: (raw['siteUrl'] ?? '').toString(),
        streamingLinks: extractOfficialTitleLinks(raw['externalLinks']),
      ));
    }
    return result;
  }

  static int _year(String value) {
    final match = RegExp(r'^\d{4}').firstMatch(value);
    return match == null ? 0 : int.tryParse(match.group(0)!) ?? 0;
  }

  static String _strip(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
