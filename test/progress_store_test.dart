import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/data/file_progress_store.dart';
import 'package:potion_post/data/progress_store.dart';
import 'package:potion_post/domain/puzzle.dart';
import 'package:potion_post/game_controller.dart';

import 'game_test.dart' show pack;

class FailingStore implements ProgressStore {
  bool failLoad = false, failWrite = false;
  Map<String, dynamic>? data;
  int writes = 0;
  @override
  Future<Map<String, dynamic>?> load() async {
    if (failLoad) throw const FormatException('Damaged');
    return data;
  }

  @override
  Future<void> save(Map<String, dynamic> value) async {
    writes++;
    if (failWrite) throw const FileSystemException('Disk unavailable');
    data = Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
  }
}

class DelayedStore extends FailingStore {
  Completer<Map<String, dynamic>?>? pending;
  int reads = 0;
  @override
  Future<Map<String, dynamic>?> load() {
    reads++;
    return pending?.future ?? super.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('potion-save-');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'Recovery stays protected while reading, including repeated Retry taps',
    () async {
      final seed = GameController(pack(), MemoryProgressStore());
      await seed.initialize();
      for (final order in seed.pack.take(4)) seed.stars[order.id] = 3;
      seed.chooseOrder(4);
      await seed.flush();
      final store = DelayedStore()..failLoad = true;
      final game = GameController(pack(), store);
      await game.initialize();
      store.pending = Completer<Map<String, dynamic>?>();
      final retry = game.retryLoad();
      final repeated = game.retryLoad();
      expect(game.loadFailed, isTrue);
      game.persist();
      await game.flush();
      expect(store.writes, 0);
      expect(store.reads, 2);
      store.pending!.complete(
        Map<String, dynamic>.from(jsonDecode(seed.exportProgress()) as Map),
      );
      await retry;
      await repeated;
      expect(game.loadFailed, isFalse);
      expect(game.level, 4);
      await game.flush();
      game.dispose();
      seed.dispose();
    },
  );

  test(
    'Saved story, daily route, partial board and tools survive separate process termination',
    () async {
      final game = GameController(pack(), MemoryProgressStore());
      await game.initialize();
      for (final order in game.pack.take(12)) game.stars[order.id] = 3;
      game.chooseOrder(12);
      game.coins = game.priceOfCompanion(game.friends.last.kind) + 2500;
      game.buyDecoration('moonbloom', 'chimes');
      game.buyCompanion(game.friends.last.kind);
      game.buyToolRefill(GameTool.hint);
      game.claimCoinOffer(game.createCoinOffer());
      game.selectGarden('lilypond');
      game.changePage(GamePage.daily);
      game.chooseOrder(1);
      game.performPour(game.order.solution.first);
      final before = copyBoard(game.board), id = game.order.id;
      final input = File('${directory.path}/input.json');
      await input.writeAsString(game.exportProgress());
      final saved = await Process.run('dart', [
        'run',
        'tool/progress_probe.dart',
        'write',
        directory.path,
        input.path,
      ]);
      expect(saved.exitCode, 0, reason: '${saved.stderr}');
      final loaded = await Process.run('dart', [
        'run',
        'tool/progress_probe.dart',
        'read',
        directory.path,
      ]);
      expect(loaded.exitCode, 0, reason: '${loaded.stderr}');
      final restored = GameController(pack(), FileProgressStore(directory));
      await restored.initialize();
      expect(restored.loadFailed, isFalse);
      expect(restored.level, 12);
      expect(restored.unlocked, 12);
      expect(restored.dailyMode, isTrue);
      expect(restored.dailySlot, 1);
      expect(restored.order.id, id);
      expect(restored.coins, 1960);
      expect(restored.decorationsFor('moonbloom'), {'chimes'});
      expect(restored.ownsCompanion(game.friends.last.kind), isTrue);
      expect(restored.courier, game.friends.last.kind);
      expect(restored.hintsAvailable, 6);
      expect(restored.coinAdsRemaining, 2);
      expect(restored.coinHistory.first.amount, 20);
      expect(restored.garden, 'lilypond');
      expect(Puzzle.equalBoard(restored.board, before), isTrue);
      expect(restored.moves, 1);
      expect(jsonDecode(loaded.stdout as String)['level'], 12);
      await game.flush();
      await restored.flush();
      game.dispose();
      restored.dispose();
    },
  );

