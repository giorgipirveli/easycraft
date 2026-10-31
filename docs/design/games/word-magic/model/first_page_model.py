"""Phase A's model of the First Page, the phase B slice (docs/design/games/word-magic.md §3.5, §3.9, §3.10): can its
wishes be granted without knowing how English says "how many"?

The First Page's eight judged wishes (after the ghost's first spell, a minute of free spells and two teaching wishes,
none judged). Each wish is a picture in a buddy's bubble (three mice eating cheese) and a frame on the Spell Ribbon with
gaps: a number gap (a, two, three, four, five) and a noun gap (the noun's forms, and the Jumble's made-up words). The
spell is cast; the world summons exactly what the noun phrase says (spell_rules.phrase_count): "five duck" brings one
duck and four empty outlines; "mouses" brings the Jumble. A wish is SOLVED when the first cast grants it. A visit
masters g3.english.nouns_pronouns at 7 of 8 (MasteryRules: at least 5 of every 6).

The FIRST DRAFT asked for one gap a wish (the number already written in the frame), regular nouns only (frog, duck,
fox, box, pony, bunny: -s, -es, -ies), two cards a gap (the singular and the plural), six wishes for more than one and
two for one. The model showed that every habit that reads the visible ending (a gold ending means more than one; the
longest word means more; it sounds like the word with an s added) granted every wish: 100 % of visits, without any idea
that English has plurals that don't add an s. The FINAL page (§3.5) has a number gap AND a noun gap in every wish (a
number word heard or read, the noun's form), three or four cards a gap, the Jumble's made-up words, two wishes for ONE
thing (one of them a wild word: a goose), wild plurals (mice, children, geese), a word that stays the same (sheep) and
an f that turns into v (leaves), and a two-phrase finale (the Story Parade).

Run: /usr/bin/python3 -I docs/design/games/word-magic/model/first_page_model.py 1000 [--draft]
Result (2026-10-18, 1,000 visits each, FINAL; the share of visits reaching 7 of 8): knows how many (reads or listens)
100 %; slips on 4 % of picks 86.2 %; random cards, the picture badge, trial and error with the first cast counting 0 %;
counts right with any form 0.2 %; a gold ending means more 0 %; sounds like an s added 0 %; the longest word 0 %; always
the plain word 0 %; trial and error with a preview (not our design) 100 %. FIRST DRAFT: the three ending habits 100 %,
random 1.7 %. STAGE 2: a child who only listens still masters the page (100 %) but gets the look-alike wish right only
half the time (49 %).
"""
import importlib.util
import os
import random
import statistics
import sys

sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("spell_rules", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                           "spell_rules.py"))
R = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(R)

COUNT_WORD = {1: "a", 2: "two", 3: "three", 4: "four", 5: "five"}


def _num_gap(rng, count, k=3):
    others = [n for n in COUNT_WORD if n != count]
    picks = [count] + rng.sample(others, k - 1)
    cards = [R.number_card(COUNT_WORD[n]) for n in picks]
    rng.shuffle(cards)
    return cards


def phrase_wish(rng, stem, count, num_gap=True, jumbles=True, limit=4, look_alikes=False, name=""):
    """One noun phrase: [number] [noun] (or the frame's own number when num_gap is False; count 'several' = the frame
    says 'The' and the bubble shows many)."""
    nouns = R.noun_cards(stem, jumbles=jumbles, look_alikes=look_alikes, limit=limit)
    rng.shuffle(nouns)
    gaps, ctx = [], []
    if num_gap and count != "several":
        gaps.append(_num_gap(rng, count))
        ctx.append({"role": "num", "count": count})
    gaps.append(nouns)
    ctx.append({"role": "noun", "stem": stem, "count": count})
    fixed = None if count == "several" else R.number_card(COUNT_WORD[count])

    def judge(ch):
        num = ch[0] if len(ch) == 2 else fixed
        return R.phrase_grants(R.phrase_count(num, ch[-1]), (stem, count))

    def right(w):
        out = []
        for gap, c in zip(w.gaps, w.context):
            if c["role"] == "num":
                out.append([x for x in gap if x.value == c["count"]][0])
            else:
                fits = [x for x in gap if R.phrase_grants(R.phrase_count(
                    out[0] if out else fixed, x), (c["stem"], c["count"]))]
                out.append(fits[0])
        return out

    return R.Wish(gaps, ctx, judge, right, name or f"{count} {stem}")


def two_phrases(rng, a, b, name="the Story Parade"):
    """The finale: [number] [noun] and [number] [noun] carried the lanterns."""
    wa, wb = phrase_wish(rng, *a), phrase_wish(rng, *b)

    def judge(ch):
        k = len(wa.gaps)
        return wa.judge(ch[:k]) and wb.judge(ch[k:])

    return R.Wish(wa.gaps + wb.gaps, wa.context + wb.context, judge, lambda w: wa.idea(wa) + wb.idea(wb), name)


