import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'garden_art.dart';
import 'garden_decorations.dart';
import 'world_art.dart';
import 'art_cache.dart';

/// The scenery, ground contacts, props and foreground share one projection.
/// Interface layout only supplies the clear part of the scene for its camera.
class WorldCamera {
  const WorldCamera(this.scale, this.origin);
  final double scale;
  final Offset origin;
  static const designSize = Size(1000, 1500);
  Rect get environment => origin & (designSize * scale);
  Offset project(Offset point) => origin + point * scale;
  Rect projectRect(Rect rect) => Rect.fromLTWH(
    origin.dx + rect.left * scale,
    origin.dy + rect.top * scale,
    rect.width * scale,
    rect.height * scale,
  );

  factory WorldCamera.fit(Size viewport, Rect stage) {
    final focus = const Offset(515, 900);
    final target = Offset(stage.center.dx, stage.bottom - stage.height * .12);
    // Cover the viewport once; moving the stage must not zoom into the art.
    final scale = math.max(
      viewport.width / designSize.width,
      viewport.height / designSize.height,
    );
    final natural = designSize * scale;
    final desired = target - focus * scale;
    final origin = Offset(
      desired.dx
          .clamp(math.min(0, viewport.width - natural.width), 0)
          .toDouble(),
      desired.dy
          .clamp(math.min(0, viewport.height - natural.height), 0)
          .toDouble(),
    );
    return WorldCamera(scale, origin);
  }
}

class GardenWorld extends StatefulWidget {
  const GardenWorld({
    super.key,
    required this.garden,
    required this.primary,
    required this.secondary,
    required this.animate,
    this.stageBounds,
    this.decorations = const {},
    this.growth = 0,
  });
  final Garden garden;
  final String primary, secondary;
  final bool animate;
  final Rect? stageBounds;
  final Set<String> decorations;
  final int growth;

  @override
  State<GardenWorld> createState() => _GardenWorldState();
}

