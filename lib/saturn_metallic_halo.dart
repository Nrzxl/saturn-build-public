import 'dart:async';

import 'package:flutter/material.dart';

/// A metallic light that shifts along the poster rim and softly tints the art.
/// There are deliberately no category words or decorative badges.
class SaturnMetallicHalo extends StatefulWidget {
  const SaturnMetallicHalo({super.key, required this.color,
    this.partnerColor, required this.child});
  final Color? color;
  /// Second partner's real metallic tier. Left half is mine, right is hers.
  final Color? partnerColor;
  final Widget child;

  @override
  State<SaturnMetallicHalo> createState() => _SaturnMetallicHaloState();
}

class _SaturnMetallicHaloState extends State<SaturnMetallicHalo> {
  Timer? _timer;
  bool _shifted = false;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  @override
  void didUpdateWidget(covariant SaturnMetallicHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color ||
        oldWidget.partnerColor != widget.partnerColor) _configure();
  }

  void _configure() {
    _timer?.cancel();
    _timer = widget.color == null && widget.partnerColor == null
        ? null
        : Timer.periodic(const Duration(milliseconds: 4300), (_) {
            if (mounted) setState(() => _shifted = !_shifted);
          });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metal = widget.color ?? widget.partnerColor;
    if (metal == null) return widget.child;
    final paired = widget.color != null && widget.partnerColor != null;
    final same = paired && widget.color == widget.partnerColor;
    final second = widget.partnerColor ?? metal;
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final moved = !reducedMotion && _shifted;
    final glint = Color.lerp(metal, Colors.white,
        same ? (moved ? 0.90 : 0.80) : 0.62)!;
    final partnerGlint = Color.lerp(second, Colors.white,
        same ? (moved ? 0.93 : 0.79) : 0.45)!;
    final duration = Duration(milliseconds: reducedMotion ? 0 : 1550);
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(2.4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: paired
              ? LinearGradient(
                  // Real split rim: left = profile 0, right = profile 1.
                  begin: moved ? Alignment.bottomLeft : Alignment.topLeft,
                  end: moved ? Alignment.topRight : Alignment.bottomRight,
                  stops: const [0, .30, .48, .52, .70, 1],
                  colors: [
                    metal.withValues(alpha: same ? 0.99 : 0.94),
                    metal.withValues(alpha: 0.83),
                    glint.withValues(alpha: same ? 1 : 0.86),
                    partnerGlint.withValues(alpha: same ? 1 : 0.86),
                    second.withValues(alpha: 0.83),
                    second.withValues(alpha: same ? 0.99 : 0.94),
                  ],
                )
              : LinearGradient(
                  begin: moved ? Alignment.bottomRight : Alignment.topLeft,
                  end: moved ? Alignment.topLeft : Alignment.bottomRight,
                  stops: const [0, 0.27, 0.52, 0.77, 1],
                  colors: [
                    metal.withValues(alpha: 0.78),
                    metal.withValues(alpha: 0.32),
                    glint.withValues(alpha: moved ? 0.98 : 0.79),
                    metal.withValues(alpha: 0.49),
                    metal.withValues(alpha: 0.89),
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color: metal.withValues(alpha: same
                  ? (moved ? 0.75 : 0.53) : moved ? 0.31 : 0.18),
              blurRadius: same ? (moved ? 30 : 22) : moved ? 21 : 14,
              spreadRadius: same ? (moved ? 2.8 : 1.7)
                  : moved ? 1.1 : 0.4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              // Low-opacity tint blends the cover/art with its metallic rim.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: duration,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: moved ? Alignment.bottomLeft : Alignment.topRight,
                        end: moved ? Alignment.topRight : Alignment.bottomLeft,
                        stops: const [0, 0.20, 0.50, 0.80, 1],
                        colors: [
                          metal.withValues(alpha: 0.105),
                          Colors.transparent,
                          glint.withValues(alpha: 0.06),
                          Colors.transparent,
                          second.withValues(alpha: same ? 0.18 : 0.085),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
