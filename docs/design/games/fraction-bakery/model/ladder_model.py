"""Phase A's model of the ladder's later rooms (docs/design/games/fraction-bakery.md §3.6, §3.9): in each, does the habit
or misconception the research names fail where the idea wins?

Each room is six judged orders, numbers new every visit; a visit reaches the room's bar at 5 of 6 right the first time
(MasteryRules). The rooms and their verbs (§3.4):
  (a) The Tin Oven, mixed tins (5.NF.1): two pieces of different sizes must go into ONE tin; tins have 2-12 moulded
      sections and a piece fits a section only when it is that size, so the child picks the tin and re-cuts both pieces
      to fit (a common denominator); it bakes when both pieces are in.
  (b) The Baguette Counter (3.NF.2, 3.NF.3c): two loaves end to end on the Fair Line (0 to 2); a box of a/b of a loaf
      (some more than one loaf, some whole loaves): cut the loaves, give the pieces; the box slides to its amount.
  (c) The Queue (4.NF.2): four buddies show order cards (numerals); line them up along the counter, the least first.
  (d) The Size Oven (5.NF.5): the oven's dial shows a number (3/4, 5/4, 4/4…); before baking, put the cake on the
      shelf where it will fit after baking: the small shelf, the same, or the big one.
  (e) The Scoops (5.NF.7, 6.NS.1): a bowl of D cups of batter and a scoop of s cups: set out the moulds (how many),
      then pour; right when every mould fills and nothing is left (D ÷ s).
  (f) The Recipe Book (6.RP.3a): a recipe card of a scoops of flour to b of butter; a big batch with a·m flour: pour the
      butter (scoops); the dough comes out right only in the recipe's ratio.
  (g) The Night Market (4.NF.2's "the same whole"; a transfer room): a buddy holds 1/2 of a small cake; give the other
      buddy the same amount from a cake two or three times as big.
  (h) The Hundred Tray (4.NF.6, 5.NBT.3): a chocolate slab of 10 rows of 10 squares; three orders to make (0.3 is
      three rows) and three queues of decimal orders to line up (0.5, 0.45, 0.405 …).

Run: /usr/bin/python3 -I docs/design/games/fraction-bakery/model/ladder_model.py 1000 [--draft]
Result (2026-10-18, 1,000 visits each; the share reaching 5 of 6): in every room the idea 100 % and every misconception
0 %, but the tins' 'bigger bottom number' habit 0.8 % (halves do fit a quarters tin). The model changed four first drafts
(--draft prints them): (b) boxes drawn anywhere in (0, 2] let 'a fraction is less than one' reach 11.7 %: now four of six
go past one loaf; (c) four random cards let 'order by the top number' reach 2.9 % (and a same-top pair alone raised it to
12.5 %): every queue now holds a same-top pair and a small-top-big-value pair; (d) one cake an order let 'multiplying
always makes bigger' reach 29.4 % and 'a fraction always shrinks' 37.5 %: now three cakes go in at once, one shrinking and
one growing; (h) decimal queues without the trap let 'shorter is larger' reach 2.7 %: every queue now holds 0.4, 0.405
and 0.45.
"""
import random
import statistics
import sys
from fractions import Fraction as F
from math import gcd

sys.dont_write_bytecode = True
KNIFE = range(2, 13)


def lcm(a, b):
    return a * b // gcd(a, b)


def mastered(solved, total):
    return total > 0 and solved * 6 >= 5 * total


# --- (a) mixed tins ------------------------------------------------------------------------------------------------------
PAIRS = {1: [(2, 4), (2, 6), (2, 8), (3, 6), (4, 8), (3, 12), (4, 12), (5, 10), (2, 10), (6, 12)],
         2: [(2, 3), (3, 4), (2, 5), (3, 2), (4, 3)],
         3: [(4, 6), (6, 4)]}


def tin_order(rng):
    while True:
        lvl = rng.choice([1, 2, 2, 3])
        b, d = rng.choice(PAIRS[lvl])
        a1, a2 = rng.randint(1, b - 1), rng.randint(1, d - 1)
        if F(a1, b) + F(a2, d) <= 1:
            return a1, b, a2, d


def tin_right(order, k):
    _, b, _, d = order
    return k <= 12 and k % b == 0 and k % d == 0


TIN_PLAYERS = [
    ("knows: a tin both sizes fit (common denominator)", lambda o, r: lcm(o[1], o[3])),
    ("any common multiple (b × d when it fits)", lambda o, r: o[1] * o[3] if o[1] * o[3] <= 12 else lcm(o[1], o[3])),
    ("adds tops and bottoms (tin b + d)", lambda o, r: min(12, o[1] + o[3])),
    ("habit: the bigger bottom number's tin", lambda o, r: max(o[1], o[3])),
    ("the first piece's tin", lambda o, r: o[1]),
    ("random tin", lambda o, r: r.choice(KNIFE)),
]


