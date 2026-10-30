"""Append twelve new routes while preserving every original order and save ID."""
from pathlib import Path
import hashlib
import heapq
import itertools
import json
import random

ROOT = Path(__file__).resolve().parents[1]
NEW_FRIENDS = [
    ('acorn', 'Acorn', 'squirrel', 'The seed-and-letter collector'),
    ('maple', 'Maple', 'redpanda', 'The lantern-route potion keeper'),
    ('basil', 'Basil', 'capybara', 'The calm hot-spring gardener'),
    ('fern', 'Fern', 'deer', 'The meadow messenger'),
    ('bram', 'Bram', 'badger', 'The patient apiary postmaster'),
    ('tobin', 'Tobin', 'beaver', 'The windmill garden builder'),
    ('tula', 'Tula', 'turtle', 'The conservatory caretaker'),
    ('puddle', 'Puddle', 'duck', 'The rainy-day letter carrier'),
    ('nori', 'Nori', 'axolotl', 'The little springwater alchemist'),
    ('fennel', 'Fennel', 'ferret', 'The spiceyard parcel scout'),
    ('winnie', 'Winnie', 'penguin', 'The cool-weather parcel keeper'),
    ('button', 'Button', 'mouse', 'The tiny harvest courier'),
    ('koa', 'Koa', 'koala', 'The teacourt botanical keeper'),
    ('mellow', 'Mellow', 'sloth', 'The unhurried garden messenger'),
    ('prism', 'Prism', 'chameleon', 'The desert potion gardener'),
    ('echo', 'Echo', 'bat', 'The twilight airpost courier'),
]
ROUTES = [
    ('lanternleaf', 'Lanternleaf Conservatory', 'turtle'),
    ('copperwind', 'Copperwind Millgarden', 'beaver'),
    ('cactuscrescent', 'Cactus Crescent', 'chameleon'),
    ('cloudberry', 'Cloudberry Airpost', 'bat'),
    ('porcelainteacourt', 'Porcelain Teacourt', 'koala'),
    ('emberglow', 'Emberglow Springs', 'capybara'),
    ('honeycombhaven', 'Honeycomb Haven', 'badger'),
    ('rootcellar', 'Rootcellar Retreat', 'squirrel'),
    ('pumpkinpatch', 'Pumpkin Lantern Patch', 'mouse'),
    ('raindroproof', 'Raindrop Roofgarden', 'duck'),
    ('saffronspice', 'Saffron Spiceyard', 'ferret'),
    ('ribbonwind', 'Ribbonwind Festival Garden', 'deer'),
]

def shortest(start, goal, capacity, max_states=70000):
    def estimate(board):
        fixed = 0
        for bottle, target in zip(board, goal):
            for value, wanted in zip(bottle, target):
                if value != wanted:
                    break
                fixed += 1
        return sum(map(len, board)) - fixed
    serial = itertools.count()
    queue = [(estimate(start), 0, next(serial), start)]
    costs = {start: 0}
    parents = {}
    visits = 0
    while queue:
        _, negative_cost, _, board = heapq.heappop(queue)
        cost = -negative_cost
        if costs.get(board) != cost:
            continue
        if board == goal:
            path = []
            while board != start:
                board, move = parents[board]
                path.append(list(move))
            return path[::-1]
        visits += 1
        if visits > max_states:
            return None
        for source, bottle in enumerate(board):
            if not bottle:
                continue
            for target, destination in enumerate(board):
                if source == target or len(destination) >= capacity:
                    continue
                next_board = list(board)
                next_board[source] = bottle[:-1]
                next_board[target] = destination + bottle[-1:]
                next_board = tuple(next_board)
                if cost + 1 >= costs.get(next_board, 10**9):
                    continue
                costs[next_board] = cost + 1
                parents[next_board] = (board, (source, target))
                heapq.heappush(queue, (cost + 1 + estimate(next_board), -cost - 1, next(serial), next_board))
    return None

def main():
    path = ROOT / 'assets/orders.json'
    original = json.loads(path.read_text())[:1000]
    assert len(original) == 1000
    digest = hashlib.sha256(json.dumps(original, sort_keys=True).encode()).hexdigest()
    existing = {c['id']: c for order in original for c in order['customers']}
    profiles = {}
    for ident, name, kind, role in NEW_FRIENDS:
        assert ident not in existing and name not in {c['name'] for c in existing.values()}
        profiles[kind] = dict(id=ident, name=name, kind=kind, role=role,
            request='A little garden magic for my delivery route, please.',
            effect=f'A soft trail of glowing leaves follows {name}.',
            thanks='A perfect little delivery. Thank you!')
    guests = list(profiles.values())
    orders = list(original)
    seen = {json.dumps([o['start'], o['targets']], separators=(',', ':')) for o in orders}
    rng = random.Random(20261021)
    route_stats = []
    for route_index, (garden, title, lead) in enumerate(ROUTES):
        pars = []
        for slot in range(40):
            while True:
                capacity = 4
                palette = rng.sample(range(12), 5)
                targets = [[rng.choice(palette) for _ in range(capacity)] for _ in range(2)]
                goal = tuple(map(tuple, targets + [[], []]))
                start = [list(b) for b in goal]
                previous = None
                for _ in range(12 + slot % 9):
                    moves = [(a, b) for a in range(4) for b in range(4)
                             if a != b and start[a] and len(start[b]) < capacity
                             and (a, b) != previous]
                    source, target = rng.choice(moves)
                    start[target].append(start[source].pop())
                    previous = (target, source)
                signature = json.dumps([start, targets], separators=(',', ':'))
                if signature in seen or tuple(map(tuple, start)) == goal:
                    continue
                solution = shortest(tuple(map(tuple, start)), goal, capacity)
                if solution is not None and len(solution) >= 5:
                    break
            seen.add(signature)
            number = len(orders) + 1
            guest = guests[(route_index * 5 + slot) % len(guests)]
            if guest['kind'] == lead:
                guest = guests[(route_index * 5 + slot + 1) % len(guests)]
            orders.append(dict(id=f'order-{number}', number=number,
                title=f'{title} · Delivery {slot + 1}', garden=garden, capacity=capacity,
                start=start, targets=targets, customers=[profiles[lead], guest],
                par=len(solution), solution=solution))
            pars.append(len(solution))
        route_stats.append(dict(garden=garden, firstOrder=len(orders)-40, count=40,
                                minimumPours=min(pars), maximumPours=max(pars)))
        print(f'{title}: 40 valid routes, {min(pars)}–{max(pars)} pours', flush=True)
    assert orders[:1000] == original
    assert len(orders) == 1480
    customers = {c['id']: c for o in orders for c in o['customers']}
    assert len(customers) == 26
    assert len({c['kind'] for c in customers.values()}) == 26
    assert len({c['name'] for c in customers.values()}) == 26
    path.write_text(json.dumps(orders, ensure_ascii=False, separators=(',', ':')))
    (ROOT / 'docs/EXPANSION.json').write_text(json.dumps(dict(
        originalOrdersPreserved=1000, originalOrdersSha256=digest,
        addedOrders=480, orders=1480, gardens=43, characters=26, routes=route_stats), indent=2))
    print('Expanded pack: 1,480 orders, 43 gardens, 26 unique characters.', flush=True)

if __name__ == '__main__':
    main()
