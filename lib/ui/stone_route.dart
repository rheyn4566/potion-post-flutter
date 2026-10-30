import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A carved, moss-edged stepping stone. The hit target remains the full tile.
class StoneLevel extends StatelessWidget {
  const StoneLevel({
    super.key,
    required this.level,
    required this.current,
    required this.complete,
    required this.locked,
    required this.onTap,
  });
  final int level;
  final bool current, complete, locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Level $level${complete
            ? ', delivered'
            : locked
            ? ', locked'
            : current
            ? ', next order'
            : ''}',
    button: true,
    enabled: !locked,
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('order-choice-${level - 1}'),
        borderRadius: BorderRadius.circular(22),
        onTap: locked ? null : onTap,
        child: CustomPaint(
          key: ValueKey('level-stone-${level - 1}'),
          painter: _LevelStonePainter(current: current, locked: locked),
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: const Alignment(0, -.08),
                  child: Text(
                    '$level',
                    style: TextStyle(
                      color: locked
                          ? const Color(0xFF59605B)
                          : const Color(0xFF28463C),
                      fontSize:
                          (c.maxWidth >= 68 ? 25.0 : 19.0) -
                          (level >= 1000 ? 2 : 0),
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(color: Color(0x99FFFFFF), offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
                if (locked || complete)
                  Positioned(
                    right: c.maxWidth * .04,
                    top: c.maxHeight * .03,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: locked
                            ? const Color(0xFF58695E)
                            : const Color(0xFF347660),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFFE4ECD6),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        locked ? Icons.lock_rounded : Icons.check_rounded,
                        size: c.maxWidth >= 68 ? 14 : 11,
                        color: const Color(0xFFFFF4DC),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Path _stoneFace() => Path()
  ..moveTo(19, 15)
  ..quadraticBezierTo(31, 8, 48, 12)
  ..lineTo(74, 11)
  ..quadraticBezierTo(89, 13, 92, 27)
  ..lineTo(94, 59)
  ..quadraticBezierTo(92, 77, 77, 80)
  ..lineTo(28, 83)
  ..quadraticBezierTo(11, 81, 8, 67)
  ..lineTo(7, 37)
  ..quadraticBezierTo(7, 24, 19, 15)
  ..close();

class _LevelStonePainter extends CustomPainter {
  const _LevelStonePainter({required this.current, required this.locked});
  final bool current, locked;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final face = _stoneFace();
    if (current) {
      canvas.drawPath(
        face,
        Paint()
          ..color = const Color(0xFFCCEFA5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9,
      );
    }
    canvas.drawShadow(
      face.shift(const Offset(0, 7)),
      const Color(0xDD142D22),
      5,
      true,
    );
    canvas.drawPath(
      face.shift(const Offset(0, 8)),
      Paint()
        ..color = locked ? const Color(0xFF657268) : const Color(0xFF857B60),
    );
    canvas.drawPath(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: locked
              ? const [Color(0xFFB9C0AD), Color(0xFF8A9987)]
              : current
              ? const [Color(0xFFE7F7C6), Color(0xFFAFD49A), Color(0xFF7BAE86)]
              : const [Color(0xFFFFF0CA), Color(0xFFDCCBA4), Color(0xFFB4AF8C)],
        ).createShader(const Rect.fromLTWH(5, 10, 90, 76)),
    );
    canvas.drawPath(
      face,
      Paint()
        ..color = const Color(0xFF64775B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(18, 32)
        ..quadraticBezierTo(20, 22, 32, 21)
        ..lineTo(70, 20)
        ..quadraticBezierTo(81, 19, 84, 29),
      Paint()
        ..color = const Color(0x99FFFBE0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final crack = Paint()
      ..color = const Color(0x66776F56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(12, 51)
        ..lineTo(22, 55)
        ..lineTo(19, 64),
      crack,
    );
    canvas.drawPath(
      Path()
        ..moveTo(73, 79)
        ..lineTo(69, 70)
        ..lineTo(76, 66),
      crack,
    );
    // Small mineral flecks and grass at the stone's grounded edge.
    for (var i = 0; i < 7; i++) {
      final p = Offset(
        22 + (i * 19 % 61).toDouble(),
        28 + (i * 13 % 38).toDouble(),
      );
      if ((p.dx - 50).abs() < 19 && (p.dy - 47).abs() < 18) continue;
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 2.4, height: 1.4),
        Paint()..color = const Color(0x6675755B),
      );
    }
    for (final x in [12.0, 19.0, 81.0, 87.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 86)
          ..quadraticBezierTo(x - 8, 81, x - 4, 75)
          ..quadraticBezierTo(x + 2, 77, x, 86),
        Paint()
          ..color = locked ? const Color(0xFF677B53) : const Color(0xFF65954B),
      );
    }
    if (current) {
      canvas.drawPath(
        Path()
          ..moveTo(43, 6)
          ..lineTo(50, 11)
          ..lineTo(57, 6)
          ..close(),
        Paint()..color = const Color(0xFFFFD780),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LevelStonePainter old) =>
      current != old.current || locked != old.locked;
}

/// A winding laid-stone trail, with visible joints, a dirt bed and moss edges.
class StoneTrailPainter extends CustomPainter {
  const StoneTrailPainter(this.points, {required this.width});
  final List<Offset> points;
  final double width;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final dy = b.dy - a.dy, dx = b.dx - a.dx;
      if (dy.abs() < dx.abs() * .4) {
        path.cubicTo(
          a.dx + dx * .35,
          a.dy + width * .3,
          b.dx - dx * .35,
          b.dy - width * .3,
          b.dx,
          b.dy,
        );
      } else {
        path.cubicTo(a.dx, a.dy + dy * .5, b.dx, b.dy - dy * .5, b.dx, b.dy);
      }
    }
    void stroke(Color color, double w, {Offset offset = Offset.zero}) =>
        canvas.drawPath(
          path.shift(offset),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = w
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
    stroke(const Color(0x66182C1D), width + 9, offset: const Offset(0, 3));
    stroke(const Color(0xFF647B4B), width + 5);
    stroke(const Color(0xFF9C926B), width + 1);
    var n = 0;
    for (final metric in path.computeMetrics()) {
      for (double d = 2; d < metric.length; d += width * .55) {
        final t = metric.getTangentForOffset(d);
        if (t == null) continue;
        // Leave the level platforms unobscured; the path runs under them.
        canvas.save();
        canvas.translate(t.position.dx, t.position.dy);
        canvas.rotate(math.atan2(t.vector.dy, t.vector.dx));
        for (var side = 0; side < 2; side++) {
          final x = side == 0 ? -width * .10 : width * .10;
          final y = (side == 0 ? -.25 : .25) * width;
          final stone = Path()
            ..moveTo(x - width * .22, y - width * .20)
            ..lineTo(x + width * .19, y - width * .23)
            ..lineTo(x + width * .24, y + width * .12)
            ..lineTo(x + width * .12, y + width * .22)
            ..lineTo(x - width * .22, y + width * .17)
            ..close();
          canvas.drawPath(
            stone.shift(const Offset(0, 1.3)),
            Paint()..color = const Color(0xFF797A5D),
          );
          canvas.drawPath(
            stone,
            Paint()
              ..color = const [
                Color(0xFFE7DAB8),
                Color(0xFFC8C6A5),
                Color(0xFFF0E6C9),
                Color(0xFFD6D1AC),
              ][n++ % 4],
          );
          canvas.drawLine(
            Offset(x - width * .15, y - width * .14),
            Offset(x + width * .13, y - width * .16),
            Paint()
              ..color = const Color(0x99FFFADE)
              ..strokeWidth = 1,
          );
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(StoneTrailPainter old) =>
      old.width != width ||
      old.points.length != points.length ||
      List.generate(
        points.length,
        (i) => old.points[i] != points[i],
      ).any((v) => v);
}
