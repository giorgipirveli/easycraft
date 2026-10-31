"""Phase A's model of eleven later rooms of the ladder (docs/design/games/word-magic.md §3.6, §3.9): in each, does the
named habit fail, does guessing fail, and does the idea win?

Every room is six wishes (the bar 5 of 6, MasteryRules), 1,000 seeded visits a player. A wish is a set of DECISIONS (a
card for a gap, a rune for a word, a comma or none at a joint, a place for a phrase); the room's own rule (the Spell
Reader's literal world, §3.4) says which combinations grant it. The players see what a child sees: the bubble's picture,
the cards' words (and what they say when touched), the runes.

(a) Time Windows (g3 verbs_tenses): the bubble's frames say WHEN (an old photo: it happened; now; a dotted plan: it will).
(b) Chain Spells (g3 joining_sentences, g5 conjunctions): two events and how they link (one causes the other, one is a
    surprise after the other, one only if the other); the child picks the joining word and which event comes first.
(c) The Homophone Hall (g4 sound_alike; a reading room): there, their, they're; to, too, two; its, it's; your, you're.
(d) The Comma Bridge (g5 commas): commas in a list and before a name (a cat, a dog and a fish; "Let's paint, Pip!").
(e) The Wandering Phrase (g7 modifiers): a describing phrase sticks to the noun it stands next to.
(f) The Which Gate (g4 relative_words, g6 extra_information): "the dragons that sleep" (only those) against "the
    dragons, which sleep," (all of them, and by the way they sleep).
(g) The Loom (g3 joining, g6 sentence_variety, g7 sentence_kinds): three things to say, one ribbon of eight slots:
    sentence combining.
(h) The Spotlight (g8 voice): who did it, and who stands in the light (the active and the passive).
(i) The Rune Bench (g3 word_building, g4 word_parts): a prefix rune and a suffix rune on a word.
(j) The Word Forge (g5 roots, g6 affixes_roots, g7 roots): two roots name the gadget the job needs.
(k) Mood Dyes (g6 connotation, g7 connotation_tone): words with one meaning and different feelings.

What the first drafts showed (--draft prints them beside the final rooms): (a) regular verbs only let "add -ed" pass
100 %; (b) a fixed order and only causes and surprises let "so everywhere" reach 17 % and "because for so" 16 %, and a
second draft that drew the hand's other words at random still let "because for so" pass 12 % whenever "because" was
missing: every hand now holds "and" and "so" (and "because" in a cause wish); (c) one homophone a wish let a listener
reach 11 %; (d) lists only let "comma everywhere" and "a comma where you pause" pass 100 %; (e) the phrase always at the
end let "always at the end" pass 100 %; (f) things only let the comma habits reach 10-11 %; (g) a ribbon with no slot
limit let the and-chain pass 100 %; (h) one scene a wish let "the first noun is the doer" reach 10 %; (i) un- words only
let "un- for every not" pass 100 %, and a second draft without un- in every hand still let it pass 19 %; (j) one job
(a far-hearer: telephone) let "the most familiar roots" pass 100 %; (k) always a warm feeling let "the nice word" pass
100 %. The lesson, as the bakery's queues taught: every hand holds the tempting wrong card.

Run: /usr/bin/python3 -I docs/design/games/word-magic/model/ladder_model.py 1000 [--draft]
Result (2026-10-18, 1,000 visits each, FINAL): in all eleven rooms the idea 100 % and every named habit 0 % (the
listener in the Homophone Hall and "the commonest" 0.1 %; "knows the suffixes only" 0.1 %; "knows the first root
only" 0.7 %; "any weave that fits the ribbon" 1.2 %); random at most 0.5 %; slips on 4 % of picks 90.2-98.5 %.
"""
import itertools
import random
import statistics
import sys

sys.dont_write_bytecode = True
SLIP = 0.04


def mastered(solved, total):
    return total > 0 and solved * 6 >= 5 * total


class Wish:
    """gaps: lists of options (dicts, each with 'w' the word or rune or mark); good: a set of tuples of option
    indices that grant the wish; info: what the bubble shows (for the players)."""

    def __init__(self, gaps, good, info):
        self.gaps, self.good, self.info = gaps, good, info

    def right(self, picks):
        return tuple(picks) in self.good

    def idea(self):
        return list(sorted(self.good)[0])


