import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/data/progress_store.dart';
import 'package:potion_post/domain/economy.dart';
import 'package:potion_post/domain/puzzle.dart';
import 'package:potion_post/game_controller.dart';

import 'game_test.dart' show pack, solve;

void main() {
  test(
    'Completing garden ten advances home and route; replay cannot move them back',
    () async {
      final g = GameController(pack(), MemoryProgressStore());
      await g.initialize();
      for (var i = 0; i < 10; i++) {
        g.chooseOrder(i);
        solve(g);
        g.deliver();
      }
      expect(g.level, 9);
      expect(g.storyResumeLevel, 10);
      expect(g.garden, 'lilypond');
      expect(g.followRouteGarden, isTrue);
      g.chooseOrder(4);
      g.restart();
      expect(g.storyResumeLevel, 10);
      expect(g.garden, 'lilypond');
      g.selectGarden('moonbloom');
      g.chooseOrder(10);
      expect(g.garden, 'moonbloom');
      expect(g.followRouteGarden, isFalse);
      g.followGardenRoute();
      expect(g.garden, 'lilypond');
      await g.flush();
      g.dispose();
    },
  );

  test(
    'Legacy 10/10 save migrates without losing coins, stars or replay session',
    () async {
      final orders = pack();
      final data = <String, dynamic>{
        'version': 1,
        'coins': 400,
        'level': 4,
        'garden': 'moonbloom',
        'stars': {for (final order in orders.take(10)) order.id: 2},
        'sessions': <String, dynamic>{},
      };
      final store = MemoryProgressStore()..data = data;
      final g = GameController(orders, store);
      await g.initialize();
      expect(g.coins, 400);
      expect(g.delivered, 10);
      expect(g.storyResumeLevel, 10);
      expect(g.garden, 'lilypond');
      expect(g.coinHistory.single.amount, 400);
      expect(g.coinHistory.single.label, 'Previous balance');
      await g.flush();
      g.dispose();
    },
  );

  test(
    'Decorations and animal purchases persist without buying story progress',
    () async {
      final store = MemoryProgressStore(), orders = pack();
      final g = GameController(orders, store);
      await g.initialize();
      expect(g.ownsCompanion(g.friends.first.kind), isTrue);
      expect(g.courier, g.friends.first.kind);
      expect(
        g.buyDecoration('moonbloom', 'chimes'),
        PurchaseResult.insufficientCoins,
      );
      expect(g.buyDecoration('lilypond', 'chimes'), PurchaseResult.unavailable);
      expect(
        g.buyDecoration('moonbloom', 'unknown'),
        PurchaseResult.unavailable,
      );
      g.coins = 4000;
      final before = copyBoard(g.board);
      expect(g.buyDecoration('moonbloom', 'chimes'), PurchaseResult.bought);
      expect(g.coins, 3500);
      expect(g.buyDecoration('moonbloom', 'chimes'), PurchaseResult.owned);
      expect(g.coins, 3500);
      expect(g.decorationsFor('moonbloom'), {'chimes'});
      g.toggleDecoration('moonbloom', 'chimes');
      expect(g.decorationsFor('moonbloom'), isEmpty);
      g.toggleDecoration('moonbloom', 'chimes');
      g.toggleDecoration('moonbloom', 'fountain');
      expect(g.decorationsFor('moonbloom'), {'chimes'});
      expect(g.isGardenUnlocked('lilypond'), isFalse);
      expect(g.unlocked, 0);
      expect(g.stars, isEmpty);
      expect(Puzzle.equalBoard(g.board, before), isTrue);
      final animal = g.friends.firstWhere((f) => f.kind == 'hedgehog'),
          price = g.priceOfCompanion('hedgehog');
      expect(price, 1500);
      expect(g.buyCompanion(animal.kind), PurchaseResult.bought);
      expect(g.coins, 3500 - price);
      expect(g.buyCompanion(animal.kind), PurchaseResult.owned);
      expect(g.friendCount(animal.id), 0);
      expect(g.collectFriend(animal.id), 0);
      expect(g.buyToolRefill(GameTool.hint), PurchaseResult.bought);
      expect(g.buyToolRefill(GameTool.undo), PurchaseResult.bought);
      await g.flush();
      final restored = GameController(orders, store);
      await restored.initialize();
      expect(restored.coins, 1900);
      expect(restored.decorationsFor('moonbloom'), {'chimes'});
      expect(restored.courier, animal.kind);
      expect(restored.ownsCompanion(animal.kind), isTrue);
      expect(restored.hintsAvailable, 6);
      expect(restored.undosAvailable, 10);
      expect(restored.coinHistory.map((e) => e.amount), [
        -40,
        -60,
        -1500,
        -500,
      ]);
      await restored.flush();
      restored.dispose();
      g.dispose();
    },
  );

  test('Unavailable balances and damaged saves cannot spend coins', () async {
    final g = GameController(pack(), MemoryProgressStore());
    await g.initialize();
    expect(
      g.buyCompanion(g.friends.last.kind),
      PurchaseResult.insufficientCoins,
    );
    expect(g.buyToolRefill(GameTool.hint), PurchaseResult.insufficientCoins);
    expect(g.coins, 0);
    expect(g.coinHistory, isEmpty);
    g.coins = 1000;
    g.loadFailed = true;
    expect(g.buyToolRefill(GameTool.undo), PurchaseResult.unavailable);
    expect(g.buyCompanion(g.friends.last.kind), PurchaseResult.unavailable);
    expect(g.buyDecoration('moonbloom', 'chimes'), PurchaseResult.unavailable);
    expect(g.coins, 1000);
    expect(g.coinHistory, isEmpty);
    g.dispose();
  });

  test(
    'Delivery and shop coin ads share a persisted three-per-day limit',
    () async {
      var now = DateTime(2026, 10, 19, 23, 59);
      final store = MemoryProgressStore(), orders = pack();
      final g = GameController(orders, store, clock: () => now);
      await g.initialize();
      expect(g.claimCoinOffer('coins-fake'), isFalse);
      solve(g);
      g.deliver();
      final deliveredId = g.order.id;
      expect(g.claimAdBonus(deliveredId), isTrue);
      expect(g.claimAdBonus(deliveredId), isFalse);
      final offer = g.createCoinOffer();
      g.changePage(GamePage.daily);
      expect(g.claimCoinOffer(offer), isTrue);
      expect(g.claimCoinOffer(offer), isFalse);
      solve(g);
      g.deliver();
      expect(g.claimAdBonus(g.order.id), isTrue);
      expect(g.coins, 100);
      expect(g.coinAdsRemaining, 0);
      expect(g.claimCoinOffer(g.createCoinOffer()), isFalse);
      g.chooseOrder(1);
      solve(g);
      g.deliver();
      expect(g.canClaimAdBonus(g.order.id), isFalse);
      expect(g.claimAdBonus(g.order.id), isFalse);
      await g.flush();
      final restored = GameController(orders, store, clock: () => now);
      await restored.initialize();
      expect(restored.coinAdsRemaining, 0);
      expect(restored.coins, 120);
      now = DateTime(2026, 10, 20, 0, 1);
      restored.refreshDate();
      expect(restored.coinAdsRemaining, 3);
      expect(restored.canClaimAdBonus(deliveredId), isFalse);
      expect(restored.claimCoinOffer(restored.createCoinOffer()), isTrue);
      expect(restored.coins, 140);
      final backup =
          jsonDecode(restored.exportProgress()) as Map<String, dynamic>;
      expect(backup['economy']['shopAds']['2026-10-19'], 3);
      await restored.flush();
      restored.dispose();
      g.dispose();
    },
  );

  test(
    'Legacy earned companions and early garden looks remain owned after migration',
    () async {
      final orders = pack();
      final data = <String, dynamic>{
        'version': 1,
        'coins': 845,
        'level': 9,
        'garden': 'sunpetal',
        'followRouteGarden': false,
        'stars': {for (final o in orders.take(10)) o.id: 3},
        'sessions': <String, dynamic>{},
        'economy': {
          'gardens': ['sunpetal'],
          'companions': ['hedgehog'],
        },
      };
      final store = MemoryProgressStore()..data = data;
      final g = GameController(orders, store);
      await g.initialize();
      final earned = orders
          .take(10)
          .expand((o) => o.customers)
          .map((f) => f.kind)
          .toSet();
      for (final kind in earned) expect(g.ownsCompanion(kind), isTrue);
      expect(g.coins, 845);
      expect(g.garden, 'sunpetal');
      expect(g.ownsGardenLook('sunpetal'), isTrue);
      expect(g.isGardenUnlocked('sunpetal'), isFalse);
      expect(g.gardenGrowth('moonbloom'), 3);
      expect(g.buyDecoration('sunpetal', 'chimes'), PurchaseResult.unavailable);
      final saved = g.exportProgress();
      await g.restoreProgress(saved);
      expect(g.coins, 845);
      for (final kind in earned) expect(g.ownsCompanion(kind), isTrue);
      await g.flush();
      g.dispose();
    },
  );

  test(
    'New deliveries do not automatically invite additional animals',
    () async {
      final g = GameController(pack(), MemoryProgressStore());
      await g.initialize();
      for (var i = 0; i < 10; i++) {
        g.chooseOrder(i);
        solve(g);
        g.deliver();
      }
      final met = g.friends.firstWhere(
        (f) => f.kind != g.friends.first.kind && g.friendCount(f.id) > 0,
      );
      expect(g.ownsCompanion(met.kind), isFalse);
      await g.flush();
      final restored = GameController(pack(), g.store);
      await restored.initialize();
      expect(restored.ownsCompanion(met.kind), isFalse);
      expect(restored.ownsCompanion(restored.friends.first.kind), isTrue);
      await restored.flush();
      restored.dispose();
      g.dispose();
    },
  );

  test(
    'Garden growth uses unique completed levels and never downgrades legacy growth',
    () async {
      final g = GameController(pack(), MemoryProgressStore());
      await g.initialize();
      for (final total in [10, 40]) {
        expect(gardenGrowthStage(0, total), 0);
        expect(gardenGrowthStage((total * .3).ceil() - 1, total), 0);
        expect(gardenGrowthStage((total * .3).ceil(), total), 1);
        expect(gardenGrowthStage((total * .6).ceil(), total), 2);
        expect(gardenGrowthStage(total - 1, total), 2);
        expect(gardenGrowthStage(total, total), 3);
        for (var completed = 0; completed <= total; completed++) {
          final oldMaximum = (completed * 3 ~/ total).clamp(0, 3);
          expect(
            gardenGrowthStage(completed, total),
            greaterThanOrEqualTo(oldMaximum),
          );
        }
      }
      for (var i = 0; i < 10; i++) {
        g.chooseOrder(i);
        final first = g.order.solution.first;
        for (var j = 0; j < 8; j++) {
          g.performPour(first);
          g.performPour(Pour(first.to, first.from));
        }
        solve(g);
        expect(g.moves, greaterThan(g.order.par + 4));
        expect(g.deliver().accepted, isTrue);
      }
      expect(g.gardenDelivered('moonbloom'), 10);
      expect(g.gardenGrowth('moonbloom'), 3);
      expect(g.coins, 200);
      g.chooseOrder(0);
      g.restart();
      solve(g);
      g.deliver();
      expect(g.gardenDelivered('moonbloom'), 10);
      expect(g.coins, 200);
      await g.flush();
      g.dispose();
    },
  );

  test(
    'Daily payout breakdown matches the balance and never repeats on replays',
    () async {
      final g = GameController(pack(), MemoryProgressStore());
      await g.initialize();
      g.changePage(GamePage.daily);
      for (var i = 0; i < 3; i++) {
        g.chooseOrder(i);
        solve(g);
        final result = g.deliver();
        expect(result.baseCoins, 20);
        expect(result.routeBonus, i == 2 ? 40 : 0);
      }
      expect(g.coins, 100);
      g.restart();
      solve(g);
      final replay = g.deliver();
      expect(replay.baseCoins, 0);
      expect(replay.routeBonus, 0);
      expect(g.coins, 100);
      expect(g.claimDailyBonus(), 0);
      await g.flush();
      g.dispose();
    },
  );

  test(
    'Recipe meter reaches 100% exactly when every recipe board is solved',
    () async {
      final orders = pack(), g = GameController(pack(), MemoryProgressStore());
      await g.initialize();
      for (var i = 0; i < orders.length; i++) {
        if (i > 0) g.stars[orders[i - 1].id] = 1;
        g.chooseOrder(i);
        expect(g.recipeProgress, inInclusiveRange(0, 1));
        expect(g.recipeProgress == 1, g.ready, reason: 'Start ${g.order.id}');
        for (final move in g.order.solution) {
          g.performPour(move);
          expect(g.recipeProgress == 1, g.ready, reason: g.order.id);
        }
        expect(g.recipeProgress, 1);
      }
      await g.flush();
      g.dispose();
    },
  );
}
