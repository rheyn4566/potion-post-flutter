import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art.dart';
import 'game_icon.dart';
import 'garden_art.dart';

class HomeScene extends StatelessWidget {
  const HomeScene({
    super.key,
    required this.accent,
    required this.garden,
    this.growth = 0,
    this.courier,
    this.decorations = const {},
  });
  final Color accent;
  final Garden garden;
  final int growth;
  final String? courier;
  final Set<String> decorations;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scale = math.min(
        math.min(c.maxWidth, 540) / 360,
        c.maxHeight / 280,
      );
      return Center(
        child: SizedBox(
          width: 360 * scale,
          height: 280 * scale,
          child: FittedBox(
            child: SizedBox(
              width: 360,
              height: 280,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GardenArt(
                      garden: garden,
                      growth: growth,
                      decorations: decorations,
                    ),
                  ),
                  Positioned(
                    right: 15,
                    bottom: 17,
                    child: CustomerArt(
                      kind: courier ?? garden.courier,
                      size: 128,
                    ),
                  ),
                  Positioned(
                    left: 40,
                    top: 58,
                    child: Transform.rotate(
                      angle: -.15,
                      child: const GameIcon('mail', size: 42),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
