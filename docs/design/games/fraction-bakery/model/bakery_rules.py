"""Fraction Bakery: the bakery's rules, shared by phase A's models (docs/design/games/fraction-bakery.md §3.4-3.5b, §3.9).

The bench (what the child can cut and give):
  wholes   fresh pies, each one whole (1); the Fair Knife cuts a whole into n equal pieces of 1/n (n = 2..12)
  pieces   a multiset of piece sizes (exact Fractions); the knife can cut a piece of size s again into n pieces of s/n
           (re-cutting: an equivalent fraction made by splitting every piece)
Every act is final: a cut cannot be undone (design ruling 4) and the knife shows no preview of its lines on a judged order
(ruling 3), so the number of pieces is chosen before the cut, never searched for.

The orders (the forms of phase B; the later rooms are in ladder_model.py):
  share(n, p)          n fresh pies for a table of p buddies: every plate the same and nothing left on the bench
                       (each plate is then n/p: fractions as division; for n = 1 a unit fraction)
  box(a, b)            one buddy's takeaway box of a/b of a pie (the order card: a pie in b parts, a of them glowing; at
                       the numeral stage "a/b"), made from fresh pies; leftovers go to the shelf and are not judged
  shelf_box(t, shelf)  the same, at midnight: no fresh pies, only the shelf's pieces (and the knife to re-cut them)
  equalize(plates, shelf)  buddies who already hold different leftovers: add pieces from the shelf until every plate is
                       the same (fair)
The world's answer is the Fair Line (the counter's brass rail, one whole from post to post): a box or plate slides along
it piece by piece and stops at its amount; the buddy's flag then shows where it should have stopped. It moves only when
the child hands the order over (ruling 5), so it can never be used to measure before committing.

The evidence rule (§3.10): an order is SOLVED (NEW_SETTING in a transfer room) when the first hand-over is right, with no
help and within its cut budget (the fewest cuts that can make it, plus one). Anything else is HELPED (or SHOWN when the
ghost finished it); the models only need SOLVED, so every non-first-time answer is counted as not solved.

Everything is deterministic given a random.Random; the models load this file by its path, so they run with `python3 -I`.
"""
from collections import Counter
from fractions import Fraction as F
from math import gcd

KNIFE = tuple(range(2, 13))     # the Fair Knife's dial: 2 to 12 equal pieces
POW2 = (2, 4, 8)                # what a child who only halves can make (halve, halve again, again)
SOLVED, NOT = "solved", "not first time"
ONE = F(1)


def mastered(solved, total):
    """MasteryRules.is_mastery: right the first time at least 5 of every 6 (core/school/mastery_rules.gd)."""
    return total > 0 and solved * 6 >= 5 * total


# --- The bench -------------------------------------------------------------------------------------------------------------
class Bench:
    """Fresh pies and loose pieces; counts the knife's cuts. Illegal acts raise (the players must play fair)."""

    def __init__(self, wholes=0, shelf=None):
        self.wholes = wholes
        self.pieces = Counter(shelf or {})
        self.cuts = 0

    def cut_whole(self, n):
        assert self.wholes > 0 and n in KNIFE, (self.wholes, n)
        self.wholes -= 1
        self.pieces[F(1, n)] += n
        self.cuts += 1

    def cut_piece(self, size, n):
        assert self.pieces[size] > 0 and n in KNIFE, (size, n)
        self.pieces[size] -= 1
        self.pieces[size / n] += n
        self.cuts += 1

    def take(self, size, k=1):
        k = min(k, self.pieces[size])
        self.pieces[size] -= k
        return [size] * k

    def take_whole(self):
        assert self.wholes > 0
        self.wholes -= 1
        return [ONE]

    def sizes(self):
        return sorted((s for s, c in self.pieces.items() if c > 0), reverse=True)

    def left(self):
        return sum(c for c in self.pieces.values() if c > 0)

    def most_plentiful(self):
        live = [(c, s) for s, c in self.pieces.items() if c > 0]
        return max(live)[1] if live else None


# --- Orders ----------------------------------------------------------------------------------------------------------------
def share(n, p):
    return {"form": "share", "n": n, "p": p, "value": F(n, p)}


def box(a, b):
    return {"form": "box", "a": a, "b": b, "value": F(a, b)}


def shelf_box(target, shelf):
    return {"form": "shelf_box", "value": F(target), "shelf": dict(shelf)}


def equalize(plates, shelf):
    return {"form": "equalize", "plates": [list(p) for p in plates], "shelf": dict(shelf)}


