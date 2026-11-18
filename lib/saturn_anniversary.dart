import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The SATURN couple's monthly anniversary, by the device's LOCAL calendar.
/// Nothing is stored remotely and the celebration never changes ratings.
class SaturnAnniversary {
  const SaturnAnniversary._();
  static bool isActive(DateTime localDate) => localDate.day == 18;
}

/// A day-18-only celebration. The background is a lightweight CustomPainter;
/// copy and the shared collection do not rebuild during each animation frame.
class SaturnAnniversaryBanner extends StatefulWidget {
  const SaturnAnniversaryBanner({super.key, this.compact = false});
  final bool compact;

  @override
  State<SaturnAnniversaryBanner> createState() =>
      _SaturnAnniversaryBannerState();
}

class _SaturnAnniversaryBannerState extends State<SaturnAnniversaryBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cosmicMotion;

  @override
  void initState() {
    super.initState();
    _cosmicMotion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect system accessibility settings and Flutter's offstage tickers.
    final media = MediaQuery.of(context);
    final canAnimate = !media.disableAnimations && !media.reduceMotion &&
        TickerMode.of(context);
    if (canAnimate && !_cosmicMotion.isAnimating) {
      _cosmicMotion.repeat();
    } else if (!canAnimate && _cosmicMotion.isAnimating) {
      _cosmicMotion.stop();
    }
  }

  @override
  void dispose() {
    _cosmicMotion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    return Semantics(
      label: compact
          ? 'Nosso aniversário de namoro. Celebrando a nossa órbita.'
          : 'Nosso aniversário de namoro, dia 18. '
              'Celebrando mais um capítulo da nossa órbita.',
      child: Container(
        key: Key(compact ? 'saturn-anniversary-shared' : 'saturn-anniversary-home'),
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xA2DFC39A)),
          boxShadow: const [
            BoxShadow(color: Color(0x453E305D), blurRadius: 22,
                spreadRadius: 2, offset: Offset(0, 4)),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1D39), Color(0xFF3D254C),
              Color(0xFF512A46), Color(0xFF221E3E),
            ],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(child: IgnorePointer(child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _cosmicMotion,
              builder: (context, _) => CustomPaint(
                painter: _SaturnConstellationPainter(_cosmicMotion.value),
              ),
            ),
          ))),
          Padding(
            padding: EdgeInsets.fromLTRB(20, compact ? 19 : 27, 20,
                compact ? 20 : 29),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFFF2DAA8), size: 15),
                  const SizedBox(width: 8),
                  Flexible(child: Text(compact
                    ? 'ANIVERSÁRIO  ·  A NOSSA CONSTELAÇÃO'
                    : 'DIA 18  ·  A NOSSA CONSTELAÇÃO',
                    style: const TextStyle(color: Color(0xFFF2DAA8),
                      fontSize: 10, letterSpacing: 1.6,
                      fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 12),
                Text(compact ? 'Feliz aniversário, meu amor.' :
                    'Mais um capítulo na nossa órbita.',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'serif', color: const Color(0xFFFFF5ED),
                    fontSize: compact ? 21 : 25,
                    height: 1.17, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Em meio a todas as estrelas, nossa história é meu universo.',
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFFE5D8E5),
                    fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Composited cosmic atmosphere: slow twinkles, a passing comet and Saturn's
/// illuminated rings. All positions are deterministic, with no timers or assets.
class _SaturnConstellationPainter extends CustomPainter {
  const _SaturnConstellationPainter(this.phase);
  final double phase;

  static double _fraction(double value) => value - value.floorToDouble();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    final angle = phase * math.pi * 2;

    // Subtle moving nebula. Two local gradients, not a fullscreen shader.
    final nebula = Offset(size.width * (.76 + .035 * math.sin(angle)),
        size.height * .34);
    final glow = Rect.fromCircle(center: nebula,
        radius: math.max(size.width * .57, size.height * .92));
    canvas.drawRect(bounds, Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x354A7AA8), Color(0x164D377C),
          Color(0x003E244A)],
        stops: [0, .50, 1],
      ).createShader(glow));

    // Fixed star positions with independent, slow and looping luminosity.
    for (var i = 0; i < 32; i++) {
      final x = (.055 + .9 * _fraction(i * .61803398875 + .17))
          * size.width;
      final y = (.07 + .87 * _fraction(i * .7548776662 + .28))
          * size.height;
      final light = .55 + .45 * math.sin(angle + i * 1.59);
      final alpha = (105 + light * 143).round();
      final point = Offset(x, y);
      final color = Color.fromARGB(alpha, 255, 231, 203);
      canvas.drawCircle(point, i % 5 == 0 ? 1.65 : .85,
          Paint()..color = color);
      if (i % 7 == 0) {
        final ray = 2.3 + light * 2.2;
        final flare = Paint()
          ..color = Color.fromARGB((alpha * .47).round(), 255, 233, 212)
          ..strokeWidth = .7
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x - ray, y), Offset(x + ray, y), flare);
        canvas.drawLine(Offset(x, y - ray), Offset(x, y + ray), flare);
      }
    }

    // A fine constellation links the pair's stars without becoming busy.
    final constellation = [
      const Offset(.65, .12), const Offset(.79, .27),
      const Offset(.91, .13), const Offset(.94, .52),
      const Offset(.74, .82), const Offset(.84, .91),
    ].map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList(growable: false);
    final lines = Path()
      ..moveTo(constellation[0].dx, constellation[0].dy)
      ..lineTo(constellation[1].dx, constellation[1].dy)
      ..lineTo(constellation[2].dx, constellation[2].dy)
      ..moveTo(constellation[1].dx, constellation[1].dy)
      ..lineTo(constellation[3].dx, constellation[3].dy)
      ..lineTo(constellation[4].dx, constellation[4].dy)
      ..lineTo(constellation[5].dx, constellation[5].dy);
    canvas.drawPath(lines, Paint()
      ..color = const Color(0x3BDAC4EA)
      ..strokeWidth = .75
      ..style = PaintingStyle.stroke);

    // One gentle shooting star per loop. The short trail never intercepts
    // taps or adds a widget to the accessibility tree.
    final travel = phase;
    final cometAlpha = (math.sin(travel * math.pi).clamp(0.0, 1.0)
        * 130).round();
    final head = Offset(size.width * (.48 + travel * .43),
        size.height * (.08 + travel * .16));
    final trail = Offset(head.dx - 18, head.dy + 8);
    canvas.drawLine(trail, head, Paint()
      ..color = Color.fromARGB(cometAlpha, 255, 239, 210)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round);

    // Saturn is painted over the nebula, with rings behind and in front.
    final center = Offset(size.width * .85, size.height * .73);
    final radius = math.min(size.height * .125, size.width * .068);
    final aura = Rect.fromCircle(center: center, radius: radius * 2.6);
    canvas.drawCircle(center, radius * 2.6, Paint()
      ..shader = const RadialGradient(colors: [
        Color(0x6479A2D5), Color(0x283A4A82), Color(0x003A4A82),
      ]).createShader(aura));

    final ring = Rect.fromCenter(center: Offset.zero,
        width: radius * 5.2, height: radius * 1.68);
    final tilt = -.3 + .045 * math.sin(angle);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.drawOval(ring, Paint()
      ..color = const Color(0x8BF5D5B2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8);
    canvas.drawOval(ring.inflate(3.2), Paint()
      ..color = const Color(0x36DFC4DE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
    canvas.restore();

    final planet = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF7D8B4), Color(0xFFC18EAF),
          Color(0xFF68547F)],
      ).createShader(planet));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.drawArc(ring, .05, math.pi - .1, false, Paint()
      ..color = const Color(0xDDF5D5B2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.15);
    canvas.restore();

    // Sparkle at the ring's edge; a soft pulse instead of flashing lights.
    final sparkle = center + Offset(radius * 2.34, -radius * .8);
    final pulse = .65 + .35 * math.sin(angle);
    final sparklePaint = Paint()
      ..color = Color.fromARGB((pulse * 185).round(), 255, 238, 203)
      ..strokeWidth = .8
      ..strokeCap = StrokeCap.round;
    final reach = 2 + pulse * 3;
    canvas.drawLine(sparkle + Offset(-reach, 0),
        sparkle + Offset(reach, 0), sparklePaint);
    canvas.drawLine(sparkle + Offset(0, -reach),
        sparkle + Offset(0, reach), sparklePaint);
  }

  @override
  bool shouldRepaint(covariant _SaturnConstellationPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
