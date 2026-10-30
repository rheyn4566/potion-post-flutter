import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/data/progress_store.dart';
import 'package:potion_post/domain/catalog.dart';
import 'package:potion_post/game_controller.dart';
import 'package:potion_post/ui/garden_art.dart';
import 'package:potion_post/ui/scene_catalog.dart';
import 'game_test.dart' show pack, solve;
import 'ui_test.dart' show FakeAds, setup, settle, capture, disposeGame;

void main() {
  test(
    'Expanded routes remain contiguous and every character has a unique identity and bundled sprite',
    () async {
      final orders = pack();
      expect(orders.length, 1480);
      expect(Garden.all.length, 43);
      expect(gardenThemes.keys.toSet(), Garden.all.map((g) => g.id).toSet());
      var next = 0;
      for (final garden in Garden.all) {
        expect(garden.firstOrder, next, reason: garden.name);
        final route = orders.sublist(
          garden.firstOrder,
          garden.firstOrder + garden.count,
        );
        expect(
          route.every((o) => o.garden == garden.id),
          isTrue,
          reason: garden.name,
        );
        next += garden.count;
      }
      expect(next, orders.length);
      final game = GameController(orders, MemoryProgressStore());
      await game.initialize();
      expect(game.friends.length, 26);
      expect(game.friends.map((f) => f.id).toSet().length, 26);
      expect(game.friends.map((f) => f.name).toSet().length, 26);
      expect(game.friends.map((f) => f.kind).toSet().length, 26);
      expect(game.friends.singleWhere((f) => f.kind == 'otter').name, 'Pebble');
      expect(
        game.friends.singleWhere((f) => f.kind == 'capybara').name,
        'Basil',
      );
      for (final friend in game.friends) {
        expect(
          File('assets/characters/${friend.kind}.webp').existsSync(),
          isTrue,
          reason: friend.kind,
        );
      }
      expect(gardenSceneAssets.length, 18);
      for (final path in gardenSceneAssets.values)
        expect(File(path).existsSync(), isTrue, reason: path);
      await game.flush();
      game.dispose();
    },
  );

  testWidgets(
    'Garden collection previews a new scene without bypassing progression and fits short displays',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(tester, ads, boundary: boundary);
      await tester.tap(find.byKey(const ValueKey('nav-gardens')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('browse-gardens')));
      await settle(tester);
      for (var page = 0; page < 5; page++) {
        await tester.tap(find.byTooltip('Next garden page'));
        await settle(tester);
      }
      await tester.tap(find.byKey(const ValueKey('collection-garden-31')));
      await settle(tester);
      expect(find.text('Unlock at order 1001'), findsOneWidget);
      expect(game.garden, 'moonbloom');
      expect(game.unlocked, 0);
      expect(tester.takeException(), isNull);
      await capture(tester, boundary, 'INTEGRATED_LANTERNLEAF');
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('browse-gardens')));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'Collection at $size');
        final banner = tester.getRect(
          find.byKey(const ValueKey('ad-reserved-space')),
        );
        expect(tester.getRect(find.text('Close')).bottom, lessThan(banner.top));
        await tester.tap(find.text('Close'));
        await settle(tester);
      }
      expect(ads.bannerMounts, 1);
      expect(ads.watches, 0);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'A new companion can be previewed, invited once and displayed on Home',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(tester, ads, boundary: boundary);
      game.coins = 5000;
      final index = game.friends.indexWhere((f) => f.kind == 'capybara');
      final price = game.priceOfCompanion('capybara');
      await tester.tap(find.byKey(const ValueKey('nav-friends')));
      await settle(tester);
      for (var page = 0; page < index ~/ 6; page++) {
        await tester.tap(find.byTooltip('Next friends'));
        await settle(tester);
      }
      await tester.tap(find.byKey(const ValueKey('friend-capybara')));
      await settle(tester);
      expect(
        find.byKey(const ValueKey('friend-preview-capybara')),
        findsOneWidget,
      );
      expect(find.text('Basil'), findsAtLeastNWidgets(1));
      await tester.tap(find.byKey(const ValueKey('friend-action')));
      await settle(tester);
      await tester.tap(find.text('Invite · $price Coins').last);
      await settle(tester);
      expect(game.coins, 5000 - price);
      expect(game.courier, 'capybara');
      await tester.tap(find.byKey(const ValueKey('friend-action')));
      await settle(tester);
      expect(game.coins, 5000 - price);
      await capture(tester, boundary, 'INTEGRATED_BASIL');
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await settle(tester);
      await capture(tester, boundary, 'INTEGRATED_HOME_BASIL');
      expect(tester.takeException(), isNull);
      expect(ads.bannerMounts, 1);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'The first expanded route opens a playable recipe and delivers above the banner',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(tester, ads, boundary: boundary);
      for (final order in game.pack.take(1000)) game.stars[order.id] = 1;
      game.selectGarden('lanternleaf');
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      expect(game.level, 1000);
      expect(game.order.garden, 'lanternleaf');
      expect(game.order.customers.first.kind, 'turtle');
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await settle(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Expanded gameplay at $size',
        );
        expect(find.byKey(const ValueKey('recipe-meter')), findsOneWidget);
      }
      await capture(tester, boundary, 'INTEGRATED_GAMEPLAY');
      solve(game);
      await settle(tester);
      expect(find.text('Delivered!'), findsOneWidget);
      expect(game.gardenDelivered('lanternleaf'), 1);
      expect(game.coins, 20);
      expect(ads.bannerMounts, 1);
      expect(ads.watches, 0);
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );
}