def bench_for(order, fresh_at_midnight=0):
    f = order["form"]
    if f == "share":
        return Bench(wholes=order["n"])
    if f == "box":
        return Bench(wholes=-(-order["a"] // order["b"]) + 2)      # a pie or two more than needed: a wrong cut can't strand
    return Bench(wholes=fresh_at_midnight, shelf=order["shelf"])


# --- Making an amount from pieces (exact; small search) ------------------------------------------------------------------
def make_from(pieces, target, prefer_big=True):
    """A Counter of pieces (size -> count) taken from `pieces` that sums exactly to `target`, or None."""
    sizes = sorted((s for s, c in pieces.items() if c > 0), reverse=prefer_big)
    best = [None]

    def go(i, rem, took):
        if rem == 0:
            best[0] = Counter(took)
            return True
        if i == len(sizes) or rem < 0:
            return False
        s = sizes[i]
        most = min(pieces[s], int(rem / s))
        for k in range(most, -1, -1):
            if k:
                took[s] = k
            elif s in took:
                del took[s]
            if go(i + 1, rem - k * s, took):
                return True
        took.pop(s, None)
        return False

    go(0, F(target), {})
    return best[0]


def plan_target(bench_pieces, target, max_cuts=2, halving_only=False):
    """The fewest re-cuts (each a piece cut into n) after which `target` can be taken from the pieces: (cuts, take)."""
    knife = POW2 if halving_only else KNIFE
    start = Counter({s: c for s, c in bench_pieces.items() if c > 0})
    frontier = [(start, [])]
    for depth in range(max_cuts + 1):
        nxt = []
        for pieces, cuts in frontier:
            take = make_from(pieces, target)
            if take is not None:
                return cuts, take
            if depth == max_cuts:
                continue
            for s in sorted(pieces):
                if pieces[s] <= 0:
                    continue
                for n in knife:
                    p2 = Counter(pieces)
                    p2[s] -= 1
                    p2[s / n] += n
                    nxt.append((p2, cuts + [(s, n)]))
        frontier = nxt
    return None


def min_cuts(order):
    f = order["form"]
    if f == "share":
        return order["n"] % order["p"]              # each pie left after the whole ones is cut once
    if f == "box":
        return 0 if order["a"] % order["b"] == 0 else 1
    if f == "shelf_box":
        plan = plan_target(Counter(order["shelf"]), order["value"])
        return len(plan[0]) if plan else 99
    if f == "equalize":
        plan = plan_equalize(order["plates"], Counter(order["shelf"]))
        return plan[0] if plan else 99
    raise ValueError(f)


def plan_equalize(plates, shelf, halving_only=False):
    """Fill every plate up to the biggest one from the shelf (the fewest cuts, plate by plate): (cuts, adds) or None."""
    top = max(sum(p) for p in plates)
    pieces = Counter(shelf)
    cuts = 0
    adds = []
    for p in plates:
        need = top - sum(p)
        if need == 0:
            adds.append(Counter())
            continue
        plan = plan_target(pieces, need, halving_only=halving_only)
        if plan is None:
            return None
        cs, take = plan
        for s, n in cs:
            pieces[s] -= 1
            pieces[s / n] += n
        for s, k in take.items():
            pieces[s] -= k
        cuts += len(cs)
        adds.append(take)
    return cuts, adds


# --- The judge (the Fair Line) ---------------------------------------------------------------------------------------------
def judge(order, bench, handed):
    """`handed` is the plates (share, equalize) or the box (box, shelf_box) at the first hand-over."""
    f = order["form"]
    if f == "share":
        amounts = {sum(pl) for pl in handed}
        right = bench.wholes == 0 and bench.left() == 0 and len(amounts) == 1 and len(handed) == order["p"]
    elif f == "equalize":
        right = len({sum(pl) for pl in handed}) == 1
    else:
        right = sum(handed) == order["value"]
    within = bench.cuts <= min_cuts(order) + 1
    return SOLVED if right and within else NOT


def run(order, player, rng, fresh_at_midnight=0):
    bench = bench_for(order, fresh_at_midnight)
    handed = player(order, bench, rng)
    return judge(order, bench, handed)


# --- Shared moves ----------------------------------------------------------------------------------------------------------
def deal(bench, plates, sizes=None):
    """Deal every loose piece round-robin onto the plates (biggest pieces first), as a child deals cards."""
    i = 0
    for s in (sizes or bench.sizes()):
        while bench.pieces[s] > 0:
            plates[i % len(plates)] += bench.take(s)
            i += 1
    return plates


def deal_even(bench, plates):
    """Deal round-robin but stop before any plate would get more pieces than another (the rest stays on the bench)."""
    for s in bench.sizes():
        k = bench.pieces[s] // len(plates)
        for pl in plates:
            pl += bench.take(s, k)
    return plates


def nearest_pow2(k):
    return min(POW2, key=lambda h: (abs(h - k), -h))


def take_plan(bench, plan):
    cuts, take = plan
    for s, n in cuts:
        bench.cut_piece(s, n)
    out = []
    for s, k in take.items():
        out += bench.take(s, k)
    return out


# --- The players (bots): children with and without the knowledge ---------------------------------------------------------
def p_rule(order, bench, rng):
    """Knows what a fraction is: equal parts, the bottom number the size, the top the count; looks at every piece's size."""
    f = order["form"]
    if f == "share":
        n, p = order["n"], order["p"]
        q, r = divmod(n, p)
        plates = [[] for _ in range(p)]
        for pl in plates:
            for _ in range(q):
                pl += bench.take_whole()
        if r:
            k = p // gcd(r, p)
            for _ in range(r):
                bench.cut_whole(k)
            deal(bench, plates)
        return plates
    if f == "box":
        a, b = order["a"], order["b"]
        out = []
        while a >= b:
            out += bench.take_whole()
            a -= b
        if a:
            bench.cut_whole(b)
            out += bench.take(F(1, b), a)
        return out
    if f == "shelf_box":
        plan = plan_target(bench.pieces, order["value"])
        return take_plan(bench, plan) if plan else []
    if f == "equalize":
        plates = [list(p) for p in order["plates"]]
        plan = plan_equalize(plates, bench.pieces)
        if not plan:
            return plates
        top = max(sum(p) for p in plates)
        for pl in plates:
            need = top - sum(pl)
            if need:
                pl += take_plan(bench, plan_target(bench.pieces, need))
        return plates
    raise ValueError(f)


def p_slips(rate):
    """The rule, with a slip on `rate` of its two decisions per order: the knife set one click off (the cut stays), or a
    count off by one that survives to the bell (a misdealt piece is in plain sight on the plates and moving pieces before
    the bell is free, ruling 6, so only a slip the child does not notice is modelled)."""
    def player(order, bench, rng):
        f = order["form"]
        knife_slip = rng.random() < rate
        count_slip = rng.random() < rate
        if f == "box" and (knife_slip or count_slip):
            a, b = order["a"], order["b"]
            b2 = max(2, min(12, b + rng.choice((-1, 1)))) if knife_slip else b
            bench.cut_whole(b2)
            return bench.take(F(1, b2), max(1, a + (rng.choice((-1, 1)) if count_slip else 0)))
        if f == "share" and knife_slip and order["n"] % order["p"]:
            n, p = order["n"], order["p"]
            q, r = divmod(n, p)
            plates = [[] for _ in range(p)]
            for pl in plates:
                for _ in range(q):
                    pl += bench.take_whole()
            k = max(2, min(12, p // gcd(r, p) + rng.choice((-1, 1))))
            for _ in range(r):
                bench.cut_whole(k)
            deal_even(bench, plates)
            return plates
        handed = p_rule(order, bench, rng)
        if count_slip:
            if f in ("share", "equalize"):
                src = [pl for pl in handed if pl]
                if src and len(handed) > 1:
                    a = rng.choice(src)
                    b = rng.choice([pl for pl in handed if pl is not a])
                    b.append(a.pop())             # a piece on the wrong plate, unnoticed
            elif f == "shelf_box" and handed:
                handed = handed[:-1] if rng.random() < 0.5 else handed + bench.take(bench.most_plentiful() or ONE)
        return handed
    return player


def p_random(order, bench, rng):
    """Random cuts and random gives: the knife set anywhere, pieces dropped anywhere."""
    f = order["form"]
    if f == "share":
        plates = [[] for _ in range(order["p"])]
        while bench.wholes:
            if rng.random() < 1 / 12:
                rng.choice(plates).extend(bench.take_whole())
            else:
                bench.cut_whole(rng.choice(KNIFE))
        for s in bench.sizes():
            for _ in range(bench.pieces[s]):
                if rng.random() < 0.9:
                    rng.choice(plates).extend(bench.take(s))
        return plates
    if f == "box":
        n = rng.choice(KNIFE)
        bench.cut_whole(n)
        return bench.take(F(1, n), rng.randint(1, n))
    if f == "shelf_box":
        if rng.random() < 0.3 and bench.sizes():
            bench.cut_piece(rng.choice(bench.sizes()), rng.choice(KNIFE))
        out = []
        for _ in range(rng.randint(1, 6)):
            if bench.sizes():
                out += bench.take(rng.choice(bench.sizes()))
        return out
    if f == "equalize":
        plates = [list(p) for p in order["plates"]]
        for _ in range(rng.randint(1, 3)):
            if bench.sizes():
                rng.choice(plates).extend(bench.take(rng.choice(bench.sizes())))
        return plates
    raise ValueError(f)


def p_halver(order, bench, rng):
    """Only halves (Pothier & Sawada's halving): cuts into 2, 4 or 8, the nearest to what is needed; knows sizes."""
    f = order["form"]
    if f == "share":
        n, p = order["n"], order["p"]
        q, r = divmod(n, p)
        plates = [[] for _ in range(p)]
        for pl in plates:
            for _ in range(q):
                pl += bench.take_whole()
        if r:
            h = nearest_pow2(p // gcd(r, p))
            for _ in range(r):
                bench.cut_whole(h)
            deal_even(bench, plates)
        return plates
    if f == "box":
        a, b = order["a"], order["b"]
        h = nearest_pow2(b)
        bench.cut_whole(h)
        return bench.take(F(1, h), max(1, round(a * h / b)))
    if f == "shelf_box":
        plan = plan_target(bench.pieces, order["value"], halving_only=True)
        if plan:
            return take_plan(bench, plan)
        return bench.take(bench.most_plentiful(), max(1, int(order["value"] / bench.most_plentiful())))
    if f == "equalize":
        plates = [list(p) for p in order["plates"]]
        top = max(sum(p) for p in plates)
        for pl in plates:
            need = top - sum(pl)
            if need:
                plan = plan_target(bench.pieces, need, halving_only=True)
                if plan:
                    pl += take_plan(bench, plan)
        return plates
    raise ValueError(f)


def p_fine_dealer(order, bench, rng):
    """Cuts every pie into the most pieces (12) and deals them round-robin; for a box, cuts by the bottom number."""
    if order["form"] == "share":
        n, p = order["n"], order["p"]
        q, r = divmod(n, p)
        plates = [[] for _ in range(p)]
        for pl in plates:
            for _ in range(q):
                pl += bench.take_whole()
        for _ in range(r):
            bench.cut_whole(12)
        deal_even(bench, plates)
        return plates
    return p_rule(order, bench, rng)


def p_one_pie(order, bench, rng):
    """'One piece for each buddy': cuts one pie into as many pieces as buddies and leaves the other pies."""
    if order["form"] == "share":
        p = order["p"]
        bench.cut_whole(p)
        return [bench.take(F(1, p)) for _ in range(p)]
    return p_rule(order, bench, rng)


def p_swap(order, bench, rng):
    """Turns n/p round (Hoot's '8 ÷ 3 is not 3/8'): cuts each pie into as many pieces as there are pies; a/b as b/a."""
    f = order["form"]
    if f == "share":
        n, p = order["n"], order["p"]
        plates = [[] for _ in range(p)]
        if n == 1:
            plates[0] += bench.take_whole()
            return plates
        while bench.wholes:
            bench.cut_whole(n)
        deal(bench, plates)
        return plates
    if f == "box":
        a, b = order["a"], order["b"]
        if a == 1:
            out = []
            for _ in range(min(b, bench.wholes)):
                out += bench.take_whole()
            return out
        out = []
        while len(out) < b and bench.wholes:
            bench.cut_whole(a)
            out += bench.take(F(1, a), b - len(out))
        return out
    return p_rule(order, bench, rng)


def p_count_habit(order, bench, rng):
    """Opening Night's habit without its idea: 'the top number is how many pieces I give', whatever their size; 'fair
    means the same number of pieces'. With a fresh pie it cuts by the bottom number (and is right)."""
    f = order["form"]
    if f in ("share", "box"):
        return p_rule(order, bench, rng)
    if f == "shelf_box":
        t = order["value"]
        if bench.wholes:
            bench.cut_whole(t.denominator)
            return bench.take(F(1, t.denominator), t.numerator)
        return bench.take(bench.most_plentiful(), t.numerator)
    if f == "equalize":
        plates = [list(p) for p in order["plates"]]
        most = max(len(p) for p in plates)
        for pl in plates:
            while len(pl) < most and bench.sizes():
                pl += bench.take(bench.most_plentiful())
        return plates
    raise ValueError(f)


def p_wnb(order, bench, rng):
    """Whole-number bias: a bigger bottom number means a bigger piece (1/8 > 1/4 because 8 > 4); counts tops."""
    f = order["form"]
    if f in ("share", "box"):
        return p_rule(order, bench, rng)        # sharing and reading a/b by counting need no comparing
    if f == "shelf_box":
        return p_count_habit(order, bench, rng)
    if f == "equalize":
        plates = [list(p) for p in order["plates"]]
        # it believes the plate whose pieces have the smallest bottom number is the smallest, and tops it up with the
        # biggest-looking pieces (the biggest bottom number) until it 'looks' as big as the others
        def believed(pl):
            return sum(F(s.denominator, 12) for s in pl)
        order_ = sorted(plates, key=believed)
        top = max(believed(p) for p in plates)
        for pl in order_:
            while believed(pl) < top and bench.sizes():
                pl += bench.take(min(bench.sizes()))
        return plates
    raise ValueError(f)


def p_greedy(order, bench, rng):
    """Knows sizes, plans nothing: the biggest piece that still fits, again and again; re-cuts the smallest piece too big
    for what is missing into the needed size."""
    f = order["form"]
    if f in ("share", "box"):
        return p_rule(order, bench, rng)

    def fill(need):
        out = []
        while need > 0:
            fits = [s for s in bench.sizes() if s <= need]
            if fits:
                s = fits[0]
                out += bench.take(s)
                need -= s
                continue
            bigger = [s for s in bench.sizes() if s > need]
            if not bigger:
                break
            s = bigger[-1]
            ratio = s / need
            n = ratio.numerator if ratio.denominator == 1 and ratio.numerator in KNIFE else None
            if n is None:
                n = next((m for m in KNIFE if (s / m) <= need and (need / (s / m)).denominator == 1), None)
            if n is None:
                break
            bench.cut_piece(s, n)
        return out

    if f == "shelf_box":
        return fill(order["value"])
    plates = [list(p) for p in order["plates"]]
    top = max(sum(p) for p in plates)
    for pl in plates:
        pl += fill(top - sum(pl))
    return plates


def p_trial(order, bench, rng):
    """Trial and error with our knife: sets a random count, cuts (it stays cut), then gives what looks closest to the
    order (it can judge 'about how much'); for a table, cuts every pie the same and deals as evenly as it can."""
    f = order["form"]
    if f == "share":
        n, p = order["n"], order["p"]
        q, r = divmod(n, p)
        plates = [[] for _ in range(p)]
        for pl in plates:
            for _ in range(q):
                pl += bench.take_whole()
        k = rng.choice(KNIFE)
        for _ in range(r):
            bench.cut_whole(k)
        deal_even(bench, plates)
        return plates
    if f == "box":
        k = rng.choice(KNIFE)
        bench.cut_whole(k)
        return bench.take(F(1, k), max(1, round(order["a"] * k / order["b"])))
    return p_rule(order, bench, rng)


def p_undo_search(order, bench, rng):
    """NOT OUR DESIGN: a knife with an undo (or a live preview of its lines) lets trial and error try every count until
    the pieces come out fair, at no cost: it always ends on a right answer with no wasted cut."""
    return p_rule(order, bench, rng)


PLAYERS_OPENING = [
    ("knows what a fraction is", p_rule),
    ("knows it, slips 4 %", p_slips(0.04)),
    ("whole-number bias", p_wnb),
    ("always halves (2, 4, 8)", p_halver),
    ("cuts in twelfths, deals", p_fine_dealer),
    ("one piece each, one pie", p_one_pie),
    ("turns n/p round", p_swap),
    ("random cuts and gives", p_random),
    ("trial and error (the cut stays)", p_trial),
    ("trial and error (undo: not ours)", p_undo_search),
]

PLAYERS_MIDNIGHT = [
    ("knows what a fraction is", p_rule),
    ("knows it, slips 4 %", p_slips(0.04)),
    ("Opening Night's habit (counts tops)", p_count_habit),
    ("whole-number bias", p_wnb),
    ("greedy (biggest piece first)", p_greedy),
    ("always halves (2, 4, 8)", p_halver),
    ("random cuts and gives", p_random),
]
