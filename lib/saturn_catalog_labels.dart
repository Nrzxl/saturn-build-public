/// Human-readable BR metadata shown on cards only when actually provided.
/// No runtime, season count or genre is inferred from a title or provider.
class SaturnCatalogLabels {
  const SaturnCatalogLabels._();

  static const Map<int, String> _genres = {
    12: 'Aventura', 14: 'Fantasia', 16: 'Animação',
    18: 'Drama', 27: 'Terror', 28: 'Ação', 35: 'Comédia',
    36: 'História', 37: 'Faroeste', 53: 'Suspense',
    80: 'Crime', 99: 'Documentário', 878: 'Ficção científica',
    9648: 'Mistério', 10402: 'Musical', 10749: 'Romance',
    10751: 'Família', 10752: 'Guerra', 10759: 'Ação e aventura',
    10762: 'Infantil', 10763: 'Notícias',
    10764: 'Reality', 10765: 'Ficção e fantasia',
    10766: 'Novela', 10767: 'Talk show', 10768: 'Guerra e política',
  };

  static List<String> genres(List<int> ids, {int limit = 2}) {
    final chosen = <String>[];
    for (final id in ids) {
      final name = _genres[id];
      if (name != null && !chosen.contains(name)) chosen.add(name);
      if (chosen.length >= limit) break;
    }
    return chosen;
  }

  static String genreLine(List<int> ids) => genres(ids).join(' · ');

  static String? technical({
    required String kind,
    int? runtimeMinutes,
    int? seasonCount,
    int? pageCount,
  }) {
    if (kind == 'Filme' && runtimeMinutes != null &&
        runtimeMinutes > 0 && runtimeMinutes <= 800) {
      return '${runtimeMinutes} min';
    }
    if (kind == 'Série' || kind == 'Dorama' || kind == 'Anime') {
      final seasons = seasonCount != null &&
              seasonCount > 0 && seasonCount < 200
          ? '${seasonCount} ${seasonCount == 1 ? "temporada" : "temporadas"}'
          : '';
      final episode = runtimeMinutes != null &&
              runtimeMinutes > 0 && runtimeMinutes <= 300
          ? '${runtimeMinutes} min/ep.'
          : '';
      if (seasons.isNotEmpty && episode.isNotEmpty) {
        return '$seasons · $episode';
      }
      if (seasons.isNotEmpty) return seasons;
      if (episode.isNotEmpty) return episode;
    }
    if (kind == 'Livro' && pageCount != null &&
        pageCount > 0 && pageCount <= 10000) {
      return '${pageCount} ${pageCount == 1 ? "página" : "páginas"}';
    }
    return null;
  }
}
