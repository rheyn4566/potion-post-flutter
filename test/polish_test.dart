import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/ui/polished_art.dart';
import 'package:potion_post/ui/storybook_skin.dart';

import 'ui_test.dart' show FakeAds, setup, settle, capture, disposeGame;

String? assetName(ImageProvider provider) {
  if (provider is ResizeImage) return assetName(provider.imageProvider);
  return provider is AssetImage ? provider.assetName : null;
}

void main() {
  testWidgets(
    'Native controls keep ornament images off ordinary buttons and panels',
    (tester) async {
      for (final height in [72.0, 220.0, 480.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 340,
                height: height,
                child: const StoryFrame(child: SizedBox.expand()),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(StoryOrnament), findsNothing);
        expect(find.byType(Image), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'The regenerated character dais retains its natural proportions',
    (tester) async {
      for (final size in [
        const Size(280, 160),
        const Size(360, 340),
        const Size(620, 500),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox.fromSize(
                size: size,
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    CompanionStage(child: SizedBox.square(dimension: 120)),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(StoryArt.plinth),
            tester.element(find.byType(CompanionStage)),
          ),
        );
        await tester.pump();
        final painted = tester.getSize(
          find.byKey(const ValueKey('companion-natural-plinth')),
        );
        expect(
          painted.width / painted.height,
          closeTo(StoryArt.plinthAspect, .001),
        );
        expect(painted.width, lessThanOrEqualTo(size.width));
        expect(painted.height, lessThanOrEqualTo(size.height));
        final stage = tester.getRect(find.byType(CompanionStage));
        final plinth = tester.getRect(
          find.byKey(const ValueKey('companion-natural-plinth')),
        );
        expect(plinth.left, greaterThanOrEqualTo(stage.left));
        expect(plinth.right, lessThanOrEqualTo(stage.right));
        expect(plinth.bottom, lessThanOrEqualTo(stage.bottom));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Daily uses one continuous full-screen plate and compact tappable tickets',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(tester, ads, boundary: boundary);
      for (final size in [
        const Size(320, 568),
        const Size(640, 1024),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('nav-daily')));
        await settle(tester);
        final backgrounds = tester
            .widgetList<Image>(find.byType(Image))
            .where((image) => assetName(image.image) == StoryArt.daily);
        expect(backgrounds.length, 1);
        final backdrop = tester.getRect(
          find.byKey(const ValueKey('daily-office-background')),
        );
        expect(backdrop.left, 0);
        expect(backdrop.top, 0);
        expect(backdrop.width, size.width);
        final ad = tester.getRect(
          find.byKey(const ValueKey('ad-reserved-space')),
        );
        for (var index = 0; index < 3; index++) {
          final ticket = tester.getRect(
            find.byKey(ValueKey('daily-order-$index')),
          );
          expect(ticket.width, greaterThanOrEqualTo(48));
          expect(ticket.height, greaterThanOrEqualTo(48));
          expect(ticket.bottom, lessThan(ad.top));
        }
        if (size == const Size(320, 568))
          await capture(tester, boundary, 'POLISHED_DAILY_SMALL');
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('daily-order-1')));
      await settle(tester);
      expect(game.dailyMode, isTrue);
      expect(game.dailySlot, 1);
      expect(ads.bannerMounts, 1);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Gameplay backdrop fills the viewport outside the constrained controls',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(tester, ads, boundary: boundary);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      for (final size in [
        const Size(390, 844),
        const Size(758, 1216),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 20);
        await settle(tester);
        final backdrop = tester.getRect(
          find.byKey(const ValueKey('gameplay-full-bleed-backdrop')),
        );
        final ad = tester.getRect(
          find.byKey(const ValueKey('ad-reserved-space')),
        );
        expect(backdrop.left, 0);
        expect(backdrop.top, 0);
        expect(backdrop.width, size.width);
        expect(backdrop.bottom, ad.top);
        final image = tester.widget<Image>(
          find.byKey(const ValueKey('visible-garden-backdrop')),
        );
        expect(assetName(image.image), StoryArt.workbench);
        expect(image.fit, BoxFit.cover);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPadding();
      tester.view.resetViewPadding();
      expect(ads.bannerMounts, 1);
      await disposeGame(tester, game, ads);
    },
  );
}
