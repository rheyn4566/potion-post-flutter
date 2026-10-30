import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/puzzle.dart';
import '../game_controller.dart';
import 'art.dart';
import 'woodland.dart';
import 'pour_motion.dart';

class PotionBoard extends StatefulWidget {
  const PotionBoard({
    super.key,
    required this.game,
    required this.accent,
    required this.onBusyChanged,
    required this.onMessage,
  });
  final GameController game;
  final Color accent;
  final ValueChanged<bool> onBusyChanged;
  final ValueChanged<String?> onMessage;
  @override
  State<PotionBoard> createState() => _PotionBoardState();
}

class _PotionBoardState extends State<PotionBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  Pour? _flight;
  Board? _before;
  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  void _message(String text) => widget.onMessage(text);
  Future<void> _tap(int index) async {
    final g = widget.game;
    if (_flight != null || g.submitted) return;
    if (g.selected == index) {
      widget.onMessage(null);
      g.select(null);
      return;
    }
    final guide = g.tutorialPour;
    if (guide != null &&
        ((g.selected == null && index != guide.from) ||
            (g.selected == guide.from && index != guide.to))) {
      _message(
        g.selected == null
            ? 'Tap the glowing bottle.'
            : 'Tap the glowing destination.',
      );
      return;
    }
    if (g.selected == null) {
      if (g.board[index].isEmpty) {
        _message('That bottle is empty.');
        return;
      }
      widget.onMessage(null);
      g.select(index);
      if (g.haptics) unawaited(HapticFeedback.selectionClick());
      return;
    }
    final move = Pour(g.selected!, index);
    if (!Puzzle.canPour(g.board, move, g.order.capacity)) {
      _message('That bottle is full.');
      return;
    }
    widget.onMessage(null);
    widget.onBusyChanged(true);
    if (!g.reduceMotion && !MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _flight = move;
        _before = copyBoard(g.board);
      });
      try {
        await _animation.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
      if (!mounted) return;
    }
    g.performPour(move);
    if (g.sound) unawaited(SystemSound.play(SystemSoundType.click));
    if (g.haptics) unawaited(HapticFeedback.lightImpact());
    if (mounted) {
      setState(() {
        _flight = null;
        _before = null;
      });
      widget.onBusyChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final g = widget.game, count = g.board.length;
      final compact = c.maxHeight < 430;
      final columns =
          c.maxHeight >= 380 && count >= 4 && c.maxWidth <= c.maxHeight * 1.4
          ? (count == 5 ? 3 : 2)
          : count;
      final rows = (count / columns).ceil(), cellW = c.maxWidth / columns;
      final goalH = compact ? 46.0 : 54.0,
          labelH = compact ? 22.0 : 26.0,
          rowGap = compact ? 18.0 : 24.0;
      final maxBottleW = math.min(
        cellW * .70,
        c.maxWidth >= 520 ? 144.0 : 114.0,
      );
      final bottleH = math.min(
        maxBottleW * 2.10,
        math.max(30.0, c.maxHeight / rows - goalH - labelH - rowGap),
      );
      final bottleW = math.min(maxBottleW, bottleH / 2.10);
      final blockH = goalH + bottleH + labelH;
      // Keep recipes beside the prompt and rows together on tall screens.
      // Spare height belongs to the garden, rather than growing cell gaps.
      final contentH = rows * blockH + (rows - 1) * rowGap;
      final top = math.min(12.0, math.max(0.0, (c.maxHeight - contentH) / 2));
      Offset location(int i) => Offset(
        (i % columns +
                .5 +
                (i ~/ columns == rows - 1
                    ? (columns - (count - (rows - 1) * columns)) / 2
                    : 0)) *
            cellW,
        top + (i ~/ columns) * (blockH + rowGap) + goalH + bottleH / 2,
      );
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final t = _flight == null ? 0.0 : _animation.value,
              transfer = ((t - .40) / .36).clamp(0.0, 1.0);
          final children = <Widget>[];
          for (var i = 0; i < count; i++) {
            final center = location(i),
                original = _before == null ? g.board[i] : _before![i];
            final destination = _flight?.to == i, source = _flight?.from == i;
            final layers = destination
                ? [...original, _before![_flight!.from].last]
                : original;
            final customer = i < g.order.targets.length,
                matched =
                    customer &&
                    Puzzle.equalBottle(g.board[i], g.order.targets[i]);
            final name = customer
                ? g.order.customers[i].name
                : 'Spare ${i - g.order.targets.length + 1}';
            final selected = g.selected == i && _flight == null;
            final cue = g.cue,
                cueIndex = cue == null
                    ? null
                    : g.selected == cue.from
                    ? cue.to
                    : cue.from;
            final highlighted = cueIndex == i && _flight == null && !g.ready;
            children.add(
              Positioned(
                left: center.dx - cellW / 2,
                top: center.dy - bottleH / 2 - goalH,
                width: cellW,
                height: blockH,
                child: Semantics(
                  key: ValueKey('bottle-$i'),
                  label:
                      '${i + 1}. $name. ${original.isEmpty ? 'Empty' : original.map((c) => liquidNames[c]).join(', ')} from bottom to top. ${customer ? 'Recipe, top to bottom: ${g.order.targets[i].reversed.map((c) => liquidNames[c]).join(', ')}' : ''}',
                  button: true,
                  selected: selected,
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _flight == null && !g.submitted
                          ? () => _tap(i)
                          : null,
                      child: Column(
                        children: [
                          SizedBox(
                            height: goalH,
                            child: customer
                                ? Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: matched
                                          ? Woodland.cream
                                          : Woodland.cream,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: matched
                                            ? widget.accent.withValues(
                                                alpha: .5,
                                              )
                                            : Colors.white.withValues(
                                                alpha: .08,
                                              ),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CustomerArt(
                                            kind: g.order.customers[i].kind,
                                            size: compact
                                                ? 24
                                                : count == 5
                                                ? 32
                                                : 40,
                                          ),
                                          const SizedBox(width: 3),
                                          Semantics(
                                            label:
                                                'Recipe, top to bottom: ${g.order.targets[i].reversed.map((c) => liquidNames[c]).join(', ')}',
                                            child: SizedBox(
                                              width: count == 5 ? 22 : 26,
                                              height: compact ? 34 : 42,
                                              child: Column(
                                                children: g
                                                    .order
                                                    .targets[i]
                                                    .reversed
                                                    .map(
                                                      (color) => Expanded(
                                                        child: Container(
                                                          width: count == 5
                                                              ? 22
                                                              : 26,
                                                          margin:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 1,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                liquidColors[color],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                          alignment:
                                                              Alignment.center,
                                                          child: LiquidSymbol(
                                                            type: color,
                                                            size: compact
                                                                ? 8
                                                                : 10,
                                                            color: const Color(
                                                              0xFF273347,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            matched
                                                ? Icons.check_circle_rounded
                                                : Icons.arrow_downward_rounded,
                                            size: 13,
                                            color: matched
                                                ? widget.accent
                                                : const Color(0xFFAAB9CB),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      'MIXING BOTTLE',
                                      style: TextStyle(
                                        fontSize: count == 5 ? 7 : 8,
                                        letterSpacing: .6,
                                        color: const Color(0xFF91AAB3),
                                      ),
                                    ),
                                  ),
                          ),
                          AnimatedContainer(
                            duration: Duration(
                              milliseconds: g.reduceMotion ? 0 : 150,
                            ),
                            transform: Matrix4.translationValues(
                              0,
                              selected ? -22 : 0,
                              0,
                            ),
                            child: SizedBox(
                              height: bottleH,
                              width: cellW,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  if (selected || highlighted)
                                    Container(
                                      width: math.min(cellW - 8, bottleW + 14),
                                      height: bottleH + 6,
                                      decoration: BoxDecoration(
                                        color: widget.accent.withValues(
                                          alpha: .08,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: widget.accent.withValues(
                                            alpha: .65,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  Opacity(
                                    opacity: source ? 0 : 1,
                                    child: BottleArt(
                                      key: ValueKey('jar-art-$i'),
                                      layers: layers,
                                      capacity: g.order.capacity,
                                      topFraction: destination ? transfer : 1,
                                      size: Size(bottleW, bottleH),
                                    ),
                                  ),
                                  if (highlighted)
                                    Positioned(
                                      right: math.max(
                                        3,
                                        (cellW - bottleW) / 2 - 8,
                                      ),
                                      top: bottleH * .35,
                                      child: Icon(
                                        Icons.touch_app_rounded,
                                        color: widget.accent,
                                        size: 26,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: labelH,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (matched)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 13,
                                        color: widget.accent,
                                      ),
                                    ),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: customer
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: customer
                                          ? const Color(0xFFFFF6E9)
                                          : const Color(0xFFAAB9CB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          if (_flight != null) {
            final from = _flight!.from,
                to = _flight!.to,
                origin = location(from),
                dest = location(to);
            final pose = PourPose.at(
              progress: t,
              origin: origin,
              destination: dest,
              bottleHeight: bottleH,
              boardWidth: c.maxWidth,
            );
            final position = pose.center, angle = pose.angle;
            if (t > .40 && t < .76)
              children.add(
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const ValueKey('pour-stream'),
                      painter: _StreamPainter(
                        pose.mouth,
                        dest + Offset(0, -bottleH * .42),
                        liquidColors[_before![from].last],
                      ),
                    ),
                  ),
                ),
              );
            children.add(
              Positioned(
                key: const ValueKey('flight-bottle'),
                left: position.dx - bottleW / 2,
                top: position.dy - bottleH / 2,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: angle,
                    child: BottleArt(
                      layers: _before![from],
                      capacity: g.order.capacity,
                      topFraction: 1 - transfer,
                      size: Size(bottleW, bottleH),
                    ),
                  ),
                ),
              ),
            );
          }
          return Stack(clipBehavior: Clip.none, children: children);
        },
      );
    },
  );
}

class _StreamPainter extends CustomPainter {
  _StreamPainter(this.start, this.end, this.color);
  final Offset start, end;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx,
        start.dy + (end.dy - start.dy) * .5,
        end.dx,
        end.dy - (end.dy - start.dy) * .25,
        end.dx,
        end.dy,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StreamPainter old) =>
      old.start != start || old.end != end || old.color != color;
}
