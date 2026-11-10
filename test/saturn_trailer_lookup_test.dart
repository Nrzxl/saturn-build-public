import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saturn_app/catalog_client.dart';

void main() {
  test('TVmaze title can recover a verified TMDB snapshot trailer', () async {
    final catalog = CatalogClient(enableTmdb: true,
      client: MockClient((request) async {
        expect(request.url.host, 'raw.githubusercontent.com');
        return http.Response(jsonEncode({
          'schema': 1, 'country': 'BR',
          'results': request.url.path.endsWith('/series.json') ? [
            {
              'id': 'tmdb:tv:2316', 'title': 'The Office',
              'originalTitle': 'The Office',
              'year': 2005,
              'trailerYoutubeId': 'a1b2c3d4e5F',
            },
          ] : [],
        }), 200);
      }));
    addTearDown(catalog.close);
    final video = await catalog.verifiedTrailerFor(
      workId: 'tvmaze:526', title: 'The Office',
      kind: 'Série', year: 2005);
    expect(video, 'a1b2c3d4e5F');
    // Idempotent cached lookup.
    final again = await catalog.verifiedTrailerFor(
      workId: 'tvmaze:526', title: 'The Office',
      kind: 'Série', year: 2005);
    expect(again, video);
  });

  test('Different year or invalid YouTube ID must never match', () async {
    final catalog = CatalogClient(enableTmdb: true,
      client: MockClient((request) async {
        return http.Response(jsonEncode({
          'schema': 1, 'country': 'BR',
          'results': request.url.path.endsWith('/series.json') ? [
            {
              'id': 'tmdb:tv:111', 'title': 'The Office',
              'year': 2001, 'trailerYoutubeId': 'a1b2c3d4e5F',
            },
            {
              'id': 'tmdb:tv:222', 'title': 'Another Office',
              'year': 2005, 'trailerYoutubeId': 'INVALID',
            },
          ] : [],
        }), 200);
      }));
    addTearDown(catalog.close);
    final video = await catalog.verifiedTrailerFor(
      workId: 'tvmaze:526', title: 'The Office',
      kind: 'Série', year: 2005);
    expect(video, isNull);
  });

  test('Do not search trailer in unrelated book catalog', () async {
    final catalog = CatalogClient(enableTmdb: true,
      client: MockClient((request) async {
        throw StateError('No request should be made for books');
      }));
    addTearDown(catalog.close);
    expect(await catalog.verifiedTrailerFor(
      workId: 'openlibrary:/books/1', title: 'Livro',
      kind: 'Livro', year: 2026), isNull);
  });
}
