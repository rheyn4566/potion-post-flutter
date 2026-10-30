import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/puzzle.dart';
import '../game_controller.dart';
import 'art.dart';
import 'game_icon.dart';
import 'game_widgets.dart';
import 'garden_art.dart';
import 'storybook_skin.dart';
import 'polished_art.dart';
import 'garden_world.dart';
import 'art_cache.dart';
import 'stone_route.dart';
import 'scene_transition.dart';
import 'world_art.dart';

class Woodland {
  static const ink = Color(0xFF173F46);
  static const muted = Color(0xFF62736B);
  static const cream = Color(0xFFFFF5DF);
  static const mint = Color(0xFF93E5C4);
  static const forest = Color(0xFF12353C);
  static const gold = Color(0xFFE4AE55);
}

/// Grounded idle breathing keeps both feet and their contact shadow stationary.
/// Motion stops for accessibility, inactive routes and app lifecycle changes.
class LivingAnimal extends StatefulWidget {
  const LivingAnimal({
    super.key,
    required this.kind,
    this.size = 160,
    this.animate = true,
    this.stroll = false,
    this.phase = 0,
  });
  final String kind;
  final double size, phase;
  final bool animate, stroll;
  @override
  State<LivingAnimal> createState() => _LivingAnimalState();
}

class _LivingAnimalState extends State<LivingAnimal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LivingAnimal old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final active =
        widget.animate &&
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (active && !_motion.isAnimating) {
      _motion.repeat();
    }
    if (!active) {
      _motion.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _motion,
      child: CustomerArt(kind: widget.kind, size: widget.size, grounded: true),
      builder: (context, child) {
        final t = _motion.value * math.pi * 2 + widget.phase;
        final enabled =
            widget.animate && !MediaQuery.disableAnimationsOf(context);
        return Transform.scale(
          scaleY: enabled ? 1 + math.sin(t * 2) * .008 : 1,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
    ),
  );
}

class WoodlandBackdrop extends StatelessWidget {
  const WoodlandBackdrop({
    super.key,
    this.office = false,
    this.dim = 0,
    this.gardenId = 'moonbloom',
    this.routeMap = false,
  });
  final bool office;
  final bool routeMap;
  final String gardenId;
  final double dim;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: gardenLookFilter(office ? 'moonbloom' : gardenId),
          child: Image.asset(
            office
                ? StoryArt.daily
                : routeMap
                ? StoryArt.route
                : 'assets/scenes/woodland.webp',
            cacheWidth: ArtImages.backgroundWidth(context),
            frameBuilder: revealArtFrame,
            key: office ? const ValueKey('daily-office-background') : null,
            fit: BoxFit.cover,
            alignment: office
                ? MediaQuery.orientationOf(context) == Orientation.landscape
                      ? const Alignment(0, -.45)
                      : Alignment.topCenter
                : Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Woodland.forest.withValues(alpha: (routeMap ? .42 : .14) + dim),
                Woodland.forest.withValues(alpha: dim),
                Woodland.forest.withValues(alpha: .88),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class CreamCard extends StatelessWidget {
  const CreamCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.none,
    elevation: 0,
    shadowColor: const Color(0x660B252B),
    child: StoryFrame(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding.add(const EdgeInsets.symmetric(horizontal: 8)),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Woodland.ink),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class GardenProgressCard extends StatelessWidget {
  const GardenProgressCard({
    super.key,
    required this.game,
    required this.garden,
    this.onTap,
    this.compact = false,
  });
  final GameController game;
  final Garden garden;
  final VoidCallback? onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final count = game.gardenDelivered(garden.id);
    return CreamCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 10,
      ),
      child: Row(
        children: [
          GameIcon('garden', size: compact ? 22 : 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${garden.name} · $count/${garden.count} delivered',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: compact ? 4 : 7),
                JourneyTrack(
                  value: count / garden.count,
                  color: Woodland.mint,
                  height: compact ? 6 : 8,
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: Woodland.ink),
        ],
      ),
    );
  }
}

class WoodlandHub extends StatefulWidget {
  const WoodlandHub({
    super.key,
    required this.game,
    required this.tab,
    required this.onTab,
    required this.onPlay,
    required this.onDaily,
    required this.onOrder,
    required this.onShop,
    required this.onSettings,
    required this.onHelp,
  });
  final GameController game;
  final int tab;
  final ValueChanged<int> onTab, onDaily, onOrder;
  final VoidCallback onPlay, onSettings, onHelp;
  final void Function(int tab, String? garden) onShop;
  @override
  State<WoodlandHub> createState() => _WoodlandHubState();
}

class _WoodlandHubState extends State<WoodlandHub> {
  final _worldRoot = GlobalKey();
  final _worldStage = GlobalKey();
  Rect? _worldStageBounds;

