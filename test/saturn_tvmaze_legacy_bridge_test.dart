import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_legacy_tvmaze_bridge.dart';
import 'package:saturn_app/saturn_orbit_merge.dart';

void main() {
  const oldOffice = 'tvmaze:526';
  const newOffice = 'tmdb:tv:2316';
  const oldAlice = 'tvmaze:50036';
  const newAlice = 'tmdb:tv:110316';

  Map<String, dynamic> legacy() => {
    'schema': 1,
    'catalogSaved': {
      oldOffice: {
        'id': oldOffice, 'title': 'The Office', 'kind': 'Série',
        'year': 2005, 'provider': 'TVmaze',
        'posterUrl': 'https://static.tvmaze.com/legacy.jpg',
        'description': 'An English summary',
      },
      newOffice: {
        'id': newOffice, 'title': 'The Office', 'kind': 'Série',
        'year': 2005, 'provider': 'TMDB',
        'posterUrl': 'https://image.tmdb.org/t/p/w500/official.jpg',
        'description': 'Sinopse em português',
      },
      oldAlice: {
        'id': oldAlice, 'title': 'Alice in Borderland',
        'kind': 'Dorama', 'year': 2020, 'provider': 'TVmaze',
        'description': 'English source',
      },
    },
    'records': {
      '0:$oldOffice': {
        'rating': 10, 'notes': 'Excelente na versão antiga',
        'status': 'Concluído', 'updatedAt': 10,
      },
      '0:$newOffice': {
        'rating': 10, 'notes': 'Comentário que já estava no TMDB',
        'status': 'Concluído', 'updatedAt': 20,
      },
      '1:$oldOffice': {
        'rating': 10, 'notes': 'Resenha independente dela',
        'status': 'Quero conhecer', 'updatedAt': 11,
      },
      '0:$oldAlice': {
        'rating': 9, 'notes': 'Minha nota',
        'status': 'Concluído', 'updatedAt': 21,
      },
      '1:$oldAlice': {
        'rating': 8, 'notes': 'Nota dela',
        'status': 'Quero conhecer', 'updatedAt': 19,
      },
      '1:$newAlice': {
        'status': 'Concluído', 'updatedAt': 22,
      },
    },
    'watchlistOps': {
      '1:$oldAlice': {'present': true, 'updatedAt': 40},
    },
    'sharedOps': {
      oldOffice: {'present': true, 'updatedAt': 45},
    },
    'archivedOps': {
      '0:$oldOffice': {'present': false, 'updatedAt': 50},
    },
    'favoriteOps': {
      '1:$oldOffice': {'present': true, 'updatedAt': 60},
    },
    'collectionItemOps': {
      'collection:0:1:0|$oldOffice':
          {'present': true, 'updatedAt': 70, 'addedAt': 30},
    },
    'collectionOps': {
      'collection:0:1:0': {
        'id': 'collection:0:1:0', 'present': true, 'owner': 0,
        'name': 'Nossas comédias', 'coverWorkId': oldOffice,
      },
    },
    'ritualOps': {
      'series:turn:0': {
        'workId': oldOffice, 'chosenBy': 1,
        'queued': false, 'finished': false, 'updatedAt': 80,
      },
    },
    'customTitleLinks': {
      oldOffice: {'netflix': 'https://www.netflix.com/'},
    },
  };

  test('Verified crosswalk preserves both profiles and all linked lists', () {
    expect(SaturnLegacyTvmazeBridge.exactIds.length, 10);
    final migrated = SaturnLegacyTvmazeBridge.upgrade(legacy());
    final saved = migrated['catalogSaved'] as Map;
    expect(saved.containsKey(oldOffice), isFalse);
    expect(saved[newOffice]['provider'], 'TMDB');
    expect(saved[newOffice]['posterUrl'], contains('image.tmdb.org'));
    expect(saved.containsKey(oldAlice), isFalse);
    expect(saved[newAlice]['id'], newAlice);

    final records = migrated['records'] as Map;
    expect(records.keys.any((key) => key.toString().contains('tvmaze:')),
        isFalse);
    expect(records['0:$newOffice']['rating'], 10);
    expect(records['1:$newOffice']['rating'], 10);
    expect(records['0:$newOffice']['notes'],
        contains('Excelente na versão antiga'));
    expect(records['0:$newOffice']['notes'],
        contains('Comentário que já estava no TMDB'));
    expect(records['1:$newOffice']['notes'], 'Resenha independente dela');
    expect(records['1:$newAlice']['rating'], 8);
    expect(records['1:$newAlice']['status'], 'Concluído');
    expect(records['0:$newAlice']['rating'], 9);

    expect((migrated['watchlistOps'] as Map)['1:$newAlice']['present'],
        isTrue);
    expect((migrated['sharedOps'] as Map)[newOffice]['present'], isTrue);
    expect((migrated['favoriteOps'] as Map)['1:$newOffice']['present'],
        isTrue);
    expect((migrated['collectionItemOps'] as Map)
        ['collection:0:1:0|$newOffice']['present'], isTrue);
    expect((migrated['collectionOps'] as Map)
        ['collection:0:1:0']['coverWorkId'], newOffice);
    expect((migrated['ritualOps'] as Map)['series:turn:0']['workId'],
        newOffice);
    expect((migrated['customTitleLinks'] as Map)
        [newOffice]['netflix'], 'https://www.netflix.com/');

    // Offline retries and cloud updates cannot append the same review twice.
    expect(jsonEncode(SaturnLegacyTvmazeBridge.upgrade(migrated)),
        jsonEncode(migrated));
  });

  test('Old offline device cannot reintroduce duplicate TVmaze titles', () {
    final fromOldDevice = legacy();
    final currentRemote = SaturnLegacyTvmazeBridge.upgrade(legacy());
    final merged = SaturnOrbitMerge.merge(fromOldDevice, currentRemote);
    final catalog = merged['catalogSaved'] as Map;
    final records = merged['records'] as Map;
    expect(catalog.containsKey(oldOffice), isFalse);
    expect(catalog.containsKey(oldAlice), isFalse);
    expect(records.containsKey('0:$oldOffice'), isFalse);
    expect(records['0:$newOffice']['notes']
        .toString().split('Excelente na versão antiga').length, 2);
    expect(records['1:$newAlice']['rating'], 8);
  });

  test('No work with a coincidentally equal title is remapped', () {
    final doc = {
      'schema': 1,
      'catalogSaved': {
        'tmdb:tv:999': {
          'id': 'tmdb:tv:999', 'title': 'The Office',
          'year': 2001, 'provider': 'TMDB'
        },
        'tvmaze:other': {
          'id': 'tvmaze:other', 'title': 'The Office', 'year': 2001,
        },
      },
      'records': {'0:tvmaze:other': {'rating': 5}},
    };
    final migrated = SaturnLegacyTvmazeBridge.upgrade(doc);
    expect((migrated['catalogSaved'] as Map).containsKey('tvmaze:other'),
        isTrue);
    expect((migrated['records'] as Map).containsKey('0:tvmaze:other'),
        isTrue);
  });

  test('Legacy fallback synopses are Portuguese and do not touch others', () {
    expect(SaturnLegacyTvmazeBridge.portugueseSynopses[oldOffice],
        contains('empresa de papel'));
    expect(SaturnLegacyTvmazeBridge.portugueseSynopses[oldAlice],
        contains('Tóquio'));
    expect(SaturnLegacyTvmazeBridge.portugueseSynopses['tvmaze:other'],
        isNull);
  });
}
