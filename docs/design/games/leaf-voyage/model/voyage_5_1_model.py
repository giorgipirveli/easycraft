"""Phase A's model of voyage 5.1's leaf (docs/design/games/leaf-voyage.md, sections 3.5, 3.9, 3.10): can guessing win?

Six doors (stomata) let CO2 in and water out; heat drives the water out; light and CO2 make sugar. Players stand in
for children: the rule ("open when a cloud cools the leaf, close in the blaze"), a slow child with the rule, a random
masher, always-open, always-closed, and "open whenever it's bright". Act 2's weather is the design's: the trap blaze,
then four turns of a cloud and a blaze, then the evening; only the silent turns (2-4: six beats) are judged, by outcome
and contrast (judge()). The mastery bar is 5 of 6.

Run: /usr/bin/python3 -I docs/design/games/leaf-voyage/model/voyage_5_1_model.py 1000
Result (2026-10-18, 1,000 runs each): the rule 100 % (flat and VR); slow 72 % flat, 100 % VR; random, always-open,
always-closed and open-when-bright 0 %. Its numbers are phase B's starting values for LeafSim, not a final tuning.
"""
import random
import statistics
import sys

DT = 0.1
DOORS = 6
TOGGLE = {"flat": 0.8, "vr": 0.6}        # seconds a door takes to reach and squeeze/tap
R_IN = 0.035          # water from the vein (soil watered), per s, scaled by (1.05 - W)
K_OUT = 0.0060        # per open door per s, times (0.10 + heat)
CUTICLE = 0.0006      # through closed skin
K_C_IN = 0.22         # CO2 diffusion per open door share
K_SUGAR = 0.35        # hexagons per s at full light, CO2 and water
DROOP = 0.55          # below: the leaf droops (seen outside)
DRY = 0.35            # below: too dry, sugar slows to 30 %, Hoot steps in (help)
BUD = 12              # hexagons the bud needs

# The weather script after Act 1: (kind, seconds). Act 2 has four cloud/blaze pairs.
SCRIPT = [("blaze", 14), ("cloud", 20), ("blaze", 15), ("cloud", 20), ("blaze", 15), ("cloud", 20),
          ("blaze", 15), ("cloud", 20), ("blaze", 15), ("evening", 10)]
# Judged: the silent turns only (segments 3-8: cloud 2, blaze 2, cloud 3, blaze 3, cloud 4, blaze 4).
JUDGED = range(3, 9)
HEAT = {"blaze": 1.0, "cloud": 0.25, "evening": 0.2, "night": 0.0}
LIGHT = {"blaze": 1.0, "cloud": 0.7, "evening": 0.4, "night": 0.0}


def weather_at(t):
    acc = 0.0
    for kind, sec in SCRIPT:
        if t < acc + sec:
            return kind, t - acc
        acc += sec
    return "evening", 99.0


class Leaf:
    def __init__(self):
        self.open = [False] * DOORS
        self.W = 0.95
        self.C = 0.0
        self.sugar = 0.0

    def step(self, kind):
        heat, light = HEAT[kind], LIGHT[kind]
        n = sum(self.open)
        out = n * K_OUT * (0.10 + heat) + CUTICLE
        self.W = max(0.0, min(1.0, self.W + (R_IN * (1.05 - self.W) - out) * DT))
        use = min(self.C, light * min(self.C / 0.5, 1.0) * 0.35 * DT * 4)
        self.C = max(0.0, min(1.0, self.C + (K_C_IN * (n / DOORS) * (1.0 - self.C)) * DT * 4 - use))
        water_ok = 1.0 if self.W > DRY else 0.3
        self.sugar += K_SUGAR * light * min(self.C / 0.5, 1.0) * water_ok * DT


