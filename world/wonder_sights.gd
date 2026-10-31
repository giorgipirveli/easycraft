class_name WonderSights
extends SpaceSights
## The wonders as sights (owner #78, spec §24), the space worlds' pattern (SpaceSights) on Earth: a few times a second
## it looks where this game's player stands; walking up to a wonder, into it or onto it (its zone: the wonder's blocks
## and a few steps round them, WonderBuilds) the first time in this world says its real fact (the descriptor's
## `sights`, WonderFacts), with a sparkle, and tells the WondersDirector (sight_found: the passport's stamp, the guide's
## next place). Found wonders are kept in the world's secrets as "sight:<id>" like a planet's sights; every wonder is
## on MY MAP from the landing.

const ZONE_MARGIN := 3            # blocks round a wonder that count as reaching it
const ZONE_BELOW := 3

## {id: [lo, hi exclusive]}: where each wonder counts as reached (zones()).
var zones := {}


## Every wonder's zone: its blocks' bounds, a few steps wider, from under its floor to over its top.
static func zones_of_tour() -> Dictionary:
	var out := {}
	for id: StringName in WonderTour.ids():
		var b := WonderBuilds.bounds(id)
		if b.is_empty():
			continue
		var lo: Vector3i = b[0]
		var hi: Vector3i = b[1]
		out[id] = [Vector3i(lo.x - ZONE_MARGIN, mini(lo.y, WonderTour.BASE_Y) - ZONE_BELOW - 8, lo.z - ZONE_MARGIN),
			Vector3i(hi.x + ZONE_MARGIN, hi.y + ZONE_MARGIN, hi.z + ZONE_MARGIN)]
	return out


## Where each wonder is on MY MAP and for the guide: [{id, pos}] (its centre at the tour's ground).
static func spots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: StringName in WonderTour.ids():
		out.append({"id": id, "pos": WonderTour.centre(id)})
	return out


## Puts every wonder on MY MAP (its name).
func setup() -> void:
	if zones.is_empty():
		zones = zones_of_tour()
	for s: Dictionary in spots():
		_mark(s.id, s.pos)


## One look where the player stands.
func tick() -> void:
	if not player_position.is_valid():
		return
	var at: Vector3 = player_position.call()
	if not at.is_finite():
		return
	var feet := Vector3i(at.floor())
	for id: StringName in zones:
		if found.has(PREFIX + String(id)) or not sights.has(id):
			continue
		var z: Array = zones[id]
		var lo: Vector3i = z[0]
		var hi: Vector3i = z[1]
		if feet.x < lo.x or feet.y < lo.y or feet.z < lo.z or feet.x >= hi.x or feet.y >= hi.y or feet.z >= hi.z:
			continue
		found[PREFIX + String(id)] = true
		if toast.is_valid():
			toast.call(tr(str(sights[id].words)))
		Audio.play(&"sparkle")
		if is_inside_tree():
			Fx.burst(get_tree().root, at + Vector3(0, 1.0, 0), Color("ffd23f"), 24, 3.0)
		sight_found.emit(id)
		return
