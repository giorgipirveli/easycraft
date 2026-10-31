#!/usr/bin/env python3
"""Owner #122 (G0, docs/design/learning-is-play.md §7), re-scoped by owner #133, #134 (docs/design/future-lessons.md
§6): the lead's play audit. Every written unit of the School (data/school/grade<N>.json units that name their `file`)
has a play level: P1 when its play block names a built signature game (a deep game), else P0 (the School's lesson and
questions; the ones a child can do without reading are played through the generic mechanics). This counts the units by
play level and the School's reading debt: the hand-written challenges that play without reading and those that need
it, and why (a written choice, a true-or-false claim, a long question, words to read on a thing), by the game's own
rules (PlayReadless, core/play/play_readless.gd; its limits are data/play/mechanics.json's "readless"). Generators are
counted by tools/play_debt.gd (it runs them); test_play_audit.gd keeps the two counts of hand-written ones equal. It
lists any unit with a type no mechanic knows (there must be none).

    python3 tools/play_audit.py                 # a table per grade: written, P0, P1, blocks, playable, reading debt
    python3 tools/play_audit.py --check         # exits 1 when a unit has a type no mechanic knows (there must be none)
    python3 tools/play_audit.py --units         # every unit: its level, its block, its playable and reading counts
    python3 tools/play_audit.py --json out.json # every unit's row, for the lead

Generated exercises: a generator makes exercises of ExerciseCheck's TYPES (core/school/exercise_check.gd; the content
test checks every generated exercise against them), so a type there with no mechanic would make every unit with a
generator unplayable: the audit checks that table too.
Prints PLAY_AUDIT lines (written, P0, P1, blocks, playable, reading, one per reason, unplayable, and one per unplayable
unit).
"""
import argparse
import collections
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LETTER = re.compile(r"[A-Za-z]")
# PlayReadless's reasons, in its order
WRITTEN_CHOICE = "a written choice"
CLAIM = "a true-or-false claim"
LONG_PROMPT = "a long question"
LONG_THING = "words to read on a thing"
NO_GAME = "no game for its type"
REASONS = (WRITTEN_CHOICE, CLAIM, LONG_PROMPT, LONG_THING, NO_GAME)
THINGS = {"order": ("items",), "sort": ("items", "groups"), "match": ("items", "matches"), "label": ("labels",)}


def data():
    return json.load(open(os.path.join(ROOT, "data", "play", "mechanics.json")))


def mechanics():
    d = data()
    by_type = {}
    names = {}
    status = {}
    for m in d.get("mechanics", []):
        names[m["id"]] = m["name"]
        status[m["id"]] = m.get("status", "kept")
        for t in m.get("types", []):
            by_type[t] = m["id"]
    return by_type, names, d.get("signature", {}) or {}, status


def words(text):
    """PlayReadless.words: the tokens (split on spaces) with a letter."""
    return sum(1 for tok in str(text).split(" ") if tok and LETTER.search(tok))


def why_not(ex, by_type, status, limits):
    """PlayReadless.why_not: "" when a child can play it without reading, else the reading it needs."""
    t = ex.get("type", "")
    if t == "choice":
        return WRITTEN_CHOICE
    if t == "truefalse":
        return CLAIM
    m = by_type.get(t)
    if m is None or status.get(m, "kept") != "kept":
        return NO_GAME
    for key in THINGS.get(t, ()):
        for v in ex.get(key, []) or []:
            text = v.get("text", "") if isinstance(v, dict) else v
            if words(text) > limits["thing_words"]:
                return LONG_THING
    if words(ex.get("prompt", "")) > limits["prompt_words"]:
        return LONG_PROMPT
    return ""


def exercise_types():
    text = open(os.path.join(ROOT, "core", "school", "exercise_check.gd")).read()
    m = re.search(r"const TYPES: Array\[String\] = \[(.*?)\]", text, re.S)
    return re.findall(r'"([a-z_]+)"', m.group(1)) if m else []


def grades():
    out = []
    for p in sorted(glob.glob(os.path.join(ROOT, "data", "school", "grade*.json"))):
        g = int(re.search(r"grade(\d+)\.json$", p).group(1))
        out.append((g, json.load(open(p))))
    return sorted(out)


