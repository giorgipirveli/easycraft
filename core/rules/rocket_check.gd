class_name RocketCheck
extends RefCounted
## The check, like real rockets (spec §21d.3; owner #78: "all things must be educational in the game, close to real
## world"). Pure: it reads the parts standing on a Launch Site's pad (cells relative to the pad's corner, y up: the
## build square is PAD × PAD) and says, in words a child follows and in numbers:
## - the rocket: the biggest piece of rocket parts standing on the pad (touching side to side);
## - its stages: read bottom to top, a layer holding a stage separator ends a stage (the bottom stage fires first, then
##   drops away with its separator);
## - lift-off: the first stage's push against the whole rocket's weight, with a margin (LIFT_MARGIN);
## - how far the fuel takes you: the rocket equation per stage, Δv = Isp × g₀ × ln(full ÷ empty), each stage carrying
##   the full stages above it; the sum against the mission's need (MissionRules);
## - the crew, on the last stage: a seat each, air and water for the trip, landing legs, power, a heat shield and a
##   parachute where there is air (a heat shield alone where a thin air is only skimmed: Triton), an engine to land with;
##   fins on the first stage and a pointed top;
## - in the Sandbox, the parts bought (`owned`): building is free, a launch needs every part paid for.
## Every miss says why and what real rockets do. The numbers of each part are RocketParts'.

const PAD := 9               # the build square: x and z from 0 to 8
const MAX_HEIGHT := 64       # layers read above the pad
const LIFT_MARGIN := 1.1     # the first stage pushes a tenth more than the rocket weighs, so it climbs
const UPPER_MARGIN := 0.5    # an upper stage pushes at least half of what it carries
const LEGS_NEEDED := 3
const FINS_NEEDED := 3

const _SIDES: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1)]


## A cell of the build square (and not too high).
static func in_square(p: Vector3i) -> bool:
	return p.x >= 0 and p.z >= 0 and p.x < PAD and p.z < PAD and p.y >= 0 and p.y < MAX_HEIGHT


## The rocket: the biggest piece of parts ({Vector3i: id}) standing on the pad (some part at y 0). Other blocks, parts
## off the square and parts that don't touch the piece stay where they are.
static func find_rocket(cells: Dictionary) -> Dictionary:
	var parts := {}
	var starts: Array[Vector3i] = []
	for p: Vector3i in cells:
		if in_square(p) and RocketParts.is_part(int(cells[p])):
			parts[p] = int(cells[p])
			if p.y == 0:
				starts.append(p)
	starts.sort()
	var seen := {}
	var best := {}
	for s in starts:
		if seen.has(s):
			continue
		var piece := {}
		var queue: Array[Vector3i] = [s]
		seen[s] = true
		while not queue.is_empty():
			var p: Vector3i = queue.pop_back()
			piece[p] = parts[p]
			for d in _SIDES:
				var q := p + d
				if parts.has(q) and not seen.has(q):
					seen[q] = true
					queue.append(q)
		if piece.size() > best.size():
			best = piece
	return best


## The rocket's cells in stages, bottom first: a layer with a stage separator ends its stage.
static func stages_of(rocket: Dictionary) -> Array:
	var top := -1
	var layers := {}
	for p: Vector3i in rocket:
		if not layers.has(p.y):
			layers[p.y] = []
		(layers[p.y] as Array).append(p)
		top = maxi(top, p.y)
	var out: Array = []
	var current: Array[Vector3i] = []
	for y in range(0, top + 1):
		var layer: Array = layers.get(y, [])
		layer.sort()
		var ends := false
		for p: Vector3i in layer:
			current.append(p)
			ends = ends or int(rocket[p]) == BlockIds.STAGE_SEPARATOR
		if ends:
			out.append(current)
			current = []
	if not current.is_empty():
		out.append(current)
	return out


