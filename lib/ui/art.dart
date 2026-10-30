import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/puzzle.dart';
import 'art_cache.dart';

const liquidColors = [
  Color(0xFF73CDED),
  Color(0xFFF4C86E),
  Color(0xFFEC9DC3),
  Color(0xFF8CD4AB),
  Color(0xFFBBA1EF),
  Color(0xFFF6AE73),
  Color(0xFFF18E94),
  Color(0xFF68C8C0),
  Color(0xFFE8DDAB),
  Color(0xFFB2DC71),
  Color(0xFF99A5EE),
  Color(0xFFDE89D0),
];
const liquidNames = [
  'Moon blue',
  'Sun gold',
  'Bloom pink',
  'Leaf green',
  'Violet wish',
  'Peach glow',
  'Coral charm',
  'Tide teal',
  'Stardust cream',
  'Clover lime',
  'Dusk indigo',
  'Orchid dream',
];
const liquidSymbols = [
  '●',
  '☀',
  '◆',
  '♧',
  '★',
  '□',
  '△',
  '≈',
  '♡',
  '+',
  '☾',
  '✦',
];

class LiquidSymbol extends StatelessWidget {
  const LiquidSymbol({
    super.key,
    required this.type,
    this.size = 12,
    this.color,
  });
  final int type;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _LiquidSymbolPainter(type, color ?? liquidColors[type]),
  );
}

class _LiquidSymbolPainter extends CustomPainter {
  _LiquidSymbolPainter(this.type, this.color);
  final int type;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => drawLiquidSymbol(
    canvas,
    Offset(size.width / 2, size.height / 2),
    size.shortestSide * .42,
    type,
    color,
  );
  @override
  bool shouldRepaint(_LiquidSymbolPainter old) =>
      old.type != type || old.color != color;
}

class BottleArt extends StatelessWidget {
  const BottleArt({
    super.key,
    required this.layers,
    required this.capacity,
    this.topFraction = 1,
    this.size = const Size(90, 210),
  });
  final List<int> layers;
  final int capacity;
  final double topFraction;
  final Size size;
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: size,
    painter: BottlePainter(layers, capacity, topFraction),
  );
}

class BottlePainter extends CustomPainter {
  BottlePainter(this.layers, this.capacity, this.topFraction);
  final List<int> layers;
  final int capacity;
  final double topFraction;

