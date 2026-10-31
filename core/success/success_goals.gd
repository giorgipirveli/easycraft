class_name SuccessGoals
extends RefCounted
## Owner #115 (docs/design/success-skills.md §2.6, [S7]; the brief: "the Goal Board (a dream → a goal → steps → if-then
## plans: 'When I finish a lesson, I put 10 gold in my rocket jar'; the Big track writes its own plan from parts), tied
## to the child's real goals in the game (the rocket, a universe, a build)"): the Goal Board's rules over
## SuccessData.goal. Its parts are data/success/goals.json: dreams (each with goals and steps), the if-then plan's
## "when" (cues) and "I will" (actions), ready plans for the Little track, the obstacle plan's "if" (obstacles) and
## "then" (responses), and the habit garden's habits. Nothing is typed: every part is picked from a list.
## A goal's measure says how the game sees it reached: rocket_gold (the child's Survivor gold against Mission Control's
## plan for one astronaut, RocketPlan), flown (MissionData.flown has the mission's world), universe (the next universe
## opened), mastered (School and Life lessons mastered since the goal was set), self_stamps (Life skills done by myself
## since then), or "" (the child ticks the steps: the game can't see a build or a dream of their own).

const PATH := "res://data/success/goals.json"
const MEASURES: Array[String] = ["rocket_gold", "flown", "universe", "mastered", "self_stamps", ""]
const LISTS: Array[String] = ["cues", "actions", "obstacles", "responses"]
const PLAN := "%s, %s."
const STEPS_WORDS := "%d of %d steps done"

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var json := JSON.new()
		var text := FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else ""
		_data = json.data if text != "" and json.parse(text) == OK and json.data is Dictionary else {"dreams": []}
	return _data


static func dreams() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: Variant in data().get("dreams", []):
		if d is Dictionary:
			out.append(d)
	return out


static func dream(id: String) -> Dictionary:
	for d in dreams():
		if str(d.id) == id:
			return d
	return {}


static func goal_of(dream_id: String, goal_id: String) -> Dictionary:
	for g: Dictionary in dream(dream_id).get("goals", []):
		if str(g.id) == goal_id:
			return g
	return {}


static func step_of(dream_id: String, step_id: String) -> Dictionary:
	for s: Dictionary in dream(dream_id).get("steps", []):
		if str(s.id) == step_id:
			return s
	return {}


