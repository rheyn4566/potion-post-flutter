import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/progress_store.dart';
import 'domain/puzzle.dart';
import 'game_controller.dart';
import 'domain/catalog.dart';
import 'domain/economy.dart';
import 'ui/coin_shop.dart';
import 'ui/recipe_meter.dart';
import 'ui/art.dart';
import 'ui/potion_board.dart';
import 'ui/woodland.dart';
import 'ui/garden_art.dart';
import 'ui/game_icon.dart';
import 'ui/game_widgets.dart';
import 'ui/storybook_skin.dart';
import 'ui/art_cache.dart';
import 'ui/polished_art.dart';
import 'ui/scene_transition.dart';
import 'ui/delivery_celebration.dart';
import 'ui/settings_dialog.dart';
import 'ads/game_ads.dart';
import 'ads/admob_test_ads.dart';
import 'ads/tool_refill_offer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final raw =
      jsonDecode(await rootBundle.loadString('assets/orders.json')) as List;
  final game = GameController(
    raw
        .map((o) => PotionOrder.fromJson(Map<String, dynamic>.from(o as Map)))
        .toList(),
    LocalProgressStore(),
  );
  await game.initialize();
  final ads = AdMobTestAds();
  runApp(PotionPostApp(game: game, ads: ads));
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => unawaited(ads.initialize()),
  );
}

class Palette {
  Palette._(this.accent, this.background, this.surface);
  factory Palette.forGarden(String id) {
    final garden = Garden.forId(id);
    final base = Palette(gardenThemes[id] ?? 'moonlight');
    final accent = garden.firstOrder < 80 ? base.accent : garden.tint;
    return Palette._(
      accent,
      Color.alphaBlend(accent.withValues(alpha: .035), base.background),
      Color.alphaBlend(accent.withValues(alpha: .045), base.surface),
    );
  }
  Palette(String theme)
    : accent = _themes[theme]?[2] ?? _themes['moonlight']![2],
      background = _themes[theme]?[0] ?? _themes['moonlight']![0],
      surface = Woodland.cream;
  final Color accent, background, surface;
  static const _themes = <String, List<Color>>{
    'moonlight': [Color(0xFF192C36), Color(0xFF2A4149), Color(0xFF9CE2C4)],
    'ember': [Color(0xFF30222B), Color(0xFF45313B), Color(0xFFFFC986)],
    'botanical': [Color(0xFF152F2C), Color(0xFF234039), Color(0xFFBFEBA2)],
    'lavender': [Color(0xFF2A2542), Color(0xFF3C355A), Color(0xFFCFC0FF)],
    'coral': [Color(0xFF342B35), Color(0xFF493D46), Color(0xFFFFB5AA)],
    'frost': [Color(0xFF223342), Color(0xFF314B5E), Color(0xFFB8E8F3)],
    'amber': [Color(0xFF332D26), Color(0xFF4B4135), Color(0xFFF5D18D)],
    'rose': [Color(0xFF352735), Color(0xFF4B3949), Color(0xFFF5B5C9)],
    'lagoon': [Color(0xFF16343E), Color(0xFF28505A), Color(0xFFA0E1EA)],
    'orchid': [Color(0xFF302844), Color(0xFF463957), Color(0xFFE5B6E9)],
    'celestial': [Color(0xFF202C49), Color(0xFF344362), Color(0xFFB4C9FF)],
    'wishing': [Color(0xFF29392F), Color(0xFF405044), Color(0xFFFFE2A3)],
  };
  static const ink = Woodland.ink, muted = Woodland.muted, gold = Woodland.gold;
}

