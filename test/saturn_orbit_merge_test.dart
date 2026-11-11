import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_orbit_merge.dart';

void main() {
  test('Série atual e turnos históricos preservados no merge da Órbita', () {
    final merged = SaturnOrbitMerge.merge({
      'ritualOps': {
        'series:turn:0': {
          'workId': 'tmdb:tv:111', 'chosenBy': 1,
          'finished': false, 'updatedAt': 100,
        },
      },
    }, {
      'ritualOps': {
        'series:turn:0': {
          'workId': 'tmdb:tv:111', 'chosenBy': 1,
          'finished': true, 'updatedAt': 200,
        },
        'series:turn:1': {
          'workId': 'tmdb:tv:222', 'chosenBy': 0,
          'finished': false, 'updatedAt': 210,
        },
      },
    });
    final ops = merged['ritualOps'] as Map;
    expect((ops['series:turn:0'] as Map)['finished'], isTrue);
    expect((ops['series:turn:1'] as Map)['chosenBy'], 0);
    expect((ops['series:turn:1'] as Map)['workId'], 'tmdb:tv:222');
  });


  test('Names and avatars for both partners merge independently', () {
    final a = SaturnOrbitMerge.merge({
      'profileOps': {
        '0': {'name': 'Eu', 'avatar': '🪐', 'updatedAt': 100},
        '1': {'name': 'Ela', 'avatar': '🌙', 'updatedAt': 110},
      },
    }, {
      'profileOps': {
        '1': {'name': 'Luna', 'avatar': '🌸', 'updatedAt': 200},
      },
    });
    final names = a['profileOps'] as Map;
    expect((names['0'] as Map)['avatar'], '🪐');
    expect((names['1'] as Map)['name'], 'Luna');
    expect((names['1'] as Map)['avatar'], '🌸');
  });


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

  test('Cada indicação e escolha mensal sincronizam sem sobrescrever outra', () {
    final merged = SaturnOrbitMerge.merge({
      'ritualOps': {
        'weekend:2026-11-14:nomination:0':
            {'workId': 'filme-eu', 'updatedAt': 150},
        'month:2026-11:selected':
            {'workId': 'livro-anterior', 'updatedAt': 100},
      },
    }, {
      'ritualOps': {
        'weekend:2026-11-14:nomination:1':
            {'workId': 'filme-ela', 'updatedAt': 210},
        'month:2026-11:selected':
            {'workId': 'livro-escolhido', 'updatedAt': 250},
      },
    });
    final ops = merged['ritualOps'] as Map;
    expect(ops, hasLength(3));
    expect(ops['weekend:2026-11-14:nomination:0']['workId'], 'filme-eu');
    expect(ops['weekend:2026-11-14:nomination:1']['workId'], 'filme-ela');
    expect(ops['month:2026-11:selected']['workId'], 'livro-escolhido');
  });

  test('Tombstone de indicação antiga não ressuscita no modo offline', () {
    final ops = SaturnOrbitMerge.merge({
      'ritualOps': {
        'month:2026-11:nomination:0':
            {'workId': '', 'updatedAt': 350},
      },
    }, {
      'ritualOps': {
        'month:2026-11:nomination:0':
            {'workId': 'livro-antigo', 'updatedAt': 300},
      },
    })['ritualOps'] as Map;
    expect(ops['month:2026-11:nomination:0']['workId'], '');
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
  });  test('Coleções, favoritos e capas sincronizam sem ressuscitar exclusões', () {
    final merged = SaturnOrbitMerge.merge({
      'favoriteOps': {
        '0:tmdb:movie:1': {'present': false, 'updatedAt': 300},
      },
      'collectionOps': {
        'collection:0:100:1': {
          'id': 'collection:0:100:1', 'owner': 0,
          'name': 'Minha coleção', 'coverUrl': '',
          'updatedAt': 220, 'present': true,
        },
      },
      'collectionItemOps': {
        'collection:0:100:1|tmdb:movie:1': {
          'present': false, 'updatedAt': 410,
        },
      },
    }, {
      'favoriteOps': {
        '0:tmdb:movie:1': {'present': true, 'updatedAt': 200},
        '1:tmdb:movie:2': {'present': true, 'updatedAt': 150},
      },
      'collectionOps': {
        'collection:0:100:1': {
          'id': 'collection:0:100:1', 'owner': 0,
          'name': 'Nome anterior', 'updatedAt': 100,
          'present': true,
        },
        'collection:1:200:2': {
          'id': 'collection:1:200:2', 'owner': 1,
          'name': 'Coleção dela', 'updatedAt': 200,
          'present': true,
        },
      },
      'collectionItemOps': {
        'collection:0:100:1|tmdb:movie:1': {
          'present': true, 'updatedAt': 100,
        },
        'collection:1:200:2|tmdb:movie:2': {
          'present': true, 'updatedAt': 210,
        },
      },
    });
    final favorites = merged['favoriteOps'] as Map;
    expect(favorites['0:tmdb:movie:1']['present'], isFalse);
    expect(favorites['1:tmdb:movie:2']['present'], isTrue);
    final defs = merged['collectionOps'] as Map;
    expect(defs['collection:0:100:1']['name'], 'Minha coleção');
    expect(defs, hasLength(2));
    final members = merged['collectionItemOps'] as Map;
    expect(members['collection:0:100:1|tmdb:movie:1']['present'], isFalse);
    expect(members['collection:1:200:2|tmdb:movie:2']['present'], isTrue);
  });


}
