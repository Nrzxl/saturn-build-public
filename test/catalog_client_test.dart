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
  test('IMDb verified identity wins duplicate cards without merging remakes', () {
    CatalogEntry media(String id, String title, int year, {
      String kind = 'Filme', String imdbId = '', String provider = 'Apple',
    }) => CatalogEntry(
      id: id, title: title, kind: kind, description: 'História',
      year: year, posterUrl: 'https://example.com/cover.jpg',
      creator: '', provider: provider, detailUrl: '', imdbId: imdbId,
    );

    final sameTitleWithoutId = media('itunes:1', 'Aventura', 2024);
    final verified = media('tmdb:movie:200', 'Aventura', 2024,
      imdbId: 'tt12345678', provider: 'TMDB');
    final duplicateDifferentLocale = media('tvmaze:900', 'Other name', 2024,
      imdbId: 'tt12345678', provider: 'TVMaze');
    final remake = media('tmdb:movie:201', 'Aventura', 2025,
      imdbId: 'tt12345679', provider: 'TMDB');
    final conflictingImdb = media('itunes:2', 'Aventura', 2024,
      imdbId: 'tt12345680');
    final bookFirst = media('openlibrary:edition:1', 'Aventura', 2024,
      kind: 'Livro');
    final bookSecond = media('openlibrary:edition:2', 'Aventura', 2024,
      kind: 'Livro');
    final picked = CatalogClient.deduplicate([
      sameTitleWithoutId, verified, duplicateDifferentLocale, remake,
      conflictingImdb, bookFirst, bookSecond,
    ]);
    expect(picked.map((e) => e.id), [
      'tmdb:movie:200', 'tmdb:movie:201', 'itunes:2',
      'openlibrary:edition:1', 'openlibrary:edition:2',
    ]);
    expect(picked.first.imdbId, 'tt12345678');
    // Zero-year works are not collapsed simply because their names match.
    expect(CatalogClient.deduplicate([
      media('itunes:3', 'Sem data', 0),
      media('tvmaze:3', 'Sem data', 0, kind: 'Filme'),
    ]), hasLength(2));
  });

}
