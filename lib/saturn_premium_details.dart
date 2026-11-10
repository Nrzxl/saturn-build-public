import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
    if (isBook) return const SizedBox.shrink();
    final valid = validRating('metacritic', ratings['metacritic']);
    return SaturnDetailSection(
      title: 'Metacritic · crítica',
      icon: Icons.insights_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (valid)
            _RatingChip(
              title: 'Metascore · crítica',
              value: ratings['metacritic']!.trim(),
              icon: Icons.insights_outlined,
            )
          else
            const Text(
              'Nota Metacritic não disponível para esta obra. '
              'Não estimamos pontuações de crítica usando outros serviços.',
              style: TextStyle(color: satinSubdued, fontSize: 12, height: 1.4),
            ),
          if (workTitle.trim().isNotEmpty) ...[
            const SizedBox(height: 11),
            ActionChip(
              tooltip: 'Consultar a obra diretamente no site oficial',
              avatar: const Icon(Icons.open_in_new, size: 15, color: satinGold),
              label: const Text('Ver no Metacritic',
                  style: TextStyle(fontSize: 11)),
              onPressed: _openMetacritic,
            ),
          ],
          const SizedBox(height: 11),
          const Text(
            'Exibimos apenas o Metascore quando há fonte atribuída. '
            'Suas notas pessoais e as do casal não são alteradas.',
            style: TextStyle(
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
        final hasFreshScores = SaturnExternalRatings.validRating(
            'metacritic', refreshed?.externalRatings['metacritic']);
        final initialHasScores = SaturnExternalRatings.validRating(
            'metacritic', widget.cachedRatings['metacritic']);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SaturnExternalRatings(
              ratings: scores, isBook: false,
              workTitle: widget.workTitle,
              tmdbScore: refreshed?.tmdbScore ?? widget.tmdbScore,
              tmdbVoteCount: refreshed?.tmdbVoteCount ?? widget.tmdbVoteCount,
            ),
            if (_lookup != null && !hasFreshScores && !initialHasScores &&
                snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.only(left: 12, bottom: 6),
                child: Text('Consultando notas públicas do catálogo online…',
                    style: TextStyle(color: satinSubdued, fontSize: 11)),
              ),
            if (_lookup != null && snapshot.connectionState == ConnectionState.done &&
                !hasFreshScores && !initialHasScores)
              const Padding(
                padding: EdgeInsets.only(left: 12, bottom: 6),
                child: Text('O catálogo não informa uma nota Metacritic verificada '
                  'para esta obra.',
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
