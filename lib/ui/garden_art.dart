import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/economy.dart';
import 'garden_decorations.dart';
import 'world_art.dart';
import 'polished_art.dart';
import 'art_cache.dart';

class Garden {
  const Garden(
    this.id,
    this.name,
    this.courier,
    this.firstOrder, {
    this.count = 10,
    this.tagline = 'A little magic, delivered',
    this.tint = const Color(0xFFB8D9BD),
  });
  final String id, name, courier;
  final int firstOrder;
  final int count;
  final String tagline;
  final Color tint;
  int get lastOrder => firstOrder + count - 1;
  int growthFor(int delivered) => gardenGrowthStage(delivered, count);
  int growthAt(int stage) => stage == 3 ? count : (count * stage * 3 + 9) ~/ 10;
  static const all = [
    Garden('moonbloom', 'Moonbloom', 'dragon', 0),
    Garden('lilypond', 'Lily Pond', 'frog', 10),
    Garden('sunpetal', 'Sunpetal', 'fox', 20),
    Garden('stargrove', 'Starlit Grove', 'moth', 30),
    Garden('lavender', 'Lavender Hollow', 'cat', 40),
    Garden('coralcove', 'Coral Cove', 'frog', 50),
    Garden('frostfern', 'Frostfern', 'moth', 60),
    Garden('amberorchard', 'Amber Orchard', 'fox', 70),
    Garden(
      'clovermeadow',
      'Clover Meadow',
      'rabbit',
      80,
      count: 40,
      tagline: 'A little luck in every letter',
      tint: Color(0xFFEDC6F2),
    ),
    Garden(
      'owlwood',
      'Owlwood',
      'owl',
      120,
      count: 40,
      tagline: 'Follow the lanterns after dusk',
      tint: Color(0xFFF5D58C),
    ),
    Garden(
      'bramblebrook',
      'Bramble Brook',
      'raccoon',
      160,
      count: 40,
      tagline: 'Secret paths beside the stream',
      tint: Color(0xFFEDA4B7),
    ),
    Garden(
      'otterbend',
      'Otter Bend',
      'otter',
      200,
      count: 40,
      tagline: 'Postcards from the riverbank',
      tint: Color(0xFFFFD590),
    ),
    Garden(
      'hazelhedge',
      'Hazel Hedge',
      'hedgehog',
      240,
      count: 40,
      tagline: 'Small parcels, big adventures',
      tint: Color(0xFFF4AE93),
    ),
    Garden(
      'cherryveil',
      'Cherry Veil',
      'cat',
      280,
      count: 40,
      tagline: 'Petals carry your wishes',
      tint: Color(0xFFFFF0D7),
    ),
    Garden(
      'mushroomvale',
      'Mushroom Vale',
      'frog',
      320,
      count: 40,
      tagline: 'Tiny doors and taller tales',
      tint: Color(0xFFE9AFC1),
    ),
    Garden(
      'buttercupbay',
      'Buttercup Bay',
      'otter',
      360,
      count: 40,
      tagline: 'Sunshine by the water',
      tint: Color(0xFFFFE192),
    ),
    Garden(
      'silverwillow',
      'Silver Willow',
      'moth',
      400,
      count: 40,
      tagline: 'A quiet place to find your glow',
      tint: Color(0xFFE9D5FF),
    ),
    Garden(
      'rosegate',
      'Rosegate',
      'rabbit',
      440,
      count: 40,
      tagline: 'Every bloom has a message',
      tint: Color(0xFFF4A6BD),
    ),
    Garden(
      'fireflyfen',
      'Firefly Fen',
      'frog',
      480,
      count: 40,
      tagline: 'A thousand tiny lights lead home',
      tint: Color(0xFFE7ED9A),
    ),
    Garden(
      'peachterrace',
      'Peach Terrace',
      'fox',
      520,
      count: 40,
      tagline: 'Warm wishes above the clouds',
      tint: Color(0xFFFFC6AE),
    ),
    Garden(
      'crystalcreek',
      'Crystal Creek',
      'owl',
      560,
      count: 40,
      tagline: 'Where the water catches stars',
      tint: Color(0xFFD6BFFF),
    ),
    Garden(
      'fernwhisper',
      'Fernwhisper',
      'hedgehog',
      600,
      count: 40,
      tagline: 'Listen for the forest post',
      tint: Color(0xFFE2C4FF),
    ),
    Garden(
      'dandeliondrift',
      'Dandelion Drift',
      'rabbit',
      640,
      count: 40,
      tagline: 'Send your wishes on the breeze',
      tint: Color(0xFFFFF1B2),
    ),
    Garden(
      'cinnamonwood',
      'Cinnamon Wood',
      'raccoon',
      680,
      count: 40,
      tagline: 'A cozy stop on a winding route',
      tint: Color(0xFFF4C77F),
    ),
    Garden(
      'auroraglen',
      'Aurora Glen',
      'moth',
      720,
      count: 40,
      tagline: 'Letters under dancing skies',
      tint: Color(0xFFE8B8F2),
    ),
    Garden(
      'poppylantern',
      'Poppy Lantern',
      'fox',
      760,
      count: 40,
      tagline: 'Let the warm lights guide you',
      tint: Color(0xFFF6A18C),
    ),
    Garden(
      'bluebellhollow',
      'Bluebell Hollow',
      'owl',
      800,
      count: 40,
      tagline: 'A melody in every delivery',
      tint: Color(0xFFBDB4F4),
    ),
    Garden(
      'jadeisles',
      'Jade Isles',
      'otter',
      840,
      count: 40,
      tagline: 'One more bridge to a new friend',
      tint: Color(0xFFF7D9A5),
    ),
    Garden(
      'honeydewheights',
      'Honeydew Heights',
      'hedgehog',
      880,
      count: 40,
      tagline: 'Sweet views from the hilltop',
      tint: Color(0xFFFFDA99),
    ),
    Garden(
      'twilightorchid',
      'Twilight Orchid',
      'cat',
      920,
      count: 40,
      tagline: 'Special deliveries after sunset',
      tint: Color(0xFFE6AFDD),
    ),
    Garden(
      'wishinggarden',
      'Wishing Garden',
      'dragon',
      960,
      count: 40,
      tagline: 'Every journey begins with a wish',
      tint: Color(0xFFFFE4A2),
    ),
    Garden(
      'lanternleaf',
      'Lanternleaf Conservatory',
      'turtle',
      1000,
      count: 40,
      tagline: 'A little wonder under glass',
      tint: Color(0xFFC4E8D3),
    ),
    Garden(
      'copperwind',
      'Copperwind Millgarden',
      'beaver',
      1040,
      count: 40,
      tagline: 'Letters on a gentle breeze',
      tint: Color(0xFFEBD1A0),
    ),
    Garden(
      'cactuscrescent',
      'Cactus Crescent',
      'chameleon',
      1080,
      count: 40,
      tagline: 'Small blossoms, warm wishes',
      tint: Color(0xFFF1C19C),
    ),
    Garden(
      'cloudberry',
      'Cloudberry Airpost',
      'bat',
      1120,
      count: 40,
      tagline: 'Special deliveries above the clouds',
      tint: Color(0xFFC3E6E8),
    ),
    Garden(
      'porcelainteacourt',
      'Porcelain Teacourt',
      'koala',
      1160,
      count: 40,
      tagline: 'A warm cup and a kind letter',
      tint: Color(0xFFDAEAD5),
    ),
    Garden(
      'emberglow',
      'Emberglow Springs',
      'capybara',
      1200,
      count: 40,
      tagline: 'Slow down beside the springs',
      tint: Color(0xFFEFC7B3),
    ),
    Garden(
      'honeycombhaven',
      'Honeycomb Haven',
      'badger',
      1240,
      count: 40,
      tagline: 'The sweetest stop on your route',
      tint: Color(0xFFF2DB9A),
    ),
    Garden(
      'rootcellar',
      'Rootcellar Retreat',
      'squirrel',
      1280,
      count: 40,
      tagline: 'Good things grow from little seeds',
      tint: Color(0xFFC3DDA3),
    ),
    Garden(
      'pumpkinpatch',
      'Pumpkin Lantern Patch',
      'mouse',
      1320,
      count: 40,
      tagline: 'A cozy harvest delivery',
      tint: Color(0xFFF3C08B),
    ),
    Garden(
      'raindroproof',
      'Raindrop Roofgarden',
      'duck',
      1360,
      count: 40,
      tagline: 'A bright thought after the rain',
      tint: Color(0xFFC4DCE8),
    ),
    Garden(
      'saffronspice',
      'Saffron Spiceyard',
      'ferret',
      1400,
      count: 40,
      tagline: 'A pinch of magic in every parcel',
      tint: Color(0xFFE3C2EA),
    ),
    Garden(
      'ribbonwind',
      'Ribbonwind Festival Garden',
      'deer',
      1440,
      count: 40,
      tagline: 'Let your little wishes fly',
      tint: Color(0xFFF0C8DA),
    ),
  ];
  static Garden forId(String id) =>
      all.firstWhere((g) => g.id == id, orElse: () => all.first);
  static Garden forLevel(int level) =>
      all.lastWhere((g) => level >= g.firstOrder, orElse: () => all.first);
}

