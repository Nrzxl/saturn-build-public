/// SATURN intelligent and personal collections.
/// All changes are stamped operations instead of overwritten lists.
class SaturnSmartCollections {
  const SaturnSmartCollections._();

  static int _next = 0;

  static String create(
    Map<String, dynamic> definitions, {
    required int owner,
    required String name,
    required int at,
  }) {
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 64) {
      throw ArgumentError('Nome deve ter entre 1 e 64 caracteres.');
    }
    final id = 'collection:$owner:$at:${_next++}';
    definitions[id] = {
      'id': id, 'owner': owner, 'name': clean,
      'coverUrl': '', 'coverWorkId': '',
      'createdAt': at, 'updatedAt': at, 'present': true,
    };
    return id;
  }

  static void edit(
    Map<String, dynamic> definitions,
    String id, {
    String? name,
    String? coverUrl,
    String? coverWorkId,
    required int at,
  }) {
    final old = definitions[id];
    if (old is! Map || old['present'] != true) return;
    final updated = Map<String, dynamic>.from(old);
    if (name != null) {
      final cleaned = name.trim();
      if (cleaned.isEmpty || cleaned.length > 64) {
        throw ArgumentError('Nome deve ter entre 1 e 64 caracteres.');
      }
      updated['name'] = cleaned;
    }
    if (coverUrl != null) {
      if (coverUrl.isNotEmpty && !validCoverUrl(coverUrl)) {
        throw ArgumentError('A capa precisa de um endereço HTTPS válido.');
      }
      updated['coverUrl'] = coverUrl;
    }
    if (coverWorkId != null) updated['coverWorkId'] = coverWorkId;
    updated['updatedAt'] = at;
    definitions[id] = updated;
  }

  static bool validCoverUrl(String url) {
    if (url.length > 1024) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' &&
        uri.host.isNotEmpty && uri.userInfo.isEmpty &&
        (uri.port == 443 || !uri.hasPort);
  }

  static void delete(
    Map<String, dynamic> definitions,
    String id, {
    required int at,
  }) {
    final old = definitions[id];
    if (old is! Map) return;
    definitions[id] = {
      ...Map<String, dynamic>.from(old),
      'present': false, 'updatedAt': at,
    };
  }

  static List<Map<String, dynamic>> owned(
      Map<String, dynamic> definitions, int owner) {
    final result = <Map<String, dynamic>>[];
    for (final entry in definitions.values) {
      if (entry is Map && entry['present'] == true &&
          entry['owner'] == owner &&
          (entry['name'] ?? '').toString().trim().isNotEmpty) {
        result.add(Map<String, dynamic>.from(entry));
      }
    }
    result.sort((a, b) {
      final byDate = ((a['createdAt'] as num?)?.toInt() ?? 0)
          .compareTo((b['createdAt'] as num?)?.toInt() ?? 0);
      return byDate != 0 ? byDate : a['id'].toString()
          .compareTo(b['id'].toString());
    });
    return result;
  }

  static bool contains(
    Map<String, dynamic> items, String collectionId, String workId,
  ) => items['$collectionId|$workId'] is Map &&
      (items['$collectionId|$workId'] as Map)['present'] == true;

  static void setItem(
    Map<String, dynamic> items, String collectionId, String workId, {
    required bool present,
    required int at,
  }) {
    final key = '$collectionId|$workId';
    final old = items[key];
    items[key] = {
      'present': present,
      'addedAt': (old is Map && old['addedAt'] is num)
          ? (old['addedAt'] as num).toInt() : at,
      'updatedAt': at,
    };
  }

  static List<String> workIds(
      Map<String, dynamic> items, String collectionId) {
    final prefix = '$collectionId|';
    final selected = <MapEntry<String, Map>>[];
    for (final entry in items.entries) {
      if (!entry.key.startsWith(prefix) || entry.value is! Map) continue;
      final row = entry.value as Map;
      if (row['present'] != true) continue;
      selected.add(MapEntry(entry.key.substring(prefix.length), row));
    }
    selected.sort((a, b) {
      final byDate = ((a.value['addedAt'] as num?)?.toInt() ?? 0)
          .compareTo((b.value['addedAt'] as num?)?.toInt() ?? 0);
      return byDate != 0 ? byDate : a.key.compareTo(b.key);
    });
    return selected.map((entry) => entry.key).toList(growable: false);
  }

  static bool isFavorite(
      Map<String, dynamic> favorites, int profile, String workId) {
    final value = favorites['$profile:$workId'];
    return value is Map && value['present'] == true;
  }

  static void setFavorite(
      Map<String, dynamic> favorites, int profile, String workId, {
    required bool present, required int at,
  }) {
    favorites['$profile:$workId'] =
        {'present': present, 'updatedAt': at};
  }

  /// Smart collections derive from live profile status, never copies.
  static List<String> smartIds(
    String type, {
    required int profile,
    required Iterable<String> knownIds,
    required Map<String, dynamic> favorites,
    required Set<String> watchlist,
    required Map<String, dynamic> records,
  }) {
    return knownIds.where((id) {
      switch (type) {
        case 'favorites':
          return isFavorite(favorites, profile, id);
        case 'watchlist':
          return watchlist.contains(id);
        case 'completed':
          final row = records['$profile:$id'];
          if (row is! Map) return false;
          return {'Concluído', 'Assistido', 'Lido'}
              .contains(row['status']);
        case 'in-progress':
          final row = records['$profile:$id'];
          return row is Map && row['status'] == 'Em andamento';
        default:
          return false;
      }
    }).toList(growable: false);
  }
}
