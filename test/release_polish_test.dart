import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/main.dart';

import 'game_test.dart' show solve;
import 'ui_test.dart' show FakeAds, setup, settle, capture, disposeGame;

void main() {
  testWidgets('Tablet level controls are large and map stops remain usable', (
    tester,
  ) async {
    final ads = FakeAds(), boundary = GlobalKey();
    final game = await setup(
      tester,
      ads,
      size: const Size(640, 1024),
      boundary: boundary,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('play-button'))).height,
      greaterThanOrEqualTo(80),
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('home-level-label')))
          .style!
          .fontSize,
      greaterThanOrEqualTo(28),
    );
    await capture(tester, boundary, 'RELEASE_TABLET_HOME');
    await tester.tap(find.byKey(const ValueKey('nav-orders')));
    await settle(tester);
    final first = find.byKey(const ValueKey('order-choice-0'));
    expect(tester.getSize(first).shortestSide, greaterThanOrEqualTo(68));
    await capture(tester, boundary, 'RELEASE_TABLET_LEVELS');
    await tester.tap(first);
    await settle(tester);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('game-level-label')))
          .style!
          .fontSize,
      greaterThanOrEqualTo(22),
    );
    expect(tester.takeException(), isNull);
    await disposeGame(tester, game, ads);
  });

  testWidgets(
    'Adaptive banner heights leave every destination and victory usable',
    (tester) async {
      final ads = FakeAds()..bannerHeight = 150;
      final game = await setup(tester, ads, size: const Size(640, 1024));
      for (final size in [
        const Size(640, 1024),
        const Size(320, 568),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        ads.bannerHeight = size.height >= 620
            ? 150
            : size.width < size.height
            ? 50
            : 78;
        ads.notifyListeners();
        await settle(tester);
        for (final tab in ['home', 'daily', 'gardens', 'orders', 'friends']) {
          await tester.tap(find.byKey(ValueKey('nav-$tab')));
          await settle(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: '$tab with ${ads.bannerHeight}px banner at $size',
          );
          expect(
            find.byKey(ValueKey('nav-$tab')).hitTestable(),
            findsOneWidget,
          );
        }
      }
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      solve(game);
      await settle(tester);
      for (final fixture in [
        (const Size(320, 568), 50.0),
        (const Size(844, 390), 78.0),
      ]) {
        tester.view.physicalSize = fixture.$1;
        ads.bannerHeight = fixture.$2;
        ads.notifyListeners();
        await settle(tester);
        expect(
          find.byKey(const ValueKey('delivery-next')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Banner loading and no-fill collapse without replacing the game route',
    (tester) async {
      final ads = FakeAds()..loadedBanner = false;
      final game = await setup(tester, ads);
      expect(find.byKey(const ValueKey('ad-reserved-space')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      final state = tester.state(find.byType(GameScreen));
      expect(find.byKey(const ValueKey('game-level-label')), findsOneWidget);
      ads.loadedBanner = true;
      ads.notifyListeners();
      await settle(tester);
      expect(identical(tester.state(find.byType(GameScreen)), state), isTrue);
      expect(find.byKey(const ValueKey('game-level-label')), findsOneWidget);
      expect(find.byKey(const ValueKey('ad-reserved-space')), findsOneWidget);
      expect(find.textContaining('Advertisement'), findsNothing);
      ads.loadedBanner = false;
      ads.notifyListeners();
      await settle(tester);
      expect(find.byKey(const ValueKey('ad-reserved-space')), findsNothing);
      expect(find.byKey(const ValueKey('game-level-label')), findsOneWidget);
      expect(ads.bannerMounts, 1);
      expect(ads.bannerDisposals, 0);
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Settings use the real brand, save working preferences and fit short screens',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(
        tester,
        ads,
        size: const Size(640, 1024),
        boundary: boundary,
      );
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      expect(find.text('Potion Post Ads Test'), findsNothing);
      final sound = game.sound;
      await tester.tap(find.byKey(const ValueKey('settings-sound')));
      await settle(tester);
      expect(game.sound, !sound);
      await capture(tester, boundary, 'RELEASE_TABLET_SETTINGS');
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.byTooltip('Close').hitTestable(), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Close'));
      await settle(tester);
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('settings-sound')),
            )
            .value,
        !sound,
      );
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Victory keeps next and home reachable on short screens with reduced motion',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(
        tester,
        ads,
        size: const Size(640, 1024),
        boundary: boundary,
      );
      game.setSettings(motionValue: true);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      solve(game);
      await settle(tester);
      expect(find.text('Delivered!'), findsOneWidget);
      expect(game.coins, 20);
      expect(ads.watches, 0);
      await capture(tester, boundary, 'RELEASE_TABLET_DELIVERY');
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('delivery-next')).hitTestable(),
          findsOneWidget,
        );
        expect(find.text('Home').hitTestable(), findsOneWidget);
        final next = tester.getRect(
          find.byKey(const ValueKey('delivery-next')),
        );
        final banner = tester.getRect(
          find.byKey(const ValueKey('ad-reserved-space')),
        );
        expect(next.bottom, lessThan(banner.top));
      }
      await tester.tap(find.byKey(const ValueKey('delivery-next')));
      await settle(tester);
      expect(game.level, 1);
      expect(game.coins, 20);
      await disposeGame(tester, game, ads);
    },
  );
}
