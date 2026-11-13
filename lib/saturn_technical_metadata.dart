import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Public, exact-TMDB-ID metadata only. Never accesses profile data or makes
/// one network request per card. One small response is reused for the whole
/// session and cached locally between PWA / Android launches.
class SaturnTechnicalMetadata {
  SaturnTechnicalMetadata({http.Client? client, String? url})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        url = url ?? defaultUrl;

  static const defaultUrl =
      'https://raw.githubusercontent.com/Nrzxl/saturn-downloads/main/catalog/v1/technical.json';
  static const _cacheKey = 'saturn_technical_v1';
  static const _updatedKey = 'saturn_technical_checked_at_v1';
  static const _refreshMs = 24 * 60 * 60 * 1000;
  static const _retryMs = 45 * 60 * 1000;

  final http.Client _client;
  final bool _ownsClient;
  final String url;
  final Map<String, List<int>> _facts = {};
  // TVmaze facts are loaded only for an opened show, never per painted card.
  final Map<String, List<int>> _tvmazeFacts = {};
  final Map<String, Future<void>> _tvmazePending = {};
  final Set<String> _tvmazeAttempted = {};
  static const _tvmazeCacheKey = 'saturn_tvmaze_technical_v1';
  bool _busy = false;
  int get factCount => _facts.length;

  static bool _valid(String id, List<int> pair) {
    if (!RegExp(r'^tmdb:(movie|tv):[1-9][0-9]{0,11}$').hasMatch(id) ||
        pair.length != 2) return false;
    final movie = id.startsWith('tmdb:movie:');
    return movie
        ? pair[0] > 0 && pair[0] <= 800 && pair[1] == 0
        : pair[0] == 0 && pair[1] > 0 && pair[1] <= 150;
  }

  static Map<String, List<int>> parse(String content) {
    if (content.length > 900000) return {};
    try {
      final doc = jsonDecode(content);
      if (doc is! Map || doc['schema'] != 1 ||
          doc['country'] != 'BR' || doc['values'] is! Map) return {};
      final raw = doc['values'] as Map;
      if (raw.length > 30000) return {};
      final facts = <String, List<int>>{};
      for (final entry in raw.entries) {
        final value = entry.value;
        if (entry.key is! String || value is! List ||
            value.length != 2 || value[0] is! int || value[1] is! int) {
          continue;
        }
        final pair = [value[0] as int, value[1] as int];
        if (_valid(entry.key as String, pair)) {
          facts[entry.key as String] = pair;
        }
      }
      return facts;
    } catch (_) {
      return {};
    }
  }

  int? runtimeFor(String id) {
    final m = _facts[id] ?? _tvmazeFacts[id];
    return m != null && m[0] > 0 ? m[0] : null;
  }

  int? seasonsFor(String id) {
    final m = _facts[id] ?? _tvmazeFacts[id];
    return m != null && m[1] > 0 ? m[1] : null;
  }

