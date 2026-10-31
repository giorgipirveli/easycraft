"""Word Magic: the spell's rules, shared by phase A's models (docs/design/games/word-magic.md §3.4-3.6, §3.9, §3.10).

A SPELL is a sentence written on the Spell Ribbon from word cards. The world does exactly what the sentence says
(the Spell Reader, §3.4): a noun phrase summons things, its NUMBER says how many; a verb says what they do, its form
says how many of them do it. Here only what the models need is kept: noun phrases (a number word or an article, then
a noun) and clauses (a subject, then a verb), with the cards a wish's gaps offer.

A CARD is a word as the child sees it: its letters (the stem in white ink, an ending in gold ink), a small picture
badge of the stem's meaning (never of its grammar: "foxes" shows ONE fox), and its voice (it says its word when
touched). What a card IS (a real word or one of the Jumble's made-up words, singular or plural) is only in its word.

A WISH is a picture in a buddy's thought bubble (three mice eating cheese) and a frame on the ribbon with gaps; the
child fills every gap from the cards the gap offers and seals the spell (the star seal, the full stop). It is SOLVED
when the first cast grants the wish, with no help (design ruling 6: a wrong cast plays out, the ink flows back, the
child may fix it and cast again, but that wish is then HELPED). Nothing previews what a spell will do before the cast
(ruling 7: the models show why).

The bar is MasteryRules.is_mastery: right the first time at least 5 of every 6 (core/school/mastery_rules.gd).

Everything is deterministic given a random.Random; the models load this file by its path, so they run with
`python3 -I` and leave no __pycache__.
"""
SOLVED, WRONG = "solved", "wrong"
SLIP = 0.04          # the slip player's chance of a wrong pick on any one decision


def mastered(solved, total):
    """MasteryRules.is_mastery: right the first time at least 5 of every 6."""
    return total > 0 and solved * 6 >= 5 * total


# --- Cards -----------------------------------------------------------------------------------------------------------
class Card:
    """One word card. kind: 'num' (a number word or the article a), 'noun', 'verb', 'pron'.
    num: for a noun 'sg', 'pl', 'both' (sheep) or None (a made-up word: it summons the Jumble);
         for a verb 'one' (the -s form: exactly one does it) or 'many' (the bare form: all of them do it);
         for a pronoun 'one' (it) or 'many' (they).
    value: a number word's count (a = 1).
    gold: the letters after the stem, drawn in gold ink ('' when none): the visible ending.
    sounds_added: the card sounds like its stem with an s or z sound added (foxes, mouses, leafs, leaves).
    stem: the picture badge (the same for every form of a word)."""

    def __init__(self, word, kind, stem=None, num=None, value=None, gold="", sounds_added=False):
        self.word, self.kind, self.stem, self.num, self.value = word, kind, stem, num, value
        self.gold, self.sounds_added = gold, sounds_added

    @property
    def real(self):
        return self.kind != "noun" or self.num is not None

    def __repr__(self):
        return self.word


NUMBER_WORDS = {"a": 1, "two": 2, "three": 3, "four": 4, "five": 5}


def number_card(w):
    return Card(w, "num", value=NUMBER_WORDS[w])


