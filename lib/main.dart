import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog_client.dart';
import 'streaming_preferences.dart';
import 'streaming_links.dart';
import 'saturn_star_rating.dart';
import 'saturn_review_tiers.dart';
import 'saturn_metallic_halo.dart';
import 'saturn_share.dart';
import 'saturn_trailer.dart';
import 'saturn_native_trailer.dart';
import 'saturn_orbit_cloud.dart';
import 'saturn_orbit_merge.dart';
import 'saturn_orbit_sync_sheet.dart';
import 'saturn_premium_details.dart';
import 'saturn_story_synopsis.dart';
import 'saturn_book_details.dart';
import 'saturn_book_cover.dart';
import 'saturn_couple_insights.dart';
import 'saturn_orbit_rituals.dart';
import 'saturn_couple_suggestions.dart';
import 'saturn_year_recap.dart';
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

// Migration-only metadata for old demo items the user actually interacted with.
const _legacyDemoWorks = <Work>[
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
  // Avoid rendering all five heavy tabs on a memory-limited mobile browser.
  // Keep the active tab and the previous one for fast back navigation.
  final List<int> _recentTabs = [0];
  int profile = 0;

  void _navigateTab(int next) {
    if (next < 0 || next > 4) return;
    setState(() {
      tab = next;
      _recentTabs.remove(next);
      _recentTabs.add(next);
      if (_recentTabs.length > 2) _recentTabs.removeAt(0);
    });
  }

  Widget _mobileSyncShortcut(String section) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
    child: OutlinedButton.icon(
      key: Key('saturn-' + section + '-sync-shortcut'),
      onPressed: _showOrbitSync,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        alignment: Alignment.centerLeft,
        side: const BorderSide(color: Color(0x997C6070)),
        foregroundColor: gold,
        backgroundColor: const Color(0xFF302334),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)),
      ),
      icon: Icon(_cloud?.connected == true
          ? Icons.cloud_done_outlined : Icons.cloud_sync_outlined),
      label: Text(_cloud?.connected == true
          ? 'Nossa Órbita conectada · gerenciar'
          : 'Entrar e sincronizar Nossa Órbita',
        maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );

  Map<String, dynamic> records = {};
  Map<String, dynamic> _watchlistOps = {};
  Map<String, dynamic> _sharedOps = {};
  Map<String, dynamic> _archivedOps = {};
  Map<String, dynamic> _ritualOps = {};
  Map<String, dynamic> _profileOps = {};
  SaturnOrbitCloud? _cloud;
  bool _cloudApplying = false;
  List<String> shared = [];
  Map<String, Work> savedWorks = {};
  Set<String> _archivedFromCollection = <String>{};
  bool _selectingWorks = false;
  final Set<String> _selectedWorkIds = <String>{};
  Map<String, Map<String, String>> customTitleLinks = {};
  List<Work> get allWorks => savedWorks.values.toList(growable: false);
  Map<int, Set<String>> watchlists = {0: <String>{}, 1: <String>{}};
  Set<String> get currentWatchlist =>
      watchlists.putIfAbsent(profile, () => <String>{});
  final CatalogClient _homeCatalog = CatalogClient();
  Timer? _featuredTimer;
  int _featuredIndex = 0;
  bool _foreground = true;
  List<Work> recommendedMovies = [];
  List<Work> recommendedBooks = [];
  bool loadingRecommendations = false;
  int _filmRecommendationPage = 0;
  final profiles = ['Eu', 'Ela'];
  final profileAvatars = ['🪐', '🌙'];
  static const _avatarChoices = <String>[
    '🪐', '🌙', '💫', '🌸', '⭐', '🦋', '📚', '🎬',
  ];
  String _collectionKind = 'Tudo';
  String _sharedKind = 'Tudo';
  String _sharedMoment = 'Todas';
  String _partnerShelfView = 'Watchlist';
  static const _collectionTypes = <String, String>{
    'Tudo': '', 'Filmes': 'Filme', 'Séries': 'Série',
    'Doramas': 'Dorama', 'Animes': 'Anime', 'Livros': 'Livro',
  };
  Set<StreamingService> _streaming = {...defaultStreamingServices};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _featuredTimer = Timer.periodic(const Duration(seconds: 9), (_) {
      if (!mounted || !_foreground || tab != 0) return;
      final slides = _featuredTitles();
      if (slides.length > 1) {
        setState(() => _featuredIndex = (_featuredIndex + 1) % slides.length);
      }
    });
    if (_saturnCloudReady) {
      _cloud = SaturnOrbitCloud(
        readLocal: _orbitDocument,
        apply: _applyOrbitDocument,
        onStatus: () {
          if (!mounted) return;
          final bound = _cloud?.connected == true
              ? _cloud?.memberProfileIndex : null;
          if (bound != null && bound != profile) {
            _setProfile(bound);
          } else {
            setState(() {});
          }
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
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _cloud?.scheduleSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cloud?.dispose();
    _featuredTimer?.cancel();
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
      final storedRitualOps =
          jsonDecode(prefs.getString('saturn_ritual_ops_v1') ?? '{}');
      final storedProfileOps =
          jsonDecode(prefs.getString('saturn_profile_ops_v1') ?? '{}');
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
        _ritualOps = storedRitualOps is Map
            ? Map<String, dynamic>.from(storedRitualOps)
            : <String, dynamic>{};
        _profileOps = storedProfileOps is Map
            ? Map<String, dynamic>.from(storedProfileOps)
            : <String, dynamic>{};
        _applyProfileIdentity();
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
        // Never seed demo titles on fresh installs. Only keep previously
        // referenced examples so no personal review disappears on upgrade.
        for (final old in _legacyDemoWorks) {
          final used = shared.contains(old.id) ||
              watchlists.values.any((items) => items.contains(old.id)) ||
              records.keys.any((key) => key.endsWith(':' + old.id)) ||
              _ritualOps.values.any((row) =>
                  row is Map && row['workId'] == old.id);
          if (used) savedWorks.putIfAbsent(old.id, () => old);
        }
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
    await prefs.setString('saturn_ritual_ops_v1', jsonEncode(_ritualOps));
    await prefs.setString('saturn_profile_ops_v1', jsonEncode(_profileOps));
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
    'ritualOps': _ritualOps,
    'profileOps': _profileOps,
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
        _ritualOps = Map<String, dynamic>.from(
          doc['ritualOps'] as Map? ?? {});
        _profileOps = Map<String, dynamic>.from(
          doc['profileOps'] as Map? ?? {});
        _applyProfileIdentity();
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
    if (next < 0 || next >= profiles.length) return;
    final bound = _cloud?.connected == true
        ? _cloud?.memberProfileIndex : null;
    if (bound != null && bound != next) return;
    setState(() => profile = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saturn_profile_index', next);
  }

  void _applyProfileIdentity() {
    for (var i = 0; i < profiles.length; i++) {
      final row = _profileOps['$i'];
      final name = row is Map ? (row['name'] ?? '').toString().trim() : '';
      final avatar = row is Map ? (row['avatar'] ?? '').toString() : '';
      profiles[i] = name.isEmpty ? (i == 0 ? 'Eu' : 'Ela')
          : name.length > 26 ? name.substring(0, 26) : name;
      profileAvatars[i] = _avatarChoices.contains(avatar) ? avatar
          : (i == 0 ? '🪐' : '🌙');
    }
  }

  Future<void> _updateProfileIdentity(
      int person, String nameInput, String avatar) async {
    final bound = _cloud?.connected == true
        ? _cloud?.memberProfileIndex : null;
    if (person < 0 || person >= profiles.length ||
        (bound != null && bound != person)) return;
    final name = nameInput.trim();
    if (name.isEmpty || name.length > 26) return;
    setState(() {
      _profileOps['$person'] = {
        'name': name, 'avatar': _avatarChoices.contains(avatar)
            ? avatar : profileAvatars[person],
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      _applyProfileIdentity();
    });
    await _save();
  }


  Future<void> _showProfileSettings() async {
    final person = profile;
    final name = TextEditingController(text: profiles[person]);
    var avatar = profileAvatars[person];
    try {
      await showModalBottomSheet<void>(
        context: context, isScrollControlled: true, useSafeArea: true,
        backgroundColor: const Color(0xFF261B2B),
        builder: (modal) => StatefulBuilder(builder: (ctx, redraw) {
          final completed = records.entries.where((row) =>
              row.key.startsWith(person.toString() + ':') &&
              row.value is Map &&
              ['Concluído', 'Assistido', 'Lido']
                .contains((row.value as Map)['status'])).length;
          final reviewed = records.entries.where((row) =>
              row.key.startsWith(person.toString() + ':') &&
              row.value is Map &&
              (row.value as Map)['rating'] is num).length;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              19, 18, 19, MediaQuery.of(ctx).viewInsets.bottom + 22),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('SEU UNIVERSO',
                    style: TextStyle(color: gold, letterSpacing: 2,
                      fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(children: [
                    CircleAvatar(
                      radius: 36, backgroundColor: const Color(0xFF543047),
                      child: Text(avatar,
                        style: const TextStyle(fontSize: 36))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profiles[person], maxLines: 2,
                          style: const TextStyle(fontFamily: 'serif',
                            fontSize: 25, color: ivory,
                            fontWeight: FontWeight.bold)),
                        Text(_cloud?.connected == true
                            ? 'Perfil vinculado à sua conta SATURN'
                            : 'Perfil local · conecte a Nossa Órbita',
                          style: const TextStyle(
                            color: Color(0xFFC9B4C0), fontSize: 11)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _profileMetric(
                      'Concluídos', completed.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _profileMetric(
                      'Minhas notas', reviewed.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _profileMetric(
                      'Minha lista',
                      (watchlists[person]?.length ?? 0).toString())),
                  ]),
                  const SizedBox(height: 20),
                  const Text('COMO QUER SER CHAMADO(A)?',
                    style: TextStyle(color: gold, fontSize: 11,
                      letterSpacing: 1.1)),
                  const SizedBox(height: 9),
                  TextField(
                    key: const Key('saturn-profile-name'),
                    controller: name, maxLength: 26,
                    decoration: const InputDecoration(
                      hintText: 'Seu nome ou apelido',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 9),
                  const Text('ESCOLHA SEU SÍMBOLO',
                    style: TextStyle(color: gold, fontSize: 11,
                      letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 7, runSpacing: 8, children: [
                    for (final choice in _avatarChoices)
                      ChoiceChip(
                        label: Text(choice,
                          style: const TextStyle(fontSize: 24)),
                        selected: avatar == choice,
                        onSelected: (_) => redraw(() => avatar = choice),
                      ),
                  ]),
                  const SizedBox(height: 19),
                  SizedBox(width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('saturn-profile-save'),
                      onPressed: name.text.trim().isEmpty
                          ? null : () {
                        _updateProfileIdentity(person, name.text, avatar);
                        Navigator.pop(modal);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Salvar meu perfil'),
                    )),
                  const SizedBox(height: 13),
                  const Divider(color: Color(0x665B4353)),
                  const SizedBox(height: 8),
                  Text('NA NOSSA ÓRBITA: ' +
                    profiles[1 - person] + ' ' + profileAvatars[1 - person],
                    style: const TextStyle(
                      color: Color(0xFFC8B4C0), fontSize: 12)),
                  if (_cloud?.connected == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Cada conta edita seu próprio perfil. '
                        'As histórias e memórias continuam compartilhadas.',
                        style: TextStyle(
                          color: Color(0xFFBBA9B6), fontSize: 11)),
                    ),
                ],
              ),
            ),
          );
        }),
      );
    } finally {
      name.dispose();
    }
  }

  Widget _profileMetric(String label, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF36243A),
      borderRadius: BorderRadius.circular(13)),
    child: Column(children: [
      Text(value, style: const TextStyle(
        color: gold, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(
        color: Color(0xFFE0CDD6), fontSize: 10)),
    ]),
  );

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
      if (!savedWorks.containsKey(w.id)) savedWorks[w.id] = w;
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
      if (!savedWorks.containsKey(w.id)) savedWorks[w.id] = w;
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
      if (!savedWorks.containsKey(w.id)) savedWorks[w.id] = w;
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
      if (!savedWorks.containsKey(w.id)) savedWorks[w.id] = w;
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


  Work? _ritualWork(String id) {
    if (id.isEmpty) return null;
    for (final work in allWorks) {
      if (work.id == id) return work;
    }
    return null;
  }

  String _ritualId(String key) => SaturnOrbitRituals.workId(_ritualOps, key);

  void _suggestToPartner(Work work) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      savedWorks.putIfAbsent(work.id, () => work);
      SaturnCoupleSuggestion.send(_ritualOps,
          from: profile, workId: work.id, at: stamp);
    });
    _save();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Sugestão enviada para ' + profiles[1 - profile])));
  }

  void _answerSuggestion(SaturnCoupleSuggestion suggestion, String decision) {
    final accepted = decision == 'accepted';
    if (!SaturnCoupleSuggestion.answer(_ritualOps, suggestion.key,
        by: profile, status: decision,
        at: DateTime.now().millisecondsSinceEpoch)) return;
    setState(() {});
    _save();
    if (accepted) {
      final work = savedWorks[suggestion.workId];
      if (work != null && !currentWatchlist.contains(work.id)) {
        _toggleWatchlist(work);
      }
    }
  }

  Widget _coupleSuggestionsCard() {
    final suggestions = SaturnCoupleSuggestion.read(_ritualOps)
        .where((item) => item.status == 'pending' ||
            item.status == 'accepted').take(12).toList(growable: false);
    return Container(
      key: const Key('saturn-couple-suggestions'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [
          Color(0xFF42283C), Color(0xFF251E2D)]),
        border: Border.all(color: const Color(0x886A5364))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.mark_chat_unread_outlined, color: gold, size: 20),
          SizedBox(width: 9),
          Text('DE MIM PARA VOCÊ',
            style: TextStyle(color: gold, letterSpacing: 1.4,
              fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        const Text('Uma história escolhida especialmente para o outro.',
          style: TextStyle(color: Color(0xFFE6CFDA), fontSize: 11)),
        const SizedBox(height: 12),
        if (suggestions.isEmpty)
          const Text('Abra a ficha de um título e toque em Sugerir.',
            style: TextStyle(color: ivory, fontSize: 12))
        else
          for (final item in suggestions)
            Builder(builder: (context) {
              final work = savedWorks[item.workId];
              if (work == null) return const SizedBox.shrink();
              final mine = item.from == profile;
              final pending = item.status == 'pending';
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Material(
                  color: const Color(0xFF211B29),
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Row(children: [
                      InkWell(onTap: () => _details(work),
                        child: PosterThumbnail(
                          work: work, width: 58, height: 84)),
                      const SizedBox(width: 11),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(work.title, maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: ivory,
                              fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(mine
                              ? 'Para ' + profiles[item.to] +
                                  (pending ? ' · enviada' : ' · aceita')
                              : 'De ' + profiles[item.from] +
                                  (pending ? ' · para você' : ' · aceita'),
                            style: const TextStyle(
                              color: gold, fontSize: 10)),
                          if (!mine && pending)
                            Wrap(spacing: 4, children: [
                              TextButton(
                                key: Key('saturn-suggestion-accept-' + item.key),
                                onPressed: () =>
                                    _answerSuggestion(item, 'accepted'),
                                child: Text(work.kind == 'Livro'
                                    ? 'Quero ler' : '+ Minha Watchlist')),
                              TextButton(
                                onPressed: () =>
                                    _answerSuggestion(item, 'dismissed'),
                                child: const Text('Agora não')),
                            ]),
                        ],
                      )),
                    ]),
                  ),
                ),
              );
            }),
      ]),
    );
  }


  void _setRitualNomination(String period, int person, Work? work) {
    if (person != profile) return;
    final book = period.startsWith('month:');
    if (work != null && (book ? work.kind != 'Livro' : work.kind != 'Filme')) {
      return;
    }
    if (book && work != null &&
        !SaturnOrbitRituals.canChooseBook(
          _ritualOps, period, person, work.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Cada perfil escolhe um livro diferente neste mês.')),
      );
      return;
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      if (work != null && !savedWorks.containsKey(work.id)) {
        savedWorks[work.id] = work;
      }
      _ritualOps[SaturnOrbitRituals.nomination(period, person)] = {
        'workId': work?.id ?? '', 'updatedAt': stamp,
      };
      if (book && work != null && !shared.contains(work.id)) {
        // Both personal reading journeys live in Nossa Órbita.
        shared.add(work.id);
        _sharedOps[work.id] = {
          'present': true, 'updatedAt': stamp,
        };
      }
      if (!book) {
        final chosenKey = SaturnOrbitRituals.selection(period);
        final selected = _ritualId(chosenKey);
        if (selected.isNotEmpty &&
            selected != _ritualId(SaturnOrbitRituals.nomination(period, 0)) &&
            selected != _ritualId(SaturnOrbitRituals.nomination(period, 1))) {
          // A replaced film candidate cannot remain the final movie pick.
          _ritualOps[chosenKey] = {
            'workId': '', 'updatedAt': stamp + 1,
          };
        }
      }
    });
    _save();
  }

  void _chooseRitualWork(String period, Work work) {
    // Monthly books are personal choices, never a shared final vote.
    if (!period.startsWith('weekend:')) return;
    if (work.id != _ritualId(SaturnOrbitRituals.nomination(period, 0)) &&
        work.id != _ritualId(SaturnOrbitRituals.nomination(period, 1))) {
      return; // Only one of the two proposals can be chosen.
    }
    if (work.kind != 'Filme') return;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      if (!savedWorks.containsKey(work.id)) {
        savedWorks[work.id] = work;
      }
      _ritualOps[SaturnOrbitRituals.selection(period)] = {
        'workId': work.id, 'updatedAt': stamp,
      };
      if (!shared.contains(work.id)) {
        shared.add(work.id);
        _sharedOps[work.id] = {
          'present': true, 'updatedAt': stamp,
        };
      }
    });
    _save();
  }


  /// Work-level manga entries group volumes. Use real edition IDs for reads.
  Future<Work?> _chooseBookEdition(Work parent) async {
    if (!parent.id.startsWith('openlibrary:/works/')) return parent;
    final client = CatalogClient();
    final isbn = TextEditingController();
    final initial = client.bookEditions(parent.id);
    var searchingIsbn = false;
    String? error;
    var page = 1;
    var more = <CatalogEntry>[];
    var loadingMore = false;
    try {
      return await showModalBottomSheet<Work>(
        context: context, isScrollControlled: true, useSafeArea: true,
        backgroundColor: const Color(0xFF241B29),
        builder: (sheet) => StatefulBuilder(builder: (ctx, repaint) {
          Future<void> lookup() async {
            if (searchingIsbn) return;
            repaint(() => searchingIsbn = true);
            try {
              final result = await client.editionByIsbn(isbn.text);
              if (!sheet.mounted) return;
              if (result != null) {
                Navigator.pop(sheet, Work.fromCatalog(result));
              } else {
                repaint(() => error = 'ISBN não encontrado na Open Library.');
              }
            } catch (_) {
              if (sheet.mounted) repaint(() =>
                error = 'Não foi possível buscar o ISBN. Tente novamente.');
            } finally {
              if (sheet.mounted) repaint(() => searchingIsbn = false);
            }
          }
          Future<void> loadMore() async {
            if (loadingMore || searchingIsbn) return;
            repaint(() { loadingMore = true; error = null; });
            try {
              final found = await client.bookEditions(parent.id, page: page + 1);
              if (!sheet.mounted) return;
              repaint(() {
                if (found.isNotEmpty) {
                  page++;
                  more = [...more, ...found];
                } else {
                  error = 'Não há mais edições catalogadas nesta obra.';
                }
                loadingMore = false;
              });
            } catch (_) {
              if (sheet.mounted) repaint(() {
                error = 'Falha ao carregar outras edições.';
                loadingMore = false;
              });
            }
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SizedBox(
              height: (MediaQuery.sizeOf(ctx).height -
                  MediaQuery.of(ctx).viewInsets.bottom - 75)
                  .clamp(170.0, 630.0).toDouble(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecionar volume ou edição',
                    style: TextStyle(color: ivory, fontFamily: 'serif',
                      fontSize: 23, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 7),
                  Text(parent.title, maxLines: 2,
                    style: const TextStyle(color: gold, fontSize: 12)),
                  const SizedBox(height: 5),
                  const Text('Volumes e edições especiais são livros '
                    'diferentes. Confira o ano, a capa e o ISBN.',
                    style: TextStyle(color: ivory, fontSize: 11)),
                  const SizedBox(height: 9),
                  Row(children: [
                    Expanded(child: TextField(
                      controller: isbn, onSubmitted: (_) => lookup(),
                      decoration: const InputDecoration(
                        isDense: true, hintText: 'ISBN da edição',
                        border: OutlineInputBorder()))),
                    IconButton.filled(
                      onPressed: searchingIsbn ? null : lookup,
                      icon: const Icon(Icons.search)),
                  ]),
                  if (error != null)
                    Text(error!, style: const TextStyle(
                        color: Color(0xFFFFAABC), fontSize: 11)),
                  Expanded(child: FutureBuilder<List<CatalogEntry>>(
                    future: initial,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        if (snapshot.hasError) {
                          return const Center(child: Text(
                            'Não foi possível carregar as edições. '
                            'Tente o ISBN da capa.'));
                        }
                        return const Center(
                          child: CircularProgressIndicator(color: gold));
                      }
                      final books = <CatalogEntry>[
                        ...snapshot.data!, ...more,
                      ];
                      if (books.isEmpty) return const Center(
                        child: Text('Nenhuma edição catalogada. '
                          'Tente pesquisar pelo ISBN.'));
                      return ListView.builder(
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final work = Work.fromCatalog(books[index]);
                          return ListTile(
                            leading: PosterThumbnail(
                              work: work, width: 42, height: 59),
                            title: Text(work.title, maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                            subtitle: Text(work.description, maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11)),
                            onTap: () => Navigator.pop(sheet, work),
                          );
                        });
                    },
                  )),
                  Row(children: [
                    Expanded(child: TextButton.icon(
                      onPressed: loadingMore ? null : loadMore,
                      icon: loadingMore
                          ? const SizedBox(width: 15, height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.expand_more),
                      label: const Text('Mais edições'))),
                    Expanded(child: TextButton(
                      onPressed: () => Navigator.pop(sheet, parent),
                      child: const Text('Obra geral'))),
                  ]),
                ],
              ),
            ),
          );
        }),
      );
    } finally {
      isbn.dispose();
      client.close();
    }
  }

  /// A new monthly title is always picked explicitly from actual catalog data.
  Future<void> _nominateRitual(String period, bool book) async {
    final client = CatalogClient();
    final searchController = TextEditingController();
    List<Work> options = allWorks
        .where((w) => w.kind == (book ? 'Livro' : 'Filme'))
        .take(40).toList(growable: false);
    bool loading = false;
    bool initialized = false;
    String? error;
    try {
      final chosen = await showModalBottomSheet<Work>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xFF241B29),
        builder: (sheet) => StatefulBuilder(
          builder: (sheet, repaint) {
            Future<void> discoverReal() async {
              if (loading) return;
              repaint(() { loading = true; error = null; });
              try {
                final found = await client.discover(
                    book ? CatalogFilter.books : CatalogFilter.movies,
                    page: 1);
                if (!sheet.mounted) return;
                repaint(() {
                  final merged = <String, Work>{
                    for (final saved in options) saved.id: saved,
                    for (final entry in found)
                      entry.id: Work.fromCatalog(entry),
                  };
                  options = merged.values.toList(growable: false);
                  if (options.isEmpty) {
                    error = 'Nenhuma sugestão carregada. '
                        'Pesquise um título para indicar.';
                  }
                  loading = false;
                });
              } catch (_) {
                if (!sheet.mounted) return;
                repaint(() {
                  if (options.isEmpty) {
                    error = 'Falha ao carregar sugestões. '
                        'Use a busca para tentar outro título.';
                  }
                  loading = false;
                });
              }
            }

            Future<void> search() async {
              if (loading) return;
              final text = searchController.text.trim();
              if (text.length < 2) {
                repaint(() => error = 'Digite pelo menos duas letras.');
                return;
              }
              repaint(() {
                loading = true;
                error = null;
              });
              try {
                final isbnResult =
                    book ? await client.editionByIsbn(text) : null;
                final found = isbnResult == null
                    ? await client.search(text,
                        book ? CatalogFilter.books : CatalogFilter.movies)
                    : [isbnResult];
                if (!sheet.mounted) return;
                repaint(() {
                  options = found.map(Work.fromCatalog)
                      .where((w) => w.kind == (book ? 'Livro' : 'Filme'))
                      .toList(growable: false);
                  if (options.isEmpty) error =
                      'Nenhum título encontrado. Tente outra pesquisa.';
                  loading = false;
                });
              } catch (_) {
                if (!sheet.mounted) return;
                repaint(() {
                  error = 'Não foi possível pesquisar agora. '
                      'Verifique a conexão ou escolha um título salvo.';
                  loading = false;
                });
              }
            }
            if (!initialized) {
              initialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (sheet.mounted) discoverReal();
              });
            }
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18, 18, 18, MediaQuery.of(sheet).viewInsets.bottom + 16),
              child: SizedBox(
                // Keep the picker above the iPhone on-screen keyboard.
                height: (MediaQuery.sizeOf(sheet).height -
                    MediaQuery.of(sheet).viewInsets.bottom - 85)
                    .clamp(120.0, 620.0).toDouble(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book ? 'Escolher meu livro do mês'
                        : 'Indicar o filme do fim de semana',
                      style: const TextStyle(
                        color: ivory, fontFamily: 'serif',
                        fontSize: 23, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Indicação de ${profiles[profile]} • '
                      'cada perfil tem uma proposta por período.',
                      style: const TextStyle(
                        color: Color(0xFFCFB9C6), fontSize: 12)),
                    const SizedBox(height: 15),
                    Row(children: [
                      Expanded(child: TextField(
                        controller: searchController,
                        autofocus: false,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => search(),
                        decoration: InputDecoration(
                          hintText: book ? 'Buscar livro ou ISBN...' : 'Buscar filme no catálogo...',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder()),
                      )),
                      const SizedBox(width: 9),
                      IconButton.filled(
                        key: const Key('saturn-ritual-search'),
                        tooltip: 'Buscar no catálogo',
                        onPressed: loading ? null : search,
                        icon: const Icon(Icons.search)),
                    ]),
                    if (loading)
                      const LinearProgressIndicator(color: gold),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Text(error!, style: const TextStyle(
                          color: Color(0xFFF1B4C2), fontSize: 12))),
                    const SizedBox(height: 9),
                    const Text('CATÁLOGO REAL · SALVOS E DESCOBERTAS',
                      style: TextStyle(color: gold,
                        letterSpacing: 1.2, fontSize: 10)),
                    const SizedBox(height: 7),
                    Expanded(child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final work = options[index];
                        return ListTile(
                          leading: PosterThumbnail(
                            work: work, width: 40, height: 57),
                          title: Text(work.title, maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            (book && work.id.startsWith('openlibrary:/works/')
                                ? 'Escolher volume/edição · ' : '') +
                            work.kind + ' · ' +
                            (work.year > 0
                                ? work.year.toString() : 'Sem ano')),
                          onTap: () async {
                            final selected = book
                                ? await _chooseBookEdition(work) : work;
                            if (selected != null && sheet.mounted) {
                              Navigator.pop(sheet, selected);
                            }
                          },
                        );
                      },
                    )),
                  ],
                ),
              ),
            );
          },
        ),
      );
      if (chosen != null && mounted) {
        _setRitualNomination(period, profile, chosen);
      }
    } finally {
      searchController.dispose();
      client.close();
    }
  }

  /// Each face reflects only that profile's reading assignments.
  String _bookFace(int person) =>
      SaturnOrbitRituals.readingFace(
        _ritualOps, records, person, DateTime.now());

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: desktop ? NavigationToolbar.kMiddleSpacing : 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SaturnMark(size: desktop ? 34 : 26),
            SizedBox(width: desktop ? 8 : 5),
            Text('SATURN', style: TextStyle(
              fontFamily: 'serif',
              fontSize: desktop ? 21 : 18,
              letterSpacing: desktop ? 3 : 1.1, color: ivory)),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('saturn-header-sync'),
            tooltip: 'Sincronizar nossa órbita',
            constraints: const BoxConstraints(
                minWidth: 48, minHeight: 48),
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
            tooltip: 'Perfis · personalizar',
            initialValue: profile,
            onSelected: (value) {
              if (value == 99) {
                _showProfileSettings();
              } else {
                _setProfile(value);
              }
            },
            itemBuilder: (context) => [
              for (var i = 0; i < profiles.length; i++)
                PopupMenuItem<int>(
                  value: i,
                  enabled: _cloud?.connected != true ||
                      _cloud?.memberProfileIndex == i,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(profileAvatars[i],
                      style: const TextStyle(fontSize: 19)),
                    const SizedBox(width: 8),
                    Text(profiles[i]),
                    if (_bookFace(i).isNotEmpty) ...[
                      const SizedBox(width: 8), Text(_bookFace(i)),
                    ],
                  ]),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<int>(
                value: 99,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_outlined, color: gold, size: 18),
                  SizedBox(width: 8), Text('Personalizar meu perfil'),
                ]),
              ),
            ],
            child: desktop
                ? Padding(
                    padding: const EdgeInsets.all(9),
                    child: Chip(
                      avatar: Text(profileAvatars[profile],
                        style: const TextStyle(fontSize: 18)),
                      label: Row(mainAxisSize: MainAxisSize.min, children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 108),
                          child: Text(profiles[profile],
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600))),
                        if (_bookFace(profile).isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(_bookFace(profile)),
                        ],
                      ]),
                    ),
                  )
                : SizedBox(
                    width: 46, height: 46,
                    child: Stack(children: [
                      Center(child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF4A2B40),
                        child: Text(profileAvatars[profile],
                          style: const TextStyle(fontSize: 21)),
                      )),
                      if (_bookFace(profile).isNotEmpty)
                        Positioned(
                          right: 0, bottom: 0,
                          child: Tooltip(
                            message: _bookFace(profile) == '😢'
                              ? 'Leitura de mês anterior em atraso'
                              : _bookFace(profile) == '📖'
                                ? 'Livro do mês em andamento · prazo até o fim do mês'
                                : 'Leitura concluída e avaliada',
                            child: Text(_bookFace(profile),
                              style: const TextStyle(fontSize: 15)),
                          ),
                        ),
                    ]),
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
                onDestinationSelected: _navigateTab,
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
                  if (desktop || _recentTabs.contains(0))
                    TickerMode(enabled: tab == 0, child: _start())
                  else const SizedBox.shrink(),
                  if (desktop || _recentTabs.contains(1))
                    TickerMode(enabled: tab == 1, child: _explore())
                  else const SizedBox.shrink(),
                  if (desktop || _recentTabs.contains(2))
                    TickerMode(enabled: tab == 2, child: _collection())
                  else const SizedBox.shrink(),
                  if (desktop || _recentTabs.contains(3))
                    TickerMode(enabled: tab == 3, child: _shared())
                  else const SizedBox.shrink(),
                  if (desktop || _recentTabs.contains(4))
                    TickerMode(enabled: tab == 4, child: _stats())
                  else const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: desktop ? null : NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: _navigateTab,
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



  List<Work> _featuredTitles() {
    final personal = allWorks.where((w) =>
        w.kind == 'Filme' && currentWatchlist.contains(w.id) &&
        w.posterUrl.startsWith('https://')).toList(growable: false);
    final likedGenres = <int>{};
    for (final work in allWorks) {
      if (currentWatchlist.contains(work.id)) {
        likedGenres.addAll(work.genreIds);
      }
    }
    final catalog = recommendedMovies.where((w) =>
        w.kind == 'Filme' && w.posterUrl.startsWith('https://')).toList();
    catalog.sort((a, b) =>
      b.genreIds.where(likedGenres.contains).length.compareTo(
        a.genreIds.where(likedGenres.contains).length));
    final seen = <String>{};
    final slides = <Work>[];
    for (final work in <Work>[...personal.take(3), ...catalog]) {
      if (seen.add(work.id)) slides.add(work);
      if (slides.length >= 8) break;
    }
    return slides;
  }

  void _moveFeatured(int direction) {
    final slides = _featuredTitles();
    if (slides.length < 2) return;
    setState(() => _featuredIndex =
        (_featuredIndex + direction + slides.length) % slides.length);
  }

  /// Usa capas realmente retornadas pelo catálogo; sem título fictício no destaque.
  Widget _cinematicHero(int ownCount) {
    final slides = _featuredTitles();
    final Work? featured = slides.isEmpty
        ? null : slides[_featuredIndex % slides.length];
    final fromWatchlist = featured != null &&
        currentWatchlist.contains(featured.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacious = constraints.maxWidth >= 680;
          return ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: spacious ? 346 : 405,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF57283D),
                          Color(0xFF2C1D2E),
                          night,
                        ],
                      ),
                    ),
                  ),
                  if (featured != null)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.36,
                        child: spacious
                            ? ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(
                                  sigmaX: 12, sigmaY: 12),
                                child: Image.network(featured.posterUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      const SizedBox.shrink()))
                            : Image.network(featured.posterUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment.centerRight,
                                errorBuilder: (context, error, stack) =>
                                    const SizedBox.shrink()),
                      ),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xF5201829),
                          Color(0xE3291D30),
                          Color(0x99201827),
                        ],
                        stops: [0, 0.5, 1],
                      ),
                    ),
                  ),
                  if (featured != null)
                    Positioned(
                      top: spacious ? 21 : 24,
                      right: spacious ? 31 : 13,
                      bottom: spacious ? 21 : 78,
                      width: spacious ? 183 : 124,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: PosterThumbnail(
                          work: featured,
                          width: spacious ? 183 : 124,
                          height: spacious ? 265 : 220,
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacious ? 35 : 22,
                      vertical: spacious ? 29 : 23,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          SaturnMark(size: 41),
                          SizedBox(width: 12),
                          Expanded(child: Text(
                            'EVERY STORY HAS ITS ORBIT',
                            style: TextStyle(
                              color: gold, letterSpacing: 1.7,
                              fontSize: 10, fontWeight: FontWeight.w600),
                          )),
                        ]),
                        const Spacer(),
                        Text(
                          featured != null
                              ? fromWatchlist ? 'DA SUA WATCHLIST · PARA VOCÊ' : 'EM DESTAQUE · DESCUBRA'
                              : 'NOSSO UNIVERSO DE HISTÓRIAS',
                          style: const TextStyle(
                            fontSize: 10, color: gold,
                            fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth:
                            featured == null ? constraints.maxWidth
                                : constraints.maxWidth * (spacious ? 0.60 : 0.58)),
                          child: Text(
                            featured?.title ?? 'Seu universo de histórias',
                             key: const Key('saturn-featured-title'),
                            maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'serif', color: ivory,
                              fontWeight: FontWeight.bold,
                              fontSize: spacious ? 35 : 25, height: 1.12),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Bem-vinda, ${profiles[profile]} • '
                          '$ownCount na coleção • ${shared.length} na nossa órbita',
                          maxLines: 2,
                          style: const TextStyle(
                            color: Color(0xFFE0CED6),
                            fontSize: 12, height: 1.35),
                        ),
                        const SizedBox(height: 18),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          FilledButton.icon(
                            onPressed: () => _navigateTab(1),
                            icon: const Icon(Icons.explore_outlined, size: 18),
                            label: const Text('Descobrir histórias'),
                          ),
                          if (featured != null)
                            OutlinedButton.icon(
                              onPressed: () => _details(featured),
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('Ver detalhes'),
                            ),
                        ]),
                      ],
                    ),
                  ),
                  if (slides.length > 1)
                    Positioned(
                      top: 12, right: 12,
                      child: Material(
                        color: const Color(0xDB241A2A),
                        borderRadius: BorderRadius.circular(32),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            key: const Key('saturn-feature-previous'),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Destaque anterior',
                            icon: const Icon(Icons.chevron_left, color: ivory),
                            onPressed: () => _moveFeatured(-1)),
                          Text('${(_featuredIndex % slides.length) + 1}/${slides.length}',
                            style: const TextStyle(color: gold, fontSize: 11)),
                          IconButton(
                            key: const Key('saturn-feature-next'),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Próximo destaque',
                            icon: const Icon(Icons.chevron_right, color: ivory),
                            onPressed: () => _moveFeatured(1)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Trilhos horizontais para as sugestões e livros já entregues pelas APIs.
  Widget _cinematicShelf(Iterable<Work> source) {
    final titles = source.take(12).toList(growable: false);
    if (titles.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 249,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        scrollDirection: Axis.horizontal,
        itemCount: titles.length,
        separatorBuilder: (context, index) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          final work = titles[index];
          return SaturnHoverLift(
            child: SizedBox(
              width: 137,
              child: Material(
                color: const Color(0xFF251B27),
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _details(work),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 177,
                        child: Stack(fit: StackFit.expand, children: [
                          PosterThumbnail(
                            work: work,
                            width: double.infinity,
                            height: double.infinity),
                          Positioned(
                            right: 3, top: 3,
                            child: IconButton.filledTonal(
                              tooltip: work.kind == 'Livro'
                                  ? 'Quero ler' : 'Watchlist',
                              onPressed: () => _toggleWatchlist(work),
                              icon: Icon(
                                _isWatchlisted(work)
                                    ? Icons.bookmark_added
                                    : Icons.bookmark_add_outlined,
                                size: 17),
                            ),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 1),
                        child: Text(work.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: ivory, height: 1.12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          work.year > 0 ? '${work.kind} · ${work.year}' : work.kind,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFC5AAB6), fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Horizontal, lazy-loaded home shelves replace long vertical lists.
  Widget _rankedShelf(List<Work> items, {required String shelfKey}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 273,
      child: ListView.separated(
        key: Key(shelfKey),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 3),
        itemBuilder: (context, index) => SizedBox(
          width: 155,
          child: _rankedPosterCard(items[index], compact: true),
        ),
      ),
    );
  }

  /// Only a personal rating plus an actual written review earns a halo.
  Widget _rankedPosterCard(Work work, {bool compact = false}) {
    final personal = entry(work);
    final tier = SaturnReviewClassification.of(personal);
    final stars = SaturnReviewClassification.stars(personal);
    final comment = (personal['notes'] ?? '').toString().trim();
    final selected = _selectedWorkIds.contains(work.id);
    void select() => setState(() {
      if (!_selectedWorkIds.add(work.id)) {
        _selectedWorkIds.remove(work.id);
      }
    });
    return SaturnHoverLift(
      child: AnimatedContainer(
        key: Key('saturn-ranked-card-' + work.id),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFF241B27),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: tier == null
                ? const Color(0x554C3547)
                : Colors.transparent,
            width: tier == null ? 1 : 0,
          ),
        ),
        child: SaturnMetallicHalo(
          key: tier == null ? null : Key('saturn-review-halo-' + work.id),
          color: tier?.color,
          child: Material(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFF251C2A),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _selectingWorks ? select : () => _details(work),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Stack(fit: StackFit.expand, children: [
                  PosterThumbnail(
                    work: work,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  if (_selectingWorks)
                    Positioned(
                      top: 3, left: 3,
                      child: Checkbox(
                        key: Key('saturn-poster-select-' + work.id),
                        value: selected,
                        onChanged: (_) => select(),
                      ),
                    ),
                ])),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 2),
                  child: Text(work.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ivory, fontSize: 12.5,
                      fontWeight: FontWeight.w700, height: 1.12)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 1, 8, 4),
                  child: Text(
                    tier == null || stars == null
                        ? (work.year > 0
                            ? work.kind + ' · ' + work.year.toString()
                            : work.kind)
                        : stars.toStringAsFixed(1) + ' ★ / 5',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tier?.color ?? const Color(0xFFCEB9C6),
                      fontSize: 10,
                      fontWeight: tier == null
                          ? FontWeight.w400 : FontWeight.w700),
                  ),
                ),
                if (tier != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                    child: Text('“$comment”',
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFDECBD4),
                        fontSize: 10.5, height: 1.15)),
                  ),
                if (!compact && !_selectingWorks)
                  SizedBox(height: 35, child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        tooltip: work.kind == 'Livro' ? 'Quero ler' : 'Watchlist',
                        constraints: const BoxConstraints(
                          minWidth: 35, minHeight: 33),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: () => _toggleWatchlist(work),
                        icon: Icon(_isWatchlisted(work)
                            ? Icons.bookmark_added_rounded
                            : Icons.bookmark_add_outlined,
                            color: gold)),
                      IconButton(
                        tooltip: work.kind == 'Livro'
                            ? 'Marcar como lido' : 'Marcar como assistido',
                        constraints: const BoxConstraints(
                          minWidth: 35, minHeight: 33),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: () => _toggleCompleted(work),
                        icon: Icon(_isDone(work)
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                            color: gold)),
                      IconButton(
                        tooltip: 'Adicionar à Nossa Órbita',
                        constraints: const BoxConstraints(
                          minWidth: 35, minHeight: 33),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: () => toggleShared(work),
                        icon: Icon(shared.contains(work.id)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                            color: gold)),
                    ],
                  )),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _start() {
    final continuing = allWorks.where(
      (work) => !_isArchived(work) &&
          entry(work)['status'] == 'Em andamento',
    ).toList();
    final watchlistTitles = allWorks.where((work) =>
      !_isArchived(work) && work.kind != 'Livro' &&
      currentWatchlist.contains(work.id)).toList(growable: false);
    final bookshelfTitles = allWorks.where((work) =>
      !_isArchived(work) && work.kind == 'Livro' &&
      (currentWatchlist.contains(work.id) ||
          entry(work)['status'] != null)).toList(growable: false);
    final ownCount = allWorks.where(
      (work) => !_isArchived(work) &&
          entry(work)['status'] != null,
    ).length;
    return ListView(
      children: [
        if (MediaQuery.sizeOf(context).width < 1000)
          _mobileSyncShortcut('home'),
        _cinematicHero(ownCount),
        _heading('Minha Watchlist'),
        _collectionSelectionToolbar(
          watchlistTitles,
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
        if (watchlistTitles.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 9, 18, 5),
            child: Text(
              'Toque em + Watchlist na ficha de um filme, anime, dorama ou série.',
              style: TextStyle(color: Color(0xFFB5A1A9)),
            ),
          ),
        _rankedShelf(watchlistTitles,
            shelfKey: 'saturn-home-watchlist-shelf'),
        if (watchlistTitles.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                tab = 2;
                _recentTabs.remove(2);
                _recentTabs.add(2);
                if (_recentTabs.length > 2) _recentTabs.removeAt(0);
                _collectionKind = 'Tudo';
              }),
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('Ver todas as capas'),
            ),
          ),
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
        _cinematicShelf(
          recommendedMovies.where(
            (w) => !_isDone(w) && !currentWatchlist.contains(w.id)),
        ),
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
        _rankedShelf(bookshelfTitles,
            shelfKey: 'saturn-home-bookshelf-shelf'),
        if (bookshelfTitles.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 9, 18, 5),
            child: Text('Sua estante está vazia. Adicione um livro para ler.',
              style: TextStyle(color: Color(0xFFB5A1A9))),
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                tab = 2;
                _recentTabs.remove(2);
                _recentTabs.add(2);
                if (_recentTabs.length > 2) _recentTabs.removeAt(0);
                _collectionKind = 'Livros';
              }),
              icon: const Icon(Icons.auto_stories_outlined, size: 18),
              label: const Text('Abrir toda a estante'),
            ),
          ),
        _heading('Livros para descobrir'),
        if (loadingRecommendations && recommendedBooks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Buscando livros da Open Library...',
              style: TextStyle(color: Color(0xFFB5A1A9))),
          ),
        _cinematicShelf(recommendedBooks),
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
            onPressed: () => _navigateTab(1),
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
      _recentTabs.remove(1);
      _recentTabs.add(1);
      if (_recentTabs.length > 2) _recentTabs.removeAt(0);
    });
  }

  void _catalogEditionAction(Work work, void Function(Work) action) {
    if (work.kind != 'Livro' ||
        !work.id.startsWith('openlibrary:/works/')) {
      action(work);
      return;
    }
    // A parent work is not necessarily a volume. Ask for the printing
    // before performing a list action so the note never joins an omnibus.
    _chooseBookEdition(work).then((edition) {
      if (edition != null && mounted) action(edition);
    });
  }

  Widget _explore() => CatalogExplore(
        active: tab == 1,
        requestedFilter: _catalogFilter,
        onOpen: _details,
        onToggleShared: (work) => _catalogEditionAction(work, toggleShared),
        isShared: (work) => shared.contains(work.id),
        onToggleWatchlist: (work) =>
            _catalogEditionAction(work, _toggleWatchlist),
        isWatchlisted: _isWatchlisted,
        onToggleCompleted: (work) =>
            _catalogEditionAction(work, _toggleCompleted),
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


  List<Work> _filteredCollection(Iterable<Work> source, bool sharedList) {
    final selected = sharedList ? _sharedKind : _collectionKind;
    final kind = _collectionTypes[selected] ?? '';
    return source.where((w) => kind.isEmpty || w.kind == kind)
        .toList(growable: false);
  }

  Widget _collectionHeader(bool sharedList, int count) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 13),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0x665E4553)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF49233A), Color(0xFF241A2A), night]),
      ),
      child: Row(children: [
        Icon(sharedList ? Icons.favorite_rounded
            : Icons.collections_bookmark_rounded, color: gold, size: 32),
        const SizedBox(width: 13),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sharedList ? 'Nossa órbita ♡' : 'Minha coleção',
              style: const TextStyle(color: ivory, fontFamily: 'serif',
                fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(sharedList
                ? 'Histórias que fazem parte da nossa trajetória'
                : 'Seu cinema, sua estante, suas memórias',
              style: const TextStyle(color: Color(0xFFDAC8D0), fontSize: 12)),
          ],
        )),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xAA241723),
            borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text('$count', style: const TextStyle(
              color: gold, fontSize: 23, fontWeight: FontWeight.w700)))),
      ]),
    ),
  );

  Widget _collectionFilters(bool sharedList) {
    final selected = sharedList ? _sharedKind : _collectionKind;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(spacing: 7, runSpacing: 2, children: [
        for (final kind in _collectionTypes.keys)
          ChoiceChip(
            key: Key('saturn-${sharedList ? 'shared' : 'collection'}-filter-$kind'),
            label: Text(kind),
            selected: selected == kind,
            selectedColor: wine,
            onSelected: (_) => setState(() {
              if (sharedList) {
                _sharedKind = kind;
              } else {
                _collectionKind = kind;
              }
              // Prevent bulk actions on items hidden by the changed filter.
              _selectingWorks = false;
              _selectedWorkIds.clear();
            }),
          ),
      ]),
    );
  }

  /// Responsive at phone, tablet and desktop widths. Keep cover cards and
  /// multi-select in the same layout, rather than returning to giant rows.
  Widget _rankedGalleryGrid(List<Work> items) =>
      LayoutBuilder(builder: (context, constraints) {
    final columns = (constraints.maxWidth / 182).floor().clamp(2, 6).toInt();
    return GridView.builder(
      key: Key('saturn-ranked-gallery-' + items.first.id),
      padding: const EdgeInsets.fromLTRB(9, 3, 9, 13),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 316,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemBuilder: (context, index) =>
          _rankedPosterCard(items[index]),
    );
  });

  /// Seamless cover wall, highest personal ratings first. A small metallic
  /// rim conveys the category without labels or interstitial headings.
  Widget _collectionContents(List<Work> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final ranked = SaturnReviewClassification.sorted<Work>(
      items, (work) => entry(work));
    return _rankedGalleryGrid(ranked);
  }

  Widget _collection() {
    final all = allWorks.where((w) =>
        !_isArchived(w) &&
        (entry(w)['status'] != null || currentWatchlist.contains(w.id)))
        .toList();
    final items = _filteredCollection(all, false);
    return ListView(children: [
      _collectionHeader(false, all.length),
      _collectionFilters(false),
      _collectionSelectionToolbar(items),
      _collectionContents(items),
      if (items.isEmpty)
        Padding(padding: const EdgeInsets.all(16),
          child: Text(all.isEmpty
              ? 'Sua coleção está vazia. Explore e escolha um título.'
              : 'Nenhum título desta categoria na sua coleção.')),
    ]);
  }


  Widget _orbitMetric(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x8D211825),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x775F4054)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: gold, size: 17),
        const SizedBox(width: 8),
        Text('$count', style: const TextStyle(
          color: ivory, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(
          color: Color(0xFFDED0D9), fontSize: 11)),
      ]),
    );
  }

  /// Editorial summary of the shared IDs, never a claim of remote sync.
  Widget _sharedUniverseHero(SaturnCoupleInsights insights) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 11),
      padding: const EdgeInsets.fromLTRB(21, 21, 21, 23),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0x776F4B61)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF632B49), Color(0xFF342139), night],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SaturnMark(size: 41),
          const SizedBox(width: 12),
          const Expanded(child: Text('NOSSA ÓRBITA',
            style: TextStyle(color: gold, letterSpacing: 2.2,
              fontSize: 11, fontWeight: FontWeight.bold))),
          const Icon(Icons.favorite_rounded,
            color: Color(0xFFE9A8BD), size: 23),
        ]),
        const SizedBox(height: 18),
        const Text('Duas histórias. Um universo.',
          style: TextStyle(
            fontFamily: 'serif', fontSize: 27, height: 1.12,
            fontWeight: FontWeight.bold, color: ivory)),
        const SizedBox(height: 7),
        const Text(
          'Filmes, séries e leituras que fazem parte da trajetória de vocês.',
          style: TextStyle(
            color: Color(0xFFE4CCD5), fontSize: 12, height: 1.4)),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0x55322438),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x77765C68))),
          child: Row(children: [
            const Text('🪐', style: TextStyle(fontSize: 23)),
            const SizedBox(width: 7),
            Flexible(child: Text(profiles[0], maxLines: 1,
              overflow: TextOverflow.ellipsis, style: const TextStyle(
              color: ivory, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            const Expanded(child: Divider(color: Color(0x997A5868))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.favorite_rounded,
                color: Color(0xFFF0B6C2), size: 20)),
            const Expanded(child: Divider(color: Color(0x997A5868))),
            const SizedBox(width: 10),
            Flexible(child: Text(profiles[1], maxLines: 1,
              overflow: TextOverflow.ellipsis, style: const TextStyle(
              color: ivory, fontWeight: FontWeight.w700))),
            const SizedBox(width: 7),
            const Text('🌙', style: TextStyle(fontSize: 23)),
          ]),
        ),
        const SizedBox(height: 15),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _orbitMetric('histórias', insights.ids.length,
            Icons.auto_stories_outlined),
          _orbitMetric('vividas pelos dois', insights.completedTogether,
            Icons.check_circle_outline_rounded),
          _orbitMetric('em andamento', insights.inProgress,
            Icons.timelapse_rounded),
          _orbitMetric('com memórias', insights.memories,
            Icons.favorite_border_rounded),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            onPressed: () => _navigateTab(1),
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text('Descobrir juntos')),
          OutlinedButton.icon(
            onPressed: _showOrbitSync,
            icon: Icon(_cloud?.connected == true
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined, size: 18),
            label: Text(_cloud?.connected == true
                ? 'Órbita conectada' : 'Sincronização'),
          ),
        ]),
        const SizedBox(height: 12),
        Text(
          _cloud?.connected == true
              ? 'Perfis conectados à Nossa Órbita.'
              : 'Estas memórias estão neste aparelho. Para aparecerem no '
                'outro celular, a sincronização precisa ser configurada.',
          style: const TextStyle(
            color: Color(0xFFDAC6CF), fontSize: 11, height: 1.35),
        ),
      ]),
    );
  }

  Widget _sharedMomentFilters() {
    const choices = [
      'Todas', 'Para descobrir', 'Em andamento', 'Vividas por nós',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 3, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('MOMENTOS DA NOSSA HISTÓRIA',
          style: TextStyle(color: gold, fontSize: 11,
            letterSpacing: 1.4, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(spacing: 7, runSpacing: 6, children: [
          for (final choice in choices)
            ChoiceChip(
              key: Key('saturn-shared-moment-$choice'),
              label: Text(choice),
              selected: _sharedMoment == choice,
              selectedColor: wine,
              onSelected: (_) => setState(() {
                _sharedMoment = choice;
                _selectingWorks = false;
                _selectedWorkIds.clear();
              }),
            ),
        ]),
      ]),
    );
  }

  Widget _sharedPersonLine(String name, int person, Work work,
      SaturnCoupleInsights insights) {
    final record = insights.profile(person, work.id);
    final rated = record['rating'];
    final stars = rated is num && rated > 0
        ? ' • ★ ${starsFromLegacy(rated).toStringAsFixed(1)}'
        : '';
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        '$name: ${insights.profileStatus(
          person, work.id, book: work.kind == 'Livro')}$stars',
        maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFE5D1DB), fontSize: 11, height: 1.25),
      ),
    );
  }

  Widget _sharedFeatured(Work work, SaturnCoupleInsights insights) {
    final complete = insights.finishedTogether(work.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 9),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF281E2D),
        child: InkWell(
          onTap: () => _details(work),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(complete
                    ? 'UMA HISTÓRIA QUE JÁ VIVEMOS'
                    : 'UMA HISTÓRIA PARA VIVER JUNTOS',
                  style: const TextStyle(color: gold, fontSize: 10,
                    letterSpacing: 1.6, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PosterThumbnail(work: work, width: 103, height: 145),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(work.title, maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'serif',
                          color: ivory, fontSize: 21,
                          fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('${work.kind} • ${work.year > 0 ? work.year : 'Ano não informado'}',
                        style: const TextStyle(
                          color: gold, fontSize: 11)),
                      const SizedBox(height: 7),
                      _sharedPersonLine(profiles[0], 0, work, insights),
                      _sharedPersonLine(profiles[1], 1, work, insights),
                      const SizedBox(height: 10),
                      const Text('Abrir história e resenhas',
                        style: TextStyle(
                          color: Color(0xFFD1B7C5),
                          fontSize: 11, decoration: TextDecoration.underline)),
                    ],
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sharedMemoryCard(Work work, SaturnCoupleInsights insights) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 9),
      color: const Color(0xFF251C28),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _details(work),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PosterThumbnail(work: work, width: 62, height: 88),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(work.title, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ivory, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                for (var person = 0; person < 2; person++)
                  if ((insights.profile(person, work.id)['notes'] ?? '')
                      .toString().trim().isNotEmpty) ...[
                    Text(profiles[person],
                      style: const TextStyle(
                        color: gold, fontSize: 10,
                        fontWeight: FontWeight.bold)),
                    Text(
                      '“${insights.profile(person, work.id)['notes'].toString().trim()}”',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE6D6DF),
                        fontSize: 11, height: 1.35)),
                    const SizedBox(height: 4),
                  ],
              ],
            )),
          ]),
        ),
      ),
    );
  }



  // Cover-first ritual: actions remain available in the contextual menu
  // without filling each couple card with multiple labels and instructions.
  Widget _ritualProposer(String period, bool book, int person) {
    final key = SaturnOrbitRituals.nomination(period, person);
    final nominatedId = _ritualId(key);
    final work = _ritualWork(nominatedId);
    final chosenId = _ritualId(SaturnOrbitRituals.selection(period));
    final mine = person == profile;
    final done = book && work != null &&
        SaturnOrbitRituals.bookFinishedAndRated(records, person, work.id);
    return Container(
      key: Key('saturn-ritual-' + (book ? 'book' : 'film') +
          '-person-' + person.toString()),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xAA251E2A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x665B4756)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(profileAvatars[person],
              style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 7),
          Expanded(child: Text(profiles[person],
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ivory, fontWeight: FontWeight.w700, fontSize: 13))),
          if (!book && work?.id == chosenId && work != null)
            const Icon(Icons.check_circle_rounded, color: gold, size: 18),
          if (mine && nominatedId.isNotEmpty)
            PopupMenuButton<String>(
              key: Key('saturn-ritual-actions-' +
                  (book ? 'book' : 'film') + '-' + person.toString()),
              tooltip: 'Opções da minha escolha',
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_horiz_rounded, color: gold),
              onSelected: (action) {
                if (action == 'change') {
                  _nominateRitual(period, book);
                } else if (action == 'remove') {
                  _setRitualNomination(period, person, null);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'change',
                  child: Text(book ? 'Trocar meu livro' : 'Trocar indicação'),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(book ? 'Retirar meu livro' : 'Retirar indicação'),
                ),
              ],
            ),
        ]),
        const SizedBox(height: 9),
        if (work != null)
          InkWell(
            onTap: () => _details(work),
            borderRadius: BorderRadius.circular(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PosterThumbnail(work: work, width: 80, height: 112),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(work.title, maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ivory,
                        fontSize: 14, fontWeight: FontWeight.bold,
                        height: 1.3)),
                    if (book) ...[
                      const SizedBox(height: 10),
                      _ritualBookFace(person, work),
                    ] else if (work.id == chosenId) ...[
                      const SizedBox(height: 8),
                      const Text('Nossa escolha',
                        style: TextStyle(color: gold, fontSize: 11)),
                    ],
                  ],
                )),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 17),
            child: Row(children: [
              const Icon(Icons.add_circle_outline, size: 19,
                color: Color(0xFFB9A1B0)),
              const SizedBox(width: 10),
              Expanded(child: Text(nominatedId.isEmpty
                  ? 'Aguardando escolha'
                  : 'Título não disponível neste aparelho',
                style: const TextStyle(
                  color: Color(0xFFD8C3CE), fontSize: 12))),
            ]),
          ),
        if (mine && work == null) ...[
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: () => _nominateRitual(period, book),
            icon: const Icon(Icons.add, size: 17),
            label: Text(book ? 'Escolher meu livro'
                : 'Fazer minha indicação'),
          ),
        ],
        if (book && work != null && mine && !done) ...[
          const SizedBox(height: 9),
          TextButton.icon(
            onPressed: () => _details(work),
            icon: const Icon(Icons.rate_review_outlined, size: 16),
            label: const Text('Marcar leitura e dar nota'),
          ),
        ],
        if (!book && work != null && work.id != chosenId) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _chooseRitualWork(period, work),
            icon: const Icon(Icons.favorite_border_rounded, size: 16),
            label: const Text('Escolher nosso filme'),
          ),
        ],
      ]),
    );
  }

  Widget _ritualBookFace(int person, Work selected) {
    final finished = SaturnOrbitRituals.bookFinishedAndRated(
      records, person, selected.id);
    return Tooltip(
      message: finished
          ? 'Leitura concluída e avaliada.'
          : 'Leitura do mês em andamento · o prazo ainda não terminou.',
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(finished ? Icons.check_circle_outline : Icons.auto_stories_outlined,
            size: 14, color: gold),
        const SizedBox(width: 5),
        Flexible(child: Text(profiles[person] +
            (finished ? ': Lido e avaliado' : ': Em leitura'),
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: gold, fontSize: 10.5))),
      ]),
    );
  }

  Widget _ritualCard({
    required String period,
    required String title,
    required String dateLabel,
    required bool book,
  }) {
    final chosenId = _ritualId(SaturnOrbitRituals.selection(period));
    final selected = _ritualWork(chosenId);
    return Container(
      key: Key('saturn-ritual-' + (book ? 'book' : 'film')),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFF392433), Color(0xFF231E29), Color(0xFF191A22),
        ]),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0x66765B67)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(book ? Icons.menu_book_outlined : Icons.local_movies_outlined,
            color: gold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(title,
            style: const TextStyle(color: ivory, fontFamily: 'serif',
              fontSize: 21, fontWeight: FontWeight.bold))),
          Text(dateLabel,
            style: const TextStyle(color: gold, fontSize: 10)),
        ]),
        const SizedBox(height: 13),
        LayoutBuilder(builder: (context, constraints) {
          final large = constraints.maxWidth >= 570;
          final cardWidth = large
              ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (var person = 0; person < 2; person++)
              SizedBox(width: cardWidth,
                child: _ritualProposer(period, book, person)),
          ]);
        }),
        if (!book && selected != null) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _details(selected),
            borderRadius: BorderRadius.circular(14),
            child: Row(children: [
              const Icon(Icons.favorite_rounded, color: gold, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Filme escolhido · ' + selected.title,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: ivory,
                  fontSize: 12, fontWeight: FontWeight.w600))),
              const Icon(Icons.arrow_outward_rounded, color: gold, size: 17),
            ]),
          ),
        ],
      ]),
    );
  }

  void _saveSeriesTurn(Work work, {
    required bool registerHerCurrent,
    SaturnSeriesTurn? editTurn,
  }) {
    final chosenBy = registerHerCurrent ? 1 : profile;
    final allowed = editTurn != null
        ? SaturnOrbitRituals.mayEditQueuedSeries(
            _ritualOps, editTurn, profile)
        : registerHerCurrent
            ? SaturnOrbitRituals.canRegisterHerExistingSeries(_ritualOps)
            : SaturnOrbitRituals.mayChooseSeries(_ritualOps, chosenBy);
    if (!allowed || !const {'Série', 'Anime', 'Dorama'}.contains(work.kind)) {
      return;
    }
    if (!SaturnOrbitRituals.canUseSeriesWork(
        _ritualOps, work.id, replacingNumber: editTurn?.number)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Esta série já está na maratona de vocês.')));
      return;
    }
    final number = editTurn?.number ??
        SaturnOrbitRituals.nextSeriesNumber(_ritualOps);
    final isQueued = editTurn != null ||
        SaturnOrbitRituals.currentSeries(_ritualOps) != null ||
        SaturnOrbitRituals.queuedSeries(_ritualOps).isNotEmpty;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      savedWorks.putIfAbsent(work.id, () => work);
      _ritualOps[SaturnOrbitRituals.seriesPrefix + number.toString()] = {
        'workId': work.id,
        'chosenBy': chosenBy,
        'finished': false,
        'queued': isQueued,
        'updatedAt': stamp,
      };
      if (!shared.contains(work.id)) {
        shared.add(work.id);
        _sharedOps[work.id] = {
          'present': true, 'updatedAt': stamp,
        };
      }
    });
    _save();
  }

  void _finishSharedSeries(SaturnSeriesTurn current) {
    final active = SaturnOrbitRituals.currentSeries(_ritualOps);
    if (active == null || active.number != current.number ||
        active.workId != current.workId) return;
    final upcoming = SaturnOrbitRituals.queuedSeries(_ritualOps);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _ritualOps[SaturnOrbitRituals.seriesPrefix +
          current.number.toString()] = {
        'workId': current.workId,
        'chosenBy': current.chosenBy,
        'finished': true,
        'queued': false,
        'updatedAt': stamp,
      };
      if (upcoming.isNotEmpty) {
        final next = upcoming.first;
        final key = SaturnOrbitRituals.seriesPrefix + next.number.toString();
        _ritualOps[key] = {
          'workId': next.workId,
          'chosenBy': next.chosenBy,
          'finished': false,
          'queued': false,
          'updatedAt': stamp + 1,
        };
      }
    });
    // A shared choice never overwrites personal progress or ratings.
    _save();
  }

  Future<void> _chooseSharedSeries({
    required bool registerHerCurrent,
    SaturnSeriesTurn? editing,
  }) async {
    if (editing != null) {
      if (!SaturnOrbitRituals.mayEditQueuedSeries(
          _ritualOps, editing, profile)) return;
    } else if (registerHerCurrent) {
      if (!SaturnOrbitRituals.canRegisterHerExistingSeries(_ritualOps)) return;
    } else if (!SaturnOrbitRituals.mayChooseSeries(_ritualOps, profile)) {
      return;
    }
    final client = CatalogClient();
    final searchController = TextEditingController();
    var choices = allWorks.where((w) =>
        const {'Série', 'Anime', 'Dorama'}.contains(w.kind))
        .toList(growable: true);
    var loading = false;
    var initialized = false;
    String? error;
    try {
      final chosen = await showModalBottomSheet<Work>(
        context: context, isScrollControlled: true, useSafeArea: true,
        backgroundColor: const Color(0xFF241B29),
        builder: (sheet) => StatefulBuilder(builder: (ctx, repaint) {
          Future<void> find({bool discover = false}) async {
            if (loading) return;
            final text = searchController.text.trim();
            if (!discover && text.length < 2) {
              repaint(() => error = 'Digite duas letras ou mais.');
              return;
            }
            repaint(() { loading = true; error = null; });
            try {
              final found = discover
                  ? await client.discover(CatalogFilter.series)
                  : await client.search(text, CatalogFilter.all);
              if (!sheet.mounted) return;
              repaint(() {
                final mapped = <String, Work>{
                  if (discover)
                    for (final w in choices) w.id: w,
                  for (final entry in found)
                    if (const {'Série', 'Anime', 'Dorama'}
                        .contains(entry.kind))
                      entry.id: Work.fromCatalog(entry),
                };
                choices = mapped.values.toList();
                if (choices.isEmpty) {
                  error = 'Nenhuma série encontrada. Tente outro título.';
                }
                loading = false;
              });
            } catch (_) {
              if (!sheet.mounted) return;
              repaint(() {
                error = 'Busca indisponível. Você pode usar uma série salva.';
                loading = false;
              });
            }
          }
          if (!initialized) {
            initialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (sheet.mounted) find(discover: true);
            });
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(17, 16, 17,
                MediaQuery.of(sheet).viewInsets.bottom + 16),
            child: SizedBox(
              height: (MediaQuery.sizeOf(sheet).height -
                      MediaQuery.of(sheet).viewInsets.bottom - 90)
                  .clamp(155.0, 625.0).toDouble(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(editing != null
                      ? 'Trocar minha escolha da fila'
                      : registerHerCurrent
                          ? 'Qual série ela escolheu?'
                          : 'Minha vez de escolher nossa série',
                    style: const TextStyle(
                      color: ivory, fontFamily: 'serif',
                      fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 7),
                  const Text('Esta escolha ficará na Nossa Órbita. '
                      'As notas de vocês continuam individuais.',
                    style: TextStyle(
                      color: Color(0xFFDCC8D2), fontSize: 11)),
                  const SizedBox(height: 13),
                  Row(children: [
                    Expanded(child: TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => find(),
                      decoration: const InputDecoration(
                        hintText: 'Buscar série, dorama ou anime',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder()))),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      key: const Key('saturn-series-search'),
                      onPressed: loading ? null : () => find(),
                      icon: const Icon(Icons.search)),
                  ]),
                  if (loading) const LinearProgressIndicator(color: gold),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Text(error!, style: const TextStyle(
                        color: Color(0xFFFFB3C4), fontSize: 11))),
                  const SizedBox(height: 7),
                  Expanded(child: ListView.builder(
                    itemCount: choices.length,
                    itemBuilder: (context, index) {
                      final work = choices[index];
                      return ListTile(
                        leading: PosterThumbnail(
                            work: work, width: 42, height: 60),
                        title: Text(work.title, maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                        subtitle: Text(work.kind),
                        onTap: () => Navigator.pop(sheet, work),
                      );
                    },
                  )),
                ],
              ),
            ),
          );
        }),
      );
      if (chosen != null && mounted) {
        _saveSeriesTurn(chosen,
            registerHerCurrent: registerHerCurrent, editTurn: editing);
      }
    } finally {
      client.close();
      searchController.dispose();
    }
  }

  Widget _sharedSeriesRotationCard() {
    final current = SaturnOrbitRituals.currentSeries(_ritualOps);
    final turns = SaturnOrbitRituals.seriesTurns(_ritualOps);
    final queue = SaturnOrbitRituals.queuedSeries(_ritualOps);
    final completed = turns.where((turn) => turn.finished).toList().reversed;
    final next = SaturnOrbitRituals.nextSeriesPicker(_ritualOps);
    final canPick = SaturnOrbitRituals.mayChooseSeries(_ritualOps, profile);
    final work = current == null ? null : _ritualWork(current.workId);
    final compact = MediaQuery.sizeOf(context).width < 550;
    return Container(
      key: const Key('saturn-shared-series'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 17),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            Color(0xFF51283E), Color(0xFF2D2030), Color(0xFF171821),
          ]),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x997D5B69)),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000),
            blurRadius: 24, offset: Offset(0, 11)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0x335D344E),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0x556E5262)),
              ),
              child: const Icon(Icons.live_tv_rounded, color: gold, size: 23),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NOSSA MARATONA',
                  style: TextStyle(color: gold, letterSpacing: 1.8,
                    fontSize: 10, fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('Nossa série da vez',
                  style: TextStyle(color: ivory, fontFamily: 'serif',
                    fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x334D3A48),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(queue.length.toString() + ' na fila',
                style: const TextStyle(color: gold, fontSize: 11,
                  fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 10),
          if (current != null) ...[
            Text(profiles[current.chosenBy] + ' escolheu desta vez.',
              style: const TextStyle(color: Color(0xFFDFC3CD),
                fontSize: 12)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF392B3C), Color(0xFF252331)]),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: const Color(0x99775667)),
              ),
              child: Row(children: [
                if (work != null)
                  InkWell(
                    onTap: () => _details(work),
                    child: PosterThumbnail(
                        work: work,
                        width: compact ? 95 : 123,
                        height: compact ? 141 : 177),
                  )
                else
                  Container(width: compact ? 95 : 123,
                    height: compact ? 141 : 177,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF322632),
                      borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.movie_outlined, color: gold)),
                const SizedBox(width: 13),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ASSISTINDO JUNTOS',
                      style: TextStyle(color: gold, letterSpacing: 1.2,
                        fontWeight: FontWeight.bold, fontSize: 10)),
                    const SizedBox(height: 7),
                    Text(work?.title ?? 'Série salva na nossa órbita',
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ivory,
                        fontFamily: 'serif', fontSize: 19,
                        fontWeight: FontWeight.bold)),
                    if (work != null) ...[
                      const SizedBox(height: 8),
                      const Text('Toque na capa para abrir',
                        style: TextStyle(
                          color: Color(0xFFCDB8C4), fontSize: 10)),
                    ],
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('saturn-series-finish'),
              onPressed: () => _finishSharedSeries(current),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Concluímos esta série'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0x553A2A3B),
                borderRadius: BorderRadius.circular(17)),
              child: Row(children: [
                const Icon(Icons.auto_awesome_outlined, color: gold),
                const SizedBox(width: 10),
                Expanded(child: Text(turns.isEmpty
                    ? 'Registrem a série que ela escolheu e comecem '
                      'a planejar os próximos capítulos.'
                    : 'Uma história terminou. A próxima escolha '
                      'já pode começar.',
                  style: const TextStyle(
                    color: Color(0xFFE8D5DE), fontSize: 12))),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.queue_play_next_rounded,
                color: gold, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text('PRÓXIMOS CAPÍTULOS',
              style: TextStyle(color: ivory, letterSpacing: 1.3,
                fontSize: 11, fontWeight: FontWeight.w800))),

          ]),
          const SizedBox(height: 11),
          for (var i = 0; i < queue.length; i++) ...[
            Builder(builder: (context) {
              final turn = queue[i];
              final upcoming = _ritualWork(turn.workId);
              final editable = SaturnOrbitRituals.mayEditQueuedSeries(
                  _ritualOps, turn, profile);
              return Container(
                key: Key('saturn-series-queued-' + i.toString()),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0x88332636),
                  border: Border.all(color: const Color(0x66684A5B)),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(children: [
                  Container(
                    width: 25, height: 25,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF775068),
                      shape: BoxShape.circle),
                    child: Text((i + 1).toString(),
                      style: const TextStyle(color: ivory,
                        fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(width: 10),
                  if (upcoming != null)
                    InkWell(
                      onTap: () => _details(upcoming),
                      child: PosterThumbnail(
                          work: upcoming,
                          width: compact ? 60 : 74,
                          height: compact ? 87 : 106))
                  else
                    Container(width: compact ? 60 : 74,
                      height: compact ? 87 : 106,
                      decoration: BoxDecoration(
                        color: wine,
                        borderRadius: BorderRadius.circular(7)),
                      child: const Icon(Icons.movie_outlined, color: gold)),
                  const SizedBox(width: 11),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(upcoming?.title ?? 'Série reservada',
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: ivory,
                          fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text('Escolha de ' + profiles[turn.chosenBy],
                        style: const TextStyle(
                          color: Color(0xFFDFC0CF), fontSize: 11)),

                    ],
                  )),
                  if (editable)
                    IconButton(
                      key: Key('saturn-series-edit-' +
                          turn.number.toString()),
                      tooltip: 'Trocar minha escolha',
                      onPressed: () => _chooseSharedSeries(
                          registerHerCurrent: false, editing: turn),
                      icon: const Icon(Icons.edit_outlined,
                          color: gold, size: 20)),
                ]),
              );
            }),
          ],
          if (queue.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0x442F2A37),
                border: Border.all(color: const Color(0x556B5663)),
                borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.add_circle_outline,
                  color: gold, size: 28),
                const SizedBox(width: 11),
                Expanded(child: Text(turns.isEmpty
                    ? 'A fila aparecerá aqui depois da primeira escolha.'
                    : 'A próxima história ainda não foi escolhida.',
                  style: const TextStyle(
                    color: Color(0xFFE1CBD5), fontSize: 12))),
              ]),
            ),
          const SizedBox(height: 15),
          Row(children: [
            const Icon(Icons.autorenew_rounded, color: gold, size: 17),
            const SizedBox(width: 7),
            Expanded(child: Text(
              'Próxima escolha: ' + profiles[turns.isEmpty ? 0 : next],
              style: const TextStyle(
                color: gold, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 10),
          if (turns.isEmpty)
            FilledButton.icon(
              key: const Key('saturn-series-register-current'),
              onPressed: () =>
                  _chooseSharedSeries(registerHerCurrent: true),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Registrar série que ela escolheu')),
          if (turns.isNotEmpty && canPick)
            FilledButton.icon(
              key: const Key('saturn-series-next-choice'),
              onPressed: () =>
                  _chooseSharedSeries(registerHerCurrent: false),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Escolher minha próxima série')),

          if (completed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: const PageStorageKey('saturn-series-history'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded,
                    color: gold, size: 20),
                title: Text(
                  'Nosso histórico · ' + completed.length.toString() +
                      ' concluída(s)',
                  style: const TextStyle(
                    color: Color(0xFFE8D8DD), fontSize: 12)),
                children: [
                  for (final past in completed)
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 8),
                      title: Text(_ritualWork(past.workId)?.title ??
                          'Série salva na órbita'),
                      subtitle: Text('Escolha de ' +
                          profiles[past.chosenBy]),
                      trailing: const Icon(Icons.check_circle_outline,
                          color: gold, size: 18),
                      onTap: _ritualWork(past.workId) == null ? null
                          : () => _details(_ritualWork(past.workId)!),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pastBookReminders(DateTime now) {
    final current = _ritualId(SaturnOrbitRituals.nomination(
      SaturnOrbitRituals.monthPeriod(now), profile));
    final pending = SaturnOrbitRituals.pendingBooks(
      _ritualOps, records, profile, now)
        .where((id) => id != current).toSet().toList();
    if (pending.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      child: Card(
        color: const Color(0xFF2A1F2C),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('😢 Leitura pendente de outro mês (${profiles[profile]})',
                style: const TextStyle(
                  color: ivory, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'A carinha triste só muda quando terminar a leitura '
                'e registrar uma nota.',
                style: TextStyle(
                  color: Color(0xFFCFBAC5), fontSize: 11)),
              for (final id in pending)
                ListTile(
                  title: Text(_ritualWork(id)?.title ?? 'Livro salvo indisponível'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _ritualWork(id) == null
                      ? null : () => _details(_ritualWork(id)!),
                ),
            ],
          ),
        ),
      ),
    );
  }


  /// Prominent true cover art. Opens the original title without changing data.
  Widget _orbitCoverRail(List<Work> works, {String keyName = 'saturn-orbit-rail'}) {
    return SizedBox(height: 219, child: ListView.separated(
      key: Key(keyName),
      scrollDirection: Axis.horizontal,
      itemCount: works.length,
      separatorBuilder: (_, __) => const SizedBox(width: 11),
      itemBuilder: (context, index) {
        final w = works[index];
        return SizedBox(width: 122, child: InkWell(
          onTap: () => _details(w),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosterThumbnail(work: w, width: 119, height: 176),
              const SizedBox(height: 6),
              Text(w.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ivory, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
        ));
      },
    ));
  }

  Widget _sharedCoverWall() {
    final active = SaturnOrbitRituals.currentSeries(_ritualOps);
    final queue = SaturnOrbitRituals.queuedSeries(_ritualOps);
    final seen = <String>{};
    final works = <Work>[];
    for (final id in <String>[
      if (active != null) active.workId,
      ...queue.map((turn) => turn.workId),
      ...shared.reversed,
    ]) {
      final w = savedWorks[id];
      if (w != null && seen.add(id)) works.add(w);
      if (works.length >= 12) break;
    }
    if (works.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('saturn-shared-cover-wall'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          colors: [Color(0xFF4B293D), Color(0xFF201E2E)]),
        border: Border.all(color: const Color(0x88795669))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CAPAS DA NOSSA HISTÓRIA',
            style: TextStyle(color: gold, fontSize: 11,
              fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          const Text('Nossas escolhas merecem o primeiro plano.',
            style: TextStyle(color: Color(0xFFE6D0D9), fontSize: 12)),
          const SizedBox(height: 13),
          _orbitCoverRail(works, keyName: 'saturn-shared-cover-rail'),
        ]),
    );
  }

  /// Only the other profile's data is read; personal records are not edited.
  Widget _partnerShelves() {
    final other = 1 - profile;
    final list = watchlists[other] ?? <String>{};
    final month = SaturnOrbitRituals.monthPeriod(DateTime.now());
    final bookId = _ritualId(SaturnOrbitRituals.nomination(month, other));
    final book = _ritualWork(bookId);
    final works = <Work>[];
    for (final w in allWorks) {
      if (_archivedFromCollection.contains(
          other.toString() + ':' + w.id)) continue;
      final record = records[other.toString() + ':' + w.id];
      final inCollection = (record is Map && record['status'] != null)
          || list.contains(w.id);
      final show = switch (_partnerShelfView) {
        'Watchlist' => list.contains(w.id) && w.kind != 'Livro',
        'Coleção' => inCollection,
        _ => w.kind == 'Livro' && (inCollection || w.id == bookId),
      };
      if (show) works.add(w);
    }
    if (_partnerShelfView == 'Livros' &&
        book != null && !works.any((w) => w.id == book.id)) {
      works.insert(0, book);
    }
    return Container(
      key: const Key('saturn-partner-shelves'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A202F),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0x88765966))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(profileAvatars[other], style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('A OUTRA METADE DA ÓRBITA',
                style: TextStyle(color: gold, fontSize: 10,
                  letterSpacing: 1.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('O universo de ' + profiles[other],
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: ivory, fontFamily: 'serif',
                  fontSize: 21, fontWeight: FontWeight.bold)),
            ])),
          const Icon(Icons.visibility_outlined, color: gold),
        ]),
        const SizedBox(height: 8),
        const Text('Explore as escolhas do outro perfil sem alterar '
          'suas listas, notas ou leituras.',
          style: TextStyle(color: Color(0xFFE2CED6), fontSize: 11)),
        const SizedBox(height: 13),
        Wrap(spacing: 7, runSpacing: 5, children: [
          for (final option in const ['Watchlist', 'Coleção', 'Livros'])
            ChoiceChip(
              key: Key('saturn-partner-filter-' + option),
              label: Text(option),
              selected: option == _partnerShelfView,
              selectedColor: wine,
              onSelected: (_) => setState(() => _partnerShelfView = option)),
        ]),
        if (_partnerShelfView == 'Livros' && book != null) ...[
          const SizedBox(height: 12),
          InkWell(
            key: const Key('saturn-partner-book-of-month'),
            onTap: () => _details(book),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A2D42), Color(0xFF2A2635)])),
              child: Row(children: [
                PosterThumbnail(work: book, width: 89, height: 132),
                const SizedBox(width: 13),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('LIVRO DO MÊS',
                      style: TextStyle(color: gold, fontSize: 10,
                        fontWeight: FontWeight.bold)),
                    const SizedBox(height: 7),
                    Text(book.title, maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ivory,
                        fontFamily: 'serif', fontSize: 17,
                        fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Escolha de ' + profiles[other],
                      style: const TextStyle(
                        color: Color(0xFFE5CBD5), fontSize: 11)),
                  ])),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(works.length.toString() + ' título(s) · ' + _partnerShelfView,
          style: const TextStyle(color: gold, fontSize: 11)),
        const SizedBox(height: 9),
        if (works.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Text(_cloud?.connected == true
                ? 'Nenhum título registrado nesta lista do outro perfil.'
                : 'Ainda não há títulos sincronizados neste aparelho. '
                  'Conecte a Nossa Órbita para compartilhar os registros.',
              style: const TextStyle(
                color: Color(0xFFD9C1CD), fontSize: 12)),
          )
        else
          _orbitCoverRail(works, keyName: 'saturn-partner-cover-rail'),
      ]),
    );
  }

  Widget _sharedYearRecap(DateTime today) {
    if (!SaturnYearRecap.visibleOn(today)) {
      return const SizedBox.shrink();
    }
    final ids = SaturnYearRecap.updatedSharedIds(
        records, shared, today.year);
    final reviews = SaturnYearRecap.reviewsUpdatedInYear(
        records, shared, today.year);
    final covers = ids.map(_ritualWork)
        .whereType<Work>().take(10).toList(growable: false);
    return Container(
      key: const Key('saturn-year-recap'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xAAA58A76)),
        gradient: const LinearGradient(colors: [
          Color(0xFF60314D), Color(0xFF37263C), Color(0xFF1D1D2A),
        ])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RETROSPECTIVA · NOSSA ÓRBITA',
          style: TextStyle(color: gold, fontSize: 11,
            letterSpacing: 1.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('O nosso ' + today.year.toString() + ' em histórias',
          style: const TextStyle(color: ivory, fontFamily: 'serif',
            fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Os momentos que registramos juntos neste ano.',
          style: TextStyle(color: Color(0xFFE6D2DC), fontSize: 12)),
        const SizedBox(height: 15),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _orbitMetric('títulos registrados', ids.length,
              Icons.auto_stories_outlined),
          _orbitMetric('resenhas do ano', reviews,
              Icons.rate_review_outlined),
        ]),
        if (covers.isNotEmpty) ...[
          const SizedBox(height: 15),
          _orbitCoverRail(covers, keyName: 'saturn-recap-covers'),
        ] else ...[
          const SizedBox(height: 12),
          const Text('Sem registros datados neste ano.',
            style: TextStyle(color: ivory, fontSize: 12)),
        ],
        const SizedBox(height: 10),
        const Text('Resumo de registros datados, sem inventar '
          'quando os títulos foram assistidos.',
          style: TextStyle(
            color: Color(0xFFDCC6D0), fontSize: 10)),
      ]),
    );
  }

  Widget _shared() {
    final all = allWorks.where((work) => shared.contains(work.id)).toList();
    final insights = SaturnCoupleInsights(
        all.map((work) => work.id), records);
    final byType = _filteredCollection(all, true);
    final items = byType.where(
      (work) => insights.matches(work.id, _sharedMoment),
    ).toList(growable: false);
    final featured = items.where(
      (work) => !insights.finishedTogether(work.id),
    ).lastOrNull ?? items.lastOrNull;
    final memories = items.where(
      (work) => insights.hasMemory(work.id),
    ).take(3).toList(growable: false);
    return ListView(
      key: const PageStorageKey('saturn_shared_orbit'),
      children: [
        if (MediaQuery.sizeOf(context).width < 1000)
          _mobileSyncShortcut('couple'),
        _sharedUniverseHero(insights),
        _sharedCoverWall(),
        _coupleSuggestionsCard(),
        _sharedYearRecap(DateTime.now()),
        _heading('Nossos encontros'),
        _sharedSeriesRotationCard(),
        _ritualCard(
          period: SaturnOrbitRituals.weekendPeriod(DateTime.now()),
          title: 'Filme do fim de semana',
          dateLabel: SaturnOrbitRituals.weekendLabel(DateTime.now()),
          book: false,
        ),
        _ritualCard(
          period: SaturnOrbitRituals.monthPeriod(DateTime.now()),
          title: 'Nossos livros do mês',
          dateLabel: SaturnOrbitRituals.monthLabel(DateTime.now()),
          book: true,
        ),
        _pastBookReminders(DateTime.now()),
        _partnerShelves(),
        _sharedMomentFilters(),
        _collectionFilters(true),
        if (featured != null)
          _sharedFeatured(featured, insights),
        if (memories.isNotEmpty) ...[
          _heading('Memórias da nossa órbita'),
          ...memories.map((work) => _sharedMemoryCard(work, insights)),
        ],
        _heading('Nossa biblioteca'),
        _collectionSelectionToolbar(items, sharedList: true),
        _collectionContents(items),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            child: Text(
              all.isEmpty
                  ? 'Ainda não há histórias na lista de vocês. '
                    'Descubram algo e adicionem à Nossa Órbita.'
                  : 'Não há histórias neste recorte. '
                    'Experimente outro tipo ou momento.',
              style: const TextStyle(
                color: Color(0xFFD8C3CE), fontSize: 13),
            ),
          ),
      ],
    );
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


  /// Hero cinematográfico feito com a capa autêntica da obra.
  Widget _cinematicDetailBanner(Work work) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 630;
      final titleWidth = (constraints.maxWidth - (wide ? 250.0 : 128.0))
          .clamp(142.0, 640.0).toDouble();
      return ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: SizedBox(
          height: wide ? 282 : 237,
          child: Stack(fit: StackFit.expand, children: [
            const DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF54283D), Color(0xFF251928), night]))),
            if (work.posterUrl.startsWith('https://'))
              Positioned.fill(child: Opacity(
                opacity: 0.32,
                child: wide
                    ? ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 12, sigmaY: 12),
                        child: Image.network(
                          SaturnBookCover.resolve(work.id, work.posterUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              const SizedBox.shrink()))
                    : Image.network(
                        SaturnBookCover.resolve(work.id, work.posterUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const SizedBox.shrink()))),
            const DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft, end: Alignment.centerRight,
                colors: [
                  Color(0xF21A1522), Color(0xD52B1C2F), Color(0x66321C2B)]))),
            Positioned(
              top: wide ? 16 : 31, bottom: wide ? 16 : 31,
              right: wide ? 25 : 11, width: wide ? 162 : 104,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PosterThumbnail(
                  work: work, width: wide ? 162 : 104,
                  height: wide ? 250 : 175))),
            Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 27 : 15, 22, 16, wide ? 23 : 19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SATURN · FICHA CINEMATOGRÁFICA',
                    style: TextStyle(color: gold, fontSize: 10,
                      fontWeight: FontWeight.w600, letterSpacing: 1.4)),
                  const Spacer(),
                  SizedBox(width: titleWidth,
                    child: Text(work.title,
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'serif', color: ivory,
                        fontWeight: FontWeight.bold,
                        fontSize: wide ? 32 : 23, height: 1.12))),
                  const SizedBox(height: 10),
                  SizedBox(width: titleWidth,
                    child: Text(
                      '${work.kind} · ${work.year > 0 ? work.year : 'Ano não informado'}'
                      '${work.creator.isNotEmpty ? ' · ${work.creator}' : ''}',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12, color: Color(0xFFE4D1D5)))),
                  const SizedBox(height: 7),
                  if (work.provider.isNotEmpty)
                    SizedBox(width: titleWidth,
                      child: Text('Fonte: ${work.provider}',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: gold, fontSize: 11))),
                ],
              ),
            ),
          ]),
        ),
      );
    });
  }

  Future<void> _details(Work w) async {
    // The official YouTube iframe is only created on supported web/mobile
    // runtimes. Flutter desktop test runners have no platform WebView;
    // display the same poster hero there without creating phantom views.
    final canEmbedTrailer = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    final current = entry(w);
    String status = current['status'] ?? 'Quero conhecer';
    double rating = (current['rating'] as num?)?.toDouble() ?? 0;
    bool ratingSet = current['rating'] is num;
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded, color: gold, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('FICHA DA HISTÓRIA',
                    style: TextStyle(color: gold, letterSpacing: 1.7,
                      fontSize: 11, fontWeight: FontWeight.bold))),
                  IconButton(
                    tooltip: 'Fechar detalhes',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: ivory)),
                ]),
                const SizedBox(height: 10),
                if (w.kind != 'Livro' && canEmbedTrailer &&
                    RegExp(r'^[A-Za-z0-9_-]{11}
                  SaturnTrailerPreview(
                    key: Key('saturn-trailer-' + w.id),
                    youtubeId: w.trailerYoutubeId,
                    heroMode: true,
                    workTitle: w.title,
                    workMetadata: w.kind + ' · ' +
                        (w.year > 0 ? w.year.toString() : 'SATURN')),
                if (w.kind == 'Livro' || !canEmbedTrailer ||
                    !RegExp(r'^[A-Za-z0-9_-]{11}
                  _cinematicDetailBanner(w),
                if (w.kind != 'Livro' &&
                    SaturnNativeTrailer.canUseNative(
                      w.nativeTrailerUrl,
                      rightsConfirmed: w.provider == 'SATURN Licensed',
                    )) ...[
                  const SizedBox(height: 10),
                  SaturnNativeTrailer(
                    mediaUrl: w.nativeTrailerUrl,
                    rightsConfirmed: true),
                ],
                const SizedBox(height: 12),
                if (w.kind == 'Livro' &&
                    w.id.startsWith('openlibrary:/works/')) ...[
                  const Text(
                    'Este registro reúne várias edições. Para mangás, '
                    'escolha o volume específico antes de registrar '
                    'o progresso e a nota.',
                    style: TextStyle(color: Color(0xFFDDC4D1), fontSize: 12)),
                  const SizedBox(height: 9),
                  FilledButton.icon(
                    onPressed: () async {
                      final edition = await _chooseBookEdition(w);
                      if (edition == null || edition.id == w.id ||
                          !ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (mounted) await _details(edition);
                    },
                    icon: const Icon(Icons.collections_bookmark_outlined),
                    label: const Text('Escolher volume ou edição'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (w.kind == 'Livro')
                  SaturnBookDetailsPanel(
                    bookId: w.id,
                    fallbackDescription: w.description,
                    fallbackCover: SaturnBookCover.resolve(w.id, w.posterUrl),
                  )
                else
                  SaturnStorySynopsis(description: w.description),
                if (w.kind != 'Livro')
                  SaturnRatingsFromCatalog(
                    workId: w.id,
                    workTitle: w.title,
                    kind: w.kind,
                    cachedRatings: w.externalRatings,
                    tmdbScore: w.tmdbScore,
                    tmdbVoteCount: w.tmdbVoteCount,
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
                if (w.kind == 'Filme' || w.kind == 'Livro') ...[
                  const Text('NOSSA ÓRBITA · INDICAÇÕES',
                    style: TextStyle(color: gold, fontSize: 11,
                      letterSpacing: 1.5)),
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    onPressed: () {
                      final period = w.kind == 'Livro'
                          ? SaturnOrbitRituals.monthPeriod(DateTime.now())
                          : SaturnOrbitRituals.weekendPeriod(DateTime.now());
                      _setRitualNomination(period, profile, w);
                      refresh(() {});
                    },
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: Text(w.kind == 'Livro'
                        ? 'Escolher como meu livro do mês'
                        : 'Indicar como meu filme do fim de semana'),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  key: const Key('saturn-suggest-to-partner'),
                  onPressed: () => _suggestToPartner(w),
                  icon: const Icon(Icons.favorite_border_rounded, size: 17),
                  label: Text('Sugerir para ' + profiles[1 - profile]),
                ),
                const SizedBox(height: 14),
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
                  const SizedBox(height: 15),
                  Row(children: [
                    const Expanded(child: Text('ONDE ASSISTIR · BRASIL',
                      style: TextStyle(color: gold,
                        letterSpacing: 1.4, fontSize: 11))),
                    IconButton(
                      tooltip: 'Editar meus serviços favoritos',
                      onPressed: _showStreamingPreferences,
                      icon: const Icon(Icons.tune, color: gold, size: 19),
                    ),
                  ]),
                  if (w.streamingProviders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(
                        'Nenhuma assinatura confirmada para este título.',
                        style: TextStyle(
                          color: Color(0xFFD4C2CA), fontSize: 11),
                      ),
                    ),
                  // Provider-independent eligibility. No unverified TVmaze
                  // service suggestion disguised as regional availability.
                  for (final service in StreamingService.values)
                    if (_streaming.contains(service))
                      Builder(builder: (itemContext) {
                        final stored =
                            customTitleLinks[w.id]?[service.name];
                        final sourced = w.streamingLinks[service.name];
                        final direct =
                            checkedTitleUrl(service, stored ?? sourced);
                        final verified =
                            w.streamingProviders.containsKey(service.name);
                        if (!verified && direct == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Material(
                            color: const Color(0xFF30232D),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: Color(0x554F4050))),
                            child: ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            leading: Icon(
                              verified
                                  ? Icons.verified_rounded
                                  : Icons.link_rounded,
                              color: verified
                                  ? const Color(0xFF97CDB4) : gold,
                            ),
                            title: Text(service.label,
                              style: const TextStyle(color: ivory,
                                fontWeight: FontWeight.w600)),
                            subtitle: Text(verified
                                ? 'Assinatura confirmada no Brasil'
                                : 'Link fornecido · disponibilidade não confirmada',
                              style: const TextStyle(
                                color: Color(0xFFD0BBC5), fontSize: 10)),
                            trailing: const Icon(
                              Icons.arrow_outward_rounded,
                              color: gold, size: 18),
                            onTap: direct != null
                                ? () => _openTitleLink(service, direct)
                                : verified
                                    ? () => _openTmdbWatch(w)
                                    : null,
                            ),
                          ),
                        );
                      }),
                  Theme(
                    data: Theme.of(ctx).copyWith(
                      dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: Key('saturn-streaming-search-' + w.id),
                      initiallyExpanded: false,
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.travel_explore_outlined,
                        color: gold, size: 20),
                      title: const Text('Pesquisar em meus serviços',
                        style: TextStyle(color: ivory, fontSize: 12)),
                      children: [
                        if (_streaming.isEmpty)
                          ListTile(
                            title: const Text('Escolher serviços favoritos'),
                            onTap: _showStreamingPreferences,
                          ),
                        for (final service in StreamingService.values)
                          if (_streaming.contains(service))
                            ListTile(
                              dense: true,
                              title: Text(service.label),
                              trailing: const Icon(
                                Icons.open_in_new_rounded, size: 17),
                              onTap: () => _openStreamingService(
                                  service, title: w.title),
                            ),
                      ],
                    ),
                  ),
                  if (w.availabilityUpdatedAt.length >= 10 &&
                      w.streamingProviders.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 5),
                      child: Text('Consulta: ' +
                          w.availabilityUpdatedAt.substring(0, 10) +
                          ' · JustWatch / TMDB',
                        style: const TextStyle(color: Color(0xFFAA969F),
                          fontSize: 10)),
                    ),
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
                  zeroIsRating: ratingSet,
                  onChanged: (stars) => refresh(() {
                    rating = legacyFromStars(stars);
                    ratingSet = true;
                  }),
                ),
                Wrap(spacing: 8, runSpacing: 2, children: [
                  TextButton.icon(
                    onPressed: () => refresh(() {
                      rating = 0;
                      ratingSet = true;
                    }),
                    icon: const Icon(Icons.star_outline_rounded, size: 17),
                    label: const Text('Dar 0 estrelas'),
                  ),
                  TextButton(
                    onPressed: () => refresh(() {
                      rating = 0;
                      ratingSet = false;
                    }),
                    child: const Text('Remover minha nota'),
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12, top: 2),
                  child: Text(
                    'Meia estrela é permitida. O brilho da capa '
                    'aparece quando você salva uma nota '
                    'e uma resenha escrita.',
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
                        'rating': ratingSet ? rating : null,
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
        ),
      ),
    );
    notes.dispose();
  }
}



/// Microanimação de mouse sem alterar o comportamento de toque no celular.
class SaturnHoverLift extends StatefulWidget {
  final Widget child;
  const SaturnHoverLift({super.key, required this.child});

  @override
  State<SaturnHoverLift> createState() => _SaturnHoverLiftState();
}

class _SaturnHoverLiftState extends State<SaturnHoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedScale(
      scale: _hovered ? 1.022 : 1,
      duration: const Duration(milliseconds: 165),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
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
    final coverUrl = SaturnBookCover.resolve(work.id, work.posterUrl);
    if (!coverUrl.startsWith('https://')) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        coverUrl,
        key: ValueKey('cover-' + work.id + '-' + coverUrl),
        width: width, height: height,
        fit: BoxFit.cover,
        // Decode smaller thumbnails where supported and keep low-cost
        // filtering while Safari scrolls hundreds of book/film covers.
        cacheWidth: width.isFinite && width > 0
            ? (width * MediaQuery.devicePixelRatioOf(context))
                .round().clamp(60, 780).toInt() : null,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        // Show the first decoded frame instead of hiding it until the
        // network loading callback finishes. Crossfade avoids white flashes.
        frameBuilder: (context, image, frame, synchronous) {
          if (synchronous) return image;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Stack(fit: StackFit.passthrough, children: [
              fallback,
              image,
            ]),
          );
        },
        loadingBuilder: (context, image, progress) =>
            progress == null ? image : Stack(
              fit: StackFit.passthrough,
              children: [fallback, image],
            ),
        errorBuilder: (context, error, stackTrace) {
          final second = SaturnBookCover.fallback(work.id);
          return second == null ? fallback : Image.network(
            second, width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          );
        },
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
                  if (_filter == CatalogFilter.books) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 7, children: [
                      ActionChip(
                        key: const Key('saturn-books-national'),
                        avatar: const Icon(Icons.auto_stories_outlined,
                          size: 16, color: gold),
                        label: const Text('Literatura brasileira'),
                        onPressed: () {
                          setState(() {
                            _query.clear();
                            _bookSubject = 'brazilian_literature';
                          });
                          _search();
                        },
                      ),
                      ActionChip(
                        key: const Key('saturn-books-agatha-pt'),
                        avatar: const Icon(Icons.auto_stories_outlined,
                          size: 16, color: gold),
                        label: const Text('Agatha Christie · português'),
                        onPressed: () {
                          _query.text = 'Agatha Christie';
                          _search();
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Text('Edições e capas conforme o catálogo',
                          style: TextStyle(
                            color: Color(0xFFCFBAC5), fontSize: 10)),
                      ),
                    ]),
                  ],
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


  /// Cinematic card: edge-to-edge original cover, restrained metadata and
  /// subtle metallic detailing. No extra network requests per visible card.
  Widget _coverCard(Work work) {
    final loved = widget.isShared(work);
    return SaturnHoverLift(child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3A2635), Color(0xFF1C1A24)]),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x88725265)),
        boxShadow: const [BoxShadow(
          color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(color: Colors.transparent,
        child: InkWell(
          key: Key('saturn-cinematic-cover-' + work.id),
          onTap: () => widget.onOpen(work),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Stack(fit: StackFit.expand, children: [
                PosterThumbnail(work: work,
                  width: double.infinity, height: double.infinity),
                const Positioned.fill(child: DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0x770D0D19), Colors.transparent,
                      Color(0xC9171420)],
                    stops: [0, 0.48, 1],
                  )),
                )),
                Positioned(top: 5, left: 5,
                  child: IconButton.filledTonal(
                    tooltip: work.kind == 'Livro' ? 'Quero ler' : 'Watchlist',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleWatchlist(work),
                    icon: Icon(widget.isWatchlisted(work)
                      ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                      color: ivory, size: 18))),
                Positioned(top: 5, right: 5,
                  child: IconButton.filledTonal(
                    tooltip: 'Adicionar à Nossa Órbita',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleShared(work),
                    icon: Icon(loved
                      ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      size: 18,
                      color: loved ? const Color(0xFFF0B6C2) : ivory))),
                Positioned(bottom: 6, right: 5,
                  child: IconButton.filledTonal(
                    tooltip: work.kind == 'Livro'
                      ? 'Marcar como lido' : 'Marcar como assistido',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleCompleted(work),
                    icon: Icon(widget.isCompleted(work)
                      ? Icons.check_circle : Icons.check_circle_outline,
                      color: widget.isCompleted(work)
                        ? const Color(0xFF97CDB4) : ivory, size: 18))),
                Positioned(bottom: 11, left: 10,
                  child: Text(work.kind.toUpperCase(),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: gold, letterSpacing: 1.4,
                      fontSize: 9, fontWeight: FontWeight.w800))),
              ])),
              Container(height: 2,
                decoration: const BoxDecoration(gradient: LinearGradient(
                  colors: [Color(0xFFB89269), Color(0xFF6C465E),
                    Colors.transparent]))),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 5),
                child: Text(work.title, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ivory, fontFamily: 'serif',
                    fontWeight: FontWeight.bold, fontSize: 14,
                    height: 1.2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 1, 8, 9),
                child: Text([
                  if (work.year > 0) work.year.toString(),
                  if (work.kind == 'Livro' && work.creator.isNotEmpty)
                    work.creator
                  else if (work.kind != 'Livro') work.provider,
                ].join(' · '), maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC5ADB9), fontSize: 10))),
            ],
          ),
        ),
      ),
    ));
  }

}
)
                        .hasMatch(w.trailerYoutubeId))
                  SaturnTrailerPreview(
                    key: Key('saturn-trailer-' + w.id),
                    youtubeId: w.trailerYoutubeId,
                    heroMode: true,
                    workTitle: w.title,
                    workMetadata: w.kind + ' · ' +
                        (w.year > 0 ? w.year.toString() : 'SATURN')),
                if (w.kind == 'Livro' ||
                    !RegExp(r'^[A-Za-z0-9_-]{11}$')
                        .hasMatch(w.trailerYoutubeId))
                  _cinematicDetailBanner(w),
                if (w.kind != 'Livro' &&
                    SaturnNativeTrailer.canUseNative(
                      w.nativeTrailerUrl,
                      rightsConfirmed: w.provider == 'SATURN Licensed',
                    )) ...[
                  const SizedBox(height: 10),
                  SaturnNativeTrailer(
                    mediaUrl: w.nativeTrailerUrl,
                    rightsConfirmed: true),
                ],
                const SizedBox(height: 12),
                if (w.kind == 'Livro' &&
                    w.id.startsWith('openlibrary:/works/')) ...[
                  const Text(
                    'Este registro reúne várias edições. Para mangás, '
                    'escolha o volume específico antes de registrar '
                    'o progresso e a nota.',
                    style: TextStyle(color: Color(0xFFDDC4D1), fontSize: 12)),
                  const SizedBox(height: 9),
                  FilledButton.icon(
                    onPressed: () async {
                      final edition = await _chooseBookEdition(w);
                      if (edition == null || edition.id == w.id ||
                          !ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (mounted) await _details(edition);
                    },
                    icon: const Icon(Icons.collections_bookmark_outlined),
                    label: const Text('Escolher volume ou edição'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (w.kind == 'Livro')
                  SaturnBookDetailsPanel(
                    bookId: w.id,
                    fallbackDescription: w.description,
                    fallbackCover: SaturnBookCover.resolve(w.id, w.posterUrl),
                  )
                else
                  SaturnStorySynopsis(description: w.description),
                if (w.kind != 'Livro')
                  SaturnRatingsFromCatalog(
                    workId: w.id,
                    workTitle: w.title,
                    kind: w.kind,
                    cachedRatings: w.externalRatings,
                    tmdbScore: w.tmdbScore,
                    tmdbVoteCount: w.tmdbVoteCount,
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
                if (w.kind == 'Filme' || w.kind == 'Livro') ...[
                  const Text('NOSSA ÓRBITA · INDICAÇÕES',
                    style: TextStyle(color: gold, fontSize: 11,
                      letterSpacing: 1.5)),
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    onPressed: () {
                      final period = w.kind == 'Livro'
                          ? SaturnOrbitRituals.monthPeriod(DateTime.now())
                          : SaturnOrbitRituals.weekendPeriod(DateTime.now());
                      _setRitualNomination(period, profile, w);
                      refresh(() {});
                    },
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: Text(w.kind == 'Livro'
                        ? 'Escolher como meu livro do mês'
                        : 'Indicar como meu filme do fim de semana'),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  key: const Key('saturn-suggest-to-partner'),
                  onPressed: () => _suggestToPartner(w),
                  icon: const Icon(Icons.favorite_border_rounded, size: 17),
                  label: Text('Sugerir para ' + profiles[1 - profile]),
                ),
                const SizedBox(height: 14),
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
                  const SizedBox(height: 15),
                  Row(children: [
                    const Expanded(child: Text('ONDE ASSISTIR · BRASIL',
                      style: TextStyle(color: gold,
                        letterSpacing: 1.4, fontSize: 11))),
                    IconButton(
                      tooltip: 'Editar meus serviços favoritos',
                      onPressed: _showStreamingPreferences,
                      icon: const Icon(Icons.tune, color: gold, size: 19),
                    ),
                  ]),
                  if (w.streamingProviders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(
                        'Nenhuma assinatura confirmada para este título.',
                        style: TextStyle(
                          color: Color(0xFFD4C2CA), fontSize: 11),
                      ),
                    ),
                  // Provider-independent eligibility. No unverified TVmaze
                  // service suggestion disguised as regional availability.
                  for (final service in StreamingService.values)
                    if (_streaming.contains(service))
                      Builder(builder: (itemContext) {
                        final stored =
                            customTitleLinks[w.id]?[service.name];
                        final sourced = w.streamingLinks[service.name];
                        final direct =
                            checkedTitleUrl(service, stored ?? sourced);
                        final verified =
                            w.streamingProviders.containsKey(service.name);
                        if (!verified && direct == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Material(
                            color: const Color(0xFF30232D),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: Color(0x554F4050))),
                            child: ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            leading: Icon(
                              verified
                                  ? Icons.verified_rounded
                                  : Icons.link_rounded,
                              color: verified
                                  ? const Color(0xFF97CDB4) : gold,
                            ),
                            title: Text(service.label,
                              style: const TextStyle(color: ivory,
                                fontWeight: FontWeight.w600)),
                            subtitle: Text(verified
                                ? 'Assinatura confirmada no Brasil'
                                : 'Link fornecido · disponibilidade não confirmada',
                              style: const TextStyle(
                                color: Color(0xFFD0BBC5), fontSize: 10)),
                            trailing: const Icon(
                              Icons.arrow_outward_rounded,
                              color: gold, size: 18),
                            onTap: direct != null
                                ? () => _openTitleLink(service, direct)
                                : verified
                                    ? () => _openTmdbWatch(w)
                                    : null,
                            ),
                          ),
                        );
                      }),
                  Theme(
                    data: Theme.of(ctx).copyWith(
                      dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: Key('saturn-streaming-search-' + w.id),
                      initiallyExpanded: false,
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.travel_explore_outlined,
                        color: gold, size: 20),
                      title: const Text('Pesquisar em meus serviços',
                        style: TextStyle(color: ivory, fontSize: 12)),
                      children: [
                        if (_streaming.isEmpty)
                          ListTile(
                            title: const Text('Escolher serviços favoritos'),
                            onTap: _showStreamingPreferences,
                          ),
                        for (final service in StreamingService.values)
                          if (_streaming.contains(service))
                            ListTile(
                              dense: true,
                              title: Text(service.label),
                              trailing: const Icon(
                                Icons.open_in_new_rounded, size: 17),
                              onTap: () => _openStreamingService(
                                  service, title: w.title),
                            ),
                      ],
                    ),
                  ),
                  if (w.availabilityUpdatedAt.length >= 10 &&
                      w.streamingProviders.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 5),
                      child: Text('Consulta: ' +
                          w.availabilityUpdatedAt.substring(0, 10) +
                          ' · JustWatch / TMDB',
                        style: const TextStyle(color: Color(0xFFAA969F),
                          fontSize: 10)),
                    ),
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
                  zeroIsRating: ratingSet,
                  onChanged: (stars) => refresh(() {
                    rating = legacyFromStars(stars);
                    ratingSet = true;
                  }),
                ),
                Wrap(spacing: 8, runSpacing: 2, children: [
                  TextButton.icon(
                    onPressed: () => refresh(() {
                      rating = 0;
                      ratingSet = true;
                    }),
                    icon: const Icon(Icons.star_outline_rounded, size: 17),
                    label: const Text('Dar 0 estrelas'),
                  ),
                  TextButton(
                    onPressed: () => refresh(() {
                      rating = 0;
                      ratingSet = false;
                    }),
                    child: const Text('Remover minha nota'),
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12, top: 2),
                  child: Text(
                    'Meia estrela é permitida. O brilho da capa '
                    'aparece quando você salva uma nota '
                    'e uma resenha escrita.',
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
                        'rating': ratingSet ? rating : null,
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
        ),
      ),
    );
    notes.dispose();
  }
}



