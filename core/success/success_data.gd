class_name SuccessData
extends RefCounted
## Owner #115 (docs/design/success-skills.md §2 systems 3, 6, 7; §4): Success S2's part of the profile, kept inside
## Life's (ProfileData.life.success) so the account's backup carries it and nothing else sends it anywhere. Everything in
## it was picked from pictures and lists (nothing is ever typed); parsed field by field (a bad field falls back on its
## own), limited in size, merged without losing a kept day, a person met or a story read. Days are SchoolClock's.
## - goal: the Goal Board's one goal (SuccessGoals): d the dream, g the goal, s its steps (ids, in the child's order),
##   t the steps ticked (bits), w / a the if-then plan's "when" and "I will", o / r the obstacle plan's "if" and "then",
##   c the day it was set, x the day it was reached (0 not yet), b the game's count when it was set (for "3 more"), n the
##   amount it needs (the rocket's gold, the universe).
## - goals_reached: how many goals the child has reached in all.
## - habit: the habit garden's plant growing now (SuccessHabits): h the habit, c the day it was chosen, k the days it was
##   kept (whole days, oldest first, the newest MAX_DAYS), n the days kept in all (the plant's size), l the last day the
##   child answered, y that answer. Never a streak: a missed day changes nothing kept.
## - garden: the plants of earlier habits, {h, n}, at the size they grew to.
## - people: the Connections Book (SuccessPeople), id -> m the day met, w warmth 0..MAX_WARMTH (shown as the person's
##   warmth, never as a number or a score others see), h times helped, p promises kept, i introductions, t the mentor's
##   tip learned.
## - stories: the Success Stories read (SuccessStories), id -> r the day first read, a its question answered.
## Owner #115 (S3):
## - shop: My Business's shop (SuccessShop): s its sign (an id of data/success/shop.json's signs), l the ledger [{d the
##   day, i money in, o money out, c customers served, k complaints fixed}] (pretend market coins; the newest
##   SHOP_MAX_DAYS days, one entry a day), r the customers' reviews [{w who, s stars 1..5, k the words' kind}] (the
##   newest SHOP_MAX_REVIEWS), g the real gold paid {d the day, g gold} (at most the day's cap), t gold paid in all. The
##   saved data never calls the rules (ProfileData loads it, and SuccessShop reaches the economy and the screens: a
##   compile cycle), so the limits live here and SuccessShop uses them.
## - market: the Market Square (SuccessMarket): t its tries finished, x the dice lesson seen (why gambling loses over
##   time), b the days the Price Board was read, l the last of them.

const VERSION := 1
const MAX_DAYS := 400
const MAX_GARDEN := 12
const MAX_PEOPLE := 64
const MAX_STORIES := 64
const MAX_STEPS := 6
const MAX_WARMTH := 5
const MAX_COUNT := 99_999
const GOAL_KEYS := ["d", "g", "w", "a", "o", "r"]
const GOAL_NUMBERS := ["t", "c", "x", "b", "n"]
const PERSON_DEFAULTS := {"m": 0, "w": 0, "h": 0, "p": 0, "i": 0, "t": false}
## Owner #115 (S3): the shop's limits (SuccessShop's DAY_CAP, MAX_DAYS, MAX_REVIEWS and MAX_COINS are these).
const SHOP_DAY_CAP := 50
const SHOP_MAX_DAYS := 60
const SHOP_MAX_REVIEWS := 12
const SHOP_MAX_COINS := 9_999
const STORY_DEFAULTS := {"r": 0, "a": false}

static var _id_re := RegEx.create_from_string("^[a-z][a-z0-9_]{0,31}$")

var goal := {}
var goals_reached := 0
var habit := {}
var garden: Array[Dictionary] = []
var people := {}
var stories := {}
var shop := {}   # owner #115 (S3)
var market := {}   # owner #115 (S3)


static func valid_id(id: Variant) -> bool:
	return id is String and _id_re.search(id) != null


func is_empty() -> bool:
	return goal.is_empty() and goals_reached == 0 and habit.is_empty() and garden.is_empty() and people.is_empty() \
		and stories.is_empty() and shop.is_empty() and market.is_empty()


# --- People and stories ------------------------------------------------------------------------------------------