def audit():
    by_type, names, signature, status = mechanics()
    limits = data().get("readless", {})
    limits = {"thing_words": int(limits.get("thing_words", 3)), "prompt_words": int(limits.get("prompt_words", 16))}
    gen_types = exercise_types()
    gen_without = [t for t in gen_types if t not in by_type]
    rows = []
    for g, d in grades():
        for s in d.get("subjects", []):
            for u in s.get("units", []):
                if "file" not in u:
                    continue
                path = os.path.join(ROOT, "data", "school", u["file"])
                row = {"id": u["id"], "grade": g, "subject": s["id"], "title": u.get("title", ""), "problems": []}
                if not os.path.exists(path):
                    row["problems"].append("its file is missing")
                    row.update({"level": "-", "block": False, "mechanics": {}})
                    rows.append(row)
                    continue
                c = json.load(open(path))
                play = c.get("play") if isinstance(c.get("play"), dict) else None
                game = (play or {}).get("game", "generic")
                row["level"] = "P1" if game in signature else "P0"
                row["block"] = play is not None
                counts = collections.Counter()
                why = collections.Counter()
                playable = 0
                for ex in c.get("exercises", []):
                    t = ex.get("type", "")
                    m = by_type.get(t)
                    if m is None:
                        row["problems"].append("type %s has no mechanic" % t)
                        continue
                    r = "" if row["level"] == "P1" and t in signature.get(game, {}).get("types", []) else \
                        why_not(ex, by_type, status, limits)
                    if r == "":
                        playable += 1
                        counts[m] += 1
                    else:
                        why[r] += 1
                gens = c.get("generators", [])
                if gens and gen_without:
                    row["problems"].append("its generators may make %s, which no mechanic plays" % ", ".join(gen_without))
                if not c.get("exercises") and not gens:
                    row["problems"].append("nothing to play")
                row["mechanics"] = dict(counts)
                row["playable"] = playable
                row["reading"] = sum(why.values())
                row["why"] = dict(why)
                row["cards"] = len(c.get("lesson", []))
                row["generators"] = len(gens)
                rows.append(row)
    return rows, names, gen_without


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="exit 1 when a unit can't be played")
    ap.add_argument("--units", action="store_true", help="one row per unit")
    ap.add_argument("--json", help="write every unit's row to this file")
    args = ap.parse_args()
    rows, names, gen_without = audit()
    unplayable = [r for r in rows if r["problems"]]
    if args.json:
        json.dump(rows, open(args.json, "w"), indent=1)
    by_grade = collections.defaultdict(list)
    for r in rows:
        by_grade[r["grade"]].append(r)
    total = collections.Counter()
    print("%-6s %8s %5s %5s %7s %9s %8s  %s" % ("grade", "written", "P0", "P1", "blocks", "playable", "reading",
                                                "played without reading, by mechanic"))
    for g in sorted(by_grade):
        rs = by_grade[g]
        mech = collections.Counter()
        for r in rs:
            mech.update(r["mechanics"])
        total.update(mech)
        n = sum(mech.values()) or 1
        shares = ", ".join("%s %d%%" % (names.get(m, m), round(100 * k / n)) for m, k in mech.most_common())
        print("%-6s %8d %5d %5d %7d %9d %8d  %s" % (g, len(rs), sum(1 for r in rs if r["level"] == "P0"),
                                                  sum(1 for r in rs if r["level"] == "P1"),
                                                  sum(1 for r in rs if r["block"]), sum(r["playable"] for r in rs),
                                                  sum(r["reading"] for r in rs), shares))
    playable = sum(r["playable"] for r in rows)
    reading = sum(r["reading"] for r in rows)
    why = collections.Counter()
    for r in rows:
        why.update(r["why"])
    print()
    print("Hand-written challenges: %d; played without reading: %d (%d%%); the reading debt: %d (%s)" % (
        playable + reading, playable, round(100 * playable / max(playable + reading, 1)), reading,
        ", ".join("%s %d" % (k, why[k]) for k in REASONS if why[k])))
    print("Generators: tools/play_debt.gd counts them (it runs them).")
    if args.units:
        print()
        for r in rows:
            print("%-44s %s %s playable %d, reading %d %s%s" % (
                r["id"], r["level"], "block" if r["block"] else "-    ", r.get("playable", 0), r.get("reading", 0),
                ", ".join("%s %d" % (names.get(m, m), k) for m, k in sorted(r["mechanics"].items())),
                ("  PROBLEM: " + "; ".join(r["problems"])) if r["problems"] else ""))
    print("PLAY_AUDIT written %d" % len(rows))
    print("PLAY_AUDIT P0 %d" % sum(1 for r in rows if r["level"] == "P0"))
    print("PLAY_AUDIT P1 %d" % sum(1 for r in rows if r["level"] == "P1"))
    print("PLAY_AUDIT blocks %d" % sum(1 for r in rows if r["block"]))
    print("PLAY_AUDIT playable %d" % playable)
    print("PLAY_AUDIT reading %d" % reading)
    for k in REASONS:
        print("PLAY_AUDIT reading_why %s: %d" % (k, why[k]))
    if gen_without:
        print("PLAY_AUDIT generated types without a mechanic: %s" % ", ".join(gen_without))
    print("PLAY_AUDIT unplayable %d" % len(unplayable))
    for r in unplayable:
        print("PLAY_AUDIT cannot play %s: %s" % (r["id"], "; ".join(r["problems"])))
    if args.check and unplayable:
        sys.exit(1)


if __name__ == "__main__":
    main()
