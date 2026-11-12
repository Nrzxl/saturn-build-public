import 'saturn_smart_collections.dart';

/// Shows the verified mark only for actual membership in at least one
/// collection, regardless of which partner saved the title. Merely appearing
/// in the public catalog / cache never counts as a personal collection.
class SaturnCollectionPresence {
  const SaturnCollectionPresence._();

  static bool hasAny({
    required String workId,
    required Map<String, dynamic> records,
    required Map<int, Set<String>> watchlists,
    required Map<String, dynamic> favorites,
    required Map<String, dynamic> definitions,
    required Map<String, dynamic> items,
    required Iterable<String> shared,
    required Set<String> archived,
  }) {
    if (shared.contains(workId)) return true;
    for (var owner = 0; owner <= 1; owner++) {
      final key = '$owner:$workId';
      if (archived.contains(key)) continue;
      final row = records[key];
      if ((row is Map && row['status'] != null) ||
          (watchlists[owner]?.contains(workId) ?? false) ||
          SaturnSmartCollections.isFavorite(favorites, owner, workId)) {
        return true;
      }
      for (final collection in SaturnSmartCollections.owned(
          definitions, owner)) {
        if (SaturnSmartCollections.contains(
            items, collection['id'].toString(), workId)) {
          return true;
        }
      }
    }
    return false;
  }
}
