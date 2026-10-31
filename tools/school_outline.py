#!/usr/bin/env python3
"""The School's outline (owner feedback #68, spec §22) as Markdown, from data/school/grade<N>.json.

    python3 tools/school_outline.py                 # prints the outline
    python3 tools/school_outline.py --write <file>  # replaces the text between the file's outline markers

The grade files are the source of truth; the plan (docs/superpowers/plans/2026-09-28-school.md) keeps a copy of this
outline between `<!-- school-outline:start -->` and `<!-- school-outline:end -->`. Run it again after editing a grade
file. A unit whose lessons are written (it names its content `file`) is marked "(written)".
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
START = "<!-- school-outline:start -->"
END = "<!-- school-outline:end -->"


def grade_files():
    def number(path):
        return int(re.search(r"grade(\d+)\.json$", path).group(1))
    return sorted(glob.glob(os.path.join(ROOT, "data", "school", "grade*.json")), key=number)


def outline():
    lines = []
    for path in grade_files():
        with open(path, encoding="utf-8") as f:
            grade = json.load(f)
        total = sum(len(s["units"]) for s in grade["subjects"])
        written = sum(1 for s in grade["subjects"] for u in s["units"] if u.get("file"))
        lines.append("### Grade %d (%s): %d units, %d written" % (grade["grade"], grade["ages"], total, written))
        lines.append("")
        for subject in grade["subjects"]:
            lines.append("**%s** (%s)" % (subject["title"], subject["framework"]))
            lines.append("")
            for i, unit in enumerate(subject["units"], 1):
                mark = " (written)" if unit.get("file") else ""
                lines.append("%d. **%s**%s (%s): %s." % (i, unit["title"], mark, ", ".join(unit["standards"]),
                                                          "; ".join(unit["goals"])))
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main():
    text = outline()
    if len(sys.argv) >= 3 and sys.argv[1] == "--write":
        path = sys.argv[2]
        with open(path, encoding="utf-8") as f:
            doc = f.read()
        if START not in doc or END not in doc:
            sys.exit("%s has no outline markers" % path)
        head, rest = doc.split(START, 1)
        _, tail = rest.split(END, 1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(head + START + "\n" + text + END + tail)
        print("outline written into %s" % path)
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main()
