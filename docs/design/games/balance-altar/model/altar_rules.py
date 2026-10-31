"""Balance Altar: the altar's rules, shared by phase A's models (docs/design/games/balance-altar.md §3.4-3.6, §3.9, §3.10).

What a pan holds (net amounts: a gem and a balloon on the same pan cancel by themselves, a zero pair that floats off):
  c  crystals: positive = frozen crystals (each weighs x), negative = crystal balloons (each lifts x; rung 7+)
  k  gems (+1 each) when positive, balloons (-1 each) when negative
An altar is two pans, L and R, that balance for the crystal's true weight x: L.c*x + L.k == R.c*x + R.k.

The verbs, each a TWIN MOVE (the same done to both pans):
  ("take", kind, n)   lift n gems / balloons / crystals / crystal balloons off BOTH pans
  ("add", kind, n)    put n gems (the gem bag), balloons (the balloon pump) or crystals (the crystal well) on BOTH pans
  ("share", n)        split BOTH pans into n equal shares and keep one (only if every amount divides by n)
  ("copy", n)         make BOTH pans n times as much (the echo bell; rung 7, for shards)
  ("mirror",)         every gem becomes a balloon and back, every crystal a crystal balloon and back (rung 7)
Anything else is refused, a RULE BREAK: lifting from one pan and then doing something other than the twin, carrying an
item across to the other pan, an unfair share. The frozen crystal's chains hold the beam level, so a refused move
rattles the chains, springs back and changes nothing, and the beam never shows which pan is heavier (design ruling 3:
the crystal is found only by keeping the balance, never by weighing it).

The crystal is freed when it stands alone on its pan (one crystal, nothing else) and the other pan holds no crystal;
the other pan then shows its weight (a balloon there: the crystal floats, a negative number; rung 7+).

The help policy is the design's (§3.8): every second rule break the ghost does the next step of a shortest solution
(the altar is then HELPED); if the child has not freed the crystal after CAP actions, the ghost finishes it (SHOWN).
An altar is SOLVED (or NEW_SETTING in a transfer room) only if the child freed it with no rule break, no help and within
its move budget (§3.10, budget()): a one-move altar in one move, a longer one with at most one move more than its
shortest solution. Consecutive commits of the same verb and kind are one operation (taking three gem pairs one by one
is "take the gems").

Everything here is deterministic given a random.Random; the models (hall_model.py, sky_room_model.py,
ladder_model.py) load this file by its path, so they run with `python3 -I`.
"""
from collections import deque
from fractions import Fraction as F

SOLVED, HELPED, SHOWN = "solved", "helped", "shown"
CAP = 40            # actions before the ghost finishes the altar
MAX_ADD = 12        # the most a supply move puts on each pan in one go
MAX_SHARE = 12      # the most bowls

# The tools a room offers (taking with the hands is always there).
HALL = frozenset({"bowls", "gem_bag"})
SKY = frozenset({"bowls", "gem_bag", "pump"})
TWIN = frozenset({"bowls", "gem_bag", "pump"})


# --- The state: (Lc, Lk, Rc, Rk), Fractions ------------------------------------------------------------------------------
def state(lc, lk, rc, rk):
    return (F(lc), F(lk), F(rc), F(rk))


def pan(s, side):
    return (s[0], s[1]) if side == 0 else (s[2], s[3])


def holds(s, x):
    return s[0] * x + s[1] == s[2] * x + s[3]


def amount(s, side, kind):
    c, k = pan(s, side)
    if kind == "gem":
        return max(k, 0)
    if kind == "balloon":
        return max(-k, 0)
    if kind == "crystal":
        return max(c, 0)
    if kind == "crystal_balloon":
        return max(-c, 0)
    raise ValueError(kind)


def freed(s):
    lc, lk, rc, rk = s
    return (lc == 1 and lk == 0 and rc == 0) or (rc == 1 and rk == 0 and lc == 0)


def crystal_side(s):
    """The pan the crystal is to be freed on: the only pan with crystals (or crystal balloons), else the one with more
    crystals (the left on a tie)."""
    if s[0] != 0 and s[2] == 0:
        return 0
    if s[2] != 0 and s[0] == 0:
        return 1
    return 0 if s[0] >= s[2] else 1


