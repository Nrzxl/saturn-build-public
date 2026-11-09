import 'package:flutter/material.dart';

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

class SaturnExternalRatings extends StatelessWidget {
  const SaturnExternalRatings({
    super.key, required this.ratings, required this.isBook,
    this.tmdbScore, this.tmdbVoteCount,
  });
  final Map<String, String> ratings;
  final bool isBook;
  final double? tmdbScore;
  final int? tmdbVoteCount;

  @override
  Widget build(BuildContext context) {
    if (isBook) return const SizedBox.shrink();
    const sources = [
      ('imdb', 'IMDb', Icons.movie_filter_outlined),
      ('rottenTomatoes', 'Rotten Tomatoes', Icons.local_movies_outlined),
      ('metacritic', 'Metacritic', Icons.insights_outlined),
    ];
    return SaturnDetailSection(
      title: 'Crítica e audiência',
      icon: Icons.stars_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 9, runSpacing: 9, children: [
            if (tmdbScore != null && tmdbScore! > 0 && tmdbScore! <= 10 &&
                (tmdbVoteCount ?? 0) > 0)
              _RatingChip(
                title: 'TMDB',
                value: '${tmdbScore!.toStringAsFixed(1)}/10',
                icon: Icons.people_alt_outlined,
              ),
            for (final source in sources)
              _RatingChip(
                title: source.$2,
                value: ratings[source.$1] ?? '—',
                icon: source.$3,
              ),
          ]),
          const SizedBox(height: 9),
          Text(
            ratings.isEmpty
                ? 'IMDb, Rotten Tomatoes e Metacritic serão exibidos '
                  'somente quando houver dados autorizados. '
                  'A nota TMDB é uma avaliação separada da comunidade.'
                : 'Notas externas via OMDb; podem não existir para '
                  'todas as obras. Não são as estrelas de vocês.',
            style: const TextStyle(
              color: satinSubdued, fontSize: 11, height: 1.35),
          ),
        ],
      ),
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
