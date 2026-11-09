import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_orbit_merge.dart';

void main() {
  test('Merges personal records without overwriting newer offline edits', () {
    final local = {
      'records': {
        '0:tmdb:movie:1': {
          'status': 'Concluído',
          'rating': 9.0,
          'notes': 'Vi no Android',
          'updatedAt': 300,
        },
        '1:openlibrary:/works/OL123W': {
          'status': 'Em andamento',
          'notes': 'Lendo no iPhone',
          'updatedAt': 400,
        },
      },
    };
    final remote = {
      'records': {
        '0:tmdb:movie:1': {
          'status': 'Em andamento',
          'rating': 6.0,
          'notes': 'Nota anterior',
          'updatedAt': 200,
        },
        '1:anilist:321': {
          'status': 'Concluído',
          'rating': 8.0,
          'updatedAt': 220,
        },
      },
    };
    final merged = SaturnOrbitMerge.merge(local, remote);
    final records = merged['records'] as Map;
    expect(records, hasLength(3));
    expect(records['0:tmdb:movie:1']['rating'], 9.0);
    expect(records['1:anilist:321']['rating'], 8.0);
    expect(records['1:openlibrary:/works/OL123W']['notes'],
        'Lendo no iPhone');
  });

  test('Tombstones prevent an offline device restoring deleted Watchlist', () {
    final local = {
      'watchlistOps': {
        '0:tmdb:movie:1': {'present': true, 'updatedAt': 100},
      },
      'sharedOps': {
        'tmdb:movie:1': {'present': true, 'updatedAt': 300},
      },
    };
    final remote = {
      'watchlistOps': {
        '0:tmdb:movie:1': {'present': false, 'updatedAt': 500},
      },
      'sharedOps': {
        'tmdb:movie:1': {'present': false, 'updatedAt': 350},
      },
    };
    final merged = SaturnOrbitMerge.merge(local, remote);
    expect(
      SaturnOrbitMerge.activeFlags(
        merged['watchlistOps'] as Map<String, dynamic>,
        prefix: '0:',
      ),
      isEmpty,
    );
    expect(SaturnOrbitMerge.activeFlags(
        merged['sharedOps'] as Map<String, dynamic>), isEmpty);
  });

  test('Legacy lists survive first cloud link and keep catalog metadata', () {
    final legacy = SaturnOrbitMerge.flagFromLegacyList(
      ['openlibrary:/works/OL50W'], prefix: '1:',
    );
    final merged = SaturnOrbitMerge.merge({
      'watchlistOps': legacy,
      'catalogSaved': {
        'openlibrary:/works/OL50W': {'title': 'Um Livro', 'kind': 'Livro'},
      },
    }, {'records': {}});
    final flags = merged['watchlistOps'] as Map<String, dynamic>;
    expect(SaturnOrbitMerge.activeFlags(flags, prefix: '1:'),
        ['openlibrary:/works/OL50W']);
    expect((merged['catalogSaved'] as Map).keys,
        contains('openlibrary:/works/OL50W'));
  });

  test('Canonical document comparison is independent of map order', () {
    expect(
      SaturnOrbitMerge.canonical({
        'records': {'b': 2, 'a': 1},
        'schema': 1,
      }),
      SaturnOrbitMerge.canonical({
        'schema': 1,
        'records': {'a': 1, 'b': 2},
      }),
    );
  });
}