class _GardenWorldState extends State<GardenWorld>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(GardenWorld oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final active =
        widget.animate &&
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (active && !_idle.isAnimating) _idle.repeat();
    if (!active) _idle.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.biggest;
          final screen = Offset.zero & viewport;
          var stage = widget.stageBounds;
          if (stage == null ||
              stage.width < 40 ||
              stage.height < 20 ||
              !screen.contains(stage.topLeft) ||
              !screen.contains(stage.bottomRight)) {
            stage = Rect.fromLTWH(
              16,
              70,
              math.max(40, viewport.width - 32),
              math.max(40, viewport.height * .52),
            );
          }
          final camera = WorldCamera.fit(viewport, stage);
          final worldId = WorldArt.worldId(widget.garden.id);
          final asset = WorldArt.environment(widget.garden.id);
          Rect decorationBounds(String id) {
            final projected = camera.projectRect(switch (id) {
              'chimes' => const Rect.fromLTWH(70, 620, 190, 190),
              'fountain' => const Rect.fromLTWH(760, 880, 185, 185),
              _ => const Rect.fromLTWH(320, 690, 420, 420),
            });
            final area = stage!;
            final edge = math.min(
              math.min(projected.width, math.max(1.0, area.shortestSide - 12)),
              math.min(
                area.width * (id == 'fireflies' ? .7 : .24),
                area.height * (id == 'fireflies' ? .8 : .42),
              ),
            );
            return Rect.fromLTWH(
              projected.left
                  .clamp(area.left + 4, area.right - edge - 4)
                  .toDouble(),
              projected.top
                  .clamp(area.top + 4, area.bottom - edge - 4)
                  .toDouble(),
              edge,
              edge,
            );
          }

          final avatarSize = math.min(
            210 * camera.scale,
            math.min(stage.height * .48, stage.width * .29),
          );
          final positions = [
            camera.project(const Offset(405, 900)),
            camera.project(const Offset(655, 928)),
          ];
          final kinds = [widget.primary, widget.secondary];
          final actors = <Rect>[];
          for (var i = 0; i < positions.length; i++) {
            final size = avatarSize * (i == 0 ? 1 : .88);
            final point = positions[i];
            final x = point.dx
                .clamp(stage.left + size * .5, stage.right - size * .5)
                .toDouble();
            final y = point.dy
                .clamp(stage.top + size, stage.bottom - 5)
                .toDouble();
            actors.add(Rect.fromLTWH(x - size * .5, y - size, size, size));
          }
          Widget environment({Key? key}) => Positioned.fromRect(
            rect: camera.environment,
            child: Image.asset(
              asset,
              cacheWidth: ArtImages.backgroundWidth(context),
              frameBuilder: revealArtFrame,
              key: key,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          );

          final world = Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: Stack(
                  children: [
                    environment(key: const ValueKey('world-environment')),
                  ],
                ),
              ),
              for (final decoration in widget.decorations)
                Positioned.fromRect(
                  key: ValueKey('world-decoration-$decoration'),
                  rect: decorationBounds(decoration),
                  child: GardenDecorations(
                    decorations: {decoration},
                    preview: true,
                  ),
                ),
              if (widget.growth >= 2)
                Positioned.fromRect(
                  rect: camera.environment,
                  child: CustomPaint(painter: _WorldBloomLights(widget.growth)),
                ),
              for (var i = 0; i < actors.length; i++)
                Positioned.fromRect(
                  rect: Rect.fromCenter(
                    center: Offset(
                      actors[i].center.dx + actors[i].width * .11,
                      actors[i].bottom + actors[i].height * .012,
                    ),
                    width: actors[i].width * .83,
                    height: actors[i].height * .16,
                  ),
                  child: const CustomPaint(painter: _WorldCastShadowPainter()),
                ),
              for (var i = 0; i < actors.length; i++)
                Positioned.fromRect(
                  rect: Rect.fromCenter(
                    center: Offset(actors[i].center.dx, actors[i].bottom),
                    width: actors[i].width * .55,
                    height: actors[i].height * .09,
                  ),
                  child: CustomPaint(
                    key: ValueKey('world-contact-$i'),
                    painter: const _WorldContactPainter(),
                  ),
                ),
              AnimatedBuilder(
                animation: _idle,
                builder: (context, child) => Stack(
                  children: [
                    for (var i = 0; i < actors.length; i++)
                      Positioned.fromRect(
                        rect: actors[i],
                        child: RepaintBoundary(
                          child: Transform.scale(
                            key: ValueKey('world-avatar-$i'),
                            alignment: Alignment.bottomCenter,
                            scaleY:
                                widget.animate &&
                                    !MediaQuery.disableAnimationsOf(context)
                                ? 1 +
                                      math.sin(_idle.value * math.pi * 4 + i) *
                                          .007
                                : 1,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(switch (worldId) {
                                'moonbloom' => const Color(0xFFD4DFE6),
                                'frostfern' => const Color(0xFFE5EDF2),
                                _ => const Color(0xFFF3F2E5),
                              }, BlendMode.modulate),
                              child: Image.asset(
                                WorldArt.pose(kinds[i]),
                                cacheWidth: ArtImages.portraitWidth,
                                frameBuilder: revealArtFrame,
                                alignment: Alignment.bottomCenter,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                gaplessPlayback: true,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Reuse the exact projected painting for foreground occluders.
              // Matching coordinates prevent a seam or a second scene layer.
              RepaintBoundary(
                child: ClipPath(
                  clipper: _WorldForegroundClip(camera),
                  child: Stack(children: [environment()]),
                ),
              ),
              for (var i = 0; i < actors.length; i++)
                Positioned.fromRect(
                  rect: Rect.fromLTWH(
                    actors[i].center.dx - actors[i].width * .19,
                    actors[i].bottom - 2,
                    actors[i].width * .38,
                    5,
                  ),
                  child: CustomPaint(
                    painter: _GroundEdgePainter(
                      WorldArt.groundColor(widget.garden.id),
                    ),
                  ),
                ),
            ],
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              if (worldId == widget.garden.id)
                world
              else
                ColorFiltered(
                  colorFilter: gardenLookFilter(widget.garden.id),
                  child: world,
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, .14, .58, 1],
                    colors: [
                      Color(0x55102E2C),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xE5123536),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// A quiet collection backdrop gives the large portrait a clear display role.
class WorldGalleryBackdrop extends StatelessWidget {
  const WorldGalleryBackdrop({super.key, required this.garden});
  final Garden garden;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: ColorFiltered(
            colorFilter: WorldArt.worldId(garden.id) == garden.id
                ? const ColorFilter.mode(Colors.white, BlendMode.modulate)
                : gardenLookFilter(garden.id),
            child: Image.asset(
              WorldArt.environment(garden.id),
              cacheWidth: ArtImages.backgroundWidth(context),
              frameBuilder: revealArtFrame,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              excludeFromSemantics: true,
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x80153735), Color(0xAA173B37), Color(0xF0183536)],
            ),
          ),
        ),
      ],
    ),
  );
}

class _WorldBloomLights extends CustomPainter {
  const _WorldBloomLights(this.growth);
  final int growth;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = const Color(0x99FCE7A5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < (growth >= 3 ? 14 : 6); i++) {
      final point = Offset(
        size.width * (.16 + (i * 37 % 67) / 100),
        size.height * (.32 + (i * 17 % 32) / 100),
      );
      canvas.drawCircle(point, 1.6, glow);
    }
  }

  @override
  bool shouldRepaint(_WorldBloomLights old) => old.growth != growth;
}

