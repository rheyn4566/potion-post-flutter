import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ads/game_ads.dart';
import '../ads/reward_offer.dart';
import 'garden_art.dart';
import '../game_controller.dart';
import 'game_icon.dart';
import 'woodland.dart';

/// Rewards are committed by the controller before this presentation opens.
class DeliveryCelebration extends StatefulWidget {
  const DeliveryCelebration({
    super.key,
    required this.game,
    required this.ads,
    required this.garden,
    required this.customer,
    required this.orderId,
    required this.earned,
    required this.routeBonus,
    required this.firstDelivery,
    required this.offerBonus,
  });
  final GameController game;
  final GameAds ads;
  final Garden garden;
  final String customer, orderId;
  final int earned, routeBonus;
  final bool firstDelivery, offerBonus;

  @override
  State<DeliveryCelebration> createState() => _DeliveryCelebrationState();
}

class _DeliveryCelebrationState extends State<DeliveryCelebration>
    with SingleTickerProviderStateMixin {
  late final _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || widget.game.reduceMotion) {
      _burst.stop();
      _burst.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _burst.forward();
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final viewport = MediaQuery.sizeOf(context);
    final short = viewport.height < 620;
    final padding = short ? 14.0 : 22.0;
    final unlocked =
        !g.dailyMode &&
        widget.firstDelivery &&
        g.level == widget.garden.lastOrder &&
        g.level + 1 < g.pack.length;
    return PopScope(
      canPop: false,
      child: Dialog(
        key: const ValueKey('delivery-celebration'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: Woodland.cream,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Color(0xFFE1C890), width: 2),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: viewport.height - 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  key: const ValueKey('delivery-details-scroll'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          padding,
                          short ? 12 : 20,
                          padding,
                          16,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF245C53), Color(0xFF123C39)],
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: _DeliveryConfetti(_burst),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  g.dailyMode
                                      ? 'DAILY DELIVERY'
                                      : 'LEVEL ${g.level + 1} COMPLETE',
                                  style: const TextStyle(
                                    color: Color(0xFFE8D49C),
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: short ? 66 : 116,
                                  height: short ? 66 : 116,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFFF4D8),
                                        Color(0xFFE8D298),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFECCF83),
                                      width: 3,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x4488E3BE),
                                        blurRadius: 26,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: LivingAnimal(
                                      kind: widget.customer,
                                      size: short ? 54 : 104,
                                      animate: !g.reduceMotion,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Delivered!',
                                  style: TextStyle(
                                    color: Woodland.cream,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (!short)
                                  const Text(
                                    'A little magic, safely delivered.',
                                    style: TextStyle(
                                      color: Color(0xFFBBDACE),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(padding, 16, padding, 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: short ? 8 : 14,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBC0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE3C384),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.earned > 0) ...[
                                    const GameIcon('coin-leaf', size: 38),
                                    const SizedBox(width: 10),
                                  ],
                                  Flexible(
                                    child: Text(
                                      widget.earned > 0
                                          ? '+${widget.earned} Coins'
                                          : 'Practice complete',
                                      key: const ValueKey(
                                        'delivery-coin-reward',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFF33654F),
                                        fontSize: short ? 24 : 32,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.routeBonus > 0)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'Includes your +40 daily route bonus',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Woodland.muted,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 14),
                            if (!g.dailyMode)
                              GardenProgressCard(
                                key: const ValueKey('delivery-garden-progress'),
                                game: g,
                                garden: widget.garden,
                                compact: short,
                              )
                            else
                              Text(
                                'Daily route · ${g.dailyDelivered}/3 delivered',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (unlocked)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_open_rounded,
                                      color: Color(0xFF287259),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${Garden.forLevel(g.level + 1).name} unlocked!',
                                        style: const TextStyle(
                                          color: Color(0xFF287259),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.offerBonus)
                              RewardOffer(
                                game: g,
                                ads: widget.ads,
                                orderId: widget.orderId,
                              ),
                            ListenableBuilder(
                              listenable: g,
                              builder: (_, _) => g.saveFailed
                                  ? TextButton(
                                      onPressed: g.flush,
                                      child: const Text(
                                        'Saving needs a retry · Retry saving',
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  12,
                  padding,
                  short ? 8 : 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        key: const ValueKey('delivery-next'),
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.play_arrow_rounded, size: 28),
                        label: Text(
                          !g.dailyMode && g.level == g.pack.length - 1
                              ? 'Play daily orders'
                              : 'Next order',
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Home'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A finite, inexpensive burst; no looping confetti or extra image decoding.
class _DeliveryConfetti extends CustomPainter {
  _DeliveryConfetti(this.animation) : super(repaint: animation);
  final Animation<double> animation;
  static const colors = [
    Color(0xFFF6D17C),
    Color(0xFF88DBBB),
    Color(0xFFFFF6D8),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t == 0 || t >= 1) return;
    final paint = Paint();
    for (var i = 0; i < 22; i++) {
      final seed = ((i * 37) % 101) / 100;
      final x = size.width * (.05 + seed * .9) + math.sin(i + t * 6) * 12;
      final y = -20 + t * (size.height + 60) - (i % 5) * 16;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 5 + i);
      paint.color = colors[i % colors.length].withValues(alpha: (1 - t) * .9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -5, 6, 10),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DeliveryConfetti oldDelegate) =>
      oldDelegate.animation != animation;
}
