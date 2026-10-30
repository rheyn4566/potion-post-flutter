import 'package:flutter/material.dart';

import 'game_widgets.dart';

class RecipeMeter extends StatelessWidget {
  const RecipeMeter({
    super.key,
    required this.matched,
    required this.total,
    required this.moves,
    required this.color,
    required this.onTap,
  });
  final int matched, total, moves;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '$matched of $total recipe layers matched. $moves pours. Tap for scoring.',
    excludeSemantics: true,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          key: const ValueKey('compact-move-counter'),
          children: [
            Text(
              'Recipe $matched/$total',
              style: const TextStyle(fontSize: 10, height: 1.1),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: JourneyTrack(
                value: total == 0 ? 0 : matched / total,
                color: color,
                height: 7,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '$moves ${moves == 1 ? 'pour' : 'pours'}',
              style: const TextStyle(fontSize: 10, height: 1.1),
            ),
          ],
        ),
      ),
    ),
  );
}
