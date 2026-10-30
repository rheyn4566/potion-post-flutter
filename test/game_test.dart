import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/data/progress_store.dart';
import 'package:potion_post/domain/puzzle.dart';
import 'package:potion_post/domain/catalog.dart';
import 'package:potion_post/game_controller.dart';

List<PotionOrder> pack() =>
    (jsonDecode(File('assets/orders.json').readAsStringSync()) as List)
        .map((v) => PotionOrder.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();

void solve(GameController g) {
  for (final move in Puzzle.solve(g.board, g.order)!) {
    g.performPour(move);
  }
}

void main() {
  test(
    'Garden colors unlock with routes, persist, and never spend stamps or reset a puzzle',
    () async {
      final orders = pack(), store = MemoryProgressStore();
      final g = GameController(orders, store);
      await g.initialize();
      expect(gardenThemes.keys.toSet(), orders.map((o) => o.garden).toSet());
      g.selectGarden('lilypond');
      g.selectGarden('unknown');
      expect(g.garden, 'moonbloom');
      for (final order in orders.take(10)) g.stars[order.id] = 3;
      g.chooseOrder(10);
      expect(g.garden, 'lilypond');
      g.performPour(g.order.solution.first);
      final board = copyBoard(g.board), coins = g.coins, moves = g.moves;
      g.selectGarden('moonbloom');
      expect(g.theme, 'moonlight');
      expect(g.level, 10);
      expect(g.moves, moves);
      expect(g.coins, coins);
      expect(Puzzle.equalBoard(g.board, board), isTrue);
      await g.flush();
      final restored = GameController(orders, store);
      await restored.initialize();
      expect(restored.garden, 'moonbloom');
      expect(restored.level, 10);
      expect(Puzzle.equalBoard(restored.board, board), isTrue);
      restored.changePage(GamePage.daily);
      expect(
        restored.garden,
        'moonbloom',
        reason: 'Daily visits preserve the chosen home garden',
      );
      await restored.flush();
      restored.dispose();
      g.dispose();
    },
  );

  test(
    'Legacy color-shop saves migrate to their story garden without losing rewards',
    () async {
      final orders = pack(), store = MemoryProgressStore();
      final old = GameController(orders, store);
      await old.initialize();
      for (final order in orders.take(40)) old.stars[order.id] = 3;
      old.coins = 845;
      old.chooseOrder(40);
      old.performPour(old.order.solution.first);
      final board = copyBoard(old.board);
      await old.flush();
      store.data!.remove('garden');
      store.data!['theme'] = 'ember';
      old.dispose();
      final restored = GameController(orders, store);
      await restored.initialize();
      expect(restored.garden, 'lavender');
      expect(restored.theme, 'lavender');
      expect(restored.coins, 845);
      expect(restored.stars.length, 40);
      expect(Puzzle.equalBoard(restored.board, board), isTrue);
      final saved =
          jsonDecode(restored.exportProgress()) as Map<String, dynamic>;
      saved['garden'] = 'wishinggarden';
      await restored.restoreProgress(jsonEncode(saved));
      expect(
        restored.garden,
        'lavender',
        reason: 'A locked saved garden cannot bypass progress',
      );
      await restored.flush();
      restored.dispose();
    },
  );

  test('All 1480 orders retain valid shortest solution certificates', () {
    final orders = pack();
    expect(orders.length, 1480);
    for (final order in orders) {
      var board = copyBoard(order.start);
      for (final move in order.solution) {
        expect(Puzzle.canPour(board, move, order.capacity), isTrue);
        board = Puzzle.pour(board, move, order.capacity);
      }
      expect(Puzzle.solved(board, order), isTrue, reason: order.id);
      expect(
        Puzzle.solve(order.start, order)!.length,
        order.par,
        reason: order.id,
      );
    }
  });

  test(
    '80000 randomized pours conserve contents and do not mutate prior boards',
    () {
      final random = Random(7621);
      for (final order in pack()) {
        var board = copyBoard(order.start);
        List<int> inventory(Board b) => b.expand((x) => x).toList()..sort();
        final original = inventory(board);
        for (var turn = 0; turn < 80; turn++) {
          final move = Pour(
            random.nextInt(board.length),
            random.nextInt(board.length),
          );
          if (!Puzzle.canPour(board, move, order.capacity)) continue;
          final before = copyBoard(board),
              next = Puzzle.pour(board, move, order.capacity);
          expect(Puzzle.equalBoard(board, before), isTrue);
          expect(inventory(next), original);
          board = next;
        }
      }
    },
  );

  test(
    'A reward requires delivery, grants once and survives restart/export',
    () async {
      final store = MemoryProgressStore(), orders = pack();
      final g = GameController(orders, store);
      await g.initialize();
      final id = g.order.id;
      expect(g.claimAdBonus(id), isFalse);
      solve(g);
      expect(g.deliver().firstDelivery, isTrue);
      expect(g.coins, 20);
      expect(g.claimAdBonus(id), isTrue);
      expect(g.coins, 40);
      expect(g.claimAdBonus(id), isFalse);
      expect(g.claimAdBonus('unknown'), isFalse);
      final saved = g.exportProgress();
      await g.flush();
      g.dispose();
      final restored = GameController(orders, store);
      await restored.initialize();
      expect(restored.coins, 40);
      expect(restored.canClaimAdBonus(id), isFalse);
      await restored.restoreProgress(saved);
      restored.restart();
      solve(restored);
      expect(restored.deliver().firstDelivery, isFalse);
      expect(restored.claimAdBonus(id), isFalse);
      expect(restored.coins, 40);
      await restored.flush();
      restored.dispose();
    },
  );

  test(
    'A delayed reward remains assigned to the delivered order after advancing',
    () async {
      final g = GameController(pack(), MemoryProgressStore());
      await g.initialize();
      final id = g.order.id;
      solve(g);
      g.deliver();
      g.nextOrder();
      final next = g.order.id;
      expect(g.claimAdBonus(id), isTrue);
      expect(g.claimAdBonus(next), isFalse);
      expect(g.coins, 40);
      expect(g.level, 1);
      expect(g.moves, 0);
      await g.flush();
      g.dispose();
    },
  );

  test(
    'Legacy saves without ads retain stamps, settings, stars and partial pours',
    () async {
      final store = MemoryProgressStore(), orders = pack();
      final old = GameController(orders, store);
      await old.initialize();
      solve(old);
      old.deliver();
      old.nextOrder();
      old.performPour(old.order.solution.first);
      old.setSettings(motionValue: true);
      final board = copyBoard(old.board);
      await old.flush();
      store.data!.remove('rewardedBonuses');
      old.dispose();
      final g = GameController(orders, store);
      await g.initialize();
      expect(g.coins, 20);
      expect(g.level, 1);
      expect(g.moves, 1);
      expect(g.reduceMotion, isTrue);
      expect(Puzzle.equalBoard(g.board, board), isTrue);
      expect(g.rewardedBonuses, isEmpty);
      expect(g.stars.length, 1);
      g.undo();
      expect(g.moves, 0);
      await g.flush();
      g.dispose();
    },
  );

  test(
    'Final order and daily rewards still work with optional ad bonuses',
    () async {
      final orders = pack(), g = GameController(pack(), MemoryProgressStore());
      await g.initialize();
      for (final order in orders.take(orders.length - 1)) {
        g.stars[order.id] = 3;
      }
      g.chooseOrder(orders.length - 1);
      solve(g);
      g.deliver();
      expect(g.delivered, orders.length);
      expect(g.claimAdBonus(g.order.id), isTrue);
      g.changePage(GamePage.daily);
      for (var i = 0; i < 3; i++) {
        g.chooseOrder(i);
        solve(g);
        g.deliver();
        expect(g.claimAdBonus(g.order.id), i < 2);
      }
      expect(g.dailyDelivered, 3);
      expect(g.coins, 180);
      expect(g.streak, 1);
      await g.flush();
      g.dispose();
    },
  );
}
