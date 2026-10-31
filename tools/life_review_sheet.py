#!/usr/bin/env python3
"""Owner #112 (docs/design/life-skills.md §6: "an expert review before each flagship ships"): writes the review sheet
for the owner's experts from the Experiences' own data (data/life/experiences/*.json), so it always says exactly what
the game says: every track's steps in order (the Expert try's own steps marked), the coach's words, the kind words
after, every picture answer and its gentle "why", the before-and-after check, the "name it" card and its source, Try it
for real, and the sources with their URLs. {number} is shown as 112 (Georgia), the kerb drill and the street's sign as
Georgia's (left, right, left; 30 km/h); the money and the kitchen's values as their tokens (they vary with each try).
Four sheets: Life L1's three Experiences, Life L2's three (owner #112), Life L3a's three (owner #118: the safe
mistakes, the danger moments whose time slows on the first tries, the harmless wrong taps, the calm debrief) and Life
L3b's three (owner #118: electricity, animals, medical emergencies; L3b's fire and heat steps are in L1's and L2's sheets,
in Fire Escape and The Kitchen). Every source is a checkbox: each fact is marked for the expert's review before it
ships (design §14).

  python3 tools/life_review_sheet.py                      # writes docs/devlog/parts/life-l1-review.md and -l2-review.md
  python3 tools/life_review_sheet.py --check              # exits 1 when a sheet is out of date
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROOT / "data" / "life" / "experiences"
SHEETS = [
	(ROOT / "docs" / "devlog" / "parts" / "life-l1-review.md", "Life L1", ["little_lifesaver", "fire_escape", "money_stall"]),
	(ROOT / "docs" / "devlog" / "parts" / "life-l2-review.md", "Life L2", ["safe_streets", "kitchen", "calm_corner"]),
	(ROOT / "docs" / "devlog" / "parts" / "life-l3a-review.md", "Life L3a",
		["water_safety", "poisons_cupboard", "earth_weather"]),
	(ROOT / "docs" / "devlog" / "parts" / "life-l3b-review.md", "Life L3b", ["electricity", "animals", "medical"]),
	(ROOT / "docs" / "devlog" / "parts" / "life-l3c-review.md", "Life L3c", ["online_city", "find_way", "home_helper"]),
]
TRACKS = [("little", "Little (about 6-8)"), ("middle", "Middle (about 9-11)"), ("big", "Big (12 and up)")]
REVIEWER = {"little_lifesaver": "a first aid trainer (the IFRC / national Red Cross or Red Crescent, the ERC)",
	"fire_escape": "a fire safety officer (the fire and rescue service)",
	"money_stall": "a financial educator (the OECD/INFE and EU money frameworks)",
	"safe_streets": "a road safety officer (the national road safety authority; the WHO's pedestrian safety manual)",
	"kitchen": "a food safety and nutrition educator (the WHO's Five Keys to Safer Food and healthy diet advice)",
	"calm_corner": "a child psychologist or school counsellor (CASEL; the national children's mental-health guidance)",
	"water_safety": "a lifesaving and water safety instructor (the Royal Life Saving Society, the RNLI or the national "
		"lifesaving federation; for the ice, a rescue service)",
	"poisons_cupboard": "a poison centre's specialist and a child accident prevention officer (the national poison "
		"centre; the Child Accident Prevention Trust); for carbon monoxide, a gas safety engineer or the fire service",
	"earth_weather": "a civil protection officer (Georgia's Emergency Management Service) with a meteorologist (the "
		"National Environmental Agency) and a mountain rescue volunteer",
	"electricity": "an electrical safety specialist (Electrical Safety First or the national electrical safety body) and "
		"the electricity network's safety officer (fallen lines, substations), with a first aid trainer for electric shock",
	"animals": "a vet or a kennel club's dog safety educator (the Dogs Trust, the Kennel Club), a farm safety officer and a "
		"mountain rescue volunteer (Georgia's mountains: bears, wolves, guard dogs), with an allergy nurse for stings",
	"medical": "a first aid trainer (the national Red Cross or Red Crescent, St John Ambulance), an allergy nurse or "
		"Anaphylaxis UK (the auto-injector trainer), an asthma nurse (Asthma + Lung UK) and an epilepsy nurse (Epilepsy "
		"Action, the Epilepsy Foundation)",
	"online_city": "an online safety educator (the UK Safer Internet Centre, Childnet or the national Safer Internet Centre) "
		"with a child protection adviser (the NSPCC or UNICEF's national office), and the game's own password rules (owner #105)",
	"find_way": "a police community officer or a child-safety charity's educator (lost children, never going off with anyone), "
		"the fire and rescue service (school fire drills), the city's metro (Tbilisi Transport Company) and an orienteering "
		"or Ordnance Survey map-skills trainer",
	"home_helper": "a home safety educator (RoSPA or the fire and rescue service for the smoke alarm and the dishwasher's "
		"knives), a vet or the RSPCA (pets), the local council's or Tbilisi's recycling service (the bins), and GINETEX (care "
		"labels)"}
KIND = {"info": "words, then OK", "touch": "touch it", "hold": "hold it", "hands": "both hands on it", "taps": "tap it",
	"sequence": "press in order", "find": "find them", "choose": "pick a picture", "count": "pick the number",
	"action": "do it with the body", "go": "go there", "point": "aim at it", "rhythm": "push to the beat",
	"coins": "give coins", "basket": "shop", "sweep": "sweep across it", "timelapse": "the clock runs by itself",
	"look": "look both ways (VR: the head turns)", "cross": "cross only when it is safe (a car stops gently if not)",
	"rub": "rub for its seconds", "pour": "pour or weigh to the line", "breathe": "breathe with the balloon",
	"feel": "pick a feeling (any picture is right, nothing kept)", "steady": "keep the needle in its band"}
TOKENS = {"{number_words}": "one one two", "{number}": "112", "{look_order}": "left, right, left", "{look_sides}":
	"left, right, left", "{first_side}": "left", "{then_side}": "right", "{speed_limit}": "30", "{speed_unit}": "km/h",
	"{speed_lo}": "20", "{speed_hi}": "30", "{speed_top}": "60",
	"{quake_where}": "In Georgia the Caucasus mountains are still growing, so the ground can shake here.",
	"{wild_where}": "In Georgia's mountains live brown bears, wolves and wild boar, and big shepherd dogs guard the flocks "
		"of sheep.",
	"{metro_where}": "Tbilisi's metro has two lines too, and they meet at Station Square, where you change.",
	"{bins_where}": "In Georgia, more and more places have their own bins for plastic bottles or for paper: look for them "
		"near you."}


def fill(text):
	out = str(text)
	for token, words in TOKENS.items():
		out = out.replace(token, words)
	return out


def step_lines(step):
	mode = step.get("mode", "")
	tag = " (Expert try only)" if mode == "expert" else (" (normal try only)" if mode == "normal" else "")
	what = KIND.get(step["kind"], step["kind"])
	targets = step.get("targets")
	if isinstance(targets, list):
		target = ", ".join(targets)
	elif isinstance(targets, str):
		target = "the keys of 112" if targets == "{number_keys}" else targets
	else:
		target = step.get("target", "")
	extra = []
	for key in ["motion", "tool", "device", "seconds", "count", "pushes", "good", "sweeps", "need", "sum", "budget", "label",
			"action", "sides", "rule", "reach", "want", "full", "tol", "unit", "lo", "hi", "top", "breaths", "in", "out",
			"button", "pay"]:
		if key in step:
			extra.append("%s %s" % (key, fill(step[key]) if isinstance(step[key], str) else step[key]))
	if step.get("glow") is False:
		extra.append("no glow")
	if step.get("low"):
		extra.append("stay low")
	if step.get("danger"):
		extra.append("a danger moment: its time slows on the first tries, real time on the Expert try")
	if step.get("within"):
		extra.append("wanted within %s s of the room's time" % step["within"])
	head = "**%s**%s: %s%s%s" % (step["id"], tag, what, (" `%s`" % target) if target else "",
		(" (" + ", ".join(extra) + ")") if extra else "")
	out = ["- " + head, "  - Coach: \"%s\"" % fill(step["say"])]
	for i, c in enumerate(step.get("choices", [])):
		mark = "right" if i == step.get("answer") else ("the safe mistake" if c.get("mistake") else "not this one")
		why = (": \"%s\"" % fill(c["why"])) if c.get("why") else ""
		out.append("  - Picture (%s) %s: \"%s\"%s" % (c.get("icon", ""), mark, fill(c["text"]), why))
	if step.get("miss"):
		out.append("  - A miss: \"%s\"" % fill(step["miss"]))
	if step.get("late"):
		out.append("  - Too late (a kind miss): \"%s\"" % fill(step["late"]))
	for target, line in step.get("not", {}).items():
		out.append("  - A harmless wrong tap `%s` (a kind miss): \"%s\"" % (target, fill(line)))
	m = step.get("safe_mistake")
	if m:
		tried = m.get("try", "the picture marked as the mistake")
		if tried == "unsafe":
			tried = "the right thing at the wrong moment (unsafe)"
		out.append("  - **The safe mistake** (owner #118: the child may try it; time freezes, the scene goes soft and still): "
			"the wrong way: %s (tried by: `%s`); the room's gentle picture: `%s`; the why card's picture: `%s`" % (m["wrong"],
			tried, m["event"], m.get("icon", "")))
		out.append("    - The coach's calm why: \"%s\"" % fill(m["why"]))
		out.append("    - Then the right way: \"%s\"" % fill(m["right"]))
	for target, line in step.get("lines", {}).items():
		out.append("  - Found `%s`: \"%s\"" % (target, fill(line)))
	if step.get("done"):
		out.append("  - After: \"%s\"" % fill(step["done"]))
	return out


def sheet(name, ids):
	lines = ["# %s: the review sheet for the experts (owner #112)" % name, "",
		"Written by `tools/life_review_sheet.py` from the Experiences' own data (`data/life/experiences/*.json`): "
		"exactly what the game shows and reads aloud. `{number}` is shown as 112 (Georgia's and Europe's number: the "
		"game uses the region a grown-up sets). Please mark each step: right / change it to ... / remove it. "
		+ ("Every first aid Experience says \"This is practice. A real first aid course teaches more.\" " if "little_lifesaver"
			in ids else ("Every Experience says it is practice and is calm (no injuries, no scares). On the Middle and Big "
			"tracks some steps let the child try **the wrong way** (a safe mistake, design §14): time freezes, the scene "
			"goes soft and still, the room shows gently what would happen, the coach says why, then the child does it "
			"right; on the Little track the coach says the rule first and no mistake is shown. Danger moments run slower "
			"on a child's first tries and at real speed on the Expert try. After each of these emergency Experiences comes "
			"a calm debrief: \"You did it. In real life, grown-ups help too.\" `{quake_where}` and `{wild_where}` are shown as Georgia's "
			"sentence (each region has its own). " if "water_safety" in ids or "electricity" in ids else
			("Every Experience says it is practice and is calm. Online City is all pretend: no real sites, apps, brands or "
			"people; nothing the child types or says is kept or sent; nothing personal is ever typed (every answer is a "
			"button or a picture). Find Your Way never asks for an address or a phone number: the child says them aloud to "
			"their grown-up (Try it for real); the school's emergency is a fire drill, never a lockdown; the man who says "
			"\"come with me\" only ever stands where he is. On the Middle and Big tracks of Online City and Find Your Way "
			"some steps let the child try **the wrong way** (a safe mistake: time freezes, the scene goes soft and still, "
			"the coach says why, then the right way); never on Little, and never in Home Helper's chores (a wrong bin or a "
			"knife pointing up is a kind miss with its why). After Online City and Find Your Way comes the calm debrief. "
			"`{metro_where}` and `{bins_where}` are shown as Georgia's sentences (each region has its own). "
			if "online_city" in ids else
			"Every Experience says it is practice; the kerb drill and the street's sign are shown as Georgia's "
			"(the game follows the grown-up's region: \"right, left, right\" where cars drive on the left, 20 mph in the UK "
			"and the US); a car stops gently for a child who steps out when it isn't safe; nothing a child picks in Calm "
			"Corner is kept. ")))
		+ "Each hands-on step names its real motion (owner #117: one of strike, stroke, twist, squeeze, press, spread, "
		"measure, pour, aim, cut), the thing in the hand, and the device it uses.", ""]
	if "kitchen" in ids:
		lines += ["The Kitchen's recipes (they vary with each try's seed: `core/life/life_kitchen.gd`): Little a rainbow "
			"fruit salad, raita (India), Bircher muesli (Switzerland), a cucumber and tomato salad (Georgia); Middle pancakes "
			"(the UK and France), an omelette (France), fried rice (China), porridge (Scotland); Big lentil dal (India), "
			"shakshuka (Tunisia), jollof rice (West Africa), pasta with tomato sauce (Italy). The cup's amount is a quarter, "
			"a half or three quarters.", ""]
	for exp_id in ids:
		d = json.loads((DATA / (exp_id + ".json")).read_text())
		lines += ["## %s" % d["title"], "", "For the review by %s." % REVIEWER[exp_id], ""]
		for dev, model in d.get("devices", {}).items():
			lines.append("The device **%s** (owner #117, the device model): controls: %s. It shows: %s. The right order: %s. "
				"Safety: %s." % (dev, "; ".join(model["controls"]), "; ".join(model["shows"]),
				" → ".join(fill(x) for x in model["order"]), "; ".join(fill(x) for x in model["safety"])))
		if d.get("devices"):
			lines.append("")
		for track, words in TRACKS:
			t = d["tracks"][track]
			lines += ["### %s: %s" % (words, t["skill"]), "", "The Expert try's twist: %s" % fill(t["twist"]), "",
				"Steps:", ""]
			for step in t["steps"]:
				lines += step_lines(step)
			lines += ["", "The before-and-after check (the same questions, the right one first here; the game mixes "
				"their order):", ""]
			for q in t["check"]:
				lines.append("- \"%s\" %s" % (fill(q["say"]), " / ".join(
					("**%s**" if i == q["answer"] else "%s") % fill(c["text"]) for i, c in enumerate(q["choices"]))))
			card = t["name_it"]
			lines += ["", "The \"name it\" card: **%s**" % card["title"], ""]
			for i, l in enumerate(card["lines"], 1):
				lines.append("%d. %s" % (i, fill(l)))
			lines += ["", "Its source line: %s" % card["source"], "", "Try it for real: %s" % fill(t["try_real"]), "",
				"Your child can now: %s" % fill(t["can_now"]), "", "Sources:", ""]
			for s in t["sources"]:
				lines.append("- [ ] %s (%s): %s" % (s["fact"], s["source"], s["url"]))
			lines.append("")
	return "\n".join(lines).rstrip() + "\n"


def main():
	stale = 0
	for out, name, ids in SHEETS:
		text = sheet(name, ids)
		if "--check" in sys.argv:
			if not out.exists() or out.read_text() != text:
				print("life_review_sheet: %s is out of date: run tools/life_review_sheet.py" % out)
				stale += 1
			continue
		out.write_text(text)
		print("life_review_sheet: wrote %s (%d lines)" % (out, text.count("\n")))
	if "--check" in sys.argv and stale == 0:
		print("life_review_sheet: up to date")
	return 1 if stale else 0


if __name__ == "__main__":
	sys.exit(main())