/// Microanimação de mouse sem alterar o comportamento de toque no celular.
class SaturnHoverLift extends StatefulWidget {
  final Widget child;
  const SaturnHoverLift({super.key, required this.child});

  @override
  State<SaturnHoverLift> createState() => _SaturnHoverLiftState();
}

class _SaturnHoverLiftState extends State<SaturnHoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedScale(
      scale: _hovered ? 1.022 : 1,
      duration: const Duration(milliseconds: 165),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
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
    final coverUrl = SaturnBookCover.resolve(work.id, work.posterUrl);
    if (!coverUrl.startsWith('https://')) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        coverUrl,
        key: ValueKey('cover-' + work.id + '-' + coverUrl),
        width: width, height: height,
        fit: BoxFit.cover,
        // Decode smaller thumbnails where supported and keep low-cost
        // filtering while Safari scrolls hundreds of book/film covers.
        cacheWidth: width.isFinite && width > 0
            ? (width * MediaQuery.devicePixelRatioOf(context))
                .round().clamp(60, 780).toInt() : null,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        // Show the first decoded frame instead of hiding it until the
        // network loading callback finishes. Crossfade avoids white flashes.
        frameBuilder: (context, image, frame, synchronous) {
          if (synchronous) return image;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Stack(fit: StackFit.passthrough, children: [
              fallback,
              image,
            ]),
          );
        },
        loadingBuilder: (context, image, progress) =>
            progress == null ? image : Stack(
              fit: StackFit.passthrough,
              children: [fallback, image],
            ),
        errorBuilder: (context, error, stackTrace) {
          final second = SaturnBookCover.fallback(work.id);
          return second == null ? fallback : Image.network(
            second, width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          );
        },
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
                  if (_filter == CatalogFilter.books) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 7, children: [
                      ActionChip(
                        key: const Key('saturn-books-national'),
                        avatar: const Icon(Icons.auto_stories_outlined,
                          size: 16, color: gold),
                        label: const Text('Literatura brasileira'),
                        onPressed: () {
                          setState(() {
                            _query.clear();
                            _bookSubject = 'brazilian_literature';
                          });
                          _search();
                        },
                      ),
                      ActionChip(
                        key: const Key('saturn-books-agatha-pt'),
                        avatar: const Icon(Icons.auto_stories_outlined,
                          size: 16, color: gold),
                        label: const Text('Agatha Christie · português'),
                        onPressed: () {
                          _query.text = 'Agatha Christie';
                          _search();
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Text('Edições e capas conforme o catálogo',
                          style: TextStyle(
                            color: Color(0xFFCFBAC5), fontSize: 10)),
                      ),
                    ]),
                  ],
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


  /// Cinematic card: edge-to-edge original cover, restrained metadata and
  /// subtle metallic detailing. No extra network requests per visible card.
  Widget _coverCard(Work work) {
    final loved = widget.isShared(work);
    return SaturnHoverLift(child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3A2635), Color(0xFF1C1A24)]),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x88725265)),
        boxShadow: const [BoxShadow(
          color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(color: Colors.transparent,
        child: InkWell(
          key: Key('saturn-cinematic-cover-' + work.id),
          onTap: () => widget.onOpen(work),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Stack(fit: StackFit.expand, children: [
                PosterThumbnail(work: work,
                  width: double.infinity, height: double.infinity),
                const Positioned.fill(child: DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0x770D0D19), Colors.transparent,
                      Color(0xC9171420)],
                    stops: [0, 0.48, 1],
                  )),
                )),
                Positioned(top: 5, left: 5,
                  child: IconButton.filledTonal(
                    tooltip: work.kind == 'Livro' ? 'Quero ler' : 'Watchlist',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleWatchlist(work),
                    icon: Icon(widget.isWatchlisted(work)
                      ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                      color: ivory, size: 18))),
                Positioned(top: 5, right: 5,
                  child: IconButton.filledTonal(
                    tooltip: 'Adicionar à Nossa Órbita',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleShared(work),
                    icon: Icon(loved
                      ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      size: 18,
                      color: loved ? const Color(0xFFF0B6C2) : ivory))),
                Positioned(bottom: 6, right: 5,
                  child: IconButton.filledTonal(
                    tooltip: work.kind == 'Livro'
                      ? 'Marcar como lido' : 'Marcar como assistido',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleCompleted(work),
                    icon: Icon(widget.isCompleted(work)
                      ? Icons.check_circle : Icons.check_circle_outline,
                      color: widget.isCompleted(work)
                        ? const Color(0xFF97CDB4) : ivory, size: 18))),
                Positioned(bottom: 11, left: 10,
                  child: Text(work.kind.toUpperCase(),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: gold, letterSpacing: 1.4,
                      fontSize: 9, fontWeight: FontWeight.w800))),
              ])),
              Container(height: 2,
                decoration: const BoxDecoration(gradient: LinearGradient(
                  colors: [Color(0xFFB89269), Color(0xFF6C465E),
                    Colors.transparent]))),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 5),
                child: Text(work.title, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ivory, fontFamily: 'serif',
                    fontWeight: FontWeight.bold, fontSize: 14,
                    height: 1.2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 1, 8, 9),
                child: Text([
                  if (work.year > 0) work.year.toString(),
                  if (work.kind == 'Livro' && work.creator.isNotEmpty)
                    work.creator
                  else if (work.kind != 'Livro') work.provider,
                ].join(' · '), maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC5ADB9), fontSize: 10))),
            ],
          ),
        ),
      ),
    ));
  }

}
)
                        .hasMatch(w.trailerYoutubeId))
                  _cinematicDetailBanner(w),
                if (w.kind != 'Livro' &&
                    SaturnNativeTrailer.canUseNative(
                      w.nativeTrailerUrl,
                      rightsConfirmed: w.provider == 'SATURN Licensed',
                    )) ...[
                  const SizedBox(height: 10),
                  SaturnNativeTrailer(
                    mediaUrl: w.nativeTrailerUrl,
                    rightsConfirmed: true),
                ],
                const SizedBox(height: 12),
                if (w.kind == 'Livro' &&
                    w.id.startsWith('openlibrary:/works/')) ...[
                  const Text(
                    'Este registro reúne várias edições. Para mangás, '
                    'escolha o volume específico antes de registrar '
                    'o progresso e a nota.',
                    style: TextStyle(color: Color(0xFFDDC4D1), fontSize: 12)),
                  const SizedBox(height: 9),
                  FilledButton.icon(
                    onPressed: () async {
                      final edition = await _chooseBookEdition(w);
                      if (edition == null || edition.id == w.id ||
                          !ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (mounted) await _details(edition);
                    },
                    icon: const Icon(Icons.collections_bookmark_outlined),
                    label: const Text('Escolher volume ou edição'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (w.kind == 'Livro')
                  SaturnBookDetailsPanel(
                    bookId: w.id,
                    fallbackDescription: w.description,
                    fallbackCover: SaturnBookCover.resolve(w.id, w.posterUrl),
                  )
                else
                  SaturnStorySynopsis(description: w.description),
                if (w.kind != 'Livro')
                  SaturnRatingsFromCatalog(
                    workId: w.id,
                    workTitle: w.title,
                    kind: w.kind,
                    cachedRatings: w.externalRatings,
                    tmdbScore: w.tmdbScore,
                    tmdbVoteCount: w.tmdbVoteCount,
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
                if (w.kind == 'Filme' || w.kind == 'Livro') ...[
                  const Text('NOSSA ÓRBITA · INDICAÇÕES',
                    style: TextStyle(color: gold, fontSize: 11,
                      letterSpacing: 1.5)),
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    onPressed: () {
                      final period = w.kind == 'Livro'
                          ? SaturnOrbitRituals.monthPeriod(DateTime.now())
                          : SaturnOrbitRituals.weekendPeriod(DateTime.now());
                      _setRitualNomination(period, profile, w);
                      refresh(() {});
                    },
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: Text(w.kind == 'Livro'
                        ? 'Escolher como meu livro do mês'
                        : 'Indicar como meu filme do fim de semana'),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  key: const Key('saturn-suggest-to-partner'),
                  onPressed: () => _suggestToPartner(w),
                  icon: const Icon(Icons.favorite_border_rounded, size: 17),
                  label: Text('Sugerir para ' + profiles[1 - profile]),
                ),
                const SizedBox(height: 14),
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
                  const SizedBox(height: 15),
                  Row(children: [
                    const Expanded(child: Text('ONDE ASSISTIR · BRASIL',
                      style: TextStyle(color: gold,
                        letterSpacing: 1.4, fontSize: 11))),
                    IconButton(
                      tooltip: 'Editar meus serviços favoritos',
                      onPressed: _showStreamingPreferences,
                      icon: const Icon(Icons.tune, color: gold, size: 19),
                    ),
                  ]),
                  if (w.streamingProviders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(
                        'Nenhuma assinatura confirmada para este título.',
                        style: TextStyle(
                          color: Color(0xFFD4C2CA), fontSize: 11),
                      ),
                    ),
                  // Provider-independent eligibility. No unverified TVmaze
                  // service suggestion disguised as regional availability.
                  for (final service in StreamingService.values)
                    if (_streaming.contains(service))
                      Builder(builder: (itemContext) {
                        final stored =
                            customTitleLinks[w.id]?[service.name];
                        final sourced = w.streamingLinks[service.name];
                        final direct =
                            checkedTitleUrl(service, stored ?? sourced);
                        final verified =
                            w.streamingProviders.containsKey(service.name);
                        if (!verified && direct == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Material(
                            color: const Color(0xFF30232D),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: Color(0x554F4050))),
                            child: ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            leading: Icon(
                              verified
                                  ? Icons.verified_rounded
                                  : Icons.link_rounded,
                              color: verified
                                  ? const Color(0xFF97CDB4) : gold,
                            ),
                            title: Text(service.label,
                              style: const TextStyle(color: ivory,
                                fontWeight: FontWeight.w600)),
                            subtitle: Text(verified
                                ? 'Assinatura confirmada no Brasil'
                                : 'Link fornecido · disponibilidade não confirmada',
                              style: const TextStyle(
                                color: Color(0xFFD0BBC5), fontSize: 10)),
                            trailing: const Icon(
                              Icons.arrow_outward_rounded,
                              color: gold, size: 18),
                            onTap: direct != null
                                ? () => _openTitleLink(service, direct)
                                : verified
                                    ? () => _openTmdbWatch(w)
                                    : null,
                            ),
                          ),
                        );
                      }),
                  Theme(
                    data: Theme.of(ctx).copyWith(
                      dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: Key('saturn-streaming-search-' + w.id),
                      initiallyExpanded: false,
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.travel_explore_outlined,
                        color: gold, size: 20),
                      title: const Text('Pesquisar em meus serviços',
                        style: TextStyle(color: ivory, fontSize: 12)),
                      children: [
                        if (_streaming.isEmpty)
                          ListTile(
                            title: const Text('Escolher serviços favoritos'),
                            onTap: _showStreamingPreferences,
                          ),
                        for (final service in StreamingService.values)
                          if (_streaming.contains(service))
                            ListTile(
                              dense: true,
                              title: Text(service.label),
                              trailing: const Icon(
                                Icons.open_in_new_rounded, size: 17),
                              onTap: () => _openStreamingService(
                                  service, title: w.title),
                            ),
                      ],
                    ),
                  ),
                  if (w.availabilityUpdatedAt.length >= 10 &&
                      w.streamingProviders.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 5),
                      child: Text('Consulta: ' +
                          w.availabilityUpdatedAt.substring(0, 10) +
                          ' · JustWatch / TMDB',
                        style: const TextStyle(color: Color(0xFFAA969F),
                          fontSize: 10)),
                    ),
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
                  zeroIsRating: ratingSet,
                  onChanged: (stars) => refresh(() {
                    rating = legacyFromStars(stars);
                    ratingSet = true;
                  }),
                ),
                Wrap(spacing: 8, runSpacing: 2, children: [
                  TextButton.icon(
                    onPressed: () => refresh(() {
                      rating = 0;
                      ratingSet = true;
                    }),
                    icon: const Icon(Icons.star_outline_rounded, size: 17),
                    label: const Text('Dar 0 estrelas'),
                  ),
                  TextButton(
                    onPressed: () => refresh(() {
                      rating = 0;
                      ratingSet = false;
                    }),
                    child: const Text('Remover minha nota'),
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12, top: 2),
                  child: Text(
                    'Meia estrela é permitida. O brilho da capa '
                    'aparece quando você salva uma nota '
                    'e uma resenha escrita.',
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
                        'rating': ratingSet ? rating : null,
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
        ),
      ),
    );
    notes.dispose();
  }
}



