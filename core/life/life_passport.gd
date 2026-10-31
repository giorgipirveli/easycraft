class_name LifePassport
extends RefCounted
## Owner #112, #113 (docs/design/life-skills.md §3, §7, §11; spec §27): the Life Passport's rules over LifeData.
## - A page per skill: every Experience on every track (skills()).
## - A finished run stamps the page (LifeRun's bits: Done it, By myself, Expert; informational, never lost, never paid
##   for themselves: engagement research §1.8); the skill's first finished run pays GOLD once, like a lesson mastered
##   (the core loop, spec §25: learning pays for the rocket); a new Expert stamp is the surprise celebration.
## - Spaced repeats: the skill comes back REPEAT_DAYS after its first finished run, step by step; never required,
##   nothing expires; a run before the day changes nothing.
## - The before-and-after checks: the first before-check is kept; the after-check's best and latest; the grown-ups'
##   line says only what was measured ("knew 1 of 5 at the start, now 5 of 5, in 9 minutes").
## - "Your child can now...": the skills done by themselves (By myself or Expert); "practising": with the coach's help.

const GOLD := EarnRules.LIFE_SKILL_GOLD   # the Gold Shop's "How to earn" names it (Life L2)
const REPEAT_DAYS: Array[int] = [1, 3, 7, 21, 60]
const TRACK_WORDS := {"little": "Little", "middle": "Middle", "big": "Big"}


## Every page: {id, experience, track, title (the skill's name), area}, in the Experiences' order, Little first.
static func skills() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			out.append({"id": LifeExperience.skill_id(id, track), "experience": id, "track": track,
				"title": str(LifeExperience.track_data(id, track).get("skill", "")),
				"area": str(LifeExperience.data(id).get("area", ""))})
	return out


## A finished run's outcome (LifeRun.outcome) on `today`: {new (stamps new this time), expert_new, gold (to pay now;
## the caller credits it: EarnRules.credit), first (the skill's first finished run)}.
static func record_run(life: LifeData, skill: String, outcome: Dictionary, today: int) -> Dictionary:
	var out := {"new": 0, "expert_new": false, "gold": 0, "first": false}
	if not bool(outcome.get("finished", false)) or not LifeData.valid_skill_id(skill):
		return out
	var p := life.skill(skill)
	var before := int(p.s)
	var first := int(p.r) == 0 and before == 0
	p.r = int(p.r) + 1
	p.s = before | int(outcome.get("stamps", 0))
	p.t = maxi(int(p.t), today)
	if int(p.c) == 0:
		p.c = today
	if int(p.w) <= 0:
		p.w = maxi(roundi(float(outcome.get("seconds", 0.0))), 1)
	if first:
		p.x = 0
		p.d = today + REPEAT_DAYS[0]
	elif today >= int(p.d):
		p.x = mini(int(p.x) + 1, REPEAT_DAYS.size() - 1)
		p.d = today + REPEAT_DAYS[int(p.x)]
	if not bool(p.g):
		p.g = true
		out.gold = GOLD
	life.set_skill(skill, p)
	out.new = int(p.s) & ~before
	out.expert_new = int(out.new) & LifeData.EXPERT != 0
	out.first = first
	return out


## A before-check (after = false: only the first one counts) or an after-check (its best and its latest).
static func record_check(life: LifeData, skill: String, after: bool, right: int, total: int) -> void:
	var p := life.skill(skill)
	p.q = clampi(total, 0, LifeData.MAX_QUESTIONS)
	right = clampi(right, 0, LifeData.MAX_QUESTIONS)
	if after:
		p.a = maxi(int(p.a), right)
		p.l = right
	elif int(p.b) < 0:
		p.b = right
	life.set_skill(skill, p)


static func stamps(life: LifeData, skill: String) -> int:
	return int(life.skill(skill).s)


## The Expert try opens once the skill is done by the child alone.
static func expert_open(life: LifeData, skill: String) -> bool:
	return life.has_stamp(skill, LifeData.SELF)


## A repeat is suggested on `today` (the map's leaf: PRACTISE AGAIN): a skill played once, on or after its day.
static func repeat_due(life: LifeData, skill: String, today: int) -> bool:
	var p := life.skill(skill)
	return int(p.s) != 0 and today >= int(p.d)


## The grown-ups' honest line for a skill ("" until it was played).
static func summary_line(life: LifeData, skill: String) -> String:
	var parts := LifeExperience.of_skill(skill)
	var p := life.skill(skill)
	if parts.is_empty() or (int(p.r) == 0 and int(p.b) < 0):
		return ""
	var name := "%s (%s)" % [LifeExperience.title(parts[0]), TRACK_WORDS[parts[1]]]
	var bits: Array[String] = []
	if int(p.b) >= 0:
		bits.append("knew %d of %d at the start" % [int(p.b), int(p.q)])
	if int(p.l) >= 0:
		bits.append("now %d of %d" % [int(p.l), int(p.q)])
	if int(p.w) > 0:
		var minutes := maxi(roundi(int(p.w) / 60.0), 1)
		bits.append("in %d minute%s" % [minutes, "" if minutes == 1 else "s"])
	if bits.is_empty():
		return "%s: practised %d time%s." % [name, int(p.r), "" if int(p.r) == 1 else "s"]
	return "%s: %s." % [name, ", ".join(bits)]


## "Your child can now ..." for every skill done by themselves, in plain words with the region's number.
static func can_now(life: LifeData, region: String) -> Array[String]:
	var out: Array[String] = []
	for page in skills():
		if life.has_stamp(str(page.id), LifeData.SELF):
			out.append(LifeExperience.words(str(page.experience), str(page.track), "can_now", region))
	return out


## Skills practised with the coach's help, not yet done alone: what the child is learning now.
static func practising(life: LifeData, region: String) -> Array[String]:
	var out: Array[String] = []
	for page in skills():
		var s := stamps(life, str(page.id))
		if s & LifeData.DONE and not s & LifeData.SELF:
			out.append(LifeExperience.words(str(page.experience), str(page.track), "can_now", region))
	return out


## The skills played in the last 7 days (the weekly summary).
static func this_week(life: LifeData, today: int) -> Array[String]:
	var out: Array[String] = []
	for page in skills():
		var t := int(life.skill(str(page.id)).t)
		if t > 0 and today - t < 7 and today >= t:
			out.append(str(page.id))
	return out
