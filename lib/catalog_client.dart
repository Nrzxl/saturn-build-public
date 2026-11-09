import 'dart:convert';

import 'package:http/http.dart' as http;
import 'streaming_links.dart';
import 'tmdb_catalog_data.dart';

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
      requests.add(safe('livros',
          () => _books(query, page: p, subject: bookSubject)));
    }

    if (requests.isEmpty) return [];
    final groups = await Future.wait(requests);
    final works = _unique(groups.expand((items) => items));
    if (works.isEmpty && errors.isNotEmpty) {
      throw StateError('Não foi possível consultar ${errors.join(', ')}. Tente novamente.');
    }
    return works;
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
    }

    final groups = await Future.wait(requests);
    final works = _unique(groups.expand((items) => items));
    if (works.isEmpty && errors.isNotEmpty) {
      throw StateError('Sem acesso aos catálogos (${errors.join(', ')}). Verifique a rede.');
    }
    return works;
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

  Future<List<CatalogEntry>> _books(
    String query, {
    int page = 1,
    String? subject,
  }) async {
    final clean = query.trim();
    final search = (subject == null || subject.isEmpty)
        ? clean
        : '$clean subject:$subject';
    final data = await _get(Uri.https('openlibrary.org', '/search.json', {
      'q': search,
      'limit': '60',
      'page': '${page.clamp(1, 150)}',
      'fields': 'key,title,author_name,cover_i,first_publish_year,'
          'isbn,edition_count,language',
    }));
    if (data is! Map || data['docs'] is! List) return [];
    final result = <CatalogEntry>[];
    for (final item in data['docs'] as List) {
      if (item is! Map) continue;
      final key = (item['key'] ?? '').toString();
      final title = (item['title'] ?? '').toString();
      if (key.isEmpty || title.isEmpty || !key.startsWith('/works/')) continue;
      final authors = item['author_name'];
      final author = authors is List && authors.isNotEmpty
          ? authors.first.toString() : '';
      final rawIsbns = item['isbn'];
      final isbn = rawIsbns is List
          ? rawIsbns.map((id) => id.toString()).firstWhere(
              (id) => RegExp(r'^[0-9Xx-]{10,17}$').hasMatch(id),
              orElse: () => '',
            )
          : '';
      final editions = item['edition_count'] is num
          ? (item['edition_count'] as num).toInt() : 0;
      final cover = item['cover_i'];
      result.add(CatalogEntry(
        id: 'openlibrary:$key',
        title: title,
        kind: 'Livro',
        description: [
          if (author.isNotEmpty) 'Autor(a): $author',
          if (isbn.isNotEmpty) 'ISBN: $isbn',
          if (editions > 0) 'Edições catalogadas: $editions',
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