# The nouns of the First Page. Each form: (word, number, the gold ending, sounds like the stem with an s or z added).
# Number None is one of the Jumble's made-up words (it summons the Jumble). Stage 1: the Jumble's words SOUND wrong,
# so a child who only listens can tell them apart (mouses, sheeps). Children is child + ren: its "ren" is gold.
NOUNS = {
    "frog": [("frog", "sg", "", False), ("frogs", "pl", "s", True)],
    "duck": [("duck", "sg", "", False), ("ducks", "pl", "s", True)],
    "fox": [("fox", "sg", "", False), ("foxes", "pl", "es", True)],
    "box": [("box", "sg", "", False), ("boxes", "pl", "es", True)],
    "pony": [("pony", "sg", "", False), ("ponies", "pl", "ies", True)],
    "bunny": [("bunny", "sg", "", False), ("bunnies", "pl", "ies", True)],
    "leaf": [("leaf", "sg", "", False), ("leaves", "pl", "ves", True), ("leafs", None, "s", True)],
    "wolf": [("wolf", "sg", "", False), ("wolves", "pl", "ves", True), ("wolfs", None, "s", True)],
    "mouse": [("mouse", "sg", "", False), ("mice", "pl", "", False), ("mouses", None, "s", True),
              ("mices", None, "s", True)],
    "goose": [("goose", "sg", "", False), ("geese", "pl", "", False), ("gooses", None, "s", True),
              ("geeses", None, "s", True)],
    "child": [("child", "sg", "", False), ("children", "pl", "ren", False), ("childs", None, "s", True),
              ("childrens", None, "s", True)],
    "sheep": [("sheep", "both", "", False), ("sheeps", None, "s", True)],
    "deer": [("deer", "both", "", False), ("deers", None, "s", True)],
}
# Stage 2 (opened by the child's own reading, §3.6): made-up words that SOUND RIGHT but are spelt wrong, so only
# reading tells them apart (ponys is heard as ponies).
LOOK_ALIKES = {"pony": [("ponys", None, "s", True)], "bunny": [("bunnys", None, "s", True)]}
WILD = {"mouse", "goose", "child", "sheep", "deer"}


def noun_cards(stem, jumbles=True, look_alikes=False, limit=None):
    """The forms of a noun a gap offers: the singular, the plural, and (if asked) the Jumble's made-up words."""
    forms = [f for f in NOUNS[stem] if f[1] is not None or jumbles]
    if look_alikes:
        forms += LOOK_ALIKES.get(stem, [])
    if limit:
        real = [f for f in forms if f[1] is not None]
        made_up = [f for f in forms if f[1] is None]
        forms = real + made_up[:max(0, limit - len(real))]
    return [Card(w, "noun", stem, n, gold=g, sounds_added=s) for w, n, g, s in forms]


def heard(card):
    """What a card sounds like when it speaks: the look-alikes sound like the right plural (ponys: 'ponies')."""
    for stem, alikes in LOOK_ALIKES.items():
        if card.word in [a[0] for a in alikes]:
            return [f[0] for f in NOUNS[stem] if f[1] == "pl"][0]
    return card.word


# --- Noun phrases: how many come ---------------------------------------------------------------------------------------
def phrase_count(num_card, noun):
    """What a noun phrase summons: (stem, count), or None when the words disagree or a word is made up.
    num_card None means the frame's own 'The': a singular noun gives 1, a plural 'several', 'both' whatever the
    wish shows (the sheep)."""
    if not noun.real:
        return None                               # the Jumble comes instead
    if num_card is None:
        if noun.num == "sg":
            return (noun.stem, 1)
        if noun.num == "pl":
            return (noun.stem, "several")
        return (noun.stem, "any")
    n = num_card.value
    if n == 1 and noun.num in ("sg", "both"):
        return (noun.stem, 1)
    if n > 1 and noun.num in ("pl", "both"):
        return (noun.stem, n)
    return None                                   # 'five duck': one duck and four empty outlines; 'a foxes'


def phrase_grants(got, want):
    """want: (stem, count) with count an int or 'several' (any number above one)."""
    if got is None or got[0] != want[0]:
        return False
    g, w = got[1], want[1]
    if g == "any":
        return True
    if w == "several":
        return g == "several" or (isinstance(g, int) and g > 1)
    return g == w


# --- Clauses: how many act ---------------------------------------------------------------------------------------------
def verb_cards(base, s_form):
    return [Card(base, "verb", base, "many"), Card(s_form, "verb", base, "one", gold=s_form[len(base):])]


def pron_cards():
    return [Card("It", "pron", None, "one"), Card("They", "pron", None, "many")]


def clause_grants(subject_number, verb, want_number):
    """The verb's form says how many act ('one' or 'many'); the subject says how many there are. Granted when both
    say what the wish shows (a disagreement: one acts while the rest look puzzled, or ink copies join in)."""
    return verb.num == want_number and subject_number == want_number