/// Microanimação de mouse sem alterar o comportamento de toque no celular.
class SaturnHoverLift extends StatefulWidget {
  final Widget child;
  const SaturnHoverLift({super.key, required this.child});

  @override
  State<SaturnHoverLift> createState() => _SaturnHoverLiftState();
}

class _SaturnHoverLiftState extends State<SaturnHoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedScale(
      scale: _hovered ? 1.022 : 1,
      duration: const Duration(milliseconds: 165),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
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
    final coverUrl = SaturnBookCover.resolve(work.id, work.posterUrl);
    if (!coverUrl.startsWith('https://')) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        coverUrl,
        key: ValueKey('cover-' + work.id + '-' + coverUrl),
        width: width, height: height,
        fit: BoxFit.cover,
        // Decode smaller thumbnails where supported and keep low-cost
        // filtering while Safari scrolls hundreds of book/film covers.
        cacheWidth: width.isFinite && width > 0
            ? (width * MediaQuery.devicePixelRatioOf(context))
                .round().clamp(60, 780).toInt() : null,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        // Show the first decoded frame instead of hiding it until the
        // network loading callback finishes. Crossfade avoids white flashes.
        frameBuilder: (context, image, frame, synchronous) {
          if (synchronous) return image;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Stack(fit: StackFit.passthrough, children: [
              fallback,
              image,
            ]),
          );
        },
        loadingBuilder: (context, image, progress) =>
            progress == null ? image : Stack(
              fit: StackFit.passthrough,
              children: [fallback, image],
            ),
        errorBuilder: (context, error, stackTrace) {
          final second = SaturnBookCover.fallback(work.id);
          return second == null ? fallback : Image.network(
            second, width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          );
        },
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
                  if (_filter == CatalogFilter.books) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 7, children: [
                      ActionChip(
                        key: const Key('saturn-books-national'),
                        avatar: const Icon(Icons.auto_stories_outlined,
                          size: 16, color: gold),
                        label: const Text('Literatura brasileira'),
                        onPressed: () {
                          setState(() {
                            _query.clear();
                            _bookSubject = 'brazilian_literature';
                          });
                          _search();
                        },
                      ),
                      ActionChip(
                        key: const Key('saturn-books-agatha-pt'),
                        avatar: const Icon(Icons.auto_stories_outlined,
                          size: 16, color: gold),
                        label: const Text('Agatha Christie · português'),
                        onPressed: () {
                          _query.text = 'Agatha Christie';
                          _search();
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Text('Edições e capas conforme o catálogo',
                          style: TextStyle(
                            color: Color(0xFFCFBAC5), fontSize: 10)),
                      ),
                    ]),
                  ],
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


  /// Cinematic card: edge-to-edge original cover, restrained metadata and
  /// subtle metallic detailing. No extra network requests per visible card.
  Widget _coverCard(Work work) {
    final loved = widget.isShared(work);
    return SaturnHoverLift(child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3A2635), Color(0xFF1C1A24)]),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x88725265)),
        boxShadow: const [BoxShadow(
          color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(color: Colors.transparent,
        child: InkWell(
          key: Key('saturn-cinematic-cover-' + work.id),
          onTap: () => widget.onOpen(work),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Stack(fit: StackFit.expand, children: [
                PosterThumbnail(work: work,
                  width: double.infinity, height: double.infinity),
                const Positioned.fill(child: DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0x770D0D19), Colors.transparent,
                      Color(0xC9171420)],
                    stops: [0, 0.48, 1],
                  )),
                )),
                Positioned(top: 5, left: 5,
                  child: IconButton.filledTonal(
                    tooltip: work.kind == 'Livro' ? 'Quero ler' : 'Watchlist',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleWatchlist(work),
                    icon: Icon(widget.isWatchlisted(work)
                      ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                      color: ivory, size: 18))),
                Positioned(top: 5, right: 5,
                  child: IconButton.filledTonal(
                    tooltip: 'Adicionar à Nossa Órbita',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleShared(work),
                    icon: Icon(loved
                      ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      size: 18,
                      color: loved ? const Color(0xFFF0B6C2) : ivory))),
                Positioned(bottom: 6, right: 5,
                  child: IconButton.filledTonal(
                    tooltip: work.kind == 'Livro'
                      ? 'Marcar como lido' : 'Marcar como assistido',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleCompleted(work),
                    icon: Icon(widget.isCompleted(work)
                      ? Icons.check_circle : Icons.check_circle_outline,
                      color: widget.isCompleted(work)
                        ? const Color(0xFF97CDB4) : ivory, size: 18))),
                Positioned(bottom: 11, left: 10,
                  child: Text(work.kind.toUpperCase(),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: gold, letterSpacing: 1.4,
                      fontSize: 9, fontWeight: FontWeight.w800))),
              ])),
              Container(height: 2,
                decoration: const BoxDecoration(gradient: LinearGradient(
                  colors: [Color(0xFFB89269), Color(0xFF6C465E),
                    Colors.transparent]))),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 5),
                child: Text(work.title, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ivory, fontFamily: 'serif',
                    fontWeight: FontWeight.bold, fontSize: 14,
                    height: 1.2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 1, 8, 9),
                child: Text([
                  if (work.year > 0) work.year.toString(),
                  if (work.kind == 'Livro' && work.creator.isNotEmpty)
                    work.creator
                  else if (work.kind != 'Livro') work.provider,
                ].join(' · '), maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC5ADB9), fontSize: 10))),
            ],
          ),
        ),
      ),
    ));
  }

}
)
                        .hasMatch(w.trailerYoutubeId))
                  SaturnTrailerPreview(
                    key: Key('saturn-trailer-' + w.id),
                    youtubeId: w.trailerYoutubeId,
                    heroMode: true,
                    workTitle: w.title,
                    workMetadata: w.kind + ' · ' +
                        (w.year > 0 ? w.year.toString() : 'SATURN')),
                if (w.kind == 'Livro' ||
                    !RegExp(r'^[A-Za-z0-9_-]{11}$')
                        .hasMatch(w.trailerYoutubeId))
                  _cinematicDetailBanner(w),
                if (w.kind != 'Livro' &&
                    SaturnNativeTrailer.canUseNative(
                      w.nativeTrailerUrl,
                      rightsConfirmed: w.provider == 'SATURN Licensed',
                    )) ...[
                  const SizedBox(height: 10),
                  SaturnNativeTrailer(
                    mediaUrl: w.nativeTrailerUrl,
                    rightsConfirmed: true),
                ],
                const SizedBox(height: 12),
                if (w.kind == 'Livro' &&
                    w.id.startsWith('openlibrary:/works/')) ...[
                  const Text(
                    'Este registro reúne várias edições. Para mangás, '
                    'escolha o volume específico antes de registrar '
                    'o progresso e a nota.',
                    style: TextStyle(color: Color(0xFFDDC4D1), fontSize: 12)),
                  const SizedBox(height: 9),
                  FilledButton.icon(
                    onPressed: () async {
                      final edition = await _chooseBookEdition(w);
                      if (edition == null || edition.id == w.id ||
                          !ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (mounted) await _details(edition);
                    },
                    icon: const Icon(Icons.collections_bookmark_outlined),
                    label: const Text('Escolher volume ou edição'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (w.kind == 'Livro')
                  SaturnBookDetailsPanel(
                    bookId: w.id,
                    fallbackDescription: w.description,
                    fallbackCover: SaturnBookCover.resolve(w.id, w.posterUrl),
                  )
                else
                  SaturnStorySynopsis(description: w.description),
                if (w.kind != 'Livro')
                  SaturnRatingsFromCatalog(
                    workId: w.id,
                    workTitle: w.title,
                    kind: w.kind,
                    cachedRatings: w.externalRatings,
                    tmdbScore: w.tmdbScore,
                    tmdbVoteCount: w.tmdbVoteCount,
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
                if (w.kind == 'Filme' || w.kind == 'Livro') ...[
                  const Text('NOSSA ÓRBITA · INDICAÇÕES',
                    style: TextStyle(color: gold, fontSize: 11,
                      letterSpacing: 1.5)),
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    onPressed: () {
                      final period = w.kind == 'Livro'
                          ? SaturnOrbitRituals.monthPeriod(DateTime.now())
                          : SaturnOrbitRituals.weekendPeriod(DateTime.now());
                      _setRitualNomination(period, profile, w);
                      refresh(() {});
                    },
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: Text(w.kind == 'Livro'
                        ? 'Escolher como meu livro do mês'
                        : 'Indicar como meu filme do fim de semana'),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  key: const Key('saturn-suggest-to-partner'),
                  onPressed: () => _suggestToPartner(w),
                  icon: const Icon(Icons.favorite_border_rounded, size: 17),
                  label: Text('Sugerir para ' + profiles[1 - profile]),
                ),
                const SizedBox(height: 14),
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
                  const SizedBox(height: 15),
                  Row(children: [
                    const Expanded(child: Text('ONDE ASSISTIR · BRASIL',
                      style: TextStyle(color: gold,
                        letterSpacing: 1.4, fontSize: 11))),
                    IconButton(
                      tooltip: 'Editar meus serviços favoritos',
                      onPressed: _showStreamingPreferences,
                      icon: const Icon(Icons.tune, color: gold, size: 19),
                    ),
                  ]),
                  if (w.streamingProviders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(
                        'Nenhuma assinatura confirmada para este título.',
                        style: TextStyle(
                          color: Color(0xFFD4C2CA), fontSize: 11),
                      ),
                    ),
                  // Provider-independent eligibility. No unverified TVmaze
                  // service suggestion disguised as regional availability.
                  for (final service in StreamingService.values)
                    if (_streaming.contains(service))
                      Builder(builder: (itemContext) {
                        final stored =
                            customTitleLinks[w.id]?[service.name];
                        final sourced = w.streamingLinks[service.name];
                        final direct =
                            checkedTitleUrl(service, stored ?? sourced);
                        final verified =
                            w.streamingProviders.containsKey(service.name);
                        if (!verified && direct == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Material(
                            color: const Color(0xFF30232D),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: Color(0x554F4050))),
                            child: ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            leading: Icon(
                              verified
                                  ? Icons.verified_rounded
                                  : Icons.link_rounded,
                              color: verified
                                  ? const Color(0xFF97CDB4) : gold,
                            ),
                            title: Text(service.label,
                              style: const TextStyle(color: ivory,
                                fontWeight: FontWeight.w600)),
                            subtitle: Text(verified
                                ? 'Assinatura confirmada no Brasil'
                                : 'Link fornecido · disponibilidade não confirmada',
                              style: const TextStyle(
                                color: Color(0xFFD0BBC5), fontSize: 10)),
                            trailing: const Icon(
                              Icons.arrow_outward_rounded,
                              color: gold, size: 18),
                            onTap: direct != null
                                ? () => _openTitleLink(service, direct)
                                : verified
                                    ? () => _openTmdbWatch(w)
                                    : null,
                            ),
                          ),
                        );
                      }),
                  Theme(
                    data: Theme.of(ctx).copyWith(
                      dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: Key('saturn-streaming-search-' + w.id),
                      initiallyExpanded: false,
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.travel_explore_outlined,
                        color: gold, size: 20),
                      title: const Text('Pesquisar em meus serviços',
                        style: TextStyle(color: ivory, fontSize: 12)),
                      children: [
                        if (_streaming.isEmpty)
                          ListTile(
                            title: const Text('Escolher serviços favoritos'),
                            onTap: _showStreamingPreferences,
                          ),
                        for (final service in StreamingService.values)
                          if (_streaming.contains(service))
                            ListTile(
                              dense: true,
                              title: Text(service.label),
                              trailing: const Icon(
                                Icons.open_in_new_rounded, size: 17),
                              onTap: () => _openStreamingService(
                                  service, title: w.title),
                            ),
                      ],
                    ),
                  ),
                  if (w.availabilityUpdatedAt.length >= 10 &&
                      w.streamingProviders.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 5),
                      child: Text('Consulta: ' +
                          w.availabilityUpdatedAt.substring(0, 10) +
                          ' · JustWatch / TMDB',
                        style: const TextStyle(color: Color(0xFFAA969F),
                          fontSize: 10)),
                    ),
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
                  zeroIsRating: ratingSet,
                  onChanged: (stars) => refresh(() {
                    rating = legacyFromStars(stars);
                    ratingSet = true;
                  }),
                ),
                Wrap(spacing: 8, runSpacing: 2, children: [
                  TextButton.icon(
                    onPressed: () => refresh(() {
                      rating = 0;
                      ratingSet = true;
                    }),
                    icon: const Icon(Icons.star_outline_rounded, size: 17),
                    label: const Text('Dar 0 estrelas'),
                  ),
                  TextButton(
                    onPressed: () => refresh(() {
                      rating = 0;
                      ratingSet = false;
                    }),
                    child: const Text('Remover minha nota'),
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12, top: 2),
                  child: Text(
                    'Meia estrela é permitida. O brilho da capa '
                    'aparece quando você salva uma nota '
                    'e uma resenha escrita.',
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
                        'rating': ratingSet ? rating : null,
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
        ),
      ),
    );
    notes.dispose();
  }
}