REGULAR = ["frog", "duck", "fox", "box", "pony", "bunny"]


def _draft_wish(count):
    return lambda r: phrase_wish(r, r.choice(REGULAR), count if count else r.randint(2, 5), num_gap=False,
                                 jumbles=False)


# The first draft: one gap, the number written in the frame, regular nouns, two cards a gap; 6 wishes for more, 2 for one.
DRAFT = [_draft_wish(None), _draft_wish(1), _draft_wish(None), _draft_wish(None), _draft_wish(1), _draft_wish(None),
         _draft_wish(None), _draft_wish(None)]


def _n(r, lo=2, hi=5):
    return r.randint(lo, hi)


# The final page (§3.5's rules table), wish by wish.
FINAL = [
    lambda r: phrase_wish(r, r.choice(["fox", "frog", "duck"]), 1),            # J1: one, regular
    lambda r: phrase_wish(r, r.choice(["box", "fox"]), _n(r)),                 # J2: -es
    lambda r: phrase_wish(r, "mouse", _n(r)),                                  # J3: wild: mice
    lambda r: phrase_wish(r, r.choice(["goose", "mouse"]), 1),                 # J4: one, wild
    lambda r: phrase_wish(r, r.choice(["leaf", "wolf"]), "several"),           # J5: f to v, "The ___"
    lambda r: phrase_wish(r, r.choice(["pony", "bunny"]), _n(r)),              # J6: -ies
    lambda r: phrase_wish(r, r.choice(["child", "sheep"]), _n(r)),             # J7: wild or the same
    lambda r: two_phrases(r, ("goose", _n(r, 2, 3)), (r.choice(["sheep", "child", "wolf"]), _n(r, 2, 3))),  # J8
]


def stage2(final):
    """The same page once the child's reading has opened stage 2: look-alike made-up words (ponys) join the -ies wish."""
    out = list(final)
    out[5] = lambda r: phrase_wish(r, r.choice(["pony", "bunny"]), _n(r), look_alikes=True, limit=5)
    return out


def by_ear_at_stage2(wish, rng):
    """A child who only listens, at stage 2 (not built: stage 2 opens by reading): ponys and ponies sound the same."""
    choice = list(wish.idea(wish))
    for i, gap in enumerate(wish.gaps):
        same = [c for c in gap if R.heard(c) == R.heard(choice[i])]
        choice[i] = rng.choice(same)
    return choice


def with_preview(wish, rng):
    """Trial and error with a preview of the spell before the seal (NOT our design): it tries until the preview is
    right, then casts."""
    import itertools
    for combo in itertools.product(*wish.gaps):
        if wish.right(list(combo)):
            return list(combo)
    return [g[0] for g in wish.gaps]


PLAYERS = [
    ("knows how many (reads or listens)", R.idea),
    ("knows it, slips on 4 % of picks", R.slips()),
    ("random cards", R.random_cards),
    ("matches the picture badge", R.by_picture),
    ("trial and error, first cast counts", R.by_picture),
    ("counts right, any form", R.counter_then(R.any_form)),
    ("gold ending means more", R.counter_then(R.gold_means_more)),
    ("sounds like an s added (by ear)", R.counter_then(R.sounds_like_more)),
    ("the longest word means more", R.counter_then(R.longest_means_more)),
    ("always the plain word", R.counter_then(R.always_plain)),
    ("trial and error with a preview (not built)", with_preview),
]


def table(night, n, players, title):
    print(title)
    print(f"{'player':44} {'bar':>7} {'solved':>7}  per wish (solved %)")
    rows = []
    for name, player in players:
        visits = [R.visit(night, player, seed, random.Random) for seed in range(n)]
        solved = [sum(1 for _, res in v if res == R.SOLVED) for v in visits]
        bar = sum(1 for s in solved if R.mastered(s, len(night))) / n
        per = [100.0 * sum(1 for v in visits if v[i][1] == R.SOLVED) / n for i in range(len(night))]
        print(f"{name:44} {100 * bar:6.1f}% {statistics.mean(solved):7.2f}  " + " ".join(f"{p:3.0f}" for p in per))
        rows.append((name, 100 * bar, statistics.mean(solved)))
    return rows


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 1000
    if "--draft" in sys.argv:
        table(DRAFT, n, PLAYERS, "FIRST DRAFT (one gap, regular nouns, two cards a gap; the bar 7 of 8)")
        print()
    table(FINAL, n, PLAYERS, "FINAL (the First Page as designed; the bar 7 of 8)")
    print()
    table(stage2(FINAL), n, PLAYERS[:2] + [("only listens, at stage 2 (not built)", by_ear_at_stage2)],
          "STAGE 2 (look-alike made-up words, opened by the child's reading)")


if __name__ == "__main__":
    main()
