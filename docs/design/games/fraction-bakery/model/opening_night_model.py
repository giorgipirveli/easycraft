"""Phase A's model of Opening Night, the phase B slice (docs/design/games/fraction-bakery.md §3.5, §3.9, §3.10): can the
night be won without knowing what a fraction is?

Opening Night's eight judged orders (after three teaching orders that are not judged): a table of buddies to feed fairly
(share: n pies, p buddies, nothing left), a takeaway box (box: a/b of a pie, the order card a pie in b parts with a
glowing), in this order: share(1, p), share(2, p), box, share(3, p), box, share(n, p), box, and the Feast (a long table:
n pies, p buddies). Numbers are new every visit. An order is SOLVED when the first hand-over is right, with no help and at
most one cut more than the fewest (bakery_rules.py). A visit masters g3.maths.unit_fractions when at least 5 of every 6
judged orders are SOLVED (MasteryRules: 7 of 8).

The first draft drew every table and box from grade 3's own denominators (2, 3, 4, 6, 8: 3.NF's grade 3 limit) with
tables of 2 to 6 buddies. The model showed that a child who cuts every pie into twelfths and deals the pieces round-robin
(no idea of the denominator) fed every table fairly (12 shares among 2, 3, 4 and 6) and reached the bar on 100 % of
visits, and that a child who only halves reached it on 12.3 %. The final night (FINAL below) seats tables of 5 and 8 (an
odd number of pies at 8) and puts thirds, fifths and sixths in the boxes, where the denominator has to be chosen.

Run: /usr/bin/python3 -I docs/design/games/fraction-bakery/model/opening_night_model.py 1000 [--draft]
Result (2026-10-18, 1,000 visits each, FINAL; the share of visits reaching 7 of 8): knows what a fraction is 100 %;
knows it but slips on 4 % of decisions 88.0 %; whole-number bias 100 % (nothing in this room compares two amounts:
Midnight Leftovers is where it fails); cuts everything in twelfths and deals 2.6 % (it reads the boxes right; only its
tables fail); always halves 0 %; one piece each from one pie 0 %; turns n/p round 0 %; random cuts and gives 0 %; trial and
error with our knife (the first cut stays) 0 %; trial and error with an undo (not our design) 100 %: why a cut is final.
"""
import importlib.util
import os
import random
import statistics
import sys

sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("bakery_rules", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                             "bakery_rules.py"))
R = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(R)


def _share(rng, ns, ps):
    while True:
        n, p = rng.choice(ns), rng.choice(ps)
        if n < p:
            return R.share(n, p)


def _box(rng, bs):
    b = rng.choice(bs)
    return R.box(rng.randint(2, b - 1), b) if b > 2 else R.box(1, 2)


# The first draft: grade 3's denominators everywhere, tables of 2-6.
DRAFT = [
    lambda r: _share(r, [1], [2, 3, 4, 6]),
    lambda r: _share(r, [2], [3, 4, 6]),
    lambda r: _box(r, [2, 3, 4, 6, 8]),
    lambda r: _share(r, [3], [4, 6]),
    lambda r: _box(r, [2, 3, 4, 6, 8]),
    lambda r: _share(r, [2, 3], [4, 6]),
    lambda r: _box(r, [2, 3, 4, 6, 8]),
    lambda r: _share(r, [3, 4, 5], [4, 6]),
]

# The final night (§3.5): tables of 5 and 8 (an odd number of pies at 8), thirds, fifths and sixths in the boxes.
FINAL = [
    lambda r: _share(r, [1], [5, 6, 8]),                           # O3: a unit fraction (O1 taught 4, O2 the trap 3)
    lambda r: _share(r, [2], [3, 5]),                              # O4: two pies, 2/3 or 2/5 each
    lambda r: _box(r, [3, 4, 6, 8]),                               # O6
    lambda r: _share(r, [3], [5, 8]),                              # O7: 3/5 or 3/8 each
    lambda r: _box(r, [3, 5, 6]),                                  # O8: never in halves
    lambda r: _pair(r, [(2, 5), (3, 5), (4, 5), (3, 8), (2, 6), (4, 6)]),   # O9
    lambda r: _box(r, [3, 5, 6, 8]),                               # O10
    lambda r: _pair(r, [(3, 8), (5, 8), (4, 6), (5, 6), (3, 5), (4, 5)]),   # O11: the Feast's long table
]


def _pair(rng, pairs):
    n, p = rng.choice(pairs)
    return R.share(n, p)


def visit(player, seed, night):
    rng = random.Random(seed)
    out = []
    for make in night:
        order = make(rng)
        out.append((order, R.run(order, player, rng)))
    return out


def label(o):
    if o["form"] == "share":
        return f"{o['n']}/{o['p']}t"
    return f"{o['a']}/{o['b']}b"


def table(night, n, players, title):
    print(title)
    print(f"{'player':34} {'7 of 8':>7} {'solved/8':>8}  per order (solved %)")
    rows = []
    for name, player in players:
        visits = [visit(player, seed, night) for seed in range(n)]
        solved = [sum(1 for _, res in v if res == R.SOLVED) for v in visits]
        bar = sum(1 for s in solved if R.mastered(s, len(night))) / n
        per = [100.0 * sum(1 for v in visits if v[i][1] == R.SOLVED) / n for i in range(len(night))]
        print(f"{name:34} {100 * bar:6.1f}% {statistics.mean(solved):8.2f}  " + " ".join(f"{p:3.0f}" for p in per))
        rows.append((name, 100 * bar, statistics.mean(solved)))
    return rows


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 1000
    if "--draft" in sys.argv:
        table(DRAFT, n, R.PLAYERS_OPENING, "FIRST DRAFT (grade 3 denominators, tables of 2-6)")
        print()
    table(FINAL, n, R.PLAYERS_OPENING, "FINAL (Opening Night as designed)")
    print("orders: O3 share(1,p), O4 share(2,p), O6 box, O7 share(3,p), O8 box, O9 share(n,p), O10 box, O11 the Feast")


if __name__ == "__main__":
    main()
