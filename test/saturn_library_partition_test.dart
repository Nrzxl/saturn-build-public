import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_library_partition.dart';

void main() {
  test('Coleção and Livros are disjoint views of the same saved works', () {
    final catalog = [
      {'id': 'm1', 'kind': 'Filme'},
      {'id': 'b1', 'kind': 'Livro'},
      {'id': 's1', 'kind': 'Série'},
      {'id': 'b2', 'kind': 'Livro'},
      {'id': 'd1', 'kind': 'Dorama'},
      {'id': 'a1', 'kind': 'Anime'},
    ];
    String kind(Map<String, String> row) => row['kind']!;
    final books = SaturnLibraryPartition.books(catalog, kind);
    final collection = SaturnLibraryPartition.collection(catalog, kind);
    expect(books.map((work) => work['id']), ['b1', 'b2']);
    expect(collection.map((work) => work['id']),
        ['m1', 's1', 'd1', 'a1']);
    expect({...books, ...collection}.length, catalog.length);
    expect(catalog.length, 6); // The source is never modified.
  });

  test('A single book never appears in Coleção and is never lost', () {
    const items = [{'id': 'isbn:9780000000000', 'kind': 'Livro'}];
    expect(SaturnLibraryPartition.collection(items, (w) => w['kind']!),
        isEmpty);
    expect(SaturnLibraryPartition.books(items, (w) => w['kind']!),
        items);
  });
}
