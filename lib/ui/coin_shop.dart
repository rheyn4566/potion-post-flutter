import 'package:flutter/material.dart';

import '../ads/game_ads.dart';
import '../domain/economy.dart';
import '../game_controller.dart';
import 'art.dart';
import 'woodland.dart';
import 'game_icon.dart';
import 'game_widgets.dart';
import 'garden_art.dart';
import 'garden_world.dart';
import 'garden_decorations.dart';

/// Purchases spend earned game coins and persist through the real game store.
/// Cash products are not offered until Play Billing and fulfillment are ready.
class CoinShop extends StatefulWidget {
  const CoinShop({
    super.key,
    required this.game,
    required this.ads,
    required this.accent,
    required this.surface,
    this.initialTab = 0,
    this.initialGarden,
  });
  final GameController game;
  final GameAds ads;
  final Color accent, surface;
  final int initialTab;
  final String? initialGarden;
  @override
  State<CoinShop> createState() => _CoinShopState();
}

class _CoinShopState extends State<CoinShop> {
  late int _tab = widget.initialTab;
  late String _gardenId = widget.initialGarden ?? g.garden;
  bool _watching = false;
  String? _adMessage;
  GameController get g => widget.game;

  Future<void> _purchase(
    String name,
    int price,
    PurchaseResult Function() buy, {
    String? detail,
    Widget? preview,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (preview != null)
              SizedBox(height: 130, child: Center(child: preview)),
            Text(
              '${detail ?? 'Added permanently to your collection.'}\n\nCost: $price Coins\nYour balance: ${g.coins} Coins',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-coin-purchase'),
            onPressed: g.coins >= price ? () => Navigator.pop(c, true) : null,
            child: Text(
              g.coins >= price
                  ? 'Spend $price coins'
                  : 'Need ${price - g.coins} more coins',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = buy();
    await g.flush();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == PurchaseResult.bought
              ? g.saveFailed
                    ? '$name added. Saving needs a retry.'
                    : '$name added. ${g.coins} coins left.'
              : result == PurchaseResult.insufficientCoins
              ? 'You need more coins. Earn them in Coins.'
              : result == PurchaseResult.owned
              ? 'Already in your collection.'
              : 'Purchase unavailable. Please retry your saved game.',
        ),
      ),
    );
  }

  Future<void> _watchCoins() async {
    if (_watching ||
        g.coinAdsRemaining == 0 ||
        widget.ads.rewardState != RewardAdState.ready)
      return;
    setState(() {
      _watching = true;
      _adMessage = null;
    });
    final game = g, id = game.createCoinOffer();
    var earned = false;
    try {
      await game.flush();
      await widget.ads.watch(
        onEarned: () {
          if (game.claimCoinOffer(id)) {
            earned = true;
            if (mounted)
              setState(() => _adMessage = '+$shopAdCoins coins added');
          }
        },
      );
    } finally {
      if (mounted)
        setState(() {
          _watching = false;
          _adMessage = earned
              ? '+$shopAdCoins coins added'
              : 'No coins earned. You can keep playing.';
        });
    }
  }