# --- (b) the Baguette Counter (0 to 2 on the Fair Line) -----------------------------------------------------------------
def line_order_draft(rng, i):
    """First draft: a/b of a loaf drawn anywhere in (0, 2]."""
    b = rng.choice([2, 3, 4, 6, 8])
    return rng.randint(1, 2 * b), b


def line_order(rng, i):
    """Final: two boxes of less than a loaf (orders 1-2), then four past post 1: more than a loaf (5/4, 7/3) or whole
    loaves (8/4), because seeing a fraction go past one is the room's idea (3.NF.2b, 3.NF.3c)."""
    b = rng.choice([2, 3, 4, 6, 8])
    if i < 2:
        return rng.randint(1, b - 1), b
    return rng.randint(b + 1, 2 * b), b


# Each player returns where its box stops on the Fair Line, in loaves.
LINE_PLAYERS = [
    ("knows: b pieces in each loaf, a of them", lambda o, r: F(o[0], o[1])),
    ("the line's end is one (cuts both loaves as one)", lambda o, r: F(2 * o[0], o[1])),   # Siegler & Pyke's 0-5 lines
    ("a fraction is less than one (stops at a loaf)", lambda o, r: F(min(o[0], o[1]), o[1])),
    ("counts the top number as loaves", lambda o, r: F(o[0])),
    ("random cut and count", lambda o, r: F(r.randint(1, 24), r.choice(KNIFE))),
]


# --- (c) the Queue ---------------------------------------------------------------------------------------------------------
DENS = [2, 3, 4, 5, 6, 8, 10, 12]


def queue_order_draft(rng, i):
    """First draft: four random cards."""
    while True:
        cards = set()
        while len(cards) < 4:
            b = rng.choice(DENS)
            cards.add((rng.randint(1, b - 1), b))
        cards = list(cards)
        if len({F(a, b) for a, b in cards}) == 4:
            rng.shuffle(cards)
            return cards


def queue_order(rng, i):
    """Final: every queue holds two traps: a pair with the same top number (2/3 and 2/5: the whole-number bias puts 2/5
    last) and a small top worth more than a bigger top (1/2 and 3/8: ordering by the top number puts 1/2 first)."""
    while True:
        a = rng.choice([1, 2, 3])
        b1, b2 = rng.sample([d for d in DENS if d > a], 2)
        cards = {(a, b1), (a, b2)}
        small_top = rng.choice([(1, 2), (2, 3), (1, 3)])
        b = rng.choice([d for d in DENS if d >= 8])
        big_top = (rng.randint(small_top[0] + 1, max(small_top[0] + 1, int(F(*small_top) * b) - 1 + 1)), b)
        if F(*big_top) >= F(*small_top) or big_top[0] >= b:
            continue
        cards |= {small_top, big_top}
        cards = list(cards)
        if len(cards) == 4 and len({F(x, y) for x, y in cards}) == 4:
            rng.shuffle(cards)
            return cards


def queue_right(cards, ordered):
    vals = [F(a, b) for a, b in ordered]
    return vals == sorted(vals)


def _half_then_random(cards, rng):
    lo = [c for c in cards if F(*c) < F(1, 2)]
    hi = [c for c in cards if F(*c) >= F(1, 2)]
    rng.shuffle(lo)
    rng.shuffle(hi)
    return lo + hi


QUEUE_PLAYERS = [
    ("knows: compares the amounts", lambda c, r: sorted(c, key=lambda x: F(*x))),
    ("whole-number bias (bigger bottom = more)", lambda c, r: sorted(c, key=lambda x: (x[1], x[0]))),
    ("by the top number", lambda c, r: sorted(c, key=lambda x: (x[0], -x[1]))),
    ("by top + bottom ('bigger numbers, more')", lambda c, r: sorted(c, key=lambda x: (x[0] + x[1], x[0]))),
    ("knows only 'less or more than a half'", _half_then_random),
    ("random queue", lambda c, r: r.sample(c, len(c))),
]


# --- (d) the Size Oven ---------------------------------------------------------------------------------------------------
# The dial's tags as written (4/4 stays 4/4 on the card): (top, bottom).
SHRINK = [(1, 2), (2, 3), (3, 4), (5, 6), (7, 8), (3, 5)]
SAME = [(4, 4), (3, 3), (6, 6), (1, 1)]
GROW = [(5, 4), (3, 2), (4, 3), (9, 8), (2, 1), (7, 4)]
DIALS = SHRINK + SAME + GROW


def shelf_of(tag):
    v = F(*tag)
    return "small" if v < 1 else ("same" if v == 1 else "big")


