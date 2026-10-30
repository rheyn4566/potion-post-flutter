import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'data/progress_store.dart';
import 'domain/puzzle.dart';
import 'domain/catalog.dart';
import 'domain/economy.dart';

enum GamePage { workshop, daily, gardens }

enum GameTool { hint, undo }

class GameController extends ChangeNotifier {
  GameController(this.pack, this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final DateTime Function() clock;
  final List<PotionOrder> pack;
  final ProgressStore store;
  GamePage page = GamePage.workshop;
  int level = 0, dailySlot = 0, moves = 0, coins = 0;
  int? selected;
  Pour? hint;
  String garden = 'moonbloom';
  bool followRouteGarden = true;
  final Set<String> purchasedGardens = {}, purchasedCompanions = {};
  final Set<String> purchasedDecorations = {}, activeDecorations = {};
  final List<CoinEntry> coinHistory = [];
  int _coinOfferSequence = 0;
  final Set<String> _coinOffers = {}, _coinClaims = {};
  final Map<String, int> _shopAds = {};

  /// All coin-reward ads share this daily allowance, including delivery ads.
  int get coinAdsRemaining =>
      (shopAdsPerDay - (_shopAds[localDateKey(clock())] ?? 0)).clamp(
        0,
        shopAdsPerDay,
      );
  String get theme => gardenThemes[garden] ?? 'moonlight';
  bool sound = true, haptics = true, reduceMotion = false;
  bool submitted = false, saveFailed = false, loadFailed = false;
  bool _hintPending = false;
  bool _initializing = false;
  int _freeHints = 3, _freeUndos = 5, _bankedHints = 0, _bankedUndos = 0;
  int _toolOfferSequence = 0;
  final Set<String> _toolClaims = {};
  final Set<String> _toolOffers = {};
  int get hintsAvailable => _freeHints + _bankedHints;
  int get undosAvailable => _freeUndos + _bankedUndos;

  /// Version-one save compatibility: these values only mark completion now.
  /// Old 1–3 values are retained, but never used as ratings or currency.
  final Map<String, int> stars = {};
  bool isCompleted(String orderId) => stars.containsKey(orderId);
  int gardenDelivered(String id) =>
      pack.where((o) => o.garden == id && isCompleted(o.id)).length;
  int gardenGrowth(String id) => gardenGrowthStage(
    gardenDelivered(id),
    pack.where((o) => o.garden == id).length,
  );
  final Map<String, int> friendship = {};
  final Map<String, bool> friendAwards = {}, dailyRouteRewards = {};
  final Set<String> rewardedBonuses = {};
  static const adBonusCoins = deliveryAdCoins;
  String? courier;
  bool _disposed = false;
  final Map<String, dynamic> _sessions = {};
  late PotionOrder order;
  late Board board;
  final List<Board> history = [];
  Future<void> _saveQueue = Future.value();
  Map<String, dynamic>? _pendingSave;
  Map<String, dynamic>? _failedSave;
  bool _saving = false;
  late String _date;

  int get unlocked {
    var first = 0;
    while (first < pack.length - 1 && stars.containsKey(pack[first].id)) {
      first++;
    }
    return first;
  }

  /// Home always continues the unfinished route. Replays retain their sessions
  /// but cannot pull the route card back to an already completed order.
  int get storyResumeLevel => unlocked;

  int get recipeLayers => order.targets.expand((b) => b).length;
  int get matchedLayers {
    var matched = 0;
    for (var i = 0; i < order.targets.length; i++) {
      final target = order.targets[i];
      for (var j = 0; j < target.length && j < board[i].length; j++) {
        if (target[j] != board[i][j]) break;
        matched++;
      }
    }
    return matched;
  }

  double get recipeProgress =>
      recipeLayers == 0 ? 0 : matchedLayers / recipeLayers;
  int get delivered => pack.where((o) => stars.containsKey(o.id)).length;
  int get dailyDelivered =>
      dailyOrders(pack, clock()).where((o) => stars.containsKey(o.id)).length;
  bool get ready => Puzzle.solved(board, order);
  bool get dailyMode => page == GamePage.daily;

  /// The first order teaches one pour; guidance follows restored states too.
  Pour? get tutorialPour {
    if (dailyMode ||
        order.id != pack.first.id ||
        submitted ||
        ready ||
        stars.containsKey(order.id))
      return null;
    final route = Puzzle.solve(board, order);
    return route == null || route.isEmpty ? null : route.first;
  }

  Pour? get cue => hint ?? tutorialPour;

  late final List<Customer> _friends = _collectFriends();
  List<Customer> get friends => _friends;

  List<Customer> _collectFriends() {
    final unique = <String, Customer>{};
    for (final order in pack) {
      for (final customer in order.customers) {
        unique[customer.id] = customer;
      }
    }
    return unique.values.toList();
  }

  int friendCount(String id) => friendship[id] ?? 0;
  int friendTier(String id) {
    for (var tier = 0; tier < friendshipMilestones.length; tier++) {
      if (friendCount(id) >= friendshipMilestones[tier] &&
          friendAwards['$id-$tier'] != true)
        return tier;
    }
    return -1;
  }

  int get friendRewardsReady =>
      friends.where((f) => friendTier(f.id) >= 0).length;
  int get streak {
    var date = clock();
    date = DateTime(date.year, date.month, date.day, 12);
    if (dailyRouteRewards[localDateKey(date)] != true) {
      date = DateTime(date.year, date.month, date.day - 1, 12);
    }
    var count = 0;
    while (dailyRouteRewards[localDateKey(date)] == true && count < 10000) {
      count++;
      date = DateTime(date.year, date.month, date.day - 1, 12);
    }
    return count;
  }

  bool get dailyBonusAvailable =>
      dailyDelivered == 3 && dailyRouteRewards[localDateKey(clock())] != true;

  Future<void> initialize() async {
    if (_initializing) return;
    _initializing = true;
    _date = localDateKey(clock());
    var loaded = false;
    try {
      final data = await store.load();
      if (data != null) {
        if (data['version'] != 1)
          throw const FormatException('Unknown save version');
        _restore(data);
        page = data['daily'] == true ? GamePage.daily : GamePage.workshop;
        if (data['date'] != null && data['date'] != _date) dailySlot = 0;
      }
      saveFailed = false;
      loaded = true;
    } catch (_) {
      loadFailed = saveFailed = true;
    }
    courier ??= friends.first.kind;
    _loadOrder(dailyMode ? dailyOrders(pack, clock())[dailySlot] : pack[level]);
    if (loaded) loadFailed = false;
    _initializing = false;
  }

  Future<void> retryLoad() async {
    await initialize();
    notifyListeners();
  }

  void _restore(Map<String, dynamic> data) {
    stars.clear();
    friendship.clear();
    friendAwards.clear();
    dailyRouteRewards.clear();
    rewardedBonuses.clear();
    purchasedGardens.clear();
    purchasedCompanions.clear();
    purchasedDecorations.clear();
    activeDecorations.clear();
    coinHistory.clear();
    _coinOffers.clear();
    _coinClaims.clear();
    _shopAds.clear();
    _toolClaims.clear();
    _toolOffers.clear();
    _sessions.clear();
    final rawStars = data['stars'];
    if (rawStars is Map) {
      rawStars.forEach((k, v) {
        if (k is String &&
            v is int &&
            v >= 1 &&
            v <= 3 &&
            (pack.any((o) => o.id == k) ||
                RegExp(r'^daily-\d{4}-\d{2}-\d{2}-[012]$').hasMatch(k)))
          stars[k] = v;
      });
    }
    final savedBonuses = data['rewardedBonuses'];
    if (savedBonuses is List) {
      rewardedBonuses.addAll(
        savedBonuses.whereType<String>().where(stars.containsKey),
      );
    }
    coins = data['coins'] is int
        ? (data['coins'] as int).clamp(0, 1000000).toInt()
        : 0;
    final economy = data['economy'];
    if (economy is Map) {
      if (economy['gardens'] is List) {
        purchasedGardens.addAll(
          (economy['gardens'] as List).whereType<String>().where(
            gardenThemes.containsKey,
          ),
        );
      }
      if (economy['companions'] is List) {
        purchasedCompanions.addAll(
          (economy['companions'] as List).whereType<String>().where(
            (kind) => friends.any((f) => f.kind == kind),
          ),
        );
      }
      if (economy['coinClaims'] is List)
        _coinClaims.addAll((economy['coinClaims'] as List).whereType<String>());
      _coinOfferSequence = economy['offerSequence'] is int
          ? (economy['offerSequence'] as int).clamp(0, 10000000)
          : 0;
      if (economy['shopAds'] is Map) {
        (economy['shopAds'] as Map).forEach((day, count) {
          if (day is String &&
              RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) &&
              count is int)
            _shopAds[day] = count.clamp(0, shopAdsPerDay);
        });
      }
      if (economy['history'] is List) {
        for (final entry in (economy['history'] as List).take(25)) {
          if (entry is Map &&
              entry['label'] is String &&
              entry['amount'] is int &&
              entry['day'] is String) {
            coinHistory.add(
              CoinEntry(entry['label'], entry['amount'], entry['day']),
            );
          }
        }
      }
    } else if (coins > 0) {
      coinHistory.add(
        CoinEntry('Previous balance', coins, localDateKey(clock())),
      );
    }
    level = data['level'] is int
        ? (data['level'] as int).clamp(0, unlocked).toInt()
        : unlocked;
    dailySlot = data['dailySlot'] is int
        ? (data['dailySlot'] as int).clamp(0, 2).toInt()
        : 0;
    final savedGarden = data['garden'];
    garden = savedGarden is String && ownsGardenLook(savedGarden)
        ? savedGarden
        : pack[level].garden;
    followRouteGarden = data['followRouteGarden'] is bool
        ? data['followRouteGarden'] as bool
        : garden == pack[level].garden;
    _syncGarden();
    sound = data['sound'] != false;
    haptics = data['haptics'] != false;
    reduceMotion = data['reduceMotion'] == true;
    final tools = data['tools'];
    int count(String key, int fallback) => tools is Map && tools[key] is int
        ? (tools[key] as int).clamp(0, 1000000)
        : fallback;
    final todayTools = tools is Map && tools['day'] == localDateKey(clock());
    _freeHints = todayTools ? count('freeHints', 3).clamp(0, 3) : 3;
    _freeUndos = todayTools ? count('freeUndos', 5).clamp(0, 5) : 5;
    _bankedHints = count('bankedHints', 0);
    _bankedUndos = count('bankedUndos', 0);
    _toolOfferSequence = count('offerSequence', 0);
    if (tools is Map && tools['claims'] is List) {
      _toolClaims.addAll((tools['claims'] as List).whereType<String>());
    }
    final sessions = data['sessions'];
    if (sessions is Map) {
      for (final entry in sessions.entries) {
        if (entry.key is String) _sessions[entry.key as String] = entry.value;
      }
    }
    final savedFriends = data['friendship'];
    for (final friend in friends) {
      final count = savedFriends is Map ? savedFriends[friend.id] : null;
      final prior = pack
          .where(
            (o) =>
                stars.containsKey(o.id) &&
                o.customers.any((c) => c.id == friend.id),
          )
          .length;
      friendship[friend.id] = count is int && count > prior
          ? count.clamp(0, 100000).toInt()
          : prior;
    }
    final awards = data['friendAwards'];
    if (awards is Map) {
      for (final friend in friends) {
        for (var tier = 0; tier < friendshipMilestones.length; tier++) {
          final key = '${friend.id}-$tier';
          if (awards[key] == true) friendAwards[key] = true;
        }
      }
    }
    final routes = data['dailyRouteRewards'];
    if (routes is Map) {
      for (final entry in routes.entries) {
        if (entry.key is String &&
            entry.value == true &&
            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(entry.key as String)) {
          dailyRouteRewards[entry.key as String] = true;
        }
      }
    }
    final savedCourier = data['courier'];
    // Preserve every companion earned for free before economy schema two.
    // Future companions have one clear coin price; the starter stays free.
    if (economy is! Map || economy['schema'] != 2) {
      purchasedCompanions.addAll(
        friends.where((f) => friendCount(f.id) > 0).map((f) => f.kind),
      );
    }
    if (economy is Map) {
      bool validDecoration(String key) {
        final parts = key.split('/');
        return parts.length == 2 &&
            gardenThemes.containsKey(parts[0]) &&
            GardenDecoration.all.any((d) => d.id == parts[1]);
      }

      if (economy['decorations'] is List) {
        purchasedDecorations.addAll(
          (economy['decorations'] as List).whereType<String>().where(
            validDecoration,
          ),
        );
      }
      if (economy['activeDecorations'] is List) {
        activeDecorations.addAll(
          (economy['activeDecorations'] as List).whereType<String>().where(
            purchasedDecorations.contains,
          ),
        );
      }
    }
    courier =
        friends.any((f) => f.kind == savedCourier && ownsCompanion(f.kind))
        ? savedCourier as String
        : friends.first.kind;
    final today = localDateKey(clock());
    _sessions.removeWhere(
      (k, _) => k.startsWith('daily-') && !k.startsWith('daily-$today-'),
    );
  }

