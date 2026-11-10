import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saturn_app/catalog_client.dart';
import 'package:saturn_app/main.dart';
import 'package:saturn_app/tmdb_catalog_data.dart';

Map<String, dynamic> title({
  required String id,
  required String name,
  String kind = 'Filme',
  Map<String, String> streaming = const {},
  bool checked = true,
}) => {
  'id': id,
  'title': name,
  'originalTitle': name,
  'kind': kind,
  'description': 'Sinopse TMDB de teste',
  'year': 2025,
  'posterUrl': 'https://image.tmdb.org/t/p/w500/test.jpg',
  'creator': '',
  'provider': 'TMDB',
  'detailUrl': 'https://www.themoviedb.org/movie/123',
  'popularity': 120.0,
  'streamingProviders': streaming,
  'watchProviders': streaming.values.toList(),
  'watchUrl': 'https://www.themoviedb.org/movie/123/watch?locale=BR',
  'availabilityChecked': checked,
};

void main() {
  test('TMDB Brazil: filtra assinatura verificada, pagina sem duplicar',
      () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'raw.githubusercontent.com');
      expect(request.url.path, contains('saturn-downloads/main/catalog/v1'));
      if (request.url.path.endsWith('/movies.json')) {
        return http.Response(jsonEncode({
          'schema': 1,
          'country': 'BR',
          'source': 'TMDB / JustWatch',
          'generatedAt': '2026-11-08T21:00:00+00:00',
          'results': [
            title(
              id: 'tmdb:movie:123', name: 'Coração de Teste',
              streaming: const {'netflix': 'Netflix'},
            ),
            title(
              id: 'tmdb:movie:456', name: 'O Outro Filme',
              streaming: const {'primeVideo': 'Amazon Prime Video'},
            ),
          ],
        }), 200, headers: const {
          'content-type': 'application/json; charset=utf-8',
        });
      }
      return http.Response('Not found', 404);
    });
    final data = TmdbCatalogData(client);
    final netflix = await data.query(
      filter: 'movies',
      search: 'Coracao', // accent-insensitive
      streaming: 'netflix',
      page: 1,
      perPage: 1,
    );
    expect(netflix, hasLength(1));
    expect(netflix.first['id'], 'tmdb:movie:123');
    expect(netflix.first['generatedAt'], '2026-11-08T21:00:00+00:00');
    final empty = await data.query(
      filter: 'movies', search: '',
      streaming: 'netflix', page: 2, perPage: 1,
    );
    expect(empty, isEmpty);
  });

  test('Críticas online usam ID exato, inclusive além da primeira página',
      () async {
    final requested = <String>[];
    final client = MockClient((request) async {
      requested.add(request.url.path);
      final movies = [
        for (var i = 1; i <= 46; i++)
          title(id: 'tmdb:movie:' + i.toString(),
            name: 'Título ' + i.toString()),
      ];
      movies[45] = {
        ...movies[45],
        'tmdbVoteAverage': 8.7,
        'tmdbVoteCount': 5100,
        'externalRatings': {'imdb': '8.4/10'},
      };
      return http.Response(jsonEncode({
        'schema': 1, 'country': 'BR', 'results': movies,
      }), 200);
    });
    final data = TmdbCatalogData(client);
    expect((await data.query(filter: 'movies', search: '',
        page: 1, perPage: 36)).length, 36);
    final fromId = await data.findById('tmdb:movie:46');
    expect(fromId?['tmdbVoteAverage'], 8.7);
    expect(fromId?['tmdbVoteCount'], 5100);
    expect(await data.findById('tmdb:movie:9999'), isNull);

    final catalog = CatalogClient(
      client: MockClient((request) async => http.Response(jsonEncode({
        'schema': 1, 'country': 'BR',
        'results': [{
          ...title(id: 'tmdb:movie:46', name: 'Um título traduzido'),
          'tmdbVoteAverage': 8.7,
          'tmdbVoteCount': 5100,
          'externalRatings': {'imdb': '8.4/10'},
        }],
      }), 200)),
      enableTmdb: true);
    addTearDown(catalog.close);
    final verified = await catalog.onlineRatingsById('tmdb:movie:46');
    expect(verified?.tmdbScore, 8.7);
    expect(verified?.tmdbVoteCount, 5100);
    expect(verified?.externalRatings['imdb'], '8.4/10');
    expect(await catalog.onlineRatingsById('not-tmdb'), isNull);
    expect(requested, hasLength(1));
  });

  test('CatalogClient maps TMDB availability; saves work without data loss',
      () async {
    final catalog = CatalogClient(
      enableTmdb: true,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/movies.json')) {
          return http.Response(jsonEncode({
            'schema': 1,
            'country': 'BR',
            'results': [
              title(
                id: 'tmdb:movie:123', name: 'Um Filme',
                streaming: const {'crunchyroll': 'Crunchyroll'},
              ),
            ],
          }), 200, headers: const {
            'content-type': 'application/json; charset=utf-8',
          });
        }
        return http.Response('Not found', 404);
      }),
    );
    addTearDown(catalog.close);
    final found = await catalog.discover(
      CatalogFilter.movies, streaming: 'crunchyroll',
    );
    expect(found, hasLength(1));
    expect(found.first.streamingProviders['crunchyroll'], 'Crunchyroll');
    final work = Work.fromCatalog(found.first);
    final restored = Work.fromJson(work.toJson());
    expect(restored.streamingProviders, work.streamingProviders);
    expect(restored.watchProviders, work.watchProviders);
    expect(restored.watchUrl, contains('/watch'));
    expect(restored.availabilityChecked, isTrue);
    expect(restored.provider, 'TMDB');
    expect(restored.genreIds, work.genreIds);
    expect(restored.externalRatings, work.externalRatings);
  });

  test('Genre filtering requires real TMDB genre metadata', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/movies.json')) {
        return http.Response(jsonEncode({
          'schema': 1,
          'country': 'BR',
          'results': [
            {...title(id: 'tmdb:movie:1', name: 'Comédia'),
              'genreIds': [35],
              'tmdbVoteAverage': 7.8, 'tmdbVoteCount': 1234,
              'externalRatings': {
                'imdb': '7.3/10',
                'rottenTomatoes': '81%',
              }},
            {...title(id: 'tmdb:movie:2', name: 'Drama'),
              'genreIds': [18]},
          ],
        }), 200, headers: const {'content-type': 'application/json'});
      }
      return http.Response('Missing', 404);
    });
    final catalog = CatalogClient(client: client, enableTmdb: true);
    addTearDown(catalog.close);
    final comedy = await catalog.discover(
      CatalogFilter.movies, genreId: 35);
    expect(comedy, hasLength(1));
    expect(comedy.first.title, 'Comédia');
    expect(comedy.first.externalRatings['imdb'], '7.3/10');
    final restored = Work.fromJson(Work.fromCatalog(comedy.first).toJson());
    expect(restored.genreIds, [35]);
    expect(restored.tmdbScore, 7.8);
    expect(restored.tmdbVoteCount, 1234);
    expect(restored.externalRatings['rottenTomatoes'], '81%');
  });

  test('Non-BR or malformed snapshot does not assert any provider',
      () async {
    final client = MockClient((request) async =>
      http.Response(jsonEncode({
        'schema': 1,
        'country': 'US',
        'results': [
          title(id: 'tmdb:movie:123', name: 'US only',
              streaming: const {'netflix': 'Netflix'}),
        ],
      }), 200, headers: const {
        'content-type': 'application/json; charset=utf-8',
      }),
    );
    final data = TmdbCatalogData(client);
    expect(await data.query(
      filter: 'movies', search: '',
      streaming: 'netflix', page: 1,
    ), isEmpty);
  });
}