  Path bottlePath(Size s) => Path()
    ..moveTo(s.width * .33, s.height * .08)
    ..lineTo(s.width * .33, s.height * .19)
    ..cubicTo(
      s.width * .32,
      s.height * .24,
      s.width * .15,
      s.height * .23,
      s.width * .15,
      s.height * .33,
    )
    ..lineTo(s.width * .15, s.height * .79)
    ..quadraticBezierTo(
      s.width * .15,
      s.height * .92,
      s.width * .5,
      s.height * .92,
    )
    ..quadraticBezierTo(
      s.width * .85,
      s.height * .92,
      s.width * .85,
      s.height * .79,
    )
    ..lineTo(s.width * .85, s.height * .33)
    ..cubicTo(
      s.width * .85,
      s.height * .23,
      s.width * .68,
      s.height * .24,
      s.width * .67,
      s.height * .19,
    )
    ..lineTo(s.width * .67, s.height * .08)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final glass = bottlePath(size);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .5, h * .95),
        width: w * .75,
        height: h * .04,
      ),
      Paint()
        ..color = const Color(0xFF071016).withValues(alpha: .45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      glass,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .13),
            Colors.white.withValues(alpha: .025),
            Colors.white.withValues(alpha: .12),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.save();
    canvas.clipPath(glass);
    final layerHeight = h * .55 / capacity;
    for (var i = 0; i < layers.length; i++) {
      final fraction = i == layers.length - 1
          ? topFraction.clamp(0.0, 1.0)
          : 1.0;
      if (fraction <= 0) continue;
      final bottom = h * .885 - i * layerHeight;
      final top = bottom - layerHeight * fraction;
      final color = liquidColors[layers[i]];
      final rect = Rect.fromLTRB(w * .14, top, w * .86, bottom + 1);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, .12)!,
              color,
              Color.lerp(color, const Color(0xFF182C3B), .25)!,
            ],
          ).createShader(rect),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * .5, top + 2),
          width: w * .70,
          height: h * .035,
        ),
        Paint()..color = Colors.white.withValues(alpha: .24),
      );
      if (fraction > .7) {
        drawLiquidSymbol(
          canvas,
          Offset(w * .50, (top + bottom) / 2),
          math.min(w * .065, 7),
          layers[i],
          const Color(0xFF263A48).withValues(alpha: .85),
        );
      }
      for (var k = 0; k < 2; k++) {
        canvas.drawCircle(
          Offset(w * (.28 + .35 * k), top + (bottom - top) * (.35 + .35 * k)),
          w * .013,
          Paint()..color = Colors.white.withValues(alpha: .3),
        );
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * .22, h * .28, w * .28, h * .82),
        Radius.circular(w * .03),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .36),
            Colors.white.withValues(alpha: .06),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawLine(
      Offset(w * .79, h * .33),
      Offset(w * .79, h * .76),
      Paint()
        ..color = Colors.white.withValues(alpha: .10)
        ..strokeWidth = w * .025,
    );
    canvas.restore();
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = const Color(0xFFC1D7DD).withValues(alpha: .42),
    );
    final rim = Rect.fromCenter(
      center: Offset(w * .5, h * .079),
      width: w * .40,
      height: h * .027,
    );
    canvas.drawOval(
      rim,
      Paint()..color = const Color(0xFFCCE1E4).withValues(alpha: .65),
    );
    canvas.drawOval(
      rim.deflate(2),
      Paint()..color = const Color(0xFF15272D).withValues(alpha: .72),
    );
    canvas.drawArc(
      Rect.fromLTRB(w * .25, h * .79, w * .77, h * .89),
      0,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: .17),
    );
  }

  @override
  bool shouldRepaint(BottlePainter old) =>
      capacity != old.capacity ||
      topFraction != old.topFraction ||
      !Puzzle.equalBottle(layers, old.layers);
}

void drawLiquidSymbol(
  Canvas c,
  Offset center,
  double radius,
  int type,
  Color color,
) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;
  if (type == 0) {
    c.drawCircle(center, radius * .75, p);
    c.drawCircle(center, radius * .16, Paint()..color = color);
  } else if (type == 1) {
    c.drawCircle(center, radius * .4, p);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      c.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * radius * .67,
        center + Offset(math.cos(a), math.sin(a)) * radius,
        p,
      );
    }
  } else if (type == 2) {
    c.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius * .7, center.dy)
        ..lineTo(center.dx, center.dy + radius)
        ..lineTo(center.dx - radius * .7, center.dy)
        ..close(),
      p,
    );
  } else if (type == 3) {
    c.drawOval(
      Rect.fromCenter(
        center: center + Offset(-radius * .25, -radius * .2),
        width: radius,
        height: radius * 1.4,
      ),
      p,
    );
    c.drawLine(
      center + Offset(-radius * .4, radius),
      center + Offset(radius * .3, -radius),
      p,
    );
  } else if (type == 4) {
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = radius * (i.isEven ? 1 : .45);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    c.drawPath(star..close(), p);
  } else if (type == 5) {
    c.drawRect(
      Rect.fromCenter(
        center: center,
        width: radius * 1.5,
        height: radius * 1.5,
      ),
      p,
    );
  } else if (type == 6) {
    c.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy + radius * .7)
        ..lineTo(center.dx - radius, center.dy + radius * .7)
        ..close(),
      p,
    );
  } else if (type == 8) {
    c.drawPath(
      Path()
        ..moveTo(center.dx, center.dy + radius)
        ..cubicTo(
          center.dx - radius * 2,
          center.dy - radius * .3,
          center.dx - radius * .5,
          center.dy - radius * 1.6,
          center.dx,
          center.dy - radius * .4,
        )
        ..cubicTo(
          center.dx + radius * .5,
          center.dy - radius * 1.6,
          center.dx + radius * 2,
          center.dy - radius * .3,
          center.dx,
          center.dy + radius,
        ),
      p,
    );
  } else if (type == 9) {
    c.drawLine(center + Offset(-radius, 0), center + Offset(radius, 0), p);
    c.drawLine(center + Offset(0, -radius), center + Offset(0, radius), p);
  } else if (type == 10) {
    c.drawPath(
      Path()
        ..moveTo(center.dx + radius * .6, center.dy - radius)
        ..cubicTo(
          center.dx - radius * 1.5,
          center.dy - radius * 1.2,
          center.dx - radius * 1.5,
          center.dy + radius * 1.2,
          center.dx + radius * .6,
          center.dy + radius,
        )
        ..cubicTo(
          center.dx - radius * .3,
          center.dy + radius * .4,
          center.dx - radius * .3,
          center.dy - radius * .4,
          center.dx + radius * .6,
          center.dy - radius,
        ),
      p,
    );
  } else if (type == 11) {
    c.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius * .3, center.dy - radius * .3)
        ..lineTo(center.dx + radius, center.dy)
        ..lineTo(center.dx + radius * .3, center.dy + radius * .3)
        ..lineTo(center.dx, center.dy + radius)
        ..lineTo(center.dx - radius * .3, center.dy + radius * .3)
        ..lineTo(center.dx - radius, center.dy)
        ..lineTo(center.dx - radius * .3, center.dy - radius * .3)
        ..close(),
      p,
    );
  } else {
    for (final y in [-.35, .35]) {
      c.drawPath(
        Path()
          ..moveTo(center.dx - radius, center.dy + radius * y)
          ..cubicTo(
            center.dx - radius * .3,
            center.dy + radius * (y - .65),
            center.dx + radius * .3,
            center.dy + radius * (y + .65),
            center.dx + radius,
            center.dy + radius * y,
          ),
        p,
      );
    }
  }
}

