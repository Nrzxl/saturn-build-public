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
            name: 'Title ' + i.toString()),
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
          ...title(id: 'tmdb:movie:46', name: 'Localized title'),
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

  test('Search matches translated names; TV genres and rotation are stable',
      () async {
    final client = MockClient((request) async {
      final isShows = request.url.path.endsWith('/dramas.json');
      return http.Response(jsonEncode({
        'schema': 1, 'country': 'BR',
        'results': isShows ? [
          {
            ...title(id: 'tmdb:tv:901', name: 'Ela Era Bonita',
                kind: 'Dorama'),
            'originalTitle': '그녀는 예뻤다',
            'aliases': ['She Was Pretty', 'Ela era bonita'],
            'genreIds': [10766, 18],
            'tmdbVoteAverage': 8.3,
            'seasonCount': 1,
          },
        ] : [
          for (var i = 0; i < 60; i++)
            {
              ...title(id: 'tmdb:movie:${1000 + i}', name: 'Filme $i'),
              'genreIds': [10749],
              'runtimeMinutes': 121,
              'popularity': 100 - i,
            },
        ],
      }), 200, headers: const {
        'content-type': 'application/json; charset=utf-8',
      });
    });
    final catalog = TmdbCatalogData(client);
    final localized = await catalog.query(
      filter: 'dramas', search: 'She Was Pretty', page: 1);
    expect(localized, hasLength(1));
    expect(localized.single['title'], 'Ela Era Bonita');
    final romance = await catalog.query(
      filter: 'dramas', search: '', page: 1, genreId: 10749);
    expect(romance, hasLength(1));
    expect(romance.single['seasonCount'], 1);
    final a = await catalog.query(filter: 'movies', search: '',
        page: 1, perPage: 10, rotationSeed: 89);
    final b = await catalog.query(filter: 'movies', search: '',
        page: 2, perPage: 10, rotationSeed: 89);
    final c = await catalog.query(filter: 'movies', search: '',
        page: 1, perPage: 10, rotationSeed: 151);
    expect(a.map((r) => r['id']).toSet()
        .intersection(b.map((r) => r['id']).toSet()), isEmpty);
    expect(a.first['id'], isNot(c.first['id']));
    expect(a.first['runtimeMinutes'], 121);
  });

  test('When raw GitHub fails, real TMDB ratings use the public CDN mirror',
      () async {
    final calls = <String>[];
    final client = MockClient((request) async {
      calls.add(request.url.host);
      if (request.url.host == 'raw.githubusercontent.com') {
        return http.Response('Temporarily unavailable', 503);
      }
      if (request.url.host == 'cdn.jsdelivr.net') {
        return http.Response(jsonEncode({
          'schema': 1, 'country': 'BR',
          'results': [{
            ...title(id: 'tmdb:movie:300', name: 'Filme verificado'),
            'tmdbVoteAverage': 8.6, 'tmdbVoteCount': 923,
            'genreIds': [35],
            'runtimeMinutes': 109,
          }],
        }), 200, headers: const {
          'content-type': 'application/json; charset=utf-8',
        });
      }
      return http.Response('Not found', 404);
    });
    final catalog = CatalogClient(client: client, enableTmdb: true);
    addTearDown(catalog.close);
    final first = await catalog.discover(CatalogFilter.movies,
        genreId: 35);
    expect(first, hasLength(1));
    final movie = Work.fromCatalog(first.single);
    expect(movie.tmdbScore, 8.6);
    expect(movie.runtimeMinutes, 109);
    final roundtrip = Work.fromJson(movie.toJson());
    expect(roundtrip.tmdbScore, 8.6);
    expect(roundtrip.runtimeMinutes, 109);
    await catalog.discover(CatalogFilter.movies, genreId: 35);
    expect(calls.where((host) =>
        host == 'raw.githubusercontent.com').length, 1);
    expect(calls.where((host) =>
        host == 'cdn.jsdelivr.net').length, 1);
  });

  test('Real TVmaze genres survive TMDB outages without invented results',
      () async {
    final client = MockClient((request) async {
      if (request.url.host == 'api.tvmaze.com') {
        return http.Response(jsonEncode([{
          'id': 501,
          'name': 'Drama verdadeiro',
          'type': 'Scripted',
          'genres': ['Drama'],
          'premiered': '2024-03-10',
          'url': 'https://www.tvmaze.com/shows/501/drama',
        }, {
          'id': 502,
          'name': 'Comédia verdadeira',
          'type': 'Scripted',
          'genres': ['Comedy'],
          'premiered': '2024-03-12',
        }]), 200);
      }
      return http.Response('No TMDB feed', 404);
    });
    final catalog = CatalogClient(client: client, enableTmdb: true);
    addTearDown(catalog.close);
    final dramas = await catalog.discover(CatalogFilter.series,
        genreId: 18);
    expect(dramas, hasLength(1));
    expect(dramas.single.title, 'Drama verdadeiro');
    expect(dramas.single.genreIds, contains(18));
    final comedies = await catalog.discover(CatalogFilter.series,
        genreId: 35);
    expect(comedies, hasLength(1));
    expect(comedies.single.title, 'Comédia verdadeira');
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
