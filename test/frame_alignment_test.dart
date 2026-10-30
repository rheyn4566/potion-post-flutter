import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/ui/storybook_skin.dart';
import 'package:potion_post/ui/polished_art.dart';

import 'game_test.dart' show solve;
import 'ui_test.dart' show FakeAds, setup, settle, capture, disposeGame;

void expectValidImageSlices(WidgetTester tester) {
  for (final image in tester.widgetList<RawImage>(find.byType(RawImage))) {
    final slice = image.centerSlice;
    if (slice == null) continue;
    expect(image.image, isNotNull);
    final source = Size(
      image.image!.width / image.scale,
      image.image!.height / image.scale,
    );
    expect(slice.left, greaterThanOrEqualTo(0));
    expect(slice.top, greaterThanOrEqualTo(0));
    expect(slice.right, lessThanOrEqualTo(source.width));
    expect(slice.bottom, lessThanOrEqualTo(source.height));
    expect(slice.width, greaterThan(0));
    expect(slice.height, greaterThan(0));
  }
}

void main() {
  testWidgets(
    'Native button, panel and dialog surfaces cover the complete face at Android density',
    (tester) async {
      tester.view.physicalSize = const Size(1240, 2020);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final fixture in [
        ('button', const Size(340, 52)),
        ('panel', const Size(340, 78)),
        ('dialog', const Size(320, 380)),
      ]) {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: boundary,
                  child: StoryFrame(
                    sprite: fixture.$1,
                    child: SizedBox.fromSize(size: fixture.$2),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(StoryArt.ornament),
            tester.element(find.byType(StoryFrame)),
          ),
        );
        await tester.pump();
        expectValidImageSlices(tester);
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2.75);
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          for (final fraction in [.2, .5, .8]) {
            final x = (image.width * fraction).floor();
            final y = image.height ~/ 2;
            final offset = (y * image.width + x) * 4;
            expect(
              pixels.getUint8(offset + 3),
              greaterThan(230),
              reason: '${fixture.$1} must cover its face at $fraction width',
            );
            expect(pixels.getUint8(offset + 1), greaterThan(150));
          }
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Uploaded Android screenshot dimensions align all five tabs, gameplay and pause above the persistent banner',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(
        tester,
        ads,
        boundary: boundary,
        size: const Size(1280, 2048),
      );
      tester.view.devicePixelRatio = 2;
      tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
      tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 32);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      game.coins = 160;
      for (final order in game.pack.take(6)) game.stars[order.id] = 1;
      game.chooseOrder(6);
      game.setSettings(motionValue: true);
      await settle(tester);
      for (final tab in ['home', 'daily', 'gardens', 'orders', 'friends']) {
        await tester.tap(find.byKey(ValueKey('nav-$tab')));
        await settle(tester);
        expectValidImageSlices(tester);
        final nav = tester.getRect(
          find.byKey(const ValueKey('woodland-navigation')),
        );
        for (final name in ['home', 'daily', 'gardens', 'orders', 'friends']) {
          final target = tester.getRect(find.byKey(ValueKey('nav-$name')));
          expect(target.width, greaterThanOrEqualTo(48));
          expect(target.height, greaterThanOrEqualTo(48));
          expect(nav.contains(target.center), isTrue);
          final label = tester.getRect(
            find.text('${name[0].toUpperCase()}${name.substring(1)}').last,
          );
          expect(target.contains(label.topLeft), isTrue);
          expect(target.contains(label.bottomRight), isTrue);
        }
        await capture(tester, boundary, 'ALIGNED_${tab.toUpperCase()}');
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('home-coin-wallet')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('shop-tab-2')));
      await settle(tester);
      await capture(tester, boundary, 'POLISHED_SHOP');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      expect(game.level, 6);
      expectValidImageSlices(tester);
      await capture(tester, boundary, 'ALIGNED_GAMEPLAY');
      final beforePause = game.exportProgress();
      await tester.tap(find.byTooltip('Menu'));
      await settle(tester);
      expectValidImageSlices(tester);
      await capture(tester, boundary, 'ALIGNED_PAUSE');
      final panel = tester.getRect(find.byKey(const ValueKey('pause-popup')));
      final resume = tester.getRect(find.text('Resume'));
      expect(panel.contains(resume.center), isTrue);
      await tester.tap(find.text('Resume'));
      await settle(tester);
      expect(game.exportProgress(), beforePause);
      solve(game);
      await settle(tester);
      expect(find.text('Delivered!'), findsOneWidget);
      expectValidImageSlices(tester);
      await capture(tester, boundary, 'ALIGNED_DELIVERY');
      expect(ads.bannerMounts, 1);
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );
}
