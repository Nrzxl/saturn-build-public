import 'package:flutter/material.dart';
import 'saturn_review_tiers.dart';

/// Single visual vocabulary for old (0–10 stored) and new (0–5 shown)
/// personal scores. Never writes data or fabricates a missing partner note.
class SaturnPersonalScore extends StatelessWidget {
  const SaturnPersonalScore({
    super.key, required this.name, required this.record,
    this.compact = true,
    this.fillWidth = false,
  });

  final String name;
  final Object? record;
  final bool compact;

  /// Used by the paired rating row: stretch both outlined pills to identical
  /// widths, while scaling long names inside the border without clipping.
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final score = SaturnReviewClassification.stars(record);
    if (score == null) return const SizedBox.shrink();
    final metal = SaturnReviewClassification.fromRating(record)?.color ??
        const Color(0xFFCEB9C6);
    final label = Text(
      '${name} ${score.toStringAsFixed(1)} ★',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: metal,
        fontSize: compact ? 10 : 12,
        fontWeight: FontWeight.w800,
      ),
    );
    return Container(
      alignment: fillWidth ? Alignment.center : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: metal.withValues(alpha: .13),
        border: Border.all(color: metal.withValues(alpha: .68)),
      ),
      child: fillWidth
          ? FittedBox(fit: BoxFit.scaleDown, child: label)
          : label,
    );
  }
}