class CustomerArt extends StatelessWidget {
  const CustomerArt({
    super.key,
    required this.kind,
    this.size = 76,
    this.grounded = false,
  });
  final String kind;
  final double size;
  final bool grounded;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$kind courier',
    image: true,
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (grounded)
            Positioned(
              bottom: size * .005,
              width: size * .43,
              height: size * .07,
              child: const CustomPaint(painter: _ContactShadowPainter()),
            ),
          Image.asset(
            'assets/characters/$kind.webp',
            cacheWidth: ArtImages.portraitWidth,
            frameBuilder: revealArtFrame,
            width: size,
            height: size,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    ),
  );
}

class _ContactShadowPainter extends CustomPainter {
  const _ContactShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromLTWH(0, size.height * .32, size.width, size.height * .36),
      Paint()
        ..color = const Color(0x32102824)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(2, size.height * .28),
        ),
    );
  }

  @override
  bool shouldRepaint(_ContactShadowPainter oldDelegate) => false;
}

/// The collection uses a close portrait crop while garden scenes use full bodies.
class CustomerPortrait extends StatelessWidget {
  const CustomerPortrait({
    super.key,
    required this.kind,
    this.size = 64,
    this.selected = false,
  });
  final String kind;
  final double size;
  final bool selected;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? const [Color(0xFFC2F1D6), Color(0xFF83C7A8)]
                : const [Color(0xFFF0DBB8), Color(0xFFBCD7C6)],
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Transform.scale(
            scale: 1.62,
            alignment: Alignment.topCenter,
            child: CustomerArt(kind: kind, size: size),
          ),
        ),
      ),
    ),
  );
}

class StarfieldPainter extends CustomPainter {
  StarfieldPainter(this.accent);
  final Color accent;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = accent.withValues(alpha: .14);
    for (var i = 0; i < 34; i++) {
      final x = ((i * 73 + 29) % 997) / 997 * s.width;
      final y = ((i * 139 + 37) % 991) / 991 * s.height;
      c.drawCircle(Offset(x, y), i % 3 == 0 ? 1.7 : .8, p);
    }
    final moon = Offset(s.width - 45, 45);
    final path = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: moon, radius: 20)),
      Path()..addOval(
        Rect.fromCircle(center: moon + const Offset(9, -6), radius: 18),
      ),
    );
    c.drawPath(path, Paint()..color = accent.withValues(alpha: .15));
  }

  @override
  bool shouldRepaint(StarfieldPainter old) => old.accent != accent;
}
