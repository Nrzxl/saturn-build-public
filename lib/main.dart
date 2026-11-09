import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog_client.dart';
import 'streaming_preferences.dart';
import 'streaming_links.dart';
import 'saturn_star_rating.dart';
import 'saturn_share.dart';
import 'saturn_trailer.dart';
import 'saturn_native_trailer.dart';
import 'saturn_orbit_cloud.dart';
import 'saturn_orbit_merge.dart';
import 'saturn_orbit_sync_sheet.dart';
import 'saturn_premium_details.dart';
import 'saturn_book_details.dart';
import 'update_center.dart';

bool _saturnCloudReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SaturnCloudConfig.enabled) {
    try {
      await Supabase.initialize(
        url: SaturnCloudConfig.url,
        publishableKey: SaturnCloudConfig.publishableKey,
      );
      _saturnCloudReady = true;
    } catch (_) {
      // Never prevent access to the existing offline library.
      _saturnCloudReady = false;
    }
  }
  runApp(const SaturnApp());
}

const night = Color(0xFF101018);
const wine = Color(0xFF491D30);
const gold = Color(0xFFC6A477);
const ivory = Color(0xFFF2E8DF);

class Work {
  final String id, title, kind, description;
  final int year;
  final String posterUrl, creator, provider, detailUrl;
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
  final String availabilityUpdatedAt;
  final bool availabilityChecked;

  const Work(this.id, this.title, this.kind, this.description, this.year,
      {this.posterUrl = '', this.creator = '', this.provider = '',
       this.detailUrl = '', this.streamingLinks = const {},
       this.streamingProviders = const {}, this.watchProviders = const [],
       this.watchUrl = '', this.trailerYoutubeId = '',
       this.nativeTrailerUrl = '',
       this.genreIds = const [], this.externalRatings = const {},
       this.tmdbScore, this.tmdbVoteCount,
       this.availabilityUpdatedAt = '',
       this.availabilityChecked = false});

  factory Work.fromCatalog(CatalogEntry entry) => Work(
        entry.id, entry.title, entry.kind, entry.description, entry.year,
        posterUrl: entry.posterUrl, creator: entry.creator,
        provider: entry.provider, detailUrl: entry.detailUrl,
        streamingLinks: entry.streamingLinks,
        streamingProviders: entry.streamingProviders,
        watchProviders: entry.watchProviders,
        genreIds: entry.genreIds,
        externalRatings: entry.externalRatings,
        tmdbScore: entry.tmdbScore,
        tmdbVoteCount: entry.tmdbVoteCount,
        watchUrl: entry.watchUrl,
        trailerYoutubeId: entry.trailerYoutubeId,
        nativeTrailerUrl: entry.nativeTrailerUrl,
        availabilityChecked: entry.availabilityChecked,
        availabilityUpdatedAt: entry.availabilityUpdatedAt,
      );

  factory Work.fromJson(Map<String, dynamic> data) => Work(
        (data['id'] ?? '').toString(),
        (data['title'] ?? '').toString(),
        (data['kind'] ?? '').toString(),
        (data['description'] ?? '').toString(),
        data['year'] is num ? (data['year'] as num).toInt() : 0,
        posterUrl: (data['posterUrl'] ?? '').toString(),
        creator: (data['creator'] ?? '').toString(),
        provider: (data['provider'] ?? '').toString(),
        detailUrl: (data['detailUrl'] ?? '').toString(),
        streamingLinks: data['streamingLinks'] is Map
            ? (data['streamingLinks'] as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()))
            : const {},
        streamingProviders: data['streamingProviders'] is Map
            ? (data['streamingProviders'] as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()))
            : const {},
        genreIds: data['genreIds'] is List
            ? (data['genreIds'] as List).whereType<num>()
                .map((n) => n.toInt()).toList(growable: false)
            : const [],
        externalRatings: data['externalRatings'] is Map
            ? (data['externalRatings'] as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()))
            : const {},
        tmdbScore: data['tmdbScore'] is num
            ? (data['tmdbScore'] as num).toDouble() : null,
        tmdbVoteCount: data['tmdbVoteCount'] is num
            ? (data['tmdbVoteCount'] as num).toInt() : null,
        watchProviders: data['watchProviders'] is List
            ? (data['watchProviders'] as List).map(
                (value) => value.toString()).toList(growable: false)
            : const [],
        watchUrl: (data['watchUrl'] ?? '').toString(),
        trailerYoutubeId: (data['trailerYoutubeId'] ?? '').toString(),
        nativeTrailerUrl: (data['nativeTrailerUrl'] ?? '').toString(),
        availabilityChecked: data['availabilityChecked'] == true,
        availabilityUpdatedAt:
            (data['availabilityUpdatedAt'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'kind': kind,
        'description': description, 'year': year,
        'posterUrl': posterUrl, 'creator': creator,
        'provider': provider, 'detailUrl': detailUrl,
        'streamingLinks': streamingLinks,
        'streamingProviders': streamingProviders,
        'genreIds': genreIds,
        'externalRatings': externalRatings,
        'tmdbScore': tmdbScore,
        'tmdbVoteCount': tmdbVoteCount,
        'watchProviders': watchProviders,
        'watchUrl': watchUrl,
        'trailerYoutubeId': trailerYoutubeId,
        'nativeTrailerUrl': nativeTrailerUrl,
        'availabilityChecked': availabilityChecked,
        'availabilityUpdatedAt': availabilityUpdatedAt,
      };
}

// Catálogo inicial demonstrativo: dados locais, sem API ou disponibilidade de streaming.
const works = <Work>[
  Work('movie_interstellar', 'Interestelar', 'Filme',
      'Uma jornada espacial sobre tempo, amor e sobrevivência.', 2014),
  Work('movie_pride', 'Orgulho e Preconceito', 'Filme',
      'Uma história de encontros, diferenças e afeto.', 2005),
  Work('series_dark', 'Dark', 'Série',
      'Um mistério que atravessa gerações.', 2017),
  Work('series_anne', 'Anne with an E', 'Série',
      'Imaginação e descobertas em uma nova família.', 2017),
  Work('book_pride', 'Orgulho e Preconceito', 'Livro',
      'Romance clássico de Jane Austen.', 1813),
  Work('book_dune', 'Duna', 'Livro',
      'Intrigas e destinos no planeta Arrakis.', 1965),
];

class SaturnApp extends StatelessWidget {
  const SaturnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SATURN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: night,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: Color(0xFF9D536B),
          surface: Color(0xFF201820),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: night,
          foregroundColor: ivory,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF251B24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'serif',
            color: ivory,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const SaturnHome(),
    );
  }
}

class SaturnHome extends StatefulWidget {
  const SaturnHome({super.key});

  @override
  State<SaturnHome> createState() => _SaturnHomeState();
}

