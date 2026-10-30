import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/data/progress_store.dart';
import 'package:potion_post/domain/puzzle.dart';
import 'package:potion_post/game_controller.dart';
import 'game_test.dart' show pack;

void main() {
  test(
    'Daily hints and undos are limited; restarting and failed actions do not charge tools',
    () async {
      final game = GameController(pack(), MemoryProgressStore());
      await game.initialize();
      for (final order in game.pack.take(2)) game.stars[order.id] = 3;
      game.chooseOrder(2);
      expect(game.hintsAvailable, 3);
      expect(game.undosAvailable, 5);
      expect(game.undo(), isFalse);
      expect(game.undosAvailable, 5);
      for (var i = 0; i < 3; i++) {
        expect(await game.showHint(), isNotNull);
        expect(
          await game.showHint(),
          isNotNull,
          reason: 'Re-reading the current hint does not charge twice',
        );
        expect(game.hintsAvailable, 2 - i);
        game.restart();
      }
      expect(await game.showHint(), isNull);
      expect(game.hintsAvailable, 0);
      for (var i = 0; i < 5; i++) {
        game.performPour(game.order.solution.first);
        expect(game.undo(), isTrue);
      }
      game.performPour(game.order.solution.first);
      final before = copyBoard(game.board);
      expect(game.undo(), isFalse);
      expect(Puzzle.equalBoard(game.board, before), isTrue);
      game.restart();
      expect(game.moves, 0);
      expect(game.hintsAvailable, 0);
      expect(game.undosAvailable, 0);
      await game.flush();
      game.dispose();
    },
  );

  test(
    'Earned tool refills grant once, survive restart and retain banked rewards after midnight',
    () async {
      var now = DateTime(2026, 10, 19, 10);
      final store = MemoryProgressStore();
      final g = GameController(pack(), store, clock: () => now);
      await g.initialize();
      for (final order in g.pack.take(2)) g.stars[order.id] = 3;
      g.chooseOrder(2);
      for (var i = 0; i < 3; i++) {
        await g.showHint();
        g.restart();
      }
      final hintId = g.createToolRefillOffer(GameTool.hint);
      final undoId = g.createToolRefillOffer(GameTool.undo);
      expect(g.claimToolRefill(GameTool.hint, 'hint-made-up'), isFalse);
      expect(g.claimToolRefill(GameTool.undo, hintId), isFalse);
      expect(g.claimToolRefill(GameTool.hint, hintId), isTrue);
      expect(g.claimToolRefill(GameTool.hint, hintId), isFalse);
      expect(g.claimToolRefill(GameTool.undo, undoId), isTrue);
      expect(g.hintsAvailable, 3);
      expect(g.undosAvailable, 10);
      await g.flush();
      g.dispose();
      final restored = GameController(pack(), store, clock: () => now);
      await restored.initialize();
      expect(restored.hintsAvailable, 3);
      expect(restored.undosAvailable, 10);
      expect(restored.claimToolRefill(GameTool.hint, hintId), isFalse);
      final newId = restored.createToolRefillOffer(GameTool.hint);
      expect(newId, isNot(hintId));
      now = DateTime(2026, 10, 20, 0, 1);
      restored.refreshDate();
      expect(
        restored.hintsAvailable,
        6,
        reason: 'New daily free tools plus banked ad reward',
      );
      expect(restored.undosAvailable, 10);
      final saved =
          jsonDecode(restored.exportProgress()) as Map<String, dynamic>;
      expect((saved['tools'] as Map)['claims'], containsAll([hintId, undoId]));
      await restored.flush();
      restored.dispose();
    },
  );

  test(
    'First-order tutorial guidance never consumes the daily hint allowance',
    () async {
      final game = GameController(pack(), MemoryProgressStore());
      await game.initialize();
      expect(await game.showHint(), isNotNull);
      expect(game.hintsAvailable, 3);
      await game.flush();
      game.dispose();
    },
  );
}