  void _measureWorldStage() {
    if (!mounted || (widget.tab != 0 && widget.tab != 2)) return;
    final root = _worldRoot.currentContext?.findRenderObject();
    final stage = _worldStage.currentContext?.findRenderObject();
    if (root is! RenderBox || stage is! RenderBox || !stage.hasSize) return;
    final next = stage.localToGlobal(Offset.zero, ancestor: root) & stage.size;
    if (_worldStageBounds != next) setState(() => _worldStageBounds = next);
  }

  late int _garden = Garden.all.indexWhere((a) => a.id == g.garden);
  late int _ordersGarden = Garden.all.indexWhere(
    (a) => a.id == Garden.forLevel(g.storyResumeLevel).id,
  );
  int _route = 0, _friend = 0, _friendPage = 0;
  GameController get g => widget.game;
  bool get motion => !g.reduceMotion;
  int _warmGeneration = 0;
  Object? _warmedFor;

  String _primaryFor(Garden garden) => g.courier ?? garden.courier;

  List<ImageProvider> _sceneImages(Garden garden, bool isWorld) => [
    ...ArtImages.icons,
    if (isWorld) ...[
      ArtImages.background(context, WorldArt.environment(garden.id)),
      ArtImages.pose(WorldArt.pose(_primaryFor(garden))),
      ArtImages.pose(
        WorldArt.pose(_primaryFor(garden) == 'rabbit' ? 'otter' : 'rabbit'),
      ),
    ] else if (widget.tab == 4) ...[
      ArtImages.background(context, WorldArt.environment(garden.id)),
      ArtImages.thumbnail(StoryArt.plinth),
      ArtImages.portrait(g.friends[_friend].kind),
      for (final friend in g.friends.skip(_friendPage * 6).take(6))
        ArtImages.portrait(friend.kind),
    ] else
      ArtImages.background(
        context,
        widget.tab == 1 ? StoryArt.daily : StoryArt.route,
      ),
    if (widget.tab == 2)
      for (final garden
          in Garden.all
              .skip(math.max(0, math.min(_garden - 1, Garden.all.length - 3)))
              .take(3)) ...[
        ArtImages.thumbnail(WorldArt.environment(garden.id)),
      ],
  ];

  void _sceneReady() {
    _measureWorldStage();
    final signature = (
      widget.tab,
      g.garden,
      g.courier,
      _garden,
      _friend,
      _friendPage,
      ArtImages.backgroundWidth(context),
    );
    if (_warmedFor == signature) return;
    _warmedFor = signature;
    final generation = ++_warmGeneration;
    final garden =
        Garden.all[widget.tab == 2
            ? _garden
            : Garden.all.indexWhere((a) => a.id == g.garden)];
    final next = (Garden.all.indexOf(garden) + 1) % Garden.all.length;
    // Only the usual next destinations and neighboring artwork, never all 43
    // worlds. These providers exactly match the ones used when painting.
    unawaited(
      ArtImages.warm(context, [
        ArtImages.background(context, StoryArt.workbench),
        ArtImages.background(context, StoryArt.daily),
        ArtImages.background(context, StoryArt.route),
        ArtImages.background(context, 'assets/scenes/woodland.webp'),
        for (final customer in g.order.customers)
          ArtImages.portrait(customer.kind),
        ArtImages.thumbnail(StoryArt.plinth),
        for (final friend in g.friends.skip(_friendPage * 6).take(6))
          ArtImages.portrait(friend.kind),
        if (widget.tab == 0 || widget.tab == 2) ...[
          ArtImages.background(
            context,
            WorldArt.environment(Garden.all[next].id),
          ),
          ArtImages.pose(WorldArt.pose(Garden.all[next].courier)),
        ],
        if (widget.tab == 4 && _friend + 1 < g.friends.length)
          ArtImages.portrait(g.friends[_friend + 1].kind),
      ], stillWanted: () => mounted && generation == _warmGeneration),
    );
  }

