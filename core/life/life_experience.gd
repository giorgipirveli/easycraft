class_name LifeExperience
extends RefCounted
## Owner #112, #113 (docs/design/life-skills.md §3, §5; spec §27): the Experiences as data,
## data/life/experiences/<id>.json: {id, title, area, room (the practice room's kind, LifeRooms), vary ("money": the
## stall's values, LifeMoney), tracks: {little, middle, big: {skill (its Passport page's name), twist (the Expert try in
## words), can_now ("your child can now..."), steps [LifeCheck data + id, view (the flat camera's view), react (a room
## event when the step starts), after (a room event when it is done), goes (the view a step moves the child to when
## done), stand (outside: GET LOW lets go), reach (hand / head / any), mode
## (normal / expert / both)], check [3-5 picture questions], name_it {title, lines, source}, try_real, sources [{fact,
## source, url}]}}}.
## Owner #117 (§13 of the design): `devices` {id: {controls, shows, order, safety}} (the device model: a step names one
## with `device`); a step's `motion` and `tool` (LifeCheck's header).
## Words may hold {tokens}: the region's {number}, {number_words} and {number_keys} (LifeRegion), and the stall's values
## (LifeMoney.stall_vars). A value that is only a token ("{change}", "{number_keys}") becomes the value itself. Choices
## are written right-first and shown in a seeded order. Files are read once and kept.

## Life L3a (owner #118, design §14): `emergency` true (an emergency Experience: the calm debrief after it), a step's
## `danger` (its moment's room time slows on the first tries: LifeRun.time_scale), `within` / `late`, `not` and
## `safe_mistake` (LifeCheck's header; a safe mistake never on the Little track), an action step's `button` (its big
## button's words), and the tokens {intensity} (the grown-up's GENTLE or REAL, Big only) and {quake_where} (the region's
## own words on earthquakes, LifeRegion.quake_words).
## Life L3c (owner #112, #118): the tokens {metro_where} and {bins_where} (LifeRegion.metro_words, .bins_words).

const DIR := "res://data/life/experiences"
const IDS: Array[String] = ["little_lifesaver", "fire_escape", "money_stall", "safe_streets", "kitchen", "calm_corner",
	"real_builder",   # owner #116: Real Builder (round 4b; its data in data/tools)
	"water_safety", "poisons_cupboard", "earth_weather",   # owner #118: Life L3a, dangerous things learned safely
	"electricity", "animals", "medical",   # owner #118: Life L3b, the dangers wave's second part
	"online_city", "find_way", "home_helper",   # owner #112, #118: Life L3c, the third wave's last part
	"goal_board", "talk_deal", "connections", "success_stories",   # owner #115: Success S2 (SuccessExperiences.IDS)
	"my_shop", "market_square"]   # owner #115 (S3): My Business's shop, the Market Square
const PRACTICE_NOTE := "This is practice. A real first aid course teaches more."
const MIN_STEPS := 5
const TOKEN := "\\{([a-z_]+)\\}"

static var _cache := {}
static var _token := RegEx.create_from_string(TOKEN)


static func data(id: String) -> Dictionary:
	if not _cache.has(id):
		var path := RealBuilder.PATH if id == RealBuilder.ID else "%s/%s.json" % [DIR, id]   # owner #116
		if SuccessExperiences.is_success(id):
			path = SuccessExperiences.path(id)   # owner #115: Success S2's data (data/success/experiences)
		var text := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
		var json := JSON.new()
		_cache[id] = json.data if text != "" and json.parse(text) == OK and json.data is Dictionary else {}
	return _cache[id]


static func clear_cache() -> void:
	_cache.clear()


static func title(id: String) -> String:
	return str(data(id).get("title", id))


static func track_data(id: String, track: String) -> Dictionary:
	var tracks: Variant = data(id).get("tracks")
	return (tracks as Dictionary).get(track, {}) if tracks is Dictionary else {}


## The Passport's skill: an Experience on a track.
static func skill_id(id: String, track: String) -> String:
	return "%s.%s" % [id, track]


## [experience, track] of a skill id ([] for a bad one).
static func of_skill(skill: String) -> Array[String]:
	var parts := skill.split(".")
	if parts.size() != 2 or not IDS.has(parts[0]) or not LifeData.valid_track(parts[1]):
		return []
	return [parts[0], parts[1]]


## Life L3a: an emergency Experience (Little Lifesaver, Fire Escape, the dangerous things): the calm debrief after it.
static func emergency(id: String) -> bool:
	return bool(data(id).get("emergency", false))