def by_rule(gaps, grant, info):
    good = {combo for combo in itertools.product(*[range(len(g)) for g in gaps])
            if grant([g[i] for g, i in zip(gaps, combo)])}
    assert good, info
    return Wish(gaps, good, info)


def idea(w, rng):
    return w.idea()


def slips(w, rng):
    picks = w.idea()
    for i, g in enumerate(w.gaps):
        if rng.random() < SLIP and len(g) > 1:
            picks[i] = rng.choice([j for j in range(len(g)) if j != picks[i]])
    return picks


def random_picks(w, rng):
    return [rng.randrange(len(g)) for g in w.gaps]


def habit(prefer):
    """A habit: for each gap, the options it likes (prefer(option, gap, wish) -> bool); random among them."""
    def player(w, rng):
        out = []
        for i, g in enumerate(w.gaps):
            liked = [j for j, o in enumerate(g) if prefer(o, i, w)]
            out.append(rng.choice(liked or list(range(len(g)))))
        return out
    return player


def shuffled(rng, opts):
    opts = list(opts)
    rng.shuffle(opts)
    return opts


# ======================================================================================================================
# (a) Time Windows: verbs and when. Subjects are plural (the ducks), so "now" is the plain verb.
REGULAR_V = [("jump", "jumped"), ("splash", "splashed"), ("climb", "climbed"), ("paint", "painted"), ("dance", "danced")]
WILD_V = [("run", "ran", "runned"), ("swim", "swam", "swimmed"), ("fly", "flew", "flied"), ("eat", "ate", "eated"),
          ("sing", "sang", "singed"), ("dig", "dug", "digged")]


def time_gap(rng, verb, wild):
    if wild:
        base, past, jumble = verb
        opts = [{"w": base, "t": "now"}, {"w": past, "t": "past"}, {"w": "will " + base, "t": "future"},
                {"w": jumble, "t": "past?", "made_up": True, "ed": True}]
    else:
        base, past = verb
        opts = [{"w": base, "t": "now"}, {"w": past, "t": "past", "ed": True}, {"w": "will " + base, "t": "future"}]
    return shuffled(rng, opts)


def time_wish(rng, frames, wilds):
    gaps, verbs_w, verbs_r = [], rng.sample(WILD_V, 2), rng.sample(REGULAR_V, 2)
    for k, (t, wild) in enumerate(zip(frames, wilds)):
        gaps.append(time_gap(rng, verbs_w[k] if wild else verbs_r[k], wild))
    return by_rule(gaps, lambda ch: all(o["t"] == t and not o.get("made_up") for o, t in zip(ch, frames)),
                   {"times": frames})


def _when(rng):
    return rng.choice(["past", "now", "future"])


TIME_DRAFT = [lambda r: time_wish(r, [_when(r)], [False]) for _ in range(6)]
TIME_FINAL = [
    lambda r: time_wish(r, ["past", _when(r)], [True, False]),
    lambda r: time_wish(r, [_when(r), "past"], [False, True]),
    lambda r: time_wish(r, ["past", "future"], [True, True]),
    lambda r: time_wish(r, ["now", "past"], [False, True]),
    lambda r: time_wish(r, ["future", "past"], [True, True]),
    lambda r: time_wish(r, ["past", "past"], [True, False]),
]


def _t_ed(o, i, w):
    t = w.info["times"][i]
    return (o.get("ed", False) if t == "past" else o["t"] == t)


TIME_PLAYERS = [
    ("the idea (the frame says when)", idea), ("slips 4 %", slips),
    ("adds -ed for the past (runned)", habit(_t_ed)),
    ("always now", habit(lambda o, i, w: o["t"] == "now")),
    ("any real word, any time", habit(lambda o, i, w: not o.get("made_up"))),
    ("the longest (will run)", habit(lambda o, i, w: o["t"] == "future")),
    ("random", random_picks),
]

# ======================================================================================================================
# (b) Chain Spells: two events A and B and their link; the child picks the joining word and the order.
CONJ = ["and", "but", "so", "because", "if", "when"]