func person(id: String) -> Dictionary:
	var out := PERSON_DEFAULTS.duplicate()
	var stored: Variant = people.get(id)
	if stored is Dictionary:
		out.merge(stored, true)
	return out


func set_person(id: String, p: Dictionary) -> void:
	if not valid_id(id) or (not people.has(id) and people.size() >= MAX_PEOPLE):
		return
	var clean := _clean_person(p)
	if clean.is_empty():
		people.erase(id)
	else:
		people[id] = clean


func met(id: String) -> bool:
	return int(person(id).m) > 0


func story(id: String) -> Dictionary:
	var out := STORY_DEFAULTS.duplicate()
	var stored: Variant = stories.get(id)
	if stored is Dictionary:
		out.merge(stored, true)
	return out


func story_read(id: String) -> bool:
	return int(story(id).r) > 0


## A story read on `day` (the first day stays), its question answered right (once true, it stays).
func mark_story(id: String, day: int, answered: bool) -> void:
	if not valid_id(id) or day <= 0 or (not stories.has(id) and stories.size() >= MAX_STORIES):
		return
	var s := story(id)
	if int(s.r) <= 0 or day < int(s.r):
		s.r = day
	s.a = bool(s.a) or answered
	stories[id] = {"r": int(s.r), "a": bool(s.a)}


# --- Saving --------------------------------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	var g: Array = []
	for plant in garden:
		g.append(plant.duplicate())
	var out := {"v": VERSION, "goal": goal.duplicate(true), "reached": goals_reached, "habit": habit.duplicate(true),
		"garden": g, "people": people.duplicate(true), "stories": stories.duplicate(true)}
	if not shop.is_empty():   # owner #115 (S3)
		out.shop = shop.duplicate(true)
	if not market.is_empty():
		out.market = market.duplicate(true)
	return out


static func from_dict(v: Variant) -> SuccessData:
	var d := SuccessData.new()
	if not v is Dictionary:
		return d
	var src: Dictionary = v
	d.goal = _clean_goal(src.get("goal"))
	d.goals_reached = _count(src.get("reached"))
	d.habit = _clean_habit(src.get("habit"))
	var g: Variant = src.get("garden")
	if g is Array:
		for plant: Variant in g:
			if d.garden.size() >= MAX_GARDEN:
				break
			var clean := _clean_plant(plant)
			if not clean.is_empty():
				d.garden.append(clean)
	var p: Variant = src.get("people")
	if p is Dictionary:
		for id: Variant in p:
			if valid_id(id) and p[id] is Dictionary:
				d.set_person(id, p[id])
	var s: Variant = src.get("stories")
	if s is Dictionary:
		for id: Variant in s:
			if valid_id(id) and s[id] is Dictionary:
				d.mark_story(id, _count(s[id].get("r")), s[id].get("a") is bool and s[id].a)
	d.shop = _clean_shop(src.get("shop"))   # owner #115 (S3)
	d.market = _clean_market(src.get("market"))
	return d


## Merges an older copy into this one (ProfileBackup.merge merges into the newer): the newer goal (its day set), the
## most goals reached; the same habit's kept days together (another habit's plant goes into the garden, never lost);
## every plant of the garden at its biggest; every person met (the first meeting, the warmest warmth, every help,
## promise and introduction counted at its most, a tip once learned); every story read (the first day).
func merge_from(other: SuccessData) -> void:
	if goal.is_empty() or (not other.goal.is_empty() and int(other.goal.get("c", 0)) > int(goal.get("c", 0))):
		goal = other.goal.duplicate(true)
	goals_reached = maxi(goals_reached, other.goals_reached)
	if habit.is_empty():
		habit = other.habit.duplicate(true)
	elif not other.habit.is_empty():
		if str(other.habit.h) == str(habit.h):
			var days: Array = (habit.k as Array).duplicate()
			for day: Variant in other.habit.k:
				if not days.has(day):
					days.append(day)
			days.sort()
			habit.k = days.slice(maxi(days.size() - MAX_DAYS, 0))
			habit.n = maxi(maxi(int(habit.n), int(other.habit.n)), days.size())
			habit.c = mini(int(habit.c), int(other.habit.c)) if int(habit.c) > 0 else int(other.habit.c)
			if int(other.habit.l) > int(habit.l):
				habit.l = other.habit.l
				habit.y = other.habit.y
		else:
			var keep := habit if int(habit.c) >= int(other.habit.c) else other.habit
			var away := other.habit if keep == habit else habit
			habit = keep.duplicate(true)
			into_garden(str(away.h), int(away.n))
	for plant in other.garden:
		into_garden(str(plant.h), int(plant.n))
	if not habit.is_empty():
		for i in range(garden.size() - 1, -1, -1):
			if str(garden[i].h) == str(habit.h):
				garden.remove_at(i)   # the plant growing now is the same habit's
	for id: String in other.people:
		var a := person(id)
		var b := other.person(id)
		if int(a.m) <= 0 or (int(b.m) > 0 and int(b.m) < int(a.m)):
			a.m = b.m
		for key: String in ["w", "h", "p", "i"]:
			a[key] = maxi(int(a[key]), int(b[key]))
		a.t = bool(a.t) or bool(b.t)
		set_person(id, a)
	for id: String in other.stories:
		var s := other.story(id)
		mark_story(id, int(s.r), bool(s.a))
	_merge_shop(other)   # owner #115 (S3)


