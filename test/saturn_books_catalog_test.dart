import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saturn_app/catalog_client.dart';

void main() {
  test('Book genres use on-demand pagination instead of a bulk mirror',
      () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      expect(request.url.host, 'openlibrary.org');
      expect(request.url.path, '/subjects/fantasy.json');
      expect(request.url.queryParameters['offset'], '60');
      expect(request.url.queryParameters['limit'], '60');
      return http.Response(jsonEncode({
        'works': [
          {
            'key': '/works/OL9812W',
            'title': 'Fantasia de Teste',
            'first_publish_year': 2020,
            'cover_id': 105,
            'authors': [
              {'name': 'Autora Teste'}
            ],
          }
        ]
      }), 200, headers: const {
        'content-type': 'application/json; charset=utf-8',
      });
    }));
    addTearDown(catalog.close);
    final page = await catalog.discover(
      CatalogFilter.books, page: 2, bookSubject: 'fantasy',
    );
    expect(page, hasLength(1));
    expect(page.single.creator, 'Autora Teste');
    expect(page.single.posterUrl, contains('/105-M.jpg'));
  });

  test('Search books by title, author or ISBN with deeper pages', () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      expect(request.url.path, '/search.json');
      expect(request.url.queryParameters['q'], 'Duna');
      expect(request.url.queryParameters['page'], '3');
      expect(request.url.queryParameters['limit'], '60');
      return http.Response(jsonEncode({
        'docs': [{
          'key': '/works/OL893415W',
          'title': 'Duna',
          'author_name': ['Frank Herbert'],
          'first_publish_year': 1965,
          'cover_i': 899,
          'isbn': ['9780441172719'],
          'edition_count': 210,
        }],
      }), 200, headers: const {
        'content-type': 'application/json; charset=utf-8',
      });
    }));
    addTearDown(catalog.close);
    final result = await catalog.search('Duna', CatalogFilter.books, page: 3);
    expect(result, hasLength(1));
    expect(result.single.description, contains('9780441172719'));
    expect(result.single.description, contains('210'));
  });


  test('Agatha Christie prioritizes verified Portuguese edition and art',
      () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      expect(request.url.path, '/search.json');
      expect(request.url.queryParameters['q'], 'Agatha Christie');
      expect(request.url.queryParameters['lang'], 'pt');
      expect(request.url.queryParameters['fields'], contains('editions.language'));
      return http.Response(jsonEncode({
        'docs': [{
          'key': '/works/OL789W',
          'title': 'Murder on the Orient Express',
          'author_name': ['Agatha Christie'],
          'cover_i': 200,
          'edition_count': 80,
          'editions': {'docs': [{
            'key': '/books/OL123M',
            'title': 'Assassinato no Expresso do Oriente',
            'language': ['por'],
            'cover_i': 9001,
            'isbn_13': ['9788532529627'],
          }]},
        }, {
          'key': '/works/OL790W',
          'title': 'A Novel Without Verified Portuguese Translation',
          'author_name': ['Agatha Christie'],
          'cover_i': 444,
          'editions': {'docs': [{
            'title': 'Foreign edition', 'language': ['eng'],
          }]},
        }],
      }), 200);
    }));
    addTearDown(catalog.close);
    final results = await catalog.search(
      'Agatha Christie', CatalogFilter.books);
    expect(results, hasLength(4));
    expect(results.first.id, 'isbn:9786555110029');
    expect(results.first.posterUrl, contains('284941-1.jpg'));
    expect(results[1].id, CatalogClient.nileBrazilianId);
    expect(results[1].title, 'Morte no Nilo');
    expect(results[1].description, contains('9788520936511'));
    expect(results[2].id, 'openlibrary:/works/OL789W');
    expect(results[2].title, 'Assassinato no Expresso do Oriente');
    expect(results[2].posterUrl, contains('/9001-M.jpg'));
    expect(results[2].description, contains('9788532529627'));
    expect(results[2].creator, 'Agatha Christie');
    expect(results.last.title,
        'A Novel Without Verified Portuguese Translation');
    expect(results.last.posterUrl, contains('/444-M.jpg'));
  });


  test('Morte no Nilo resolves the original work title and Brazilian edition',
      () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      expect(request.url.path, '/search.json');
      expect(request.url.queryParameters['q'], 'Death on the Nile');
      return http.Response(jsonEncode({
        'docs': [{
          'key': '/works/OL471724W',
          'title': 'Death on the Nile',
          'author_name': ['Agatha Christie'],
          'first_publish_year': 1937,
        }],
      }), 200);
    }));
    addTearDown(catalog.close);
    final results = await catalog.search(
        'Morte no Nilo', CatalogFilter.books);
    expect(results, hasLength(3));
    expect(results.first.id, 'isbn:9786555110029');
    expect(results.first.title, 'Morte no Nilo');
    expect(results.first.year, 2020);
    expect(results.first.posterUrl, contains('284941-1.jpg'));
    expect(results[1].id, CatalogClient.nileBrazilianId);
    expect(results[1].year, 2014);
    expect(results[1].detailUrl, contains('aabbportoalegre.com.br'));
    expect(results[1].posterUrl, contains('9788520936511'));
    expect(results.last.id, 'openlibrary:/works/OL471724W');
  });

  test('Brazilian edition persists as an honest fallback during catalog error',
      () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      return http.Response('Unavailable', 503);
    }));
    addTearDown(catalog.close);
    final titleResults = await catalog.search(
        'Morte no Nilo', CatalogFilter.books);
    expect(titleResults, hasLength(2));
    expect(titleResults.first.id, 'isbn:9786555110029');
    expect(titleResults.last.id, CatalogClient.nileBrazilianId);
    final isbnResults = await catalog.search(
        '9788520936511', CatalogFilter.books);
    expect(isbnResults, hasLength(2));
    expect(isbnResults.last.id, CatalogClient.nileBrazilianId);
    // Other pages are source-driven and should report an actual outage
    // rather than silently pretending there are no further books.
    await expectLater(
      catalog.search('Morte no Nilo', CatalogFilter.books, page: 2),
      throwsStateError,
    );
  });

  test('Portuguese book editions appear first without hiding other editions',
      () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      expect(request.url.path, '/works/OL222W/editions.json');
      return http.Response(jsonEncode({
        'entries': [
          {'key': '/books/OL1M', 'title': 'Murder on the Orient Express',
           'languages': [{'key': '/languages/eng'}]},
          {'key': '/books/OL2M', 'title': 'Assassinato no Expresso do Oriente',
           'languages': [{'key': '/languages/por'}], 'covers': [1000]},
          {'key': '/books/OL3M', 'title': 'French edition',
           'languages': [{'key': '/languages/fre'}]},
        ],
      }), 200);
    }));
    addTearDown(catalog.close);
    final editions = await catalog.bookEditions('openlibrary:/works/OL222W');
    expect(editions.map((e) => e.id).toList(), [
      'openlibrary:/books/OL2M',
      'openlibrary:/books/OL1M',
      'openlibrary:/books/OL3M',
    ]);
    expect(editions.first.posterUrl, contains('/1000-M.jpg'));
  });

  test('Manga volume 1 and special edition keep distinct IDs', () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      expect(request.url.path, '/works/OL999W/editions.json');
      expect(request.url.queryParameters['offset'], '0');
      return http.Response(jsonEncode({
        'entries': [
          {'key': '/books/OL111M', 'title': 'Soul Eater',
            'subtitle': 'Vol. 1', 'publish_date': '2020',
            'isbn_13': ['9780000000001'], 'covers': [555]},
          {'key': '/books/OL222M', 'title': 'Soul Eater',
            'edition_name': 'Perfect Edition',
            'publish_date': '2021', 'covers': [666]},
        ],
      }), 200);
    }));
    addTearDown(catalog.close);
    final editions = await catalog.bookEditions('openlibrary:/works/OL999W');
    expect(editions, hasLength(2));
    expect(editions[0].id, 'openlibrary:/books/OL111M');
    expect(editions[1].id, 'openlibrary:/books/OL222M');
    expect(editions[0].title, contains('Vol. 1'));
    expect(editions[0].year, 2020);
    expect(editions[1].title, contains('Perfect Edition'));
    expect(await catalog.bookEditions('not-a-work'), isEmpty);
  });

  test('ISBN looks up one edition instead of parent work', () async {
    final catalog = CatalogClient(client: MockClient((request) async {
      expect(request.url.path, '/isbn/9780000000001.json');
      return http.Response(jsonEncode({
        'key': '/books/OL111M', 'title': 'Soul Eater 1',
        'publish_date': '2020', 'isbn_13': ['9780000000001'],
      }), 200);
    }));
    addTearDown(catalog.close);
    final edition = await catalog.editionByIsbn('978-0-000000-00-1');
    expect(edition?.id, 'openlibrary:/books/OL111M');
    expect(edition?.year, 2020);
    expect(await catalog.editionByIsbn('invalid'), isNull);
  });

  test('Unrecognized genres cannot create arbitrary API paths', () {
    expect(CatalogClient.bookSubjects.values,
      containsAll(['manga', 'romance', 'science_fiction', 'fiction']));
  });
  test('Berserk prefix finds both Japanese-indexed work and PT volume',
      () async {
    expect(CatalogClient.canonicalBookTitleQuery('bers'), 'Berserk');
    expect(CatalogClient.canonicalBookTitleQuery('berse'), 'Berserk');
    expect(CatalogClient.canonicalBookTitleQuery('berser'), 'Berserk');
    expect(CatalogClient.canonicalBookTitleQuery('ベルセルク'), 'Berserk');
    expect(CatalogClient.canonicalBookTitleQuery('biology'), 'biology');

    final queries = <String>[];
    final catalog = CatalogClient(client: MockClient((request) async {
      if (request.url.host == 'openlibrary.org' &&
          request.url.path == '/search.json') {
        queries.add(request.url.queryParameters['q'] ?? '');
        return http.Response(jsonEncode({'docs': [{
          'key': '/works/OL101W',
          'title': 'ベルセルク',
          'author_name': ['Kentaro Miura'],
          'first_publish_year': 1989,
        }]}), 200);
      }
      if (request.url.host == 'www.googleapis.com' &&
          request.url.path == '/books/v1/volumes') {
        queries.add(request.url.queryParameters['q'] ?? '');
        return http.Response(jsonEncode({'items': [{
          'id': 'berserkPT1',
          'volumeInfo': {
            'title': 'Berserk - Volume 1',
            'authors': ['Kentaro Miura'],
            'language': 'pt',
            'pageCount': 216,
            'publishedDate': '2020',
          }
        }]}), 200);
      }
      throw StateError('Unexpected URL: ${request.url}');
    }), enableTmdb: false);
    addTearDown(catalog.close);

    final results = await catalog.search('bers', CatalogFilter.books);
    expect(queries, ['Berserk', 'Berserk']);
    expect(results.any((x) => x.id == 'openlibrary:/works/OL101W' &&
        x.title == 'Berserk'), isTrue);
    expect(results.any((x) => x.id == 'googlebooks:berserkPT1' &&
        x.pageCount == 216), isTrue);
  });

  test('Page count resolves exact edition only, with cached on-demand calls',
      () async {
    var openCalls = 0, googleCalls = 0;
    final catalog = CatalogClient(client: MockClient((request) async {
      if (request.url.host == 'openlibrary.org' &&
          request.url.path == '/books/OL999M.json') {
        openCalls++;
        return http.Response(jsonEncode({'number_of_pages': 352}), 200);
      }
      if (request.url.host == 'www.googleapis.com' &&
          request.url.path == '/books/v1/volumes/truePT') {
        googleCalls++;
        expect(request.url.queryParameters['fields'],
            'volumeInfo(pageCount)');
        return http.Response(jsonEncode({
          'volumeInfo': {'pageCount': 120}
        }), 200);
      }
      throw StateError('Unexpected request: ${request.url}');
    }), enableTmdb: false);
    addTearDown(catalog.close);
    expect(await catalog.verifiedPageCountFor('openlibrary:/works/OL101W'),
        isNull);
    expect(await catalog.verifiedPageCountFor('openlibrary:/books/OL999M'),
        352);
    expect(await catalog.verifiedPageCountFor('openlibrary:/books/OL999M'),
        352);
    expect(await catalog.verifiedPageCountFor('googlebooks:truePT'), 120);
    expect(openCalls, 1);
    expect(googleCalls, 1);
  });


}