class Child:
    """Acts through a queue of door toggles; each takes `toggle` seconds (reach + squeeze)."""

    def __init__(self, policy, mode, rng, reaction):
        self.policy, self.toggle, self.rng, self.reaction = policy, TOGGLE[mode], rng, reaction
        self.busy = 0.0

    def act(self, leaf, kind, since):
        if self.busy > 0:
            self.busy -= DT
            return
        want = None
        p = self.policy
        if p == "rule" or p == "slow":
            if since >= self.reaction:
                target = kind == "cloud"
                for i in range(DOORS):
                    if leaf.open[i] != target:
                        want = i
                        break
        elif p == "random":
            if self.rng.random() < DT / 1.5:
                want = self.rng.randrange(DOORS)
        elif p == "always_open":
            for i in range(DOORS):
                if not leaf.open[i]:
                    want = i
                    break
        elif p == "always_closed":
            want = None
        elif p == "greedy_light":        # opens whenever it is bright: the light-not-heat mistake
            target = kind in ("blaze", "cloud")
            for i in range(DOORS):
                if leaf.open[i] != target and since >= self.reaction:
                    want = i
                    break
        if want is not None:
            leaf.open[want] = not leaf.open[want]
            self.busy = self.toggle


def judge(log):
    """The judged turns (JUDGED): outcome and contrast.

    blaze beat: the leaf never drops below DROOP in the blaze AND in the blaze's second half at most 0.34 of the
    doors are open on average (two of six).
    cloud beat: at least 2 hexagons made in the cloud AND the doors' open share in the cloud's last 70 % is at least
    0.4 above the share in the blaze before it (its last 70 %).
    """
    beats = []
    segs = []
    for kind, sec in SCRIPT:
        segs.append((kind, sec))
    t0 = 0.0
    prev_blaze_share = None
    for idx, (kind, sec) in enumerate(segs):
        rows = [r for r in log if t0 <= r[0] < t0 + sec]
        tail = [r for r in rows if r[0] >= t0 + 0.3 * sec]
        share = statistics.mean(r[2] for r in tail) / DOORS if tail else 0.0
        if kind == "blaze":
            half = [r for r in rows if r[0] >= t0 + 0.5 * sec]
            half_share = statistics.mean(r[2] for r in half) / DOORS if half else 0.0
            ok = min(r[1] for r in rows) >= DROOP and half_share <= 0.34
            if idx in JUDGED:
                beats.append(ok)
            prev_blaze_share = share
        elif kind == "cloud":
            made = rows[-1][3] - rows[0][3]
            contrast = share - (prev_blaze_share if prev_blaze_share is not None else 0.0)
            ok = made >= 2.0 and contrast >= 0.4
            if idx in JUDGED:
                beats.append(ok)
        t0 += sec
    return beats


def run(policy, mode, seed):
    rng = random.Random(seed)
    reaction = {"rule": 1.5, "slow": 4.0}.get(policy, 1.5) + rng.uniform(-0.5, 0.8)
    leaf, child = Leaf(), Child(policy, mode, rng, reaction)
    log = []
    t, total = 0.0, sum(s for _, s in SCRIPT)
    dry_events = 0
    was_dry = False
    while t < total:
        kind, since = weather_at(t)
        child.act(leaf, kind, since)
        leaf.step(kind)
        dry = leaf.W < DRY
        if dry and not was_dry:
            dry_events += 1
        was_dry = dry
        log.append((t, leaf.W, sum(leaf.open), leaf.sugar))
        t += DT
    beats = judge(log)
    return beats, leaf.sugar, min(r[1] for r in log), dry_events


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    print(f"{'policy':14} {'mode':4} {'beats>=5/6':>10} {'avg beats':>9} {'avg sugar':>9} {'min W':>6} {'dry':>5}")
    for mode in ("flat", "vr"):
        for policy in ("rule", "slow", "random", "always_open", "always_closed", "greedy_light"):
            res = [run(policy, mode, s) for s in range(n)]
            passed = sum(1 for b, *_ in res if sum(b) >= 5)
            print(f"{policy:14} {mode:4} {passed / n:10.3f} {statistics.mean(sum(b) for b, *_ in res):9.2f} "
                  f"{statistics.mean(r[1] for r in res):9.1f} {statistics.mean(r[2] for r in res):6.2f} "
                  f"{statistics.mean(r[3] for r in res):5.2f}")


if __name__ == "__main__":
    main()
