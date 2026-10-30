import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'game_ads.dart';

class ToolRefillOffer extends StatefulWidget {
  const ToolRefillOffer({
    super.key,
    required this.game,
    required this.ads,
    required this.tool,
    required this.offerId,
  });
  final GameController game;
  final GameAds ads;
  final GameTool tool;
  final String offerId;
  @override
  State<ToolRefillOffer> createState() => _ToolRefillOfferState();
}

class _ToolRefillOfferState extends State<ToolRefillOffer> {
  bool _watching = false, _earned = false;
  String? _message;
  String get _reward => widget.tool == GameTool.hint ? '3 hints' : '5 undos';

  Future<void> _watch() async {
    if (_watching || _earned || widget.ads.rewardState != RewardAdState.ready)
      return;
    setState(() {
      _watching = true;
      _message = null;
    });
    final game = widget.game,
        tool = widget.tool,
        id = widget.offerId,
        ads = widget.ads;
    try {
      await game.flush();
      await ads.watch(
        onEarned: () {
          if (game.claimToolRefill(tool, id)) _earned = true;
          if (mounted) setState(() {});
        },
      );
    } finally {
      if (mounted)
        setState(() {
          _watching = false;
          if (!_earned) _message = 'No refill earned. You can keep playing.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.ads,
    builder: (context, _) {
      if (_earned)
        return Text(
          '+$_reward added',
          key: const ValueKey('tool-refill-earned'),
          textAlign: TextAlign.center,
        );
      final ready = widget.ads.rewardState == RewardAdState.ready && !_watching;
      final loading =
          _watching ||
          widget.ads.rewardState == RewardAdState.loading ||
          widget.ads.rewardState == RewardAdState.showing;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Watch one ad to add $_reward.', textAlign: TextAlign.center),
          const SizedBox(height: 10),
          const Text(
            'Restart and normal play stay free. Daily free tools refresh at local midnight.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('watch-tool-refill'),
              onPressed: ready ? _watch : null,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: Text('Watch ad · +$_reward'),
            ),
          ),
          if (loading)
            const Text('Loading ad…', style: TextStyle(fontSize: 11))
          else if (!ready)
            TextButton(
              onPressed: widget.ads.retry,
              child: const Text('Ad unavailable · Retry'),
            ),
          if (_message != null)
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
        ],
      );
    },
  );
}
