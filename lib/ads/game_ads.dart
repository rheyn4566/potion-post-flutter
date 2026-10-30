import 'dart:async';

import 'package:flutter/material.dart';

enum RewardAdState { disabled, loading, ready, unavailable, showing }

class AdBannerFrame extends StatelessWidget {
  const AdBannerFrame({super.key, required this.child, this.height = 50});
  final Widget child;
  final double height;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('ad-reserved-space'),
      height: height + 12,
      child: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

abstract class GameAds extends ChangeNotifier {
  bool get enabled;

  /// Loading/no-fill banners occupy no screen space. Keep the loader mounted.
  bool get bannerVisible => false;
  bool get usesDemoAds => true;
  RewardAdState get rewardState;
  Future<void> initialize();
  Future<void> retry();
  Future<void> watch({required VoidCallback onEarned});
  Widget banner({required bool active});
}

class NoGameAds extends GameAds {
  static final instance = NoGameAds();
  @override
  bool get enabled => false;
  @override
  RewardAdState get rewardState => RewardAdState.disabled;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> retry() async {}
  @override
  Future<void> watch({required VoidCallback onEarned}) async {}
  @override
  Widget banner({required bool active}) => const SizedBox.shrink();
}

abstract interface class RewardedSession {
  Future<void> show({
    required VoidCallback onEarned,
    required VoidCallback onClosed,
    required VoidCallback onFailed,
  });
  void dispose();
}

/// Coordinates single-use ads. Closing or failing never grants a reward.
class RewardedCoordinator extends ChangeNotifier {
  RewardedCoordinator(this.loadSession);
  final Future<RewardedSession> Function() loadSession;
  RewardAdState state = RewardAdState.disabled;
  RewardedSession? _ready;
  bool _disposed = false;
  int _generation = 0;

  void _set(RewardAdState value) {
    if (_disposed) return;
    state = value;
    notifyListeners();
  }

  Future<void> load() async {
    if (_disposed ||
        state == RewardAdState.loading ||
        state == RewardAdState.showing ||
        _ready != null)
      return;
    final generation = ++_generation;
    _set(RewardAdState.loading);
    try {
      final session = await loadSession();
      if (_disposed || generation != _generation) {
        session.dispose();
        return;
      }
      _ready = session;
      _set(RewardAdState.ready);
    } catch (_) {
      if (generation == _generation) _set(RewardAdState.unavailable);
    }
  }

  Future<void> watch({required VoidCallback onEarned}) async {
    final session = _ready;
    if (_disposed || state != RewardAdState.ready || session == null) return;
    _ready = null;
    _set(RewardAdState.showing);
    final closed = Completer<void>();
    var earned = false, finished = false;
    void finish() {
      if (finished) return;
      finished = true;
      session.dispose();
      _set(RewardAdState.unavailable);
      if (!closed.isCompleted) closed.complete();
      if (!_disposed) unawaited(load());
    }

    try {
      await session.show(
        onEarned: () {
          if (!earned) {
            earned = true;
            onEarned();
          }
        },
        onClosed: finish,
        onFailed: finish,
      );
    } catch (_) {
      finish();
    }
    await closed.future;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _ready?.dispose();
    _ready = null;
    super.dispose();
  }
}