  /// Retrieve the real average episode duration and aired seasons by TVmaze
  /// ID, excluding season zero (specials). No guesses from title or year.
  /// Opened sheets trigger only two short requests, then persist the cache.
  Future<void> hydrateTvmaze(String id, {void Function()? onChanged}) {
    final match = RegExp(r'^tvmaze:([1-9][0-9]{0,8})  /// usable if GitHub/CDN is unreachable. Network retry is throttled.
  Future<void> hydrate({void Function()? onChanged}) async {
    if (_busy) return;
    _busy = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_cacheKey);
      if (stored != null && stored.isNotEmpty) {
        final cached = parse(stored);
        if (cached.isNotEmpty) {
          _facts
            ..clear()
            ..addAll(cached);
          onChanged?.call();
        }
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = prefs.getInt(_updatedKey) ?? 0;
      if (last > 0 && now >= last && now - last < _refreshMs) return;
      try {
        final response = await _client.get(Uri.parse(url),
          headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 7));
        if (response.statusCode != 200 || response.bodyBytes.length > 900000) {
          throw StateError('Technical metadata not available');
        }
        final raw = utf8.decode(response.bodyBytes);
        final next = parse(raw);
        if (next.isEmpty) throw StateError('Empty technical snapshot');
        _facts
          ..clear()
          ..addAll(next);
        await prefs.setString(_cacheKey, raw);
        await prefs.setInt(_updatedKey, now);
        onChanged?.call();
      } catch (_) {
        // On error retry at a bounded interval, not per visible poster.
        await prefs.setInt(_updatedKey, now - _refreshMs + _retryMs);
      }
    } catch (_) {
      // Metadata is supplementary. Personal collections must always work.
    } finally {
      _busy = false;
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
).firstMatch(id);
    if (match == null || _tvmazeFacts.containsKey(id) ||
        _tvmazeAttempted.contains(id)) return Future<void>.value();
    return _tvmazePending.putIfAbsent(id, () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_tvmazeCacheKey);
        if (cached != null && cached.length < 200000) {
          try {
            final parsed = jsonDecode(cached);
            if (parsed is Map) {
              for (final row in parsed.entries) {
                if (row.key is! String || row.value is! List ||
                    (row.value as List).length != 2) continue;
                final pair = row.value as List;
                if (pair[0] is! int || pair[1] is! int) continue;
                final runtime = pair[0] as int;
                final seasons = pair[1] as int;
                if (runtime >= 0 && runtime <= 300 &&
                    seasons >= 0 && seasons <= 150) {
                  _tvmazeFacts[row.key as String] = [runtime, seasons];
                }
              }
            }
          } catch (_) {
            // A corrupt optional cache must not prevent future lookups.
          }
        }
        if (_tvmazeFacts.containsKey(id)) {
          onChanged?.call();
          return;
        }
        final showNumber = match.group(1)!;
        int duration = 0;
        int seasons = 0;
        try {
          final show = await _client.get(
            Uri.https('api.tvmaze.com', '/shows/$showNumber'),
            headers: const {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 7));
          if (show.statusCode == 200 && show.bodyBytes.length < 100000) {
            final data = jsonDecode(utf8.decode(show.bodyBytes));
            if (data is Map) {
              final value = data['averageRuntime'] ?? data['runtime'];
              if (value is num && value > 0 && value <= 300) {
                duration = value.round();
              }
            }
          }
        } catch (_) {
          // One failed source does not hide a valid seasons response.
        }
        try {
          final seasonResponse = await _client.get(
            Uri.https('api.tvmaze.com', '/shows/$showNumber/seasons'),
            headers: const {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 7));
          if (seasonResponse.statusCode == 200 &&
              seasonResponse.bodyBytes.length < 200000) {
            final data = jsonDecode(utf8.decode(seasonResponse.bodyBytes));
            if (data is List) {
              final distinct = <int>{};
              for (final item in data) {
                if (item is! Map) continue;
                final number = item['number'];
                if (number is num && number > 0 && number <= 150) {
                  distinct.add(number.toInt());
                }
              }
              seasons = distinct.length;
            }
          }
        } catch (_) {
          // Failed metadata is optional; never invent a season count.
        }
        if (duration == 0 && seasons == 0) return;
        _tvmazeFacts[id] = [duration, seasons];
        await prefs.setString(_tvmazeCacheKey, jsonEncode(_tvmazeFacts));
        onChanged?.call();
      } finally {
        // Retry a failed lookup only when reopening the app, not on rebuild.
        _tvmazeAttempted.add(id);
        _tvmazePending.remove(id);
      }
    });
  }

  /// Never blocks startup or title browsing; a stale verified cache stays
  /// usable if GitHub/CDN is unreachable. Network retry is throttled.
  Future<void> hydrate({void Function()? onChanged}) async {
    if (_busy) return;
    _busy = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_cacheKey);
      if (stored != null && stored.isNotEmpty) {
        final cached = parse(stored);
        if (cached.isNotEmpty) {
          _facts
            ..clear()
            ..addAll(cached);
          onChanged?.call();
        }
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = prefs.getInt(_updatedKey) ?? 0;
      if (last > 0 && now >= last && now - last < _refreshMs) return;
      try {
        final response = await _client.get(Uri.parse(url),
          headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 7));
        if (response.statusCode != 200 || response.bodyBytes.length > 900000) {
          throw StateError('Technical metadata not available');
        }
        final raw = utf8.decode(response.bodyBytes);
        final next = parse(raw);
        if (next.isEmpty) throw StateError('Empty technical snapshot');
        _facts
          ..clear()
          ..addAll(next);
        await prefs.setString(_cacheKey, raw);
        await prefs.setInt(_updatedKey, now);
        onChanged?.call();
      } catch (_) {
        // On error retry at a bounded interval, not per visible poster.
        await prefs.setInt(_updatedKey, now - _refreshMs + _retryMs);
      }
    } catch (_) {
      // Metadata is supplementary. Personal collections must always work.
    } finally {
      _busy = false;
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