class _SaturnHomeState extends State<SaturnHome>
    with WidgetsBindingObserver {
  int tab = 0;
  int profile = 0;
  Map<String, dynamic> records = {};
  Map<String, dynamic> _watchlistOps = {};
  Map<String, dynamic> _sharedOps = {};
  Map<String, dynamic> _archivedOps = {};
  SaturnOrbitCloud? _cloud;
  bool _cloudApplying = false;
  List<String> shared = [];
  Map<String, Work> savedWorks = {};
  Set<String> _archivedFromCollection = <String>{};
  bool _selectingWorks = false;
  final Set<String> _selectedWorkIds = <String>{};
  Map<String, Map<String, String>> customTitleLinks = {};
  List<Work> get allWorks => {
    for (final work in works) work.id: work,
    ...savedWorks,
  }.values.toList(growable: false);
  Map<int, Set<String>> watchlists = {0: <String>{}, 1: <String>{}};
  Set<String> get currentWatchlist =>
      watchlists.putIfAbsent(profile, () => <String>{});
  final CatalogClient _homeCatalog = CatalogClient();
  List<Work> recommendedMovies = [];
  List<Work> recommendedBooks = [];
  bool loadingRecommendations = false;
  int _filmRecommendationPage = 0;
  final profiles = ['Eu', 'Ela'];
  Set<StreamingService> _streaming = {...defaultStreamingServices};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_saturnCloudReady) {
      _cloud = SaturnOrbitCloud(
        readLocal: _orbitDocument,
        apply: _applyOrbitDocument,
        onStatus: () {
          if (mounted) setState(() {});
        },
      );
    }
    _load().then((_) => _tryResumeOrbit());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadHomeRecommendations(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cloud?.scheduleSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cloud?.dispose();
    _homeCatalog.close();
    super.dispose();
  }

  Future<void> _loadHomeRecommendations({bool refreshMovies = false}) async {
    if (loadingRecommendations || !mounted) return;
    setState(() => loadingRecommendations = true);
    try {
      if (refreshMovies || recommendedMovies.isEmpty) {
        final nextPage = refreshMovies ? _filmRecommendationPage + 1 : 1;
        final films = await _homeCatalog.discover(
          CatalogFilter.movies, page: nextPage);
        if (!mounted) return;
        setState(() {
          recommendedMovies = films.map(Work.fromCatalog).toList(growable: false);
          _filmRecommendationPage = nextPage;
        });
      }
    } catch (_) {
      // A home continua funcional mesmo sem acesso aos catálogos remotos.
    }
    try {
      if (recommendedBooks.isEmpty) {
        final books = await _homeCatalog.discover(CatalogFilter.books);
        if (!mounted) return;
        setState(() {
          recommendedBooks = books.map(Work.fromCatalog).toList(growable: false);
        });
      }
    } catch (_) {
      // Não substituir livros salvos por conteúdo fictício.
    } finally {
      if (mounted) setState(() => loadingRecommendations = false);
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    try {
      final storedRecords = jsonDecode(prefs.getString('records') ?? '{}');
      final storedWatchOps =
          jsonDecode(prefs.getString('saturn_watchlist_ops') ?? '{}');
      final storedSharedOps =
          jsonDecode(prefs.getString('saturn_shared_ops') ?? '{}');
      final storedArchivedOps =
          jsonDecode(prefs.getString('saturn_archived_ops') ?? '{}');
      final savedProfile = prefs.getInt('saturn_profile_index') ?? 0;
      final archived = prefs.getStringList('saturn_archived_v1') ?? <String>[];
      final storedShared = jsonDecode(prefs.getString('shared') ?? '[]');
      final storedCatalog = jsonDecode(prefs.getString('catalog_saved') ?? '{}');
      final savedStreaming = prefs.getStringList('streaming_services');
      final storedWatchlists =
          jsonDecode(prefs.getString('watchlist_v1') ?? '{}');
      final storedTitleLinks =
          jsonDecode(prefs.getString('custom_title_links') ?? '{}');
      setState(() {
        records = Map<String, dynamic>.from(storedRecords as Map);
        shared = List<String>.from(storedShared as List);
        profile = savedProfile.clamp(0, profiles.length - 1).toInt();
        _archivedFromCollection = archived.toSet();
        _archivedOps = storedArchivedOps is Map
            ? Map<String, dynamic>.from(storedArchivedOps)
            : <String, dynamic>{};
        for (final id in archived) {
          _archivedOps.putIfAbsent(id, () => {
            'present': true, 'updatedAt': 0,
          });
        }
        _watchlistOps = storedWatchOps is Map
            ? Map<String, dynamic>.from(storedWatchOps)
            : <String, dynamic>{};
        _sharedOps = storedSharedOps is Map
            ? Map<String, dynamic>.from(storedSharedOps)
            : <String, dynamic>{};
        _streaming = decodeStreamingPreferences(savedStreaming);
        if (storedWatchlists is Map) {
          watchlists = {
            for (var i = 0; i < profiles.length; i++)
              i: storedWatchlists['$i'] is List
                  ? Set<String>.from(storedWatchlists['$i'] as List)
                  : <String>{},
          };
        }
        customTitleLinks = (storedTitleLinks as Map).map(
          (id, links) => MapEntry(id.toString(),
            (links as Map).map((key, value) => MapEntry(
              key.toString(), value.toString()))),
        );
        savedWorks = (storedCatalog as Map).map((key, value) =>
          MapEntry(key.toString(), Work.fromJson(Map<String, dynamic>.from(value as Map))));
        for (final index in watchlists.keys) {
          final previous = SaturnOrbitMerge.flagFromLegacyList(
            watchlists[index] ?? <String>{},
            prefix: '$index:',
          );
          for (final entry in previous.entries) {
            _watchlistOps.putIfAbsent(entry.key, () => entry.value);
          }
        }
        final oldShared = SaturnOrbitMerge.flagFromLegacyList(shared);
        for (final entry in oldShared.entries) {
          _sharedOps.putIfAbsent(entry.key, () => entry.value);
        }
      });
    } catch (_) {
      // Não destruir dados existentes caso o armazenamento local esteja corrompido.
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('records', jsonEncode(records));
    await prefs.setString('shared', jsonEncode(shared));
    await prefs.setString('catalog_saved', jsonEncode(savedWorks.map(
        (key, work) => MapEntry(key, work.toJson()))));
    await prefs.setString('custom_title_links', jsonEncode(customTitleLinks));
    await prefs.setString('watchlist_v1', jsonEncode({
      for (final entry in watchlists.entries)
        '${entry.key}': entry.value.toList(growable: false),
    }));
    await prefs.setString('saturn_watchlist_ops', jsonEncode(_watchlistOps));
    await prefs.setString('saturn_shared_ops', jsonEncode(_sharedOps));
    await prefs.setString('saturn_archived_ops', jsonEncode(_archivedOps));
    await prefs.setStringList('saturn_archived_v1',
      _archivedFromCollection.toList(growable: false));
    if (!_cloudApplying) _cloud?.scheduleSync();
  }


  Map<String, dynamic> _orbitDocument() => {
    'schema': 1,
    'records': records,
    'watchlistOps': _watchlistOps,
    'sharedOps': _sharedOps,
    'archivedOps': _archivedOps,
    'catalogSaved': savedWorks.map(
      (key, work) => MapEntry(key, work.toJson())),
    'customTitleLinks': customTitleLinks,
  };

  Future<void> _applyOrbitDocument(Map<String, dynamic> doc) async {
    if (!mounted) return;
    _cloudApplying = true;
    try {
      setState(() {
        records = Map<String, dynamic>.from(doc['records'] as Map? ?? {});
        _watchlistOps = Map<String, dynamic>.from(
          doc['watchlistOps'] as Map? ?? {});
        _sharedOps = Map<String, dynamic>.from(
          doc['sharedOps'] as Map? ?? {});
        _archivedOps = Map<String, dynamic>.from(
          doc['archivedOps'] as Map? ?? {});
        _archivedFromCollection =
            SaturnOrbitMerge.activeFlags(_archivedOps).toSet();
        watchlists = {
          for (var index = 0; index < profiles.length; index++)
            index: SaturnOrbitMerge.activeFlags(
              _watchlistOps, prefix: '$index:').toSet(),
        };
        shared = SaturnOrbitMerge.activeFlags(_sharedOps);
        final stored = doc['catalogSaved'];
        if (stored is Map) {
          savedWorks = {
            for (final entry in stored.entries)
              if (entry.value is Map)
                entry.key.toString(): Work.fromJson(
                    Map<String, dynamic>.from(entry.value as Map)),
          };
        }
        final links = doc['customTitleLinks'];
        if (links is Map) {
          customTitleLinks = {
            for (final entry in links.entries)
              if (entry.value is Map)
                entry.key.toString(): (entry.value as Map).map(
                  (key, value) =>
                      MapEntry(key.toString(), value.toString())),
          };
        }
      });
      await _save();
    } finally {
      _cloudApplying = false;
    }
  }

  Future<void> _tryResumeOrbit() async {
    final cloud = _cloud;
    if (!mounted || cloud == null || !cloud.signedIn) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final prior = prefs.getString('saturn_orbit_id');
      final available = await cloud.availableOrbits();
      final choice = prior != null && available.contains(prior)
          ? prior
          : available.length == 1 ? available.first : null;
      if (choice != null && mounted) await cloud.attach(choice);
    } catch (_) {
      // No data is deleted if the partner is offline or RLS denies access.
    }
  }

  Future<void> _showOrbitSync() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF201820),
      builder: (context) => SaturnOrbitSyncSheet(cloud: _cloud),
    );
    final cloud = _cloud;
    if (cloud != null && cloud.orbitId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saturn_orbit_id', cloud.orbitId!);
    }
    if (mounted) setState(() {});
  }

  Future<void> _setProfile(int next) async {
    setState(() => profile = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saturn_profile_index', next);
  }

  Future<void> _setStreaming(StreamingService service, bool enabled) async {
    setState(() {
      if (enabled) {
        _streaming.add(service);
      } else {
        _streaming.remove(service);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'streaming_services',
      encodeStreamingPreferences(_streaming),
    );
  }


  Future<void> _openTitleLink(StreamingService service, String url) async {
    final exact = checkedTitleUrl(service, url);
    if (exact == null) return;
    try {
      final opened = await launchUrl(
        Uri.parse(exact), mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir esse título.')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir esse título.')));
    }
  }

  Future<void> _openTmdbWatch(Work work) async {
    final url = work.watchUrl.isNotEmpty ? work.watchUrl : work.detailUrl;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' ||
        uri.host != 'www.themoviedb.org' || uri.userInfo.isNotEmpty) {
      return;
    }
    try {
      final opened = await launchUrl(
        uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
            'Não foi possível abrir as opções de streaming.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao abrir o catálogo TMDB.')));
      }
    }
  }

  Future<void> _openStreamingService(StreamingService service, {String? title}) async {
    try {
      final ok = await launchUrl(
        title == null ? service.uri : officialSearchUri(service, title),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir ${service.label}.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao abrir ${service.label}.')),
      );
    }
  }

  void _showStreamingPreferences() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF251B24),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nossos streamings',
                  style: TextStyle(color: ivory, fontFamily: 'serif',
                    fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Marque os serviços que vocês usam. Essa seleção fica salva '
                  'no aparelho e organiza os atalhos de pesquisa.',
                  style: TextStyle(color: Color(0xFFD1BBC3))),
                const SizedBox(height: 15),
                ...StreamingService.values.map(
                  (service) => SwitchListTile(
                    title: Text(service.label),
                    activeTrackColor: wine,
                    value: _streaming.contains(service),
                    onChanged: (enabled) {
                      _setStreaming(service, enabled);
                      refresh(() {});
                    },
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Os atalhos não confirmam que uma obra esteja disponível '
                  'nesses catálogos. Informações de disponibilidade no Brasil '
                  'serão integradas separadamente.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB9A5AC)),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Concluído'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdates() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF251B24),
      isScrollControlled: true,
      builder: (ctx) => const SaturnUpdateCenter(),
    );
  }

  Map<String, dynamic> entry(Work w) =>
      Map<String, dynamic>.from(records['${profile}:${w.id}'] ?? {});

  bool _isDone(Work w) {
    final state = entry(w)['status'];
    return state == 'Concluído' || state == 'Assistido' || state == 'Lido';
  }

  bool _isWatchlisted(Work w) => currentWatchlist.contains(w.id);

  void _toggleWatchlist(Work w) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      if (!works.any((old) => old.id == w.id)) savedWorks[w.id] = w;
      if (!currentWatchlist.add(w.id)) currentWatchlist.remove(w.id);
      _watchlistOps['$profile:${w.id}'] = {
        'present': currentWatchlist.contains(w.id),
        'updatedAt': stamp,
      };
    });
    _save();
  }

  void _toggleCompleted(Work w) {
    final old = entry(w);
    final done = _isDone(w);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      if (!works.any((other) => other.id == w.id)) savedWorks[w.id] = w;
      _archivedFromCollection.remove('${profile}:${w.id}');
      _archivedOps['${profile}:${w.id}'] = {
        'present': false, 'updatedAt': stamp,
      };
      records['${profile}:${w.id}'] = {
        ...old,
        'status': done ? 'Em andamento' : 'Concluído',
        'updatedAt': stamp,
      };
      if (!done) {
        currentWatchlist.remove(w.id);
        _watchlistOps['$profile:${w.id}'] = {
          'present': false, 'updatedAt': stamp,
        };
      }
    });
    _save();
  }

  String _statusLabel(Work w) {
    final state = entry(w)['status'];
    if (state == 'Concluído' || state == 'Assistido' || state == 'Lido') {
      return w.kind == 'Livro' ? 'Lido' : 'Assistido';
    }
    return state?.toString() ?? '';
  }

  void update(Work w, Map<String, dynamic> value) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      if (!works.any((old) => old.id == w.id)) savedWorks[w.id] = w;
      _archivedFromCollection.remove('${profile}:${w.id}');
      _archivedOps['${profile}:${w.id}'] = {
        'present': false, 'updatedAt': stamp,
      };
      records['${profile}:${w.id}'] = {
        ...value, 'updatedAt': stamp,
      };
      if (value['status'] == 'Concluído') {
        currentWatchlist.remove(w.id);
        _watchlistOps['$profile:${w.id}'] = {
          'present': false, 'updatedAt': stamp,
        };
      }
    });
    _save();
  }

  void toggleShared(Work w) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      if (!works.any((old) => old.id == w.id)) savedWorks[w.id] = w;
      if (shared.contains(w.id)) {
        shared.remove(w.id);
      } else {
        shared.add(w.id);
      }
      _sharedOps[w.id] = {
        'present': shared.contains(w.id),
        'updatedAt': stamp,
      };
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            SaturnMark(size: 34),
            SizedBox(width: 8),
            Text('SATURN',
                style: TextStyle(
                    fontFamily: 'serif', letterSpacing: 3, color: ivory)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sincronizar nossa órbita',
            icon: Icon(
              _cloud?.connected == true
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_sync_outlined,
              color: gold,
            ),
            onPressed: _showOrbitSync,
          ),
          IconButton(
            tooltip: 'Atualizar SATURN',
            icon: const Icon(Icons.system_update_alt_rounded, color: gold),
            onPressed: _showUpdates,
          ),
          PopupMenuButton<int>(
            tooltip: 'Trocar perfil demonstrativo',
            initialValue: profile,
            onSelected: _setProfile,
            itemBuilder: (context) => [
              for (var i = 0; i < profiles.length; i++)
                PopupMenuItem(
                    value: i, child: Text('Perfil: ${profiles[i]}')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Chip(label: Text(profiles[profile])),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (desktop) ...[
              NavigationRail(
                backgroundColor: const Color(0xFF17121B),
                indicatorColor: wine,
                selectedIconTheme: const IconThemeData(color: gold),
                unselectedIconTheme: const IconThemeData(
                  color: Color(0xFFBDA9B5)),
                selectedLabelTextStyle: const TextStyle(
                  color: ivory, fontSize: 12),
                unselectedLabelTextStyle: const TextStyle(
                  color: Color(0xFFBDA9B5), fontSize: 12),
                labelType: NavigationRailLabelType.all,
                selectedIndex: tab,
                onDestinationSelected: (value) => setState(() => tab = value),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined), label: Text('Início')),
                  NavigationRailDestination(
                    icon: Icon(Icons.search), label: Text('Explorar')),
                  NavigationRailDestination(
                    icon: Icon(Icons.bookmarks_outlined), label: Text('Coleção')),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite_border), label: Text('Nós dois')),
                  NavigationRailDestination(
                    icon: Icon(Icons.bar_chart), label: Text('Dados')),
                ],
              ),
              const VerticalDivider(
                width: 1, thickness: 1, color: Color(0xFF3C2837)),
            ],
            Expanded(
              child: IndexedStack(
                index: tab,
                children: [
                  _start(), _explore(), _collection(), _shared(), _stats(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: desktop ? null : NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Explorar'),
          NavigationDestination(
              icon: Icon(Icons.bookmarks_outlined), label: 'Coleção'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border), label: 'Nós dois'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart), label: 'Dados'),
        ],
      ),
    );
  }

  Widget _heading(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Text(
          label,
          style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 23,
              color: ivory,
              fontWeight: FontWeight.bold),
        ),
      );

  Widget _start() {
    final continuing = allWorks.where(
      (work) => !_isArchived(work) &&
          entry(work)['status'] == 'Em andamento',
    ).toList();
    final ownCount = allWorks.where(
      (work) => !_isArchived(work) &&
          entry(work)['status'] != null,
    ).length;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 26, 20, 25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF56233C), Color(0xFF2B1D31), night],
              ),
              border: Border.all(color: const Color(0x775E4553)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: SaturnMark(size: 89)),
                const SizedBox(height: 14),
                const Center(child: Text(
                  'EVERY STORY HAS ITS ORBIT',
                  style: TextStyle(
                    color: gold, letterSpacing: 2.4, fontSize: 10,
                  ),
                )),
                const SizedBox(height: 24),
                Text('Bem-vinda ao seu universo, ${profiles[profile]}',
                  style: const TextStyle(
                    color: ivory, fontFamily: 'serif',
                    fontSize: 26, fontWeight: FontWeight.bold, height: 1.2,
                  )),
                const SizedBox(height: 8),
                Text('$ownCount histórias na sua coleção • ${shared.length} na nossa órbita',
                  style: const TextStyle(color: Color(0xFFD9C2C7), fontSize: 12)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => setState(() => tab = 1),
                  icon: const Icon(Icons.auto_awesome, size: 17),
                  label: const Text('Descobrir histórias'),
                ),
              ],
            ),
          ),
        ),
        _heading('Minha Watchlist'),
        _collectionSelectionToolbar(
          allWorks.where((w) => currentWatchlist.contains(w.id)),
          watchlist: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '${currentWatchlist.where((id) => allWorks.any(
              (w) => w.id == id && w.kind != 'Livro')).length} '
            'títulos para assistir • perfil ${profiles[profile]}',
            style: const TextStyle(
              color: Color(0xFFD7C0C7), fontSize: 12),
          ),
        ),
        if (!allWorks.any((w) =>
            w.kind != 'Livro' && currentWatchlist.contains(w.id)))
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 9, 18, 5),
            child: Text(
              'Toque em + Watchlist na ficha de um filme, anime, dorama ou série.',
              style: TextStyle(color: Color(0xFFB5A1A9)),
            ),
          ),
        ...allWorks
            .where((w) => w.kind != 'Livro' &&
                currentWatchlist.contains(w.id))
            .take(8)
            .map(_tile),
        _heading('Recomendações de filmes'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'Sugestões reais do catálogo de filmes. Não são '
            'disponibilidades confirmadas por streaming.',
            style: TextStyle(
              fontSize: 12, color: Color(0xFFB5A1A9)),
          ),
        ),
        if (loadingRecommendations && recommendedMovies.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Carregando sugestões de filmes...',
              style: TextStyle(color: Color(0xFFBFAEB8))),
          ),
        ...recommendedMovies
            .where((w) => !_isDone(w) && !currentWatchlist.contains(w.id))
            .take(5)
            .map(_tile),
        if (!loadingRecommendations && recommendedMovies.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sem sugestões no momento. Confira sua conexão.',
              style: TextStyle(color: Color(0xFFB5A1A9))),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: loadingRecommendations
                ? null
                : () => _loadHomeRecommendations(refreshMovies: true),
            icon: const Icon(Icons.casino_outlined, size: 18),
            label: const Text('Outras sugestões'),
          ),
        ),
        _heading('Livros • Minha estante'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'Suas próximas leituras e os livros já registrados.',
            style: TextStyle(
              fontSize: 12, color: Color(0xFFB5A1A9)),
          ),
        ),
        ...allWorks
            .where((w) => w.kind == 'Livro' &&
                (currentWatchlist.contains(w.id) ||
                    entry(w)['status'] != null))
            .take(7)
            .map(_tile),
        if (!allWorks.any((w) => w.kind == 'Livro' &&
            (currentWatchlist.contains(w.id) ||
                entry(w)['status'] != null)))
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 9, 18, 5),
            child: Text('Sua estante está vazia. Adicione um livro para ler.',
              style: TextStyle(color: Color(0xFFB5A1A9))),
          ),
        _heading('Livros para descobrir'),
        if (loadingRecommendations && recommendedBooks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Buscando livros da Open Library...',
              style: TextStyle(color: Color(0xFFB5A1A9))),
          ),
        ...recommendedBooks.take(5).map(_tile),
        if (!loadingRecommendations && recommendedBooks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhum livro carregado agora.',
              style: TextStyle(color: Color(0xFFB5A1A9))),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _openCatalogFilter(CatalogFilter.books),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text('Explorar livros'),
          ),
        ),
        _heading('Continuar de onde parou'),
        if (continuing.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            child: Text('Comece uma leitura ou série e marque como Em andamento.',
              style: TextStyle(color: Color(0xFFB5A1A9))),
          ),
        ...continuing.map(_tile),
        _heading('Nossa órbita ♡'),
        if (shared.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            child: Text('Suas histórias favoritas a dois aparecerão aqui.',
              style: TextStyle(color: Color(0xFFB5A1A9))),
          ),
        ...allWorks.where((work) => shared.contains(work.id)).take(3).map(_tile),
        _heading('Descubra novas histórias'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
          child: TextButton.icon(
            onPressed: () => setState(() => tab = 1),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Abrir o catálogo com capas reais'),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  CatalogFilter _catalogFilter = CatalogFilter.all;

  void _openCatalogFilter(CatalogFilter filter) {
    setState(() {
      _catalogFilter = filter;
      tab = 1;
    });
  }

  Widget _explore() => CatalogExplore(
        active: tab == 1,
        requestedFilter: _catalogFilter,
        onOpen: _details,
        onToggleShared: toggleShared,
        isShared: (work) => shared.contains(work.id),
        onToggleWatchlist: _toggleWatchlist,
        isWatchlisted: _isWatchlisted,
        onToggleCompleted: _toggleCompleted,
        isCompleted: _isDone,
      );

  bool _isArchived(Work work) =>
      _archivedFromCollection.contains('$profile:${work.id}');

  void _beginSelection() => setState(() {
    _selectingWorks = !_selectingWorks;
    if (!_selectingWorks) _selectedWorkIds.clear();
  });

  void _selectAll(Iterable<Work> source) => setState(() {
    _selectedWorkIds
      ..clear()
      ..addAll(source.map((work) => work.id));
  });

  void _applyBulk(String action) {
    if (_selectedWorkIds.isEmpty) return;
    final selected = _selectedWorkIds.toList(growable: false);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      for (final id in selected) {
        final work = allWorks.where((w) => w.id == id).firstOrNull;
        if (work == null) continue;
        final recordId = '$profile:$id';
        switch (action) {
          case 'watched':
            records[recordId] = {
              ...(records[recordId] is Map
                  ? Map<String, dynamic>.from(records[recordId] as Map)
                  : <String, dynamic>{}),
              'status': 'Concluído',
              'updatedAt': stamp,
            };
            currentWatchlist.remove(id);
            _watchlistOps[recordId] = {
              'present': false, 'updatedAt': stamp,
            };
            _archivedFromCollection.remove(recordId);
            _archivedOps[recordId] = {
              'present': false, 'updatedAt': stamp,
            };
          case 'watchlist':
            currentWatchlist.add(id);
            _watchlistOps[recordId] = {
              'present': true, 'updatedAt': stamp,
            };
            _archivedFromCollection.remove(recordId);
            _archivedOps[recordId] = {
              'present': false, 'updatedAt': stamp,
            };
          case 'shared':
            if (!shared.contains(id)) shared.add(id);
            _sharedOps[id] = {
              'present': true, 'updatedAt': stamp,
            };
          case 'remove':
            _archivedFromCollection.add(recordId);
            _archivedOps[recordId] = {
              'present': true, 'updatedAt': stamp,
            };
            currentWatchlist.remove(id);
            _watchlistOps[recordId] = {
              'present': false, 'updatedAt': stamp,
            };
          case 'removeWatchlist':
            currentWatchlist.remove(id);
            _watchlistOps[recordId] = {
              'present': false, 'updatedAt': stamp,
            };
          case 'removeShared':
            shared.remove(id);
            _sharedOps[id] = {
              'present': false, 'updatedAt': stamp,
            };
        }
      }
      _selectingWorks = false;
      _selectedWorkIds.clear();
    });
    _save();
  }

  Widget _collectionSelectionToolbar(Iterable<Work> source,
      {bool sharedList = false, bool watchlist = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8, runSpacing: 6, children: [
          OutlinedButton.icon(
            onPressed: _beginSelection,
            icon: Icon(_selectingWorks
                ? Icons.close_rounded : Icons.library_add_check_outlined),
            label: Text(_selectingWorks ? 'Cancelar' : 'Selecionar vários'),
          ),
          if (_selectingWorks) ...[
            Text('${_selectedWorkIds.length} selecionados',
              style: const TextStyle(color: gold, fontSize: 12)),
            TextButton(
              onPressed: () => _selectAll(source),
              child: const Text('Selecionar tudo'),
            ),
            PopupMenuButton<String>(
              enabled: _selectedWorkIds.isNotEmpty,
              tooltip: 'Aplicar em lote',
              onSelected: _applyBulk,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'watched', child: Text('Marcar assistidos / lidos')),
                const PopupMenuItem(
                  value: 'watchlist', child: Text('Adicionar à Watchlist')),
                const PopupMenuItem(
                  value: 'shared', child: Text('Adicionar à Nossa Órbita')),
                PopupMenuItem(
                  value: sharedList ? 'removeShared'
                      : watchlist ? 'removeWatchlist' : 'remove',
                  child: Text(sharedList
                      ? 'Remover de Nossa Órbita'
                      : watchlist ? 'Remover da Watchlist'
                      : 'Remover da minha coleção'),
                ),
              ],
              child: Chip(
                label: const Text('Ações em massa'),
                avatar: const Icon(Icons.more_horiz_rounded, size: 18),
                backgroundColor: wine,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _collection() {
    final items = allWorks.where((w) =>
        entry(w)['status'] != null && !_isArchived(w)).toList();
    return ListView(children: [
      _heading('Minha coleção'),
      _collectionSelectionToolbar(items),
      ...items.map(_tile),
      if (items.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sua coleção está vazia. Explore e escolha um título.'),
        ),
    ]);
  }

  Widget _shared() {
    final items = allWorks.where((w) => shared.contains(w.id)).toList();
    return ListView(children: [
      _heading('Nossa órbita ♡'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          _cloud?.connected == true
              ? 'Nossa coleção compartilhada entre os aparelhos conectados.'
              : 'Coleção de vocês neste aparelho. Ative a nuvem para '
                'sincronizar Android e iPhone.',
          style: const TextStyle(color: Color(0xFFD6C4CE)),
        ),
      ),
      _collectionSelectionToolbar(items, sharedList: true),
      ...items.map(_tile),
      if (items.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Ainda não há histórias na lista de vocês.'),
        ),
    ]);
  }

  Widget _stats() {
    final rated = allWorks.where((w) =>
        !_isArchived(w) && entry(w)['rating'] != null).toList();
    final average = rated.isEmpty
        ? 0.0
        : rated
                .map((w) => (entry(w)['rating'] as num).toDouble())
                .reduce((a, b) => a + b) /
            rated.length;
    return ListView(
      children: [
        _heading('Seu ano no Saturno'),
        _stat(
            'Obras registradas',
            allWorks
                .where((w) => !_isArchived(w) && entry(w)['status'] != null)
                .length
                .toString()),
        _stat('Avaliações', rated.length.toString()),
        _stat('Média de estrelas', '${(average / 2).toStringAsFixed(1)} ★'),
        _stat('Na lista do casal', shared.length.toString()),
      ],
    );
  }

  Widget _stat(String label, String value) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: ListTile(
          title: Text(label),
          trailing: Text(value,
              style: const TextStyle(color: gold, fontSize: 24)),
        ),
      );

  Widget _tile(Work w) {
    final current = entry(w);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: ListTile(
        leading: _selectingWorks
            ? Checkbox(
                value: _selectedWorkIds.contains(w.id),
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _selectedWorkIds.add(w.id);
                  } else {
                    _selectedWorkIds.remove(w.id);
                  }
                }),
              )
            : PosterThumbnail(work: w),
        title: Text(w.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${w.kind} · ${w.year}${current['status'] != null ? ' · ${_statusLabel(w)}' : ''}${current['rating'] != null ? ' · ★ ${starsFromLegacy(current['rating'] as num).toStringAsFixed(1)}/5' : ''}'),
        trailing: SizedBox(
          width: 102,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: w.kind == 'Livro' ? 'Quero ler' : 'Watchlist',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _toggleWatchlist(w),
                  child: SizedBox(
                    width: 34, height: 44,
                    child: Center(
                      child: Icon(_isWatchlisted(w)
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_add_outlined,
                        size: 20, color: gold),
                    ),
                  ),
                ),
              ),
              Tooltip(
                message: w.kind == 'Livro'
                    ? 'Marcar como lido' : 'Marcar como assistido',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _toggleCompleted(w),
                  child: SizedBox(
                    width: 34, height: 44,
                    child: Center(
                      child: Icon(_isDone(w)
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                        size: 20,
                        color: _isDone(w)
                            ? const Color(0xFF97CDB4) : gold),
                    ),
                  ),
                ),
              ),
              Tooltip(
                message: 'Adicionar à Nossa Órbita',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => toggleShared(w),
                  child: SizedBox(
                    width: 34, height: 44,
                    child: Center(
                      child: Icon(
                        shared.contains(w.id)
                            ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: shared.contains(w.id)
                            ? const Color(0xFFDA728F) : gold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: _selectingWorks
            ? () => setState(() {
                if (!_selectedWorkIds.add(w.id)) {
                  _selectedWorkIds.remove(w.id);
                }
              })
            : () => _details(w),
      ),
    );
  }

  Future<void> _details(Work w) async {
    final current = entry(w);
    String status = current['status'] ?? 'Quero conhecer';
    double rating = (current['rating'] as num?)?.toDouble() ?? 0;
    final notes = TextEditingController(text: current['notes'] ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF201820),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (w.kind != 'Livro' &&
                    SaturnNativeTrailer.canUseNative(
                      w.nativeTrailerUrl,
                      rightsConfirmed: w.provider == 'SATURN Licensed',
                    )) ...[
                  SaturnNativeTrailer(
                    mediaUrl: w.nativeTrailerUrl,
                    rightsConfirmed: true,
                  ),
                  const SizedBox(height: 14),
                ] else if (w.kind != 'Livro' &&
                    w.trailerYoutubeId.isNotEmpty) ...[
                  SaturnTrailerPreview(youtubeId: w.trailerYoutubeId),
                  const SizedBox(height: 14),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x776A4A58)),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF512A42), Color(0xFF241B2A)],
                    ),
                  ),
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: PosterThumbnail(work: w,
                        width: 124, height: 183),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.title, style: const TextStyle(
                            fontFamily: 'serif', fontWeight: FontWeight.bold,
                            fontSize: 26, color: ivory, height: 1.2,
                          )),
                          const SizedBox(height: 9),
                          Text('${w.kind} · ${w.year > 0 ? w.year : 'Ano não informado'}',
                            style: const TextStyle(color: gold)),
                          if (w.creator.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Text(w.creator,
                              style: const TextStyle(fontSize: 12, color: ivory)),
                          ],
                          if (w.provider.isNotEmpty) ...[
                            const SizedBox(height: 9),
                            Text('Catálogo: ${w.provider}',
                              style: const TextStyle(fontSize: 11,
                                color: Color(0xFFBDA9B3))),
                          ],
                        ],
                      ),
                    ),
                  ],
                  ),
                ),
                const SizedBox(height: 12),
                if (w.kind == 'Livro')
                  SaturnBookDetailsPanel(
                    bookId: w.id,
                    fallbackDescription: w.description,
                    fallbackCover: w.posterUrl,
                  )
                else
                  SaturnDetailSection(
                    title: 'A história',
                    icon: Icons.auto_stories_outlined,
                    child: Text(
                      w.description.isEmpty
                        ? 'Sinopse indisponível nesta fonte.'
                        : w.description,
                      style: const TextStyle(
                        color: ivory, height: 1.6, fontSize: 13),
                    ),
                  ),
                if (w.kind != 'Livro')
                  SaturnExternalRatings(
                    ratings: w.externalRatings,
                    tmdbScore: w.tmdbScore,
                    tmdbVoteCount: w.tmdbVoteCount,
                    isBook: false,
                  ),
                const SizedBox(height: 7),
                if (w.creator.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 5, 4, 8),
                    child: Text('Criação / autoria: ${w.creator}',
                      style: const TextStyle(
                        color: Color(0xFFD3BFC7), fontSize: 12)),
                  ),
                const SizedBox(height: 19),
                const Text('MINHAS LISTAS',
                  style: TextStyle(color: gold, fontSize: 11,
                    letterSpacing: 1.8)),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        final done = _isDone(w);
                        _toggleCompleted(w);
                        refresh(() =>
                          status = done ? 'Em andamento' : 'Concluído');
                      },
                      icon: Icon(_isDone(w)
                          ? Icons.check_circle
                          : Icons.check_circle_outline),
                      label: Text(w.kind == 'Livro'
                          ? _isDone(w) ? 'Lido ✓' : 'Marcar como lido'
                          : _isDone(w) ? 'Assistido ✓' : 'Marcar como assistido'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _toggleWatchlist(w);
                        refresh(() {});
                      },
                      icon: Icon(_isWatchlisted(w)
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_add_outlined),
                      label: Text(w.kind == 'Livro'
                          ? _isWatchlisted(w) ? 'Quero ler ✓' : '+ Quero ler'
                          : _isWatchlisted(w) ? 'Na Watchlist ✓' : '+ Watchlist'),
                    ),
                  ],
                ),
                if (w.kind != 'Livro') ...[
                  const SizedBox(height: 21),
                  Row(children: [
                    const Expanded(
                      child: Text('ONDE ASSISTIR · BRASIL',
                        style: TextStyle(color: gold,
                          letterSpacing: 1.5, fontSize: 11)),
                    ),
                    IconButton(
                      tooltip: 'Editar streamings favoritos',
                      onPressed: _showStreamingPreferences,
                      icon: const Icon(Icons.tune, color: gold),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  Text(
                    w.provider == 'TMDB'
                      ? 'Disponibilidade de assinatura no Brasil, via '
                        'TMDB / JustWatch. Catálogo atualizado periodicamente; '
                        'a oferta pode mudar.'
                      : 'Esta fonte não confirma os serviços de assinatura '
                        'no Brasil. Links específicos são mostrados quando '
                        'a fonte os fornece.',
                    style: const TextStyle(
                      color: Color(0xFFCCB6BF), fontSize: 12, height: 1.4),
                  ),
                  if (w.availabilityUpdatedAt.length >= 10) ...[
                    const SizedBox(height: 5),
                    Text('Dados consultados: ${w.availabilityUpdatedAt.substring(0, 10)}',
                      style: const TextStyle(
                        color: Color(0xFFB8A8AC), fontSize: 11)),
                  ],
                  const SizedBox(height: 10),
                  if (w.watchProviders.isNotEmpty) ...[
                    const Text('Plataformas encontradas para assinatura:',
                      style: TextStyle(color: ivory, fontSize: 12)),
                    const SizedBox(height: 7),
                    Wrap(spacing: 6, runSpacing: 3, children: [
                      for (final provider in w.watchProviders)
                        Chip(
                          label: Text(provider, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                    ]),
                    const SizedBox(height: 8),
                  ],
                  if (w.streamingProviders.isEmpty &&
                      w.availabilityChecked)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Nenhuma oferta de assinatura identificada '
                        'no Brasil nesta consulta. '
                        'Isso não significa que a obra nunca estará disponível.',
                        style: TextStyle(color: Color(0xFFC7B8BC), fontSize: 12),
                      ),
                    ),
                  for (final service in StreamingService.values)
                    if (_streaming.contains(service))
                      Builder(builder: (itemContext) {
                        final stored = customTitleLinks[w.id]?[service.name];
                        final sourced = w.streamingLinks[service.name];
                        final direct = checkedTitleUrl(
                          service, stored ?? sourced);
                        final verified =
                            w.streamingProviders.containsKey(service.name);
                        if (w.provider == 'TMDB' &&
                            !verified && direct == null) {
                          return const SizedBox.shrink();
                        }
                        return Card(
                          color: const Color(0xFF30232D),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                            child: Row(children: [
                              Icon(direct != null
                                ? Icons.play_circle_fill_rounded
                                : verified ? Icons.verified_rounded
                                    : Icons.help_outline_rounded,
                                color: verified
                                  ? const Color(0xFF97CDB4) : gold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(service.label,
                                      style: const TextStyle(
                                        color: ivory,
                                        fontWeight: FontWeight.bold)),
                                    Text(
                                      verified
                                        ? 'Assinatura confirmada · Brasil'
                                        : direct != null
                                            ? 'Link específico fornecido pela fonte'
                                            : 'Disponibilidade não confirmada',
                                      style: const TextStyle(
                                        color: Color(0xFFCCB6BF),
                                        fontSize: 11)),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: direct != null
                                  ? () => _openTitleLink(service, direct)
                                  : verified
                                    ? () => _openTmdbWatch(w)
                                    : () => _openStreamingService(
                                        service, title: w.title),
                                icon: const Icon(
                                  Icons.open_in_new_rounded, size: 16),
                                label: Text(
                                  direct != null
                                    ? 'Abrir título'
                                    : verified ? 'Ver opções' : 'Pesquisar'),
                              ),
                            ]),
                          ),
                        );
                      }),
                  if (w.provider == 'TMDB' &&
                      w.streamingProviders.isEmpty &&
                      !w.availabilityChecked)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Sem confirmação regional para esta obra. '
                        'Mais títulos serão verificados na próxima sincronização.',
                        style: TextStyle(
                          color: Color(0xFFC5B2BA), fontSize: 12)),
                    ),
                  if (w.provider == 'TMDB' &&
                      w.streamingProviders.isEmpty &&
                      w.watchUrl.startsWith('https://'))
                    TextButton.icon(
                      onPressed: () => _openTmdbWatch(w),
                      icon: const Icon(Icons.travel_explore),
                      label: const Text('Ver opções de streaming da obra'),
                    ),
                  if (_streaming.isEmpty)
                    TextButton.icon(
                      onPressed: _showStreamingPreferences,
                      icon: const Icon(Icons.tune),
                      label: const Text('Escolher streamings favoritos'),
                    ),
                  const SizedBox(height: 9),
                  const Text('Fonte da disponibilidade: JustWatch, via TMDB. '
                    'Um link de opções não garante reprodução automática.',
                    style: TextStyle(
                      fontSize: 10, color: Color(0xFFAA969F))),
                ],
                const SizedBox(height: 18),
                if (w.detailUrl.startsWith('https://'))
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(w.detailUrl),
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.info_outline, size: 17),
                    label: Text('Ver no catálogo ${w.provider}'),
                  ),
                SaturnCoupleReview(
                  selfName: profiles[profile],
                  otherName: profiles[1 - profile],
                  self: entry(w),
                  other: records['${1 - profile}:${w.id}'] is Map
                    ? Map<String, dynamic>.from(
                        records['${1 - profile}:${w.id}'] as Map)
                    : const {},
                  cloudConnected: _cloud?.connected == true,
                ),
                const Divider(height: 22),
                const Text('MEU UNIVERSO',
                  style: TextStyle(color: gold,
                    fontSize: 11, letterSpacing: 2)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Meu status'),
                  items: [
                    'Quero conhecer',
                    'Em andamento',
                    'Concluído',
                    'Abandonado'
                  ]
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      refresh(() => status = value ?? status),
                ),
                const SizedBox(height: 18),
                const Text('MINHAS ESTRELAS',
                  style: TextStyle(color: gold,
                    fontSize: 11, letterSpacing: 1.8)),
                const SizedBox(height: 7),
                SaturnStarRating(
                  stars: starsFromLegacy(rating),
                  onChanged: (stars) =>
                      refresh(() => rating = legacyFromStars(stars)),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12, top: 2),
                  child: Text(
                    'Toque na metade de uma estrela para dar meia estrela.',
                    style: TextStyle(
                      fontSize: 11, color: Color(0xFFBFAAB4)),
                  ),
                ),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Minha resenha / memória',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      FocusScope.of(ctx).unfocus();
                      try {
                        await shareSaturnReview(
                          context: ctx,
                          title: w.title,
                          kind: w.kind,
                          comment: notes.text,
                          stars: starsFromLegacy(rating),
                          status: status == 'Concluído'
                              ? w.kind == 'Livro' ? 'Lido' : 'Assistido'
                              : status,
                        );
                      } catch (_) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text(
                            'Não foi possível abrir o compartilhamento.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Compartilhar avaliação no Instagram'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'Uma arte com sua nota e comentário será criada. '
                    'Escolha Instagram no menu de compartilhamento.',
                    style: TextStyle(
                      fontSize: 11, color: Color(0xFFC5AEB7)),
                  ),
                ),
                if (entry(w)['status'] != null && !_isArchived(w))
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Remover da minha coleção'),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: ctx,
                          builder: (dialog) => AlertDialog(
                            title: const Text('Remover da coleção?'),
                            content: const Text(
                              'O título deixará de aparecer na sua coleção. '
                              'Suas avaliações e comentários serão '
                              'preservados e podem ser restaurados.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialog, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dialog, true),
                                child: const Text('Remover'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !mounted) return;
                        setState(() {
                          _archivedFromCollection.add('$profile:${w.id}');
                          _archivedOps['$profile:${w.id}'] = {
                            'present': true,
                            'updatedAt': DateTime.now().millisecondsSinceEpoch,
                          };
                          currentWatchlist.remove(w.id);
                          _watchlistOps['$profile:${w.id}'] = {
                            'present': false,
                            'updatedAt': DateTime.now().millisecondsSinceEpoch,
                          };
                        });
                        _save();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      update(w, {
                        'status': status,
                        'rating': rating == 0 ? null : rating,
                        'notes': notes.text,
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar avaliação e comentário'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    notes.dispose();
  }
}


class PosterThumbnail extends StatelessWidget {
  final Work work;
  final double width;
  final double height;
  const PosterThumbnail({super.key, required this.work, this.width = 54, this.height = 74});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width, height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [wine, Color(0xFF272132)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(work.kind == 'Livro' ? Icons.menu_book_rounded
          : (work.kind == 'Série' || work.kind == 'Dorama' || work.kind == 'Anime')
              ? Icons.tv_rounded : Icons.movie_creation_outlined,
          color: gold, size: 26),
    );
    if (!work.posterUrl.startsWith('https://')) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        work.posterUrl, width: width, height: height, fit: BoxFit.cover,
        loadingBuilder: (context, child, loading) =>
            loading == null ? child : fallback,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class SaturnMark extends StatelessWidget {
  final double size;
  const SaturnMark({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _SaturnPainter(),
  );
}

class _SaturnPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.32);
    final orbit = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero,
          width: size.width * 0.94, height: size.height * 0.35),
      orbit,
    );
    final planet = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF1D9A6), gold, Color(0xFF876146)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.26));
    canvas.drawCircle(Offset.zero, size.width * 0.25, planet);
    final frontRing = Paint()
      ..color = const Color(0xFFF2D19C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.056;
    canvas.drawArc(
      Rect.fromCenter(center: Offset.zero,
          width: size.width * 0.94, height: size.height * 0.35),
      0.05, 3.08, false, frontRing,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CatalogExplore extends StatefulWidget {
  final bool active;
  final CatalogFilter requestedFilter;
  final Future<void> Function(Work) onOpen;
  final void Function(Work) onToggleShared;
  final bool Function(Work) isShared;
  final void Function(Work) onToggleWatchlist;
  final bool Function(Work) isWatchlisted;
  final void Function(Work) onToggleCompleted;
  final bool Function(Work) isCompleted;

  const CatalogExplore({
    super.key,
    required this.active,
    required this.requestedFilter,
    required this.onOpen,
    required this.onToggleShared,
    required this.isShared,
    required this.onToggleWatchlist,
    required this.isWatchlisted,
    required this.onToggleCompleted,
    required this.isCompleted,
  });

  @override
  State<CatalogExplore> createState() => _CatalogExploreState();
}

class _CatalogExploreState extends State<CatalogExplore> {
  final _query = TextEditingController();
  final _catalog = CatalogClient();
  late CatalogFilter _filter = widget.requestedFilter;
  StreamingService? _streamingFilter;
  String? _bookSubject;
  int? _genreId;
  List<Work> _results = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _loaded = false;
  String? _error;
  int _page = 0;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void didUpdateWidget(covariant CatalogExplore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestedFilter != oldWidget.requestedFilter) {
      _selectFilter(widget.requestedFilter);
    }
    if (widget.active && !oldWidget.active && !_loaded && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _request++;
    _query.dispose();
    _catalog.close();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading || _loadingMore) return;
    final query = _query.text.trim();
    final page = more ? _page + 1 : 1;
    final request = ++_request;
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _loaded = true;
        _page = 0;
        _hasMore = true;
        _error = null;
        _results = [];
      }
    });
    try {
      final entries = query.length >= 2
          ? await _catalog.search(query, _filter,
              page: page, streaming: _streamingFilter?.name,
              genreId: _genreId,
              bookSubject: _filter == CatalogFilter.books
                  ? _bookSubject : null)
          : await _catalog.discover(_filter,
              page: page, streaming: _streamingFilter?.name,
              genreId: _genreId,
              bookSubject: _filter == CatalogFilter.books
                  ? _bookSubject : null);
      if (!mounted || request != _request) return;
      final converted = entries.map(Work.fromCatalog);
      setState(() {
        if (more) {
          final existing = {for (final work in _results) work.id: work};
          for (final work in converted) {
            existing.putIfAbsent(work.id, () => work);
          }
          _results = existing.values.toList(growable: false);
        } else {
          _results = converted.toList(growable: false);
        }
        _page = page;
        _hasMore = entries.isNotEmpty && page < 150;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = 'Não foi possível carregar os catálogos. '
            'Verifique sua conexão e tente novamente.';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _selectFilter(CatalogFilter next) {
    if (_filter == next) return;
    setState(() {
      _filter = next;
      if (next == CatalogFilter.books) _streamingFilter = null;
    });
    _request++;
    _loading = false;
    _loadingMore = false;
    _load();
  }

  static const Map<int, String> _movieGenres = {
    28: 'Ação', 12: 'Aventura', 16: 'Animação', 35: 'Comédia',
    80: 'Crime', 99: 'Documentário', 18: 'Drama', 10751: 'Família',
    14: 'Fantasia', 27: 'Terror', 9648: 'Mistério',
    10749: 'Romance', 878: 'Ficção científica', 53: 'Suspense',
  };

  Future<void> _openFilters() async {
    var category = _filter;
    var streaming = _streamingFilter;
    var bookSubject = _bookSubject;
    var genre = _genreId;
    const labels = ['Tudo', 'Filmes', 'Séries', 'Doramas', 'Animes', 'Livros'];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF211923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, redraw) =>
        FractionallySizedBox(
          heightFactor: 0.82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.tune_rounded, color: gold),
                const SizedBox(width: 10),
                const Expanded(child: Text('Refinar descobertas',
                  style: TextStyle(
                    fontFamily: 'serif', color: ivory,
                    fontSize: 25, fontWeight: FontWeight.w600))),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 12),
              Expanded(child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TIPO DE HISTÓRIA', style: TextStyle(
                      color: gold, fontSize: 11, letterSpacing: 1.6)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 7, children: [
                      for (var i=0; i < CatalogFilter.values.length; i++)
                        ChoiceChip(
                          label: Text(labels[i]),
                          selected: category == CatalogFilter.values[i],
                          selectedColor: wine,
                          onSelected: (_) => redraw(() {
                            category = CatalogFilter.values[i];
                            if (category == CatalogFilter.books) {
                              streaming = null;
                              genre = null;
                            } else {
                              bookSubject = null;
                            }
                          }),
                        ),
                    ]),
                    const SizedBox(height: 20),
                    if (category == CatalogFilter.books) ...[
                      const Text('GÊNERO LITERÁRIO', style: TextStyle(
                        color: gold, fontSize: 11, letterSpacing: 1.6)),
                      const SizedBox(height: 9),
                      Wrap(spacing: 7, runSpacing: 7, children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: bookSubject == null,
                          selectedColor: wine,
                          onSelected: (_) =>
                              redraw(() => bookSubject = null),
                        ),
                        for (final entry in CatalogClient.bookSubjects.entries)
                          ChoiceChip(
                            label: Text(entry.key),
                            selected: bookSubject == entry.value,
                            selectedColor: wine,
                            onSelected: (_) =>
                                redraw(() => bookSubject = entry.value),
                          ),
                      ]),
                    ] else ...[
                      const Text('STREAMING NO BRASIL', style: TextStyle(
                        color: gold, fontSize: 11, letterSpacing: 1.6)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 7, runSpacing: 7, children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: streaming == null,
                          selectedColor: wine,
                          onSelected: (_) => redraw(() => streaming = null),
                        ),
                        for (final service in StreamingService.values)
                          ChoiceChip(
                            label: Text(service.label),
                            selected: streaming == service,
                            selectedColor: wine,
                            onSelected: (_) => redraw(
                              () => streaming = service),
                          ),
                      ]),
                      const SizedBox(height: 20),
                      const Text('GÊNERO', style: TextStyle(
                        color: gold, fontSize: 11, letterSpacing: 1.6)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 7, runSpacing: 7, children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: genre == null,
                          selectedColor: wine,
                          onSelected: (_) => redraw(() => genre = null),
                        ),
                        for (final entry in _movieGenres.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: genre == entry.key,
                            selectedColor: wine,
                            onSelected: (_) =>
                                redraw(() => genre = entry.key),
                          ),
                      ]),
                      const SizedBox(height: 7),
                      const Text('Gêneros e plataformas dependem de '
                        'metadados verificados da fonte.',
                        style: TextStyle(
                          fontSize: 11, color: Color(0xFFB9A9B0))),
                    ],
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Row(children: [
                TextButton(
                  onPressed: () => redraw(() {
                    category = CatalogFilter.all;
                    streaming = null;
                    bookSubject = null;
                    genre = null;
                  }),
                  child: const Text('Limpar filtros'),
                ),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _filter = category;
                      _streamingFilter = streaming;
                      _bookSubject = bookSubject;
                      _genreId = genre;
                    });
                    Navigator.pop(ctx);
                    _search();
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Ver títulos'),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _search() {
    if (_query.text.trim().isNotEmpty &&
        _query.text.trim().length < 2) {
      setState(() => _error = 'Digite pelo menos duas letras para pesquisar.');
      return;
    }
    _request++;
    _loading = false;
    _loadingMore = false;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Tudo', 'Filmes', 'Séries', 'Doramas', 'Animes', 'Livros',
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      // Cards com largura adequada tanto no iPhone quanto no desktop.
      final columns = (width / 205).floor().clamp(2, 8).toInt();
      return CustomScrollView(
        key: const PageStorageKey('saturn_catalog_grid'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF522238),
                          Color(0xFF2C2030),
                          night,
                        ],
                      ),
                    ),
                    child: Row(children: [
                      const SaturnMark(size: 62),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SATURN · DESCOBERTAS',
                              style: TextStyle(
                                fontSize: 10, color: gold, letterSpacing: 2)),
                            SizedBox(height: 6),
                            Text('Histórias sem fim',
                              style: TextStyle(
                                fontFamily: 'serif', color: ivory,
                                fontSize: 24, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text('Filmes, séries, doramas, animes e livros.',
                              style: TextStyle(
                                fontSize: 12, color: Color(0xFFDAC8CF))),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: _filter == CatalogFilter.books
                          ? 'Buscar livro, autor ou ISBN'
                          : 'Buscar pelo nome da história',
                      prefixIcon: const Icon(Icons.search_rounded,
                        color: gold),
                      suffixIcon: IconButton(
                        tooltip: 'Pesquisar catálogo',
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: _search,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2B202A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: _openFilters,
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Filtros: tipos, gêneros e streaming'),
                    )),
                  ]),
                  if (_filter != CatalogFilter.all ||
                      _streamingFilter != null ||
                      _bookSubject != null || _genreId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${labels[_filter.index]}'
                        '${_streamingFilter != null ? ' • ${_streamingFilter!.label}' : ''}'
                        '${_bookSubject != null ? ' • Livros: $_bookSubject' : ''}'
                        '${_genreId != null ? ' • ${_movieGenres[_genreId] ?? 'Gênero'}' : ''}',
                        style: const TextStyle(
                          fontSize: 11, color: Color(0xFFC6A477)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: Text(
                        _query.text.trim().length >= 2
                          ? 'Resultados · ${_results.length} títulos'
                          : 'Descobrir · ${_results.length} títulos',
                        style: const TextStyle(
                          fontFamily: 'serif', fontSize: 20,
                          fontWeight: FontWeight.w600, color: ivory),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Recarregar catálogo',
                      onPressed: _loading ? null : _search,
                      icon: const Icon(Icons.refresh, color: gold),
                    ),
                  ]),
                  if (widget.active && (_loading || !_loaded))
                    const LinearProgressIndicator(color: gold),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(_error!,
                        style: const TextStyle(
                          color: Color(0xFFFFB5C1))),
                    ),
                  if (_loaded && _results.isEmpty && !_loading && _error == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        'Nenhum título neste recorte. '
                        'Tente outra pesquisa ou categoria.',
                        style: TextStyle(
                          color: Color(0xFFD1BBC3)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _coverCard(_results[index]),
                childCount: _results.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 0.59,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(children: [
              if (_loadingMore)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(color: gold),
                ),
              if (_hasMore && !_loading && !_loadingMore &&
                  _results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: OutlinedButton.icon(
                    onPressed: () => _load(more: true),
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Carregar mais títulos'),
                  ),
                ),
              if (_error != null)
                TextButton.icon(
                  onPressed: _search,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(19, 12, 19, 30),
                child: Text(
                  'Filmes, séries, animes e doramas: TMDB/JustWatch '
                  '(catálogo brasileiro quando ativado), com fallback '
                  'Apple, TVmaze e AniList. Livros: Open Library. '
                  'Ofertas podem mudar. Dados do TMDB não são endossados '
                  'ou certificados pelo TMDB.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFAFA1AC),
                    fontSize: 11, height: 1.35),
                ),
              ),
            ]),
          ),
        ],
      );
    });
  }

  Widget _coverCard(Work work) {
    final loved = widget.isShared(work);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: const Color(0xFF2A202B),
      child: InkWell(
        onTap: () => widget.onOpen(work),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PosterThumbnail(
                    work: work,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: IconButton.filledTonal(
                      tooltip: work.kind == 'Livro' ? 'Quero ler' : 'Watchlist',
                      onPressed: () => widget.onToggleWatchlist(work),
                      icon: Icon(
                        widget.isWatchlisted(work)
                            ? Icons.bookmark_added
                            : Icons.bookmark_add_outlined,
                        color: ivory,
                        size: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: IconButton.filledTonal(
                      tooltip: work.kind == 'Livro'
                          ? 'Marcar como lido' : 'Marcar como assistido',
                      onPressed: () => widget.onToggleCompleted(work),
                      icon: Icon(
                        widget.isCompleted(work)
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: widget.isCompleted(work)
                            ? const Color(0xFF97CDB4) : ivory,
                        size: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton.filledTonal(
                      tooltip: 'Adicionar à Nossa Órbita',
                      onPressed: () => widget.onToggleShared(work),
                      icon: Icon(
                        loved ? Icons.favorite : Icons.favorite_outline,
                        size: 18,
                        color: loved ? const Color(0xFFE78DA4) : ivory,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xE41B1420),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                        child: Text(work.kind.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.bold,
                            color: gold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 9, 9, 3),
              child: Text(
                work.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ivory,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.18,
                ),
              ),
            ),
            if (work.streamingProviders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Text(
                  'BR: ${work.streamingProviders.values.join(' · ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF97CDB4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 0, 9, 9),
              child: Text(
                work.year > 0 ? '${work.year} · ${work.provider}' : work.provider,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFBFAEB6),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
