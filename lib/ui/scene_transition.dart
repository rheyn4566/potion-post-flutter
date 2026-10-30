import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'art_cache.dart';

typedef SceneImageLoader =
    Future<void> Function(BuildContext context, List<ImageProvider> images);

Future<void> _loadScene(BuildContext context, List<ImageProvider> images) =>
    ArtImages.warm(context, images);

/// A single mounted scene avoids duplicate controls and global keys during a
/// transition. The outgoing scene stays underneath a veil while art decodes.
class SceneTransition extends StatefulWidget {
  const SceneTransition({
    super.key,
    required this.scene,
    required this.images,
    required this.child,
    this.animate = true,
    this.onReady,
    this.loadImages = _loadScene,
  });

  final Object scene;
  final List<ImageProvider> images;
  final Widget child;
  final bool animate;
  final VoidCallback? onReady;
  final SceneImageLoader loadImages;

  @override
  State<SceneTransition> createState() => _SceneTransitionState();
}

class _SceneTransitionState extends State<SceneTransition>
    with SingleTickerProviderStateMixin {
  late final _veil = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 260),
  );
  Widget? _visible;
  int _generation = 0;
  bool _started = false, _loading = false, _revealing = false;
  bool _showProgress = false;
  Timer? _progressTimer;
  Size? _viewport;

  bool get _motion =>
      widget.animate && !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewport = MediaQuery.sizeOf(context);
    _viewport ??= viewport;
    if (_loading && _viewport != viewport) {
      // A layout made for the old viewport must not overflow a newly rotated
      // window while its replacement artwork is still being decoded.
      _visible = null;
      _veil.value = 1;
    }
    if (!_started) {
      _started = true;
      if (widget.images.isEmpty) {
        _visible = widget.child;
      } else {
        _prepare();
      }
    }
    if (!_motion && _revealing) {
      _veil.value = 0;
      _revealing = false;
    }
  }

  @override
  void didUpdateWidget(SceneTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    final viewport = MediaQuery.sizeOf(context);
    final resized = _viewport != null && _viewport != viewport;
    _viewport = viewport;
    if (resized && _loading) {
      _visible = null;
      _veil.value = 1;
    }
    if (oldWidget.scene != widget.scene ||
        !listEquals(oldWidget.images, widget.images)) {
      if (resized) {
        _visible = null;
        _veil.value = 1;
      }
      _prepare();
    } else if (!_loading) {
      _visible = widget.child;
    }
    if (!_motion && _revealing) {
      _veil.value = 0;
      _revealing = false;
    }
  }

  void _prepare() {
    final generation = ++_generation;
    _progressTimer?.cancel();
    _loading = true;
    _revealing = false;
    _showProgress = _visible == null;
    _progressTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted && generation == _generation && _loading) {
        setState(() => _showProgress = true);
      }
    });
    final cover = _visible != null && _motion
        ? _veil.forward().orCancel
        : Future<void>.value();
    if (_visible == null) _veil.value = 1;
    unawaited(_reveal(generation, cover));
  }

  Future<void> _reveal(int generation, Future<void> cover) async {
    try {
      await Future.wait([widget.loadImages(context, widget.images), cover]);
    } on TickerCanceled {
      return;
    } catch (error, stack) {
      // A failed asset must not trap navigation behind a permanent loading veil.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Potion Post scene loading',
        ),
      );
    }
    if (!mounted || generation != _generation) return;
    _progressTimer?.cancel();
    setState(() {
      _visible = widget.child;
      _loading = false;
      _showProgress = false;
      _revealing = _motion;
    });
    if (_motion) {
      unawaited(_veil.reverse(from: 1).orCancel.catchError((Object _) {}));
    } else {
      _veil.value = 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _generation) widget.onReady?.call();
    });
  }

  @override
  void dispose() {
    _generation++;
    _progressTimer?.cancel();
    _veil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _veil,
    builder: (context, child) {
      final opacity = Curves.easeInOutCubic.transform(_veil.value);
      return Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF204E48), Color(0xFF123735)],
              ),
            ),
          ),
          if (_visible != null)
            AbsorbPointer(
              absorbing: _loading,
              child: ExcludeSemantics(
                excluding: _loading,
                child: TickerMode(
                  enabled: !_loading,
                  child: Transform.translate(
                    offset: Offset(0, _revealing ? 8 * opacity : 0),
                    child: _visible,
                  ),
                ),
              ),
            ),
          if (opacity > 0)
            IgnorePointer(
              child: ColoredBox(
                key: const ValueKey('scene-loading-veil'),
                color: Color.fromRGBO(18, 55, 53, opacity),
              ),
            ),
          if (_showProgress)
            Center(
              child: Semantics(
                liveRegion: true,
                label: 'Preparing your post',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_post_office_rounded,
                      size: 38,
                      color: Color(0xFFF4DCA7),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Preparing your post…',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFFFFF5DF),
                      ),
                    ),
                    if (_motion) ...[
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 84,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: Color(0xFF9DDFC2),
                          backgroundColor: Color(0x443D7C6C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
