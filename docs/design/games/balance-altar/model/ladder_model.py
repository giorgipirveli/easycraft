"""Phase A's model of the ladder's later altars (docs/design/games/balance-altar.md §3.6, §3.9): does guessing lose and
does the old habit fail there too?

(a) Crystals on both pans (rung 8, 8.EE.7): a x + b = c x + d. The arithmetic habit ('unwind': take away what is beside
    the crystal, then share by its count; Knuth et al. 2006) works on one-sided equations and fails here, because the
    crystals on the other pan never divide (the didactic cut: Filloy & Rojano 1989, Herscovics & Linchevski 1994). The
    rule gathers the crystals first (take the smaller count off both pans).
(b) Breathing crystals (rung 6-7, 6.EE.3-4 and 7.EE.1): the left pan holds a recipe box, e.g. 3 x [crystal + 4 gems];
    the child builds the right pan from crystals and gems; the beam is locked until the lever is pulled, then the
    crystal breathes through three sizes (2, 5, 8) and the altar must stay level at every one. Only the equivalent
    expression passes; the distributive error (3x + 4, Kuchemann's n + 20), conjoining (7x for 3x + 4) and matching
    the weight at one size fail.
(c) The leaning altar (rung 7, 7.EE.4b): p x + q > r and its kin; the twin moves are the equation's, the beam stays
    tipped; with p < 0 the mirror (gems <-> balloons) flips which pan is heavier. Then the child lights the solution on
    the floor's number line (which side, and whether the boundary stone is lit: level counts for >= and <=). Treating it
    as an equation (Tsamir & Almog 2001) or keeping the old direction after the mirror fails.
(d) Twin altars (rung 8, 8.EE.8): x + y = s beside x = y + d. A search over every twin move on the first altar alone
    shows no sequence frees either crystal; the swap (justified by the second altar) frees it in two or three moves.

Run: /usr/bin/python3 -I docs/design/games/balance-altar/model/ladder_model.py 1000
Result (2026-10-18, 1,000 visits each; the share reaching 5 of 6):
(a) knows the rule 100 %, slips 4 % 88.1 %, the unwind habit 0 % (0 of 6), greedy 100 %, no plan 0 %, guesses 0 %,
    random taps 0 %, one pan only 0 %.
(b) knows the rule 100 %; the distributive error, conjoining, matching one size, guessing the gems, a random build: 0 %.
(c) knows the rule 100 %; treating it as an equation 0 %; forgetting the mirror's flip 0 % (3 of 6); random 0.5 %.
(d) one altar alone, every twin move to depth 7: 1,576 states, no crystal freed; after one swap: two moves.
"""
import importlib.util
import os
import random
import statistics
import sys
from collections import deque
from fractions import Fraction as F

sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("altar_rules", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                            "altar_rules.py"))
R = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(R)


# --- (a) Crystals on both pans ---------------------------------------------------------------------------------------------
TWIN = ["twin_L", "twin_R", "twin_L", "twin_L", "twin_R", "twin_L"]
TWIN_PLAYERS = [
    ("knows the rule", R.bot_rule),
    ("knows it, slips 4 %", R.bot_rule_slips(0.04)),
    ("unwind habit (one-sided)", R.bot_habit),
    ("keeps balance, greedy", R.bot_greedy_legal),
    ("keeps balance, no plan", R.bot_legal_random),
    ("guesses which move", R.bot_op_guess),
    ("random taps", None),
    ("one pan only", R.bot_one_pan),
]


def twin_visit(bot, seed):
    rng = random.Random(20_000 + seed)
    out = []
    for form in TWIN:
        s, x = R.make(form, rng)
        out.append(R.play_taps(s, x, R.TWIN, rng) if bot is None else R.play(s, x, R.TWIN, bot, rng))
    return out


# --- (b) Breathing crystals: build the equivalent pan ---------------------------------------------------------------------
BREATHS = (2, 5, 8)
BUILDS = ["box", "box", "sum", "box_plus", "box", "box_plus"]