## Owner #115 (S3): the shop's every day (the same day once: the copy with more customers that day), a sign from either,
## the newer copy's reviews (the older's when it has none), the most gold paid on the latest day paid, the most in all;
## the market's most tries, the dice lesson once seen, the most Price Board days.
func _merge_shop(other: SuccessData) -> void:
	if not other.shop.is_empty():
		var mine := shop.duplicate(true)
		if not mine.has("s") and other.shop.has("s"):
			mine.s = other.shop.s
		var days := {}
		for e: Variant in other.shop.get("l", []):
			days[int(e.d)] = (e as Dictionary).duplicate()
		for e: Variant in mine.get("l", []):
			if not days.has(int(e.d)) or int(e.c) >= int(days[int(e.d)].c):
				days[int(e.d)] = (e as Dictionary).duplicate()
		var ledger: Array = days.values()
		ledger.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.d) < int(b.d))
		if not ledger.is_empty():
			mine.l = ledger.slice(maxi(ledger.size() - SHOP_MAX_DAYS, 0))
		if (mine.get("r", []) as Array).is_empty() and not (other.shop.get("r", []) as Array).is_empty():
			mine.r = (other.shop.r as Array).duplicate(true)
		var g_a: Dictionary = mine.get("g", {})
		var g_b: Dictionary = other.shop.get("g", {})
		if not g_b.is_empty() and (g_a.is_empty() or int(g_b.d) > int(g_a.d)):
			mine.g = g_b.duplicate()
		elif not g_b.is_empty() and int(g_b.d) == int(g_a.d):
			mine.g = {"d": int(g_a.d), "g": maxi(int(g_a.g), int(g_b.g))}
		var t := maxi(int(mine.get("t", 0)), int(other.shop.get("t", 0)))
		if t > 0:
			mine.t = t
		shop = _clean_shop(mine)
	if not other.market.is_empty():
		market = _clean_market({"t": maxi(int(market.get("t", 0)), int(other.market.get("t", 0))),
			"x": bool(market.get("x", false)) or bool(other.market.get("x", false)),
			"b": maxi(int(market.get("b", 0)), int(other.market.get("b", 0))),
			"l": maxi(int(market.get("l", 0)), int(other.market.get("l", 0)))})


