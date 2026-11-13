import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/saturn_catalog_labels.dart';
import 'package:saturn_app/saturn_technical_metadata.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('TVmaze exact ID supplies aired seasons and average episode minutes',
      () async {
    final calls = <String>[];
    final client = MockClient((request) async {
      calls.add(request.url.path);
      expect(request.url.host, 'api.tvmaze.com');
      if (request.url.path == '/shows/526') {
        return http.Response(jsonEncode({
          'id': 526, 'name': 'The Office', 'averageRuntime': 22,
        }), 200);
      }
      if (request.url.path == '/shows/526/seasons') {
        return http.Response(jsonEncode([
          {'id': 1, 'number': 0}, // Specials do not count.
          {'id': 2, 'number': 1},
          {'id': 3, 'number': 2},
          {'id': 4, 'number': 2},
        ]), 200);
      }
      return http.Response('Not found', 404);
    });
    final facts = SaturnTechnicalMetadata(client: client);
    var changes = 0;
    await facts.hydrateTvmaze('tvmaze:526',
        onChanged: () => changes++);
    expect(changes, 1);
    expect(facts.runtimeFor('tvmaze:526'), 22);
    expect(facts.seasonsFor('tvmaze:526'), 2);
    expect(SaturnCatalogLabels.technical(
      kind: 'Série', runtimeMinutes: facts.runtimeFor('tvmaze:526'),
      seasonCount: facts.seasonsFor('tvmaze:526')),
      '2 temporadas · 22 min/ep.');
    expect(calls, ['/shows/526', '/shows/526/seasons']);

    // Reopening in this session never creates extra network calls.
    await facts.hydrateTvmaze('tvmaze:526');
    expect(calls.length, 2);

    // A new instance reuses the exact-ID persistent cache.
    final restored = SaturnTechnicalMetadata(client: client);
    await restored.hydrateTvmaze('tvmaze:526');
    expect(restored.seasonsFor('tvmaze:526'), 2);
    expect(calls.length, 2);
  });

  test('TVmaze lookup refuses titles and invalid numeric identifiers',
      () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response('{}', 200);
    });
    final facts = SaturnTechnicalMetadata(client: client);
    await facts.hydrateTvmaze('The Office');
    await facts.hydrateTvmaze('tmdb:tv:2316');
    await facts.hydrateTvmaze('tvmaze:-12');
    expect(requests, 0);
    expect(facts.seasonsFor('tvmaze:-12'), isNull);
  });

  test('TVmaze show runtime alone is not a guessed movie duration', () {
    expect(SaturnCatalogLabels.technical(
        kind: 'Série', runtimeMinutes: 44), '44 min/ep.');
    expect(SaturnCatalogLabels.technical(
        kind: 'Filme', runtimeMinutes: 123), '123 min');
  });
}
