import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';
import 'package:saturn_app/saturn_orbit_playlists.dart';

void main() {
  testWidgets('Nós dois creates a playlist, stores films and custom order',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1620);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const iron = Work('tmdb:movie:1726', 'Homem de Ferro', 'Filme',
        'O início de uma saga.', 2008);
    const cap = Work('tmdb:movie:1771', 'Capitão América', 'Filme',
        'Uma outra história.', 2011);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        iron.id: iron.toJson(), cap.id: cap.toJson(),
      }),
      'records': jsonEncode({
        '0:${iron.id}': {
          'status': 'Concluído', 'rating': 10,
          'notes': 'Uma avaliação que não deve mudar.',
        },
      }),
      'saturn_ritual_ops_v1': '{}',
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    final create = find.byKey(const Key('saturn-playlist-create'));
    await tester.scrollUntilVisible(create, 275,
        scrollable: find.byType(Scrollable).first, maxScrolls:30);
    await tester.tap(create);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('saturn-playlist-name')),
        'Nossa ordem Marvel');
    await tester.tap(find.byKey(const Key('saturn-playlist-save-name')));
    await tester.pumpAndSettle();

    var prefs = await SharedPreferences.getInstance();
    var ops = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('saturn_ritual_ops_v1')!) as Map);
    final playlist = SaturnOrbitPlaylists.playlists(ops).single;
    expect(playlist.name, 'Nossa ordem Marvel');
    final card = find.byKey(Key('saturn-playlist-card-${playlist.id}'));
    expect(card, findsOneWidget);
    await tester.tap(find.text('Nossa ordem Marvel'));
    await tester.pumpAndSettle();

    Future<void> addMovie(String id) async {
      await tester.tap(find.byKey(
          Key('saturn-playlist-add-${playlist.id}')));
      await tester.pumpAndSettle();
      final target = find.byKey(Key('saturn-playlist-search-result-$id'));
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await addMovie(iron.id);
    await addMovie(cap.id);
    prefs = await SharedPreferences.getInstance();
    ops = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('saturn_ritual_ops_v1')!) as Map);
    expect(SaturnOrbitPlaylists.films(ops, playlist.id)
        .map((item) => item.workId).toList(), [iron.id, cap.id]);

    // The couple can put Captain America BEFORE Iron Man despite dates.
    await tester.tap(find.byKey(
        Key('saturn-playlist-position-${cap.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Posição 1').last);
    await tester.pumpAndSettle();
    ops = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('saturn_ritual_ops_v1')!) as Map);
    expect(SaturnOrbitPlaylists.films(ops, playlist.id)
        .map((item) => item.workId).toList(), [cap.id, iron.id]);

    final records = jsonDecode(prefs.getString('records')!) as Map;
    expect((records['0:${iron.id}'] as Map)['rating'], 10);
    expect((records['0:${iron.id}'] as Map)['notes'],
        'Uma avaliação que não deve mudar.');
    expect(tester.takeException(), isNull);
  });
}