def oven_order_draft(rng, i):
    """First draft: one cake per order."""
    return [rng.choice(DIALS)]


def oven_order(rng, i):
    """Final: three cakes go in at once, at least one shrinking and one growing; the order is right when all three are
    on the right shelves."""
    cakes = [rng.choice(SHRINK), rng.choice(GROW), rng.choice(DIALS)]
    rng.shuffle(cakes)
    return cakes


def _oven(rule):
    return lambda cakes, r: [rule(t, r) for t in cakes]


OVEN_PLAYERS = [
    ("knows: below 1 shrinks, above 1 grows", _oven(lambda t, r: shelf_of(t))),
    ("multiplying always makes bigger", _oven(lambda t, r: "same" if t[0] == t[1] else "big")),
    ("a fraction always shrinks", _oven(lambda t, r: "big" if t[1] == 1 and t[0] > 1 else
                                        ("same" if t[0] == t[1] else "small"))),
    ("bigger numbers on the dial grow more", _oven(lambda t, r: "same" if t[0] == t[1] else
                                                   ("big" if t[0] + t[1] > 6 else "small"))),
    ("random shelves", _oven(lambda t, r: r.choice(["small", "same", "big"]))),
]


# --- (e) the Scoops --------------------------------------------------------------------------------------------------------
SCOOPS = [(6, F(3, 4)), (F(3, 4), F(1, 8)), (2, F(2, 5)), (F(2, 3), F(1, 6)), (3, F(1, 4)), (5, F(1, 3)), (4, F(1, 2)),
          (2, F(1, 3)), (3, F(3, 8)), (F(3, 2), F(1, 4)), (4, F(2, 3)), (1, F(1, 6))]


def scoop_order(rng):
    d, s = rng.choice(SCOOPS)
    return F(d), s


SCOOP_PLAYERS = [
    ("knows: how many scoops fit (D ÷ s)", lambda o, r: o[0] / o[1]),
    ("division makes smaller (multiplies)", lambda o, r: round(o[0] * o[1])),
    ("flips the wrong one (s ÷ D, as many)", lambda o, r: max(1, round(o[1] / o[0]))),
    ("whole cups only (one mould a cup)", lambda o, r: max(1, int(o[0]))),
    ("random moulds", lambda o, r: r.randint(1, 24)),
]


# --- (f) the Recipe Book ---------------------------------------------------------------------------------------------------
def recipe_order(rng):
    while True:
        a, b = rng.randint(1, 5), rng.randint(1, 5)
        if a != b and gcd(a, b) == 1:
            m = rng.randint(2, 4)
            if b * m <= 20:
                return a, b, m


RECIPE_PLAYERS = [
    ("knows: the same times as much (ratio)", lambda o, r: o[1] * o[2]),
    ("adds the same amount (additive, Karplus)", lambda o, r: o[1] + (o[0] * o[2] - o[0])),
    ("keeps the butter the same", lambda o, r: o[1]),
    ("adds the batch number", lambda o, r: o[1] + o[2]),
    ("random scoops", lambda o, r: r.randint(1, 20)),
]


# --- (g) the Night Market (the whole matters) --------------------------------------------------------------------------
def market_order(rng):
    while True:
        t = rng.choice([F(1, 2), F(1, 3), F(1, 4), F(2, 3), F(3, 4), F(1, 6)])
        size = rng.choice([2, 3])
        need = t / size                    # the fraction of the big cake that is the same amount
        if need.denominator <= 12:
            return t, size


MARKET_PLAYERS = [
    ("knows: the same amount, so a smaller fraction", lambda o, r: o[0] / o[1]),
    ("habit: the same fraction (1/2 of the big cake)", lambda o, r: o[0]),
    ("random cut and count", lambda o, r: F(r.randint(1, 6), r.choice(KNIFE))),
]


# --- (h) the Hundred Tray ------------------------------------------------------------------------------------------------
def tray_make_order(rng):
    tenths = rng.random() < 0.5
    return F(rng.randint(1, 9), 10) if tenths else F(rng.randint(1, 99), 100)


def tray_queue_order_draft(rng):
    """First draft: four of five decimal cards near each other."""
    while True:
        base = rng.randint(1, 9)
        cands = {f"0.{base}", f"0.{base - 1 if base > 1 else base + 1}5", f"0.{base}0{rng.randint(1, 9)}",
                 f"0.{rng.randint(1, 9)}{rng.randint(1, 9)}", f"0.0{rng.randint(1, 9)}"}
        cands = list(cands)
        if len({F(c) for c in cands}) == len(cands) >= 4:
            rng.shuffle(cands)
            return cands[:4]


