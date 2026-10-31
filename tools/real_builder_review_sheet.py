#!/usr/bin/env python3
"""Owner #116, #117 (docs/design/life-skills.md §6: "an expert review before each flagship ships"): writes Real Builder's
review sheet for the owner's experts from its own data (data/tools/real_builder.json), so it says exactly what the game
says: every track's steps in order (the Expert try's own marked), the coach's words, each tool and its real motion with
the step's numbers, the safety gear, owner #118's safe mistakes, every picture answer and its "why", the check, the card,
Try it for real and the sources; and the Tool Book's entries for the tools it uses (data/tools/tools.json).

  /usr/bin/python3 tools/real_builder_review_sheet.py           # writes docs/devlog/parts/tools-r4b-review.md
  /usr/bin/python3 tools/real_builder_review_sheet.py --check   # exits 1 when the sheet is out of date
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROOT / "data" / "tools" / "real_builder.json"
BOOK = ROOT / "data" / "tools" / "tools.json"
OUT = ROOT / "docs" / "devlog" / "parts" / "tools-r4b-review.md"
TRACKS = [("little", "Little (about 6-8)"), ("middle", "Middle (about 9-11)"), ("big", "Big (12 and up)")]
KIND = {"info": "words, then OK", "touch": "do it", "taps": "lay or press them", "find": "put them on",
	"choose": "pick a picture", "count": "pick the number", "go": "go there", "timelapse": "the team builds (a time-lapse)"}


def words(entry):
	return entry if isinstance(entry, str) else entry.get("words", "")


def step_lines(step):
	mode = step.get("mode", "")
	tag = " (Expert try only)" if mode == "expert" else (" (normal try only)" if mode == "normal" else "")
	what = KIND.get(step["kind"], step["kind"])
	target = ", ".join(step["targets"]) if isinstance(step.get("targets"), list) else step.get("target", "")
	extra = []
	for key in ["motion", "tool", "device", "safety", "count", "seconds", "label", "walk"]:
		if key in step:
			extra.append("%s %s" % (key, step[key]))
	if "gear" in step:
		extra.append("gear " + ", ".join(step["gear"]))
	if step.get("glow") is False:
		extra.append("no glowing places")
	if "checks" in step:
		extra.append("numbers " + ", ".join("%s %s" % (k, v) for k, v in step["checks"].items()))
	head = "**%s**%s: %s%s%s" % (step["id"], tag, what, (" `%s`" % target) if target else "",
		(" (" + "; ".join(extra) + ")") if extra else "")
	out = ["- " + head, "  - Coach: \"%s\"" % step["say"]]
	for i, c in enumerate(step.get("choices", [])):
		mark = "right" if i == step.get("answer") else "not this one"
		why = (": \"%s\"" % c["why"]) if c.get("why") else ""
		out.append("  - Picture %s: \"%s\"%s" % (mark, c["text"], why))
	for target, line in step.get("lines", {}).items():
		out.append("  - `%s`: \"%s\"" % (target, line))
	m = step.get("safe_mistake")
	if m:
		out.append("  - Safe mistake (owner #118): trying %s: \"%s\" (shown: %s); then: %s" % (m["wrong"], m["why"],
			m["event"], m["right"]))
		if m.get("try"):   # Life L3b: tried for real (the saw at the wrong moment, before the goggles)
			out.append("    - Tried for real (Life L3b): the first try freezes time, the room shows its still picture, the "
				"coach's card says why; GOT IT, then the goggles glow.")
	if step.get("done"):
		out.append("  - After: \"%s\"" % step["done"])
	return out


def sheet():
	d = json.loads(DATA.read_text())
	book = {t["id"]: t for t in json.loads(BOOK.read_text())["tools"]}
	lines = ["# Real Builder: the review sheet for the experts (owner #116, #117)", "",
		"Written by `tools/real_builder_review_sheet.py` from Real Builder's own data (`data/tools/real_builder.json`) and the "
		"Tool Book (`data/tools/tools.json`): exactly what the game shows and reads aloud. For the review by a bricklaying "
		"trainer (the Brick Development Association, a construction college) and a site safety adviser (the HSE's "
		"construction guidance). Please mark each step: right / change it to ... / remove it. Every tool step names the "
		"real motion it is done with (strike, stroke, twist, squeeze, press, spread, measure, pour, aim, cut) and the "
		"numbers the game checks (metres, m/s, radians, seconds).", ""]
	for dev, model in d.get("devices", {}).items():
		lines.append("The device **%s**: controls: %s. It shows: %s. The right order: %s. Safety: %s." % (dev,
			"; ".join(words(c) for c in model["controls"]), "; ".join(words(s) for s in model["shows"]),
			" → ".join(words(o) for o in model["order"]), "; ".join(words(s) for s in model["safety"])))
		lines.append("")
	used = []
	for track, label in TRACKS:
		t = d["tracks"][track]
		lines += ["## %s: %s" % (label, t["skill"]), "", "The Expert try's twist: %s" % t["twist"], "", "Steps:", ""]
		for step in t["steps"]:
			lines += step_lines(step)
			for k in [step.get("tool"), step.get("safety")] + step.get("gear", []):
				if k and k not in used:
					used.append(k)
		lines += ["", "The before-and-after check (the right one first here; the game mixes their order):", ""]
		for q in t["check"]:
			lines.append("- \"%s\" %s" % (q["say"], " / ".join(("**%s**" if i == q["answer"] else "%s") % c["text"]
				for i, c in enumerate(q["choices"]))))
		card = t["name_it"]
		lines += ["", "The \"name it\" card: **%s**" % card["title"], ""]
		for i, l in enumerate(card["lines"], 1):
			lines.append("%d. %s" % (i, l))
		lines += ["", "Its source line: %s" % card["source"], "", "Try it for real: %s" % t["try_real"], "",
			"Your child can now: %s" % t["can_now"], "", "Sources:", ""]
		for s in t["sources"]:
			lines.append("- %s (%s): %s" % (s["fact"], s["source"], s["url"]))
		lines.append("")
	lines += ["## The Tool Book's words for these tools", ""]
	for k in used:
		e = book.get(k, {})
		lines.append("- **%s** (%s): for %s. How: %s Safety: %s%s" % (e.get("name", k), ", ".join(e.get("motions", [])) or
			"safety gear", e.get("for", ""), e.get("hold", ""), e.get("safety", ""),
			" A grown-up's job in real life." if e.get("grown_up") else ""))
	return "\n".join(lines).rstrip() + "\n"


def main():
	text = sheet()
	if "--check" in sys.argv:
		if not OUT.exists() or OUT.read_text() != text:
			print("real_builder_review_sheet: %s is out of date: run tools/real_builder_review_sheet.py" % OUT)
			return 1
		print("real_builder_review_sheet: up to date")
		return 0
	OUT.write_text(text)
	print("real_builder_review_sheet: wrote %s (%d lines)" % (OUT, text.count("\n")))
	return 0


if __name__ == "__main__":
	sys.exit(main())
