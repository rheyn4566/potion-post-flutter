typedef Board = List<List<int>>;

Board copyBoard(Board board) => board.map((b) => List<int>.of(b)).toList();

class Pour {
  const Pour(this.from, this.to);
  final int from;
  final int to;

  List<int> toJson() => [from, to];
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.role,
    required this.kind,
    required this.request,
    required this.effect,
    required this.thanks,
  });
  final String id, name, role, kind, request, effect, thanks;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
    kind: json['kind'] as String,
    request: json['request'] as String,
    effect: json['effect'] as String,
    thanks: json['thanks'] as String,
  );
}

class PotionOrder {
  const PotionOrder({
    required this.id,
    required this.number,
    required this.title,
    required this.capacity,
    required this.start,
    required this.targets,
    required this.customers,
    required this.par,
    required this.solution,
    this.garden = 'moonbloom',
  });

  final String id, title, garden;
  final int number, capacity, par;

  /// Layer index zero is always the bottom of a bottle.
  final Board start, targets;
  final List<Customer> customers;
  final List<Pour> solution;

  Board get goal => [
    ...copyBoard(targets),
    for (var i = targets.length; i < start.length; i++) <int>[],
  ];

  factory PotionOrder.fromJson(Map<String, dynamic> json) => PotionOrder(
    id: json['id'] as String,
    number: json['number'] as int,
    title: json['title'] as String,
    capacity: json['capacity'] as int,
    start: parseBoard(json['start']),
    targets: parseBoard(json['targets']),
    customers: (json['customers'] as List)
        .map((c) => Customer.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList(),
    par: json['par'] as int,
    solution: (json['solution'] as List)
        .map((m) => Pour((m as List)[0] as int, m[1] as int))
        .toList(),
    garden: json['garden'] as String? ?? 'moonbloom',
  );

  PotionOrder asDaily(String date, int slot, int shift) => PotionOrder(
    id: 'daily-$date-$slot',
    number: slot + 1,
    title: title,
    capacity: capacity,
    start: start.map((b) => b.map((c) => (c + shift) % 4).toList()).toList(),
    targets: targets
        .map((b) => b.map((c) => (c + shift) % 4).toList())
        .toList(),
    customers: customers,
    par: par,
    solution: solution,
    garden: garden,
  );
}

Board parseBoard(dynamic raw) => (raw as List)
    .map((b) => (b as List).map((c) => c as int).toList())
    .toList();

class Puzzle {
  static bool equalBottle(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool equalBoard(Board a, Board b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!equalBottle(a[i], b[i])) return false;
    }
    return true;
  }

  static bool canPour(Board board, Pour move, int capacity) =>
      move.from >= 0 &&
      move.to >= 0 &&
      move.from < board.length &&
      move.to < board.length &&
      move.from != move.to &&
      board[move.from].isNotEmpty &&
      board[move.to].length < capacity;

  static Board pour(Board board, Pour move, int capacity) {
    if (!canPour(board, move, capacity)) {
      throw ArgumentError(
        'A pour needs liquid and room in a different bottle.',
      );
    }
    final next = copyBoard(board);
    next[move.to].add(next[move.from].removeLast());
    return next;
  }

  static bool solved(Board board, PotionOrder order) =>
      equalBoard(board, order.goal);

  static String key(Board board) => board.map((b) => b.join(',')).join('|');

