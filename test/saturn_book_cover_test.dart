import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_book_cover.dart';

void main() {
  test('Soul Eater Perfect Edition 01 usa capa da edição correta', () {
    const id = 'openlibrary:/books/OL29840451M';
    const old = 'https://covers.openlibrary.org/b/isbn/9781646090013-M.jpg';
    expect(SaturnBookCover.resolve(id, old),
        SaturnBookCover.soulEaterPerfect01Front);
    expect(SaturnBookCover.fallback(id),
        SaturnBookCover.soulEaterPerfect01PublisherCover);
    expect(SaturnBookCover.resolve(
      'openlibrary:/books/OL222222M', old), old);
    expect(SaturnBookCover.fallback(
      'openlibrary:/works/OL21882850W'), isNull);
  });
}
