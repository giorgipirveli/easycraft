"""Phase A's model of the Sleepy Dragons, phase B's transfer room (docs/design/games/word-magic.md §3.5b, §3.9): does
the First Page's habit fail here, and does the idea win?

On Dragon Hill the subjects are already written (the dragons, the baby, the egg, the fox and the dragon, the mice, the
sheep) and the child chooses the VERB'S form (snore or snores) and sometimes a pronoun (It or They). The world's rule
(spell_rules.clause_grants; a fiction the honesty table names): the verb's form says how many act. The -s form means
exactly ONE does it; the plain form means ALL of them do. So "The dragons snores" makes one dragon snore while the
others sleep on, and "The baby dragon sneeze" makes ink copies of the baby appear and sneeze with it. The First Page's
habit ("an s at the end means more than one") picks exactly the wrong form every time: on a noun the s means more, on a
verb it means one. (Children learn the plural s years before the verb's s: Brown's order, design §2.1.)

The FIRST DRAFT had one verb gap a wish (two cards: snore, snores): a child who flips a coin reached 5 of 6 on about one
visit in nine. The SECOND DRAFT linked two or three decisions in every wish (two clauses, or a pronoun and its verb) but
had one compound subject: a child who makes the verb agree with the NEAREST noun (the fox and the dragon laughs) still
passed every visit. The FINAL room (§3.5b) has two compound subjects, each beside a clause about one thing.

The six wishes are NEW_SETTING events for g3.english.nouns_pronouns when unhelped (design ruling 15; the bar 5 of 6).

Run: /usr/bin/python3 -I docs/design/games/word-magic/model/sleepy_dragons_model.py 1000 [--draft]
Result (2026-10-18, 1,000 visits each, FINAL; the share reaching 5 of 6): knows it 100 %; slips 4 % 89.3 %; the First
Page's habit 0 %; copies the subject's ending 0 %; agrees with the nearest noun 0 %; always the plain verb 0 %; always
the s verb 0 %; flips a coin 0.1 %. FIRST DRAFT: the coin 11.0 %, always the s verb 11.6 %; SECOND DRAFT: the nearest
noun 100 %.
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

VERBS = [("snore", "snores"), ("sneeze", "sneezes"), ("dance", "dances"), ("hatch", "hatches"), ("cheer", "cheers"),
         ("laugh", "laughs"), ("roll", "rolls"), ("squeak", "squeaks"), ("honk", "honks"), ("yawn", "yawns"),
         ("sleep", "sleeps"), ("fly", "flies"), ("splash", "splashes")]

# Subjects as the child sees them: (the words, how many there are, its last word ends in s, the number of the noun
# nearest the verb).
SUBJECTS = {
    "dragons": ("The dragons", "many", True, "many"), "dragon": ("The dragon", "one", False, "one"),
    "baby": ("The baby", "one", False, "one"), "babies": ("The babies", "many", True, "many"),
    "egg": ("The egg", "one", False, "one"), "eggs": ("The eggs", "many", True, "many"),
    "fox_and_dragon": ("The fox and the dragon", "many", False, "one"),
    "goose_and_mouse": ("The goose and the mouse", "many", False, "one"),
    "mice": ("The mice", "many", False, "many"), "mouse": ("The mouse", "one", False, "one"),
    "goose": ("The goose", "one", False, "one"), "geese": ("The geese", "many", False, "many"),
    "sheep_one": ("The sheep", "one", False, "one"), "sheep_many": ("The sheep", "many", False, "many"),
    "they": ("They", "many", False, "many"), "it": ("It", "one", False, "one"),
}


def _verb_gap(rng, verb):
    cards = R.verb_cards(*verb)
    rng.shuffle(cards)
    return cards


def clause_wish(rng, parts, name=""):
    """parts: a list of clauses; each ('subject key', verb) with the subject written in the frame, or ('pron', want,
    verb) with a pronoun gap whose referent shows `want` ('one' or 'many') in the bubble."""
    gaps, ctx, plan = [], [], []
    for p in parts:
        if p[0] == "pron":
            _, want, verb = p
            pg = R.pron_cards()
            rng.shuffle(pg)
            gaps.append(pg)
            ctx.append({"role": "pron", "want": want})
            gaps.append(_verb_gap(rng, verb))
            ctx.append({"role": "verb", "want": want, "subject": None})
            plan.append(("pron", want))
        else:
            key, verb = p
            text, want, ends_s, nearest = SUBJECTS[key]
            gaps.append(_verb_gap(rng, verb))
            ctx.append({"role": "verb", "want": want, "subject": (text, want, ends_s, nearest)})
            plan.append(("fixed", want))

    def judge(ch):
        i = 0
        for kind, want in plan:
            if kind == "pron":
                pron, verb = ch[i], ch[i + 1]
                i += 2
                if not R.clause_grants(pron.num, verb, want):
                    return False
            else:
                verb = ch[i]
                i += 1
                if not R.clause_grants(want, verb, want):
                    return False
        return True

    def right(w):
        out = []
        for gap, c in zip(w.gaps, w.context):
            out.append([x for x in gap if x.num == c["want"]][0])
        return out

    return R.Wish(gaps, ctx, judge, right, name)


def _pick(rng, k):
    return rng.sample(VERBS, k)


def _one_or_many(rng, one_key, many_key):
    return rng.choice([one_key, many_key])


# The first draft: one verb a wish (snore or snores), the subject written.
def _draft(key_one, key_many):
    return lambda r: clause_wish(r, [(_one_or_many(r, key_one, key_many), _pick(r, 1)[0])])


DRAFT = [_draft("dragon", "dragons"), _draft("baby", "babies"), _draft("egg", "eggs"), _draft("mouse", "mice"),
         _draft("goose", "geese"), _draft("sheep_one", "sheep_many")]


def _two(r, a, b):
    v = _pick(r, 2)
    return clause_wish(r, [(a, v[0]), (b, v[1])])


# The final room (§3.5b): two or three linked decisions in every wish; two compound subjects (D4, D5).
FINAL = [
    lambda r: _two(r, "dragons", r.choice(["baby", "babies"])),                      # D1: the dragons snore, the baby…
    lambda r: clause_wish(r, [("pron", "many", _pick(r, 1)[0]), ("mouse", _pick(r, 1)[0])]),  # D2: They dance; the mouse…
    lambda r: _two(r, r.choice(["egg", "eggs"]), "mice"),                             # D3: the egg hatches; the mice…
    lambda r: clause_wish(r, [("fox_and_dragon", _pick(r, 1)[0]), ("pron", "many", _pick(r, 1)[0])]),  # D4
    lambda r: _two(r, "goose_and_mouse", "dragon"),                                   # D5: two subjects, then one
    lambda r: clause_wish(r, [(r.choice(["sheep_one", "sheep_many"]), _pick(r, 1)[0]),
                              ("pron", r.choice(["one", "many"]), _pick(r, 1)[0])]),   # D6: only the verb says how many
]

# The second draft: as FINAL but with one compound subject (D5 was "the mice squeak, and the goose honks"): agreeing
# with the nearest noun passed 5 of 6 on every visit.
SECOND_DRAFT = list(FINAL)
SECOND_DRAFT[4] = lambda r: _two(r, "mice", r.choice(["goose", "geese"]))


# --- Players ---------------------------------------------------------------------------------------------------------
def verb_habit(choose):
    """A habit for the verb's form; every habit player knows It is one thing and They many (generous to it)."""
    def player(wish, rng):
        out = []
        for gap, c in zip(wish.gaps, wish.context):
            if c["role"] == "pron":
                out.append([x for x in gap if x.num == c["want"]][0])
            else:
                want_s = choose(c, out, rng)
                pool = [x for x in gap if bool(x.gold) == want_s]
                out.append(rng.choice(pool or gap))
        return out
    return player


