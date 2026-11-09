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

  test('Unrecognized genres cannot create arbitrary API paths', () {
    expect(CatalogClient.bookSubjects.values,
      containsAll(['manga', 'romance', 'science_fiction', 'fiction']));
  });
}