  /// A* keeps hints practical for the new four-layer recipes. A layer
  /// outside a matching bottom prefix must be moved at least once, so this
  /// estimate never overstates the number of remaining pours.
  static List<Pour>? solve(
    Board start,
    PotionOrder order, {
    int maxStates = 150000,
  }) {
    final target = key(order.goal), first = key(start);
    if (first == target) return [];
    final goal = order.goal;
    int estimate(Board board) {
      var fixed = 0, total = 0;
      for (var i = 0; i < board.length; i++) {
        total += board[i].length;
        for (var j = 0; j < board[i].length && j < goal[i].length; j++) {
          if (board[i][j] != goal[i][j]) break;
          fixed++;
        }
      }
      return total - fixed;
    }

    final heap = _RouteHeap();
    final costs = <String, int>{first: 0};
    final parents = <String, (String, Pour)>{};
    var serial = 0, visited = 0;
    heap.add(_RouteNode(copyBoard(start), 0, estimate(start), serial++));
    while (heap.nodes.isNotEmpty) {
      final node = heap.remove();
      final stateKey = key(node.board);
      if (costs[stateKey] != node.moves) continue;
      if (stateKey == target) {
        final result = <Pour>[];
        var cursor = target;
        while (cursor != first) {
          final parent = parents[cursor]!;
          result.add(parent.$2);
          cursor = parent.$1;
        }
        return result.reversed.toList();
      }
      if (++visited > maxStates) return null;
      for (var from = 0; from < node.board.length; from++) {
        for (var to = 0; to < node.board.length; to++) {
          final move = Pour(from, to);
          if (!canPour(node.board, move, order.capacity)) continue;
          final next = pour(node.board, move, order.capacity);
          final nextKey = key(next), cost = node.moves + 1;
          if (cost >= (costs[nextKey] ?? 1000000000)) continue;
          costs[nextKey] = cost;
          parents[nextKey] = (stateKey, move);
          heap.add(_RouteNode(next, cost, cost + estimate(next), serial++));
        }
      }
    }
    return null;
  }

  /// A stale or damaged save may never change capacity or liquid inventory.
  static bool validBoard(Board board, PotionOrder order) {
    if (board.length != order.start.length) return false;
    final counts = List<int>.filled(12, 0);
    final expected = List<int>.filled(12, 0);
    for (final bottle in board) {
      if (bottle.length > order.capacity) return false;
      for (final c in bottle) {
        if (c < 0 || c >= 12) return false;
        counts[c]++;
      }
    }
    for (final bottle in order.start) {
      for (final c in bottle) {
        expected[c]++;
      }
    }
    return equalBottle(counts, expected);
  }
}

String localDateKey(DateTime time) =>
    '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';

List<PotionOrder> dailyOrders(List<PotionOrder> pack, DateTime time) {
  // Retain the original daily pool so old daily saves still match.
  pack = pack.take(30).toList();
  final date = localDateKey(time);
  var seed = 0;
  for (final unit in date.codeUnits) {
    seed = (seed * 31 + unit) % 1000003;
  }
  return List.generate(
    3,
    (i) =>
        pack[2 + (seed + i * 3) % (pack.length - 2)].asDaily(date, i, seed % 4),
  );
}

class _RouteNode {
  const _RouteNode(this.board, this.moves, this.score, this.serial);
  final Board board;
  final int moves, score, serial;
}

class _RouteHeap {
  final List<_RouteNode> nodes = [];
  bool _less(_RouteNode a, _RouteNode b) =>
      a.score < b.score ||
      a.score == b.score &&
          (a.moves > b.moves || a.moves == b.moves && a.serial < b.serial);
  void add(_RouteNode node) {
    nodes.add(node);
    var i = nodes.length - 1;
    while (i > 0) {
      final parent = (i - 1) ~/ 2;
      if (!_less(nodes[i], nodes[parent])) break;
      final previous = nodes[parent];
      nodes[parent] = nodes[i];
      nodes[i] = previous;
      i = parent;
    }
  }

  _RouteNode remove() {
    final result = nodes.first, last = nodes.removeLast();
    if (nodes.isNotEmpty) {
      nodes[0] = last;
      var i = 0;
      while (true) {
        var child = i * 2 + 1;
        if (child >= nodes.length) break;
        if (child + 1 < nodes.length && _less(nodes[child + 1], nodes[child]))
          child++;
        if (!_less(nodes[child], nodes[i])) break;
        final previous = nodes[i];
        nodes[i] = nodes[child];
        nodes[child] = previous;
        i = child;
      }
    }
    return result;
  }
}