def recipe(form, rng):
    """The left pan as (crystals p, gems q) in value, and the parts the child sees (k, a, b, or the two crystal heaps)."""
    if form == "box":                      # k x [crystal + a gems]
        k, a = rng.randint(2, 4), rng.randint(1, 5)
        return (k, k * a), {"k": k, "a": a, "b": 0}
    if form == "box_plus":                 # k x [crystal + a gems] + b gems
        k, a, b = rng.randint(2, 3), rng.randint(1, 4), rng.randint(1, 5)
        return (k, k * a + b), {"k": k, "a": a, "b": b}
    if form == "sum":                      # m crystals, n more crystals, q gems (like terms)
        m, n, q = rng.randint(1, 4), rng.randint(1, 4), rng.randint(1, 6)
        return (m + n, q), {"m": m, "n": n, "q": q}
    raise ValueError(form)


def build_rule(p, q, parts, rng):
    return p, q


def build_forget(p, q, parts, rng):        # multiplies only the crystal: k x [x + a] -> k x + a
    if "k" in parts:
        return parts["k"], parts["a"] + parts["b"]
    return p, q


def build_conjoin(p, q, parts, rng):       # adds unlike things together: 3x + 4 -> 7x
    return p + q, 0


def build_one_size(p, q, parts, rng):      # matches the weight at the size it saw first, in gems
    s0 = rng.randint(1, 9)
    return 0, p * s0 + q


def build_gem_guess(p, q, parts, rng):     # right crystals, gems guessed
    return p, rng.randint(0, 15)


def build_random(p, q, parts, rng):
    return rng.randint(0, 8), rng.randint(0, 15)


BUILD_PLAYERS = [
    ("knows the rule", build_rule),
    ("distributive error", build_forget),
    ("conjoins (3x + 4 = 7x)", build_conjoin),
    ("matches one size", build_one_size),
    ("crystals right, gems guessed", build_gem_guess),
    ("random build", build_random),
]


def breathe_visit(builder, seed):
    rng = random.Random(30_000 + seed)
    passed = 0
    for form in BUILDS:
        (p, q), parts = recipe(form, rng)
        c, g = builder(p, q, parts, rng)
        if all(c * s + g == p * s + q for s in BREATHS):
            passed += 1
    return passed


# --- (c) The leaning altar --------------------------------------------------------------------------------------------------
LEAN_TOOLS = frozenset({"bowls", "gem_bag", "pump", "mirror"})
FLIP = {">": "<", "<": ">", ">=": "<=", "<=": ">="}


def leaning(rng, negative):
    """p x + q (op) r with the boundary x0: returns the equation state, x0, op, and the true solution (side, lit)."""
    p = rng.randint(2, 3) * (-1 if negative else 1)
    x0 = rng.randint(-3, 6)
    q = rng.randint(1, 6)
    r = p * x0 + q
    op = rng.choice([">", "<", ">=", "<="])
    s = R.state(p, q, 0, r)
    true_op = FLIP[op] if p < 0 else op
    return s, x0, op, (true_op[0], "=" in true_op)


def mark_rule(op, mirrored, rng):
    o = FLIP[op] if mirrored else op
    return (o[0], "=" in o)


def mark_equation(op, mirrored, rng):      # treats it as an equation: lights only the boundary stone
    return ("=", True)


def mark_no_flip(op, mirrored, rng):       # keeps the direction it started with
    return (op[0], "=" in op)


def mark_random(op, mirrored, rng):
    return (rng.choice(["<", ">"]), rng.random() < 0.5)


LEAN_PLAYERS = [
    ("knows the rule", mark_rule),
    ("treats it as an equation", mark_equation),
    ("forgets the mirror's flip", mark_no_flip),
    ("random side and stone", mark_random),
]


def lean_visit(marker, seed):
    rng = random.Random(40_000 + seed)
    passed = 0
    for negative in (False, True, False, True, False, True):
        s, x0, op, truth = leaning(rng, negative)
        alt = R.play(s, F(x0), LEAN_TOOLS, R.bot_rule, rng)          # the twin moves: the equation's, done right
        mirrored = alt.s != s and negative                            # the rule mirrors exactly when p < 0
        clean = alt.outcome() == R.SOLVED
        if clean and marker(op, mirrored, rng) == truth:
            passed += 1
    return passed