class _WorldContactPainter extends CustomPainter {
  const _WorldContactPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * .88,
      height: size.height * .5,
    );
    canvas.drawOval(
      oval,
      Paint()
        ..color = const Color(0x441C291C)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(1.5, size.height * .25),
        ),
    );
    canvas.drawOval(
      oval.deflate(size.height * .14),
      Paint()
        ..color = const Color(0x28172518)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  @override
  bool shouldRepaint(_WorldContactPainter oldDelegate) => false;
}

class _WorldCastShadowPainter extends CustomPainter {
  const _WorldCastShadowPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width * .9,
        height: size.height * .55,
      ),
      Paint()
        ..color = const Color(0x32182B1B)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(2, size.height * .25),
        ),
    );
  }

  @override
  bool shouldRepaint(_WorldCastShadowPainter old) => false;
}

class _GroundEdgePainter extends CustomPainter {
  const _GroundEdgePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .62)
      ..strokeWidth = .8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final x = size.width * ((i * 17 % 73) / 100 + .08);
      canvas.drawLine(
        Offset(x, size.height * .7),
        Offset(x + (i.isEven ? 1 : -1), size.height * (i.isEven ? .3 : .1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GroundEdgePainter old) => color != old.color;
}

class _WorldForegroundClip extends CustomClipper<Path> {
  const _WorldForegroundClip(this.camera);
  final WorldCamera camera;
  @override
  Path getClip(Size size) {
    final points = [
      [
        const Offset(0, 1050),
        const Offset(90, 1140),
        const Offset(175, 1360),
        const Offset(140, 1500),
        const Offset(0, 1500),
      ],
      [
        const Offset(1000, 1070),
        const Offset(920, 1190),
        const Offset(845, 1400),
        const Offset(880, 1500),
        const Offset(1000, 1500),
      ],
    ];
    final path = Path();
    for (final polygon in points) {
      path.addPolygon(polygon.map(camera.project).toList(), true);
    }
    return path;
  }

  @override
  bool shouldReclip(_WorldForegroundClip old) =>
      camera.scale != old.camera.scale || camera.origin != old.camera.origin;
}
