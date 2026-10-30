import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'polished_art.dart';
import 'art_cache.dart';

/// Quiet paper and mint controls keep decoration inside the game world.
class StoryFrame extends StatelessWidget {
  const StoryFrame({
    super.key,
    required this.child,
    this.sprite = 'panel',
    this.opacity = 1,
  });
  final Widget child;
  final String sprite;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final mint = sprite == 'button' || sprite == 'button-pressed';
    final pressed = sprite == 'button-pressed';
    final dialog = sprite == 'dialog';
    final radius = BorderRadius.circular(
      dialog
          ? 26
          : mint
          ? 22
          : 18,
    );
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: mint
                            ? pressed
                                  ? const [Color(0xFF8DD4B8), Color(0xFF4EAB8D)]
                                  : const [
                                      Color(0xFFC5F3D9),
                                      Color(0xFF8AD6B6),
                                      Color(0xFF64BA9B),
                                    ]
                            : const [Color(0xFFFFF9EA), Color(0xFFF5E9CE)],
                      ),
                      border: Border.all(
                        color: mint
                            ? const Color(0xFF418B76)
                            : const Color(0xFFCFB88B),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0B2829)
                              .withValues(alpha: mint ? .22 : .15),
                          blurRadius: mint ? 7 : 12,
                          offset: Offset(0, pressed ? 1 : 3),
                        ),
                        if (mint)
                          const BoxShadow(
                            color: Color(0xFF397E6C),
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .65),
                          width: .8,
                        ),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: radius,
                    child: CustomPaint(painter: _SurfaceGrain(mint)),
                  ),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class StoryOrnament extends StatelessWidget {
  const StoryOrnament({super.key, this.size = 24, this.quarterTurns = 0});
  final double size;
  final int quarterTurns;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox.square(
      dimension: size,
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: Image.asset(
          StoryArt.ornament,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}

class _SurfaceGrain extends CustomPainter {
  const _SurfaceGrain(this.mint);
  final bool mint;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (mint ? const Color(0xFF286B5A) : const Color(0xFF97774D))
          .withValues(alpha: .035)
      ..strokeWidth = .65
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row * 15 < size.height; row++) {
      for (var column = 0; column * 19 < size.width; column++) {
        final x = column * 19.0 + (row.isEven ? 4 : 12);
        final y = row * 15.0 + (column % 3) * 2 + 4;
        canvas.drawLine(Offset(x, y), Offset(x + 1.5 + (column % 2), y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SurfaceGrain old) => mint != old.mint;
}

/// Five independent native wells resize without flattening a painted strip.
class StoryNavigationFrame extends StatelessWidget {
  const StoryNavigationFrame({super.key, required this.children})
    : assert(children.length == 5);
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 72,
    child: Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF285A54), Color(0xFF123632)],
            ),
            borderRadius: BorderRadius.circular(29),
            border: Border.all(color: const Color(0xFFD4C49D), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x660A2524),
                offset: Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(7, 9, 7, 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(width: 4),
                Expanded(child: children[index]),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Widget storyButtonBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  final disabled = states.contains(WidgetState.disabled);
  final pressed = states.contains(WidgetState.pressed);
  final motion = !MediaQuery.disableAnimationsOf(context);
  return AnimatedSlide(
    duration: Duration(milliseconds: motion ? 80 : 0),
    offset: Offset(0, pressed ? .035 : 0),
    child: StoryFrame(
      sprite: pressed ? 'button-pressed' : 'button',
      opacity: disabled ? .46 : 1,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

/// Keep the regenerated stone dais at its natural image aspect ratio.
class CompanionStage extends StatelessWidget {
  const CompanionStage({super.key, required this.child, this.name});
  final Widget child;
  final String? name;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.min(
        constraints.maxWidth * .78,
        constraints.maxHeight * 1.2,
      );
      final height = width / StoryArt.plinthAspect;
      return SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              width: width,
              height: height,
              child: Image.asset(
                StoryArt.plinth,
                cacheWidth: ArtImages.thumbnailWidth,
                frameBuilder: revealArtFrame,
                key: const ValueKey('companion-natural-plinth'),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: height * .44),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class StoryDialog extends StatelessWidget {
  const StoryDialog({
    super.key,
    required this.child,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 16,
    ),
  });
  final Widget child;
  final EdgeInsets insetPadding;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: insetPadding,
    child: StoryFrame(sprite: 'dialog', child: child),
  );
}
