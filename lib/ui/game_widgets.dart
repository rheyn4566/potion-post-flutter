import 'package:flutter/material.dart';
import 'storybook_skin.dart';

/// Tactile, matte game buttons with a shared radius and a small lower rim.
/// The whole face is tappable; keyboard focus and reduced motion are retained.
class BentoButton extends StatefulWidget {
  const BentoButton({
    super.key,
    required this.child,
    required this.color,
    required this.onPressed,
    this.label,
    this.padding = const EdgeInsets.all(12),
    this.radius = 20,
    this.depth = 4,
    this.animate = true,
  });
  final Widget child;
  final Color color;
  final VoidCallback? onPressed;
  final String? label;
  final EdgeInsetsGeometry padding;
  final double radius, depth;
  final bool animate;

  @override
  State<BentoButton> createState() => _BentoButtonState();
}

class _BentoButtonState extends State<BentoButton> {
  bool _held = false;

  void _press(bool value) {
    if (mounted && value != _held) setState(() => _held = value);
  }

  @override
  void didUpdateWidget(BentoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) _held = false;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final face = enabled
        ? widget.color
        : Color.lerp(widget.color, const Color(0xFF34434A), .6)!;
    final border = BorderRadius.circular(widget.radius);
    final duration = Duration(
      milliseconds: widget.animate && !MediaQuery.disableAnimationsOf(context)
          ? 85
          : 0,
    );
    final paper = widget.color.computeLuminance() > .48;
    Widget content = Padding(
      padding: widget.padding,
      child: Opacity(opacity: enabled ? 1 : .45, child: widget.child),
    );
    if (paper)
      content = StoryFrame(
        sprite: 'button-cream',
        opacity: enabled ? 1 : .5,
        child: content,
      );
    Widget button = Semantics(
      button: true,
      enabled: enabled,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.depth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: paper
                ? Colors.transparent
                : Color.lerp(face, Colors.black, .35),
            borderRadius: border,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                offset: Offset(0, widget.depth),
                blurRadius: 5,
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: duration,
            transform: Matrix4.translationValues(
              0,
              _held ? widget.depth * .65 : 0,
              0,
            ),
            decoration: BoxDecoration(
              borderRadius: border,
              boxShadow: paper
                  ? const []
                  : [
                      BoxShadow(
                        color: Color.lerp(face, Colors.black, .35)!,
                        offset: Offset(0, widget.depth),
                        blurRadius: 0,
                      ),
                    ],
              gradient: paper
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(face, Colors.white, .24)!, face],
                    ),
            ),
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: border,
                side: BorderSide(
                  color: paper
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: enabled ? .42 : .06),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onPressed,
                onTapDown: enabled ? (_) => _press(true) : null,
                onTapUp: enabled ? (_) => _press(false) : null,
                onTapCancel: () => _press(false),
                canRequestFocus: enabled,
                splashColor: Colors.white.withValues(alpha: .12),
                highlightColor: Colors.white.withValues(alpha: .04),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.label != null)
      button = Tooltip(message: widget.label!, child: button);
    return button;
  }
}

/// One quiet panel treatment connects the route, album and puzzle controls.
class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color.computeLuminance() > .48 ? Colors.transparent : color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Colors.white.withValues(alpha: .09)),
    ),
    clipBehavior: Clip.none,
    child: StoryFrame(
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class JourneyTrack extends StatelessWidget {
  const JourneyTrack({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });
  final double value, height;
  final Color color;
  @override
  Widget build(BuildContext context) => Semantics(
    value: '${(value.clamp(0, 1) * 100).round()} percent',
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFD7D6BC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB1B99E), width: .7),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(color, Colors.white, .35)!,
                    color,
                    Color.lerp(color, const Color(0xFF409F8A), .24)!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