def chain_grant(link):
    """(conjunction, which event first) -> the world plays the link the bubble shows?"""
    def grant(ch):
        c, first = ch[0]["w"], ch[1]["w"]
        if link == "cause":          # A causes B: "A, so B" or "B because A"
            return (c == "so" and first == "A") or (c == "because" and first == "B")
        if link == "surprise":       # A, and B happens anyway: "A, but B"
            return c == "but" and first == "A"
        if link == "only_if":        # B happens only if A: "if A, B" (written "B if A" too)
            return c == "if"
        if link == "after":          # B waits for A: "when A, B" (or "B when A")
            return c == "when"
        return False
    return grant


def chain_wish(rng, link, order_gap=True, traps=True):
    """traps: every hand holds the habits' tempting words ('and'; 'because' beside 'so' in a cause wish). The second
    draft drew the other three words at random: 'because for so' passed 12 % of visits when 'because' was missing."""
    main = {"cause": "so", "surprise": "but", "only_if": "if", "after": "when"}[link]
    tempting = (["because", "and"] if link == "cause" else ["and", "so"]) if traps else []
    rest = [c for c in CONJ if c != main and c not in tempting]
    conj = [{"w": c} for c in [main] + tempting + rng.sample(rest, 4 - 1 - len(tempting))]
    rng.shuffle(conj)
    order = shuffled(rng, [{"w": "A"}, {"w": "B"}]) if order_gap else [{"w": "A"}]
    return by_rule([conj, order], chain_grant(link), {"link": link})


# The first draft: the order fixed (the cause told first), only causes and surprises: "so everywhere" passed 17 %.
CHAIN_DRAFT = [lambda r: chain_wish(r, r.choice(["cause", "surprise"]), order_gap=False, traps=False)
               for _ in range(6)]
CHAIN_FINAL = [lambda r: chain_wish(r, "cause"), lambda r: chain_wish(r, "surprise"), lambda r: chain_wish(r, "only_if"),
               lambda r: chain_wish(r, "cause"), lambda r: chain_wish(r, "after"), lambda r: chain_wish(r, "cause")]


def _because_is_so(o, i, w):
    if i == 1:
        return o["w"] == "A"                                    # tells it in the order it happened
    link = w.info["link"]
    return o["w"] == {"cause": "because", "surprise": "but", "only_if": "if", "after": "when"}[link]


CHAIN_PLAYERS = [
    ("the idea", idea), ("slips 4 %", slips),
    ("and everywhere", habit(lambda o, i, w: o["w"] in ("and", "A"))),
    ("because for 'so' (the cause told second)", habit(_because_is_so)),
    ("so everywhere", habit(lambda o, i, w: o["w"] in ("so", "A"))),
    ("random", random_picks),
]

# ======================================================================================================================
# (c) The Homophone Hall: every card in a set SAYS the same sound; only reading tells them apart.
HOMO = {
    "there": ("there", "their", "they're"), "their": ("there", "their", "they're"), "they're": ("there", "their", "they're"),
    "to": ("to", "too", "two"), "too": ("to", "too", "two"), "two": ("to", "too", "two"),
    "its": ("its", "it's"), "it's": ("its", "it's"), "your": ("your", "you're"), "you're": ("your", "you're"),
}
OWNS = {"their", "its", "your"}
COMMON = {"there", "to", "its", "your"}


def homo_wish(rng, targets):
    gaps = [shuffled(rng, [{"w": x, "target": t} for x in HOMO[t]]) for t in targets]
    return by_rule(gaps, lambda ch: all(o["w"] == o["target"] for o in ch), {"targets": targets})


def _pair(rng, pool):
    return rng.sample(pool, 2)


HOMO_DRAFT = [lambda r: homo_wish(r, [r.choice(["its", "it's", "your", "you're"])]) for _ in range(6)]
HOMO_FINAL = [lambda r: homo_wish(r, [r.choice(["their", "they're"]), r.choice(["too", "two"])]),
              lambda r: homo_wish(r, [r.choice(["it's", "its"]), r.choice(["there", "their"])]),
              lambda r: homo_wish(r, [r.choice(["your", "you're"]), r.choice(["to", "too"])]),
              lambda r: homo_wish(r, [r.choice(["they're", "there"]), r.choice(["its", "it's"])]),
              lambda r: homo_wish(r, [r.choice(["two", "to"]), r.choice(["you're", "your"])]),
              lambda r: homo_wish(r, [r.choice(["their", "there", "they're"]), r.choice(["it's", "its"])])]


