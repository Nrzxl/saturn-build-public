import 'package:flutter/material.dart';

/// Personal classification. The halo is an award for a written review,
/// not for a film's imported synopsis or its public TMDB/IMDb rating.
enum SaturnReviewTier { bronze, prata, ouro }

extension SaturnReviewTierAppearance on SaturnReviewTier {
  String get label => switch (this) {
    SaturnReviewTier.bronze => 'BRONZE',
    SaturnReviewTier.prata => 'PRATA',
    SaturnReviewTier.ouro => 'OURO',
  };

  Color get color => switch (this) {
    SaturnReviewTier.bronze => const Color(0xFFC38A62),
    SaturnReviewTier.prata => const Color(0xFFBDC8D4),
    SaturnReviewTier.ouro => const Color(0xFFE3BF70),
  };
}

class SaturnReviewClassification {
  const SaturnReviewClassification._();

  /// Older SATURN records are stored as scores from 0 through 10.
  /// An explicit zero can be bronze; an absent rating can never glow.
  static double? stars(Object? row) {
    if (row is! Map || row['rating'] is! num) return null;
    final score = (row['rating'] as num).toDouble();
    if (!score.isFinite || score < 0 || score > 10) return null;
    return score / 2;
  }

  static bool hasWrittenReview(Object? row) =>
      row is Map && (row['notes'] ?? '').toString().trim().isNotEmpty;

  static SaturnReviewTier? of(Object? row) {
    final value = stars(row);
    if (value == null || !hasWrittenReview(row)) return null;
    if (value >= 4) return SaturnReviewTier.ouro;
    if (value >= 2) return SaturnReviewTier.prata;
    return SaturnReviewTier.bronze;
  }
}