# --- (d) Twin altars: one altar alone can never free a crystal ----------------------------------------------------------
def twin_altars_search(s_sum=9, depth=7):
    """Altar one is x + y = s (one blue, one rose | s gems). Every twin move on it alone (take or add any kind on both
    pans, share): breadth-first to `depth`. Returns (states seen, a freed state found?)."""
    start = (1, 1, 0, 0, 0, s_sum)                    # (Lx, Ly, Lk, Rx, Ry, Rk)
    seen = {start}
    queue = deque([(start, 0)])
    found = False

    def freed2(t):
        lx, ly, lk, rx, ry, rk = t
        alone_left = (lx, ly, lk) in ((1, 0, 0), (0, 1, 0)) and rx == 0 and ry == 0
        alone_right = (rx, ry, rk) in ((1, 0, 0), (0, 1, 0)) and lx == 0 and ly == 0
        return alone_left or alone_right

    while queue:
        t, d = queue.popleft()
        if freed2(t):
            found = True
            break
        if d >= depth:
            continue
        lx, ly, lk, rx, ry, rk = t
        moves = []
        for i, j in ((0, 3), (1, 4)):                 # take crystals of one kind off both pans
            for n in range(1, min(t[i], t[j]) + 1):
                u = list(t); u[i] -= n; u[j] -= n; moves.append(tuple(u))
        for n in range(1, min(max(lk, 0), max(rk, 0)) + 1):
            u = list(t); u[2] -= n; u[5] -= n; moves.append(tuple(u))
        for i, j in ((0, 3), (1, 4), (2, 5)):         # add crystals (the well) or gems to both pans
            for n in range(1, 4):
                u = list(t); u[i] += n; u[j] += n; moves.append(tuple(u))
        for n in range(2, 7):                         # share
            if all(v % n == 0 for v in t):
                moves.append(tuple(v // n for v in t))
        for u in moves:
            if u not in seen and all(v >= 0 for v in (u[0], u[1], u[3], u[4])):
                seen.add(u)
                queue.append((u, d + 1))
    return len(seen), found


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 1000

    print("(a) Crystals on both pans: a x + b = c x + d, six judged altars, the bar 5 of 6")
    print(f"  {'player':26} {'5 of 6':>7} {'solved/6':>8} {'breaks':>7}")
    for name, bot in TWIN_PLAYERS:
        visits = [twin_visit(bot, seed) for seed in range(n)]
        solved = [sum(1 for a in v if a.outcome() == R.SOLVED) for v in visits]
        bar = sum(1 for sv in solved if R.mastered(sv, len(TWIN))) / n
        breaks = statistics.mean(sum(a.breaks for a in v) for v in visits)
        print(f"  {name:26} {100 * bar:6.1f}% {statistics.mean(solved):8.2f} {breaks:7.2f}")

    print("(b) Breathing crystals: build the equivalent pan; level at sizes 2, 5 and 8; six judged altars")
    print(f"  {'player':30} {'5 of 6':>7} {'passed/6':>8}")
    for name, builder in BUILD_PLAYERS:
        res = [breathe_visit(builder, seed) for seed in range(n)]
        bar = sum(1 for r in res if R.mastered(r, len(BUILDS))) / n
        print(f"  {name:30} {100 * bar:6.1f}% {statistics.mean(res):8.2f}")

    print("(c) The leaning altar: p x + q > r (and <, >=, <=), half with p < 0 (the mirror); six judged altars")
    print(f"  {'player':30} {'5 of 6':>7} {'passed/6':>8}")
    for name, marker in LEAN_PLAYERS:
        res = [lean_visit(marker, seed) for seed in range(n)]
        bar = sum(1 for r in res if R.mastered(r, 6)) / n
        print(f"  {name:30} {100 * bar:6.1f}% {statistics.mean(res):8.2f}")

    seen, found = twin_altars_search()
    print(f"(d) Twin altars: x + y = 9 alone, every twin move to depth 7: {seen} states, a crystal freed: {found}")
    print("    with the swap (a blue crystal swapped for the second altar's rose crystal + d gems): x + y = 9, x = y + 3")
    s = R.state(2, 3, 0, 9)                            # after the swap: two rose crystals and 3 gems | 9 gems
    best = R.shortest(s, R.HALL)
    print(f"    -> 2 rose + 3 gems = 9 gems, freed in {len(best)} more moves: {best}")


if __name__ == "__main__":
    main()
