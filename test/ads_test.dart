import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:potion_post/ads/game_ads.dart';

class FakeSession implements RewardedSession {
  void Function()? earned, closed, failed;
  int shows = 0, disposals = 0;
  @override
  Future<void> show({
    required void Function() onEarned,
    required void Function() onClosed,
    required void Function() onFailed,
  }) async {
    shows++;
    earned = onEarned;
    closed = onClosed;
    failed = onFailed;
  }

  @override
  void dispose() => disposals++;
}

void main() {
  test(
    'Loading is single-flight and never automatically shows an ad',
    () async {
      final pending = Completer<RewardedSession>(), session = FakeSession();
      var loads = 0;
      final ads = RewardedCoordinator(() {
        loads++;
        return pending.future;
      });
      final first = ads.load();
      await ads.load();
      expect(loads, 1);
      expect(ads.state, RewardAdState.loading);
      pending.complete(session);
      await first;
      expect(ads.state, RewardAdState.ready);
      expect(session.shows, 0);
      ads.dispose();
      expect(session.disposals, 1);
    },
  );

  test('Only earned callback grants once, even if SDK repeats it', () async {
    final session = FakeSession();
    final ads = RewardedCoordinator(() async => session);
    await ads.load();
    var rewards = 0;
    final watched = ads.watch(onEarned: () => rewards++);
    expect(rewards, 0);
    session.earned!();
    session.earned!();
    expect(rewards, 1);
    session.closed!();
    session.closed!();
    await watched;
    expect(session.disposals, 1);
    ads.dispose();
  });

  for (final failure in [false, true]) {
    test(
      '${failure ? 'Failed' : 'Skipped'} ad earns no reward and does not lock another attempt',
      () async {
        final first = FakeSession(), second = FakeSession();
        var loads = 0, rewards = 0;
        final ads = RewardedCoordinator(
          () async => loads++ == 0 ? first : second,
        );
        await ads.load();
        final watched = ads.watch(onEarned: () => rewards++);
        (failure ? first.failed : first.closed)!();
        await watched;
        await Future<void>.delayed(Duration.zero);
        expect(rewards, 0);
        expect(ads.state, RewardAdState.ready);
        expect(second.shows, 0, reason: 'Preloading must not auto-show');
        ads.dispose();
      },
    );
  }

  test('Rapid repeated taps cannot reuse the same ad', () async {
    final session = FakeSession();
    final ads = RewardedCoordinator(() async => session);
    await ads.load();
    final first = ads.watch(onEarned: () {});
    await ads.watch(onEarned: () => fail('duplicate watch'));
    expect(session.shows, 1);
    session.closed!();
    await first;
    ads.dispose();
  });

  test('Load failure permits an explicit retry', () async {
    var attempts = 0;
    final ads = RewardedCoordinator(() async {
      if (attempts++ == 0) throw StateError('offline');
      return FakeSession();
    });
    await ads.load();
    expect(ads.state, RewardAdState.unavailable);
    await ads.load();
    expect(ads.state, RewardAdState.ready);
    ads.dispose();
  });

  test('An ad that loads after disposal is released', () async {
    final pending = Completer<RewardedSession>(), session = FakeSession();
    final ads = RewardedCoordinator(() => pending.future);
    final load = ads.load();
    ads.dispose();
    pending.complete(session);
    await load;
    expect(session.disposals, 1);
    expect(session.shows, 0);
  });

  test(
    'Late earned event after closing is still granted exactly once',
    () async {
      final session = FakeSession();
      final ads = RewardedCoordinator(() async => session);
      await ads.load();
      var rewards = 0;
      final watched = ads.watch(onEarned: () => rewards++);
      session.closed!();
      await watched;
      expect(rewards, 0);
      session.earned!();
      session.earned!();
      expect(rewards, 1);
      ads.dispose();
    },
  );
}