## Owner #115 (S3): the shop from saved data, field by field ({} when nothing is left).
static func _clean_shop(v: Variant) -> Dictionary:
	if not v is Dictionary:
		return {}
	var src: Dictionary = v
	var out := {}
	if valid_id(src.get("s")):   # a sign shop.json doesn't know shows as none (SuccessShop.sign_text)
		out.s = src.s
	var ledger: Array = []
	var seen := {}
	if src.get("l") is Array:
		for e: Variant in src.l:
			if not e is Dictionary or _count((e as Dictionary).get("d")) <= 0 or seen.has(_count(e.d)):
				continue
			seen[_count(e.d)] = true
			ledger.append({"d": _count(e.d), "i": mini(_count(e.get("i")), SHOP_MAX_COINS),
				"o": mini(_count(e.get("o")), SHOP_MAX_COINS), "c": mini(_count(e.get("c")), SHOP_MAX_COINS),
				"k": mini(_count(e.get("k")), SHOP_MAX_COINS)})
	ledger.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.d) < int(b.d))
	if not ledger.is_empty():
		out.l = ledger.slice(maxi(ledger.size() - SHOP_MAX_DAYS, 0))
	var reviews: Array = []
	if src.get("r") is Array:
		for r: Variant in src.r:
			if r is Dictionary and valid_id((r as Dictionary).get("w")) and valid_id(r.get("k", "fresh")):
				reviews.append({"w": r.w, "s": clampi(_count(r.get("s", 5)), 1, 5), "k": str(r.get("k", "fresh"))})
	if not reviews.is_empty():
		out.r = reviews.slice(maxi(reviews.size() - SHOP_MAX_REVIEWS, 0))
	if src.get("g") is Dictionary and _count((src.g as Dictionary).get("d")) > 0:
		out.g = {"d": _count(src.g.d), "g": mini(_count(src.g.get("g")), SHOP_DAY_CAP)}
	if _count(src.get("t")) > 0:
		out.t = _count(src.t)
	return out


static func _clean_market(v: Variant) -> Dictionary:
	if not v is Dictionary:
		return {}
	var src: Dictionary = v
	var out := {}
	for k: String in ["t", "b", "l"]:
		if _count(src.get(k)) > 0:
			out[k] = _count(src[k])
	if src.get("x") is bool and src.x:
		out.x = true
	return out


func into_garden(h: String, n: int) -> void:
	if not valid_id(h) or n <= 0:
		return
	for plant in garden:
		if str(plant.h) == h:
			plant.n = maxi(int(plant.n), n)
			return
	if garden.size() >= MAX_GARDEN:
		garden.pop_front()
	garden.append({"h": h, "n": mini(n, MAX_COUNT)})


static func _clean_goal(v: Variant) -> Dictionary:
	if not v is Dictionary or not valid_id((v as Dictionary).get("d")):
		return {}
	var src: Dictionary = v
	var out := {}
	for k: String in GOAL_KEYS:
		if valid_id(src.get(k)):
			out[k] = src[k]
	var steps: Array = []
	var s: Variant = src.get("s")
	if s is Array:
		for id: Variant in s:
			if valid_id(id) and steps.size() < MAX_STEPS:
				steps.append(id)
	out.s = steps
	for k: String in GOAL_NUMBERS:
		out[k] = _count(src.get(k))
	return out


static func _clean_habit(v: Variant) -> Dictionary:
	if not v is Dictionary or not valid_id((v as Dictionary).get("h")):
		return {}
	var src: Dictionary = v
	var days: Array = []
	var k: Variant = src.get("k")
	if k is Array:
		for day: Variant in k:
			if typeof(day) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(day)) and int(day) > 0 and not days.has(int(day)):
				days.append(int(day))
	days.sort()
	var kept := days.size()
	days = days.slice(maxi(days.size() - MAX_DAYS, 0))
	return {"h": src.h, "c": _count(src.get("c")), "k": days, "n": maxi(_count(src.get("n")), kept),
		"l": _count(src.get("l")), "y": src.get("y") is bool and src.y}


static func _clean_plant(v: Variant) -> Dictionary:
	if not v is Dictionary or not valid_id((v as Dictionary).get("h")):
		return {}
	var n := _count((v as Dictionary).get("n"))
	return {"h": v.h, "n": n} if n > 0 else {}


static func _clean_person(p: Dictionary) -> Dictionary:
	var out := {}
	for k: String in PERSON_DEFAULTS:
		var v: Variant = p.get(k, PERSON_DEFAULTS[k])
		var clean: Variant
		if PERSON_DEFAULTS[k] is bool:
			clean = v is bool and v
		elif k == "w":
			clean = clampi(_count(v), 0, MAX_WARMTH)
		else:
			clean = _count(v)
		if clean != PERSON_DEFAULTS[k]:
			out[k] = clean
	return out


## A whole number 0..MAX_COUNT (anything else is 0).
static func _count(v: Variant) -> int:
	if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)):
		return clampi(int(v), 0, MAX_COUNT)
	return 0
