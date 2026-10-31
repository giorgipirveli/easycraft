#!/usr/bin/env python3
"""Adds a grade's subjects to its School outline from the curriculum research (owner #70, #73).

The research (docs/design/school-curriculum-research.md §6) lists every grade's units in one table per subject:
| # | id | Title | Goals (";" between them) | Follows (framework codes, ";" between them) |
This writes those units into data/school/grade<N>.json as the subject's `units` (id "g<N>.<subject>.<id>", title,
goals, standards). A subject the outline already has is left alone unless it is named with --replace, so written
units (their `file`) are never lost by accident.

    tools/school_from_research.py 3 history geography        # add grade 3's history and geography
    tools/school_from_research.py 3 --all-new                 # every subject of grade 3 the outline does not have yet
    tools/school_from_research.py 4 --all-new --dry-run       # show what would be added
    tools/school_from_research.py 4 maths --merge             # add the research's new maths units; keep the rest

--merge keeps every unit the outline has (its title, goals, standards and written `file`), adds the research's units
the outline lacks and puts all of them in the research's order (units the research does not list stay at the end).
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
RESEARCH = os.path.join(ROOT, "docs/design/school-curriculum-research.md")
# The research's table headings -> the School's subject ids and titles, in the School's tab order (Curriculum.SUBJECTS).
SUBJECTS = [
    ("maths", "Maths", "Maths"),
    ("science", "Science", "Science"),
    ("english", "English", "English"),
    ("history", "History", "History"),
    ("geography", "Geography", "Geography"),
    ("citizenship", "Citizenship", "Citizenship"),
    ("computing", "Computing", "Computing"),
    ("art", "Art and Design", "Art and Design"),
    ("music", "Music", "Music"),
    ("health_pe", "Health and PE", "Health and PE"),
    ("design_tech", "Design and Technology", "Design and Technology"),
    ("projects", "Projects", "Projects"),
]
FRAMEWORKS = {
    "history": "England's National Curriculum (KS2-KS3) with California world history, Cambridge Humanities and C3",
    "geography": "England's National Curriculum (KS2-KS3) with Cambridge Humanities and C3",
    "citizenship": "England's citizenship, C3 civics and economics, Jump$tart, Japan's and Finland's ethics",
    "computing": "England's computing with CSTA, Cambridge Computing and Digital Literacy, Estonia and Korea",
    "art": "England's Art and Design with the National Core Arts Standards and Cambridge",
    "music": "England's Music with the National Core Arts Standards",
    "health_pe": "England's PE and health education, SHAPE America, the National Health Education Standards and CASEL",
    "design_tech": "England's Design and Technology with Finland's, Estonia's and Japan's crafts and home economics",
    "projects": "Finland's modules, Japan's integrated study, the IB and Cambridge Global Perspectives",
}
MAX_UNITS = 18      # Curriculum.MAX_UNITS: the map's grid
MAX_GOAL = 120      # characters (the unit page shows each goal on its own line)


def tables(grade: int) -> dict:
    """Heading -> rows [(id, title, goals, follows)] of the research's grade section."""
    text = open(RESEARCH, encoding="utf-8").read()
    m = re.search(r"^### 6\.\d+ Grade %d \(.*?$(.*?)(?=^### |\Z)" % grade, text, re.M | re.S)
    if not m:
        sys.exit("no grade %d section in the research" % grade)
    out = {}
    for block in re.split(r"^#### ", m.group(1), flags=re.M)[1:]:
        heading = re.sub(r"\s*\(\d+\)\s*$", "", block.split("\n", 1)[0]).strip()
        rows = []
        for line in block.split("\n"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) >= 5 and cells[0].isdigit():
                rows.append((cells[1].rstrip("*").strip(), cells[2], cells[3], cells[4]))
        out[heading] = rows
    return out


def units(grade: int, sid: str, rows: list) -> list:
    out = []
    for uid, title, goals, follows in rows:
        if not re.fullmatch(r"[a-z0-9_]+", uid):
            sys.exit("%s: odd unit id %r" % (sid, uid))
        gs = [g.strip().rstrip(".") for g in goals.split(";") if g.strip()]
        gs = [g[0].upper() + g[1:] for g in gs]
        for g in gs:
            if len(g) > MAX_GOAL:
                print("warning: g%d.%s.%s goal of %d characters: %s" % (grade, sid, uid, len(g), g), file=sys.stderr)
        out.append({"id": "g%d.%s.%s" % (grade, sid, uid), "title": title, "standards":
                    [s.strip() for s in follows.split(";") if s.strip()], "goals": gs[:4]})
    if len(out) > MAX_UNITS:
        sys.exit("%s: %d units, the map holds %d" % (sid, len(out), MAX_UNITS))
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("grade", type=int)
    ap.add_argument("subjects", nargs="*", help="subject ids (history, geography, …)")
    ap.add_argument("--all-new", action="store_true", help="every subject the outline does not have yet")
    ap.add_argument("--replace", action="store_true", help="replace the named subjects even if the outline has them")
    ap.add_argument("--merge", action="store_true", help="add the research's new units to subjects the outline has")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    path = os.path.join(ROOT, "data/school/grade%d.json" % a.grade)
    raw = open(path, encoding="utf-8").read()
    grade = json.loads(raw)
    have = {s["id"]: s for s in grade["subjects"]}
    found = tables(a.grade)
    wanted = [sid for sid, _, _ in SUBJECTS if sid not in have] if a.all_new else list(a.subjects)
    for sid in wanted:
        entry = next((e for e in SUBJECTS if e[0] == sid), None)
        if entry is None:
            sys.exit("unknown subject %s" % sid)
        rows = found.get(entry[1])
        if not rows:
            sys.exit("the research has no grade %d %s table" % (a.grade, entry[1]))
        if sid in have and a.merge:
            old = {u["id"]: u for u in have[sid]["units"]}
            new = units(a.grade, sid, rows)
            merged = [old.get(u["id"], u) for u in new] + [u for u in have[sid]["units"] if u["id"] not in
                                                          {n["id"] for n in new}]
            if len(merged) > MAX_UNITS:
                sys.exit("%s: %d units after the merge, the map holds %d" % (sid, len(merged), MAX_UNITS))
            added = [u["id"] for u in merged if u["id"] not in old]
            have[sid]["units"] = merged
            print("grade %d %s: %d units (%d new: %s)" % (a.grade, sid, len(merged), len(added), ", ".join(added)))
            continue
        if sid in have and not a.replace:
            print("grade %d already has %s (use --replace or --merge)" % (a.grade, sid))
            continue
        have[sid] = {"id": sid, "title": entry[2], "framework": FRAMEWORKS.get(sid, have.get(sid, {}).get("framework", "")),
                     "units": units(a.grade, sid, rows)}
        print("grade %d %s: %d units" % (a.grade, sid, len(have[sid]["units"])))
    grade["subjects"] = [have[sid] for sid, _, _ in SUBJECTS if sid in have]
    if a.dry_run:
        return
    with open(path, "w", encoding="utf-8") as f:
        f.write(json.dumps(grade, ensure_ascii=False, indent="\t") + "\n")


if __name__ == "__main__":
    main()