static func vars(id: String, track: String, seed: int, region: String, intensity: String = LifeData.GENTLE) -> Dictionary:
	var n := LifeRegion.number(region)
	var v := {"number": n, "number_words": LifeRegion.spoken(n), "number_keys": LifeRegion.keys(n),
		"region_name": LifeRegion.region_name(region), "seed": seed,
		"intensity": intensity if LifeData.INTENSITIES.has(intensity) else LifeData.GENTLE,   # Life L3a (owner #118)
		"quake_where": LifeRegion.quake_words(region),
		"wild_where": LifeRegion.wild_words(region),   # Life L3b (owner #118): Safe with Animals' wild animals
		"metro_where": LifeRegion.metro_words(region),   # Life L3c: Find Your Way's metro (Tbilisi's two lines)
		"bins_where": LifeRegion.bins_words(region)}   # Life L3c: Home Helper's recycling bins
	# Life L2, Safe Streets: the kerb drill and the practice street's sign follow the region (the grown-ups' page)
	var sides := LifeRegion.look_sides(region)
	var limit := LifeRegion.speed_limit(region)
	v.merge({"look_order": LifeRegion.look_order(region), "look_sides": sides, "first_side": sides[0],
		"then_side": sides[1], "drive": LifeRegion.drive(region), "speed_unit": LifeRegion.speed_unit(region),
		"speed_limit": limit, "speed_hi": limit, "speed_lo": limit - (7 if limit == 20 else 10), "speed_top": limit * 2})
	match str(data(id).get("vary", "")):
		"money":
			v.merge(LifeMoney.stall_vars(track, seed))
		"kitchen":
			v.merge(LifeKitchen.vars(track, seed))
		"success":   # owner #115: Success S2's words that vary (SuccessExperiences.vars)
			v.merge(SuccessExperiences.vars(id, track, seed))
	return v


## A run's steps: the track's steps for this try (normal or Expert), every token filled, choices in the seed's order.
static func steps(id: String, track: String, expert: bool, seed: int, region: String) -> Array[Dictionary]:
	var v := vars(id, track, seed, region)
	var out: Array[Dictionary] = []
	for s: Variant in track_data(id, track).get("steps", []):
		if not s is Dictionary:
			continue
		var mode := str((s as Dictionary).get("mode", ""))
		if (mode == "expert" and not expert) or (mode == "normal" and expert):
			continue
		var step: Dictionary = resolve(s, v)
		out.append(_mixed(step, seed))
	return out


## The before-and-after picture check: choose questions, filled, in the seed's order.
static func check(id: String, track: String, region: String, seed: int = 0) -> Array[Dictionary]:
	var v := vars(id, track, seed, region)
	var out: Array[Dictionary] = []
	var i := 0
	for q: Variant in track_data(id, track).get("check", []):
		if q is Dictionary:
			var step: Dictionary = resolve(q, v)
			step.kind = "choose"
			step.id = "check_%d" % i
			out.append(_mixed(step, seed))
		i += 1
	return out


## The Experience's devices, filled for the region: {id: {controls, shows, order, safety}} ({} when it has none).
static func devices(id: String, region: String) -> Dictionary:
	var d: Variant = data(id).get("devices", {})
	return resolve(d, vars(id, "little", 0, region)) if d is Dictionary else {}


## The "name it" card, filled: {title, lines, source}.
static func card(id: String, track: String, region: String) -> Dictionary:
	return resolve(track_data(id, track).get("name_it", {}), vars(id, track, 0, region))


## One of a track's sentences (try_real, can_now, twist, skill), filled.
static func words(id: String, track: String, key: String, region: String, seed: int = 0) -> String:
	return fill(str(track_data(id, track).get(key, "")), vars(id, track, seed, region))


static func fill(text: String, v: Dictionary) -> String:
	var out := text
	for m in _token.search_all(text):
		var key := m.get_string(1)
		if v.has(key):
			out = out.replace(m.get_string(), str(v[key]))
	return out


## Every string filled; a string that is one whole token becomes that value (an int, an Array).
static func resolve(value: Variant, v: Dictionary) -> Variant:
	if value is String:
		var m := _token.search(value)
		if m != null and m.get_string() == value and v.has(m.get_string(1)):
			var whole: Variant = v[m.get_string(1)]
			return whole.duplicate() if whole is Array else whole
		return fill(value, v)
	if value is Array:
		var a := []
		for x: Variant in value:
			a.append(resolve(x, v))
		return a
	if value is Dictionary:
		var d := {}
		for k: Variant in value:
			d[k] = resolve(value[k], v)
		return d
	return value


