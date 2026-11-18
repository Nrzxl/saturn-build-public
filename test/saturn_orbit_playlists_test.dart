import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_orbit_playlists.dart';
import 'package:saturn_app/saturn_orbit_merge.dart';

void main() {
  test('Manual order can be any narrative or fan-selected sequence', () {
    final ops = <String, dynamic>{};
    expect(SaturnOrbitPlaylists.create(
        ops, id: 'marvel', name: '  Minha   Marvel  ', at: 100), isTrue);
    expect(SaturnOrbitPlaylists.playlists(ops).single.name, 'Minha Marvel');
    final ids = [
      'tmdb:movie:1771', // Captain America
      'tmdb:movie:1726', // Iron Man
      'tmdb:movie:634649', // Spider-Man
      'tmdb:movie:271110', // Civil War
    ];
    for (var i = 0; i < ids.length; i++) {
      expect(SaturnOrbitPlaylists.add(ops, 'marvel', ids[i], 110 + i), isTrue);
    }
    expect(SaturnOrbitPlaylists.add(ops, 'marvel', ids[0], 123), isFalse);
    final order = [ids[2], ids[0], ids[3], ids[1]];
    expect(SaturnOrbitPlaylists.reorder(ops, 'marvel', order, 130), isTrue);
    expect(SaturnOrbitPlaylists.films(ops, 'marvel')
        .map((entry) => entry.workId), order);
    expect(SaturnOrbitPlaylists.reorder(ops, 'marvel', order, 140), isFalse);
    expect(SaturnOrbitPlaylists.reorder(ops, 'marvel', [ids[0]], 145), isFalse);
  });

  test('Rename, remove and delete are timestamped tombstones', () {
    final ops = <String, dynamic>{};
    SaturnOrbitPlaylists.create(ops, id: 'seq', name: 'Sequência', at: 200);
    SaturnOrbitPlaylists.add(ops, 'seq', 'tmdb:movie:42', 201);
    expect(SaturnOrbitPlaylists.rename(ops, 'seq', 'Versão 2', 202), isTrue);
    expect(SaturnOrbitPlaylists.remove(
        ops, 'seq', 'tmdb:movie:42', 203), isTrue);
    expect(SaturnOrbitPlaylists.films(ops, 'seq'), isEmpty);
    expect(ops['playlist:item:seq:tmdb:movie:42']['present'], isFalse);
    expect(SaturnOrbitPlaylists.add(ops, 'seq', 'tmdb:movie:42', 205), isTrue);
    expect(SaturnOrbitPlaylists.delete(ops, 'seq', 206), isTrue);
    expect(SaturnOrbitPlaylists.playlists(ops), isEmpty);
    expect(ops['playlist:def:seq']['present'], isFalse);
  });

  test('Concurrent adds by both partners survive the existing orbit merge',
      () {
    final baseline = <String, dynamic>{};
    SaturnOrbitPlaylists.create(
        baseline, id: 'cinema', name: 'Nosso universo', at: 1);
    final mine = <String, dynamic>{
      'ritualOps': <String, dynamic>{...baseline},
    };
    final hers = <String, dynamic>{
      'ritualOps': <String, dynamic>{...baseline},
    };
    final mineOps = mine['ritualOps'] as Map<String, dynamic>;
    final herOps = hers['ritualOps'] as Map<String, dynamic>;
    SaturnOrbitPlaylists.add(mineOps, 'cinema', 'tmdb:movie:1', 100);
    SaturnOrbitPlaylists.add(herOps, 'cinema', 'tmdb:movie:2', 101);
    final merged = SaturnOrbitMerge.merge(mine, hers);
    expect(SaturnOrbitPlaylists.films(
        Map<String, dynamic>.from(merged['ritualOps'] as Map), 'cinema')
        .map((entry) => entry.workId).toSet(),
        {'tmdb:movie:1', 'tmdb:movie:2'});
    expect((merged['records'] as Map), isEmpty);
  });

  test('An older client preserving ritualOps cannot erase newer playlists',
      () {
    final newer = <String, dynamic>{};
    SaturnOrbitPlaylists.create(
        newer, id: 'classic', name: 'Clássicos', at: 100);
    SaturnOrbitPlaylists.add(newer, 'classic', 'tmdb:movie:10', 101);
    final merged = SaturnOrbitMerge.merge(
        {'schema': 1, 'ritualOps': <String, dynamic>{}},
        {'schema': 1, 'ritualOps': newer});
    final mergedOps = Map<String, dynamic>.from(merged['ritualOps'] as Map);
    expect(SaturnOrbitPlaylists.playlists(mergedOps).single.name, 'Clássicos');
    expect(SaturnOrbitPlaylists.films(mergedOps, 'classic'), hasLength(1));
  });
}
