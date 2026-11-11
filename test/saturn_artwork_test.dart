import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_artwork.dart';

void main() {
  test('TMDB posters receive a suitable HD size', () {
    expect(SaturnArtwork.bestUrl(
      'https://image.tmdb.org/t/p/w185/someposter.jpg', devicePixels: 580),
      'https://image.tmdb.org/t/p/w780/someposter.jpg');
    expect(SaturnArtwork.bestUrl(
      'https://image.tmdb.org/t/p/w342/someposter.jpg', devicePixels: 200),
      'https://image.tmdb.org/t/p/w342/someposter.jpg');
    expect(SaturnArtwork.bestUrl(
      'https://image.tmdb.org/t/p/w185/someposter.jpg', devicePixels: 430),
      'https://image.tmdb.org/t/p/w500/someposter.jpg');
  });

  test('TVmaze original and Open Library large are provider-safe', () {
    expect(SaturnArtwork.bestUrl(
      'https://static.tvmaze.com/uploads/images/medium_portrait/1/22.jpg',
      devicePixels: 450),
      'https://static.tvmaze.com/uploads/images/original_untouched/1/22.jpg');
    expect(SaturnArtwork.bestUrl(
      'https://covers.openlibrary.org/b/id/1234-M.jpg?default=false',
      devicePixels: 480),
      'https://covers.openlibrary.org/b/id/1234-L.jpg?default=false');
    expect(SaturnArtwork.bestUrl(
      'https://static.tvmaze.com/uploads/images/medium_portrait/1/22.jpg',
      devicePixels: 110),
      'https://static.tvmaze.com/uploads/images/medium_portrait/1/22.jpg');
    expect(SaturnArtwork.bestUrl(
      'https://covers.openlibrary.org/b/id/1234-M.jpg',
      devicePixels: 120),
      contains('1234-M.jpg'));
  });

  test('Unrecognized provider and edition-specific cover are unchanged', () {
    const cover = 'https://images.penguinrandomhouse.com/cover/9781646090013';
    expect(SaturnArtwork.bestUrl(cover, devicePixels: 700), cover);
    expect(SaturnArtwork.bestUrl('http://invalid.example/poster.jpg'),
        'http://invalid.example/poster.jpg');
  });

  test('Empty art does not trigger image extraction', () async {
    expect(await SaturnArtwork.toneFor(''), SaturnArtwork.fallback);
  });
}
