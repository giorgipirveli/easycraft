"""Phase A's model of the Word Lights (docs/design/games/word-magic.md §3.6 "the reading track", §3.10): the game's
record of the child's own reading, which moves the fade. Can guessing light words, and does a reader get the pictures
taken away soon enough not to feel babied?

Every card says its word when touched (a non-reader is never stuck). A word LIGHTS (turns gold in the child's
Spellbook, and its picture badge fades from then on) when the child picks it right WITHOUT touching it first, three
times in a row, in three different wishes, each time beside cards that look like it (the same picture badge: fox,
foxes, foxs; or the same first letter). A wrong pick without a touch puts the word's count back to nought; when two of
a lit word's last three unaided picks are wrong its badge comes back until it lights again. A touch is never a
mistake: it just isn't evidence.

The FIRST DRAFT lit a word after one right pick without a touch, and the SECOND after two: a child who never touches
and guesses (a third of its picks are right by luck) lit most of the words it met within two sessions and nearly all of
them in ten. The THIRD DRAFT asked for three in a row and put the badge back after ONE wrong pick: guessing kept about
3.5 % of the words lit, but a reader's rare slips kept taking its own badges back (about one word in eleven it reads
stayed dark). The FOURTH DRAFT put the badge back after two wrong picks in a row, the FINAL rule after two wrong picks
among the word's last three: a reader keeps 99 % of its words lit, a guesser about 7 % at any time (each only until
its next misses), a child who reads only the first letter and the gold ending about 10 %.

A session: 120 picks (about 30 minutes of the First Page, the Sleepy Dragons and free spells), each pick a target word
from a vocabulary of 40 word forms, in a hand of 3 cards: the target and two that look like it (half the hands hold
another word with the same first letter instead of one of the forms). Ten sessions (the child's first weeks).

The LEARNER is an assumption, not a measurement: it starts reading none of the words; every time it touches a card
while looking at it, or hears Hoot read its own spell with each word lighting as it is said, that word gets one
exposure; after a number of exposures (on average 6, from 2 to 14) it can read that word. The point is not how fast a
real child learns (no source gives that for this setting) but whether the lights FOLLOW what it can read.

Run: /usr/bin/python3 -I docs/design/games/word-magic/model/word_lights_model.py 1000 [--draft]
Result (2026-10-18, 500 runs each, FINAL; after sessions 1 / 2 / 10): reads the words: 51.4 % / 89.9 % / 99.4 % of the
words it reads are lit, none it can't; never reads (touches every card): nothing lit; never touches (guesses): 3.1 % /
6.4 % / 7.2 % of all words lit though it reads none; first letter and gold ending only: 4.5 % / 9.1 % / 10.3 %; learns
from the voice (an assumption): 24.5 % / 62.3 % / 99.5 % of what it reads, never a word it can't. FIRST DRAFT: the
guesser 63.4 % after one session; SECOND: 26.5 %; THIRD (one wrong pick unlights): the reader keeps only 91 %.
"""
import random
import statistics
import sys

sys.dont_write_bytecode = True

VOCAB = 40
PICKS = 120
SESSIONS = 10
HAND = 3
READ_RIGHT = 0.97          # a reader's unaided pick is right this often
AT = (1, 2, 5, 10)         # the sessions the table shows


class Lights:
    """The lighting rule. need: right unaided picks in a row to light; reset: a wrong unaided pick resets the count;
    unlight: wrong unaided picks in a row (no right one between) that put a lit word's badge back (0: never)."""

    def __init__(self, need, reset, unlight, window=0):
        self.need, self.reset, self.unlight, self.window = need, reset, unlight, window
        self.streak, self.misses, self.lit, self.last_wish, self.history = {}, {}, set(), {}, {}

    def unaided(self, word, right, wish):
        if right and self.last_wish.get(word) == wish:
            return                                      # one wish counts once
        self.last_wish[word] = wish
        h = self.history.setdefault(word, [])
        h.append(right)
        if right:
            self.misses[word] = 0
            self.streak[word] = self.streak.get(word, 0) + 1
            if self.streak[word] >= self.need:
                self.lit.add(word)
            return
        if self.reset:
            self.streak[word] = 0
        self.misses[word] = self.misses.get(word, 0) + 1
        if self.window:
            if sum(1 for x in h[-self.window:] if not x) >= self.unlight:
                self.lit.discard(word)
        elif self.unlight and self.misses[word] >= self.unlight:
            self.lit.discard(word)