## A choice step's choices in a seeded order (the files write the right one first: a child must never learn "the first
## button"); the answer follows its choice.
static func _mixed(step: Dictionary, seed: int) -> Dictionary:
	var choices: Variant = step.get("choices")
	if not choices is Array or (choices as Array).size() < 2 or typeof(step.get("answer")) not in [TYPE_INT, TYPE_FLOAT]:
		return step
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, str(step.get("id", "")), str(step.get("say", ""))])
	var order: Array = range((choices as Array).size())
	GenKit.shuffle(rng, order)
	var mixed: Array = []
	for i: int in order:
		mixed.append(choices[i])
	step.choices = mixed
	step.answer = order.find(int(step.answer))
	return step


## What is wrong with an Experience's data ([] when nothing): every track's words, cards, check and sources, and its
## steps for several seeds in every region, on both tries; every run ends with words (a good ending).
static func problems(id: String) -> Array[String]:
	var out: Array[String] = []
	var d := data(id)
	if d.is_empty():
		return ["%s: no file or a broken one" % id]
	for key: String in ["title", "area", "room"]:
		if str(d.get(key, "")) == "":
			out.append("%s has no %s" % [id, key])
	var devs := devices(id, LifeRegion.DEFAULT)
	for dev: Variant in devs:
		for key: String in ["controls", "shows", "order", "safety"]:
			var list: Variant = (devs[dev] as Dictionary).get(key) if devs[dev] is Dictionary else null
			if not list is Array or (list as Array).is_empty():
				out.append("%s: the device %s needs its %s" % [id, dev, key])
	for track in LifeData.TRACKS:
		var t := track_data(id, track)
		var where := "%s.%s" % [id, track]
		if t.is_empty():
			out.append(where + " is missing")
			continue
		for key: String in ["skill", "twist", "can_now", "try_real"]:
			if str(t.get(key, "")).strip_edges() == "":
				out.append("%s has no %s" % [where, key])
		var card_data: Variant = t.get("name_it")
		if not card_data is Dictionary or str((card_data as Dictionary).get("title", "")) == "" \
				or str((card_data as Dictionary).get("source", "")) == "" \
				or not (card_data as Dictionary).get("lines") is Array \
				or ((card_data as Dictionary).lines as Array).size() < 3 or ((card_data as Dictionary).lines as Array).size() > 5:
			out.append(where + ": its name-it card needs a title, 3-5 lines and its source")
		var sources: Variant = t.get("sources")
		if not sources is Array or (sources as Array).size() < 2:
			out.append(where + " needs two sources or more")
		else:
			for s: Variant in sources:
				if not s is Dictionary or not str((s as Dictionary).get("url", "")).begins_with("https://") \
						or str((s as Dictionary).get("fact", "")) == "":
					out.append("%s: a source without its fact or url: %s" % [where, s])
		var questions := check(id, track, LifeRegion.DEFAULT)
		if questions.size() < 3 or questions.size() > 5:
			out.append(where + " needs 3-5 check questions")
		for q in questions:
			var why := LifeCheck.problem(q)
			if why != "":
				out.append("%s check: %s" % [where, why])
		for region in LifeRegion.ids():
			for expert: bool in [false, true]:
				for seed in 6:
					var list := steps(id, track, expert, seed, region)
					if list.size() < MIN_STEPS:
						out.append("%s: only %d steps" % [where, list.size()])
						continue
					if str(list.back().get("kind", "")) != "info":
						out.append(where + ": a run ends with kind words (an info step)")
					for step in list:
						var why := LifeCheck.problem(step)
						if why != "":
							out.append("%s %s: %s" % [where, step.get("id", "?"), why])
						if str(step.get("id", "")) == "":
							out.append(where + ": a step without an id")
						if step.has("device") and not devs.has(str(step.device)):
							out.append("%s %s: no device %s" % [where, step.get("id", "?"), step.device])
						if step.has("safe_mistake") and track == "little":   # owner #118: the coach guides before
							out.append("%s %s: on the Little track the coach guides before any mistake" % [where,
								step.get("id", "?")])
						for key: String in ["say", "done", "miss"]:
							if str(step.get(key, "")).contains("{"):
								out.append("%s %s: a token left in %s" % [where, step.get("id", "?"), key])
	var seen := {}
	for p in out:
		seen[p] = true
	var unique: Array[String] = []
	for p: String in seen:
		unique.append(p)
	return unique
