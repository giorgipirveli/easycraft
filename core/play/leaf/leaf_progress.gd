class_name LeafProgress
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.10, §3.12, rulings 12, 19, 32): the garden of voyage plants,
## kept on this device only in phase B (FILE, like PlayQuests: never in the profile or its backup; phase C moves it into
## the profile, merged so growth is never lost). It remembers which voyages are done (the board opens the next), each
## plant's state (the sunflower droops until its voyage, then stands in bloom; its scale gains GROWTH gold blocks a
## voyage while the soil's stays: the plant got heavier, the soil didn't), the bud's fill kept when a child stops for now
## (never less plant), and the leaf journal: each idea shown, with or without help, and where (the next voyage reads it;
## phase C's grown-ups' page shows it). Nothing changes by itself: no clocks, no timers, no wilting while away.

const FILE := "user://leaf_voyage.json"
const VERSION := 1
const DROOP := "droop"
const STAND := "stand"
const BLOOM := "bloom"
## The scales by the pot: the plant's gold blocks before its first voyage, and the soil's brown ones (never change).
const START_BLOCKS := 6
const SOIL_BLOCKS := 6
## Gold blocks a finished voyage adds to its plant's scale.
const GROWTH := 2
## The journal's ideas (§3.4): the doors let air in (opened when it is cool), and they let water out (shut in the heat).
const AIR_IN := "air_in"
const WATER_OUT := "water_out"
const _IDEA_OF := {"cloud": AIR_IN, "night": AIR_IN, "blaze": WATER_OUT, "day": WATER_OUT, "dawn": WATER_OUT,
	"act1": WATER_OUT}

var path := FILE
var done: Array[String] = []
## {plant: {stage, blocks, bud (0-1)}}
var plants := {}
## {idea: {shown, helped, settings: [where]}}
var journal := {}


static func open_at(file: String = FILE) -> LeafProgress:
	var g := LeafProgress.new()
	g.path = file
	g.plants = {"sunflower": _new_plant()}
	if not FileAccess.file_exists(file):
		return g
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file)) != OK or not json.data is Dictionary:
		return g
	var d: Dictionary = json.data
	for id: Variant in d.get("done", []):
		if LeafVoyages.voyage(str(id)).size() > 0 and not g.done.has(str(id)):
			g.done.append(str(id))
	var saved_plants: Variant = d.get("plants", {})
	if saved_plants is Dictionary:
		for name: Variant in saved_plants:
			var p: Variant = saved_plants[name]
			if p is Dictionary:
				g.plants[str(name)] = {"stage": str(p.get("stage", DROOP)), "blocks": int(p.get("blocks", START_BLOCKS)),
					"bud": clampf(float(p.get("bud", 0.0)), 0.0, 1.0)}
	var saved_journal: Variant = d.get("journal", {})
	if saved_journal is Dictionary:
		for idea: Variant in saved_journal:
			var j: Variant = saved_journal[idea]
			if j is Dictionary:
				g.journal[str(idea)] = {"shown": int(j.get("shown", 0)), "helped": int(j.get("helped", 0)),
					"settings": (j.get("settings", []) as Array).map(func(s: Variant) -> String: return str(s))}
	return g


static func _new_plant() -> Dictionary:
	return {"stage": DROOP, "blocks": START_BLOCKS, "bud": 0.0}


## A voyage ended (not stopped): it is done, its plant blooms and gains GROWTH gold blocks, its beats go in the journal.
func finish(voyage_id: String, beat_results: Array) -> void:
	var v := LeafVoyages.voyage(voyage_id)
	if v.is_empty():
		return
	if not done.has(voyage_id):
		done.append(voyage_id)
	var name := str(v.get("plant", ""))
	var p := plant(name)
	p.stage = BLOOM
	p.blocks = int(p.blocks) + GROWTH
	p.bud = 1.0
	plants[name] = p
	var setting := str(v.get("setting", "")) if bool(v.get("transfer", false)) else ""
	for r: Dictionary in beat_results:
		var idea := str(_IDEA_OF.get(str(r.get("rule", "")), ""))
		if idea == "":
			continue
		var j: Dictionary = journal.get(idea, {"shown": 0, "helped": 0, "settings": []})
		if SkillShown.COUNTS.has(str(r.get("kind", ""))):
			j.shown = int(j.shown) + 1
			if setting != "" and not (j.settings as Array).has(setting):
				(j.settings as Array).append(setting)
		else:
			j.helped = int(j.helped) + 1
		journal[idea] = j


## Stopped for now: nothing recorded, but the plant keeps what the child did (the bud's fill, 0-1), never less.
func keep(voyage_id: String, bud_fill: float) -> void:
	var name := str(LeafVoyages.voyage(voyage_id).get("plant", ""))
	if name == "":
		return
	var p := plant(name)
	p.bud = maxf(float(p.bud), clampf(bud_fill, 0.0, 1.0))
	plants[name] = p


## A plant's state ({stage, blocks, bud}); a new one droops.
func plant(name: String) -> Dictionary:
	return (plants.get(name, _new_plant()) as Dictionary).duplicate()


func has_plant(name: String) -> bool:
	return plants.has(name)


func soil_blocks(_plant_name: String) -> int:
	return SOIL_BLOCKS


## The board's open voyages, in order.
func open_voyages() -> Array[String]:
	var out: Array[String] = []
	for id in LeafVoyages.ids():
		if LeafVoyages.unlocked(id, done):
			out.append(id)
	return out


func shown(idea: String) -> int:
	return int((journal.get(idea, {}) as Dictionary).get("shown", 0))


func helped(idea: String) -> int:
	return int((journal.get(idea, {}) as Dictionary).get("helped", 0))


func settings(idea: String) -> Array:
	return (journal.get(idea, {}) as Dictionary).get("settings", [])


func to_dict() -> Dictionary:
	return {"version": VERSION, "done": done, "plants": plants, "journal": journal}


func save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()