## The whole check of the parts in `cells` for `mission` (MissionRules) with `crew` astronauts; `owned` ({id: count},
## the Sandbox's bought parts) or null (Survivor: the bag paid). Returns {ok, empty, cells (the rocket), stages
## ([{cells, parts, full, empty, fuel, push, isp, engines, blocked, space_first, carries, dv}], bottom first), mass,
## push, dv, need, seats, kept (astronauts the service modules keep for the whole trip, owner #98), missing ({id: count}
## to buy), lines ([{key, ok, text, why}], in the board's order)}.
static func check(cells: Dictionary, mission: Dictionary, crew: int = 1, owned: Variant = null) -> Dictionary:
	var rocket := find_rocket(cells)
	var out := {"ok": false, "empty": rocket.is_empty(), "cells": rocket, "stages": [], "mass": 0.0, "push": 0.0,
		"dv": 0.0, "need": MissionRules.need(mission), "seats": 0, "kept": 0, "missing": {}, "lines": []}
	if rocket.is_empty():
		out.lines = [_line(&"empty", false, "Build a rocket on the pad: engines at the bottom, fuel tanks, a crew capsule on top.",
			"Every part you place on the pad's square counts. Buy parts at the Mission Board.")]
		return out
	var stages := _stages(rocket)
	out.stages = stages
	var dv := 0.0
	for st: Dictionary in stages:
		dv += float(st.dv)
	out.mass = float(stages[0].full) + float(stages[0].carries)
	out.push = float(stages[0].push)
	out.dv = dv
	var last: Dictionary = stages[stages.size() - 1]
	out.seats = _n(last, BlockIds.CREW_CAPSULE) * RocketParts.seats(BlockIds.CREW_CAPSULE)
	out.kept = _n(last, BlockIds.SERVICE_MODULE) * RocketParts.keeps(BlockIds.SERVICE_MODULE)   # owner #98
	var lines: Array[Dictionary] = []
	_engine_lines(stages, float(out.mass), lines)
	_speed_line(mission, dv, float(out.need), lines)
	_crew_lines(stages, rocket, mission, maxi(crew, 1), int(out.seats), int(out.kept), lines)
	if owned is Dictionary:
		out.missing = RocketParts.missing(RocketParts.count(rocket), owned)
		lines.append(_paid_line(out.missing))
	out.lines = lines
	var ok := true
	for l in lines:
		ok = ok and bool(l.ok)
	out.ok = ok
	return out


## The rocket the flight gets (spec §21d.4; the flight's brief): {destination, cells ({Vector3i relative to the pad's
## corner, y up: id}), stages ([[Vector3i, …]], bottom stage first), seats}.
static func description(result: Dictionary, destination: int) -> Dictionary:
	var stages: Array = []
	for st: Dictionary in result.get("stages", []):
		stages.append((st.cells as Array).duplicate())
	return {"destination": destination, "cells": (result.get("cells", {}) as Dictionary).duplicate(), "stages": stages,
		"seats": int(result.get("seats", 0))}


static func _stages(rocket: Dictionary) -> Array:
	var groups := stages_of(rocket)
	var stages: Array = []
	for i in groups.size():
		var own := {}
		for p: Vector3i in groups[i]:
			own[p] = true
		var st := {"cells": groups[i], "parts": {}, "full": 0.0, "empty": 0.0, "fuel": 0.0, "push": 0.0, "isp": 0.0,
			"engines": 0, "blocked": 0, "space_first": 0, "carries": 0.0, "dv": 0.0}
		var flow := 0.0
		for p: Vector3i in groups[i]:
			var id := int(rocket[p])
			st.parts[id] = int(st.parts.get(id, 0)) + 1
			st.full += RocketParts.mass_full(id)
			st.empty += RocketParts.mass_empty(id)
			st.fuel += RocketParts.fuel(id)
			if not RocketParts.is_engine(id):
				continue
			if own.has(p + Vector3i.DOWN):
				st.blocked += 1   # its bell points into its own stage
			elif i == 0 and RocketParts.space_only(id):
				st.space_first += 1
			else:
				st.engines += 1
				st.push += RocketParts.push(id)
				flow += RocketParts.push(id) / RocketParts.isp(id)
		st.isp = st.push / flow if flow > 0.0 else 0.0
		stages.append(st)
	var above := 0.0
	for i in range(stages.size() - 1, -1, -1):
		var st: Dictionary = stages[i]
		st.carries = above
		if float(st.push) > 0.0 and float(st.fuel) > 0.0:
			st.dv = float(st.isp) * RocketParts.G0 * log((float(st.full) + above) / (float(st.empty) + above)) / 1000.0
		above += float(st.full)
	return stages


