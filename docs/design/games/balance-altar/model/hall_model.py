"""Phase A's model of the Entrance Hall, the phase B slice (docs/design/games/balance-altar.md §3.5, §3.9, §3.10):
can the hall be won without the knowledge?

The hall's eight judged altars (after three teaching altars that are not judged): x + a = b, b = x + a, c x = b,
x + a = b, b = c x, b = x + a, c x = b, and the Great Altar c x + a = b; numbers new every visit (the crystal's weight
1-8, at most 12-15 gems on a pan). The tools are the hands (take), the sharing bowls (share) and the gem bag (add).
Each altar is SOLVED when the child frees the crystal with no rule break, no help and at most one operation more than
the shortest solution (altar_rules.py). A visit masters the unit (g6.maths.equations) when at least 5 of every 6 judged
altars are SOLVED (MasteryRules: 7 of 8).

The players stand in for children: one who knows the rule (and one who knows it but slips), and the ways to try
without it: random taps, random moves, keeping the balance with no plan, guessing which move undoes what, the habits
'always take away' and 'divide by the number', working on the crystal's pan only, carrying things across, and using
the beam as a scale (refused by the chained beam; the free-swinging counterfactual shows why the chain is there).
A 'greedy' player that keeps the balance and always makes the crystal more alone is shown too: it wins, because that is
the understanding the hall teaches (§3.9).

Run: /usr/bin/python3 -I docs/design/games/balance-altar/model/hall_model.py 1000
Result (2026-10-18, 1,000 visits each; the share of visits reaching 7 of 8): knows the rule 100 %; knows it but slips
4 % of moves 95.3 %; keeps the balance and makes the crystal more alone (greedy) 100 %; keeps the balance with no plan
0.2 % (3.0 of 8); guesses which move 0 % (1.6 of 8); 'always take away' 0 % (4 of 8); 'divide by the number' 0 %
(3 of 8); random moves, random taps, one pan only, carrying across, weighing with the chained beam: 0 %. Weighing with
a free-swinging beam (not our design) 100 %: the reason the beam is chained. Phase B's AltarSim starts from these rules.
"""
import importlib.util
import os
import random
import statistics
import sys

sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("altar_rules", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                            "altar_rules.py"))
R = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(R)

HALL = ["add_L", "add_R", "mul_L", "add_L", "mul_R", "add_R", "mul_L", "two_L"]

PLAYERS = [
    ("knows the rule", R.bot_rule),
    ("knows it, slips 4 %", R.bot_rule_slips(0.04)),
    ("keeps balance, greedy", R.bot_greedy_legal),
    ("keeps balance, no plan", R.bot_legal_random),
    ("guesses which move", R.bot_op_guess),
    ("habit: always take away", R.bot_take_only),
    ("habit: divide by the number", R.bot_share_only),
    ("random moves", R.bot_random_moves),
    ("random taps", None),
    ("one pan only", R.bot_one_pan),
    ("carries across", R.bot_mover),
    ("weighs (chained beam)", R.bot_weigh),
    ("weighs (free beam: not ours)", R.free_beam(R.bot_weigh)),
]


def visit(bot, seed):
    rng = random.Random(seed)
    results = []
    for form in HALL:
        s, x = R.make(form, rng)
        alt = R.play_taps(s, x, R.HALL, rng) if bot is None else R.play(s, x, R.HALL, bot, rng)
        results.append((form, alt))
    return results


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    print(f"{'player':30} {'masters':>8} {'solved/8':>8} {'breaks':>7} {'helped':>7} {'shown':>6}  per altar (solved %)")
    for name, bot in PLAYERS:
        visits = [visit(bot, seed) for seed in range(n)]
        solved = [sum(1 for _, a in v if a.outcome() == R.SOLVED) for v in visits]
        masters = sum(1 for sv in solved if R.mastered(sv, len(HALL))) / n
        breaks = statistics.mean(sum(a.breaks for _, a in v) for v in visits)
        helped = statistics.mean(sum(1 for _, a in v if a.outcome() == R.HELPED) for v in visits)
        shown = statistics.mean(sum(1 for _, a in v if a.outcome() == R.SHOWN) for v in visits)
        per = []
        for i, form in enumerate(HALL):
            per.append(100.0 * sum(1 for v in visits if v[i][1].outcome() == R.SOLVED) / n)
        per_s = " ".join(f"{p:3.0f}" for p in per)
        print(f"{name:30} {100 * masters:7.1f}% {statistics.mean(solved):8.2f} {breaks:7.2f} {helped:7.2f} {shown:6.2f}  {per_s}")
    print("altars:", " ".join(HALL))


if __name__ == "__main__":
    main()
