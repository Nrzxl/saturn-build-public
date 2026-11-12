import 'dart:convert';

import 'package:http/http.dart' as http;

/// Read-only TMDB snapshots published by SATURN's private CI.
/// The TMDB API secret never travels to mobile clients.
/// Each response is an attributed snapshot, not live availability.
class TmdbCatalogData {
  static const String baseUrl =
      'https://raw.githubusercontent.com/Nrzxl/saturn-downloads/main/catalog/v1';
  static const groups = ['movies', 'series', 'dramas', 'anime'];

  final http.Client client;
  final String base;
  final Map<String, Future<List<Map<String, dynamic>>>> _cache = {};
  Future<Map<String, String>>? _backdropFallback;

  TmdbCatalogData(this.client, {this.base = baseUrl});

  /// Small public, exact-ID artwork index for old snapshots. This does not
  /// change saved ratings, personal data or the main TMDB catalog.
  Future<Map<String, String>> _loadBackdropFallback() {
    return _backdropFallback ??= () async {
      try {
        final response = await client.get(
          Uri.parse('$base/backdrops-fallback.json'),
          headers: const {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) return <String, String>{};
        final doc = jsonDecode(utf8.decode(response.bodyBytes));
        if (doc is! Map || doc['schema'] != 1 ||
            doc['country'] != 'BR' || doc['overrides'] is! Map) {
          return <String, String>{};
        }
        final rows = doc['overrides'] as Map;
        final ids = RegExp(r'^tmdb:(movie|tv):[0-9]+$');
        final images = RegExp(
          r'^https://image\.tmdb\.org/t/p/(w1280|original)/[A-Za-z0-9_./-]+\.(jpg|jpeg|png|webp)$',
        );
        return <String, String>{
          for (final row in rows.entries)
            if (row.key is String && row.value is String &&
                ids.hasMatch(row.key as String) &&
                images.hasMatch(row.value as String))
              row.key as String: row.value as String,
        };
      } catch (_) {
        return <String, String>{};
      }
    }();
  }

  /// Real background by catalog ID; direct TMDB art wins over rescue data.
  Future<String?> backdropForId(String id) async {
    if (!RegExp(r'^tmdb:(movie|tv):[0-9]+$').hasMatch(id)) return null;
    try {
      final row = await findById(id);
      final panorama = (row?['backdropUrl'] ?? '').toString();
      if (panorama.isNotEmpty) return panorama;
    } catch (_) {
      // Rescue art remains available when the main snapshot cannot load.
    }
    return (await _loadBackdropFallback())[id];
  }

  Future<List<Map<String, dynamic>>> load(String group) async {
    if (!groups.contains(group)) return [];
    try {
      final entries = await _cache.putIfAbsent(group, () async {
      final response = await client.get(
        Uri.parse('$base/$group.json'),
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final parsed = jsonDecode(utf8.decode(response.bodyBytes));
      if (parsed is! Map ||
          parsed['schema'] != 1 ||
          parsed['country'] != 'BR' ||
          parsed['results'] is! List) {
        return [];
      }
      final results = parsed['results'] as List;
      return [
        for (final record in results)
          if (record is Map && record['id'] is String &&
              (record['id'] as String).startsWith('tmdb:'))
            {
              ...Map<String, dynamic>.from(record),
              'generatedAt': (parsed['generatedAt'] ?? '').toString(),
            },
      ];
      });
      // A missing/empty feed can become available after its first publish.
      // Do not permanently cache a 404 in an already-open application.
      if (entries.isEmpty) _cache.remove(group);
      return entries;
    } catch (_) {
      _cache.remove(group);
      rethrow;
    }
  }

  /// Direct exact-ID lookup: a saved title may be on page 100 of discovery.
  /// Search by title and take(36) could otherwise hide its online ratings.
  Future<Map<String, dynamic>?> findById(String id) async {
    final categories = id.startsWith('tmdb:movie:')
        ? ['movies']
        : id.startsWith('tmdb:tv:')
            ? ['series', 'dramas', 'anime']
            : const <String>[];
    if (categories.isEmpty) return null;
    final groups = await Future.wait(categories.map(load));
    for (final group in groups) {
      for (final entry in group) {
        if (entry['id'] == id) return entry;
      }
    }
    return null;
  }

  /// A snapshot can be several thousand titles. It stays in memory for
  /// the session, and never modifies ratings or the saved watchlist.
  Future<List<Map<String, dynamic>>> query({
    required String filter,
    required String search,
    required int page,
    String? streaming,
    int? genreId,
    int rotationSeed = 0,
    int perPage = 36,
  }) async {
    final categories = switch (filter) {
      'movies' => ['movies'],
      'series' => ['series'],
      'dramas' => ['dramas'],
      'anime' => ['anime'],
      'books' => <String>[],
      _ => groups,
    };
    if (categories.isEmpty) return [];

    final lists = await Future.wait(
      categories.map((category) => load(category)),
    );
    final unique = <String, Map<String, dynamic>>{};
    for (final list in lists) {
      for (final record in list) {
        unique.putIfAbsent(record['id'] as String, () => record);
      }
    }
    final wanted = _normal(search);
    final selected = unique.values.where((record) {
      if (streaming != null && streaming.isNotEmpty) {
        final providers = record['streamingProviders'];
        if (providers is! Map || !providers.containsKey(streaming)) {
          return false;
        }
      }
      if (genreId != null) {
        final genres = record['genreIds'];
        if (genres is! List ||
            !genres.any((value) => _genreMatches(genreId, value))) {
          return false;
        }
      }
      if (wanted.isEmpty) return true;
      final aliases = record['aliases'];
      final full = _normal([
        record['title'] ?? '',
        record['originalTitle'] ?? '',
        if (aliases is List) ...aliases,
      ].join(' '));
      // Compatibility for the user's validated bilingual title while the
      // refreshed translated-title index is being republished.
      const knownPairs = <String, String>{
        'she was pretty': 'ela era bonita',
        'ela era bonita': 'she was pretty',
      };
      final alternative = knownPairs[wanted];
      return full.contains(wanted) ||
          (alternative != null && full.contains(alternative));
    }).toList();

    if (wanted.isEmpty) {
      selected.sort((a, b) => ((b['popularity'] as num?) ?? 0)
          .compareTo((a['popularity'] as num?) ?? 0));
    } else {
      selected.sort((a, b) {
        final ax = _normal((a['title'] ?? '').toString());
        final bx = _normal((b['title'] ?? '').toString());
        final aExact = ax == wanted ? 1 : 0;
        final bExact = bx == wanted ? 1 : 0;
        if (aExact != bExact) return bExact.compareTo(aExact);
        return ((b['popularity'] as num?) ?? 0)
            .compareTo((a['popularity'] as num?) ?? 0);
      });
    }

    // Each fresh Explore visit starts at a different place within a stable
    // popularity-ranked discovery window. The seed stays fixed across pages.
    if (wanted.isEmpty && rotationSeed != 0 && selected.length > perPage) {
      final window = selected.length < 360 ? selected.length : 360;
      final offset = rotationSeed.abs() % window;
      final front = [...selected.sublist(offset, window),
        ...selected.sublist(0, offset)];
      selected.setRange(0, window, front);
    }
    final offset = (page.clamp(1, 500).toInt() - 1) * perPage;
    if (offset >= selected.length) return [];
    return selected.skip(offset).take(perPage).toList(growable: false);
  }

  static bool _genreMatches(int selected, Object? actual) {
    if (actual is! num) return false;
    final id = actual.toInt();
    // TMDB uses different IDs for certain movie and television genres.
    const aliases = <int, List<int>>{
      28: [28, 10759], 12: [12, 10759],
      14: [14, 10765], 878: [878, 10765],
      10749: [10749, 10766],
      10751: [10751],
      53: [53, 10759],
    };
    return (aliases[selected] ?? [selected]).contains(id);
  }

  static String _normal(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const into = 'aaaaaeeeeiiiiooooouuuucn';
    var text = value.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      text = text.replaceAll(from[i], into[i]);
    }
    return text.replaceAll(RegExp(r'[^a-z0-9\u0080-\uFFFF]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
