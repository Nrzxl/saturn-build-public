import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_smart_collections.dart';

void main() {
  test('Smart collections reflect favorites, watchlist and status', () {
    final favorites = <String, dynamic>{};
    SaturnSmartCollections.setFavorite(favorites, 0, 'tmdb:movie:9',
      present: true, at: 10);
    expect(SaturnSmartCollections.isFavorite(favorites, 0,
      'tmdb:movie:9'), isTrue);
    expect(SaturnSmartCollections.isFavorite(favorites, 1,
      'tmdb:movie:9'), isFalse);

    List<String> smart(String kind) => SaturnSmartCollections.smartIds(kind,
      profile: 0,
      knownIds: ['tmdb:movie:9', 'tmdb:movie:10', 'tmdb:movie:11'],
      favorites: favorites,
      watchlist: {'tmdb:movie:10'},
      records: {
        '0:tmdb:movie:9': {'status': 'Concluído'},
        '0:tmdb:movie:11': {'status': 'Em andamento'},
      });
    expect(smart('favorites'), ['tmdb:movie:9']);
    expect(smart('watchlist'), ['tmdb:movie:10']);
    expect(smart('completed'), ['tmdb:movie:9']);
    expect(smart('in-progress'), ['tmdb:movie:11']);
    SaturnSmartCollections.setFavorite(favorites, 0, 'tmdb:movie:9',
      present: false, at: 20);
    expect(smart('favorites'), isEmpty);
    expect((favorites['0:tmdb:movie:9'] as Map)['present'], false);
  });

  test('Custom collection membership and cover follow first saved title', () {
    final collections = <String, dynamic>{};
    final memberships = <String, dynamic>{};
    final id = SaturnSmartCollections.create(collections,
      owner: 0, name: '  Só nós dois  ', at: 100);
    expect(SaturnSmartCollections.owned(collections, 0).single['name'],
      'Só nós dois');
    expect(SaturnSmartCollections.owned(collections, 1), isEmpty);
    SaturnSmartCollections.setItem(memberships, id, 'tmdb:movie:1',
      present: true, at: 101);
    SaturnSmartCollections.setItem(memberships, id, 'tmdb:movie:2',
      present: true, at: 102);
    expect(SaturnSmartCollections.workIds(memberships, id),
      ['tmdb:movie:1', 'tmdb:movie:2']);
    SaturnSmartCollections.setItem(memberships, id, 'tmdb:movie:1',
      present: false, at: 103);
    expect(SaturnSmartCollections.workIds(memberships, id),
      ['tmdb:movie:2']);
    SaturnSmartCollections.edit(collections, id,
      coverWorkId: 'tmdb:movie:2',
      coverUrl: 'https://example.com/meu-poster.jpg',
      name: 'Dois mundos', at: 120);
    expect((collections[id] as Map)['coverWorkId'], 'tmdb:movie:2');
    expect((collections[id] as Map)['name'], 'Dois mundos');
    SaturnSmartCollections.delete(collections, id, at: 150);
    expect(SaturnSmartCollections.owned(collections, 0), isEmpty);
    expect(SaturnSmartCollections.workIds(memberships, id),
      ['tmdb:movie:2']); // Tombstone preserves original linkage history.
  });

  test('Bad covers and invalid collection names cannot enter the library', () {
    expect(SaturnSmartCollections.validCoverUrl(
      'https://image.tmdb.org/t/p/w500/cover.jpg'), isTrue);
    expect(SaturnSmartCollections.validCoverUrl(
      'javascript:alert(1)'), isFalse);
    expect(SaturnSmartCollections.validCoverUrl(
      'http://example.com/cover.jpg'), isFalse);
    expect(SaturnSmartCollections.validCoverUrl(
      'https://user:password@host.test/image.jpg'), isFalse);
    expect(() => SaturnSmartCollections.create(<String, dynamic>{},
      owner: 0, name: '  ', at: 10), throwsArgumentError);
  });
}
