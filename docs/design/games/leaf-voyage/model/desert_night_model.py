"""Phase A's model of the transfer voyage 5.T1, The Desert Night (docs/design/games/leaf-voyage.md, section 3.9):
does the sunflower's habit fail where the understood rule wins?

The cactus: a blazing day (heat 1.3, light 1.0, with a dawn that ramps up over 8 s) and a cool, dark night (heat 0.05,
light 0); dry soil gives little water. At night, air that comes in through open doors is kept in jars (CAM: stored in
the cells' vacuoles as an acid); by day the workshops build with the jars' air even with the doors shut. Players: the
understood rule (open when it is cool: here only at night), the sunflower's habit (open by day), random, always closed,
always open. A win: at least 6 sugars and the cactus never drooping.

Run: /usr/bin/python3 -I docs/design/games/leaf-voyage/model/desert_night_model.py 500
Result (2026-10-18, 500 runs each; the six judged beats, 5 of 6 to pass): the rule wins every run with 6 of 6; the
sunflower's habit 0 of 6, random about 1, always closed 4 (it never opens at night), always open 2: none passes.
"""
import random
import statistics
import sys

DT = 0.1
DOORS = 6
TOGGLE = 0.8
R_IN = 0.012           # dry desert soil: little water from the roots, times (1.05 - W)
K_OUT = 0.0060
CUTICLE = 0.0004       # a thick waxy skin
JAR_CAP = 8.0          # air the jars can hold (in hexagon-worths)
K_JAR = 0.06           # air into the jars per open door per s at night
K_SUGAR = 0.35
DROOP = 0.55
DRY = 0.35
SCRIPT = [("day", 30), ("night", 30), ("day", 30), ("night", 30), ("day", 30)]
HEAT = {"day": 1.3, "night": 0.05}
LIGHT = {"day": 1.0, "night": 0.0}


def phase_at(t):
    acc = 0.0
    for kind, sec in SCRIPT:
        if t < acc + sec:
            return kind, t - acc
        acc += sec
    return "day", 99.0


def run(policy, seed):
    rng = random.Random(seed)
    opened = [False] * DOORS
    W, jars, C, sugar = 0.9, 0.0, 0.0, 0.0
    busy, t = 0.0, 0.0
    total = sum(s for _, s in SCRIPT)
    min_w, dry_events, was_dry = 1.0, 0, False
    log = []                                      # (t, W, doors open) for the beats
    reaction = 1.5 + rng.uniform(-0.5, 0.8)
    while t < total:
        kind, since = phase_at(t)
        heat, light = HEAT[kind], LIGHT[kind]
        if kind == "day" and since < 8.0:          # dawn: the heat and the light ramp up
            k = since / 8.0
            heat, light = 0.2 + (HEAT["day"] - 0.2) * k, 0.3 + 0.7 * k
        if busy > 0:
            busy -= DT
        else:
            want = None
            if policy in ("habit", "rule"):
                target = (kind == "day") if policy == "habit" else (kind == "night")
                if since >= reaction:
                    for i in range(DOORS):
                        if opened[i] != target:
                            want = i
                            break
            elif policy == "random" and rng.random() < DT / 1.5:
                want = rng.randrange(DOORS)
            elif policy == "always_open":
                for i in range(DOORS):
                    if not opened[i]:
                        want = i
                        break
            if want is not None:
                opened[want] = not opened[want]
                busy = TOGGLE
        n = sum(opened)
        W = max(0.0, min(1.0, W + (R_IN * (1.05 - W) - (n * K_OUT * (0.10 + heat) + CUTICLE)) * DT))
        if kind == "night":
            jars = min(JAR_CAP, jars + K_JAR * n * DT)
        else:
            C = min(1.0, C + 0.22 * (n / DOORS) * (1.0 - C) * DT * 4)   # day air through open doors
        water_ok = 1.0 if W > DRY else 0.3
        if light > 0:
            from_jars = min(jars, K_SUGAR * light * water_ok * DT) if jars > 0 else 0.0
            from_air = K_SUGAR * light * min(C / 0.5, 1.0) * water_ok * DT if from_jars <= 0 else 0.0
            jars -= from_jars
            C = max(0.0, C - from_air * 2.0)
            sugar += from_jars + from_air
        min_w = min(min_w, W)
        log.append((t, W, n))
        dry = W < DRY
        if dry and not was_dry:
            dry_events += 1
        was_dry = dry
        t += DT
    win = sugar >= 6.0 and min_w >= DROOP
    return win, sugar, min_w, dry_events, judge(log)


def judge(log):
    """The design's six beats (leaf-voyage.md section 3.5b): Day 1, Night 1, Dawn 1, Day 2, Night 2, Dawn 2.

    Day: in the day's second half at most 0.34 of the doors open (two of six) and the cactus never below DROOP.
    Night: at least half the doors open on average over the night's last 70 %.
    Dawn (the next day's first 8 s): at most two doors open at its end and the cactus never below DROOP in it.
    """
    starts, acc = [], 0.0
    for kind, sec in SCRIPT:
        starts.append((kind, acc, sec))
        acc += sec

    def rows(a, b):
        return [r for r in log if a <= r[0] < b]

    beats = []
    for i, (kind, t0, sec) in enumerate(starts[:4]):
        if kind == "day":
            seg = rows(t0, t0 + sec)
            half = rows(t0 + sec / 2, t0 + sec)
            beats.append(min(r[1] for r in seg) >= DROOP and statistics.mean(r[2] for r in half) / DOORS <= 0.34)
        else:
            tail = rows(t0 + 0.3 * sec, t0 + sec)
            beats.append(statistics.mean(r[2] for r in tail) / DOORS >= 0.5)
            _, d0, _ = starts[i + 1]
            dawn = rows(d0, d0 + 8.0)
            beats.append(min(r[1] for r in dawn) >= DROOP and dawn[-1][2] <= 2)
    return beats


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 500
    print(f"{'policy':12} {'wins':>6} {'beats>=5/6':>10} {'avg beats':>9} {'avg sugar':>9} {'min W':>6} {'dry':>5}")
    for policy in ("rule", "habit", "random", "always_closed", "always_open"):
        res = [run(policy, s) for s in range(n)]
        passed = sum(1 for r in res if sum(r[4]) >= 5) / n
        print(f"{policy:12} {sum(r[0] for r in res) / n:6.3f} {passed:10.3f} {statistics.mean(sum(r[4]) for r in res):9.2f} "
              f"{statistics.mean(r[1] for r in res):9.1f} {statistics.mean(r[2] for r in res):6.2f} {statistics.mean(r[3] for r in res):5.2f}")


if __name__ == "__main__":
    main()
