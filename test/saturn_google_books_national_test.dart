import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saturn_app/catalog_client.dart';

void main() {
  test('Google Livros acrescenta volumes nacionais reais em português',
      () async {
    final c = CatalogClient(client: MockClient((request) async {
      if (request.url.host == 'openlibrary.org') {
        return http.Response('Service unavailable', 503);
      }
      expect(request.url.host, 'www.googleapis.com');
      expect(request.url.path, '/books/v1/volumes');
      expect(request.url.queryParameters['langRestrict'], 'pt');
      expect(request.url.queryParameters['printType'], 'books');
      // The author/title query must not inherit a stale subject filter.
      expect(request.url.queryParameters['q'], 'Machado de Assis');
      return http.Response(jsonEncode({
        'items': [
          {
            'id': 'real-volume-1',
            'volumeInfo': {
              'title': 'Dom Casmurro',
              'language': 'pt-BR',
              'authors': ['Machado de Assis'],
              'publishedDate': '2018-10-11',
              'publisher': 'Editora brasileira',
              'imageLinks': {
                'large': 'http://books.google.com/edition-hd.jpg',
                'thumbnail': 'http://books.google.com/example-cover.jpg',
              },
              'industryIdentifiers': [
                {'type': 'ISBN_13', 'identifier': '9788550000000'}
              ],
            },
          },
          {
            'id': 'foreign-volume',
            'volumeInfo': {
              'title': 'English volume', 'language': 'en',
            },
          },
        ],
      }), 200);
    }));
    addTearDown(c.close);
    final books = await c.search('Machado de Assis',
      CatalogFilter.books, bookSubject: 'brazilian_literature');
    expect(books, hasLength(1));
    expect(books.single.id, 'googlebooks:real-volume-1');
    expect(books.single.title, 'Dom Casmurro');
    expect(books.single.creator, 'Machado de Assis');
    expect(books.single.description, contains('9788550000000'));
    expect(books.single.posterUrl,
        'https://books.google.com/edition-hd.jpg');
  });

  test('Agatha Christie busca o autor mesmo após categoria nacional',
      () async {
    final calls = <String>[];
    final client = CatalogClient(client: MockClient((request) async {
      calls.add(request.url.queryParameters['q'] ?? '');
      if (request.url.host == 'openlibrary.org') {
        return http.Response(jsonEncode({'docs': [{
          'key': '/works/OL777W',
          'title': 'And Then There Were None',
          'author_name': ['Agatha Christie'],
          'cover_i': 420,
          'first_publish_year': 1939,
        }]}), 200);
      }
      return http.Response(jsonEncode({'items': [{
        'id': 'pt-volume',
        'volumeInfo': {
          'title': 'E Não Sobrou Nenhum',
          'language': 'pt',
          'authors': ['Agatha Christie'],
        },
      }]}), 200, headers: {
        'content-type': 'application/json; charset=utf-8',
      });
    }));
    addTearDown(client.close);
    final result = await client.search('Agatha Christie',
        CatalogFilter.books, bookSubject: 'brazilian_literature');
    expect(result.any((book) => book.title == 'E Não Sobrou Nenhum'), isTrue,
      reason: 'Titles: ${result.map((e) => e.title).toList()}; calls: $calls');
    expect(calls, contains('Agatha Christie'));
    expect(calls.where((q) => q.contains('subject:brazilian_literature')),
      isEmpty);
  });

  test('Descoberta nacional pagina autores de verdade sob demanda', () async {
    final searched = <String>[];
    final c = CatalogClient(client: MockClient((request) async {
      if (request.url.host == 'openlibrary.org') {
        return http.Response(jsonEncode({'works': []}), 200);
      }
      searched.add(request.url.queryParameters['q']!);
      expect(request.url.queryParameters['maxResults'], '40');
      return http.Response(jsonEncode({'items': [{
        'id': 'volume-' + searched.length.toString(),
        'volumeInfo': {
          'title': 'Livro nacional pesquisado', 'language': 'pt',
          'authors': ['Autor brasileiro'],
        },
      }]}), 200);
    }));
    addTearDown(c.close);
    final a = await c.discover(CatalogFilter.books,
        bookSubject: 'brazilian_literature', page: 1);
    final b = await c.discover(CatalogFilter.books,
        bookSubject: 'brazilian_literature', page: 2);
    expect(a, hasLength(1));
    expect(b, hasLength(1));
    expect(searched.first, contains('Machado de Assis'));
    expect(searched.last, contains('Clarice Lispector'));
  });
}
