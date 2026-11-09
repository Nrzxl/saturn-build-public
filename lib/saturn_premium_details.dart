import 'package:flutter/material.dart';
import 'catalog_client.dart';

const satinGold = Color(0xFFC6A477);
const satinIvory = Color(0xFFF2E8DF);
const satinSubdued = Color(0xFFD4BFC6);

class SaturnDetailSection extends StatelessWidget {
  const SaturnDetailSection({
    super.key, required this.title, required this.child, this.icon,
  });
  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 9),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF2B212C),
      border: Border.all(color: const Color(0x555E4758)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (icon != null) ...[
            Icon(icon, color: satinGold, size: 18),
            const SizedBox(width: 9),
          ],
          Expanded(child: Text(title.toUpperCase(), style: const TextStyle(
            color: satinGold, letterSpacing: 1.4,
            fontSize: 11, fontWeight: FontWeight.w600,
          ))),
        ]),
        const SizedBox(height: 11),
        child,
      ],
    ),
  );
}

/// Ratings are attributable metadata, not the couple's own scores.
///
/// A public TMDB vote average is NOT the Rotten Tomatoes audience
/// Popcornmeter; Rotten Tomatoes and other sources need explicit feeds.
class SaturnExternalRatings extends StatelessWidget {
  const SaturnExternalRatings({
    super.key, required this.ratings, required this.isBook,
    this.tmdbScore, this.tmdbVoteCount,
  });

  final Map<String, String> ratings;
  final bool isBook;
  final double? tmdbScore;
  final int? tmdbVoteCount;

  static const _sources = [
    ('imdb', 'IMDb', Icons.movie_filter_outlined),
    ('rottenTomatoes', 'Rotten Tomatoes · crítica', Icons.local_movies_outlined),
    ('metacritic', 'Metacritic · crítica', Icons.insights_outlined),
  ];

  static bool validRating(String key, String? value) {
    if (value == null) return false;
    final input = value.trim();
    return switch (key) {
      'imdb' => RegExp(r'^(10([.]0)?|[0-9]([.][0-9])?)/10$')
          .hasMatch(input),
      'rottenTomatoes' => RegExp(r'^(100|[0-9]{1,2})%$')
          .hasMatch(input),
      'metacritic' => RegExp(r'^(100|[0-9]{1,2})/100$')
          .hasMatch(input),
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isBook) return const SizedBox.shrink();
    final hasAudience = tmdbScore != null && tmdbScore! > 0 &&
        tmdbScore! <= 10 && (tmdbVoteCount ?? 0) > 0;
    final external = [
      for (final source in _sources)
        if (validRating(source.$1, ratings[source.$1])) source,
    ];
    return SaturnDetailSection(
      title: 'Crítica e audiência',
      icon: Icons.stars_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AUDIÊNCIA · COMUNIDADE TMDB',
            style: TextStyle(color: satinGold,
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
          const SizedBox(height: 7),
          if (hasAudience)
            _RatingChip(
              title: 'Público TMDB',
              value: '${tmdbScore!.toStringAsFixed(1)}/10',
              icon: Icons.people_alt_outlined,
            )
          else
            const Text(
              'Ainda não há uma nota de público TMDB verificada para este título.',
              style: TextStyle(color: satinSubdued, fontSize: 12, height: 1.4),
            ),
          if (hasAudience) ...[
            const SizedBox(height: 5),
            Text(
              '${tmdbVoteCount!} votos da comunidade TMDB. '
              'Não é a nota do público Rotten Tomatoes.',
              style: const TextStyle(
                color: satinSubdued, fontSize: 11, height: 1.4),
            ),
          ],
          const SizedBox(height: 17),
          const Text('OUTRAS FONTES · NOTAS PUBLICADAS',
            style: TextStyle(color: satinGold,
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
          const SizedBox(height: 8),
          if (external.isEmpty)
            const Text(
              'As notas IMDb, Rotten Tomatoes e Metacritic não estão '
              'disponíveis neste catálogo. Elas exigem uma fonte '
              'autorizada e podem não existir para todas as obras.',
              style: TextStyle(color: satinSubdued, fontSize: 12, height: 1.4),
            )
          else
            Wrap(spacing: 9, runSpacing: 9, children: [
              for (final source in external)
                _RatingChip(
                  title: source.$2,
                  value: ratings[source.$1]!.trim(),
                  icon: source.$3,
                ),
            ]),
          const SizedBox(height: 11),
          Text(
            external.isEmpty
                ? 'SATURN não inventa pontuações ausentes. '
                  'As avaliações pessoais de vocês ficam separadas.'
                : 'Notas externas fornecidas por fonte atribuída via OMDb. '
                  'Elas não equivalem às estrelas de vocês nem a '
                  'uma pontuação de audiência Rotten Tomatoes.',
            style: const TextStyle(
              color: satinSubdued, fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// When an older locally saved title does not yet contain public scores,
/// consult the currently published SATURN catalog *without* changing notes,
/// watchlists, local storage or the stored Work snapshot.
class SaturnRatingsFromCatalog extends StatefulWidget {
  const SaturnRatingsFromCatalog({
    super.key,
    required this.workId,
    required this.workTitle,
    required this.kind,
    required this.cachedRatings,
    this.tmdbScore,
    this.tmdbVoteCount,
  });
  final String workId;
  final String workTitle;
  final String kind;
  final Map<String, String> cachedRatings;
  final double? tmdbScore;
  final int? tmdbVoteCount;

  @override
  State<SaturnRatingsFromCatalog> createState() =>
      _SaturnRatingsFromCatalogState();
}

class _SaturnRatingsFromCatalogState extends State<SaturnRatingsFromCatalog> {
  CatalogClient? _client;
  Future<CatalogEntry?>? _lookup;

  @override
  void initState() {
    super.initState();
    _startLookup();
  }

  void _startLookup() {
    _client?.close();
    _client = null;
    _lookup = null;
    if (!widget.workId.startsWith('tmdb:') ||
        widget.workTitle.trim().length < 2) {
      return;
    }
    final filter = switch (widget.kind) {
      'Filme' => CatalogFilter.movies,
      'Série' => CatalogFilter.series,
      'Dorama' => CatalogFilter.dramas,
      'Anime' => CatalogFilter.anime,
      _ => CatalogFilter.all,
    };
    _client = CatalogClient();
    _lookup = _client!.search(widget.workTitle, filter).then((items) {
      for (final item in items) {
        if (item.id == widget.workId) return item;
      }
      return null;
    }).catchError((Object _) => null);
  }

  @override
  void didUpdateWidget(covariant SaturnRatingsFromCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workId != widget.workId ||
        oldWidget.workTitle != widget.workTitle ||
        oldWidget.kind != widget.kind) {
      _startLookup();
    }
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CatalogEntry?>(
      future: _lookup,
      builder: (context, snapshot) {
        final refreshed = snapshot.data;
        final scores = <String, String>{
          ...widget.cachedRatings,
          if (refreshed != null) ...refreshed.externalRatings,
        };
        final hasFreshScores = refreshed?.externalRatings.isNotEmpty == true ||
            ((refreshed?.tmdbScore ?? 0) > 0 &&
                (refreshed?.tmdbVoteCount ?? 0) > 0);
        final initialHasScores = widget.cachedRatings.isNotEmpty ||
            (widget.tmdbScore != null && (widget.tmdbVoteCount ?? 0) > 0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SaturnExternalRatings(
              ratings: scores, isBook: false,
              tmdbScore: refreshed?.tmdbScore ?? widget.tmdbScore,
              tmdbVoteCount: refreshed?.tmdbVoteCount ?? widget.tmdbVoteCount,
            ),
            if (_lookup != null && !hasFreshScores && !initialHasScores &&
                snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.only(left: 12, bottom: 6),
                child: Text('Consultando notas públicas disponíveis…',
                    style: TextStyle(color: satinSubdued, fontSize: 11)),
              ),
            if (_lookup != null && snapshot.connectionState == ConnectionState.done &&
                !hasFreshScores && !initialHasScores)
              const Padding(
                padding: EdgeInsets.only(left: 12, bottom: 6),
                child: Text('O catálogo atual também não informa notas '
                  'verificadas para esta obra.',
                  style: TextStyle(color: satinSubdued, fontSize: 11)),
              ),
          ],
        );
      },
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.title, required this.value, required this.icon,
  });
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 130,
    constraints: const BoxConstraints(minHeight: 86),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFF1D1924),
      border: Border.all(color: const Color(0x557F6873)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: satinGold, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(title,
            overflow: TextOverflow.ellipsis, maxLines: 1,
            style: const TextStyle(
              fontSize: 10, color: satinSubdued))),
        ]),
        const SizedBox(height: 9),
        Text(value, style: const TextStyle(
          color: satinIvory, fontSize: 24,
          fontWeight: FontWeight.bold, height: 1,
        )),
      ],
    ),
  );
}

