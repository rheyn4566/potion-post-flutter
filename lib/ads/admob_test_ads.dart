import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'game_ads.dart';

/// Real SDK placements; publisher IDs will replace Google's demo units later.
class AdMobTestAds extends GameAds {
  AdMobTestAds() {
    _rewarded.addListener(notifyListeners);
  }
  static const bannerId = 'ca-app-pub-3940256099942544/9214589741';
  static const fixedBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const rewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const request = AdRequest(nonPersonalizedAds: true);

  /// Preserve playable space on small/short windows; tablets use adaptive ads.
  static bool compactBannerFor(Size viewport) =>
      viewport.width < 360 || viewport.height < 620;
  final _rewarded = RewardedCoordinator(() async {
    final result = Completer<RewardedSession>();
    await RewardedAd.load(
      adUnitId: rewardedId,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => result.complete(_GoogleRewardedSession(ad)),
        onAdFailedToLoad: (error) => result.completeError(error),
      ),
    );
    return result.future;
  });
  bool initialized = false, _initializing = false, _disposed = false;
  int bannerAttempt = 0;
  bool _bannerVisible = false;
  @override
  bool get bannerVisible => _bannerVisible;

  void _setBannerVisible(bool value) {
    if (_disposed || value == _bannerVisible) return;
    _bannerVisible = value;
    notifyListeners();
  }

  @override
  bool get enabled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  RewardAdState get rewardState => _rewarded.state;

  @override
  Future<void> initialize() async {
    if (!enabled || _initializing || initialized || _disposed) return;
    _initializing = true;
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
      );
      await MobileAds.instance.initialize();
      if (_disposed) return;
      initialized = true;
      notifyListeners();
      unawaited(_rewarded.load());
    } catch (_) {
      // Network or platform errors must not prevent offline gameplay.
    } finally {
      _initializing = false;
    }
  }

  @override
  Future<void> retry() async {
    if (!initialized) await initialize();
    if (initialized && !_disposed) {
      bannerAttempt++;
      notifyListeners();
      await _rewarded.load();
    }
  }

  @override
  Future<void> watch({required VoidCallback onEarned}) =>
      _rewarded.watch(onEarned: onEarned);

  @override
  Widget banner({required bool active}) =>
      _BottomBanner(ads: this, active: active);

  @override
  void dispose() {
    _disposed = true;
    _rewarded.removeListener(notifyListeners);
    _rewarded.dispose();
    super.dispose();
  }
}

class _GoogleRewardedSession implements RewardedSession {
  _GoogleRewardedSession(this.ad);
  final RewardedAd ad;
  @override
  Future<void> show({
    required VoidCallback onEarned,
    required VoidCallback onClosed,
    required VoidCallback onFailed,
  }) async {
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (_) => onClosed(),
      onAdFailedToShowFullScreenContent: (_, _) => onFailed(),
    );
    await ad.show(onUserEarnedReward: (_, _) => onEarned());
  }

  @override
  void dispose() {
    unawaited(ad.dispose());
  }
}

class _BottomBanner extends StatefulWidget {
  const _BottomBanner({required this.ads, required this.active});
  final AdMobTestAds ads;
  final bool active;
  @override
  State<_BottomBanner> createState() => _BottomBannerState();
}

class _BottomBannerState extends State<_BottomBanner>
    with WidgetsBindingObserver {
  BannerAd? _ad;
  bool _loaded = false;
  String? _configuration;
  int _generation = 0;
  Timer? _retryTimer;
  int _failures = 0;
  bool _foreground = true;
  bool _compactBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _retryTimer?.cancel();
    if (_foreground && _ad == null && mounted) {
      setState(() => _configuration = null);
    }
  }

  void _retryLater(int width, bool landscape, int generation) {
    _retryTimer?.cancel();
    if (!mounted || !_foreground || generation != _generation || !widget.active)
      return;
    final seconds = 30 * (1 << _failures.clamp(0, 2));
    _failures++;
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (mounted &&
          _foreground &&
          generation == _generation &&
          widget.active) {
        unawaited(_load(width, landscape, generation));
      }
    });
  }

  void _configure(int width, bool landscape, bool compact) {
    final id =
        '$width-$landscape-$compact-${widget.ads.initialized}-${widget.ads.bannerAttempt}-${widget.active}';
    if (id == _configuration) return;
    _retryTimer?.cancel();
    _failures = 0;
    _configuration = id;
    _compactBanner = compact;
    final generation = ++_generation;
    final old = _ad;
    _ad = null;
    _loaded = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (old != null) unawaited(old.dispose());
      if (mounted && generation == _generation)
        widget.ads._setBannerVisible(false);
      if (mounted &&
          generation == _generation &&
          widget.active &&
          _foreground &&
          widget.ads.initialized) {
        unawaited(_load(width, landscape, generation));
      }
    });
  }

  Future<void> _load(int width, bool landscape, int generation) async {
    if (!mounted || !_foreground || generation != _generation) return;
    try {
      final adaptive = _compactBanner
          ? null
          : await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted || !_foreground || generation != _generation) return;
      final AdSize size = adaptive ?? AdSize.banner;
      if (size.width > width) return;
      late final BannerAd ad;
      ad = BannerAd(
        adUnitId: size is AnchoredAdaptiveBannerAdSize
            ? AdMobTestAds.bannerId
            : AdMobTestAds.fixedBannerId,
        request: AdMobTestAds.request,
        size: size,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (!mounted || generation != _generation) {
              unawaited(ad.dispose());
              return;
            }
            setState(() {
              _ad = ad;
              _loaded = true;
            });
            _failures = 0;
            widget.ads._setBannerVisible(true);
          },
          onAdFailedToLoad: (failed, _) {
            unawaited(failed.dispose());
            if (mounted && generation == _generation) {
              setState(() {
                _ad = null;
                _loaded = false;
              });
              widget.ads._setBannerVisible(false);
              _retryLater(width, landscape, generation);
            }
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (_) {
      if (mounted && generation == _generation) {
        final failed = _ad;
        _ad = null;
        if (failed != null) unawaited(failed.dispose());
        setState(() => _loaded = false);
        widget.ads._setBannerVisible(false);
        _retryLater(width, landscape, generation);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _generation++;
    final ad = _ad;
    if (ad != null) unawaited(ad.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final landscape =
          MediaQuery.orientationOf(context) == Orientation.landscape;
      final width = c.maxWidth.floor();
      _configure(
        width,
        landscape,
        AdMobTestAds.compactBannerFor(MediaQuery.sizeOf(context)),
      );
      if (!widget.active || !_loaded || _ad == null)
        return const SizedBox.shrink();
      return AdBannerFrame(
        height: _ad!.size.height.toDouble(),
        child: SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      );
    },
  );
}