def tray_queue_order(rng):
    """Final: every queue holds the trap 0.4, 0.405, 0.45 (longer-is-larger puts 0.405 last, shorter-is-larger puts 0.4
    last) and one more card."""
    while True:
        b = rng.randint(1, 8)
        cands = [f"0.{b}", f"0.{b}0{rng.randint(1, 9)}", f"0.{b}5", f"0.{rng.randint(1, 9)}{rng.randint(1, 9)}"]
        if len({F(c) for c in cands}) == 4:
            rng.shuffle(cands)
            return cands


def card(f):
    """The order card's numeral: 3/10 -> '0.3', 45/100 -> '0.45', 1/20 -> '0.05'."""
    return str(float(f))


def _after_point(s):
    return s.split(".")[1]


def tray_rule(o, r):
    return o if not isinstance(o, list) else sorted(o, key=F)


def tray_longer(o, r):
    """Longer is larger (Steinle & Stacey): the digits after the point read as a whole number of squares; in a queue,
    0.405 > 0.45 > 0.5 because 405 > 45 > 5."""
    if isinstance(o, list):
        return sorted(o, key=lambda s: int(_after_point(s)))
    return F(int(_after_point(card(o))), 100)


def tray_shorter(o, r):
    """Shorter is larger: more digits after the point means smaller pieces, so a smaller number; makes amounts right."""
    if isinstance(o, list):
        return sorted(o, key=lambda s: (-len(_after_point(s)), F(s)))
    return o


TRAY_PLAYERS = [
    ("knows: tenths are rows, hundredths squares", tray_rule),
    ("longer is larger (the digits as a whole number)", tray_longer),
    ("shorter is larger (more digits, smaller)", tray_shorter),
    ("random", lambda o, r: (F(r.randint(1, 99), 100) if not isinstance(o, list) else r.sample(o, len(o)))),
]


def tray_right(order, answer):
    if isinstance(order, list):
        return [F(s) for s in answer] == sorted(F(s) for s in order)
    return answer == order


# --- running ---------------------------------------------------------------------------------------------------------------
def room(name, n, make, players, right, seed0):
    print(name)
    for pname, player in players:
        solved = []
        for v in range(n):
            rng = random.Random(seed0 + v)
            s = 0
            for i in range(6):
                order = make(rng, i)
                s += 1 if right(order, player(order, rng)) else 0
            solved.append(s)
        bar = sum(1 for s in solved if mastered(s, 6)) / n
        print(f"  {pname:50} {100 * bar:6.1f}%  {statistics.mean(solved):5.2f} of 6")
    print()


def oven_right(cakes, shelves):
    return shelves == [shelf_of(t) for t in cakes]


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 1000
    if "--draft" in sys.argv:
        print("FIRST DRAFTS (changed by this model)\n")
        room("(b) draft: boxes anywhere in (0, 2]", n, line_order_draft, LINE_PLAYERS,
             lambda o, stop: stop == F(o[0], o[1]), 40_000)
        room("(c) draft: four random cards", n, queue_order_draft, QUEUE_PLAYERS, queue_right, 50_000)
        room("(d) draft: one cake an order", n, oven_order_draft, OVEN_PLAYERS, oven_right, 60_000)
        room("(h) draft: decimal queues without the trap", n,
             lambda r, i: tray_make_order(r) if i < 3 else tray_queue_order_draft(r), TRAY_PLAYERS, tray_right, 100_000)
        print("FINAL\n")
    room("(a) The Tin Oven, mixed tins (5.NF.1)", n, lambda r, i: tin_order(r), TIN_PLAYERS, tin_right, 30_000)
    room("(b) The Baguette Counter, 0 to 2 (3.NF.2, 3.NF.3c)", n, line_order, LINE_PLAYERS,
         lambda o, stop: stop == F(o[0], o[1]), 40_000)
    room("(c) The Queue (4.NF.2)", n, queue_order, QUEUE_PLAYERS, queue_right, 50_000)
    room("(d) The Size Oven (5.NF.5)", n, oven_order, OVEN_PLAYERS, oven_right, 60_000)
    room("(e) The Scoops (5.NF.7, 6.NS.1)", n, lambda r, i: scoop_order(r), SCOOP_PLAYERS,
         lambda o, a: F(a) == o[0] / o[1], 70_000)
    room("(f) The Recipe Book (6.RP.3a)", n, lambda r, i: recipe_order(r), RECIPE_PLAYERS,
         lambda o, a: a == o[1] * o[2], 80_000)
    room("(g) The Night Market: the same whole? (4.NF.2; transfer)", n, lambda r, i: market_order(r), MARKET_PLAYERS,
         lambda o, a: a * o[1] == o[0], 90_000)
    room("(h) The Hundred Tray (4.NF.6, 5.NBT.3)", n, lambda r, i: tray_make_order(r) if i < 3 else tray_queue_order(r),
         TRAY_PLAYERS, tray_right, 100_000)


if __name__ == "__main__":
    main()