  void _activity() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Coin activity'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: g.coinHistory.isEmpty
                ? [const Text('Your first delivery earns 20 coins.')]
                : g.coinHistory
                      .map(
                        (e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            e.label,
                            style: const TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            e.day,
                            style: const TextStyle(fontSize: 10),
                          ),
                          trailing: Text(
                            '${e.amount >= 0 ? '+' : ''}${e.amount}',
                            style: TextStyle(
                              color: e.amount >= 0
                                  ? widget.accent
                                  : const Color(0xFFFFB5AA),
                            ),
                          ),
                        ),
                      )
                      .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([g, widget.ads]),
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GamePanel(
          color: const Color(0xFFF9E8C7),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const GameIcon('stamp', size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR COINS',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF725E43),
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      '${g.coins}',
                      key: const ValueKey('shop-balance'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF523F2B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Coin activity',
                onPressed: _activity,
                icon: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF725E43),
                ),
              ),
            ],
          ),
        ),
        if (g.saveFailed) ...[
          const SizedBox(height: 12),
          const Text(
            'Your latest changes need to be saved. Keep the app open and retry.',
            style: TextStyle(fontSize: 11, color: Color(0xFFFFCA90)),
          ),
          TextButton(onPressed: g.flush, child: const Text('Retry saving')),
        ],
        const SizedBox(height: 14),
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 3 ? 0 : 5),
                child: SizedBox(
                  height: 44,
                  child: BentoButton(
                    key: ValueKey('shop-tab-$i'),
                    color: _tab == i ? widget.accent : widget.surface,
                    radius: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 8,
                    ),
                    onPressed: () => setState(() => _tab = i),
                    child: Center(
                      child: Text(
                        ['Coins', 'Animals', 'Decor', 'Tools'][i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tab == i
                              ? const Color(0xFF20382E)
                              : Woodland.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (_tab == 0) ..._coins(),
        if (_tab == 1) ..._animals(),
        if (_tab == 2) ..._gardens(),
        if (_tab == 3) ..._tools(),
      ],
    ),
  );

  List<Widget> _coins() {
    final ready =
        !_watching &&
        widget.ads.rewardState == RewardAdState.ready &&
        g.coinAdsRemaining > 0;
    final loading =
        _watching ||
        widget.ads.rewardState == RewardAdState.loading ||
        widget.ads.rewardState == RewardAdState.showing;
    return [
      _heading('A little treasure'),
      const Text(
        'Coins buy extra tools, animal companions and garden decorations.',
        style: TextStyle(fontSize: 11, height: 1.5),
      ),
      const SizedBox(height: 14),
      GamePanel(
        color: widget.surface,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const GameIcon('stamp', size: 44),
            const SizedBox(height: 8),
            const Text(
              '20 bonus coins',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Optional coin bonuses · ${g.coinAdsRemaining}/$shopAdsPerDay left today',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('watch-shop-coins'),
                onPressed: ready ? _watchCoins : null,
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Watch ad · +20 coins'),
              ),
            ),
            if (g.coinAdsRemaining == 0)
              const Text(
                'More bonus ads at local midnight.',
                style: TextStyle(fontSize: 10),
              )
            else if (loading)
              const Text('Loading ad…', style: TextStyle(fontSize: 10))
            else if (widget.ads.rewardState == RewardAdState.unavailable)
              TextButton(
                onPressed: widget.ads.retry,
                child: const Text('Ad unavailable · Retry'),
              ),
            if (_adMessage != null)
              Text(
                _adMessage!,
                key: const ValueKey('shop-ad-result'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            const SizedBox(height: 6),
            const Text(
              'Shared with delivery coin bonuses.',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _heading('Earn as you play'),
      const Text(
        'New delivery  +20 coins\nAll 3 daily orders  100 coins total\nFriendship milestones  +15 to +150 coins\nReplays  practice only',
        style: TextStyle(fontSize: 11, height: 1.9),
      ),
    ];
  }

  List<Widget> _animals() => [
    _heading('Your delivery companions'),
    Text(
      '${g.friends.first.name} is your free starter. Invite more companions with coins; they are yours to keep.',
      style: TextStyle(fontSize: 11, height: 1.5),
    ),
    const SizedBox(height: 14),
    _grid(
      g.friends.map((f) {
        final owned = g.ownsCompanion(f.kind), selected = g.courier == f.kind;
        final price = g.priceOfCompanion(f.kind);
        return _item(
          'shop-animal-${f.kind}',
          CustomerArt(kind: f.kind, size: 96),
          f.name,
          selected
              ? 'Your companion'
              : owned
              ? 'In your collection'
              : 'Invite companion',
          selected
              ? 'Selected'
              : owned
              ? 'Use companion'
              : '$price coins',
          selected
              ? null
              : owned
              ? () => g.chooseCourier(f)
              : () => _purchase(
                  f.name,
                  price,
                  () => g.buyCompanion(f.kind),
                  preview: CustomerArt(kind: f.kind, size: 130),
                ),
        );
      }).toList(),
    ),
  ];

  List<Widget> _gardens() {
    final garden = Garden.forId(_gardenId);
    final active = g.decorationsFor(garden.id);
    return [
      _heading('Make it your garden'),
      const Text(
        'Gardens unlock by completing story levels. Coins add optional decorations to each unlocked garden.',
        style: TextStyle(fontSize: 11, height: 1.5),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: const ValueKey('decoration-garden-picker'),
        initialValue: _gardenId,
        isExpanded: true,
        menuMaxHeight: 300,
        decoration: const InputDecoration(
          labelText: 'Garden',
          border: OutlineInputBorder(),
        ),
        items: Garden.all
            .where((item) => g.ownsGardenLook(item.id))
            .map(
              (item) => DropdownMenuItem(
                value: item.id,
                enabled: true,
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: g.isGardenUnlocked(item.id)
                        ? Woodland.ink
                        : Woodland.muted,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (id) {
          if (id != null && g.ownsGardenLook(id))
            setState(() => _gardenId = id);
        },
      ),
      const SizedBox(height: 12),
      GamePanel(
        key: const ValueKey('decoration-garden-preview'),
        color: widget.surface,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GardenWorld(
                  key: const ValueKey('shop-world-preview'),
                  garden: garden,
                  primary: g.courier ?? garden.courier,
                  secondary: (g.courier ?? garden.courier) == 'rabbit'
                      ? 'otter'
                      : 'rabbit',
                  animate: false,
                  growth: g.gardenGrowth(garden.id),
                  decorations: active,
                ),
              ),
            ),
            Text(
              '${g.gardenDelivered(garden.id)}/${garden.count} delivered',
              style: const TextStyle(fontSize: 11),
            ),
            TextButton.icon(
              key: const ValueKey('shop-use-garden'),
              onPressed: g.ownsGardenLook(garden.id) && g.garden != garden.id
                  ? () => g.selectGarden(garden.id)
                  : null,
              icon: Icon(
                g.garden == garden.id
                    ? Icons.check_rounded
                    : Icons.landscape_rounded,
                size: 18,
              ),
              label: Text(
                g.garden == garden.id
                    ? 'Selected on Home'
                    : g.ownsGardenLook(garden.id)
                    ? 'Use on Home'
                    : 'Garden locked',
              ),
            ),
          ],
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Follow my route', style: TextStyle(fontSize: 12)),
        subtitle: const Text(
          'Home follows newly unlocked gardens.',
          style: TextStyle(fontSize: 10),
        ),
        value: g.followRouteGarden,
        onChanged: (v) => v ? g.followGardenRoute() : g.selectGarden(g.garden),
      ),
      const SizedBox(height: 6),
      _grid(
        GardenDecoration.all.map((decoration) {
          final owned = g.ownsDecoration(garden.id, decoration.id);
          final shown = active.contains(decoration.id);
          return _item(
            'shop-decor-${decoration.id}',
            SizedBox(
              width: 100,
              height: 100,
              child: GardenDecorations(
                decorations: {decoration.id},
                preview: true,
              ),
            ),
            decoration.name,
            !g.isGardenUnlocked(garden.id) && !owned
                ? 'Unlock at order ${garden.firstOrder + 1}'
                : owned
                ? (shown ? 'Showing in ${garden.name}' : 'Owned · hidden')
                : decoration.description,
            !g.isGardenUnlocked(garden.id) && !owned
                ? 'Locked'
                : owned
                ? (shown ? 'Hide decoration' : 'Show decoration')
                : '${decoration.price} coins',
            !g.isGardenUnlocked(garden.id) && !owned
                ? null
                : owned
                ? () => g.toggleDecoration(garden.id, decoration.id)
                : () => _purchase(
                    decoration.name,
                    decoration.price,
                    () => g.buyDecoration(garden.id, decoration.id),
                    detail:
                        'Adds ${decoration.name.toLowerCase()} to ${garden.name}. Buy once, then show or hide freely.',
                  ),
          );
        }).toList(),
      ),
    ];
  }

  List<Widget> _tools() => [
    _heading('A helping hand'),
    Text(
      '${g.hintsAvailable} hints · ${g.undosAvailable} undos available',
      style: const TextStyle(fontSize: 12),
    ),
    const SizedBox(height: 6),
    const Text(
      '3 free hints and 5 free undos refresh daily. Extra tools carry over. Restart is always free.',
      style: TextStyle(fontSize: 11, height: 1.5),
    ),
    const SizedBox(height: 14),
    _grid([
      _item(
        'shop-tool-hint',
        const GameIcon('hint', size: 60),
        '3 hints',
        'Find your next pour',
        '$hintPackPrice coins',
        () => _purchase(
          '3 hints',
          hintPackPrice,
          () => g.buyToolRefill(GameTool.hint),
          detail: 'Adds 3 extra hints. They carry over to the next day.',
        ),
      ),
      _item(
        'shop-tool-undo',
        const GameIcon('undo', size: 60),
        '5 undos',
        'Take back a pour',
        '$undoPackPrice coins',
        () => _purchase(
          '5 undos',
          undoPackPrice,
          () => g.buyToolRefill(GameTool.undo),
          detail: 'Adds 5 extra undos. They carry over to the next day.',
        ),
      ),
    ]),
  ];

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    ),
  );

  Widget _grid(List<Widget> children) => LayoutBuilder(
    builder: (context, c) => Wrap(
      spacing: 10,
      runSpacing: 10,
      children: children
          .map((w) => SizedBox(width: (c.maxWidth - 10) / 2, child: w))
          .toList(),
    ),
  );

  Widget _item(
    String key,
    Widget art,
    String title,
    String detail,
    String label,
    VoidCallback? action,
  ) => GamePanel(
    color: widget.surface,
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        SizedBox(height: 100, child: Center(child: art)),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 30,
          child: Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              height: 1.4,
              color: Woodland.muted,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: BentoButton(
            key: ValueKey(key),
            color: Woodland.mint,
            onPressed: action,
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF20382E),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
