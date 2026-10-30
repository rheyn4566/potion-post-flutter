import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'game_ads.dart';

class RewardOffer extends StatefulWidget {
  const RewardOffer({
    super.key,
    required this.game,
    required this.ads,
    required this.orderId,
  });
  final GameController game;
  final GameAds ads;
  final String orderId;
  @override
  State<RewardOffer> createState() => _RewardOfferState();
}

class _RewardOfferState extends State<RewardOffer> {
  bool _watching = false;
  String? _message;

  Future<void> _watch() async {
    if (_watching ||
        widget.ads.rewardState != RewardAdState.ready ||
        !widget.game.canClaimAdBonus(widget.orderId))
      return;
    setState(() {
      _watching = true;
      _message = null;
    });
    final game = widget.game, orderId = widget.orderId;
    try {
      await widget.ads.watch(onEarned: () => game.claimAdBonus(orderId));
    } finally {
      if (mounted)
        setState(() {
          _watching = false;
          if (game.canClaimAdBonus(orderId))
            _message = 'No bonus earned. You can continue.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.game, widget.ads]),
    builder: (context, _) {
      if (widget.game.rewardedBonuses.contains(widget.orderId)) {
        return const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            '+20 bonus coins added',
            key: ValueKey('reward-confirmed'),
            style: TextStyle(fontSize: 12, color: Color(0xFF24745D)),
          ),
        );
      }
      if (!widget.game.canClaimAdBonus(widget.orderId)) {
        return const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Daily coin bonus limit reached. More tomorrow.',
            style: TextStyle(fontSize: 10),
          ),
        );
      }
      final ready = widget.ads.rewardState == RewardAdState.ready && !_watching;
      final loading =
          widget.ads.rewardState == RewardAdState.loading ||
          widget.ads.rewardState == RewardAdState.showing ||
          _watching;
      return Container(
        key: const ValueKey('reward-offer'),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Optional bonus',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.game.coinAdsRemaining}/3 available today',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('watch-rewarded-ad'),
                onPressed: ready ? _watch : null,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 19),
                label: const Text(
                  'Watch ad · +20 coins',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
            if (!ready)
              loading
                  ? const Text('Loading ad…', style: TextStyle(fontSize: 10))
                  : TextButton(
                      onPressed: () async {
                        await widget.ads.retry();
                      },
                      child: const Text(
                        'Ad unavailable · Retry',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
            if (_message != null)
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      );
    },
  );
}
