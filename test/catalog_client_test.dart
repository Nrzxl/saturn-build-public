import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saturn_app/catalog_client.dart';

void main() {
  test('Open Library: pesquisa e identidade persistente da obra', () async {
    final client = CatalogClient(client: MockClient((request) async {
      expect(request.url.host, 'openlibrary.org');
      return http.Response(jsonEncode({
        'docs': [
          {
            'key': '/works/OL893415W',
            'title': 'Duna',
            'author_name': ['Frank Herbert'],
            'first_publish_year': 1965,
            'cover_i': 123,
          }
        ],
      }), 200, headers: const {'content-type': 'application/json; charset=utf-8'});
    }));
    addTearDown(client.close);
    final books = await client.search('Duna', CatalogFilter.books);
    expect(books, hasLength(1));
    expect(books.first.id, 'openlibrary:/works/OL893415W');
    expect(books.first.kind, 'Livro');
    expect(books.first.creator, 'Frank Herbert');
    expect(books.first.year, 1965);
    expect(books.first.posterUrl, contains('/b/id/123-M.jpg'));
  });

  test('TVmaze: remove marcação HTML de sinopses', () async {
    final client = CatalogClient(client: MockClient((request) async {
      expect(request.url.host, 'api.tvmaze.com');
      return http.Response(jsonEncode([
        {
          'show': {
            'id': 100,
            'name': 'Uma Série',
            'summary': '<p>História de <b>mistério</b> &amp; drama.</p>',
            'premiered': '2022-05-15',
            'image': {'medium': 'https://example.org/cover.jpg'},
          }
        }
      ]), 200, headers: const {'content-type': 'application/json; charset=utf-8'});
    }));
    addTearDown(client.close);
    final shows = await client.search('Uma Série', CatalogFilter.series);
    expect(shows, hasLength(1));
    expect(shows.first.id, 'tvmaze:100');
    expect(shows.first.description, 'História de mistério & drama.');
    expect(shows.first.year, 2022);
  });

  test('Apple: filmes não são apresentados como informação de streaming', () async {
    final client = CatalogClient(client: MockClient((request) async {
      expect(request.url.host, 'itunes.apple.com');
      expect(request.url.queryParameters['country'], 'BR');
      return http.Response(jsonEncode({
        'resultCount': 1,
        'results': [
          {
            'trackId': 12345,
            'trackName': 'Um Filme',
            'releaseDate': '2014-01-01T00:00:00Z',
            'longDescription': 'Descrição de exemplo',
            'trackViewUrl': 'https://itunes.apple.com/br/movie/id12345',
          }
        ],
      }), 200, headers: const {'content-type': 'application/json; charset=utf-8'});
    }));
    addTearDown(client.close);
    final movies = await client.search('Um Filme', CatalogFilter.movies);
    expect(movies, hasLength(1));
    expect(movies.first.provider, 'Apple TV Store');
    expect(movies.first.kind, 'Filme');
    expect(movies.first.year, 2014);
  });

  test('Rede indisponível informa falha sem fabricar resultados', () async {
    final client = CatalogClient(client: MockClient((request) async =>
        http.Response('Unavailable', 503)));
    addTearDown(client.close);
    await expectLater(
      client.search('Busca', CatalogFilter.books),
      throwsA(isA<StateError>()),
    );
  });
}