static func _engine_lines(stages: Array, mass: float, lines: Array[Dictionary]) -> void:
	var first: Dictionary = stages[0]
	var push := float(first.push)
	if push >= mass * LIFT_MARGIN:
		lines.append(_line(&"liftoff", true, "Lift-off! Your engines push %s tonnes; your rocket weighs %s." % [_t(push), _t(mass)],
			"A rocket rises when its engines push harder than it weighs. Real ones push a tenth to a half more."))
	elif push <= 0.0:
		lines.append(_line(&"liftoff", false, "Nothing lifts it: put rocket engines at the bottom, on the pad.",
			"Engines go at the bottom, bells pointing down: hot gas rushes down and the rocket goes up."))
	else:
		lines.append(_line(&"liftoff", false, ("Too heavy: your engines push %s tonnes; your rocket weighs %s (it needs %s to "
			+ "climb). Add an engine or take off a tank.") % [_t(push), _t(mass), _t(mass * LIFT_MARGIN)],
			"That is why big rockets have many engines side by side: the first stage lifts everything."))
	var space_first := int(first.space_first)
	if space_first > 0:
		lines.append(_line(&"space_engine", false, "Space engines can't lift off: their huge bells are made for space. Use "
			+ "rocket engines in stage 1.", "Near the ground the thick air spoils a huge bell's push: real rockets use them "
			+ "on upper stages only."))
	var blocked := 0
	for st: Dictionary in stages:
		blocked += int(st.blocked)
	if blocked > 0:
		lines.append(_line(&"blocked", false, "%s pointing into the rocket: an engine needs room for its flame. Put engines "
			% _count(blocked, "engine is", "engines are") + "at the bottom of their stage.",
			"An engine pushes hot gas out of its bell: with a tank in the way it pushes nothing."))
	for i in stages.size():
		var st: Dictionary = stages[i]
		if int(st.engines) > 0 and float(st.fuel) <= 0.0:
			lines.append(_line(&"no_fuel", false, "Stage %d has engines but no fuel tank." % (i + 1),
				"An engine burns the fuel in the tanks of its own stage."))
		elif int(st.engines) == 0 and float(st.fuel) > 0.0 and i > 0:
			lines.append(_line(&"no_engine", false, ("Stage %d has fuel but no engine to burn it: put an engine under its "
				+ "tanks.") % (i + 1), "Each stage has its own engines: when one is empty it drops away and the next fires."))
	for i in range(1, stages.size()):
		var st: Dictionary = stages[i]
		var carries := float(st.full) + float(st.carries)
		if int(st.engines) > 0 and float(st.push) < carries * UPPER_MARGIN:
			lines.append(_line(&"upper_push", false, ("Stage %d is too weak: its engines push %s tonnes but it carries %s "
				+ "(it needs %s). Add an engine.") % [i + 1, _t(float(st.push)), _t(carries), _t(carries * UPPER_MARGIN)],
				"High up a stage still pushes at least half of what it carries, or gravity pulls it back while it climbs."))