def _apostrophe_owns(o, i, w):
    t = o["target"]
    owning = t in OWNS
    return ("'" in o["w"]) == owning if t in ("their", "its", "your", "they're", "it's", "you're") else o["w"] == "to"


HOMO_PLAYERS = [
    ("reads them (the idea)", idea), ("slips 4 %", slips),
    ("only listens: they sound the same", random_picks),
    ("the apostrophe means it belongs", habit(_apostrophe_owns)),
    ("always the commonest", habit(lambda o, i, w: o["w"] in COMMON)),
]

# ======================================================================================================================
# (d) The Comma Bridge: a decision at each joint: a comma or none. Lists: no comma fuses two things into one ("a cat
# dog": a cat-dog); a comma before the last 'and' is allowed either way. A name spoken to: "Let's paint, Pip!" (Pip
# helps) against "Let's paint Pip!" (Pip is painted). Between a describing word and its noun: never.
def comma_wish(rng, joints):
    """joints: list of kinds: 'list' (needs a comma), 'list_and' (either), 'address' (needs one), 'noun' (none),
    'not_address' (the wish wants the thing done TO the name: none), 'long_subject' (between a long subject and its
    verb: none, though a reader pauses there: the comma cuts the verb off its subject)."""
    gaps = [shuffled(rng, [{"w": ",", "kind": k}, {"w": "", "kind": k}]) for k in joints]
    need = {"list": {","}, "list_and": {",", ""}, "address": {","}, "noun": {""}, "not_address": {""},
            "long_subject": {""}}
    return by_rule(gaps, lambda ch: all(o["w"] in need[o["kind"]] for o in ch), {"joints": joints})


# The first draft: lists only: "a comma everywhere" granted every wish.
COMMA_DRAFT = [lambda r: comma_wish(r, ["list", "list"]) for _ in range(6)]
COMMA_FINAL = [lambda r: comma_wish(r, ["list", "list", "list_and"]),
               lambda r: comma_wish(r, ["address", "long_subject"]),
               lambda r: comma_wish(r, ["not_address", "list"]),
               lambda r: comma_wish(r, ["noun", "list", "list_and"]),
               lambda r: comma_wish(r, [r.choice(["address", "not_address"]), "long_subject", "list"]),
               lambda r: comma_wish(r, ["list", "not_address"])]
PAUSES = ("list", "list_and", "address", "long_subject")
COMMA_PLAYERS = [
    ("the idea", idea), ("slips 4 %", slips),
    ("a comma everywhere", habit(lambda o, i, w: o["w"] == ",")),
    ("never a comma", habit(lambda o, i, w: o["w"] == "")),
    ("a comma wherever you pause", habit(lambda o, i, w: (o["w"] == ",") == (o["kind"] in PAUSES))),
    ("random", random_picks),
]

# ======================================================================================================================
# (e) The Wandering Phrase: "with a wagging tail" goes in one of three places and sticks to the noun beside it.
def phrase_wish(rng, right_spot):
    spots = shuffled(rng, [{"w": s} for s in ("start", "middle", "end")])
    return by_rule([spots], lambda ch: ch[0]["w"] == right_spot, {"spot": right_spot})


def two_phrases(rng, a, b):
    s1 = shuffled(rng, [{"w": s} for s in ("start", "middle", "end")])
    s2 = shuffled(rng, [{"w": s} for s in ("start", "middle", "end")])
    return by_rule([s1, s2], lambda ch: ch[0]["w"] == a and ch[1]["w"] == b, {"spots": (a, b)})


MOD_DRAFT = [lambda r: phrase_wish(r, "end") for _ in range(6)]
MOD_FINAL = [lambda r: two_phrases(r, "start", "end"), lambda r: two_phrases(r, "middle", "end"),
             lambda r: two_phrases(r, "end", "start"), lambda r: two_phrases(r, "start", "middle"),
             lambda r: two_phrases(r, "middle", "start"), lambda r: two_phrases(r, "end", "middle")]
