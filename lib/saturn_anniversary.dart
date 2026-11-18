import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The SATURN couple's monthly anniversary, by the device's LOCAL calendar.
/// Nothing is stored remotely and the celebration never changes ratings.
class SaturnAnniversary {
  const SaturnAnniversary._();
  static bool isActive(DateTime localDate) => localDate.day == 18;
}

/// Premium, gently luminous cosmos. Static paint means no perpetual ticker,
/// battery drain or inaccessible endless animation on reduced-motion devices.
class SaturnAnniversaryBanner extends StatelessWidget {
  const SaturnAnniversaryBanner({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Nosso aniversário de namoro, dia 18. '
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
          Positioned.fill(child: IgnorePointer(child: CustomPaint(
            painter: _SaturnConstellationPainter(),
          ))),
          Padding(
            padding: EdgeInsets.fromLTRB(20, compact ? 19 : 27, 20,
                compact ? 20 : 29),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFFF2DAA8), size: 15),
                  SizedBox(width: 8),
                  Flexible(child: Text('DIA 18  ·  A NOSSA CONSTELAÇÃO',
                    style: TextStyle(color: Color(0xFFF2DAA8),
                      fontSize: 10, letterSpacing: 1.6,
                      fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 12),
                Text(compact ? 'Feliz dia 18, meu amor.' :
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

class _SaturnConstellationPainter extends CustomPainter {
  const _SaturnConstellationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stars = <Offset>[
      const Offset(.68,.12), const Offset(.78,.31),
      const Offset(.89,.15), const Offset(.93,.55),
      const Offset(.74,.78), const Offset(.82,.92),
      const Offset(.52,.36), const Offset(.63,.93),
      const Offset(.34,.11), const Offset(.12,.83),
    ].map((point) => Offset(point.dx * size.width,
        point.dy * size.height)).toList();
    final path = Path()
      ..moveTo(stars[0].dx, stars[0].dy)
      ..lineTo(stars[1].dx, stars[1].dy)
      ..lineTo(stars[2].dx, stars[2].dy)
      ..moveTo(stars[1].dx, stars[1].dy)
      ..lineTo(stars[3].dx, stars[3].dy)
      ..lineTo(stars[4].dx, stars[4].dy)
      ..lineTo(stars[5].dx, stars[5].dy);
    canvas.drawPath(path, Paint()
      ..color = const Color(0x55E1CFEB)
      ..strokeWidth = 1 ..style = PaintingStyle.stroke);
    for (var i = 0; i < stars.length; i++) {
      canvas.drawCircle(stars[i], i.isEven ? 2.1 : 1.4,
        Paint()..color = const Color(0xC4FFE8CC));
      canvas.drawCircle(stars[i], 5.2,
        Paint()..color = const Color(0x1FFFDFB6));
    }
    // A subtly glowing planetary ring, never a copied external illustration.
    final center = Offset(size.width * .89, size.height * .72);
    final ring = Rect.fromCenter(
      center: center,
      width: math.min(size.width * .27, 126),
      height: math.min(size.height * .24, 58),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.30);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawOval(ring, Paint()
      ..color = const Color(0x88F3D2AD)
      ..strokeWidth = 1.1 ..style = PaintingStyle.stroke);
    canvas.drawCircle(center, math.min(size.height * .13, 22),
      Paint()..color = const Color(0x336B5C92));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SaturnConstellationPainter oldDelegate) => false;
}
