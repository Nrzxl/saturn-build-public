import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saturn_app/catalog_client.dart';
import 'package:saturn_app/saturn_orbit_merge.dart';

void main() {
  test('TVmaze imported titles display Brazilian Portuguese synopsis',
      () async {
    var requests = 0;
    final client = CatalogClient(
      client: MockClient((request) async {
        requests++;
        expect(request.url.host, 'api.tvmaze.com');
        expect(request.url.path, '/search/shows');
        return http.Response(jsonEncode([
          {
            'show': {
              'id': 526,
              'name': 'The Office',
              'premiered': '2005-03-24',
              'summary': '<p>A mock English synopsis about an office.</p>',
              'type': 'Scripted',
              'genres': ['Comedy'],
              'externals': {'imdb': 'tt0386676'},
            }
          },
        ]), 200);
      }),
      enableTmdb: false,
    );
    addTearDown(client.close);
    final found = await client.search('The Office', CatalogFilter.series);
    final office = found.firstWhere((e) => e.id == 'tvmaze:526');
    expect(office.description, contains('empresa de papel'));
    expect(office.description, isNot(contains('mock English')));
    expect(office.imdbId, 'tt0386676');
    expect(requests, greaterThanOrEqualTo(1));
  });

  test('Merge chooses verified TMDB row over stale TVmaze artwork', () {
    const id = 'tmdb:tv:2316';
    final outdated = {
      'catalogSaved': {
        'tvmaze:526': {
          'id': 'tvmaze:526', 'title': 'The Office',
          'kind': 'Série', 'year': 2005,
          'provider': 'TVmaze',
          'posterUrl': 'https://static.tvmaze.com/old.jpg',
        }
      },
      'records': {
        '1:tvmaze:526': {'rating': 10, 'notes': 'Avaliação antiga'},
      }
    };
    final canonical = {
      'catalogSaved': {
        id: {
          'id': id, 'title': 'The Office',
          'kind': 'Série', 'year': 2005,
          'provider': 'TMDB',
          'posterUrl': 'https://image.tmdb.org/t/p/w500/real.jpg',
          'description': 'Descrição brasileira',
        }
      },
      'records': {
        '0:$id': {'rating': 10, 'notes': 'Minha resenha'},
      }
    };
    final merged = SaturnOrbitMerge.merge(canonical, outdated);
    final saved = merged['catalogSaved'] as Map;
    expect(saved.keys, contains(id));
    expect(saved.keys, isNot(contains('tvmaze:526')));
    expect(saved[id]['posterUrl'], contains('image.tmdb.org'));
    expect(saved[id]['description'], 'Descrição brasileira');
    final records = merged['records'] as Map;
    expect(records['1:$id']['rating'], 10);
    expect(records['0:$id']['rating'], 10);
  });
}