MOD_PLAYERS = [
    ("the idea (next to what it describes)", idea), ("slips 4 %", slips),
    ("always at the end", habit(lambda o, i, w: o["w"] == "end")),
    ("always at the start", habit(lambda o, i, w: o["w"] == "start")),
    ("random", random_picks),
]

# ======================================================================================================================
# (f) The Which Gate: the relative word and the commas. Restrictive (only those): who/that, no commas. Non-restrictive
# (all of them, and by the way): who/which with a pair of commas. People take who; things which or that.
def which_wish(rng, restrictive, people):
    word = shuffled(rng, [{"w": x} for x in ("who", "which", "that", "where")])
    commas = shuffled(rng, [{"w": "commas"}, {"w": "none"}])

    def grant(ch):
        rel, c = ch[0]["w"], ch[1]["w"]
        if restrictive:
            return c == "none" and rel in (("who", "that") if people else ("that", "which"))
        return c == "commas" and rel == ("who" if people else "which")

    return by_rule([word, commas], grant, {"restrictive": restrictive, "people": people})


WHICH_DRAFT = [lambda r: which_wish(r, r.random() < 0.5, False) for _ in range(6)]
WHICH_FINAL = [lambda r: which_wish(r, True, False), lambda r: which_wish(r, False, False),
               lambda r: which_wish(r, True, True), lambda r: which_wish(r, False, True),
               lambda r: which_wish(r, r.random() < 0.5, r.random() < 0.5), lambda r: which_wish(r, True, False)]
WHICH_PLAYERS = [
    ("the idea", idea), ("slips 4 %", slips),
    ("commas always, 'which' for things", habit(lambda o, i, w: o["w"] in ("commas", "who" if w.info["people"]
                                                                           else "which"))),
    ("never commas", habit(lambda o, i, w: o["w"] in ("none", "who" if w.info["people"] else "which"))),
    ("random", random_picks),
]

# ======================================================================================================================
# (g) The Loom: three things to say (a dragon; it is small and green; it sleeps by the lake), one ribbon of eight
# slots. Ways to weave: an and-chain (too long: the ribbon overflows and the end falls off), the first thing only (two
# are lost), adjectives woven in, a who/which clause, an -ing phrase, or a weave that hangs a piece on the wrong noun.
WEAVES = [("and-chain", 13, True, True), ("first thing only", 4, False, True), ("adjectives in", 8, True, True),
          ("a which-clause", 8, True, True), ("an -ing phrase", 8, True, True), ("on the wrong noun", 8, True, False)]


def loom_wish(rng, fits, budget=8):
    """fits: which weaves the three things allow (adjectives woven in only when two of them are describing words).
    budget: the ribbon's slots (None: no limit, the first draft)."""
    opts = shuffled(rng, [{"w": n, "len": L, "all": a, "right_noun": rn,
                           "allowed": n in fits or (budget is None and n == "and-chain")} for n, L, a, rn in WEAVES])
    return by_rule([opts], lambda ch: (budget is None or ch[0]["len"] <= budget) and ch[0]["all"]
                   and ch[0]["right_noun"] and ch[0]["allowed"], {"fits": fits})


# The first draft: a ribbon with no slot limit; any spell that said all three things counted.
LOOM_DRAFT = [lambda r: loom_wish(r, {"adjectives in", "a which-clause"}, budget=None) for _ in range(6)]
LOOM_FINAL = [lambda r: loom_wish(r, {"adjectives in", "a which-clause"}),
              lambda r: loom_wish(r, {"a which-clause", "an -ing phrase"}),
              lambda r: loom_wish(r, {"adjectives in"}), lambda r: loom_wish(r, {"an -ing phrase"}),
              lambda r: loom_wish(r, {"a which-clause"}), lambda r: loom_wish(r, {"adjectives in", "an -ing phrase"})]
LOOM_PLAYERS = [
    ("the idea (combines the sentences)", idea), ("slips 4 %", slips),
    ("joins with and, and, and", habit(lambda o, i, w: o["w"] == "and-chain")),
    ("says only the first thing", habit(lambda o, i, w: o["w"] == "first thing only")),
    ("any weave that fits the ribbon", habit(lambda o, i, w: o["len"] <= 8)),
    ("random", random_picks),
]