class PotionPostApp extends StatelessWidget {
  const PotionPostApp({super.key, required this.game, this.ads});
  final GameController game;
  final GameAds? ads;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([game, if (ads != null) ads!]),
    builder: (context, _) {
      final p = Palette.forGarden(game.garden);
      return MaterialApp(
        title: 'Potion Post',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                game.reduceMotion || MediaQuery.disableAnimationsOf(context),
          ),
          child: ColoredBox(
            color: p.background,
            child: Column(
              key: const ValueKey('persistent-app-shell'),
              children: [
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: ads?.bannerVisible == true,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
                if (ads?.enabled == true)
                  Material(
                    color: p.background,
                    child: SafeArea(
                      top: false,
                      bottom: ads!.bannerVisible,
                      child: ads!.banner(active: true),
                    ),
                  ),
              ],
            ),
          ),
        ),
        theme: ThemeData(
          dialogTheme: const DialogThemeData(
            backgroundColor: Woodland.cream,
            titleTextStyle: TextStyle(
              color: Woodland.ink,
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            contentTextStyle: TextStyle(
              color: Woodland.ink,
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Woodland.cream,
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Woodland.ink,
              side: const BorderSide(color: Woodland.ink),
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          brightness: Brightness.light,
          useMaterial3: true,
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: p.background,
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF246F61),
            onPrimary: const Color(0xFF20382E),
            surface: p.surface,
            onSurface: Palette.ink,
            secondary: const Color(0xFF287B6E),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style:
                FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Woodland.ink,
                  minimumSize: const Size(48, 52),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ).copyWith(
                  backgroundBuilder: storyButtonBackground,
                  shadowColor: const WidgetStatePropertyAll(Color(0x55356A58)),
                  elevation: const WidgetStatePropertyAll(0),
                ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: p.surface,
            contentTextStyle: const TextStyle(
              color: Woodland.ink,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        home: GameScreen(
          game: game,
          palette: p,
          ads: ads ?? NoGameAds.instance,
        ),
      );
    },
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.game,
    required this.palette,
    required this.ads,
  });
  final GameController game;
  final Palette palette;
  final GameAds ads;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  bool _busy = false, _findingHint = false;
  bool _home = true;
  int _hubTab = 0;
  bool _deliveryShowing = false, _deliveryScheduled = false;
  String? _feedback;
  Timer? _feedbackTimer;
  Timer? _clock;
  GameController get g => widget.game;
  Palette get p => _home ? widget.palette : Palette.forGarden(g.order.garden);
  GameAds get ads => widget.ads;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    g.addListener(_checkDelivery);
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_busy) g.refreshDate();
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _feedbackTimer?.cancel();
    g.removeListener(_checkDelivery);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) g.refreshDate();
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      g.persist();
      unawaited(g.flush());
    }
  }

  void _message(String? value) {
    _feedbackTimer?.cancel();
    setState(() => _feedback = value);
    if (value != null)
      _feedbackTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _feedback = null);
      });
  }

  String get _prompt {
    if (_findingHint) return 'Finding a route…';
    if (_feedback != null) return _feedback!;
    if (g.submitted || g.ready || _busy) return '';
    final cue = g.cue;
    if (cue != null)
      return g.selected == cue.from
          ? 'Now tap the glowing destination.'
          : 'Tap the glowing bottle.';
    return '';
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _home,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_busy) _goHome();
    },
    child: g.loadFailed
        ? _recoveryScreen()
        : SceneTransition(
            key: const ValueKey('game-scene-transition'),
            scene: _home ? 'hub' : 'play-${g.order.id}',
            images: _home
                ? const []
                : [
                    ArtImages.background(context, StoryArt.workbench),
                    for (final customer in g.order.customers)
                      ArtImages.portrait(customer.kind),
                  ],
            animate: !g.reduceMotion,
            child: _home ? _homeScreen() : _gameScreen(),
          ),
  );

  Widget _recoveryScreen() => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GameIcon('mail', size: 64),
              const SizedBox(height: 16),
              const Text(
                'Let’s recover your saved game',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your save could not be opened. It has been kept so it can be retried or restored.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: g.retryLoad,
                child: const Text('Retry saved game'),
              ),
              TextButton(
                onPressed: _settings,
                child: const Text('Settings & restore progress'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _checkDelivery() {
    if (!mounted ||
        _home ||
        _busy ||
        _deliveryShowing ||
        _deliveryScheduled ||
        !g.ready ||
        g.submitted)
      return;
    _deliveryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deliveryScheduled = false;
      if (mounted &&
          !_home &&
          !_busy &&
          !_deliveryShowing &&
          g.ready &&
          !g.submitted)
        unawaited(_deliver());
    });
  }

  bool get _compactLandscape =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  Widget _gameScreen() => Scaffold(
    backgroundColor: p.background,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          key: const ValueKey('gameplay-full-bleed-backdrop'),
          child: GardenBackdrop(
            garden: Garden.forId(g.order.garden),
            accent: p.accent,
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        CreamCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          child: _gameHeader(),
                        ),
                        SizedBox(
                          height: _compactLandscape ? 16 : 20,
                          child: Center(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _prompt,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Woodland.cream,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_compactLandscape)
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height < 620
                                ? 64
                                : 78,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 340,
                                ),
                                child: CreamCard(
                                  key: const ValueKey('game-courier-panel'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomerPortrait(
                                        kind: g.order.customers.first.kind,
                                        size: 43,
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          g.ready
                                              ? 'Just right!'
                                              : 'A potion for ${g.order.customers.first.name}',
                                          maxLines: 2,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: PotionBoard(
                            key: ValueKey(g.order.id),
                            game: g,
                            accent: p.accent,
                            onMessage: _message,
                            onBusyChanged: (value) {
                              if (mounted) setState(() => _busy = value);
                              if (!value) _checkDelivery();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _puzzleTool(
                                  'undo',
                                  'Undo',
                                  _busy || g.history.isEmpty || g.submitted
                                      ? null
                                      : _undo,
                                  remaining: g.undosAvailable,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _puzzleTool(
                                  'reset',
                                  'Restart',
                                  _busy ? null : _restart,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _puzzleTool(
                                  'hint',
                                  'Hint',
                                  _busy || g.ready || g.submitted
                                      ? null
                                      : _hint,
                                  featured: true,
                                  remaining: g.hintsAvailable,
                                ),
                              ),
                            ],
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
      ],
    ),
  );

  Widget _gameHeader() {
    final title = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            g.dailyMode ? 'Daily ${g.dailySlot + 1}' : 'Level ${g.level + 1}',
            key: const ValueKey('game-level-label'),
            maxLines: 1,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
          ),
        ),
        if (!_compactLandscape)
          Text(
            Garden.forId(g.order.garden).name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Woodland.muted),
          ),
        if (_compactLandscape) _recipeMeter(),
      ],
    );
    final controls = SizedBox(
      height: _compactLandscape ? 58 : 66,
      child: Row(
        children: [
          _roundIcon(Icons.arrow_back_rounded, 'Home', _busy ? null : _goHome),
          const SizedBox(width: 8),
          Expanded(child: title),
          const SizedBox(width: 8),
          _currencyPlate(compact: true),
          const SizedBox(width: 8),
          _roundIcon(Icons.pause_rounded, 'Menu', _busy ? null : _menu),
        ],
      ),
    );
    if (_compactLandscape) return controls;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        controls,
        SizedBox(height: 28, child: _recipeMeter()),
      ],
    );
  }

  Widget _recipeMeter() => RecipeMeter(
    key: const ValueKey('recipe-meter'),
    matched: g.matchedLayers,
    total: g.recipeLayers,
    moves: g.moves,
    color: p.accent,
    onTap: _scoring,
  );

  void _scoring() {
    if (_busy || _deliveryShowing) return;
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Your recipe progress'),
        content: Text(
          '${g.matchedLayers}/${g.recipeLayers} layers match, from the bottom up. '
          'The bar fills as you build the requested potions and can go down when you move a correct layer.\n\n'
          'Finish in as many pours as you need. Each new story delivery grows its garden and earns 20 coins.\n\n'
          'Complete all three daily orders for 100 coins total. Replays are for practice; completion rewards are collected once.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _puzzleTool(
    String icon,
    String label,
    VoidCallback? action, {
    bool featured = false,
    int? remaining,
  }) => SizedBox(
    height: _compactLandscape ? 54 : 62,
    child: BentoButton(
      key: ValueKey('tool-$icon'),
      label: remaining == null
          ? label
          : '$label. $remaining available. Optional ad refill.',
      color: featured ? const Color(0xFFE8CA90) : p.surface,
      onPressed: action,
      animate: !g.reduceMotion,
      padding: EdgeInsets.symmetric(
        horizontal: 4,
        vertical: _compactLandscape ? 4 : 7,
      ),
      radius: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GameIcon(icon, size: _compactLandscape ? 22 : 25),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: featured ? const Color(0xFF523F2B) : Palette.ink,
                ),
              ),
              if (remaining != null) ...[
                const SizedBox(width: 5),
                if (remaining == 0)
                  const Icon(Icons.play_circle_outline_rounded, size: 12)
                else
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: Woodland.ink,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    ),
  );

  void _goHome() {
    if (_busy) return;
    g.select(null);
    g.persist();
    unawaited(g.flush());
    _feedbackTimer?.cancel();
    setState(() {
      _home = true;
      _hubTab = 0;
      _feedback = null;
    });
  }

  void _playStory() {
    g.changePage(GamePage.workshop);
    if (g.level != g.storyResumeLevel) g.chooseOrder(g.storyResumeLevel);
    if (g.submitted) g.restart();
    setState(() {
      _home = false;
      _feedback = null;
    });
    _checkDelivery();
  }

  void _playDaily({int? slot}) {
    g.changePage(GamePage.daily);
    if (slot != null) {
      g.chooseOrder(slot);
      if (g.submitted) g.restart();
    } else if (g.submitted) {
      final route = dailyOrders(g.pack, g.clock());
      final next = route.indexWhere((o) => !g.isCompleted(o.id));
      if (next >= 0)
        g.chooseOrder(next);
      else
        g.restart();
    }
    setState(() {
      _home = false;
      _feedback = null;
    });
    _checkDelivery();
  }

  void _openOrder(int i) {
    g.changePage(GamePage.workshop);
    g.chooseOrder(i);
    if (g.submitted) g.restart();
    setState(() {
      _home = false;
      _feedback = null;
    });
    _checkDelivery();
  }

  void _showHub(int tab) {
    if (_busy || _deliveryShowing) return;
    g.persist();
    unawaited(g.flush());
    setState(() {
      _home = true;
      _hubTab = tab;
      _feedback = null;
    });
  }

  Widget _homeScreen() => WoodlandHub(
    game: g,
    tab: _hubTab,
    onTab: _showHub,
    onPlay: _playStory,
    onDaily: (slot) => _playDaily(slot: slot),
    onOrder: _openOrder,
    onShop: (tab, garden) => _shop(tab: tab, gardenId: garden),
    onSettings: _settings,
    onHelp: _help,
  );

  Widget _currencyPlate({bool compact = false}) => Tooltip(
    message: 'Coin shop',
    child: Semantics(
      label: '${g.coins} coins. Open coin shop.',
      button: true,
      child: InkWell(
        key: ValueKey(compact ? 'game-coin-wallet' : 'home-coin-wallet'),
        onTap: () => _shop(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          width: compact ? 68 : 100,
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF9E8C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFF6E5)),
            boxShadow: const [
              BoxShadow(color: Color(0xFF9C7D54), offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              GameIcon('stamp', size: compact ? 19 : 24),
              const SizedBox(width: 5),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${g.coins}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF664D32),
                    ),
                  ),
                ),
              ),
              if (!compact)
                const Icon(
                  Icons.add_rounded,
                  size: 15,
                  color: Color(0xFF664D32),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  void _shop({int tab = 0, String? gardenId}) {
    if (_busy || _deliveryShowing) return;
    _adPage(
      'Coin shop',
      CoinShop(
        initialGarden: gardenId,
        game: g,
        ads: ads,
        accent: p.accent,
        surface: p.surface,
        initialTab: tab,
      ),
    );
  }

  Widget _roundIcon(IconData icon, String label, VoidCallback? action) {
    final back = icon == Icons.arrow_back_rounded,
        menu = icon == Icons.pause_rounded;
    return SizedBox(
      width: 48,
      height: 52,
      child: BentoButton(
        label: label,
        color: back
            ? const Color(0xFFB96358)
            : menu
            ? const Color(0xFF39829C)
            : p.surface,
        onPressed: action,
        animate: !g.reduceMotion,
        radius: 14,
        padding: const EdgeInsets.all(10),
        child: Center(
          child: back
              ? const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 25,
                )
              : menu
              ? const Icon(Icons.menu_rounded, color: Colors.white, size: 25)
              : GameIcon.fromMaterial(icon, size: 26),
        ),
      ),
    );
  }

  Future<void> _hint() async {
    if (_busy) return;
    if (g.hintsAvailable == 0 && g.hint == null && g.tutorialPour == null) {
      await _refill(GameTool.hint);
      return;
    }
    setState(() {
      _busy = true;
      _findingHint = true;
    });
    Pour? hint;
    try {
      hint = await g.showHint();
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
          _findingHint = false;
        });
    }
    if (hint == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Undo a pour, then try Hint.')),
      );
    }
  }

  Future<void> _undo() async {
    if (_busy || g.history.isEmpty || g.submitted) return;
    if (g.undosAvailable == 0) {
      await _refill(GameTool.undo);
      return;
    }
    g.undo();
  }

  Future<void> _refill(GameTool tool) async {
    final offerId = g.createToolRefillOffer(tool);
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tool == GameTool.hint ? 'More hints' : 'More undos'),
        content: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: g,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ToolRefillOffer(
                  game: g,
                  ads: ads,
                  tool: tool,
                  offerId: offerId,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Text(
                  'Or use your coins · Balance ${g.coins}',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('buy-tool-refill'),
                    onPressed:
                        g.coins <
                            (tool == GameTool.hint
                                ? hintPackPrice
                                : undoPackPrice)
                        ? null
                        : () {
                            if (g.buyToolRefill(tool) ==
                                PurchaseResult.bought) {
                              Navigator.pop(c);
                              unawaited(g.flush());
                            }
                          },
                    child: Text(
                      tool == GameTool.hint
                          ? 'Buy 3 hints · 60 coins'
                          : 'Buy 5 undos · 40 coins',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Keep playing'),
          ),
        ],
      ),
    );
  }

  Future<void> _restart() async {
    if (g.moves == 0 || g.submitted) {
      g.restart();
      return;
    }
    final reset = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Restart this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (reset == true && mounted) g.restart();
  }

  void _next() {
    if (!g.dailyMode && g.level == g.pack.length - 1)
      g.changePage(GamePage.daily);
    else
      g.nextOrder();
  }

  Future<void> _deliver() async {
    if (_deliveryShowing) return;
    _deliveryShowing = true;
    final coinsBefore = g.coins;
    final result = g.deliver();
    final earned = g.coins - coinsBefore;
    if (!result.accepted) {
      _deliveryShowing = false;
      return;
    }
    if (g.haptics) unawaited(HapticFeedback.mediumImpact());
    final customer = g.order.customers.first;
    final garden = Garden.forId(g.order.garden);
    final orderId = g.order.id;
    final bonus = ads.enabled && g.canClaimAdBonus(orderId);
    await g.flush();
    if (!mounted) return;
    final advance = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => DeliveryCelebration(
        game: g,
        ads: ads,
        garden: garden,
        customer: customer.kind,
        orderId: orderId,
        earned: earned,
        routeBonus: result.routeBonus,
        firstDelivery: result.firstDelivery,
        offerBonus: bonus,
      ),
    );
    _deliveryShowing = false;
    if (mounted) {
      if (advance == true) {
        _next();
      } else {
        _goHome();
      }
    }
  }

  Future<void> _sheet(String title, Widget child) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Woodland.cream,
    showDragHandle: true,
    builder: (c) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * .88),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 23,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(c),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    ),
  );

  /// Destinations share the single banner below the root Navigator.
  Future<void> _adPage(String title, Widget child) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (routeContext) => ListenableBuilder(
            listenable: Listenable.merge([g, ads]),
            builder: (pageContext, _) => Scaffold(
              key: ValueKey('ad-page-$title'),
              backgroundColor: p.background,
              appBar: AppBar(
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                foregroundColor: Woodland.cream,
                backgroundColor: p.background,
                surfaceTintColor: Colors.transparent,
              ),
              body: Stack(
                children: [
                  const Positioned.fill(child: WoodlandBackdrop(dim: .1)),
                  SafeArea(
                    top: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                          child: CreamCard(
                            padding: const EdgeInsets.all(14),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void _menu() => showDialog<void>(
    context: context,
    builder: (c) => StoryDialog(
      key: const ValueKey('pause-popup'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomerArt(
                  kind: g.order.customers.first.kind,
                  size: MediaQuery.sizeOf(c).height < 500 ? 32 : 112,
                ),
                const Text(
                  'Paused',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ListenableBuilder(
                  listenable: g,
                  builder: (_, _) => Row(
                    children: [
                      const GameIcon('settings', size: 24),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Sound', style: TextStyle(fontSize: 13)),
                      ),
                      Switch(
                        value: g.sound,
                        onChanged: (v) => g.setSettings(soundValue: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Resume'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(c);
                          _restart();
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const Text('Restart'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(c);
                          _goHome();
                        },
                        icon: const Icon(Icons.home_rounded, size: 18),
                        label: const Text('Home'),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(c);
                    _settings();
                  },
                  child: const Text(
                    'Settings & saved progress',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _copyProgress() async {
    await Clipboard.setData(ClipboardData(text: g.exportProgress()));
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Progress copied.')));
  }

  Future<void> _restoreProgress() async {
    Navigator.pop(context);
    final text = TextEditingController();
    try {
      final raw = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Restore progress'),
          content: TextField(
            controller: text,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Paste your progress',
              helperText: 'Replaces progress on this device.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, text.text),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (raw == null || !mounted) return;
      try {
        await g.restoreProgress(raw);
        if (mounted) {
          _goHome();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Progress restored.')));
        }
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('That progress save could not be opened.'),
            ),
          );
      }
    } finally {
      text.dispose();
    }
  }

  void _settings() => showDialog<void>(
    context: context,
    builder: (_) => GameSettingsDialog(
      game: g,
      ads: ads,
      onCopy: _copyProgress,
      onRestore: _restoreProgress,
      onHelp: _help,
    ),
  );
  void _help() => _sheet(
    'How to play',
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _helpStep(Icons.touch_app_rounded, 'Tap a bottle, then a destination.'),
        _helpStep(
          Icons.water_drop_outlined,
          'Only the top layer pours. Any color can mix.',
        ),
        _helpStep(
          Icons.check_circle_outline_rounded,
          'Match the recipe above each customer bottle.',
        ),
        _helpStep(
          Icons.trending_up_rounded,
          'The recipe bar tracks matching layers. Finish at your own pace.',
        ),
        _helpStep(
          Icons.paid_outlined,
          'Earn 20 coins per new delivery. Spend coins on extra tools, animals and decorations.',
        ),
        _helpStep(
          Icons.local_florist_outlined,
          'Story deliveries grow each garden. Finish its levels to unlock the next garden.',
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            _openOrder(0);
            g.restart();
          },
          child: const Text('Try the first order'),
        ),
      ],
    ),
  );
  Widget _helpStep(IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, color: p.accent, size: 26),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, height: 1.5)),
        ),
      ],
    ),
  );
}