/// Preserve image alpha while giving each saved garden look a distinct palette.
ColorFilter gardenLookFilter(String id) {
  final i = Garden.all.indexWhere((g) => g.id == id);
  final angle = i <= 0 ? 0.0 : ((i * 47) % 170 - 85) * .009;
  final c = math.cos(angle), s = math.sin(angle);
  return ColorFilter.matrix([
    .213 + c * .787 - s * .213,
    .715 - c * .715 - s * .715,
    .072 - c * .072 + s * .928,
    0,
    0,
    .213 - c * .213 + s * .143,
    .715 + c * .285 + s * .140,
    .072 - c * .072 - s * .283,
    0,
    0,
    .213 - c * .213 - s * .787,
    .715 - c * .715 + s * .715,
    .072 + c * .928 + s * .072,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
}

class GardenArt extends StatelessWidget {
  const GardenArt({
    super.key,
    required this.garden,
    this.fit = BoxFit.cover,
    this.growth = 0,
    this.decorations = const {},
  });
  final Garden garden;
  final BoxFit fit;
  final int growth;
  final Set<String> decorations;
  @override
  Widget build(BuildContext context) {
    // Every picker shows the same world painting and palette used on Home.
    Widget painting = Image.asset(
      WorldArt.environment(garden.id),
      key: ValueKey('garden-art-${garden.id}'),
      cacheWidth: ArtImages.thumbnailWidth,
      frameBuilder: revealArtFrame,
      fit: fit,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.high,
    );
    if (WorldArt.worldId(garden.id) != garden.id) {
      painting = ColorFiltered(
        colorFilter: gardenLookFilter(garden.id),
        child: painting,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          painting,
          if (growth >= 2)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _GardenBloomLight(growth: growth)),
              ),
            ),
          if (decorations.isNotEmpty)
            Positioned.fill(child: GardenDecorations(decorations: decorations)),
        ],
      ),
    );
  }
}

class _GardenBloomLight extends CustomPainter {
  _GardenBloomLight({required this.growth});
  final int growth;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < (growth == 3 ? 18 : 7); i++) {
      final point = Offset(
        size.width * (.12 + ((i * 37) % 77) / 100),
        size.height * (.35 + ((i * 23) % 49) / 100),
      );
      canvas.drawCircle(
        point,
        2.1,
        Paint()
          ..color = const Color(0xFFFFE6A5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_GardenBloomLight old) => old.growth != growth;
}

/// Faint foliage sits behind controls; the active puzzle keeps a clear center.
class GardenBackdrop extends StatelessWidget {
  const GardenBackdrop({super.key, required this.garden, required this.accent});
  final Garden garden;
  final Color accent;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          StoryArt.workbench,
          cacheWidth: ArtImages.backgroundWidth(context),
          frameBuilder: revealArtFrame,
          key: const ValueKey('visible-garden-backdrop'),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
        const ColoredBox(color: Color(0x45123239)),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x006D4228), Color(0xEE6D4228)],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