# ======================================================================================================================
# (h) The Spotlight: the bubble shows who did it (the doer) and who must stand in the light (the subject).
FRAMES = ["D did it to R", "R did it to D", "R was done by D", "D was done by R", "R was done"]


def spot_wish(rng, light_on, doer_seen=True):
    opts = shuffled(rng, [{"w": f} for f in FRAMES])

    def grant(ch):
        f = ch[0]["w"]
        if light_on == "doer":
            return f == "D did it to R"
        if not doer_seen:
            return f == "R was done"
        return f == "R was done by D"

    return by_rule([opts], grant, {"light_on": light_on, "doer_seen": doer_seen})


def spot_two(rng, a, b):
    w1, w2 = spot_wish(rng, *a), spot_wish(rng, *b)
    good = {(x[0], y[0]) for x in w1.good for y in w2.good}
    return Wish(w1.gaps + w2.gaps, good, {"pairs": (w1.info, w2.info)})


SPOT_DRAFT = [lambda r: spot_wish(r, r.choice(["doer", "receiver"])) for _ in range(6)]
SPOT_FINAL = [lambda r: spot_two(r, ("receiver",), ("doer",)), lambda r: spot_two(r, ("doer",), ("receiver",)),
              lambda r: spot_two(r, ("receiver", False), ("receiver",)), lambda r: spot_two(r, ("receiver",), ("doer",)),
              lambda r: spot_two(r, ("doer",), ("receiver", False)), lambda r: spot_two(r, ("receiver",), ("receiver",))]


def _first_noun_doer(o, i, w):
    info = w.info["pairs"][i] if "pairs" in w.info else w.info
    if info["light_on"] == "doer":
        return o["w"] == "D did it to R"
    # wants R in the light, and reads "X was done by Y" as X did it: puts the doer first
    return o["w"] == "D was done by R"


SPOT_PLAYERS = [
    ("the idea", idea), ("slips 4 %", slips),
    ("the first noun is the doer (reads passives as actives)", habit(_first_noun_doer)),
    ("always active", habit(lambda o, i, w: o["w"] == "D did it to R")),
    ("random", random_picks),
]

# ======================================================================================================================
# (i) The Rune Bench: a prefix rune and a suffix rune on a stem; only real words work.
RUNES = {
    # stem: {prefix meaning: prefix}, {suffix meaning: suffix}
    "lock": ({"reverse": "un", "again": "re"}, {"can": "able"}),
    "appear": ({"opposite": "dis", "again": "re"}, {"": ""}),
    "build": ({"again": "re"}, {"person": "er"}),
    "heat": ({"before": "pre", "again": "re"}, {"person": "er"}),
    "agree": ({"opposite": "dis"}, {"can": "able"}),
    "help": ({"opposite": "un"}, {"full": "ful", "without": "less"}),
    "spell": ({"wrongly": "mis"}, {"person": "er"}),
    "care": ({"opposite": "un"}, {"full": "ful", "without": "less"}),
    "fear": ({}, {"full": "ful", "without": "less"}),
    "kind": ({"opposite": "un"}, {"way": "ly", "state": "ness"}),
}
PREFIXES = ["un", "re", "dis", "pre", "mis", ""]
SUFFIXES = ["ful", "less", "able", "er", "ly", ""]


def rune_wish(rng, stem, pre_meaning, suf_meaning):
    """The bubble shows what the word must do (a lock that can be opened again: unlockable). Four prefix runes (one
    of them 'none') and four suffix runes are offered; a made-up word (unappear) summons the Jumble."""
    pmap, smap = RUNES[stem]
    want_p = pmap[pre_meaning] if pre_meaning else ""
    want_s = smap[suf_meaning] if suf_meaning else ""
    # every 'not' wish offers un- (the tempting rune): the second draft drew the others at random, and "un- for every
    # not" passed 19 % of visits when un- happened to be missing
    tempt = ["un"] if pre_meaning in ("opposite", "reverse") and want_p != "un" else []
    p_opts = [want_p] + tempt + rng.sample([p for p in PREFIXES if p != want_p and p not in tempt], 3 - len(tempt))
    s_opts = [want_s] + rng.sample([s for s in SUFFIXES if s != want_s], 3)
    ps = shuffled(rng, [{"w": p, "want": want_p, "meaning": pre_meaning} for p in p_opts])
    ss = shuffled(rng, [{"w": s, "want": want_s, "meaning": suf_meaning} for s in s_opts])
    return by_rule([ps, ss], lambda ch: ch[0]["w"] == want_p and ch[1]["w"] == want_s,
                   {"stem": stem, "pre": pre_meaning, "suf": suf_meaning})