static func _speed_line(mission: Dictionary, dv: float, need: float, lines: Array[Dictionary]) -> void:
	var place := _capital(str(mission.get("place", "Space")))
	if dv >= need:
		lines.append(_line(&"speed", true, "Your fuel takes you %.1f km/s. %s needs %.1f: enough!" % [dv, place, need],
			"Speed changes add up: to Earth orbit, then on, then braking to land."))
	else:
		lines.append(_line(&"speed", false, ("Your fuel takes you %.1f km/s; %s needs %.1f. Add a stage: a stage separator, "
			+ "then space engines and fuel tanks on it.") % [dv, place, need], "Real rockets drop their empty stages: the "
			+ "rest is lighter and goes faster (the rocket equation). That is why they have two or three stages."))


static func _crew_lines(stages: Array, rocket: Dictionary, mission: Dictionary, crew: int, seats: int, kept: int,
		lines: Array[Dictionary]) -> void:
	var last: Dictionary = stages[stages.size() - 1]
	var place := str(mission.get("place", "space"))
	if seats >= crew:
		lines.append(_line(&"seats", true, "A seat for each astronaut: %d." % seats, "The capsule carries the people, on top."))
	else:
		var lower := 0
		for i in stages.size() - 1:
			if _n(stages[i], BlockIds.CREW_CAPSULE) > 0:
				lower = i + 1
				break
		var text := "No seat: put a crew capsule on the top stage."
		if lower > 0:
			text = "The capsule is in stage %d, which falls away: put it on the top stage." % lower
		elif seats > 0:
			text = "%d astronauts need %d seats: you have %d. Add a crew capsule." % [crew, crew, seats]
		lines.append(_line(&"seats", false, text, "The capsule is the only part that carries people; it rides on top."))
	# Owner #98: a service module keeps one astronaut for the whole trip, however long (it cleans and reuses air and water
	# like the space station and grows a little food); the line still says the real trip.
	var why_supplies := "Each astronaut needs about 5 kg of air, water and food a day. A service module cleans and reuses " \
		+ "air and water, like the space station, and grows a little food."
	if kept >= crew:
		lines.append(_line(&"supplies", true, "Air, water and food for the whole trip (%s): a service module for each "
			% str(mission.get("trip", "")) + ("astronaut." if crew > 1 else "the astronaut."), why_supplies))
	else:
		var have := "you have none" if kept == 0 else ("you have 1" if kept == 1 else "you have %d" % kept)
		var who := "1 astronaut needs 1 service module" if crew == 1 else "%d astronauts need %d service modules" % [crew, crew]
		lines.append(_line(&"supplies", false, "Air and water for the trip (%s): %s on the top stage; %s." % [
			str(mission.get("trip", "")), who, have], why_supplies))
	if bool(mission.get("air", false)):
		if _n(last, BlockIds.HEAT_SHIELD) > 0:
			lines.append(_line(&"heat_shield", true, "A heat shield for %s's air." % place, "It keeps the lander cool."))
		else:
			lines.append(_line(&"heat_shield", false, "%s has air: coming down through it you need a heat shield." % _capital(place),
				"Air rushing past at thousands of km an hour makes a lander glow hot: the shield keeps it cool."))
		if _n(last, BlockIds.PARACHUTE_PACK) > 0:
			lines.append(_line(&"parachute", true, "A parachute for %s's air." % place, "It slows the lander down."))
		else:
			lines.append(_line(&"parachute", false, "Add a parachute pack: %s's air can slow you down." % place,
				"Landers on Mars and Titan opened parachutes, then landed softly."))
	elif bool(mission.get("skim", false)):   # cosmos: Triton's thin air is skimmed to slow down, far too thin to land with
		if _n(last, BlockIds.HEAT_SHIELD) > 0:
			lines.append(_line(&"heat_shield", true, "A heat shield to skim %s's thin air." % place,
				"Skimming through the air slows the rocket, so it stays."))
		else:
			lines.append(_line(&"heat_shield", false, "To stay at %s, skim its thin air: add a heat shield to the top stage."
				% place, "Real heat shields can even blow up like a big balloon, to be large and light."))
	var legs := _n(last, BlockIds.LANDING_LEGS)
	if legs >= LEGS_NEEDED:
		lines.append(_line(&"legs", true, "%d landing legs: it stands steady." % legs, "Three legs stand steady, like a stool."))
	else:
		lines.append(_line(&"legs", false, "Landing legs: you have %d on the top stage; a lander needs %d." % [legs, LEGS_NEEDED],
			"Three legs stand steady on bumpy ground, like a stool."))
	if _n(last, BlockIds.SOLAR_ARRAY) > 0:
		lines.append(_line(&"power", true, "A solar array for power.", "Sunlight becomes electricity for the crew."))
	else:
		lines.append(_line(&"power", false, "No power: add a solar array to the top stage.",
			"The crew needs electricity for lights, radio and air pumps."))
	var fins := _n(stages[0], BlockIds.ROCKET_FINS)
	if fins >= FINS_NEEDED:
		lines.append(_line(&"fins", true, "%d fins keep it flying straight." % fins, "Like the feathers on an arrow."))
	else:
		lines.append(_line(&"fins", false, "Fins: put %d on the first stage (you have %d)." % [FINS_NEEDED, fins],
			"Fins keep a rocket flying straight, like an arrow's feathers (big rockets also steer by tilting engines)."))
	if _pointed(rocket):
		lines.append(_line(&"top", true, "A pointed top: air slides round it.", "A nose cone or the capsule's cone."))
	else:
		lines.append(_line(&"top", false, "Its top is flat: put a nose cone (or the capsule) at the very top.",
			"Air pushes hard on a flat top; a cone lets it slide round."))
	if int(last.engines) > 0 and float(last.fuel) > 0.0:
		lines.append(_line(&"lander", true, "The top stage has an engine and fuel to brake and land.",
			"Landers fire their own engines to come down softly."))
	else:
		lines.append(_line(&"lander", false, "The top stage needs an engine and a fuel tank to brake and land.",
			"Landers on the Moon and Mars fired their own engines to come down softly."))


