import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/ui/garden_art.dart';
import 'package:potion_post/ui/garden_world.dart';
import 'package:potion_post/ui/polished_art.dart';
import 'package:potion_post/ui/storybook_skin.dart';
import 'package:potion_post/ui/world_art.dart';

import 'ui_test.dart' show FakeAds, setup, settle, capture, disposeGame;

void main() {
  testWidgets(
    'Cold tablet tabs reveal decoded artwork within a bounded working set',
    (tester) async {
      PaintingBinding.instance.imageCache.clear();
      final ads = FakeAds();
      final game = await setup(
        tester,
        ads,
        size: const Size(1280, 2048),
        pixelRatio: 2,
      );
      final bytesByTab = <String, int>{};
      for (final tab in ['home', 'daily', 'gardens', 'orders', 'friends']) {
        await tester.tap(find.byKey(ValueKey('nav-$tab')));
        await settle(tester);
        expect(find.text('Preparing your post…'), findsNothing);
        final images = tester.widgetList<RawImage>(find.byType(RawImage));
        expect(images, isNotEmpty, reason: tab);
        for (final image in images) {
          expect(image.image, isNotNull, reason: '$tab revealed undecoded art');
        }
        bytesByTab[tab] = PaintingBinding.instance.imageCache.currentSizeBytes;
        expect(
          bytesByTab[tab],
          lessThan(80 << 20),
          reason: '$tab should not fill the default 100 MiB image cache',
        );
        expect(tester.takeException(), isNull);
      }
      if (Platform.environment['POTION_POST_CAPTURE'] == '1') {
        File('docs/LOADING_CACHE.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert({
            'surface': 'Flutter host widget test; not physical Android RAM',
            'physical_size': [1280, 2048],
            'device_pixel_ratio': 2,
            'maximum_cache_bytes':
                PaintingBinding.instance.imageCache.maximumSizeBytes,
            'cached_decoded_bytes_by_tab': bytesByTab,
            'every_visible_raw_image_decoded_before_reveal': true,
          }),
        );
      }
      await disposeGame(tester, game, ads);
    },
  );

  test(
    'Every route resolves to an opaque-world asset and every courier has a grounded pose',
    () {
      expect(WorldArt.worlds.length, 19);
      for (final garden in Garden.all) {
        expect(
          File(WorldArt.environment(garden.id)).existsSync(),
          isTrue,
          reason: garden.id,
        );
      }
      final poses = Directory(
        'assets/worlds',
      ).listSync().whereType<File>().where((f) => f.path.contains('pose-'));
      expect(poses.length, 26);
    },
  );

  testWidgets(
    'Garden previews change the world without changing the saved selected garden',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(
        tester,
        ads,
        boundary: boundary,
        size: const Size(640, 1024),
      );
      for (final order in game.pack.take(10)) game.stars[order.id] = 1;
      game.selectGarden('lilypond');
      await settle(tester);
      expect(
        tester.widget<GardenWorld>(find.byType(GardenWorld)).garden.id,
        'lilypond',
      );
      expect(find.byKey(const ValueKey('world-environment')), findsOneWidget);
      expect(find.byType(GardenArt), findsNothing);
      await capture(tester, boundary, 'WORLD_LILYPOND_HOME');
      await tester.tap(find.byKey(const ValueKey('nav-gardens')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('garden-1')));
      await settle(tester);
      await capture(tester, boundary, 'WORLD_LILYPOND_GARDENS');
      await tester.tap(find.byKey(const ValueKey('garden-2')));
      await settle(tester);
      expect(
        tester.widget<GardenWorld>(find.byType(GardenWorld)).garden.id,
        'sunpetal',
      );
      expect(game.garden, 'lilypond');
      expect(find.text('Unlock at order 21'), findsOneWidget);
      await capture(tester, boundary, 'WORLD_SUNPETAL_PREVIEW');
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await settle(tester);
      expect(
        tester.widget<GardenWorld>(find.byType(GardenWorld)).garden.id,
        'lilypond',
      );
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'World inhabitants fit the clear scene and keep their ground contact while breathing',
    (tester) async {
      final ads = FakeAds(), boundary = GlobalKey();
      final game = await setup(tester, ads, boundary: boundary);
      for (final size in [
        const Size(320, 568),
        const Size(640, 1024),
        const Size(758, 1216),
        const Size(1024, 768),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        await settle(tester);
        for (final tab in ['home', 'gardens']) {
          await tester.tap(find.byKey(ValueKey('nav-$tab')));
          await settle(tester);
          final widget = tester.widget<GardenWorld>(find.byType(GardenWorld));
          final world = tester.getRect(find.byType(GardenWorld));
          final stage = widget.stageBounds!.shift(world.topLeft);
          for (var i = 0; i < 2; i++) {
            final art = find.descendant(
              of: find.byKey(ValueKey('world-avatar-$i')),
              matching: find.byType(Image),
            );
            final actor = tester.getRect(art);
            final contact = tester.getRect(
              find.byKey(ValueKey('world-contact-$i')),
            );
            expect(actor.bottom, closeTo(contact.center.dy, .01));
            expect(actor.left, greaterThanOrEqualTo(stage.left - .1));
            expect(actor.right, lessThanOrEqualTo(stage.right + .1));
            expect(actor.top, greaterThanOrEqualTo(stage.top - .5));
            expect(actor.bottom, lessThanOrEqualTo(stage.bottom));
            expect(actor.height, lessThanOrEqualTo(stage.height * .49));
            await tester.pump(const Duration(milliseconds: 750));
            expect(tester.getRect(art).bottom, closeTo(actor.bottom, .01));
            expect(
              tester.getRect(find.byKey(ValueKey('world-contact-$i'))),
              contact,
            );
          }
          expect(tester.takeException(), isNull, reason: '$tab at $size');
        }
        if (size == const Size(844, 390)) {
          await capture(tester, boundary, 'WORLD_LANDSCAPE');
        }
      }
      game.setSettings(motionValue: true);
      await settle(tester);
      final actor = find.descendant(
        of: find.byKey(const ValueKey('world-avatar-0')),
        matching: find.byType(Image),
      );
      final still = tester.getRect(actor);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.getRect(actor), still);
      await disposeGame(tester, game, ads);
    },
  );

  testWidgets(
    'Ordinary hub, shop and puzzle controls have no decorative flower clusters',
    (tester) async {
      final ads = FakeAds();
      final game = await setup(tester, ads);
      void noClusters() {
        expect(find.byType(StoryOrnament), findsNothing);
        expect(
          tester
              .widgetList<Image>(find.byType(Image))
              .where(
                (image) =>
                    image.image is AssetImage &&
                    (image.image as AssetImage).assetName == StoryArt.ornament,
              ),
          isEmpty,
        );
      }

      for (final tab in ['home', 'daily', 'gardens', 'orders', 'friends']) {
        await tester.tap(find.byKey(ValueKey('nav-$tab')));
        await settle(tester);
        noClusters();
      }
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('home-coin-wallet')));
      await settle(tester);
      noClusters();
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await settle(tester);
      noClusters();
      expect(find.byKey(const ValueKey('game-courier-panel')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeGame(tester, game, ads);
    },
  );
}
