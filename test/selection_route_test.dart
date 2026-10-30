import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/data/progress_store.dart';
import 'package:potion_post/domain/economy.dart';
import 'package:potion_post/game_controller.dart';
import 'package:potion_post/ui/garden_world.dart';
import 'package:potion_post/ui/garden_art.dart';
import 'package:potion_post/ui/stone_route.dart';
import 'package:potion_post/ui/woodland.dart';

import 'game_test.dart' show pack;
import 'ui_test.dart' show FakeAds, setup, settle, capture, disposeGame;

void main() {
  test(
    'World camera covers the screen without magnifying a portrait painting',
    () {
      const viewport = Size(640, 960);
      for (final stage in [
        const Rect.fromLTWH(16, 90, 608, 340),
        const Rect.fromLTWH(16, 200, 608, 500),
      ]) {
        final camera = WorldCamera.fit(viewport, stage);
        expect(camera.environment.width, closeTo(viewport.width, .01));
        expect(camera.environment.height, closeTo(viewport.height, .01));
        expect(camera.environment.contains(Offset.zero), isTrue);
        expect(
          camera.environment.bottomRight.dx,
          greaterThanOrEqualTo(viewport.width),
        );
        expect(
          camera.environment.bottomRight.dy,
          greaterThanOrEqualTo(viewport.height),
        );
      }
    },
  );

  testWidgets(
    'Shop choices apply to Home, Gardens and Orders and survive restart',
    (tester) async {
      final ads = FakeAds(),
          store = MemoryProgressStore(),
          boundary = GlobalKey();
      final game = await setup(
        tester,
        ads,
        store: store,
        boundary: boundary,
        size: const Size(640, 1024),
      );
      for (final order in game.pack.take(10)) game.stars[order.id] = 1;
      game.coins = 6000;
      expect(game.buyCompanion('hedgehog'), PurchaseResult.bought);
      game.selectGarden('lilypond');
      expect(game.buyDecoration('lilypond', 'chimes'), PurchaseResult.bought);
      final balance = game.coins;
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('home-coin-wallet')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('shop-tab-2')));
      await settle(tester);
      final preview = tester.widget<GardenWorld>(
        find.byKey(const ValueKey('shop-world-preview')),
      );
      expect(preview.garden.id, 'lilypond');
      expect(preview.primary, 'hedgehog');
      expect(preview.decorations, {'chimes'});
      final previewArea = tester.getRect(
        find.byKey(const ValueKey('shop-world-preview')),
      );
      final chimes = tester.getRect(
        find.byKey(const ValueKey('world-decoration-chimes')),
      );
      expect(chimes.left, greaterThanOrEqualTo(previewArea.left));
      expect(chimes.right, lessThanOrEqualTo(previewArea.right));
      expect(chimes.top, greaterThanOrEqualTo(previewArea.top));
      expect(chimes.bottom, lessThanOrEqualTo(previewArea.bottom));
      await capture(tester, boundary, 'STONE_SHOP_GARDEN');

      Future<void> pickGarden(String name) async {
        final picker = find.byKey(const ValueKey('decoration-garden-picker'));
        await tester.ensureVisible(picker);
        await tester.tap(
          find.descendant(
            of: picker,
            matching: find.byType(DropdownButton<String>),
          ),
        );
        await settle(tester);
        await tester.ensureVisible(find.text(name).last);
        await tester.tap(find.text(name).hitTestable().last);
        await settle(tester);
      }

      await pickGarden('Moonbloom');
      expect(
        game.garden,
        'lilypond',
        reason: 'Browsing must not select or spend',
      );
      expect(
        tester
            .widget<GardenWorld>(
              find.byKey(const ValueKey('shop-world-preview')),
            )
            .decorations,
        isEmpty,
      );
      final useGarden = find.byKey(const ValueKey('shop-use-garden'));
      await tester.ensureVisible(useGarden);
      await tester.tap(useGarden);
      await settle(tester);
      expect(game.garden, 'moonbloom');
      await pickGarden('Lily Pond');
      await tester.ensureVisible(useGarden);
      await tester.tap(useGarden);
      await settle(tester);
      expect(game.garden, 'lilypond');

      await tester.ensureVisible(find.byKey(const ValueKey('shop-tab-1')));
      await tester.tap(find.byKey(const ValueKey('shop-tab-1')));
      await settle(tester);
      for (final kind in [game.friends.first.kind, 'hedgehog']) {
        final choice = find.byKey(ValueKey('shop-animal-$kind'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await settle(tester);
        expect(game.courier, kind);
      }
      expect(game.coins, balance, reason: 'Reselecting owned items is free');
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      var world = tester.widget<GardenWorld>(find.byType(GardenWorld));
      expect(world.garden.id, 'lilypond');
      expect(world.primary, 'hedgehog');
      expect(world.decorations, {'chimes'});
      final raw = tester.widget<RawImage>(
        find.descendant(
          of: find.byKey(const ValueKey('world-environment')),
          matching: find.byType(RawImage),
        ),
      );
      expect(
        raw.image!.width,
        1024,
        reason: 'Full-size world must not use a low-resolution thumbnail',
      );
      await capture(tester, boundary, 'STONE_SHARP_HOME');

      await tester.tap(find.byKey(const ValueKey('nav-gardens')));
      await settle(tester);
      world = tester.widget<GardenWorld>(find.byType(GardenWorld));
      expect(world.garden.id, 'lilypond');
      expect(world.primary, 'hedgehog');
      await tester.tap(find.byKey(const ValueKey('garden-0')));
      await settle(tester);
      expect(
        tester.widget<GardenWorld>(find.byType(GardenWorld)).garden.id,
        'moonbloom',
      );
      expect(game.garden, 'lilypond');
      await tester.tap(find.byKey(const ValueKey('nav-orders')));
      await settle(tester);
      expect(find.byType(StoneLevel), findsNWidgets(10));
      expect(find.byKey(const ValueKey('orders-stone-trail')), findsOneWidget);
      expect(
        tester
            .widget<LivingAnimal>(
              find.byKey(const ValueKey('orders-selected-companion')),
            )
            .kind,
        'hedgehog',
      );
      expect(
        tester
            .widget<InkWell>(find.byKey(const ValueKey('order-choice-11')))
            .onTap,
        isNull,
      );
      await capture(tester, boundary, 'STONE_SELECTED_ORDERS_TABLET');
      await tester.tap(find.byKey(const ValueKey('order-choice-10')));
      await settle(tester);
      expect(game.level, 10);
      expect(game.unlocked, 10);
      await game.flush();
      final restored = GameController(pack(), store);
      await restored.initialize();
      expect(restored.courier, 'hedgehog');
      expect(restored.garden, 'lilypond');
      expect(restored.decorationsFor('lilypond'), {'chimes'});
      expect(restored.decorationsFor('moonbloom'), isEmpty);
      expect(restored.coins, balance);
      expect(restored.followRouteGarden, isFalse);
      expect(restored.unlocked, 10);
      await restored.flush();
      restored.dispose();
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets('Stone level targets fit small and landscape routes', (
    tester,
  ) async {
    final ads = FakeAds(), boundary = GlobalKey();
    final game = await setup(tester, ads, boundary: boundary);
    for (final size in [
      const Size(320, 568),
      const Size(844, 390),
      const Size(640, 1024),
    ]) {
      tester.view.physicalSize = size;
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('nav-orders')));
      await settle(tester);
      final route = tester.getRect(find.byType(RoutePath));
      for (var i = 0; i < 10; i++) {
        final rect = tester.getRect(find.byKey(ValueKey('order-choice-$i')));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(route.left));
        expect(rect.right, lessThanOrEqualTo(route.right));
        expect(rect.top, greaterThanOrEqualTo(route.top));
        expect(rect.bottom, lessThanOrEqualTo(route.bottom));
      }
      if (size.width == 320)
        await capture(tester, boundary, 'STONE_ORDERS_PHONE');
      if (size.width == 844)
        await capture(tester, boundary, 'STONE_ORDERS_LANDSCAPE');
      if (size.width == 640)
        await capture(tester, boundary, 'STONE_ORDERS_TABLET');
      expect(tester.takeException(), isNull);
    }
    await disposeGame(tester, game, ads);
  });

  testWidgets(
    'Purchased ornaments remain inside the visible stage in compact previews and worlds',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final size in [
        const Size(320, 568),
        const Size(640, 1024),
        const Size(844, 390),
        const Size(500, 180),
      ]) {
        tester.view.physicalSize = size;
        final stage = Rect.fromLTWH(16, 20, size.width - 32, size.height - 40);
        await tester.pumpWidget(
          MaterialApp(
            home: GardenWorld(
              garden: Garden.all.first,
              primary: 'hedgehog',
              secondary: 'rabbit',
              animate: false,
              stageBounds: stage,
              decorations: const {'chimes', 'fountain', 'fireflies'},
            ),
          ),
        );
        await tester.pump();
        for (final id in ['chimes', 'fountain', 'fireflies']) {
          final rect = tester.getRect(
            find.byKey(ValueKey('world-decoration-$id')),
          );
          expect(rect.width, greaterThan(10));
          expect(rect.left, greaterThanOrEqualTo(stage.left));
          expect(rect.right, lessThanOrEqualTo(stage.right));
          expect(rect.top, greaterThanOrEqualTo(stage.top));
          expect(rect.bottom, lessThanOrEqualTo(stage.bottom));
        }
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
