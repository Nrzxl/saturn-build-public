import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'catalog_client.dart';
import 'saturn_review_tiers.dart';

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

/// Personal star ratings stay separate. The only external score displayed
/// in SATURN is a verified Metacritic critic score (0-100). It is never
/// computed from TMDB, IMDb, Rotten Tomatoes, or partner reviews.
class SaturnExternalRatings extends StatelessWidget {
  const SaturnExternalRatings({
    super.key, required this.ratings, required this.isBook,
    this.tmdbScore, this.tmdbVoteCount, this.workTitle = '',
  });

  final Map<String, String> ratings;
  final String workTitle;
  final bool isBook;
  // Keep compatibility with existing catalog entries, but do not display
  // these values or use them as a fallback for the Metacritic score.
  final double? tmdbScore;
  final int? tmdbVoteCount;

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

  static Uri sourceSearch(String key, String title) {
    final query = title.trim();
    return switch (key) {
      'imdb' => Uri.https('www.imdb.com', '/find/', {'q': query}),
      'rottenTomatoes' => Uri.https(
          'www.rottentomatoes.com', '/search', {'search': query}),
      'metacritic' => Uri.https(
          'www.metacritic.com', '/search/' + query + '/'),
      _ => throw ArgumentError.value(key, 'source', 'Unknown source'),
    };
  }

  Future<void> _openMetacritic() async {
    if (workTitle.trim().isEmpty) return;
    try {
      await launchUrl(sourceSearch('metacritic', workTitle),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      // External browser availability must not affect saved private reviews.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isBook ||
        !validRating('metacritic', ratings['metacritic'])) {
      // No empty 'Metacritic unavailable' block or duplicate disclaimers.
      // In particular, legacy TVmaze records do not have verified scores.
      return const SizedBox.shrink();
    }
    return SaturnDetailSection(
      title: 'Metacritic · crítica',
      icon: Icons.insights_outlined,
      child: Row(children: [
        _RatingChip(
          title: 'Metascore · crítica',
          value: ratings['metacritic']!.trim(),
          icon: Icons.insights_outlined,
        ),
        if (workTitle.trim().isNotEmpty) ...[
          const SizedBox(width: 12),
          Flexible(child: TextButton.icon(
            onPressed: _openMetacritic,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Fonte oficial'),
          )),
        ],
      ]),
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
    if (!widget.workId.startsWith('tmdb:')) return;
    // Online catalog lookups use the exact TMDB ID, not an ambiguous title.
    _client = CatalogClient();
    _lookup = _client!.onlineRatingsById(widget.workId)
        .catchError((Object _) => null);
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SaturnExternalRatings(
              ratings: scores, isBook: false,
              workTitle: widget.workTitle,
              tmdbScore: refreshed?.tmdbScore ?? widget.tmdbScore,
              tmdbVoteCount: refreshed?.tmdbVoteCount ?? widget.tmdbVoteCount,
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

/// Each partner's saved score and memory are visually independent.
/// The active profile is explicit, even when both reviews have different tiers.
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

  Widget _review({
    required Key key,
    required String heading,
    required String name,
    required Map<String, dynamic> record,
    required IconData icon,
    required bool mine,
  }) {
    final score = SaturnReviewClassification.stars(record);
    final tier = SaturnReviewClassification.fromRating(record);
    final accent = tier?.color ?? (mine
        ? satinGold : const Color(0xFFCEBBD8));
    final note = (record['notes'] ?? '').toString().trim();
    final completed = (record['status'] ?? '').toString();

    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: .18),
            const Color(0xFF211A27),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: .78), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: accent, size: 19),
            const SizedBox(width: 7),
            Expanded(child: Text(
              heading,
              style: TextStyle(
                color: accent, letterSpacing: 1.2,
                fontSize: 10, fontWeight: FontWeight.w800,
              ),
            )),
          ]),
          const SizedBox(height: 5),
          Text(name,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: satinIvory, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            score == null ? 'Sem nota'
                : '${score.toStringAsFixed(1)} ★',
            key: Key(mine ? 'saturn-review-self-score'
                : 'saturn-review-partner-score'),
            style: TextStyle(
              color: score == null ? satinSubdued : accent,
              fontSize: score == null ? 19 : 29,
              fontWeight: FontWeight.w900, height: 1,
            ),
          ),
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(completed, style: const TextStyle(
              fontSize: 11, color: satinSubdued)),
          ],
          const SizedBox(height: 10),
          Text(
            note.isEmpty
                ? 'Ainda não escreveu uma resenha.' : '“$note”',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontStyle: note.isEmpty
                  ? FontStyle.italic : FontStyle.normal,
              color: note.isEmpty ? satinSubdued : satinIvory,
              fontSize: 12, height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SaturnDetailSection(
      title: 'Nossas avaliações · notas individuais',
      icon: Icons.people_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 530;
            // An unscored partner must not leave an empty review panel.
            // No saved record, note, or independent profile is changed.
            final partnerRated =
                SaturnReviewClassification.stars(other) != null;
            final mine = _review(
              key: const Key('saturn-couple-review-self'),
              heading: 'SUA NOTA',
              name: selfName,
              record: self,
              icon: Icons.person_rounded,
              mine: true,
            );
            final partner = _review(
              key: const Key('saturn-couple-review-other'),
              heading: 'NOTA DA OUTRA PESSOA',
              name: otherName,
              record: other,
              icon: Icons.nightlight_round,
              mine: false,
            );
            if (!partnerRated) return mine;
            return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: mine),
                    const SizedBox(width: 12),
                    Expanded(child: partner),
                  ],
                )
              : Column(children: [
                  mine,
                  const SizedBox(height: 10),
                  partner,
                ]);
          }),
          const SizedBox(height: 10),
          Text(
            cloudConnected
              ? 'As notas são independentes e sincronizadas por perfil.'
              : 'As notas continuam separadas por perfil. Conecte '
                'Nossa Órbita para sincronizar entre aparelhos.',
            style: const TextStyle(
              color: satinSubdued, fontSize: 10, height: 1.3),
          ),
        ],
      ),
    );
  }
}
