import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saturn_app/catalog_client.dart';
import 'package:saturn_app/main.dart';

void main() {
  test('Panorama HD is retrieved by exact TMDB ID and cached', () async {
    var calls = 0;
    final catalog = CatalogClient(
      enableTmdb: true,
      client: MockClient((request) async {
        calls++;
        expect(request.url.path, contains('/movies.json'));
        return http.Response(jsonEncode({
          'schema': 1,
          'country': 'BR',
          'results': [
            {
              'id': 'tmdb:movie:24',
              'title': 'Kill Bill: Volume 1',
              'posterUrl': 'https://image.tmdb.org/t/p/w500/poster.jpg',
              'backdropUrl': 'https://image.tmdb.org/t/p/w1280/scene.jpg',
            },
            {
              'id': 'tmdb:movie:25',
              'title': 'Another film',
              'backdropUrl': 'https://image.tmdb.org/t/p/w1280/other.jpg',
            },
          ],
        }), 200);
      }),
    );
    final first = await catalog.verifiedBackdropFor(workId: 'tmdb:movie:24');
    final second = await catalog.verifiedBackdropFor(workId: 'tmdb:movie:24');
    expect(first, 'https://image.tmdb.org/t/p/w1280/scene.jpg');
    expect(second, first);
    expect(calls, 1);
    catalog.close();
  });

  test('Invalid or unrelated backdrop cannot replace a saved poster', () async {
    final catalog = CatalogClient(enableTmdb: false);
    expect(await catalog.verifiedBackdropFor(
      workId: 'tmdb:movie:24', cachedBackdrop: 'http://example.com/fake.jpg',
    ), isNull);
    expect(await catalog.verifiedBackdropFor(
      workId: 'tmdb:movie:24',
      cachedBackdrop: 'https://image.tmdb.org/t/p/w1280/real.jpg',
    ), 'https://image.tmdb.org/t/p/w1280/real.jpg');
    catalog.close();
  });

  test('Backdrop survives Work local serialization without altering poster', () {
    const original = Work(
      'tmdb:movie:24', 'Kill Bill: Volume 1', 'Filme', 'Descrição', 2003,
      posterUrl: 'https://image.tmdb.org/t/p/w780/poster.jpg',
      backdropUrl: 'https://image.tmdb.org/t/p/w1280/scene.jpg',
    );
    final restored = Work.fromJson(original.toJson());
    expect(restored.posterUrl, original.posterUrl);
    expect(restored.backdropUrl, original.backdropUrl);
  });
}