class SaturnCoupleReview extends StatelessWidget {
  const SaturnCoupleReview({
    super.key, required this.selfName, required this.otherName,
    required this.self, required this.other,
    required this.cloudConnected,
  });
  final String selfName;
  final String otherName;
  final Map<String, dynamic> self;
  final Map<String, dynamic> other;
  final bool cloudConnected;

  @override
  Widget build(BuildContext context) {
    Widget review(String label, Map<String, dynamic> record) {
      final note = (record['notes'] ?? '').toString().trim();
      final rating = record['rating'];
      final value = rating is num
          ? '${(rating.toDouble() / 2).toStringAsFixed(1)} ★'
          : 'Sem nota';
      final completed = (record['status'] ?? '').toString();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFF1D1923),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const CircleAvatar(radius: 13,
                backgroundColor: Color(0xFF51354A),
                child: Icon(Icons.person_outline_rounded,
                  color: satinGold, size: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: const TextStyle(
                fontWeight: FontWeight.bold, color: satinIvory))),
              Text(value, style: const TextStyle(
                color: satinGold, fontWeight: FontWeight.w700)),
            ]),
            if (completed.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(completed, style: const TextStyle(
                fontSize: 11, color: satinSubdued)),
            ],
            const SizedBox(height: 7),
            Text(
              note.isEmpty ? 'Ainda não escreveu uma resenha.' : '“$note”',
              style: TextStyle(
                fontStyle: note.isEmpty ? FontStyle.italic : FontStyle.normal,
                color: note.isEmpty ? satinSubdued : satinIvory,
                fontSize: 12, height: 1.4),
            ),
          ],
        ),
      );
    }

    return SaturnDetailSection(
      title: 'O que nós achamos',
      icon: Icons.favorite_border_rounded,
      child: Column(
        children: [
          review(selfName, self),
          review(otherName, other),
          Text(
            cloudConnected
              ? 'Resenhas dos dois perfis na Nossa Órbita conectada.'
              : 'A outra avaliação aparece aqui se estiver salva '
                'neste aparelho. Conecte Nossa Órbita para '
                'sincronizar entre Android e iPhone.',
            style: const TextStyle(
              color: satinSubdued, fontSize: 10, height: 1.3),
          ),
        ],
      ),
    );
  }
}
