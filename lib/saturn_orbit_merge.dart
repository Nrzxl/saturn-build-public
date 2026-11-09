import 'dart:convert';

/// Pure, deterministic two-device merge. Each changed item carries its own
/// timestamp. Deleted watchlist/favorite entries use explicit tombstones.
/// Nothing is removed just because another device was temporarily offline.
class SaturnOrbitMerge {
  static int _clock(Object? row) {
    if (row is Map) {
      final stamp = row['updatedAt'];
      return stamp is num ? stamp.toInt() : 0;
    }
    return 0;
  }

  static Map<String, dynamic> _map(Object? source) {
    if (source is! Map) return <String, dynamic>{};
    return source.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  static bool _hasData(Object? entry) {
    if (entry is! Map) return false;
    return entry['rating'] != null ||
        (entry['notes'] ?? '').toString().isNotEmpty ||
        (entry['status'] ?? '').toString().isNotEmpty;
  }

  static Map<String, dynamic> _mergeStamped(
    Object? localRaw,
    Object? remoteRaw, {
    bool mergeMissingFields = false,
  }) {
    final local = _map(localRaw);
    final remote = _map(remoteRaw);
    final merged = <String, dynamic>{};
    for (final key in {...local.keys, ...remote.keys}.toList()..sort()) {
      final a = local[key];
      final b = remote[key];
      if (a == null) {
        merged[key] = b;
        continue;
      }
      if (b == null) {
        merged[key] = a;
        continue;
      }
      final la = _clock(a);
      final rb = _clock(b);
      if (la > rb) {
        merged[key] = a;
      } else if (rb > la) {
        merged[key] = b;
      } else if (mergeMissingFields && a is Map && b is Map) {
        // Legacy records lack clocks: preserve the richest data fields.
        merged[key] = {
          ..._map(b),
          for (final entry in a.entries)
            if (!_hasData({entry.key: b[entry.key]}) &&
                entry.value != null && entry.value.toString().isNotEmpty)
              entry.key.toString(): entry.value,
        };
      } else if (a is Map && b is Map &&
          a['present'] == true && b['present'] == false && la == 0) {
        merged[key] = a;
      } else {
        merged[key] = b;
      }
    }
    return merged;
  }

  static Map<String, dynamic> _unionObjects(Object? localRaw, Object? remoteRaw) {
    final local = _map(localRaw);
    final remote = _map(remoteRaw);
    return {
      ...remote,
      for (final entry in local.entries)
        if (!remote.containsKey(entry.key)) entry.key: entry.value,
    };
  }

  static Map<String, dynamic> merge(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localLinks = _map(local['customTitleLinks']);
    final remoteLinks = _map(remote['customTitleLinks']);
    final links = <String, dynamic>{};
    for (final id in {...localLinks.keys, ...remoteLinks.keys}.toList()..sort()) {
      links[id] = _unionObjects(localLinks[id], remoteLinks[id]);
    }

    return {
      'schema': 1,
      'records': _mergeStamped(
        local['records'], remote['records'],
        mergeMissingFields: true,
      ),
      'watchlistOps': _mergeStamped(
        local['watchlistOps'], remote['watchlistOps'],
      ),
      'sharedOps': _mergeStamped(
        local['sharedOps'], remote['sharedOps'],
      ),
      'archivedOps': _mergeStamped(
        local['archivedOps'], remote['archivedOps'],
      ),
      'catalogSaved': _unionObjects(
        local['catalogSaved'], remote['catalogSaved'],
      ),
      'customTitleLinks': links,
    };
  }

  /// Canonical serialization avoids unnecessary revision writes when maps
  /// arrive from PostgreSQL in a different key insertion order.
  static String canonical(Map<String, dynamic> document) =>
      jsonEncode(_canonical(document));

  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) {
      return value.map(_canonical).toList(growable: false);
    }
    return value;
  }

  static Map<String, dynamic> flagFromLegacyList(
    Iterable<String> items, {
    String prefix = '',
  }) => {
    for (final id in items)
      '$prefix$id': {'present': true, 'updatedAt': 0},
  };

  static List<String> activeFlags(
    Map<String, dynamic> flags, {
    String prefix = '',
  }) {
    final result = <String>[];
    for (final entry in flags.entries) {
      if (prefix.isNotEmpty && !entry.key.startsWith(prefix)) continue;
      if (entry.value is Map &&
          (entry.value as Map)['present'] == true) {
        result.add(prefix.isEmpty
            ? entry.key : entry.key.substring(prefix.length));
      }
    }
    result.sort();
    return result;
  }
}
