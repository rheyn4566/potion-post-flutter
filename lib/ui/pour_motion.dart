import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Lift, travel to the actual target mouth, pour one layer, and return.
class PourPose {
  const PourPose(this.center, this.angle, this.mouth, this.transfer);
  final Offset center, mouth;
  final double angle, transfer;
  static PourPose at({
    required double progress,
    required Offset origin,
    required Offset destination,
    required double bottleHeight,
    required double boardWidth,
  }) {
    final t = progress.clamp(0.0, 1.0);
    final dx = destination.dx - origin.dx;
    final side = dx.abs() > 1
        ? dx.sign
        : destination.dx <= boardWidth / 2
        ? -1.0
        : 1.0;
    final tilt = side * math.pi * .39;
    final neck = bottleHeight * .42;
    final targetMouth = destination - Offset(0, neck);
    final rotatedNeck = Offset(math.sin(tilt) * neck, -math.cos(tilt) * neck);
    final hover = targetMouth - const Offset(0, 18) - rotatedNeck;
    final selected = origin - const Offset(0, 22),
        lifted = origin - const Offset(0, 36);
    Offset arc(Offset a, Offset b, double amount) {
      final control = Offset(
        (a.dx + b.dx) / 2,
        math.min(a.dy, b.dy) - bottleHeight * .12,
      );
      return a * ((1 - amount) * (1 - amount)) +
          control * (2 * (1 - amount) * amount) +
          b * (amount * amount);
    }

    late final Offset center;
    late final double angle;
    if (t < .16) {
      final ease = Curves.easeOut.transform(t / .16);
      center = Offset.lerp(selected, lifted, ease)!;
      angle = 0;
    } else if (t < .40) {
      final ease = Curves.easeInOutCubic.transform((t - .16) / .24);
      center = arc(lifted, hover, ease);
      angle = tilt * ease;
    } else if (t <= .76) {
      center = hover;
      angle = tilt;
    } else {
      final ease = Curves.easeInOutCubic.transform((t - .76) / .24);
      center = arc(hover, origin, ease);
      angle = tilt * (1 - ease);
    }
    final mouth =
        center + Offset(math.sin(angle) * neck, -math.cos(angle) * neck);
    return PourPose(center, angle, mouth, ((t - .40) / .36).clamp(0.0, 1.0));
  }
}
