import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_bulk_collection_adder.dart';
import 'package:saturn_app/saturn_smart_collections.dart';

void main() {
  test('New discoveries can enter named custom collections in one batch', () {
    final definitions = <String, dynamic>{};
    final first = SaturnSmartCollections.create(definitions,
        owner: 0, name: 'Histórias preferidas', at: 100);
    final second = SaturnSmartCollections.create(definitions,
        owner: 0, name: 'Filmes do casal', at: 101);
    final items = <String, dynamic>{};
    final favorites = <String, dynamic>{};
    final watchlist = <String>{};
    final watchlistOps = <String, dynamic>{};
    final archived = <String>{};
    final archivedOps = <String, dynamic>{};
    final records = <String, dynamic>{
      '0:film:1': {'rating': 10, 'notes': 'Comentário importante'},
    };

    int apply(List<String> ids, Set<String> destinations, int timestamp) =>
        SaturnBulkCollectionAdder.add(
          workIds: ids, destinationIds: destinations, owner: 0,
          definitions: definitions, items: items, favorites: favorites,
          watchlist: watchlist, watchlistOps: watchlistOps,
          archived: archived, archivedOps: archivedOps, at: timestamp);

    expect(apply(['film:1', 'film:2', 'film:2'], {first, second}, 200), 4);
    expect(SaturnSmartCollections.workIds(items, first), ['film:1', 'film:2']);
    expect(SaturnSmartCollections.workIds(items, second), ['film:1', 'film:2']);
    final addedAt = items['$first|film:1']['addedAt'];
    expect(apply(['film:1', 'film:2'], {first, second}, 210), 0);
    expect(items['$first|film:1']['addedAt'], addedAt);
    expect(records['0:film:1']['rating'], 10);
    expect(records['0:film:1']['notes'], 'Comentário importante');

    // One partner cannot write into the other's private named collection.
    final other = SaturnSmartCollections.create(definitions,
        owner: 1, name: 'Privada dela', at: 103);
    expect(apply(['film:3'], {other}, 220), 0);
    expect(SaturnSmartCollections.contains(items, other, 'film:3'), isFalse);

    expect(apply(['film:3'], {'watchlist', 'favorites'}, 230), 2);
    expect(watchlist.contains('film:3'), isTrue);
    expect(SaturnSmartCollections.isFavorite(favorites, 0, 'film:3'), isTrue);
    expect(watchlistOps['0:film:3']['present'], isTrue);
    expect(apply(['film:3'], {'watchlist', 'favorites'}, 240), 0);

    archived.add('0:film:4');
    expect(apply(['film:4'], {first}, 250), 1);
    expect(archived.contains('0:film:4'), isFalse);
    expect(archivedOps['0:film:4']['present'], isFalse);
  });
}
