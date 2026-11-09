import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Arte original em formato Story: o comentário faz parte dos pixels,
/// porque o Instagram pode ignorar a legenda enviada pelo compartilhamento.
Future<Uint8List> buildSaturnStoryPng({
  required String title,
  required String kind,
  required String comment,
  required double stars,
  required String status,
}) async {
  const w = 1080.0;
  const h = 1920.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawRect(
    const Rect.fromLTWH(0, 0, w, h),
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(w, h),
        const [
          Color(0xFF101018),
          Color(0xFF381D31),
          Color(0xFF161421),
        ],
        const [0, 0.53, 1],
      ),
  );
  final orbit = Paint()
    ..color = const Color(0x55C6A477)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5;
  for (final radius in [320.0, 490.0, 680.0]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(910, 390),
        width: radius * 2,
        height: radius * 0.92,
      ),
      orbit,
    );
  }
  canvas.drawCircle(
    const Offset(860, 375),
    125,
    Paint()
      ..shader = ui.Gradient.radial(
        const Offset(830, 325),
        230,
        const [Color(0xFFF0D8A6), Color(0xFF9C6474), Color(0xFF41263B)],
        const [0, 0.6, 1],
      ),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(76, 760, 928, 880),
      const Radius.circular(48),
    ),
    Paint()..color = const Color(0xDB201923),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(76, 760, 928, 880),
      const Radius.circular(48),
    ),
    Paint()
      ..color = const Color(0x77C6A477)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke,
  );

  void write(
    String text,
    double x,
    double y, {
    double fontSize = 44,
    Color color = const Color(0xFFF2E8DF),
    FontWeight weight = FontWeight.w400,
    int maxLines = 4,
    double width = 896,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          height: 1.2,
          fontWeight: weight,
        ),
      ),
      maxLines: maxLines,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    painter.paint(canvas, Offset(x, y));
    painter.dispose();
  }

  write('S A T U R N', 88, 100, fontSize: 40,
      weight: FontWeight.w600, color: const Color(0xFFC6A477));
  write('EVERY STORY HAS ITS ORBIT', 88, 160,
      fontSize: 23, color: const Color(0xFFD9C2C7));

  write(kind.toUpperCase(), 126, 820, fontSize: 27,
      color: const Color(0xFFC6A477), weight: FontWeight.w600);
  write(title, 126, 895, fontSize: 77,
      width: 818, weight: FontWeight.bold, maxLines: 3);
  final bounded = stars.clamp(0.0, 5.0);
  final starLabels = List.generate(
    5, (index) => bounded >= index + 0.5 ? '★' : '☆',
  ).join(' ');
  write(starLabels, 126, 1160,
      fontSize: 80, color: const Color(0xFFC6A477));
  write('${bounded.toStringAsFixed(1)} / 5   •   ${status.toUpperCase()}',
      126, 1270, fontSize: 27, color: const Color(0xFFEADCCF));
  write('MINHA RESENHA', 126, 1358,
      fontSize: 26, color: const Color(0xFFC6A477),
      weight: FontWeight.bold);
  final quote = comment.trim().isEmpty
      ? 'Uma história para guardar na memória.'
      : comment.trim();
  write('“$quote”', 126, 1410, fontSize: 36, width: 790, maxLines: 5);
  write('Meu universo de histórias  •  SATURN', 88, 1770,
      fontSize: 25, color: const Color(0xFFE2D3D8));

  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(w.toInt(), h.toInt());
    try {
      final raw = await image.toByteData(format: ui.ImageByteFormat.png);
      if (raw == null) {
        throw StateError('Não foi possível exportar a imagem.');
      }
      return raw.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

/// Abre o compartilhamento do sistema com uma imagem 1080×1920.
/// O usuário escolhe Instagram/Story quando o aplicativo estiver disponível.
Future<void> shareSaturnReview({
  required BuildContext context,
  required String title,
  required String kind,
  required String comment,
  required double stars,
  required String status,
}) async {
  final picture = await buildSaturnStoryPng(
    title: title,
    kind: kind,
    comment: comment,
    stars: stars,
    status: status,
  );
  final render = context.findRenderObject();
  final origin = render is RenderBox && render.hasSize
      ? render.localToGlobal(Offset.zero) & render.size
      : const Rect.fromLTWH(0, 0, 1, 1);
  await SharePlus.instance.share(ShareParams(
    title: 'Minha avaliação no SATURN',
    text: '$title • ${stars.toStringAsFixed(1)}/5 ⭐\n$comment\n#SATURN',
    files: [XFile.fromData(picture, mimeType: 'image/png')],
    fileNameOverrides: const ['SATURN-minha-avaliacao.png'],
    sharePositionOrigin: origin,
  ));
}
