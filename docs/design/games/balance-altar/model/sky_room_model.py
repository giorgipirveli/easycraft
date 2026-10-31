"""Phase A's model of the transfer room, the Sky Room (docs/design/games/balance-altar.md §3.5b, §3.9): does the
hall's habit fail where the understood rule wins?

The Sky Room floats in the clouds and its altars carry balloons: a balloon tied to a pan pulls it up (a balloon and a
gem on the same pan cancel and float off together). Six judged altars, numbers new every visit: x - a = b, x - a = b,
x + a = b, b = x - a, c x = b, and the room's own Great Altar c x - a = b (four with a balloon beside the crystal, two
familiar). The tools: the hands, the sharing bowls, the gem bag and the balloon pump. A judged altar freed with no rule
break, no help and within its move budget is NEW_SETTING (transfer) for g6.maths.equations; 5 of the 6 is the bar.

The hall taught 'take away what is beside the crystal, then share'. Here what is beside the crystal is a balloon, and
there is no balloon on the other pan to take: the habit is stuck. The rule ('the same to both pans; undo what is beside
the crystal') says: a balloon is undone by a gem, so put that many gems on BOTH pans; the gem and the balloon float off.

Run: /usr/bin/python3 -I docs/design/games/balance-altar/model/sky_room_model.py 1000
Result (2026-10-18, 1,000 visits each; the share reaching 5 of 6): knows the rule 100 %; slips 4 % 97.0 %; the hall's
habit 0 % (it frees only the two familiar altars, 2 of 6); keeps the balance and makes the crystal more alone 100 %;
keeps the balance with no plan 0 % (1.2 of 6); guesses which move 0.2 % (1.4 of 6); 'always take away' 0 %; random
moves and taps, one pan only, carrying across: 0 %.
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

SKY = ["sub_L", "sub_L", "add_L", "sub_R", "mul_L", "subtwo_L"]

PLAYERS = [
    ("knows the rule", R.bot_rule),
    ("knows it, slips 4 %", R.bot_rule_slips(0.04)),
    ("the hall's habit", R.bot_habit),
    ("keeps balance, greedy", R.bot_greedy_legal),
    ("keeps balance, no plan", R.bot_legal_random),
    ("guesses which move", R.bot_op_guess),
    ("habit: always take away", R.bot_take_only),
    ("random moves", R.bot_random_moves),
    ("random taps", None),
    ("one pan only", R.bot_one_pan),
    ("carries across", R.bot_mover),
]


def visit(bot, seed):
    rng = random.Random(10_000 + seed)
    out = []
    for form in SKY:
        s, x = R.make(form, rng)
        alt = R.play_taps(s, x, R.SKY, rng) if bot is None else R.play(s, x, R.SKY, bot, rng)
        out.append((form, alt))
    return out


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    print(f"{'player':26} {'5 of 6':>7} {'transfer/6':>10} {'breaks':>7}  per altar (new-setting %)")
    for name, bot in PLAYERS:
        visits = [visit(bot, seed) for seed in range(n)]
        solved = [sum(1 for _, a in v if a.outcome() == R.SOLVED) for v in visits]
        bar = sum(1 for sv in solved if R.mastered(sv, len(SKY))) / n
        breaks = statistics.mean(sum(a.breaks for _, a in v) for v in visits)
        per = [100.0 * sum(1 for v in visits if v[i][1].outcome() == R.SOLVED) / n for i in range(len(SKY))]
        print(f"{name:26} {100 * bar:6.1f}% {statistics.mean(solved):10.2f} {breaks:7.2f}  " + " ".join(f"{p:3.0f}" for p in per))
    print("altars:", " ".join(SKY))


if __name__ == "__main__":
    main()