  test(
    'Legacy preferences migrate once and file checkpoints become authoritative',
    () async {
      final legacy = MemoryProgressStore(),
          game = GameController(pack(), legacy);
      await game.initialize();
      for (final order in game.pack.take(10)) game.stars[order.id] = 3;
      game.chooseOrder(10);
      game.coins = 200;
      await game.flush();
      final store = LocalProgressStore(
        directory: () async => directory,
        legacy: legacy,
      );
      expect((await store.load())!['level'], 10);
      legacy.data!['level'] = 0;
      expect(
        (await LocalProgressStore(
          directory: () async => directory,
          legacy: legacy,
        ).load())!['level'],
        10,
      );
      expect(
        await File('${directory.path}/potion-post-save-a.json').exists(),
        isTrue,
      );
      expect(
        await File('${directory.path}/potion-post-save-b.json').exists(),
        isTrue,
      );
      game.dispose();
    },
  );

  test(
    'A valid-JSON checksum mismatch recovers the second copy without a reset',
    () async {
      final game = GameController(pack(), FileProgressStore(directory));
      await game.initialize();
      for (final order in game.pack.take(8)) game.stars[order.id] = 3;
      game.chooseOrder(8);
      await game.flush();
      final a = File('${directory.path}/potion-post-save-a.json');
      final envelope =
          jsonDecode(await a.readAsString()) as Map<String, dynamic>;
      final payload =
          jsonDecode(envelope['payload'] as String) as Map<String, dynamic>;
      payload['level'] = 0;
      envelope['payload'] = jsonEncode(payload);
      await a.writeAsString(jsonEncode(envelope), flush: true);
      final restored = GameController(pack(), FileProgressStore(directory));
      await restored.initialize();
      expect(restored.loadFailed, isFalse);
      expect(restored.level, 8);
      expect(restored.stars.length, 8);
      game.dispose();
      restored.dispose();
    },
  );

  test(
    'A flushed pending checkpoint survives interruption just before rename',
    () async {
      final store = FileProgressStore(directory),
          game = GameController(pack(), MemoryProgressStore());
      await game.initialize();
      final data = jsonDecode(game.exportProgress()) as Map<String, dynamic>;
      await store.save(data);
      final old = await File(
        '${directory.path}/potion-post-save-a.json',
      ).readAsString();
      data['coins'] = 777;
      await store.save(data);
      final pending = await File(
        '${directory.path}/potion-post-save-a.json',
      ).readAsString();
      await File(
        '${directory.path}/potion-post-save-a.json',
      ).writeAsString(old);
      await File(
        '${directory.path}/potion-post-save-b.json',
      ).writeAsString(old);
      await File(
        '${directory.path}/potion-post-save-a.tmp',
      ).writeAsString(pending, flush: true);
      expect((await FileProgressStore(directory).load())!['coins'], 777);
      game.dispose();
    },
  );

  test(
    'Unreadable saves block zero-state writes and allow retry recovery',
    () async {
      final store = FailingStore()..failLoad = true;
      final game = GameController(pack(), store);
      await game.initialize();
      expect(game.loadFailed, isTrue);
      game.persist();
      await game.flush();
      expect(store.writes, 0);
      store.failLoad = false;
      await game.retryLoad();
      expect(game.loadFailed, isFalse);
      game.persist();
      await game.flush();
      expect(store.writes, 1);
      game.dispose();
    },
  );

  test(
    'Failed writes retain current progress and flush retries the latest checkpoint',
    () async {
      final store = FailingStore()..failWrite = true;
      final game = GameController(pack(), store);
      await game.initialize();
      game.coins = 91;
      game.persist();
      await game.flush();
      expect(game.saveFailed, isTrue);
      store.failWrite = false;
      game.coins = 92;
      await game.flush();
      expect(game.saveFailed, isFalse);
      expect(store.data!['coins'], 92);
      game.dispose();
    },
  );

  test(
    'Android storage uses the app-private directory supplied by MainActivity',
    () async {
      const channel = MethodChannel('potion_post/progress');
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'supportDirectory');
            calls++;
            return directory.path;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final store = LocalProgressStore(legacy: MemoryProgressStore());
      final game = GameController(pack(), store);
      await game.initialize();
      game.persist();
      await game.flush();
      expect(calls, 1);
      expect((await FileProgressStore(directory).load())!['level'], 0);
      game.dispose();
    },
  );
  test(
    'Android legacy migration reads the existing save through the native channel',
    () async {
      final seed = GameController(pack(), MemoryProgressStore());
      await seed.initialize();
      for (final order in seed.pack.take(6)) seed.stars[order.id] = 3;
      seed.chooseOrder(6);
      await seed.flush();
      final raw = seed.exportProgress(), calls = <String>[];
      const channel = MethodChannel('potion_post/progress');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return call.method == 'supportDirectory' ? directory.path : raw;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final game = GameController(pack(), LocalProgressStore());
      await game.initialize();
      expect(game.loadFailed, isFalse);
      expect(game.level, 6);
      expect(game.stars.length, 6);
      expect(calls, ['supportDirectory', 'legacyProgress']);
      expect((await FileProgressStore(directory).load())!['level'], 6);
      await game.flush();
      game.dispose();
      seed.dispose();
    },
  );
}