## One of LISTS: [{id, title}].
static func parts(list: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Variant in data().get(list, []):
		if p is Dictionary:
			out.append(p)
	return out


static func part(list: String, id: String) -> Dictionary:
	for p in parts(list):
		if str(p.id) == id:
			return p
	return {}


static func ready_plans() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Variant in data().get("ready_plans", []):
		if p is Dictionary and not part("cues", str(p.w)).is_empty() and not part("actions", str(p.a)).is_empty():
			out.append(p)
	return out


## The child's goal on `day`: its dream, its goal, its steps in their order and the if-then plan, all from the lists
## (false and nothing kept for a part that isn't). The game's count now is kept so "3 more" counts from today.
static func set_goal(d: SuccessData, profile: ProfileData, dream_id: String, goal_id: String, steps: Array,
		cue: String, action: String, day: int) -> bool:
	var g := goal_of(dream_id, goal_id)
	if g.is_empty() or steps.is_empty() or part("cues", cue).is_empty() or part("actions", action).is_empty():
		return false
	var ids: Array = []
	for s: Variant in steps:
		if step_of(dream_id, str(s)).is_empty() or ids.has(str(s)):
			return false
		ids.append(str(s))
	var goal := {"d": dream_id, "g": goal_id, "s": ids.slice(0, SuccessData.MAX_STEPS), "t": 0, "w": cue, "a": action,
		"c": day, "x": 0, "b": 0, "n": 0}
	match str(g.get("measure", "")):
		"universe":
			goal.b = profile.universe_unlocked
			goal.n = mini(profile.universe_unlocked + 1, UniverseRegistry.size())
		"mastered":
			goal.b = mastered_count(profile)
		"self_stamps":
			goal.b = self_count(profile)
	d.goal = goal
	return true


## The Big track's obstacle plan ("If ..., then ..."); false for parts not on the lists or no goal.
static func set_obstacle(d: SuccessData, obstacle: String, response: String) -> bool:
	if d.goal.is_empty() or part("obstacles", obstacle).is_empty() or part("responses", response).is_empty():
		return false
	d.goal.o = obstacle
	d.goal.r = response
	return true


static func clear(d: SuccessData) -> void:
	d.goal = {}


static func tick(d: SuccessData, i: int) -> void:
	if d.goal.is_empty() or i < 0 or i >= (d.goal.get("s", []) as Array).size():
		return
	d.goal.t = int(d.goal.get("t", 0)) ^ (1 << i)


static func ticked(d: SuccessData, i: int) -> bool:
	return not d.goal.is_empty() and int(d.goal.get("t", 0)) & (1 << i) != 0


static func ticked_count(d: SuccessData) -> int:
	var n := 0
	for i in (d.goal.get("s", []) as Array).size():
		if ticked(d, i):
			n += 1
	return n


## "When I finish a lesson, I put 10 gold aside for my goal." ("" without a plan).
static func plan_words(d: SuccessData) -> String:
	return plan_of(str(d.goal.get("w", "")), str(d.goal.get("a", "")))


static func plan_of(cue: String, action: String) -> String:
	var w := part("cues", cue)
	var a := part("actions", action)
	if w.is_empty() or a.is_empty():
		return ""
	return PLAN % [str(w.title), str(a.title)]


## "If my friends ask me to play, then I play after my step." ("" without one).
static func obstacle_words(d: SuccessData) -> String:
	var o := part("obstacles", str(d.goal.get("o", "")))
	var r := part("responses", str(d.goal.get("r", "")))
	if o.is_empty() or r.is_empty():
		return ""
	return PLAN % [str(o.title), str(r.title)]


static func title(d: SuccessData) -> String:
	return str(goal_of(str(d.goal.get("d", "")), str(d.goal.get("g", ""))).get("title", ""))


## How far the goal is, as the game sees it: {have, need, reached, words}.
static func progress(d: SuccessData, profile: ProfileData) -> Dictionary:
	var out := {"have": 0, "need": 1, "reached": false, "words": ""}
	if d.goal.is_empty():
		return out
	var g := goal_of(str(d.goal.d), str(d.goal.g))
	match str(g.get("measure", "")):
		"rocket_gold":
			var m := _mission(str(g.get("mission", "")))
			out.need = maxi(RocketPlan.gold(m, 1), 1)
			out.have = profile.survivor_gold
			out.words = "Your gold: %d. Mission Control's rocket to %s: %d gold." % [out.have, str(m.get("place", "")),
				out.need]
		"flown":
			var m := _mission(str(g.get("mission", "")))
			out.have = 1 if profile.missions.flown.has(int(m.get("world", -1))) else 0
			out.words = "You flew to %s!" % str(m.get("place", "")) if int(out.have) > 0 else \
				"Not flown yet. Mission Control's plan: %d gold." % RocketPlan.gold(m, 1)
		"universe":
			out.need = int(d.goal.get("n", 0))
			out.have = profile.universe_unlocked
			var name := str(UniverseRegistry.LADDER[clampi(int(out.need) - 1, 0, UniverseRegistry.size() - 1)].display_name)
			out.words = "Next: %s (universe %d)." % [name, out.need]
		"mastered":
			out.need = int(g.get("need", 3))
			out.have = maxi(mastered_count(profile) - int(d.goal.get("b", 0)), 0)
			out.words = "%d of %d lessons mastered since %s." % [out.have, out.need, SchoolClock.short_date(int(d.goal.c))]
		"self_stamps":
			out.need = int(g.get("need", 2))
			out.have = maxi(self_count(profile) - int(d.goal.get("b", 0)), 0)
			out.words = "%d of %d By myself stamps since %s." % [out.have, out.need, SchoolClock.short_date(int(d.goal.c))]
		_:
			out.need = maxi((d.goal.get("s", []) as Array).size(), 1)
			out.have = ticked_count(d)
			out.words = STEPS_WORDS % [out.have, out.need]
	out.reached = int(d.goal.get("x", 0)) > 0 or int(out.have) >= int(out.need)
	return out


## On reaching the goal the first time: true (celebrate), the day kept and goals_reached counted; false after.
static func check_reached(d: SuccessData, profile: ProfileData, day: int) -> bool:
	if d.goal.is_empty() or int(d.goal.get("x", 0)) > 0 or not bool(progress(d, profile).reached):
		return false
	d.goal.x = day
	d.goals_reached += 1
	return true


## Lessons mastered (two stars or three), the School's and Life's.
static func mastered_count(profile: ProfileData) -> int:
	var n := 0
	for id: String in profile.school.units:
		if MasteryRules.stars(profile.school.progress(id)) >= MasteryRules.MASTERED:
			n += 1
	for id: String in profile.life.units:
		if MasteryRules.stars(profile.life.unit(id)) >= MasteryRules.MASTERED:
			n += 1
	return n


## Life skills done by myself (By myself or Expert).
static func self_count(profile: ProfileData) -> int:
	var n := 0
	for id: String in profile.life.skills:
		if profile.life.has_stamp(id, LifeData.SELF):
			n += 1
	return n


## The grown-ups' honest line ("" before a goal was set).
static func grown_ups_line(d: SuccessData, profile: ProfileData) -> String:
	if d.goal.is_empty():
		return ""
	var bits: Array[String] = ["Goal: %s (set %s)." % [title(d), SchoolClock.short_date(int(d.goal.get("c", 0)))]]
	var plan := plan_words(d)
	if plan != "":
		bits.append("Plan: \"%s\"" % plan)
	var obstacle := obstacle_words(d)
	if obstacle != "":
		bits.append("\"%s\"" % obstacle)
	bits.append(STEPS_WORDS % [ticked_count(d), (d.goal.get("s", []) as Array).size()] + ".")
	if int(d.goal.get("x", 0)) > 0:
		bits.append("Reached on %s!" % SchoolClock.short_date(int(d.goal.x)))
	elif str(goal_of(str(d.goal.d), str(d.goal.g)).get("measure", "")) != "":   # what the game measured
		bits.append(str(progress(d, profile).words))
	return " ".join(PackedStringArray(bits))


static func _mission(id: String) -> Dictionary:
	for m in MissionRules.MISSIONS:
		if str(m.id) == id:
			return m
	return {}
