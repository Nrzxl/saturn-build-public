import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'saturn_review_tiers.dart';

/// The SATURN couple's monthly anniversary, by the device's LOCAL calendar.
/// Nothing is stored remotely and the celebration never changes ratings.
class SaturnAnniversary {
  const SaturnAnniversary._();

  /// Date of the couple's first official relationship anniversary.
  static DateTime get startedAt => DateTime(2025, 1, 18);
  static bool isActive(DateTime localDate) => localDate.day == 18;
  /// Explicit local day of transition into watched status. Do not infer from
  /// generic updatedAt, which also changes on edits to notes and ratings.
  static String calendarDay(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  static bool isWatchedStatus(Object? status) {
    final value = (status ?? '').toString().trim().toLowerCase();
    return value == 'concluído' || value == 'assistido' || value == 'visto';
  }

  static String? completedOnAfter({
    required Object? previous,
    required Object? nextStatus,
    required DateTime localNow,
  }) {
    if (!isWatchedStatus(nextStatus)) return null;
    final old = previous is Map ? previous : const <String, Object?>{};
    if (!isWatchedStatus(old['status'])) return calendarDay(localNow);
    final stored = old['completedOn'];
    return stored is String && stored.length == 10 ? stored : null;
  }


  /// Completed calendar months, not approximate days / 30.
  static int completedMonths(DateTime localDate) {
    final wholeMonths = (localDate.year - 2025) * 12 +
        localDate.month - 1 - (localDate.day < 18 ? 1 : 0);
    return wholeMonths < 0 ? 0 : wholeMonths;
  }

  static String relationshipDuration(DateTime localDate) {
    final months = completedMonths(localDate);
    final years = months ~/ 12;
    final remainder = months % 12;
    final yearText = '$years ${years == 1 ? 'ano' : 'anos'}';
    final monthText = '$remainder ${remainder == 1 ? 'mês' : 'meses'}';
    if (years == 0) return monthText;
    if (remainder == 0) return yearText;
    return '$yearText e $monthText';
  }

  /// Personal, authored memories only. A TMDB synopsis and public rating
  /// never qualify. A partner's status cannot complete the other's review.
  static bool isMemoryFilm({
    required DateTime localDate,
    required String kind,
    required Object? mine,
    Object? partner,
  }) {
    if (!isActive(localDate) || kind != 'Filme') return false;
    for (final row in [mine, partner]) {
      if (row is! Map) continue;
      if (isWatchedStatus(row['status']) &&
          row['completedOn'] == calendarDay(localDate) &&
          SaturnReviewClassification.stars(row) != null &&
          SaturnReviewClassification.hasWrittenReview(row)) {
        return true;
      }
    }
    return false;
  }
}

/// A permanent, read-only relationship timeline in the Nós Dois header.
class SaturnRelationshipTime extends StatelessWidget {
  const SaturnRelationshipTime({super.key});

  @override
  Widget build(BuildContext context) {
    final duration = SaturnAnniversary.relationshipDuration(DateTime.now());
    return Semantics(
      label: '$duration juntos. Desde 18 de janeiro de 2025.',
      child: Container(
        key: const Key('saturn-relationship-time'),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xAA9C7DB2)),
          gradient: const LinearGradient(
            colors: [Color(0xFF34264F), Color(0xFF202A49)],
          ),
        ),
        child: Row(children: [
          const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFFF1D6BC), size: 21),
          const SizedBox(width: 11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NOSSO TEMPO JUNTOS', style: TextStyle(
                color: Color(0xFFDCC2EE), fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 3),
              Text('$duration juntos',
                key: const Key('saturn-relationship-duration'),
                maxLines: 2,
                style: const TextStyle(
                  color: Color(0xFFFFF5EC), fontFamily: 'serif',
                  fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              const Text('Desde 18 de janeiro de 2025',
                style: TextStyle(color: Color(0xFFD6C2D9),
                  fontSize: 11, height: 1.3)),
            ],
          )),
        ]),
      ),
    );
  }
}

/// A static glow for posters shown without a metallic rating frame.
class SaturnAnniversaryAura extends StatelessWidget {
  const SaturnAnniversaryAura({
    super.key, required this.active, required this.child,
  });
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return DecoratedBox(
      key: const Key('saturn-anniversary-memory-aura'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFAE80FF), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xB48B4BFF),
            blurRadius: 26, spreadRadius: 3),
          BoxShadow(color: Color(0xBF132B83),
            blurRadius: 38, spreadRadius: 6),
        ],
      ),
      child: child,
    );
  }
}

/// A day-18-only celebration: one smooth cosmic entrance, then a still sky.
/// Finite animation also lets Flutter screens and widget tests settle.
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
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect system accessibility settings and Flutter's offstage tickers.
    final media = MediaQuery.of(context);
    final canAnimate = !media.disableAnimations && !media.reduceMotion &&
        TickerMode.of(context);
    if (canAnimate && !_cosmicMotion.isAnimating &&
        !_cosmicMotion.isCompleted) {
      _cosmicMotion.forward();
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
                const SizedBox(height: 12),
                Text('${SaturnAnniversary.relationshipDuration(DateTime.now())} juntos',
                  key: const Key('saturn-anniversary-elapsed'),
                  maxLines: 2,
                  style: const TextStyle(color: Color(0xFFF4D8B5),
                    fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text('Desde 18 de janeiro de 2025',
                  style: TextStyle(color: Color(0xFFE2CADA), fontSize: 10)),
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
