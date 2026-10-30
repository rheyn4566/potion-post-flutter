import 'package:flutter/material.dart';

/// Small secondary illustrations fade in on a genuine first decode. Cached
/// images paint immediately; this does not add a new delay on repeat visits.
Widget revealArtFrame(
  BuildContext context,
  Widget child,
  int? frame,
  bool synchronouslyLoaded,
) {
  if (synchronouslyLoaded || MediaQuery.disableAnimationsOf(context))
    return child;
  return AnimatedOpacity(
    opacity: frame == null ? 0 : 1,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    child: child,
  );
}

/// Preloading and painting must use the same provider and decode dimensions.
/// Keep a small working set rather than decoding every garden at launch.
class ArtImages {
  static const portraitWidth = 512;
  static const thumbnailWidth = 512;
  static final _pending = <Future<void>>{};
  static bool get hasPending => _pending.isNotEmpty;

  static int backgroundWidth(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    // Portrait scenery covers a tall canvas. A width based only on the short
    // edge downsampled the painting before the camera enlarged it again.
    final pixels = (screen.longestSide * (2 / 3) * ratio).clamp(
      screen.shortestSide * ratio,
      double.infinity,
    );
    if (pixels <= 1024) return 1024;
    if (pixels <= 1536) return 1536;
    return 2048;
  }

  static ImageProvider background(BuildContext context, String asset) =>
      ResizeImage(AssetImage(asset), width: backgroundWidth(context));

  static ImageProvider portrait(String kind) => ResizeImage(
    AssetImage('assets/characters/$kind.webp'),
    width: portraitWidth,
  );

  static ImageProvider pose(String asset) =>
      ResizeImage(AssetImage(asset), width: portraitWidth);

  static ImageProvider thumbnail(String asset) =>
      ResizeImage(AssetImage(asset), width: thumbnailWidth);

  static const commonIcons = <String>[
    'home',
    'daily',
    'garden',
    'orders',
    'album',
    'settings',
    'coin-leaf',
    'play',
    'help',
    'pause',
    'undo',
    'hint',
    'reset',
    'mail',
    'check',
    'lock',
    'arrow',
    'star',
    'palette',
  ];

  static Iterable<ImageProvider> get icons =>
      commonIcons.map((name) => AssetImage('assets/icons/$name.png'));

  static Future<void> warm(
    BuildContext context,
    Iterable<ImageProvider> providers, {
    bool Function()? stillWanted,
  }) async {
    // Decode sequentially so speculative work cannot flood a tablet's decoder.
    for (final provider in providers.toSet()) {
      if (!context.mounted || stillWanted?.call() == false) return;
      final task = precacheImage(provider, context);
      _pending.add(task);
      try {
        await task;
      } finally {
        _pending.remove(task);
      }
    }
  }

  /// Also useful for deterministic host rendering without preloading all art.
  static Future<void> waitForPending() async {
    while (_pending.isNotEmpty) {
      await Future.wait(_pending.toList());
    }
  }
}