static func _paid_line(missing: Dictionary) -> Dictionary:
	if missing.is_empty():
		return _line(&"paid", true, "Every part is paid for.", "Rocket parts are bought with the gold you earn by learning.")
	return _line(&"paid", false, "Buy the parts you don't have yet: %s (%d gold)." % [RocketParts.list_words(missing),
		RocketParts.cost(missing)], "In the Sandbox building is free; rocket parts are bought with the gold you earn.")


## The top layer is only nose cones and capsules (a cone's point).
static func _pointed(rocket: Dictionary) -> bool:
	var top := -1
	for p: Vector3i in rocket:
		top = maxi(top, p.y)
	for p: Vector3i in rocket:
		if p.y == top and not int(rocket[p]) in [BlockIds.NOSE_CONE, BlockIds.CREW_CAPSULE]:
			return false
	return top >= 0


static func _n(stage: Dictionary, id: int) -> int:
	return int((stage.parts as Dictionary).get(id, 0))


static func _line(key: StringName, ok: bool, text: String, why: String) -> Dictionary:
	return {"key": key, "ok": ok, "text": text, "why": why}


static func _count(n: int, one: String, many: String) -> String:
	return "1 %s" % one if n == 1 else "%d %s" % [n, many]


static func _capital(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s


## Tonnes for a child: whole numbers with thousands' commas (1,558), a half when there is one (116.5).
static func _t(x: float) -> String:
	var whole := int(floor(x + 0.0001))
	var frac := x - whole
	var digits := str(absi(whole))
	var grouped := ""
	while digits.length() > 3:
		grouped = "," + digits.substr(digits.length() - 3) + grouped
		digits = digits.substr(0, digits.length() - 3)
	grouped = digits + grouped
	if whole < 0:
		grouped = "-" + grouped
	if frac >= 0.05:
		grouped += ".%d" % int(round(frac * 10.0))
	return grouped
