import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saturn_app/catalog_client.dart';
import 'package:saturn_app/main.dart';
import 'package:saturn_app/streaming_links.dart';
import 'package:saturn_app/streaming_preferences.dart';

void main() {
  test('Aceita apenas links diretos de títulos nos hosts oficiais', () {
    expect(
      checkedTitleUrl(StreamingService.netflix,
        'https://www.netflix.com/title/80057281?utm_source=test'),
      'https://www.netflix.com/title/80057281',
    );
    expect(
      checkedTitleUrl(StreamingService.crunchyroll,
        'https://www.crunchyroll.com/pt-br/series/GR123ABC/serie'),
      'https://www.crunchyroll.com/pt-br/series/GR123ABC/serie',
    );
    expect(
      checkedTitleUrl(StreamingService.primeVideo,
        'https://www.primevideo.com/detail/0TEST1234'),
      'https://www.primevideo.com/detail/0TEST1234',
    );
    expect(
      checkedTitleUrl(StreamingService.netflix,
        'https://www.netflix.com.evil.example/title/80057281'),
      isNull,
    );
    expect(checkedTitleUrl(StreamingService.netflix,
      'https://www.netflix.com/search?q=Dark'), isNull);
    expect(checkedTitleUrl(StreamingService.netflix,
      'javascript:alert(1)'), isNull);
    expect(checkedTitleUrl(StreamingService.primeVideo,
      'https://fake-primevideo.com/detail/0TEST1234'), isNull);
  });

  test('Extrai apenas URLs oficiais do catálogo AniList', () {
    final links = extractOfficialTitleLinks([
      {
        'site': 'Crunchyroll',
        'url': 'https://www.crunchyroll.com/series/G12345/exemplo'
      },
      {
        'site': 'Fake',
        'url': 'https://www.crunchyroll.com.evil.example/series/G12345'
      },
      {
        'site': 'Netflix',
        'url': 'https://www.netflix.com/search?q=serie'
      },
    ]);
    expect(links.keys, contains(StreamingService.crunchyroll.name));
    expect(links.keys, isNot(contains(StreamingService.netflix.name)));
    expect(officialSearchUri(StreamingService.netflix, 'Um Dorama')
        .queryParameters['q'], 'Um Dorama');
  });

  test('AniList: anime sem conteúdo adulto e link específico', () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      expect(request.url.host, 'graphql.anilist.co');
      expect(request.method, 'POST');
      final payload = jsonDecode(request.body) as Map;
      expect((payload['query'] as String), contains('isAdult: false'));
      expect((payload['variables'] as Map)['search'], 'Naruto');
      return http.Response(jsonEncode({
        'data': {
          'Page': {
            'media': [
              {
                'id': 30,
                'title': {
                  'english': 'Naruto',
                  'romaji': 'NARUTO',
                },
                'description': 'Jornada de um ninja.',
                'startDate': {'year': 2002},
                'coverImage': {
                  'large': 'https://example.org/naruto.jpg',
                },
                'siteUrl': 'https://anilist.co/anime/30',
                'externalLinks': [
                  {
                    'site': 'Crunchyroll',
                    'url': 'https://www.crunchyroll.com/series/G12345/naruto'
                  }
                ]
              }
            ]
          }
        }
      }), 200, headers: const {
        'content-type': 'application/json; charset=utf-8',
      });
    }));
    addTearDown(catalog.close);
    final works = await catalog.search('Naruto', CatalogFilter.anime);
    expect(works, hasLength(1));
    expect(works.first.kind, 'Anime');
    expect(works.first.streamingLinks['crunchyroll'],
        contains('/series/G12345'));
    final saved = Work.fromCatalog(works.first);
    expect(Work.fromJson(saved.toJson()).streamingLinks,
        saved.streamingLinks);
  });

  test('TVmaze: classifica dorama e reconhece link oficial Netflix', () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      expect(request.url.host, 'api.tvmaze.com');
      return http.Response(jsonEncode([
        {
          'show': {
            'id': 987,
            'name': 'Drama Coreano de Teste',
            'language': 'Korean',
            'premiered': '2020-01-01',
            'officialSite': 'https://www.netflix.com/title/81234567',
            'image': {
              'original': 'https://example.org/drama.jpg'
            }
          }
        },
        {
          'show': {
            'id': 988,
            'name': 'Série Americana',
            'language': 'English',
          }
        },
      ]), 200, headers: const {
        'content-type': 'application/json; charset=utf-8',
      });
    }));
    addTearDown(catalog.close);
    final works = await catalog.search('Drama', CatalogFilter.dramas);
    expect(works, hasLength(1));
    expect(works.single.kind, 'Dorama');
    expect(works.single.streamingLinks['netflix'],
      'https://www.netflix.com/title/81234567');
  });

  test('Open Library: descoberta paginada por assunto', () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      expect(request.url.path, '/subjects/fiction.json');
      expect(request.url.queryParameters['offset'], '60');
      return http.Response(jsonEncode({
        'works': [
          {
            'key': '/works/OL123W',
            'title': 'Livro em Destaque',
            'cover_id': 15,
            'authors': [{'name': 'Autora Teste'}]
          }
        ]
      }), 200, headers: const {
        'content-type': 'application/json; charset=utf-8',
      });
    }));
    addTearDown(catalog.close);
    final result = await catalog.discover(
      CatalogFilter.books, page: 2, bookSubject: 'fiction');
    expect(result, hasLength(1));
    expect(result.first.kind, 'Livro');
    expect(result.first.posterUrl,
      'https://covers.openlibrary.org/b/id/15-M.jpg');
  });
}
