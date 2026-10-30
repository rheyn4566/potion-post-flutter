import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/ads/game_ads.dart';
import 'package:potion_post/data/progress_store.dart';
import 'package:potion_post/game_controller.dart';
import 'package:potion_post/main.dart';
import 'package:potion_post/ui/art_cache.dart';

import 'game_test.dart' show pack, solve;
import 'progress_store_test.dart' show FailingStore;

class FakeAds extends GameAds {
  RewardAdState state = RewardAdState.ready;
  bool lastActive = false, award = true;
  bool loadedBanner = true;
  double bannerHeight = 50;
  @override
  bool get bannerVisible => loadedBanner;
  int watches = 0, retries = 0, bannerMounts = 0, bannerDisposals = 0;
  bool repeatEarned = false;
  bool deferEarned = false;
  VoidCallback? pendingReward;
  @override
  bool get enabled => true;
  @override
  RewardAdState get rewardState => state;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> retry() async {
    retries++;
    state = RewardAdState.ready;
    notifyListeners();
  }

  @override
  Future<void> watch({required VoidCallback onEarned}) async {
    watches++;
    if (deferEarned) {
      pendingReward = onEarned;
      return;
    }
    if (award) {
      onEarned();
      if (repeatEarned) onEarned();
    }
  }

  @override
  Widget banner({required bool active}) {
    lastActive = active;
    return TrackedBanner(ads: this);
  }
}

class TrackedBanner extends StatefulWidget {
  const TrackedBanner({super.key, required this.ads});
  final FakeAds ads;
  @override
  State<TrackedBanner> createState() => _TrackedBannerState();
}

class _TrackedBannerState extends State<TrackedBanner> {
  @override
  void initState() {
    super.initState();
    widget.ads.bannerMounts++;
  }

  @override
  void dispose() {
    widget.ads.bannerDisposals++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.ads.loadedBanner
      ? AdBannerFrame(
          height: widget.ads.bannerHeight,
          child: const SizedBox.shrink(),
        )
      : const SizedBox.shrink();
}

Future<GameController> setup(
  WidgetTester tester,
  FakeAds ads, {
  Size size = const Size(390, 844),
  double pixelRatio = 1,
  GlobalKey? boundary,
  ProgressStore? store,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.runAsync(() async {
    final fonts = FontLoader('Poppins');
    for (final name in ['Regular', 'Medium', 'SemiBold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Poppins-$name.ttf'));
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final game = GameController(pack(), store ?? MemoryProgressStore());
  await game.initialize();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20;
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: PotionPostApp(game: game, ads: ads),
    ),
  );
  await settle(tester);
  return game;
}

Future<void> capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  if (Platform.environment['POTION_POST_CAPTURE'] != '1') return;
  // Wait for the providers actually visible in this capture, including resized
  // portraits and a newly selected world, before recording the painted frame.
  await tester.runAsync(() async {
    final context = tester.element(
      find.byType(GameScreen, skipOffstage: false),
    );
    final providers = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .toSet();
    await Future.wait(
      providers.map((provider) => precacheImage(provider, context)),
    );
  });
  await tester.pump();
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('docs/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> disposeGame(
  WidgetTester tester,
  GameController game,
  FakeAds ads,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await settle(tester);
  await game.flush();
  game.dispose();
  ads.dispose();
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  for (final milliseconds in [1100, 350, 350, 350]) {
    // Give actual local image decoding time, then flush its fake-clock callbacks.
    // Exercise the production working set instead of precaching every asset.
    final wait = Stopwatch()..start();
    while (ArtImages.hasPending) {
      if (wait.elapsed > const Duration(seconds: 15)) {
        throw StateError('Scene artwork did not finish loading');
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 8)),
      );
      await tester.pump();
    }
    await tester.pump(Duration(milliseconds: milliseconds));
  }
}

