import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/ui/art.dart';
import 'ui_test.dart' show FakeAds, setup, settle, capture, disposeGame;

void main() {
  testWidgets(
    'All five destinations fit phones, tablets and landscape above one persistent banner',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(tester, ads, boundary: boundary);
      const names = ['home', 'daily', 'gardens', 'orders', 'friends'];
      for (final size in [
        const Size(320, 568),
        const Size(360, 640),
        const Size(390, 844),
        const Size(844, 390),
        const Size(758, 1216),
      ]) {
        tester.view.physicalSize = size;
        await settle(tester);
        for (final name in names) {
          await tester.tap(find.byKey(ValueKey('nav-$name')));
          await settle(tester);
          expect(tester.takeException(), isNull, reason: '$name at $size');
          expect(find.byType(Scrollable), findsNothing);
          final ad = tester.getRect(
            find.byKey(const ValueKey('ad-reserved-space')),
          );
          final nav = tester.getRect(
            find.byKey(const ValueKey('woodland-navigation')),
          );
          expect(nav.bottom, lessThanOrEqualTo(ad.top));
          expect(nav.left, greaterThanOrEqualTo(0));
          expect(nav.right, lessThanOrEqualTo(size.width));
          if (size == const Size(390, 844))
            await capture(tester, boundary, 'WOODLAND_${name.toUpperCase()}');
        }
      }
      expect(ads.bannerMounts, 1);
      expect(ads.bannerDisposals, 0);
      expect(ads.watches, 0);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Garden growth, selected looks and next story order survive tab changes',
    (tester) async {
      final ads = FakeAds();
      final game = await setup(tester, ads);
      for (final order in game.pack.take(10)) game.stars[order.id] = 1;
      game.selectGarden('moonbloom');
      await settle(tester);
      expect(find.text('Level 11'), findsOneWidget);
      expect(find.textContaining('Lily Pond · 0/10 delivered'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-gardens')));
      await settle(tester);
      expect(
        find.textContaining('Moonbloom · 10/10 delivered'),
        findsOneWidget,
      );
      expect(find.text('Your garden is in full bloom'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('garden-1')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('use-garden')));
      await settle(tester);
      expect(game.garden, 'lilypond');
      expect(game.level, 0);
      expect(game.coins, 0);
      await tester.tap(find.byKey(const ValueKey('nav-orders')));
      await settle(tester);
      expect(find.byKey(const ValueKey('order-choice-10')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('order-choice-10')));
      await settle(tester);
      expect(game.level, 10);
      expect(find.byKey(const ValueKey('recipe-meter')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Daily customer tickets open the correct saved order and pause resumes it',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(tester, ads, boundary: boundary);
      await tester.tap(find.byKey(const ValueKey('nav-daily')));
      await settle(tester);
      expect(find.byType(CustomerArt), findsAtLeastNWidgets(3));
      await tester.tap(find.byKey(const ValueKey('daily-order-1')));
      await settle(tester);
      expect(game.dailyMode, isTrue);
      expect(game.dailySlot, 1);
      final before = game.exportProgress();
      await tester.tap(find.byTooltip('Menu'));
      await settle(tester);
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'Pause $size');
        final ad = tester.getRect(
          find.byKey(const ValueKey('ad-reserved-space')),
        );
        expect(tester.getRect(find.text('Resume')).bottom, lessThan(ad.top));
      }
      await capture(tester, boundary, 'WOODLAND_PAUSE');
      await tester.tap(find.text('Resume'));
      await settle(tester);
      expect(game.exportProgress(), before);
      expect(ads.bannerMounts, 1);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Friend invitations preview the actual animal and spend once after confirmation',
    (tester) async {
      final ads = FakeAds();
      final game = await setup(tester, ads);
      game.coins = 1000;
      final friend = game.friends[1],
          price = game.priceOfCompanion(game.friends[1].kind);
      await tester.tap(find.byKey(const ValueKey('nav-friends')));
      await settle(tester);
      await tester.tap(find.byKey(ValueKey('friend-${friend.kind}')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('friend-action')));
      await settle(tester);
      expect(find.text('Invite ${friend.name}'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(game.coins, 1000);
      await tester.tap(find.byKey(const ValueKey('friend-action')));
      await settle(tester);
      await tester.tap(find.text('Invite · $price Coins').last);
      await settle(tester);
      expect(game.coins, 1000 - price);
      expect(game.ownsCompanion(friend.kind), isTrue);
      await tester.tap(find.byKey(const ValueKey('friend-action')));
      await settle(tester);
      expect(game.courier, friend.kind);
      expect(game.coins, 1000 - price);
      for (var page = 1; page < (game.friends.length / 6).ceil(); page++) {
        await tester.tap(find.byTooltip('Next friends'));
        await settle(tester);
      }
      expect(
        find.byKey(ValueKey('friend-${game.friends.last.kind}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Animal movement responds to Reduce motion without shifting controls',
    (tester) async {
      final ads = FakeAds();
      final game = await setup(tester, ads);
      final play = tester.getRect(find.byKey(const ValueKey('play-button')));
      final animal = find.descendant(
        of: find.byKey(const ValueKey('world-avatar-0')),
        matching: find.byType(Image),
      );
      final before = tester.getRect(animal);
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.getRect(animal), isNot(before));
      expect(tester.getRect(animal).bottom, closeTo(before.bottom, .01));
      expect(tester.getRect(find.byKey(const ValueKey('play-button'))), play);
      game.setSettings(motionValue: true);
      await settle(tester);
      final still = tester.getRect(animal);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.getRect(animal), still);
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );
}