def _subject_many(c, out):
    if c["subject"] is None:
        return out[-1].num == "many"
    return c["subject"][1] == "many"


def s_means_more(c, out, rng):
    """The First Page's habit carried over: an s at the end means more than one."""
    return _subject_many(c, out)


def copy_the_ending(c, out, rng):
    """The verb copies the subject's ending: an s on the subject, an s on the verb."""
    if c["subject"] is None:
        return out[-1].word.endswith("s")
    return c["subject"][2]


def nearest_noun(c, out, rng):
    """Agrees with the noun nearest the verb (the fox and THE DRAGON laughs): agreement attraction."""
    if c["subject"] is None:
        return out[-1].num == "one"
    return c["subject"][3] == "one"


PLAYERS = [
    ("knows it (the verb agrees: s means one)", R.idea),
    ("knows it, slips on 4 % of picks", R.slips()),
    ("the First Page's habit: an s means more", verb_habit(s_means_more)),
    ("copies the subject's ending", verb_habit(copy_the_ending)),
    ("agrees with the nearest noun", verb_habit(nearest_noun)),
    ("always the plain verb (he go)", verb_habit(lambda c, o, r: False)),
    ("always the s verb", verb_habit(lambda c, o, r: True)),
    ("flips a coin", R.random_cards),
]


def table(room, n, title):
    print(title)
    print(f"{'player':44} {'bar':>7} {'solved':>7}  per wish (solved %)")
    rows = []
    for name, player in PLAYERS:
        visits = [R.visit(room, player, seed, random.Random) for seed in range(n)]
        solved = [sum(1 for _, res in v if res == R.SOLVED) for v in visits]
        bar = sum(1 for s in solved if R.mastered(s, len(room))) / n
        per = [100.0 * sum(1 for v in visits if v[i][1] == R.SOLVED) / n for i in range(len(room))]
        print(f"{name:44} {100 * bar:6.1f}% {statistics.mean(solved):7.2f}  " + " ".join(f"{p:3.0f}" for p in per))
        rows.append((name, 100 * bar, statistics.mean(solved)))
    return rows


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 1000
    if "--draft" in sys.argv:
        table(DRAFT, n, "FIRST DRAFT (one verb a wish; the bar 5 of 6)")
        print()
        table(SECOND_DRAFT, n, "SECOND DRAFT (linked decisions, one compound subject; the bar 5 of 6)")
        print()
    table(FINAL, n, "FINAL (the Sleepy Dragons as designed; the bar 5 of 6)")


if __name__ == "__main__":
    main()