void main() {
  testWidgets(
    'Save read failures show recovery and never overwrite existing progress with zero',
    (tester) async {
      final seed = GameController(pack(), MemoryProgressStore());
      await seed.initialize();
      for (final order in seed.pack.take(10)) seed.stars[order.id] = 3;
      seed.chooseOrder(10);
      await seed.flush();
      final store = FailingStore()
        ..failLoad = true
        ..data = Map<String, dynamic>.from(
          jsonDecode(seed.exportProgress()) as Map,
        );
      final ads = FakeAds(), game = await setup(tester, ads, store: store);
      expect(find.text('Let’s recover your saved game'), findsOneWidget);
      expect(find.byKey(const ValueKey('play-button')), findsNothing);
      game.persist();
      await game.flush();
      expect(store.writes, 0);
      store.failLoad = false;
      await tester.tap(find.text('Retry saved game'));
      await settle(tester);
      expect(game.level, 10);
      expect(game.stars.length, 10);
      expect(find.byKey(const ValueKey('play-button')), findsOneWidget);
      await disposeGame(tester, game, ads);
      seed.dispose();
    },
  );

  testWidgets(
    'One bottom system inset keeps the banner and game controls separated',
    (tester) async {
      final ads = FakeAds(), game = await setup(tester, ads);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      final slot = tester.getRect(
        find.byKey(const ValueKey('ad-reserved-space')),
      );
      expect(slot.bottom, 844 - 24);
      final tools = tester.getRect(find.byKey(const ValueKey('tool-hint')));
      expect(tools.bottom, lessThanOrEqualTo(slot.top - 12));
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Rewarded tool refills require opt-in, grant once and leave free play available',
    (tester) async {
      final ads = FakeAds()..state = RewardAdState.unavailable;
      final boundary = GlobalKey(),
          game = await setup(tester, ads, boundary: boundary);
      for (final order in game.pack.take(2)) game.stars[order.id] = 3;
      game.chooseOrder(2);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      for (var i = 0; i < 3; i++) {
        await game.showHint();
        game.restart();
      }
      await settle(tester);
      await tester.tap(find.text('Hint'));
      await settle(tester);
      expect(find.text('Watch one ad to add 3 hints.'), findsOneWidget);
      expect(ads.watches, 0);
      expect(game.hintsAvailable, 0);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('watch-tool-refill')),
            )
            .onPressed,
        isNull,
      );
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.text('Keep playing')).bottom,
          lessThan(
            tester.getRect(find.byKey(const ValueKey('ad-reserved-space'))).top,
          ),
        );
      }
      await tester.tap(find.text('Ad unavailable · Retry'));
      await settle(tester);
      expect(ads.watches, 0);
      expect(ads.retries, 1);
      ads.award = false;
      await tester.tap(find.byKey(const ValueKey('watch-tool-refill')));
      await settle(tester);
      expect(game.hintsAvailable, 0);
      await tester.tap(find.text('Keep playing'));
      await settle(tester);
      await tester.tap(find.text('Restart'));
      await settle(tester);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.text('Hint'));
      await settle(tester);
      ads.award = true;
      ads.repeatEarned = true;
      await tester.tap(find.byKey(const ValueKey('watch-tool-refill')));
      await settle(tester);
      expect(game.hintsAvailable, 3);
      expect(find.text('+3 hints added'), findsOneWidget);
      expect(find.byKey(const ValueKey('watch-tool-refill')), findsNothing);
      await capture(tester, boundary, 'TOOL_REFILL');
      await tester.tap(find.text('Keep playing'));
      await settle(tester);
      for (var i = 0; i < 5; i++) {
        game.performPour(game.order.solution.first);
        game.undo();
      }
      game.performPour(game.order.solution.first);
      await settle(tester);
      expect(game.undosAvailable, 0);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Watch one ad to add 5 undos.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('watch-tool-refill')));
      await settle(tester);
      expect(game.undosAvailable, 5);
      expect(ads.bannerMounts, 1);
      expect(ads.bannerDisposals, 0);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Real animated pour remains usable and rewarded bonus is explicit and once-only',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(tester, ads, boundary: boundary);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      final move = game.order.solution.first;
      final before = tester.getRect(
        find.byKey(ValueKey('bottle-${move.from}')),
      );
      await tester.tap(find.byKey(ValueKey('bottle-${move.from}')));
      await settle(tester);
      await tester.tap(find.byKey(ValueKey('bottle-${move.to}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 480));
      expect(find.byKey(const ValueKey('flight-bottle')), findsOneWidget);
      expect(find.byKey(const ValueKey('pour-stream')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('game-coin-wallet')));
      await tester.pump();
      expect(find.byKey(const ValueKey('ad-page-Coin shop')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('recipe-meter')));
      await tester.pump();
      expect(find.text('Your recipe progress'), findsNothing);
      await settle(tester);
      expect(game.ready, isTrue);
      expect(find.text('Delivered!'), findsOneWidget);
      expect(
        tester.getRect(find.byKey(ValueKey('bottle-${move.from}'))),
        before,
        reason: 'Delivery popup must not resize the board',
      );
      expect(
        find.byKey(const ValueKey('compact-move-counter')),
        findsOneWidget,
      );
      expect(find.text('1 pour'), findsOneWidget);
      expect(find.textContaining('pours or fewer'), findsNothing);
      expect(find.text('Deliver potion'), findsNothing);
      expect(game.coins, 20);
      expect(ads.watches, 0);
      expect(find.text('3/3 available today'), findsOneWidget);
      await capture(tester, boundary, 'ADS_DELIVERY_LAYOUT');
      await tester.tap(find.byKey(const ValueKey('watch-rewarded-ad')));
      await settle(tester);
      expect(game.coins, 40);
      expect(ads.watches, 1);
      expect(find.byKey(const ValueKey('reward-confirmed')), findsOneWidget);
      expect(find.byKey(const ValueKey('watch-rewarded-ad')), findsNothing);
      await tester.tap(find.text('Next order').last);
      await settle(tester);
      expect(game.level, 1);
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Unavailable reward can be retried but never auto-plays; skipping keeps normal coins',
    (tester) async {
      final ads = FakeAds()..state = RewardAdState.unavailable;
      final game = await setup(tester, ads);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      solve(game);
      await settle(tester);
      expect(ads.watches, 0);
      expect(game.coins, 20);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('watch-rewarded-ad')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Ad unavailable · Retry'));
      await settle(tester);
      expect(ads.retries, 1);
      expect(ads.watches, 0);
      ads.award = false;
      await tester.tap(find.byKey(const ValueKey('watch-rewarded-ad')));
      await settle(tester);
      expect(game.coins, 20);
      expect(find.text('No bonus earned. You can continue.'), findsOneWidget);
      await tester.tap(find.text('Next order').last);
      await settle(tester);
      expect(game.level, 1);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Continue stays visible with optional reward on short screens and landscape',
    (tester) async {
      final ads = FakeAds()..state = RewardAdState.loading;
      final game = await setup(tester, ads);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(758, 1216),
      ]) {
        tester.view.physicalSize = size;
        game.restart();
        solve(game);
        await settle(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Reward result at $size',
        );
        final next = tester.getRect(find.text('Next order').last);
        expect(next.top, greaterThanOrEqualTo(0));
        expect(next.bottom, lessThan(size.height));
        await tester.tap(find.text('Next order').last);
        await settle(tester);
        expect(ads.watches, 0);
        expect(tester.takeException(), isNull);
      }
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets('Four and five bottle layouts retain compact tablet spacing', (
    tester,
  ) async {
    final ads = FakeAds(), boundary = GlobalKey();
    final game = await setup(tester, ads, boundary: boundary);
    for (final order in game.pack.take(999)) {
      game.stars[order.id] = 3;
    }
    await tester.tap(find.byKey(const ValueKey('play-button')));
    await settle(tester);
    for (final index in [
      2,
      40,
      game.pack.indexWhere((o) => o.targets.length == 3),
    ]) {
      game.chooseOrder(index);
      for (final size in [
        const Size(320, 568),
        const Size(390, 844),
        const Size(844, 390),
        const Size(758, 1216),
      ]) {
        tester.view.physicalSize = size;
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'Board $index at $size');
        expect(find.byKey(const ValueKey('ad-reserved-space')), findsOneWidget);
        for (var i = 0; i < game.board.length; i++) {
          final rect = tester.getRect(find.byKey(ValueKey('bottle-$i')));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThan(size.height));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
        }
        if (index == 2 && size == const Size(390, 844))
          await capture(tester, boundary, 'GARDEN_GAMEPLAY');
        if (size == const Size(758, 1216)) {
          final first = tester.getRect(find.byKey(const ValueKey('bottle-0')));
          final nextRow = tester.getRect(
            find.byKey(ValueKey('bottle-${game.board.length == 5 ? 3 : 2}')),
          );
          expect(nextRow.top - first.bottom, inInclusiveRange(12, 40));
        }
      }
    }
    await disposeGame(tester, game, ads);
  });

  testWidgets(
    'Coin shop grants only earned ads, keeps the banner without unfinished cash packs',
    (tester) async {
      final ads = FakeAds()..repeatEarned = true;
      final boundary = GlobalKey(),
          game = await setup(tester, ads, boundary: boundary);
      await tester.tap(find.byKey(const ValueKey('home-coin-wallet')));
      await settle(tester);
      expect(find.byKey(const ValueKey('ad-page-Coin shop')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('paid-coins-unavailable')),
        findsNothing,
      );
      expect(ads.watches, 0);
      expect(game.coins, 0);
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(390, 844),
        const Size(758, 1216),
      ]) {
        tester.view.physicalSize = size;
        for (var tab = 0; tab < 4; tab++) {
          await settle(tester);
          await tester.ensureVisible(find.byKey(ValueKey('shop-tab-$tab')));
          await tester.tap(find.byKey(ValueKey('shop-tab-$tab')));
          await settle(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Shop tab $tab at $size',
          );
        }
      }
      tester.view.physicalSize = const Size(390, 844);
      await settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('shop-tab-0')));
      await tester.tap(find.byKey(const ValueKey('shop-tab-0')));
      await settle(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('watch-shop-coins')),
      );
      ads.award = false;
      await tester.tap(find.byKey(const ValueKey('watch-shop-coins')));
      await settle(tester);
      expect(game.coins, 0);
      ads.award = true;
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('watch-shop-coins')));
        await settle(tester);
        expect(game.coins, (i + 1) * 20);
      }
      expect(game.coinAdsRemaining, 0);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('watch-shop-coins')),
            )
            .onPressed,
        isNull,
      );
      expect(ads.bannerMounts, 1);
      expect(ads.bannerDisposals, 0);
      await capture(tester, boundary, 'COIN_SHOP');
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Confirmed shop purchases spend coins once, cancel is free and story stays locked',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(tester, ads, boundary: boundary);
      game.coins = 1000;
      await tester.tap(find.byKey(const ValueKey('home-coin-wallet')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('shop-tab-1')));
      await settle(tester);
      final friend = game.friends[1],
          price = game.priceOfCompanion(game.friends[1].kind);
      final animal = find.byKey(ValueKey('shop-animal-${friend.kind}'));
      await tester.ensureVisible(animal);
      await tester.tap(animal);
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(game.coins, 1000);
      await tester.tap(animal);
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-coin-purchase')));
      await settle(tester);
      expect(game.coins, 1000 - price);
      expect(game.ownsCompanion(friend.kind), isTrue);
      expect(game.friendCount(friend.id), 0);
      expect(game.friendRewardsReady, 0);
      await tester.ensureVisible(find.byKey(const ValueKey('shop-tab-2')));
      await tester.tap(find.byKey(const ValueKey('shop-tab-2')));
      await settle(tester);
      final garden = find.byKey(const ValueKey('shop-decor-chimes'));
      await tester.ensureVisible(garden);
      await tester.tap(garden);
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-coin-purchase')));
      await settle(tester);
      expect(game.coins, 1000 - price - 500);
      expect(game.garden, 'moonbloom');
      expect(game.decorationsFor('moonbloom'), {'chimes'});
      await tester.ensureVisible(garden);
      await tester.tap(garden);
      await settle(tester);
      expect(game.decorationsFor('moonbloom'), isEmpty);
      expect(game.coins, 1000 - price - 500);
      await tester.tap(garden);
      await settle(tester);
      expect(game.decorationsFor('moonbloom'), {'chimes'});
      expect(game.isGardenUnlocked('lilypond'), isFalse);
      expect(game.unlocked, 0);
      expect(game.stars, isEmpty);
      await capture(tester, boundary, 'SHOP_GARDENS');
      await tester.ensureVisible(find.byKey(const ValueKey('shop-tab-3')));
      await tester.tap(find.byKey(const ValueKey('shop-tab-3')));
      await settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('shop-tool-hint')));
      await tester.tap(find.byKey(const ValueKey('shop-tool-hint')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-coin-purchase')));
      await settle(tester);
      expect(game.coins, 1000 - price - 500 - 60);
      expect(game.hintsAvailable, 6);
      expect(game.coinHistory.first.amount, -60);
      Navigator.pop(
        tester.element(find.byKey(const ValueKey('ad-page-Coin shop'))),
      );
      await settle(tester);
      expect(find.textContaining('Moonbloom · 0/10 delivered'), findsOneWidget);
      expect(find.byKey(const ValueKey('play-button')), findsOneWidget);
      expect(find.textContaining('0/10 delivered'), findsOneWidget);
      expect(ads.watches, 0);
      expect(ads.bannerMounts, 1);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Late shop earned callback remains once-only after its page closes',
    (tester) async {
      final ads = FakeAds()..deferEarned = true;
      final game = await setup(tester, ads);
      await tester.tap(find.byKey(const ValueKey('home-coin-wallet')));
      await settle(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('watch-shop-coins')),
      );
      await tester.tap(find.byKey(const ValueKey('watch-shop-coins')));
      await settle(tester);
      expect(game.coins, 0);
      expect(ads.pendingReward, isNotNull);
      Navigator.pop(
        tester.element(find.byKey(const ValueKey('ad-page-Coin shop'))),
      );
      await settle(tester);
      ads.pendingReward!();
      ads.pendingReward!();
      await settle(tester);
      expect(game.coins, 20);
      expect(game.coinAdsRemaining, 2);
      expect(tester.takeException(), isNull);
      expect(ads.bannerMounts, 1);
      expect(ads.bannerDisposals, 0);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Shop save failure exposes retry without repeating a coin purchase',
    (tester) async {
      final ads = FakeAds(), store = FailingStore();
      final game = await setup(tester, ads, store: store);
      game.coins = 1000;
      await tester.tap(find.byKey(const ValueKey('home-coin-wallet')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('shop-tab-3')));
      await settle(tester);
      store.failWrite = true;
      await tester.ensureVisible(find.byKey(const ValueKey('shop-tool-hint')));
      await tester.tap(find.byKey(const ValueKey('shop-tool-hint')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-coin-purchase')));
      await settle(tester);
      expect(game.coins, 940);
      expect(game.hintsAvailable, 6);
      expect(game.saveFailed, isTrue);
      expect(find.textContaining('latest changes need'), findsOneWidget);
      store.failWrite = false;
      await tester.ensureVisible(find.text('Retry saving'));
      await tester.tap(find.text('Retry saving'));
      await settle(tester);
      expect(game.saveFailed, isFalse);
      expect(store.data!['coins'], 940);
      expect(game.hintsAvailable, 6);
      expect(game.coinHistory.where((e) => e.amount < 0).length, 1);
      await disposeGame(tester, game, ads);
    },
  );
}
