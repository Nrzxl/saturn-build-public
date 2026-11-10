/// Edition-specific presentation overrides. A missing Open Library cover
/// must not change the book's ID, ISBN, reading status or sync record.
class SaturnBookCover {
  const SaturnBookCover._();

  static const soulEaterPerfect01Id = 'openlibrary:/books/OL29840451M';
  static const soulEaterPerfect01Isbn = '9781646090013';
  static const soulEaterPerfect01Front =
      'https://images.thalia.media/-/BF2000-2000/1945d452ca8e49f3928ef7ca460e1c95/'
      'soul-eater-the-perfect-edition-01-gebundene-ausgabe-atsushi-ohkubo.jpeg';
  static const soulEaterPerfect01PublisherCover =
      'https://images.penguinrandomhouse.com/cover/9781646090013';

  static bool isPerfect01(String workId) =>
      workId == soulEaterPerfect01Id;

  /// Resolve exact edition to a verified matching cover; no title guessing.
  static String resolve(String workId, String original) =>
      isPerfect01(workId) ? soulEaterPerfect01Front : original;

  static String? fallback(String workId) =>
      isPerfect01(workId) ? soulEaterPerfect01PublisherCover : null;
}
