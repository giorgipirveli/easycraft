class_name LabModels
extends RefCounted
## Spec §23.3: makes an experiment's scene model from its data (LabModel's kinds) and checks the data (the content test).
## Scene data by kind:
## - tank {things: [{thing, name, floats}]}: float or sink; 2-8 things of THINGS, both kinds among them.
## - magnet {things: [{thing, name, magnetic}]}: the same, magnetic or not.
## - heat {start, low, step, melt, boil}: whole °C; low ≤ start ≤ melt < boil; the steps land on melt and on boil.
## - colours {paints, lights, paint_goals, light_goals}: paints of ColourMix.PAINTS, lights of LabColours.LIGHTS, goals
##   the mixes they make (a recipe of two or more of the paints; a light mix of two or more of the lights).
## - plants {days, pots: [{name, light, water}]}: 1-7 days, 2-4 pots.
## - circuit {wires, bulbs}: 1-4 wires to take out, 1-2 bulbs.

const KINDS: Array[String] = ["tank", "magnet", "heat", "colours", "plants", "circuit"]
## The things the Lab can draw (LabThings) and drop, hold to a magnet, …
const THINGS: Array[String] = ["wood", "stone", "ice", "iron", "leaf", "gold", "sponge", "glass", "clip", "copper", "tin"]
const MIN_THINGS := 2
const MAX_THINGS := 8
const MAX_NAME := 16   # a thing's or a pot's name fits its card


## The scene's model (null for a kind the Lab doesn't know). `now` (unix seconds) is the plants' clock.
static func make(scene: Dictionary, now: Callable = Callable()) -> LabModel:
	match str(scene.get("kind", "")):
		"tank":
			return LabTank.new(scene)
		"magnet":
			return LabMagnet.new(scene)
		"heat":
			return LabHeat.new(scene)
		"colours":
			return LabColours.new(scene)
		"plants":
			return LabPlants.new(scene, now)
		"circuit":
			return LabCircuit.new(scene)
	return null


## "" when the scene can be made and drawn; otherwise what is wrong.
static func problem(scene: Variant) -> String:
	if not scene is Dictionary:
		return "a scene is a dictionary"
	var s: Dictionary = scene
	var kind := str(s.get("kind", ""))
	match kind:
		"tank":
			return _things_problem(s, "floats")
		"magnet":
			return _things_problem(s, "magnetic")
		"heat":
			for k: String in ["start", "low", "step", "melt", "boil"]:
				if not _is_int(s.get(k)):
					return "heat: %s must be a whole number of degrees" % k
			var start := int(s.start)
			var step := int(s.step)
			if not (int(s.low) <= start and start <= int(s.melt) and int(s.melt) < int(s.boil)) or step <= 0:
				return "heat: low ≤ start ≤ melt < boil, and a step above 0"
			if (int(s.melt) - start) % step != 0 or (int(s.boil) - int(s.melt)) % step != 0:
				return "heat: the steps must land on the melting and the boiling points"
		"colours":
			var paints: Array = s.get("paints", [])
			var lights: Array = s.get("lights", [])
			if paints.size() < 2 or lights.size() < 2:
				return "colours: two or more paints and lights"
			for p: Variant in paints:
				if not ColourMix.PAINTS.has(str(p)):
					return "colours: %s is not a paint" % p
			for l: Variant in lights:
				if not LabColours.LIGHTS.has(str(l)):
					return "colours: %s is not a light" % l
			for g: Variant in s.get("paint_goals", []):
				var recipe: Dictionary = ColourMix.RECIPES.get(str(g), {})
				if recipe.size() < 2 or recipe.keys().any(func(k: Variant) -> bool: return not paints.has(k)):
					return "colours: the paints can't mix %s" % g
			for g: Variant in s.get("light_goals", []):
				if not _light_reachable(str(g), lights):
					return "colours: the lights can't make %s" % g
		"plants":
			var days: Variant = s.get("days")
			if not _is_int(days) or int(days) < 1 or int(days) > 7:
				return "plants: 1-7 days"
			var pots: Variant = s.get("pots")
			if not pots is Array or (pots as Array).size() < 2 or (pots as Array).size() > 4:
				return "plants: 2-4 pots"
			for p: Variant in pots:
				if not p is Dictionary or not (p as Dictionary).get("light") is bool or not (p as Dictionary).get("water") is bool:
					return "plants: every pot has light and water, true or false"
				if not _name_ok(p.get("name")):
					return "plants: a pot's name is 1-%d letters" % MAX_NAME
		"circuit":
			if not _is_int(s.get("wires")) or int(s.wires) < 1 or int(s.wires) > 4:
				return "circuit: 1-4 wires"
			if not _is_int(s.get("bulbs")) or int(s.bulbs) < 1 or int(s.bulbs) > 2:
				return "circuit: 1-2 bulbs"
		_:
			return "unknown scene kind '%s'" % kind
	return ""


static func _things_problem(s: Dictionary, flag: String) -> String:
	var things: Variant = s.get("things")
	if not things is Array or (things as Array).size() < MIN_THINGS or (things as Array).size() > MAX_THINGS:
		return "%s: %d-%d things" % [s.kind, MIN_THINGS, MAX_THINGS]
	var names := {}
	var kinds := {}
	for t: Variant in things:
		if not t is Dictionary:
			return "%s: a thing is a dictionary" % s.kind
		var d: Dictionary = t
		if not THINGS.has(str(d.get("thing", ""))):
			return "%s: the Lab can't draw '%s'" % [s.kind, d.get("thing", "")]
		if not _name_ok(d.get("name")) or names.has(str(d.name).to_lower()):
			return "%s: every thing has its own name of 1-%d letters" % [s.kind, MAX_NAME]
		names[str(d.name).to_lower()] = true
		if not d.get(flag) is bool:
			return "%s: %s must say %s, true or false" % [s.kind, d.name, flag]
		kinds[d[flag]] = true
	if kinds.size() < 2:
		return "%s: some things of each kind" % s.kind
	return ""


static func _light_reachable(goal: String, lights: Array) -> bool:
	var n := lights.size()
	for mask in range(1, 1 << n):
		var on: Array = []
		for i in n:
			if mask & (1 << i):
				on.append(lights[i])
		if on.size() >= 2 and LabColours.light_name(on) == goal:
			return true
	return false


static func _name_ok(v: Variant) -> bool:
	return v is String and str(v).strip_edges() != "" and str(v).length() <= MAX_NAME


static func _is_int(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and float(v) == floorf(float(v))