def clutter(s):
    """How far the crystal is from alone: extra crystals and loose items on its pan, crystals on the other pan."""
    side = crystal_side(s)
    c, k = pan(s, side)
    oc, _ = pan(s, 1 - side)
    return abs(c - 1) + abs(k) + abs(oc)


# --- The twin moves ------------------------------------------------------------------------------------------------------
SUPPLY = {"gem": "gem_bag", "balloon": "pump", "crystal": "well"}


def legal(s, op, tools):
    verb = op[0]
    if verb == "take":
        _, kind, n = op
        return n >= 1 and amount(s, 0, kind) >= n and amount(s, 1, kind) >= n
    if verb == "add":
        _, kind, n = op
        return SUPPLY.get(kind) in tools and 1 <= n <= MAX_ADD
    if verb == "share":
        n = op[1]
        return "bowls" in tools and 2 <= n <= MAX_SHARE and all((v / n).denominator == 1 for v in s)
    if verb == "copy":
        return "bell" in tools and 2 <= op[1] <= 6
    if verb == "mirror":
        return "mirror" in tools
    return False


def apply(s, op):
    lc, lk, rc, rk = s
    verb = op[0]
    if verb == "take":
        _, kind, n = op
        if kind == "gem":
            return (lc, lk - n, rc, rk - n)
        if kind == "balloon":
            return (lc, lk + n, rc, rk + n)
        if kind == "crystal":
            return (lc - n, lk, rc - n, rk)
        return (lc + n, lk, rc + n, rk)          # crystal balloons
    if verb == "add":
        _, kind, n = op
        if kind == "gem":
            return (lc, lk + n, rc, rk + n)
        if kind == "balloon":
            return (lc, lk - n, rc, rk - n)
        return (lc + n, lk, rc + n, rk)          # crystals from the well
    if verb == "share":
        n = op[1]
        return (lc / n, lk / n, rc / n, rk / n)
    if verb == "copy":
        n = op[1]
        return (lc * n, lk * n, rc * n, rk * n)
    if verb == "mirror":
        return (-lc, -lk, -rc, -rk)
    raise ValueError(op)


def legal_ops(s, tools, max_add=MAX_ADD):
    """Every legal twin move (takes of any size, adds up to max_add, shares by every n that divides)."""
    ops = []
    for kind in ("gem", "balloon", "crystal", "crystal_balloon"):
        m = int(min(amount(s, 0, kind), amount(s, 1, kind)))
        ops += [("take", kind, n) for n in range(1, m + 1)]
    for kind, tool in SUPPLY.items():
        if tool in tools:
            ops += [("add", kind, n) for n in range(1, max_add + 1)]
    if "bowls" in tools:
        ops += [("share", n) for n in range(2, MAX_SHARE + 1) if legal(s, ("share", n), tools)]
    if "bell" in tools:
        ops += [("copy", n) for n in range(2, 7)]
    if "mirror" in tools:
        ops.append(("mirror",))
    return ops


_MIN = {}


def shortest(s, tools, depth=5):
    """A shortest list of twin moves that frees the crystal (breadth-first), or None within `depth`."""
    key = (s, tools)
    if key in _MIN:
        return _MIN[key]
    seen = {s}
    queue = deque([(s, [])])
    found = None
    while queue:
        cur, path = queue.popleft()
        if freed(cur):
            found = path
            break
        if len(path) >= depth:
            continue
        for op in legal_ops(cur, tools):
            nxt = apply(cur, op)
            if nxt not in seen:
                seen.add(nxt)
                queue.append((nxt, path + [op]))
    _MIN[key] = found
    return found


