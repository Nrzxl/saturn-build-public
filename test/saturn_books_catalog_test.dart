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
}