  String exportProgress() {
    _rememberSession();
    return jsonEncode(_snapshot());
  }

  Future<void> restoreProgress(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['stars'] is! Map ||
        decoded['sessions'] is! Map) {
      throw const FormatException('Choose a Potion Post progress save.');
    }
    _restore(decoded);
    loadFailed = false;
    page = decoded['daily'] == true ? GamePage.daily : GamePage.workshop;
    _date = localDateKey(clock());
    if (decoded['date'] != null && decoded['date'] != _date) dailySlot = 0;
    _loadOrder(dailyMode ? dailyOrders(pack, clock())[dailySlot] : pack[level]);
    persist();
    await flush();
    notifyListeners();
  }

  int collectFriend(String id) {
    if (!friends.any((f) => f.id == id)) return 0;
    final tier = friendTier(id);
    if (tier < 0) return 0;
    friendAwards['$id-$tier'] = true;
    _credit(friendshipRewards[tier], 'Friendship reward');
    persist();
    notifyListeners();
    return friendshipRewards[tier];
  }

  void chooseCourier(Customer friend) {
    if (!friends.any((f) => f.id == friend.id) || !ownsCompanion(friend.kind))
      return;
    courier = friend.kind;
    persist();
    notifyListeners();
  }

  int claimDailyBonus() {
    if (!dailyBonusAvailable) return 0;
    dailyRouteRewards[localDateKey(clock())] = true;
    _credit(dailyRouteCoins, 'Daily route bonus');
    persist();
    notifyListeners();
    return dailyRouteCoins;
  }

  void _rememberSession() {
    _sessions[order.id] = {
      'board': copyBoard(board),
      'moves': moves,
      'history': history.map(copyBoard).toList(),
      'submitted': submitted,
    };
  }

  void _loadOrder(PotionOrder next) {
    order = next;
    board = copyBoard(next.start);
    moves = 0;
    submitted = false;
    selected = null;
    hint = null;
    history.clear();
    try {
      final raw = _sessions[next.id];
      if (raw is Map) {
        final restored = parseBoard(raw['board']);
        final restoredHistory = (raw['history'] as List)
            .map(parseBoard)
            .toList();
        final restoredMoves = raw['moves'] ?? restoredHistory.length;
        if (restoredMoves is int &&
            restoredMoves == restoredHistory.length &&
            restoredMoves >= 0 &&
            restoredMoves <= 500 &&
            Puzzle.validBoard(restored, next) &&
            restoredHistory.every((b) => Puzzle.validBoard(b, next))) {
          board = restored;
          moves = restoredMoves;
          history.addAll(restoredHistory);
          submitted =
              raw['submitted'] == true &&
              Puzzle.solved(board, next) &&
              stars.containsKey(next.id);
        }
      }
    } catch (_) {
      /* Damaged session resets only this order. */
    }
  }

  void refreshDate() {
    final date = localDateKey(clock());
    if (date == _date) return;
    _date = date;
    _sessions.removeWhere(
      (k, v) => k.startsWith('daily-') && !k.startsWith('daily-$date-'),
    );
    dailySlot = 0;
    _freeHints = 3;
    _freeUndos = 5;
    if (page == GamePage.daily) {
      _loadOrder(dailyOrders(pack, clock())[0]);
    }
    persist();
    notifyListeners();
  }

  void changePage(GamePage next) {
    _rememberSession();
    page = next;
    refreshDate();
    if (next == GamePage.workshop) {
      _loadOrder(pack[level]);
    }
    if (next == GamePage.daily) {
      _loadOrder(dailyOrders(pack, clock())[dailySlot]);
    }
    persist();
    notifyListeners();
  }

  void chooseOrder(int index) {
    if (page == GamePage.gardens) return;
    if (dailyMode && (index < 0 || index > 2)) return;
    if (!dailyMode && (index < 0 || index > unlocked)) return;
    _rememberSession();
    if (dailyMode) {
      dailySlot = index;
    } else {
      level = index;
      _syncGarden();
    }
    _loadOrder(dailyMode ? dailyOrders(pack, clock())[index] : pack[index]);
    persist();
    notifyListeners();
  }

  void select(int? index) {
    selected = index;
    hint = null;
    notifyListeners();
  }

  void performPour(Pour pour) {
    if (submitted || !Puzzle.canPour(board, pour, order.capacity)) return;
    history.add(copyBoard(board));
    if (history.length > 500) {
      history.removeAt(0);
    }
    board = Puzzle.pour(board, pour, order.capacity);
    moves = history.length;
    selected = null;
    hint = null;
    persist();
    notifyListeners();
  }

  bool undo() {
    refreshDate();
    if (history.isEmpty || submitted || undosAvailable == 0) return false;
    if (_freeUndos > 0) {
      _freeUndos--;
    } else {
      _bankedUndos--;
    }
    board = history.removeLast();
    moves = history.length;
    selected = null;
    hint = null;
    persist();
    notifyListeners();
    return true;
  }

  void restart() {
    board = copyBoard(order.start);
    moves = 0;
    history.clear();
    selected = null;
    hint = null;
    submitted = false;
    persist();
    notifyListeners();
  }

  Future<Pour?> showHint() async {
    refreshDate();
    if (submitted || ready || _hintPending) return null;
    if (hint != null) return hint;
    final tutorial = tutorialPour;
    if (tutorial != null) {
      hint = tutorial;
      selected = tutorial.from;
      notifyListeners();
      return hint;
    }
    if (hintsAvailable == 0) return null;
    _hintPending = true;
    final id = order.id, before = Puzzle.key(board);
    try {
      final route = Puzzle.equalBoard(board, order.start)
          ? order.solution
          : await compute(_findRoute, (copyBoard(board), order));
      if (_disposed ||
          order.id != id ||
          Puzzle.key(board) != before ||
          route == null ||
          route.isEmpty)
        return null;
      if (_freeHints > 0) {
        _freeHints--;
      } else {
        _bankedHints--;
      }
      hint = route.first;
      selected = hint!.from;
      persist();
      notifyListeners();
      return hint;
    } finally {
      _hintPending = false;
    }
  }

  String createToolRefillOffer(GameTool tool) {
    _toolOfferSequence++;
    final id = '${tool.name}-$_toolOfferSequence';
    _toolOffers.add(id);
    persist();
    return id;
  }

  bool claimToolRefill(GameTool tool, String offerId) {
    if (_disposed ||
        !_toolOffers.contains(offerId) ||
        !offerId.startsWith('${tool.name}-') ||
        _toolClaims.contains(offerId))
      return false;
    _toolClaims.add(offerId);
    if (tool == GameTool.hint) {
      _bankedHints += 3;
    } else {
      _bankedUndos += 5;
    }
    persist();
    notifyListeners();
    return true;
  }

  ({bool accepted, bool firstDelivery, int baseCoins, int routeBonus})
  deliver() {
    if (!ready || submitted)
      return (
        accepted: false,
        firstDelivery: false,
        baseCoins: 0,
        routeBonus: 0,
      );
    final first = !stars.containsKey(order.id);
    if (first) {
      _credit(
        deliveryCoins,
        dailyMode
            ? 'Daily ${dailySlot + 1} delivery'
            : 'Order ${level + 1} delivery',
      );
      for (final customer in order.customers) {
        friendship[customer.id] = friendCount(customer.id) + 1;
      }
    }
    stars.putIfAbsent(order.id, () => 1);
    final routeBonus = dailyMode ? claimDailyBonus() : 0;
    _syncGarden();
    submitted = true;
    selected = null;
    hint = null;
    persist();
    notifyListeners();
    return (
      accepted: true,
      firstDelivery: first,
      baseCoins: first ? deliveryCoins : 0,
      routeBonus: routeBonus,
    );
  }

  void nextOrder() {
    if (dailyMode) {
      chooseOrder((dailySlot + 1) % 3);
    } else if (level < pack.length - 1) {
      chooseOrder(level + 1);
    } else {
      changePage(GamePage.gardens);
    }
  }

  bool canClaimAdBonus(String orderId) =>
      !loadFailed &&
      coinAdsRemaining > 0 &&
      stars.containsKey(orderId) &&
      !rewardedBonuses.contains(orderId);

  /// Called only by the SDK's earned-reward event. The captured order ID
  /// keeps late callbacks tied to the completed order, not the current board.
  bool claimAdBonus(String orderId) {
    if (_disposed || !canClaimAdBonus(orderId)) return false;
    rewardedBonuses.add(orderId);
    final day = localDateKey(clock());
    _shopAds[day] = (_shopAds[day] ?? 0) + 1;
    _credit(adBonusCoins, 'Bonus ad');
    persist();
    notifyListeners();
    return true;
  }

  bool isGardenUnlocked(String id) {
    final first = pack.indexWhere((order) => order.garden == id);
    return gardenThemes.containsKey(id) && first >= 0 && first <= unlocked;
  }

  void selectGarden(String id) {
    if (!ownsGardenLook(id)) return;
    followRouteGarden = false;
    garden = id;
    persist();
    notifyListeners();
  }

  void _syncGarden() {
    if (followRouteGarden) garden = pack[unlocked].garden;
  }

  void followGardenRoute() {
    followRouteGarden = true;
    _syncGarden();
    persist();
    notifyListeners();
  }

  bool ownsGardenLook(String id) =>
      isGardenUnlocked(id) || purchasedGardens.contains(id);
  bool ownsCompanion(String kind) =>
      purchasedCompanions.contains(kind) || kind == friends.first.kind;
  int priceOfCompanion(String kind) =>
      companionPrice(friends.indexWhere((f) => f.kind == kind));

  void _credit(int amount, String label) {
    coins += amount;
    _recordCoins(label, amount);
  }

  void _recordCoins(String label, int amount) {
    coinHistory.insert(0, CoinEntry(label, amount, localDateKey(clock())));
    if (coinHistory.length > 25)
      coinHistory.removeRange(25, coinHistory.length);
  }

  Set<String> decorationsFor(String gardenId) => activeDecorations
      .where((key) => key.startsWith('$gardenId/'))
      .map((key) => key.split('/').last)
      .toSet();

  bool ownsDecoration(String gardenId, String decorationId) =>
      purchasedDecorations.contains('$gardenId/$decorationId');

  PurchaseResult buyDecoration(String gardenId, String decorationId) {
    final matches = GardenDecoration.all.where((d) => d.id == decorationId);
    if (loadFailed || !isGardenUnlocked(gardenId) || matches.isEmpty)
      return PurchaseResult.unavailable;
    final decoration = matches.single, key = '$gardenId/$decorationId';
    if (purchasedDecorations.contains(key)) return PurchaseResult.owned;
    if (coins < decoration.price) return PurchaseResult.insufficientCoins;
    coins -= decoration.price;
    _recordCoins('${decoration.name} · $gardenId', -decoration.price);
    purchasedDecorations.add(key);
    activeDecorations.add(key);
    persist();
    notifyListeners();
    return PurchaseResult.bought;
  }

  void toggleDecoration(String gardenId, String decorationId) {
    final key = '$gardenId/$decorationId';
    if (loadFailed || !purchasedDecorations.contains(key)) return;
    if (!activeDecorations.remove(key)) activeDecorations.add(key);
    persist();
    notifyListeners();
  }

  PurchaseResult buyCompanion(String kind) {
    if (loadFailed || !friends.any((f) => f.kind == kind))
      return PurchaseResult.unavailable;
    if (ownsCompanion(kind)) return PurchaseResult.owned;
    final price = priceOfCompanion(kind);
    if (coins < price) return PurchaseResult.insufficientCoins;
    coins -= price;
    _recordCoins('Companion', -price);
    purchasedCompanions.add(kind);
    courier = kind;
    persist();
    notifyListeners();
    return PurchaseResult.bought;
  }

  PurchaseResult buyToolRefill(GameTool tool) {
    if (loadFailed) return PurchaseResult.unavailable;
    final price = tool == GameTool.hint ? hintPackPrice : undoPackPrice;
    if (coins < price) return PurchaseResult.insufficientCoins;
    coins -= price;
    _recordCoins(tool == GameTool.hint ? '3 hints' : '5 undos', -price);
    if (tool == GameTool.hint) {
      _bankedHints += 3;
    } else {
      _bankedUndos += 5;
    }
    persist();
    notifyListeners();
    return PurchaseResult.bought;
  }

  String createCoinOffer() {
    final id = 'coins-${++_coinOfferSequence}';
    _coinOffers.add(id);
    persist();
    return id;
  }

  bool claimCoinOffer(String id) {
    if (_disposed ||
        loadFailed ||
        !_coinOffers.contains(id) ||
        _coinClaims.contains(id) ||
        coinAdsRemaining == 0)
      return false;
    _coinClaims.add(id);
    final day = localDateKey(clock());
    _shopAds[day] = (_shopAds[day] ?? 0) + 1;
    _credit(shopAdCoins, 'Bonus ad');
    persist();
    notifyListeners();
    return true;
  }

  void setSettings({bool? soundValue, bool? hapticsValue, bool? motionValue}) {
    sound = soundValue ?? sound;
    haptics = hapticsValue ?? haptics;
    reduceMotion = motionValue ?? reduceMotion;
    persist();
    notifyListeners();
  }

  void persist() {
    if (loadFailed) return;
    _rememberSession();
    _pendingSave = _snapshot();
    // Keep writes ordered and replace waiting snapshots with the latest state.
    // Long routes must not queue thousands of obsolete full-save writes.
    if (!_saving) {
      _saving = true;
      _saveQueue = _drainSaves();
    }
    unawaited(_saveQueue);
  }

  Future<void> _drainSaves() async {
    final wasFailed = saveFailed;
    while (_pendingSave != null) {
      final snapshot = _pendingSave!;
      _pendingSave = null;
      try {
        await store.save(snapshot);
        _failedSave = null;
        saveFailed = false;
      } catch (_) {
        _failedSave = snapshot;
        saveFailed = true;
      }
    }
    _saving = false;
    if (!_disposed && wasFailed != saveFailed) notifyListeners();
  }

  Map<String, dynamic> _snapshot() => {
    'version': 1,
    'coins': coins,
    'followRouteGarden': followRouteGarden,
    'economy': {
      'schema': 2,
      'gardens': purchasedGardens.toList(),
      'companions': purchasedCompanions.toList(),
      'decorations': purchasedDecorations.toList(),
      'activeDecorations': activeDecorations.toList(),
      'history': coinHistory.map((e) => e.toJson()).toList(),
      'offerSequence': _coinOfferSequence,
      'coinClaims': _coinClaims.toList(),
      'shopAds': Map.of(_shopAds),
    },
    'stars': Map.of(stars),
    'level': level,
    'dailySlot': dailySlot,
    'daily': dailyMode,
    'date': _date,
    'tools': {
      'day': _date,
      'freeHints': _freeHints,
      'freeUndos': _freeUndos,
      'bankedHints': _bankedHints,
      'bankedUndos': _bankedUndos,
      'offerSequence': _toolOfferSequence,
      'claims': _toolClaims.toList(),
    },
    'theme': theme,
    'garden': garden,
    'sound': sound,
    'haptics': haptics,
    'reduceMotion': reduceMotion,
    // Session values are private snapshots, replaced wholesale on each action.
    'sessions': Map.of(_sessions),
    'friendship': Map.of(friendship),
    'friendAwards': Map.of(friendAwards),
    'dailyRouteRewards': Map.of(dailyRouteRewards),
    'rewardedBonuses': rewardedBonuses.toList(),
    'courier': courier,
  };

  Future<void> flush() async {
    await _saveQueue;
    if (_failedSave != null && !loadFailed) {
      persist();
      await _saveQueue;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

List<Pour>? _findRoute((Board, PotionOrder) request) =>
    Puzzle.solve(request.$1, request.$2);
