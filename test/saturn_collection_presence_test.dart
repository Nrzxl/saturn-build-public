import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_collection_presence.dart';

void main() {
  final records = <String, dynamic>{};
  final watchlists = <int, Set<String>>{0: <String>{}, 1: <String>{}};
  final favorites = <String, dynamic>{};
  final definitions = <String, dynamic>{};
  final items = <String, dynamic>{};
  final shared = <String>[];
  final archived = <String>{};

  bool marked(String id) => SaturnCollectionPresence.hasAny(
    workId: id,
    records: records,
    watchlists: watchlists,
    favorites: favorites,
    definitions: definitions,
    items: items,
    shared: shared,
    archived: archived,
  );

  setUp(() {
    records.clear();
    watchlists[0]!.clear();
    watchlists[1]!.clear();
    favorites.clear();
    definitions.clear();
    items.clear();
    shared.clear();
    archived.clear();
  });

  test('Catalog cache by itself is never considered collection membership', () {
    expect(marked('tmdb:movie:1'), isFalse);
  });

  test('Either partner watchlist and completed records receive a check', () {
    watchlists[1]!.add('tmdb:movie:1');
    expect(marked('tmdb:movie:1'), isTrue);
    watchlists[1]!.clear();
    records['0:tmdb:movie:1'] = {'status': 'Concluído'};
    expect(marked('tmdb:movie:1'), isTrue);
    records.clear();
    expect(marked('tmdb:movie:1'), isFalse);
  });

  test('Favorites or shared Orbit count as actual collection membership', () {
    favorites['1:tmdb:movie:1'] = {'present': true};
    expect(marked('tmdb:movie:1'), isTrue);
    favorites['1:tmdb:movie:1'] = {'present': false};
    expect(marked('tmdb:movie:1'), isFalse);
    shared.add('tmdb:movie:1');
    expect(marked('tmdb:movie:1'), isTrue);
  });

  test('Only active custom collections and actual saved items count', () {
    const collectionId = 'collection:1:1:0';
    definitions[collectionId] = {
      'id': collectionId,
      'owner': 1,
      'name': 'Nossos filmes',
      'present': true,
    };
    expect(marked('tmdb:movie:1'), isFalse);
    items['$collectionId|tmdb:movie:1'] = {'present': true};
    expect(marked('tmdb:movie:1'), isTrue);
    definitions[collectionId]['present'] = false;
    expect(marked('tmdb:movie:1'), isFalse);
  });

  test('Archived items do not masquerade as active personal titles', () {
    records['0:tmdb:movie:1'] = {'status': 'Concluído'};
    archived.add('0:tmdb:movie:1');
    expect(marked('tmdb:movie:1'), isFalse);
    watchlists[1]!.add('tmdb:movie:1');
    expect(marked('tmdb:movie:1'), isTrue);
  });
}