  @override
  void dispose() {
    _warmGeneration++;
    super.dispose();
  }

  @override
  void didUpdateWidget(WoodlandHub old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab && widget.tab == 2) {
      _garden = Garden.all.indexWhere((a) => a.id == g.garden);
    }
    if (old.tab != widget.tab && widget.tab == 3) {
      _ordersGarden = Garden.all.indexWhere(
        (a) => a.id == Garden.forLevel(g.storyResumeLevel).id,
      );
      _route =
          (g.storyResumeLevel - Garden.all[_ordersGarden].firstOrder) ~/ 10;
    }
  }

  Widget _action(
    String label,
    VoidCallback? action, {
    Key? key,
    IconData? icon,
  }) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      key: key,
      onPressed: action,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _wallet() => CreamCard(
    key: const ValueKey('home-coin-wallet'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onTap: () => widget.onShop(0, null),
    child: Semantics(
      button: true,
      label: '${g.coins} coins. Open coin shop.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameIcon('stamp', size: 22),
          const SizedBox(width: 6),
          Text(
            '${g.coins}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.add_rounded, size: 16, color: Woodland.ink),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureWorldStage());
    final worldGarden = widget.tab == 2
        ? Garden.all[_garden]
        : Garden.forId(g.garden);
    final isWorld = widget.tab == 0 || widget.tab == 2;
    return Scaffold(
      backgroundColor: Woodland.forest,
      body: SceneTransition(
        key: const ValueKey('hub-scene-transition'),
        scene: (
          widget.tab,
          worldGarden.id,
          g.courier,
          _friend,
          _friendPage,
          _ordersGarden,
          _route,
        ),
        images: _sceneImages(worldGarden, isWorld),
        animate: motion,
        onReady: _sceneReady,
        child: Stack(
          key: _worldRoot,
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: isWorld
                  ? GardenWorld(
                      key: const ValueKey('garden-world'),
                      garden: worldGarden,
                      stageBounds: _worldStageBounds,
                      primary: _primaryFor(worldGarden),
                      secondary: _primaryFor(worldGarden) == 'rabbit'
                          ? 'otter'
                          : 'rabbit',
                      animate: motion,
                      decorations: g.decorationsFor(worldGarden.id),
                      growth: g.gardenGrowth(worldGarden.id),
                    )
                  : widget.tab == 4
                  ? WorldGalleryBackdrop(garden: worldGarden)
                  : WoodlandBackdrop(
                      key: ValueKey('home-garden-${g.garden}'),
                      office: widget.tab == 1,
                      routeMap: widget.tab == 3,
                      gardenId: widget.tab == 3
                          ? Garden.all[_ordersGarden].id
                          : g.garden,
                    ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWorld ? 1120 : 860),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 12, 6),
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  [
                                    'Potion Post',
                                    'Daily orders',
                                    'Gardens',
                                    'Orders',
                                    'Friends',
                                  ][widget.tab],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Woodland.cream,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        color: Woodland.forest,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _wallet(),
                              const SizedBox(width: 6),
                              IconButton(
                                tooltip: 'Settings',
                                onPressed: widget.onSettings,
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xB51C4750),
                                  side: const BorderSide(
                                    color: Color(0x887DAFA2),
                                  ),
                                ),
                                icon: const GameIcon('settings', size: 27),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final wide = c.maxWidth > c.maxHeight * 1.35;
                              return switch (widget.tab) {
                                1 => _daily(wide, compact: c.maxHeight < 440),
                                2 => _gardens(wide, compact: c.maxHeight < 420),
                                3 => _orders(wide),
                                4 => _friends(wide),
                                _ => _home(wide),
                              };
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: _navigation(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigation() => StoryNavigationFrame(
    key: const ValueKey('woodland-navigation'),
    children: List.generate(5, (i) {
      const names = ['Home', 'Daily', 'Gardens', 'Orders', 'Friends'];
      const icons = ['home', 'daily', 'garden', 'orders', 'album'];
      final selected = widget.tab == i;
      return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          key: ValueKey('nav-${names[i].toLowerCase()}'),
          onTap: () => widget.onTab(i),
          borderRadius: BorderRadius.circular(21),
          child: AnimatedContainer(
            duration: Duration(milliseconds: motion ? 160 : 0),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: selected
                    ? const [Color(0xFFC1F0D8), Color(0xFF77C9AA)]
                    : const [Color(0xFF24524D), Color(0xFF143C38)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? const Color(0xFFE4F8D8)
                    : const Color(0x446DA59A),
                width: selected ? 1.3 : 1,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x55317A62),
                        offset: Offset(0, 2),
                        blurRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GameIcon(icons[i], size: 25),
                const SizedBox(height: 3),
                Text(
                  names[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Woodland.ink : Woodland.cream,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );

  Widget _split(bool wide, Widget scene, Widget controls) => wide
      ? Row(
          children: [
            Expanded(flex: 3, child: scene),
            const SizedBox(width: 20),
            Flexible(
              flex: 2,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(width: 300, child: controls),
                  ),
                ),
              ),
            ),
          ],
        )
      : Column(
          children: [
            Expanded(child: scene),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.tab == 2 ? 520 : 440,
                ),
                child: controls,
              ),
            ),
          ],
        );

  Widget _home(bool wide) {
    final scene = SizedBox.expand(key: _worldStage);
    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GardenProgressCard(
          key: const ValueKey('home-garden-progress'),
          game: g,
          garden: Garden.forLevel(g.storyResumeLevel),
          onTap: () => widget.onTab(2),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: wide
                    ? 72
                    : MediaQuery.sizeOf(context).shortestSide >= 600
                    ? 88
                    : 76,
                child: FilledButton(
                  key: const ValueKey('play-button'),
                  onPressed: g.dailyMode && g.dailyDelivered < 3
                      ? () => widget.onDaily(g.dailySlot)
                      : widget.onPlay,
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .34),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 38,
                          color: Color(0xFF245C47),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              g.dailyMode && g.dailyDelivered < 3
                                  ? 'CONTINUE DAILY'
                                  : 'PLAY',
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: Color(0xFF38664E),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                g.dailyMode && g.dailyDelivered < 3
                                    ? 'Daily ${g.dailySlot + 1}'
                                    : 'Level ${g.storyResumeLevel + 1}',
                                key: const ValueKey('home-level-label'),
                                style: TextStyle(
                                  fontSize: wide ? 26 : 30,
                                  fontWeight: FontWeight.w600,
                                  color: Woodland.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'How to play',
              onPressed: widget.onHelp,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xEDFAF2DC),
                foregroundColor: Woodland.ink,
                fixedSize: const Size(50, 50),
              ),
              icon: const Icon(Icons.help_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
    return _split(wide, scene, controls);
  }

  Widget _daily(bool wide, {required bool compact}) {
    final orders = dailyOrders(g.pack, g.clock());
    final smallTickets = compact;
    Widget ticket(int index) {
      final order = orders[index];
      final name = order.customers.first.name;
      final completed = g.isCompleted(order.id);
      return CreamCard(
        key: ValueKey('daily-order-$index'),
        padding: EdgeInsets.all(smallTickets ? 6 : 9),
        onTap: () => widget.onDaily(index),
        child: smallTickets
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomerPortrait(kind: order.customers.first.kind, size: 40),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        completed
                            ? Icons.check_circle_rounded
                            : Icons.play_arrow_rounded,
                        size: 15,
                        color: const Color(0xFF29705D),
                      ),
                      Text(
                        completed ? 'Replay' : 'Play',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF29705D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  CustomerPortrait(kind: order.customers.first.kind, size: 47),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          Garden.forId(order.garden).name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Woodland.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      onPressed: () => widget.onDaily(index),
                      child: Text(
                        completed ? 'Replay' : 'Play',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
      );
    }

    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        CreamCard(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: smallTickets ? 7 : 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${g.dailyDelivered}/3 delivered · ${g.streak} day streak',
                      style: TextStyle(
                        fontSize: smallTickets ? 10 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    JourneyTrack(
                      value: g.dailyDelivered / 3,
                      color: Woodland.mint,
                      height: 7,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GameIcon('daily', size: smallTickets ? 23 : 29),
              const SizedBox(width: 5),
              const Text(
                '+40\nbonus Coins',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (smallTickets)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < orders.length; index++) ...[
                if (index > 0) const SizedBox(width: 7),
                Expanded(child: ticket(index)),
              ],
            ],
          )
        else
          for (var index = 0; index < orders.length; index++) ...[
            ticket(index),
            const SizedBox(height: 8),
          ],
        if (g.dailyBonusAvailable) ...[
          const SizedBox(height: 6),
          _action('Collect 40 Coins', g.claimDailyBonus),
        ],
        if (!wide) ...[
          const SizedBox(height: 5),
          const Text(
            'New deliveries at local midnight',
            style: TextStyle(color: Woodland.cream, fontSize: 10),
          ),
        ],
      ],
    );
    // The otter and office are composed into the single full-screen backdrop.
    return _split(
      wide,
      const SizedBox.expand(key: ValueKey('daily-scene-space')),
      controls,
    );
  }

  Future<void> _browseGardens() async {
    final pageSize =
        MediaQuery.sizeOf(context).height < 500 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.25
        ? 3
        : 6;
    var page = _garden ~/ pageSize;
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Garden collection'),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          titlePadding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
          contentPadding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var row = 0; row < pageSize ~/ 3; row++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        for (var column = 0; column < 3; column++)
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final index =
                                    page * pageSize + row * 3 + column;
                                if (index >= Garden.all.length)
                                  return const SizedBox(height: 88);
                                final garden = Garden.all[index];
                                return InkWell(
                                  key: ValueKey('collection-garden-$index'),
                                  onTap: () =>
                                      Navigator.pop(dialogContext, index),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 64,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              GardenArt(
                                                garden: garden,
                                                growth: 3,
                                              ),
                                              if (!g.isGardenUnlocked(
                                                garden.id,
                                              ))
                                                const Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: Icon(
                                                    Icons.lock_rounded,
                                                    color: Woodland.ink,
                                                    size: 15,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          garden.name,
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Woodland.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Previous garden page',
                      onPressed: page > 0 ? () => update(() => page--) : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      '${page + 1} / ${(Garden.all.length / pageSize).ceil()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    IconButton(
                      tooltip: 'Next garden page',
                      onPressed: (page + 1) * pageSize < Garden.all.length
                          ? () => update(() => page++)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _garden = selected);
  }

  Widget _gardens(bool wide, {required bool compact}) {
    final garden = Garden.all[_garden];
    final unlocked = g.isGardenUnlocked(garden.id);
    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GardenProgressCard(game: g, garden: garden, compact: compact),
        const SizedBox(height: 8),
        SizedBox(
          height: compact ? 54 : 86,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous garden',
                onPressed: _garden > 0 ? () => setState(() => _garden--) : null,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Woodland.cream,
                ),
              ),
              for (
                var i = math.max(
                  0,
                  math.min(_garden - 1, Garden.all.length - 3),
                );
                i <
                    math.min(
                      Garden.all.length,
                      math.max(
                            0,
                            math.min(_garden - 1, Garden.all.length - 3),
                          ) +
                          3,
                    );
                i++
              )
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      key: ValueKey('garden-$i'),
                      onTap: () => setState(() => _garden = i),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _garden == i
                              ? const Color(0xFF357B76)
                              : const Color(0xD41A4148),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _garden == i
                                ? Woodland.mint
                                : const Color(0x336EABA5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  GardenArt(garden: Garden.all[i], growth: 3),
                                  if (!g.isGardenUnlocked(Garden.all[i].id))
                                    const Icon(
                                      Icons.lock_rounded,
                                      size: 22,
                                      color: Woodland.cream,
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              Garden.all[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Woodland.cream,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Next garden',
                onPressed: _garden < Garden.all.length - 1
                    ? () => setState(() => _garden++)
                    : null,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Woodland.cream,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _action(
                unlocked
                    ? 'Decorate'
                    : 'Unlock at order ${garden.firstOrder + 1}',
                unlocked ? () => widget.onShop(2, garden.id) : null,
                key: const ValueKey('decorate-garden'),
                icon: unlocked ? Icons.brush_rounded : Icons.lock_rounded,
              ),
            ),
            if (g.ownsGardenLook(garden.id)) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  key: const ValueKey('use-garden'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Woodland.cream,
                    side: const BorderSide(color: Woodland.mint),
                  ),
                  onPressed: () => g.selectGarden(garden.id),
                  child: Text(
                    g.garden == garden.id ? 'Selected' : 'Use look',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          Text(
            [
              'Deliver orders to grow this garden',
              'Flowers are blooming',
              'The lanterns are glowing',
              'Your garden is in full bloom',
            ][g.gardenGrowth(garden.id)],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Woodland.cream),
          ),
        ],
      ],
    );
    return _split(
      wide,
      Stack(
        fit: StackFit.expand,
        children: [
          SizedBox.expand(key: _worldStage),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                key: const ValueKey('browse-gardens'),
                onPressed: _browseGardens,
                style: TextButton.styleFrom(
                  foregroundColor: Woodland.cream,
                  backgroundColor: const Color(0xC51B4945),
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: Text(
                  'All gardens · ${_garden + 1}/${Garden.all.length}',
                ),
              ),
            ),
          ),
        ],
      ),
      controls,
    );
  }

  Widget _orders(bool wide) {
    final garden = Garden.all[_ordersGarden];
    final maxRoute = (garden.count - 1) ~/ 10;
    if (_route > maxRoute) _route = maxRoute;
    final scene = Column(
      children: [
        GardenProgressCard(game: g, garden: garden),
        const SizedBox(height: 8),
        Expanded(
          child: RoutePath(
            game: g,
            garden: garden,
            route: _route,
            animate: motion,
            onOrder: widget.onOrder,
          ),
        ),
      ],
    );
    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (garden.count > 10)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous route',
                onPressed: _route > 0 ? () => setState(() => _route--) : null,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Woodland.cream,
                ),
              ),
              Text(
                'Route ${_route + 1}/${maxRoute + 1}',
                style: const TextStyle(color: Woodland.cream, fontSize: 12),
              ),
              IconButton(
                tooltip: 'Next route',
                onPressed: _route < maxRoute
                    ? () => setState(() => _route++)
                    : null,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Woodland.cream,
                ),
              ),
            ],
          ),
        _action('Play · Order ${g.storyResumeLevel + 1}', widget.onPlay),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _ordersGarden > 0
                  ? () => setState(() {
                      _ordersGarden--;
                      _route = 0;
                    })
                  : null,
              child: const Text(
                'Previous garden',
                style: TextStyle(fontSize: 10, color: Woodland.cream),
              ),
            ),
            TextButton(
              onPressed: _ordersGarden < Garden.all.length - 1
                  ? () => setState(() {
                      _ordersGarden++;
                      _route = 0;
                    })
                  : null,
              child: const Text(
                'Next garden',
                style: TextStyle(fontSize: 10, color: Woodland.cream),
              ),
            ),
          ],
        ),
      ],
    );
    return _split(wide, scene, controls);
  }

  Widget _friends(bool wide) {
    final friend = g.friends[_friend];
    final owned = g.ownsCompanion(friend.kind),
        leading = g.courier == friend.kind;
    final tier = g.friendTier(friend.id);
    final scene = Column(
      children: [
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                alignment: Alignment.center,
                children: [
                  CompanionStage(
                    child: LivingAnimal(
                      key: ValueKey('friend-preview-${friend.kind}'),
                      kind: friend.kind,
                      size: math.min(c.maxWidth * .78, c.maxHeight * .94),
                      animate: motion,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Previous companion',
                      onPressed: _friend > 0
                          ? () => setState(() {
                              _friend--;
                              _friendPage = _friend ~/ 6;
                            })
                          : null,
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Woodland.cream,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Next companion',
                      onPressed: _friend < g.friends.length - 1
                          ? () => setState(() {
                              _friend++;
                              _friendPage = _friend ~/ 6;
                            })
                          : null,
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Woodland.cream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(
          friend.name,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: Woodland.cream,
          ),
        ),
        Text(
          '${g.friendCount(friend.id)} deliveries together',
          style: const TextStyle(fontSize: 11, color: Woodland.cream),
        ),
        const SizedBox(height: 8),
      ],
    );
    final start = _friendPage * 6;
    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _action(
          tier >= 0
              ? 'Collect friendship reward'
              : leading
              ? 'In your garden'
              : owned
              ? 'Choose companion'
              : 'Invite · ${g.priceOfCompanion(friend.kind)} Coins',
          () {
            if (tier >= 0) {
              g.collectFriend(friend.id);
            } else if (owned) {
              g.chooseCourier(friend);
            } else {
              _invite(friend);
            }
          },
          key: const ValueKey('friend-action'),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final tileH = wide
                ? 68.0
                : MediaQuery.sizeOf(context).height < 660
                ? 65.0
                : 79.0;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (
                  var i = start;
                  i < math.min(start + 6, g.friends.length);
                  i++
                )
                  SizedBox(
                    width: (c.maxWidth - 16) / 3,
                    height: tileH,
                    child: CreamCard(
                      key: ValueKey('friend-${g.friends[i].kind}'),
                      padding: const EdgeInsets.all(4),
                      onTap: () => setState(() => _friend = i),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Column(
                              children: [
                                Expanded(
                                  child: CustomerPortrait(
                                    kind: g.friends[i].kind,
                                    size: 65,
                                    selected: _friend == i,
                                  ),
                                ),
                                Text(
                                  g.friends[i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!g.ownsCompanion(g.friends[i].kind))
                            const Align(
                              alignment: Alignment.topRight,
                              child: Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: Woodland.muted,
                              ),
                            ),
                          if (_friend == i)
                            const Align(
                              alignment: Alignment.topLeft,
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 17,
                                color: Color(0xFF268773),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous friends',
              onPressed: _friendPage > 0
                  ? () => setState(() => _friendPage--)
                  : null,
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: Woodland.cream,
              ),
            ),
            Text(
              '${_friendPage + 1} / ${(g.friends.length / 6).ceil()}',
              style: const TextStyle(color: Woodland.cream, fontSize: 11),
            ),
            IconButton(
              tooltip: 'Next friends',
              onPressed: start + 6 < g.friends.length
                  ? () => setState(() => _friendPage++)
                  : null,
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: Woodland.cream,
              ),
            ),
          ],
        ),
      ],
    );
    return _split(wide, scene, controls);
  }

  Future<void> _invite(Customer friend) async {
    final price = g.priceOfCompanion(friend.kind);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Invite ${friend.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomerArt(kind: friend.kind, size: 140),
            const SizedBox(height: 8),
            Text(
              '$price Coins · Balance ${g.coins}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: g.coins >= price ? () => Navigator.pop(c, true) : null,
            child: Text(
              g.coins >= price
                  ? 'Invite · $price Coins'
                  : 'Need ${price - g.coins} more Coins',
            ),
          ),
        ],
      ),
    );
    if (yes == true) {
      g.buyCompanion(friend.kind);
      await g.flush();
    }
  }
}