# --- The altars a room offers (rung 6 numbers: at most 12-15 gems on a pan, so a child can count them) -------------------
def make(form, rng):
    """(state, x) for a form; the crystal's weight x is a whole number the child never sees until it is freed."""
    if form in ("add_L", "add_R"):                    # x + a = b
        x = rng.randint(1, 8)
        a = rng.randint(1, min(6, 12 - x))
        s = state(1, a, 0, x + a)
    elif form in ("mul_L", "mul_R"):                  # c x = b
        c = rng.randint(2, 4)
        x = rng.randint(1, 12 // c)
        s = state(c, 0, 0, c * x)
    elif form in ("two_L", "two_R"):                  # c x + a = b (the Great Altar)
        c = rng.randint(2, 3)
        x = rng.randint(1, 4)
        a = rng.randint(1, 4)
        s = state(c, a, 0, c * x + a)
    elif form in ("sub_L", "sub_R"):                  # x - a = b (balloons beside the crystal: the Sky Room)
        a = rng.randint(1, 5)
        b = rng.randint(1, 7)
        x = a + b
        s = state(1, -a, 0, b)
    elif form in ("subtwo_L",):                       # c x - a = b
        c = rng.randint(2, 3)
        x = rng.randint(2, 5)
        a = rng.randint(1, min(4, c * x - 1))
        s = state(c, -a, 0, c * x - a)
    elif form in ("twin_L", "twin_R"):                # a x + b = c x + d (crystals on both pans: rung 8)
        c = rng.randint(1, 3)
        a = c + rng.randint(1, 3)
        x = rng.randint(1, 5)
        b = rng.randint(0, 5)
        d = (a - c) * x + b
        s = state(a, b, c, d)
    else:
        raise ValueError(form)
    if form.endswith("_R"):
        s = (s[2], s[3], s[0], s[1])
    assert holds(s, x), (form, s, x)
    return s, x


# --- One altar, played by a bot ------------------------------------------------------------------------------------------
class Altar:
    """The child's side of one altar: twin moves commit, anything else is a rule break (help every second one)."""

    def __init__(self, s, x, tools, cap=CAP):
        self.s, self.x, self.tools, self.cap = s, x, tools, cap
        best = shortest(s, tools)
        self.min_ops = len(best) if best is not None else 99
        self.breaks = 0
        self.helped = False
        self.ops = 0                  # the child's operations (consecutive same verb and kind merged)
        self.last = None
        self.actions = 0
        self.by_ghost = False
        self.notes = []

    def done(self):
        return freed(self.s)

    def child(self, op):
        """The child tries a move. Misconception acts and illegal moves are rule breaks."""
        self.actions += 1
        if op[0] == "noop":                       # the free-beam counterfactual already moved the pans
            return True
        if op[0] in ("one_pan", "across", "weigh", "unfair") or not legal(self.s, op, self.tools):
            self.rule_break(op)
            return False
        self.s = apply(self.s, op)
        tag = op[:2] if op[0] in ("take", "add") else op[:1]
        if tag != self.last:
            self.ops += 1
            self.last = tag
        if self.done():
            self.by_ghost = False
        return True

    def rule_break(self, op):
        self.breaks += 1
        self.notes.append(op[0] if op[0] in ("one_pan", "across", "weigh") else "unfair " + op[0])
        if self.breaks % 2 == 0 and not self.done():
            self.ghost_step()

    def ghost_step(self):
        self.helped = True
        best = shortest(self.s, self.tools)
        if best:
            self.s = apply(self.s, best[0])
            self.last = None
            if self.done():
                self.by_ghost = True

    def finish(self):
        """The ghost finishes an altar the child could not."""
        while not self.done():
            self.ghost_step()
            if shortest(self.s, self.tools) is None:
                break
        self.by_ghost = True

    def outcome(self):
        if not self.done() or self.by_ghost:
            return SHOWN
        if self.breaks == 0 and not self.helped and self.ops <= budget(self.min_ops):
            return SOLVED
        return HELPED


def budget(min_ops):
    """The most operations a SOLVED altar may take: a one-move altar in one move (a detour there shows the child does not
    yet see which move undoes what); a longer altar may take one move more than its shortest solution."""
    return min_ops if min_ops <= 1 else min_ops + 1


def play(s, x, tools, bot, rng, cap=CAP):
    """Plays one altar with a bot (a function (Altar, rng) -> op) and returns the Altar."""
    alt = Altar(s, x, tools, cap)
    memo = {}
    while not alt.done() and alt.actions < cap:
        alt.child(bot(alt, rng, memo))
    if not alt.done():
        alt.finish()
    return alt


def mastered(solved, total):
    """MasteryRules.is_mastery: right the first time at least 5 of every 6 (core/school/mastery_rules.gd)."""
    return total > 0 and solved * 6 >= 5 * total


# --- The players (bots): children with and without the knowledge ---------------------------------------------------------
def _beside(s):
    side = crystal_side(s)
    c, k = pan(s, side)
    oc, ok = pan(s, 1 - side)
    return side, c, k, oc, ok


def bot_rule(alt, rng, memo):
    """Knows it: the same to both pans; gather the crystals on one pan; undo what is beside the crystal (take gems,
    a balloon is undone by a gem), then share by the crystal count; a crystal balloon is turned back by the mirror."""
    s = alt.s
    side, c, k, oc, ok = _beside(s)
    if c > 0 and oc > 0:                                  # crystals on both pans: gather them on one
        return ("take", "crystal", int(min(c, oc)))
    if c < 0 and oc < 0:
        return ("take", "crystal_balloon", int(min(-c, -oc)))
    if k > 0:                                             # gems beside the crystal: take them (or balloons undo them)
        if ok >= k:
            return ("take", "gem", int(k))
        return ("add", "balloon", int(k)) if "pump" in alt.tools else ("take", "gem", int(k))
    if k < 0:                                             # balloons beside the crystal: gems undo them
        return ("add", "gem", int(-k))
    if c < 0:                                             # crystal balloons: the mirror turns them back
        return ("mirror",)
    if c > 1:                                             # several crystals: share them out
        return ("share", int(c))
    return ("take", "gem", 1)


def bot_rule_slips(p_slip=0.04):
    """Knows it, but slips now and then (a finger on the wrong pan): the fairness check."""
    def bot(alt, rng, memo):
        if rng.random() < p_slip:
            return ("one_pan",)
        return bot_rule(alt, rng, memo)
    return bot


def bot_greedy_legal(alt, rng, memo):
    """Keeps the balance (only twin moves) and always does the move that leaves the crystal most alone."""
    ops = legal_ops(alt.s, alt.tools)
    scored = [(clutter(apply(alt.s, op)), rng.random(), op) for op in ops]
    scored.sort()
    return scored[0][2]


def bot_legal_random(alt, rng, memo):
    """Keeps the balance but has no plan: a random twin move each time (a kind of move first, then its size)."""
    ops = legal_ops(alt.s, alt.tools, max_add=3)
    groups = {}
    for op in ops:
        groups.setdefault(op[:2] if op[0] in ("take", "add") else op[:1], []).append(op)
    keys = sorted(groups)
    return rng.choice(groups[rng.choice(keys)])


def bot_op_guess(alt, rng, memo):
    """Knows the moves and the twin rule but not which move undoes what: guesses take, add or share each time."""
    side, c, k, oc, ok = _beside(alt.s)
    kind = "gem" if k > 0 else ("balloon" if k < 0 else "crystal")
    n = int(abs(k)) if k != 0 else max(int(c), 1)
    choice = rng.randrange(3)
    if choice == 0:
        return ("take", kind, n)
    if choice == 1:
        return ("add", "gem", n)
    return ("share", rng.randint(2, 6))


def bot_take_only(alt, rng, memo):
    """The habit 'take away': takes what is beside the crystal from both pans; never shares, never adds."""
    side, c, k, oc, ok = _beside(alt.s)
    if k > 0:
        return ("take", "gem", int(k))
    if k < 0:
        return ("take", "balloon", int(-k))
    return ("take", "crystal", max(int(c) - 1, 1))


def bot_share_only(alt, rng, memo):
    """The habit 'divide by the number you see': shares by the number beside the crystal."""
    side, c, k, oc, ok = _beside(alt.s)
    n = int(c) if c > 1 else int(abs(k)) if k else 2
    return ("share", max(n, 2))


def bot_habit(alt, rng, memo):
    """The hall's routine learned as a recipe (the Sky Room's habit; Knuth's 'unwind'): take away what is beside the
    crystal from both pans, then share by the crystal count on its pan. Never adds, never takes crystals."""
    side, c, k, oc, ok = _beside(alt.s)
    if k > 0:
        return ("take", "gem", int(k))
    if k < 0:
        return ("take", "balloon", int(-k))
    if c > 1:
        return ("share", int(c))
    return ("take", "gem", 1)


def bot_one_pan(alt, rng, memo):
    """The classic error: works on the crystal's pan only (takes its gems and expects the crystal to be free)."""
    return ("one_pan",)


def bot_mover(alt, rng, memo):
    """'Move it to the other side': carries an item from the crystal's pan across (the transposition shortcut)."""
    return ("across",)


def bot_weigh(alt, rng, memo):
    """Uses the beam as a scale: lifts crystals off one pan and gems off the other until it looks level. The chained
    beam (our design) refuses it; see free_beam() for what a free-swinging beam would allow."""
    return ("weigh",)


def bot_random_moves(alt, rng, memo):
    """Random moves of every kind, fair or not (one pan, across, any take, add or share)."""
    r = rng.randrange(6)
    if r == 0:
        return ("one_pan",)
    if r == 1:
        return ("across",)
    if r == 2:
        return ("take", rng.choice(["gem", "balloon", "crystal"]), rng.randint(1, 4))
    if r == 3:
        return ("add", rng.choice(["gem", "balloon"]), rng.randint(1, 4))
    return ("share", rng.randint(2, 6))


# --- The random tapper: taps at the level of single items (pending twins, as the place really works) --------------------
def play_taps(s, x, tools, rng, cap=CAP):
    """A child tapping things at random: lift an item from a pan, put a supply item on a pan, share, put back, carry
    across, or tap the crystal. A lift or a placement waits for its twin on the other pan (a batch: more of the same
    on the same pan grows it); anything else in between is a rule break and the waiting items spring back."""
    alt = Altar(s, x, tools, cap)
    pending = None                                    # [side, verb, kind, count, twins]
    supply = [k for k, t in SUPPLY.items() if t in tools]
    while not alt.done() and alt.actions < cap:
        alt.actions += 1
        r = rng.random()
        side = rng.randrange(2)
        if r < 0.45:                                  # lift something off a pan
            kinds = [k for k in ("gem", "balloon", "crystal") if amount(alt.s, side, k) > 0]
            if not kinds:
                continue
            act = ("lift", side, rng.choice(kinds))
        elif r < 0.65 and supply:                     # put something from the supply on a pan
            act = ("place", side, rng.choice(supply))
        elif r < 0.78:
            act = ("share", rng.randint(2, 6))
        elif r < 0.86:
            pending = None                            # puts the waiting items back: no harm
            continue
        elif r < 0.94:
            act = ("across", side, None)
        else:
            act = ("tap_crystal", None, None)
        verb = act[0]
        if verb in ("lift", "place"):
            _, side, kind = act
            if pending is None:
                pending = [side, verb, kind, 1, 0]
            elif pending[1] == verb and pending[2] == kind:
                if side == pending[0]:
                    if verb == "lift" and amount(alt.s, side, kind) < pending[3] + 1:
                        continue
                    pending[3] += 1
                else:
                    if verb == "lift" and amount(alt.s, side, kind) < pending[4] + 1:
                        continue
                    pending[4] += 1
                    if pending[4] == pending[3]:
                        op = ("take" if verb == "lift" else "add", kind, pending[3])
                        pending = None
                        alt.actions -= 1
                        alt.child(op)
            else:
                pending = None
                alt.rule_break(("one_pan",))
        elif verb == "share":
            if pending is not None:
                pending = None
                alt.rule_break(("one_pan",))
            else:
                alt.actions -= 1
                alt.child(act[:2])
        elif verb == "across":
            pending = None
            alt.rule_break(("across",))
        else:                                          # tapping the crystal: speaks, unless items are waiting
            if pending is not None:
                pending = None
                alt.rule_break(("one_pan",))
    if not alt.done():
        alt.finish()
    return alt


def free_beam(bot):
    """A counterfactual: a beam that swings freely shows which pan is heavier, so 'weigh' frees the crystal by
    measuring it (lift crystals and gems until level). Our design chains the beam so this never works."""
    def wrapped(alt, rng, memo):
        op = bot(alt, rng, memo)
        if op[0] == "weigh":
            side = crystal_side(alt.s)
            c, k = pan(alt.s, side)
            oc, ok = pan(alt.s, 1 - side)
            # measuring: keep one crystal, read the gems that balance it (x), clear the rest: the pans now show x
            alt.s = state(1, 0, 0, alt.x) if side == 0 else state(0, alt.x, 1, 0)
            alt.ops += 1
            return ("noop",)
        return op
    return wrapped
