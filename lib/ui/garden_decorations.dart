import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show setEquals;

/// Optional ornaments use the same illustrated shapes as the bundled gardens.
class GardenDecorations extends StatelessWidget {
  const GardenDecorations({
    super.key,
    required this.decorations,
    this.preview = false,
  });
  final Set<String> decorations;
  final bool preview;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Semantics(
      label: 'Garden decorations: ${decorations.join(', ')}',
      child: CustomPaint(painter: _DecorationPainter(decorations, preview)),
    ),
  );
}

class _DecorationPainter extends CustomPainter {
  _DecorationPainter(this.decorations, this.preview);
  final Set<String> decorations;
  final bool preview;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / (preview ? 240 : 960),
      size.height / (preview ? 240 : 835),
    );
    canvas.save();
    canvas.translate(
      (size.width - (preview ? 240 : 960) * scale) / 2,
      (size.height - (preview ? 240 : 835) * scale) / 2,
    );
    canvas.scale(scale);
    if (decorations.contains('chimes')) {
      canvas.save();
      canvas.translate(preview ? 60 : 155, preview ? 20 : 320);
      _chimes(canvas);
      canvas.restore();
    }
    if (decorations.contains('fountain')) {
      canvas.save();
      canvas.translate(preview ? 30 : 365, preview ? 30 : 565);
      _fountain(canvas);
      canvas.restore();
    }
    if (decorations.contains('fireflies')) {
      canvas.save();
      _fireflies(canvas);
      canvas.restore();
    }
    canvas.restore();
  }

  void _chimes(Canvas c) {
    final rope = Paint()
      ..color = const Color(0xFFD9BC8C)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(60, 0)
        ..lineTo(12, 42)
        ..lineTo(108, 42)
        ..close(),
      rope,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 38, 120, 15),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFF9E6666),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 38, 108, 6),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFE7B09D),
    );
    for (var i = 0; i < 5; i++) {
      final x = 12.0 + i * 24, y = 75.0 + (i.isEven ? 15 : 0);
      c.drawLine(Offset(x, 53), Offset(x, y + 55), rope);
      c.drawCircle(
        Offset(x, y - 7),
        5,
        Paint()..color = const Color(0xFFF0D299),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 5, y, 10, 42),
          const Radius.circular(5),
        ),
        Paint()
          ..color = i.isEven
              ? const Color(0xFFB3DCC4)
              : const Color(0xFFD9B5DF),
      );
      final petal = Path()
        ..moveTo(x, y + 45)
        ..quadraticBezierTo(x - 18, y + 57, x, y + 70)
        ..quadraticBezierTo(x + 18, y + 57, x, y + 45);
      c.drawPath(petal, Paint()..color = const Color(0xFFF2B3CA));
      c.drawLine(Offset(x, y + 50), Offset(x, y + 64), rope..strokeWidth = 1.5);
    }
  }

  void _fountain(Canvas c) {
    final stone = Paint()..color = const Color(0xFF9AB9CD);
    c.drawOval(
      const Rect.fromLTWH(5, 162, 190, 25),
      Paint()..color = const Color(0xFF102F36).withValues(alpha: .3),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(73, 105, 54, 58),
        const Radius.circular(13),
      ),
      stone,
    );
    c.drawOval(
      const Rect.fromLTWH(48, 151, 104, 23),
      Paint()..color = const Color(0xFF789DAF),
    );
    c.drawOval(const Rect.fromLTWH(0, 87, 200, 53), stone);
    c.drawOval(
      const Rect.fromLTWH(4, 80, 192, 45),
      Paint()..color = const Color(0xFFD2E5EB),
    );
    c.drawOval(
      const Rect.fromLTWH(14, 87, 172, 31),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF62B6C4), Color(0xFFB4EDF0)],
        ).createShader(const Rect.fromLTWH(14, 87, 172, 31)),
    );
    final water = Paint()
      ..color = const Color(0xFFB0F1EB)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(99, 94)
        ..quadraticBezierTo(68, 32, 49, 92),
      water,
    );
    c.drawPath(
      Path()
        ..moveTo(103, 94)
        ..quadraticBezierTo(138, 26, 158, 93),
      water,
    );
    c.drawLine(const Offset(100, 37), const Offset(100, 98), water);
    c.drawOval(const Rect.fromLTWH(62, 47, 76, 18), stone);
    c.drawOval(
      const Rect.fromLTWH(65, 43, 70, 17),
      Paint()..color = const Color(0xFFD2E5EB),
    );
    final moon = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(const Rect.fromLTWH(81, 1, 40, 43))
      ..addOval(const Rect.fromLTWH(94, -5, 32, 36));
    c.save();
    c.clipRect(const Rect.fromLTWH(78, 0, 47, 46));
    c.drawPath(moon, Paint()..color = const Color(0xFFFFDE96));
    c.restore();
    for (final p in [
      const Offset(43, 73),
      const Offset(162, 76),
      const Offset(92, 78),
    ]) {
      c.drawOval(
        Rect.fromCenter(center: p, width: 5, height: 10),
        Paint()..color = const Color(0xFFC9FBF0),
      );
    }
  }

  void _fireflies(Canvas c) {
    const points = [
      Offset(235, 220),
      Offset(350, 145),
      Offset(590, 192),
      Offset(730, 285),
      Offset(280, 385),
      Offset(632, 370),
      Offset(480, 278),
      Offset(206, 540),
      Offset(710, 540),
      Offset(350, 600),
      Offset(570, 525),
      Offset(450, 460),
    ];
    final positions = preview
        ? const [Offset(70, 55), Offset(165, 90), Offset(80, 160)]
        : points;
    for (final position in positions) {
      c.save();
      c.translate(position.dx, position.dy);
      if (preview) c.scale(2);
      const p = Offset.zero;
      c.drawCircle(
        p,
        20,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFEEFF9D).withValues(alpha: .45),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: p, radius: 20)),
      );
      c.drawOval(
        Rect.fromCenter(center: p + const Offset(-5, -5), width: 11, height: 6),
        Paint()..color = const Color(0xFFC4F4D6).withValues(alpha: .8),
      );
      c.drawOval(
        Rect.fromCenter(center: p + const Offset(5, -5), width: 11, height: 6),
        Paint()..color = const Color(0xFFC4F4D6).withValues(alpha: .8),
      );
      c.drawOval(
        Rect.fromCenter(center: p, width: 7, height: 10),
        Paint()..color = const Color(0xFFFFE89F),
      );
      c.drawCircle(
        p + const Offset(0, -5),
        2.5,
        Paint()..color = const Color(0xFF638F81),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DecorationPainter old) =>
      old.preview != preview || !setEquals(old.decorations, decorations);
}