class RoutePath extends StatelessWidget {
  const RoutePath({
    super.key,
    required this.game,
    required this.garden,
    required this.route,
    required this.onOrder,
    this.animate = true,
  });
  final GameController game;
  final Garden garden;
  final int route;
  final ValueChanged<int> onOrder;
  final bool animate;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final short = c.maxHeight < 240;
      final h = c.maxHeight / (short ? 2 : 5);
      final diameter = math
          .min(88.0, math.min(h * .9, c.maxWidth / (short ? 5 : 2) * .82))
          .clamp(48.0, 88.0);
      const xs = [.28, .70, .70, .30, .28, .70, .72, .30, .28, .70];
      final start = garden.firstOrder + route * 10;
      final count = math.max(
        0,
        math.min(10, math.min(garden.lastOrder + 1, game.pack.length) - start),
      );
      final positions = List.generate(
        count,
        (i) => Offset(
          c.maxWidth *
              (short ? (i ~/ 5 == 0 ? i % 5 + .5 : 4.5 - i % 5) / 5 : xs[i]),
          h * ((short ? i ~/ 5 : i ~/ 2) + .5),
        ),
      );
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('orders-stone-trail'),
                painter: StoneTrailPainter(
                  positions,
                  width: (diameter * .3).clamp(14, 25).toDouble(),
                ),
              ),
            ),
          ),
          if (c.maxHeight > 220)
            Positioned(
              right: 0,
              bottom: h * 1.7,
              child: IgnorePointer(
                child: LivingAnimal(
                  key: const ValueKey('orders-selected-companion'),
                  kind: game.courier ?? garden.courier,
                  size: math.min(100, c.maxWidth * .23),
                  animate: animate,
                ),
              ),
            ),
          for (var i = 0; i < count; i++)
            Positioned(
              left: positions[i].dx - diameter / 2,
              top: positions[i].dy - diameter / 2,
              width: diameter,
              height: diameter,
              child: StoneLevel(
                level: start + i + 1,
                locked: start + i > game.unlocked,
                complete: game.isCompleted(game.pack[start + i].id),
                current: start + i == game.storyResumeLevel,
                onTap: () => onOrder(start + i),
              ),
            ),
        ],
      );
    },
  );
}
