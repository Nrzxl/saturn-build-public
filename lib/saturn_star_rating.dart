import 'package:flutter/material.dart';

/// Armazenamento legado usa 0 a 10; a interface usa 0 a 5 estrelas.
double starsFromLegacy(num? rating) =>
    ((rating ?? 0).toDouble() / 2).clamp(0.0, 5.0);

double legacyFromStars(double stars) =>
    (stars.clamp(0.0, 5.0) * 2).roundToDouble();

class SaturnStarRating extends StatelessWidget {
  final double stars;
  final ValueChanged<double>? onChanged;
  final double size;
  final bool showValue;
  /// Distinguishes an explicitly saved zero-star review from no rating.
  final bool zeroIsRating;

  const SaturnStarRating({
    super.key,
    required this.stars,
    this.onChanged,
    this.size = 32,
    this.showValue = true,
    this.zeroIsRating = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = stars.clamp(0.0, 5.0);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 4,
      children: [
        for (var index = 0; index < 5; index++)
          Semantics(
            label: 'Estrela ${index + 1} de 5',
            button: onChanged != null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: onChanged == null
                  ? null
                  : (details) {
                      final half = details.localPosition.dx < size / 2;
                      final picked = index + (half ? 0.5 : 1.0);
                      onChanged!(picked);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Icon(
                  value >= index + 1
                      ? Icons.star_rounded
                      : value >= index + 0.5
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded,
                  size: size,
                  color: const Color(0xFFC6A477),
                ),
              ),
            ),
          ),
        if (showValue)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              value == 0 && !zeroIsRating
                  ? 'Sem nota' : '${value.toStringAsFixed(1)} ★',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFF2E8DF),
              ),
            ),
          ),
      ],
    );
  }
}
