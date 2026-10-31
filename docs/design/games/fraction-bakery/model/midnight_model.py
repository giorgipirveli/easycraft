"""Phase A's model of the transfer room, Midnight Leftovers (docs/design/games/fraction-bakery.md §3.5b, §3.9): does
Opening Night's habit fail where the understood idea wins?

At midnight the oven sleeps: no fresh pies, only the leftover shelf (pies already cut into halves, thirds, quarters,
sixths, eighths…), and the Fair Knife, which can still cut a piece into smaller equal pieces. Six judged orders, numbers
new every visit:
  M1 a box of a/b (b = 2, 3 or 4) when the shelf holds pieces two or three times smaller (3/4 from eighths)
  M2 a box of one half from sixths, eighths, tenths or quarters
  M3 two buddies who already hold one piece each, of different sizes (1/4 and 1/8): make it fair
  M4 a box of one small piece when the shelf holds only bigger ones (1/6 from halves: cut a half into three)
  M5 a box of a/b when the shelf has one piece of 1/b and the rest in pieces half as big (2/3 = 1/3 + 2/6)
  M6 three buddies holding 1/2, 1/3 and 1/6 (or 1/2, 1/4, 1/8 …): make it fair
A judged order handed over right the first time, with no help and within its cut budget, is NEW_SETTING for
g3.maths.unit_fractions (3.NF.1: "a/b is a parts of size 1/b": the size is the idea); the bar is 5 of 6.

Opening Night taught 'cut the pie into b equal pieces, give a of them'. With a fresh pie that habit is right. At midnight
there is no fresh pie, and 'give a pieces' gives a pieces of the wrong size; 'fair means the same number of pieces' calls
a quarter and an eighth fair. The idea ('a parts of size 1/b; equal parts; look at the size') wins.

Run: /usr/bin/python3 -I docs/design/games/fraction-bakery/model/midnight_model.py 1000
The last row is NOT OUR DESIGN: the habit with one fresh pie left on the bench for every order (why the oven sleeps).
Result (2026-10-18, 1,000 visits each; the share reaching 5 of 6): knows what a fraction is 100 %; slips 4 % 97.6 %;
Opening Night's habit 0 % (0 of 6); whole-number bias 0 % (0 of 6); greedy, biggest piece first (it knows sizes: the
idea) 100 %; always halves 100 % (it knows sizes too: only a re-cut into three fails it, 5.75 of 6; Opening Night's
thirds and fifths are what catch halving); random 0 % (0.22 of 6); the habit with a fresh pie (not ours) fills every box
order (4 of 6) and fails only the two plates to make fair.
"""
import importlib.util
import os
import random
import statistics
import sys
from fractions import Fraction as F

sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("bakery_rules", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                             "bakery_rules.py"))
R = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(R)


def _distractor(rng, shelf, avoid):
    d = rng.choice([x for x in (3, 5, 6, 10) if x not in avoid])
    shelf[F(1, d)] = shelf.get(F(1, d), 0) + rng.randint(1, 2)


def m1(rng):
    b = rng.choice([2, 3, 4])
    a = rng.randint(1, b - 1) if b > 2 else 1
    if b == 4:
        a = 3 if rng.random() < 0.7 else 1
    m = rng.choice([x for x in (2, 3) if b * x <= 12])
    shelf = {F(1, b * m): a * m + rng.randint(1, 2)}
    _distractor(rng, shelf, {b, b * m})
    return R.shelf_box(F(a, b), shelf)


def m2(rng):
    m = rng.choice([2, 3, 4, 5])
    shelf = {F(1, 2 * m): m + rng.randint(1, 2)}
    _distractor(rng, shelf, {2, 2 * m})
    return R.shelf_box(F(1, 2), shelf)


def m3(rng):
    b = rng.choice([2, 3, 4])
    m = rng.choice([x for x in (2, 3) if b * x <= 12])
    d = b * m
    plates = [[F(1, b)], [F(1, d)]]
    rng.shuffle(plates)
    return R.equalize(plates, {F(1, d): m + 1, F(1, b): 1})


def m4(rng):
    small, big = rng.choice([(4, 2), (6, 2), (8, 4), (6, 3), (10, 5), (12, 4), (12, 3), (12, 6)])
    return R.shelf_box(F(1, small), {F(1, big): rng.randint(2, 3)})


def m5(rng):
    b = rng.choice([3, 4])
    a = rng.randint(2, b - 1)
    shelf = {F(1, b): 1, F(1, 2 * b): 2 * (a - 1) + rng.randint(1, 2)}
    _distractor(rng, shelf, {b, 2 * b})
    return R.shelf_box(F(a, b), shelf)


def m6(rng):
    fam = rng.choice([(2, 3, 6), (2, 4, 8), (3, 6, 12), (2, 5, 10), (2, 6, 12)])
    top, mid, low = (F(1, x) for x in fam)
    unit = low
    need = (top - mid) / unit + (top - low) / unit
    plates = [[top], [mid], [low]]
    rng.shuffle(plates)
    return R.equalize(plates, {unit: int(need) + 1, F(1, fam[1]): 1})


ROOM = [m1, m2, m3, m4, m5, m6]


def visit(player, seed, fresh=0):
    rng = random.Random(20_000 + seed)
    out = []
    for make in ROOM:
        order = make(rng)
        assert R.plan_target(R.Counter(order["shelf"]), order["value"]) if order["form"] == "shelf_box" else \
            R.plan_equalize(order["plates"], R.Counter(order["shelf"])), order
        out.append((order, R.run(order, player, rng, fresh_at_midnight=fresh)))
    return out


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    rows = list(R.PLAYERS_MIDNIGHT) + [("habit + a fresh pie (not ours)", R.p_count_habit)]
    print(f"{'player':38} {'5 of 6':>7} {'transfer/6':>10}  per order (new-setting %)")
    for name, player in rows:
        fresh = 1 if "fresh pie" in name else 0
        visits = [visit(player, seed, fresh) for seed in range(n)]
        solved = [sum(1 for _, res in v if res == R.SOLVED) for v in visits]
        bar = sum(1 for s in solved if R.mastered(s, len(ROOM))) / n
        per = [100.0 * sum(1 for v in visits if v[i][1] == R.SOLVED) / n for i in range(len(ROOM))]
        print(f"{name:38} {100 * bar:6.1f}% {statistics.mean(solved):10.2f}  " + " ".join(f"{p:3.0f}" for p in per))
    print("orders: M1 a/b from smaller pieces, M2 1/2, M3 make two plates fair, M4 a small piece from big ones (re-cut),"
          " M5 mixed sizes, M6 make three plates fair")


if __name__ == "__main__":
    main()