# The first draft: only un- words (unlock, unhelpful, unkind, uncaring): "un- for every not" granted every wish.
RUNE_DRAFT = [lambda r: rune_wish(r, "lock", "reverse", None), lambda r: rune_wish(r, "help", "opposite", "full"),
              lambda r: rune_wish(r, "kind", "opposite", None), lambda r: rune_wish(r, "care", "opposite", "full"),
              lambda r: rune_wish(r, "lock", "reverse", "can"), lambda r: rune_wish(r, "help", "opposite", None)]
RUNE_FINAL = [lambda r: rune_wish(r, "lock", "reverse", "can"),        # unlockable
              lambda r: rune_wish(r, "appear", "opposite", None),      # disappear
              lambda r: rune_wish(r, "help", "opposite", "full"),      # unhelpful
              lambda r: rune_wish(r, "agree", "opposite", "can"),      # disagreeable
              lambda r: rune_wish(r, "build", "again", None),          # rebuild
              lambda r: rune_wish(r, "spell", "wrongly", None)]        # misspell


def _un_for_not(o, i, w):
    if i == 0:
        m = o["meaning"]
        if m in ("reverse", "opposite"):
            return o["w"] == "un"
        return o["w"] == o["want"]
    return o["w"] == o["want"]


RUNE_PLAYERS = [
    ("the idea (each rune's meaning, real words)", idea), ("slips 4 %", slips),
    ("un- for every 'not' (unappear)", habit(_un_for_not)),
    ("knows the suffixes only", habit(lambda o, i, w: o["w"] == o["want"] if i == 1 else True)),
    ("random", random_picks),
]

# ======================================================================================================================
# (j) The Word Forge: two roots name the gadget the job needs (a far-seer: tele + scope).
JOBS = [("see far", "tele", "scope"), ("see small", "micro", "scope"), ("write with light", "photo", "graph"),
        ("measure heat", "thermo", "meter"), ("hear far", "tele", "phone"), ("write a life", "bio", "graphy"),
        ("measure time", "chrono", "meter"), ("carry across", "trans", "port")]
FIRSTS = ["tele", "micro", "photo", "thermo", "bio", "chrono", "trans", "hydro"]
SECONDS = ["scope", "graph", "meter", "phone", "graphy", "port", "logy"]
FAMILIAR = {"tele": 3, "phone": 3, "photo": 2, "graph": 2, "micro": 2, "scope": 1}


def forge_wish(rng, job):
    name, a, b = job
    g1 = shuffled(rng, [{"w": x, "want": a} for x in [a] + rng.sample([f for f in FIRSTS if f != a], 3)])
    g2 = shuffled(rng, [{"w": x, "want": b} for x in [b] + rng.sample([s for s in SECONDS if s != b], 3)])
    return by_rule([g1, g2], lambda ch: ch[0]["w"] == a and ch[1]["w"] == b, {"job": name})


def _forge(rng):
    return forge_wish(rng, rng.choice(JOBS))


FORGE_DRAFT = [lambda r: forge_wish(r, JOBS[4]) for _ in range(6)]
FORGE_FINAL = [lambda r, j=j: forge_wish(r, j) for j in (JOBS[0], JOBS[1], JOBS[2], JOBS[3], JOBS[5], JOBS[6])]
FORGE_PLAYERS = [
    ("the idea (each root's meaning)", idea), ("slips 4 %", slips),
    ("the most familiar roots (telephone)", habit(lambda o, i, w: FAMILIAR.get(o["w"], 0) == max(
        FAMILIAR.get(x["w"], 0) for x in w.gaps[i]))),
    ("knows the first root only", habit(lambda o, i, w: o["w"] == o["want"] if i == 0 else True)),
    ("random", random_picks),
]