# --- A wish -------------------------------------------------------------------------------------------------------------
class Wish:
    """gaps: a list of lists of Cards (each gap's options, shuffled by the maker). context: what the child can SEE in
    the bubble, for each gap (the stem's picture, how many). judge(choice) -> bool: does the world grant the wish."""

    def __init__(self, gaps, context, judge, idea, name=""):
        self.gaps, self.context, self.judge, self.idea, self.name = gaps, context, judge, idea, name

    def right(self, choice):
        return bool(self.judge(choice))


def run(wish, player, rng):
    choice = player(wish, rng)
    return SOLVED if wish.right(choice) else WRONG


def visit(makers, player, seed, rng_factory):
    rng = rng_factory(seed)
    out = []
    for make in makers:
        w = make(rng)
        out.append((w, run(w, player, rng)))
    return out


# --- Players (what they can see: the bubble's picture and count, each card's letters, its gold ending, its picture,
# and what it says when touched) ------------------------------------------------------------------------------------------
def idea(wish, rng):
    """Knows the idea: the wish's own right choice (wish.idea picks it from what is seen and heard)."""
    return wish.idea(wish)


def slips(p=SLIP):
    def player(wish, rng):
        choice = list(wish.idea(wish))
        for i, gap in enumerate(wish.gaps):
            if rng.random() < p:
                others = [c for c in gap if c is not choice[i]]
                if others:
                    choice[i] = rng.choice(others)
        return choice
    return player


def random_cards(wish, rng):
    return [rng.choice(gap) for gap in wish.gaps]


def _right_stem(gap, ctx):
    cards = [c for c in gap if c.kind != "noun" or c.stem == ctx.get("stem")]
    return cards or gap


def by_picture(wish, rng):
    """Matches the picture badge to the bubble's picture, then any form: the picture never shows the grammar."""
    out = []
    for gap, ctx in zip(wish.gaps, wish.context):
        if ctx["role"] == "num":
            out.append(rng.choice(gap))
        else:
            out.append(rng.choice(_right_stem(gap, ctx)))
    return out


def _counts_right(gap, ctx):
    want = ctx["count"]
    return [c for c in gap if c.value == want][0]


def counter_then(pick_noun):
    """Counts the bubble right (a number word is touched and heard, or read), then picks the noun by a habit."""
    def player(wish, rng):
        out = []
        for gap, ctx in zip(wish.gaps, wish.context):
            if ctx["role"] == "num":
                out.append(_counts_right(gap, ctx))
            elif ctx["role"] == "noun":
                out.append(pick_noun(_right_stem(gap, ctx), ctx, rng))
            else:
                out.append(rng.choice(gap))
        return out
    return player


def _many(ctx):
    return ctx["count"] == "several" or (isinstance(ctx["count"], int) and ctx["count"] > 1)


def gold_means_more(cards, ctx, rng):
    """The visible-ending habit: more than one = the card with a gold ending; one = the card without."""
    pool = [c for c in cards if bool(c.gold) == _many(ctx)]
    return rng.choice(pool or cards)


def sounds_like_more(cards, ctx, rng):
    """The by-ear regulariser (overregularisation): more than one = it sounds like the stem with an s added."""
    pool = [c for c in cards if c.sounds_added == _many(ctx)]
    return rng.choice(pool or cards)


def longest_means_more(cards, ctx, rng):
    """More than one = the longest word; one = the shortest."""
    key = (lambda c: -len(c.word)) if _many(ctx) else (lambda c: len(c.word))
    best = min(key(c) for c in cards)
    return rng.choice([c for c in cards if key(c) == best])


def always_plain(cards, ctx, rng):
    """Always the word as it is (no ending): the singular."""
    pool = [c for c in cards if not c.gold and c.real]
    return rng.choice(pool or cards)


def any_form(cards, ctx, rng):
    return rng.choice(cards)