/// Microanimação de mouse sem alterar o comportamento de toque no celular.
class SaturnHoverLift extends StatefulWidget {
  final Widget child;
  const SaturnHoverLift({super.key, required this.child});

  @override
  State<SaturnHoverLift> createState() => _SaturnHoverLiftState();
}

class _SaturnHoverLiftState extends State<SaturnHoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedScale(
      scale: _hovered ? 1.022 : 1,
      duration: const Duration(milliseconds: 165),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
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
    final coverUrl = SaturnBookCover.resolve(work.id, work.posterUrl);
    if (!coverUrl.startsWith('https://')) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        coverUrl,
        key: ValueKey('cover-' + work.id + '-' + coverUrl),
        width: width, height: height,
        fit: BoxFit.cover,
        // Decode smaller thumbnails where supported and keep low-cost
        // filtering while Safari scrolls hundreds of book/film covers.
        cacheWidth: width.isFinite && width > 0
            ? (width * MediaQuery.devicePixelRatioOf(context))
                .round().clamp(60, 780).toInt() : null,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        // Show the first decoded frame instead of hiding it until the
        // network loading callback finishes. Crossfade avoids white flashes.
        frameBuilder: (context, image, frame, synchronous) {
          if (synchronous) return image;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Stack(fit: StackFit.passthrough, children: [
              fallback,
              image,
            ]),
          );
        },
        loadingBuilder: (context, image, progress) =>
            progress == null ? image : Stack(
              fit: StackFit.passthrough,
              children: [fallback, image],
            ),
        errorBuilder: (context, error, stackTrace) {
          final second = SaturnBookCover.fallback(work.id);
          return second == null ? fallback : Image.network(
            second, width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          );
        },
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
                  if (_filter == CatalogFilter.books) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 7, children: [
                      ActionChip(
                        key: const Key('saturn-books-national'),
                        avatar: const Icon(Icons.auto_stories_outlined,
                          size: 16, color: gold),
                        label: const Text('Literatura brasileira'),
                        onPressed: () {
                          setState(() {
                            _query.clear();
                            _bookSubject = 'brazilian_literature';
                          });
                          _search();
                        },
                      ),
                      ActionChip(
                        key: const Key('saturn-books-agatha-pt'),
                        avatar: const Icon(Icons.auto_stories_outlined,
                          size: 16, color: gold),
                        label: const Text('Agatha Christie · português'),
                        onPressed: () {
                          _query.text = 'Agatha Christie';
                          _search();
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Text('Edições e capas conforme o catálogo',
                          style: TextStyle(
                            color: Color(0xFFCFBAC5), fontSize: 10)),
                      ),
                    ]),
                  ],
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


  /// Cinematic card: edge-to-edge original cover, restrained metadata and
  /// subtle metallic detailing. No extra network requests per visible card.
  Widget _coverCard(Work work) {
    final loved = widget.isShared(work);
    return SaturnHoverLift(child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3A2635), Color(0xFF1C1A24)]),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x88725265)),
        boxShadow: const [BoxShadow(
          color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(color: Colors.transparent,
        child: InkWell(
          key: Key('saturn-cinematic-cover-' + work.id),
          onTap: () => widget.onOpen(work),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Stack(fit: StackFit.expand, children: [
                PosterThumbnail(work: work,
                  width: double.infinity, height: double.infinity),
                const Positioned.fill(child: DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0x770D0D19), Colors.transparent,
                      Color(0xC9171420)],
                    stops: [0, 0.48, 1],
                  )),
                )),
                Positioned(top: 5, left: 5,
                  child: IconButton.filledTonal(
                    tooltip: work.kind == 'Livro' ? 'Quero ler' : 'Watchlist',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleWatchlist(work),
                    icon: Icon(widget.isWatchlisted(work)
                      ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                      color: ivory, size: 18))),
                Positioned(top: 5, right: 5,
                  child: IconButton.filledTonal(
                    tooltip: 'Adicionar à Nossa Órbita',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleShared(work),
                    icon: Icon(loved
                      ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      size: 18,
                      color: loved ? const Color(0xFFF0B6C2) : ivory))),
                Positioned(bottom: 6, right: 5,
                  child: IconButton.filledTonal(
                    tooltip: work.kind == 'Livro'
                      ? 'Marcar como lido' : 'Marcar como assistido',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onToggleCompleted(work),
                    icon: Icon(widget.isCompleted(work)
                      ? Icons.check_circle : Icons.check_circle_outline,
                      color: widget.isCompleted(work)
                        ? const Color(0xFF97CDB4) : ivory, size: 18))),
                Positioned(bottom: 11, left: 10,
                  child: Text(work.kind.toUpperCase(),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: gold, letterSpacing: 1.4,
                      fontSize: 9, fontWeight: FontWeight.w800))),
              ])),
              Container(height: 2,
                decoration: const BoxDecoration(gradient: LinearGradient(
                  colors: [Color(0xFFB89269), Color(0xFF6C465E),
                    Colors.transparent]))),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 5),
                child: Text(work.title, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ivory, fontFamily: 'serif',
                    fontWeight: FontWeight.bold, fontSize: 14,
                    height: 1.2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 1, 8, 9),
                child: Text([
                  if (work.year > 0) work.year.toString(),
                  if (work.kind == 'Livro' && work.creator.isNotEmpty)
                    work.creator
                  else if (work.kind != 'Livro') work.provider,
                ].join(' · '), maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC5ADB9), fontSize: 10))),
            ],
          ),
        ),
      ),
    ));
  }

}