# ======================================================================================================================
# (k) Mood Dyes: one meaning, three feelings (cosy / small / cramped); the bubble shows the feeling wanted.
MOODS = [("cosy", "small", "cramped"), ("curious", "interested", "nosy"), ("brave", "bold", "reckless"),
         ("thrifty", "careful", "stingy"), ("slim", "thin", "skinny"), ("chatty", "talkative", "noisy"),
         ("firm", "determined", "stubborn"), ("relaxed", "slow", "lazy")]


def mood_wish(rng, feelings):
    gaps = []
    for f, trio in zip(feelings, rng.sample(MOODS, len(feelings))):
        opts = [{"w": trio[0], "f": "warm"}, {"w": trio[1], "f": "plain"}, {"w": trio[2], "f": "cold"}]
        gaps.append(shuffled(rng, [dict(o, want=f) for o in opts]))
    return by_rule(gaps, lambda ch: all(o["f"] == o["want"] for o in ch), {"feelings": feelings})


MOOD_DRAFT = [lambda r: mood_wish(r, ["warm"]) for _ in range(6)]
MOOD_FINAL = [lambda r: mood_wish(r, ["warm", "cold"]), lambda r: mood_wish(r, ["cold", "plain"]),
              lambda r: mood_wish(r, ["plain", "warm"]), lambda r: mood_wish(r, ["cold", "cold"]),
              lambda r: mood_wish(r, ["warm", "plain"]), lambda r: mood_wish(r, ["cold", "warm"])]
MOOD_PLAYERS = [
    ("the idea (the feeling each word carries)", idea), ("slips 4 %", slips),
    ("always the nice word", habit(lambda o, i, w: o["f"] == "warm")),
    ("always the strongest word", habit(lambda o, i, w: o["f"] == "cold")),
    ("random", random_picks),
]

ROOMS = [
    ("(a) Time Windows (g3)", TIME_DRAFT, TIME_FINAL, TIME_PLAYERS),
    ("(b) Chain Spells (g3, g5)", CHAIN_DRAFT, CHAIN_FINAL, CHAIN_PLAYERS),
    ("(c) The Homophone Hall (g4)", HOMO_DRAFT, HOMO_FINAL, HOMO_PLAYERS),
    ("(d) The Comma Bridge (g5)", COMMA_DRAFT, COMMA_FINAL, COMMA_PLAYERS),
    ("(e) The Wandering Phrase (g7)", MOD_DRAFT, MOD_FINAL, MOD_PLAYERS),
    ("(f) The Which Gate (g4, g6)", WHICH_DRAFT, WHICH_FINAL, WHICH_PLAYERS),
    ("(g) The Loom (g3, g6, g7)", LOOM_DRAFT, LOOM_FINAL, LOOM_PLAYERS),
    ("(h) The Spotlight (g8)", SPOT_DRAFT, SPOT_FINAL, SPOT_PLAYERS),
    ("(i) The Rune Bench (g3, g4)", RUNE_DRAFT, RUNE_FINAL, RUNE_PLAYERS),
    ("(j) The Word Forge (g5-7)", FORGE_DRAFT, FORGE_FINAL, FORGE_PLAYERS),
    ("(k) Mood Dyes (g6, g7)", MOOD_DRAFT, MOOD_FINAL, MOOD_PLAYERS),
]


def score(room, player, n):
    bars, solved = 0, []
    for seed in range(n):
        rng = random.Random(seed)
        s = 0
        for make in room:
            w = make(rng)
            s += w.right(player(w, rng))
        solved.append(s)
        bars += mastered(s, len(room))
    return 100.0 * bars / n, statistics.mean(solved)


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 1000
    draft = "--draft" in sys.argv
    for title, d, f, players in ROOMS:
        print(title)
        for name, p in players:
            fb, fs = score(f, p, n)
            line = f"  {name:52} final {fb:5.1f}% ({fs:4.2f} of 6)"
            if draft:
                db, ds = score(d, p, n)
                line += f"   first draft {db:5.1f}% ({ds:4.2f})"
            print(line)
        print()


if __name__ == "__main__":
    main()