RULES = {
    "first draft: one right pick": (1, False, 0),
    "second draft: two right picks": (2, False, 0),
    "third draft: three in a row, one wrong pick unlights": (3, True, 1),
    "fourth draft: three in a row, two wrong in a row unlight": (3, True, 2),
    "final: three in a row; two wrong of the last three unlight": (3, True, 2, 3),
}
FINAL = "final: three in a row; two wrong of the last three unlight"


# --- Players: for a pick, (touched?, right?) -----------------------------------------------------------------------
class Reader:
    def knows(self, word):
        return True

    def pick(self, word, hand, twin, rng):
        if rng.random() < 0.05:
            return True, rng.random() < 0.99           # touches to check now and then
        return False, rng.random() < READ_RIGHT

    def heard(self, word):
        pass


class Listener:
    def knows(self, word):
        return False

    def pick(self, word, hand, twin, rng):
        return True, rng.random() < 0.97

    def heard(self, word):
        pass


class Guesser:
    def knows(self, word):
        return False

    def pick(self, word, hand, twin, rng):
        return False, rng.random() < 1.0 / hand

    def heard(self, word):
        pass


class FirstLetter:
    def knows(self, word):
        return False

    def pick(self, word, hand, twin, rng):
        # the forms of one word share their first letter; it tells a gold ending from none (right half the time among
        # two forms with an ending), and a same-first-letter word beside it halves that again
        p = 0.5 if not twin else 0.25
        return False, rng.random() < p

    def heard(self, word):
        pass


class Learner:
    def __init__(self, rng):
        self.need = {w: min(14, max(2, int(rng.expovariate(1 / 6.0)) + 1)) for w in range(VOCAB)}
        self.seen = {w: 0 for w in range(VOCAB)}

    def knows(self, word):
        return self.seen[word] >= self.need[word]

    def pick(self, word, hand, twin, rng):
        if self.knows(word):
            return False, rng.random() < READ_RIGHT
        return True, rng.random() < 0.97

    def heard(self, word):
        self.seen[word] += 1


PLAYERS = [
    ("reads the words", lambda r: Reader()),
    ("never reads: touches every card", lambda r: Listener()),
    ("never touches: guesses by the picture", lambda r: Guesser()),
    ("reads only the first letter and the gold ending", lambda r: FirstLetter()),
    ("learns from the voice (an assumption)", lambda r: Learner(r)),
]


def run(player_factory, rule, seed):
    rng = random.Random(seed)
    player = player_factory(rng)
    lights = Lights(*RULES[rule])
    wish = 0
    snaps = []
    for _ in range(SESSIONS):
        for _ in range(PICKS):
            wish += 1
            word = rng.randrange(VOCAB)
            twin = rng.random() < 0.5
            touched, right = player.pick(word, HAND, twin, rng)
            if touched:
                player.heard(word)                     # a touch: the word heard while it is seen (an exposure)
            else:
                lights.unaided(word, right, wish)
            if right:
                player.heard(word)                     # Hoot reads the cast spell, each word lighting as it is said
        known = {w for w in range(VOCAB) if player.knows(w)}
        snaps.append((len(lights.lit - known), len(lights.lit & known), len(known)))
    return snaps


def table(rule, n):
    print(f"RULE: {rule}  ({PICKS} picks a session, {VOCAB} word forms, hands of {HAND})")
    print(f"{'after session':48}" + "".join(f"{f'#{k}':>20}" for k in AT))
    print(f"{'':48}" + "".join(f"{'not read lit / read lit':>20}" for _ in AT))
    for name, factory in PLAYERS:
        rows = [run(factory, rule, seed) for seed in range(n)]
        cells = []
        for k in AT:
            false = statistics.mean(r[k - 1][0] for r in rows)
            true = statistics.mean(r[k - 1][1] for r in rows)
            known = statistics.mean(r[k - 1][2] for r in rows)
            share = f"{100 * true / known:.1f}%" if known else "-"
            cells.append(f"{100 * false / VOCAB:.1f}% / {share}")
        print(f"{name:48}" + "".join(f"{c:>20}" for c in cells))


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 1000
    rules = list(RULES) if "--draft" in sys.argv else [FINAL]
    for rule in rules:
        table(rule, n)
        print()
    print("'not read lit': words lit that the player cannot read, of all 40 (a picture taken away too soon: the child")
    print("just touches the card); 'read lit': of the words it can read by then, the share lit (low: a reader babied).")


if __name__ == "__main__":
    main()
