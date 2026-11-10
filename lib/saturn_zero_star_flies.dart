import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tiny, playful insects hovering above a film explicitly rated ZERO.
/// Decorative and pointer-transparent. There is no animation on unrated art
/// or when the visitor has reduced-motion enabled.
class SaturnZeroStarFlies extends StatefulWidget {
  const SaturnZeroStarFlies({super.key});

  @override
  State<SaturnZeroStarFlies> createState() => _SaturnZeroStarFliesState();
}

class _SaturnZeroStarFliesState extends State<SaturnZeroStarFlies>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6100),
  )..repeat();

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      ignoring: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _SaturnFliesPainter(_flight),
            size: Size.infinite,
            isComplex: false,
            willChange: true,
          ),
        ),
      ),
    );
  }
}

class _SaturnFliesPainter extends CustomPainter {
  _SaturnFliesPainter(this.flight) : super(repaint: flight);
  final Animation<double> flight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = flight.value * math.pi * 2;
    final factor = math.min(size.width / 145, size.height / 180)
        .clamp(.65, 1.4).toDouble();

    void insect(double x, double y, double phase, double scale) {
      final origin = Offset(
        size.width * x + math.sin(t + phase) * (19 * factor),
        size.height * y + math.cos(t * .82 + phase) * (12 * factor),
      );
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(math.sin(t * 1.4 + phase) * .34);
      canvas.scale(factor * scale);

      // Tiny white wings flicker without flashing or creating a new widget.
      final wing = Paint()
        ..color = const Color(0xDAE6E5D4)
        ..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(
        center: Offset(-3.5, -3.1 + math.sin(t * 9 + phase) * .7),
        width: 5.5, height: 3), wing);
      canvas.drawOval(Rect.fromCenter(
        center: Offset(3.5, -3.1 - math.sin(t * 9 + phase) * .7),
        width: 5.5, height: 3), wing);

      final body = Paint()..color = const Color(0xEC101016);
      canvas.drawOval(Rect.fromCenter(
        center: Offset.zero, width: 5, height: 8), body);
      canvas.drawCircle(const Offset(0, -4), 2.2, body);
      canvas.drawCircle(const Offset(-1, -4.6), .65,
        Paint()..color = const Color(0xFFBF7688));
      canvas.restore();
    }

    insect(.30, .19, 0, 1);
    insect(.69, .36, 2.2, .82);
    insect(.46, .12, 4.4, .65);
  }

  @override
  bool shouldRepaint(covariant _SaturnFliesPainter oldDelegate) =>
      oldDelegate.flight != flight;
}
