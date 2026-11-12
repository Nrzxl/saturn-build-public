import 'saturn_smart_collections.dart';

/// Adds selected catalog titles to explicitly chosen destinations without
/// creating fake reviews or changing either partner's existing scores.
class SaturnBulkCollectionAdder {
  const SaturnBulkCollectionAdder._();

  static int add({
    required Iterable<String> workIds,
    required Set<String> destinationIds,
    required int owner,
    required Map<String, dynamic> definitions,
    required Map<String, dynamic> items,
    required Map<String, dynamic> favorites,
    required Set<String> watchlist,
    required Map<String, dynamic> watchlistOps,
    required Set<String> archived,
    required Map<String, dynamic> archivedOps,
    required int at,
  }) {
    final allowedCustom = SaturnSmartCollections.owned(definitions, owner)
        .map((row) => row['id'].toString()).toSet();
    final allowedDestinations = destinationIds.where(
      (id) => allowedCustom.contains(id) ||
          id == 'watchlist' || id == 'favorites',
    ).toSet();
    if (allowedDestinations.isEmpty) return 0;

    var added = 0;
    for (final id in workIds.toSet()) {
      if (id.trim().isEmpty) continue;
      final recordId = '$owner:$id';
      for (final dest in allowedDestinations) {
        if (dest == 'watchlist') {
          if (watchlist.add(id)) {
            watchlistOps[recordId] = {'present': true, 'updatedAt': at};
            added++;
          }
        } else if (dest == 'favorites') {
          if (!SaturnSmartCollections.isFavorite(favorites, owner, id)) {
            SaturnSmartCollections.setFavorite(
                favorites, owner, id, present: true, at: at);
            added++;
          }
        } else if (!SaturnSmartCollections.contains(items, dest, id)) {
          SaturnSmartCollections.setItem(
              items, dest, id, present: true, at: at);
          added++;
        }
      }
      // Re-adding an archived title should make it visible again for the
      // acting profile; notes and rating remain untouched in records.
      if (archived.remove(recordId)) {
        archivedOps[recordId] = {'present': false, 'updatedAt': at};
      }
    }
    return added;
  }
}
