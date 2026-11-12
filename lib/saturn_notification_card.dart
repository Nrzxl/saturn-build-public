import 'package:flutter/material.dart';

import 'saturn_metallic_halo.dart';
import 'saturn_review_tiers.dart';
import 'saturn_zero_star_flies.dart';

/// One shared, personalizable notification tile for Web/PWA and Android.
/// Rating is always the *author's* saved score, never an external rating.
class SaturnNoticeCard extends StatelessWidget {
  const SaturnNoticeCard({
    super.key,
    required this.headline,
    required this.title,
    required this.author,
    required this.when,
    required this.kind,
    required this.posterUrl,
    required this.rating,
    required this.unread,
    required this.onTap,
  });

  final String headline, title, author, when, kind, posterUrl;
  final Object? rating;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final record = rating is num ? <String, Object?>{'rating': rating} : null;
    final tier = SaturnReviewClassification.fromRating(record);
    final zeroMovie = SaturnReviewClassification.shouldShowFlies(kind, record);
    final rim = tier?.color;
    final poster = posterUrl.startsWith('https://') ? posterUrl : '';
    final color = rim ?? const Color(0xFF705266);

    final image = poster.isEmpty
        ? const _PosterFallback()
        : Image.network(
            poster,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const _PosterFallback(),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      child: SaturnMetallicHalo(
        color: rim,
        intenseBronze: zeroMovie,
        child: Material(
          color: const Color(0xFF2A202D),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 78,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          image,
                          if (zeroMovie)
                            const Positioned.fill(
                              child: SaturnZeroStarFlies(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFF2E8DF),
                            fontWeight: unread
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$author · $when',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCDB8C5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  unread
                      ? const Icon(
                          Icons.circle,
                          size: 8,
                          color: Color(0xFFC6A477),
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF987C90),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFF3C293A),
        child: Center(
          child: Icon(
            Icons.auto_stories_rounded,
            color: Color(0xFFC6A477),
            size: 23,
          ),
        ),
      );
}
