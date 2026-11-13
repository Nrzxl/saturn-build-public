import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/saturn_technical_metadata.dart';

void main() {
  final snapshot = jsonEncode({
    'schema': 1,
    'country': 'BR',
    'generatedAt': '2026-11-13T11:00:00Z',
    'values': {
      'tmdb:movie:101': [117, 0],
      'tmdb:tv:202': [0, 3],
      'tmdb:tv:203': [0, 1],
      'tmdb:tv:204': [123, 0], // Never accept a TV episode as a movie.
      'tmdb:movie:205': [0, 5], // Never accept seasons as movie runtime.
      'tmdb:movie:206': [9999, 0],
      'external:42': [123, 0],
    },
  });

  test('Only real exact-ID metadata with plausible bounds is visible', () {
    final values = SaturnTechnicalMetadata.parse(snapshot);
    expect(values.length, 3);
    expect(values['tmdb:movie:101'], [117, 0]);
    expect(values['tmdb:tv:202'], [0, 3]);
    expect(values['tmdb:tv:203'], [0, 1]);
    expect(SaturnTechnicalMetadata.parse('bad json'), isEmpty);
    expect(SaturnTechnicalMetadata.parse(jsonEncode({
      'schema': 1, 'country': 'US', 'values': {},
    })), isEmpty);
  });

  test('One small GET is cached for 24 hours, not one GET per title', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response(snapshot, 200);
    });
    final metadata = SaturnTechnicalMetadata(client: client);
    var changes = 0;
    await metadata.hydrate(onChanged: () => changes++);
    expect(metadata.factCount, 3);
    for (var i = 0; i < 1000; i++) {
      expect(metadata.runtimeFor('tmdb:movie:101'), 117);
      expect(metadata.seasonsFor('tmdb:tv:202'), 3);
    }
    await metadata.hydrate(onChanged: () => changes++);
    expect(calls, 1);
    expect(changes, 2); // cached data on second load is usable.
    metadata.close();

    final offline = SaturnTechnicalMetadata(client: MockClient((_) async {
      fail('Fresh local cache must not require another request');
    }));
    await offline.hydrate();
    expect(offline.runtimeFor('tmdb:movie:101'), 117);
    expect(offline.seasonsFor('tmdb:tv:203'), 1);
    offline.close();
  });

  test('Unreachable index does not break posters or cached metadata',
      () async {
    SharedPreferences.setMockInitialValues({
      'saturn_technical_v1': snapshot,
      'saturn_technical_checked_at_v1': 1,
    });
    var calls = 0;
    final metadata = SaturnTechnicalMetadata(
      client: MockClient((_) async {
        calls++;
        return http.Response('unavailable', 503);
      }),
    );
    await metadata.hydrate();
    expect(metadata.runtimeFor('tmdb:movie:101'), 117);
    expect(calls, 1);
    await metadata.hydrate();
    expect(calls, 1); // throttled failure
    metadata.close();
  });
}
