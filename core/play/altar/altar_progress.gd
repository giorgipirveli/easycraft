class_name AltarProgress
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.6's fade, §3.10's keeper's journal, §3.12, rulings 11, 19,
## 20, 30): the temple's state, kept on this device only in phase B (FILE, like PlayQuests: never in the profile or its
## backup; phase C moves it into the profile, merged so nothing is lost). It remembers the rooms lit (the board opens the
## next), each room's Glimmers freed (kept when the child stops for now: a freed Glimmer is never lost), the keeper's
## journal (each idea of §3.4 shown with or without help, in which rooms, and the misconceptions seen) and the fade's
## stage (the grade sets the start, `begin_stage`; three altars freed first time in a row move it on, two helped in a row
## move it back: `note_altar`). Nothing changes by itself: no clocks, no timers, no decay.

const FILE := "user://balance_altar.json"
const VERSION := 1
## The journal's ideas (§3.4): the twin rule, take, share, balloons, the reverse order.
const TWIN := "twin"
const TAKE := "take"
const SHARE := "share"
const BALLOONS := "balloons"
const ORDER := "order"
const _IDEAS_OF := {"add": [TWIN, TAKE], "mul": [TWIN, SHARE], "two": [TWIN, TAKE, SHARE, ORDER],
	"sub": [TWIN, BALLOONS], "subtwo": [TWIN, BALLOONS, SHARE, ORDER], "twin": [TWIN, TAKE, SHARE],
	"fixed": [TWIN]}
const UP_AFTER := 3
const DOWN_AFTER := 2

var path := FILE
var done: Array[String] = []
## {room id: [altar numbers whose Glimmers are free]}
var glimmers := {}
## {idea: {shown, helped, rooms: [ids], misses: {note: count}}}
var journal := {}
## The fade's stage (AltarRunes' stages; 0 until the grade sets it).
var stage := 0
## Altars in a row: + freed first time, - helped.
var in_a_row := 0


static func open_at(file: String = FILE) -> AltarProgress:
	var p := AltarProgress.new()
	p.path = file
	if not FileAccess.file_exists(file):
		return p
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file)) != OK or not json.data is Dictionary:
		return p
	var d: Dictionary = json.data
	for id: Variant in d.get("done", []):
		if not AltarHalls.room(str(id)).is_empty() and not p.done.has(str(id)):
			p.done.append(str(id))
	var saved: Variant = d.get("glimmers", {})
	if saved is Dictionary:
		for room: Variant in saved:
			var list: Array = []
			for n: Variant in (saved[room] if saved[room] is Array else []):
				list.append(int(n))
			p.glimmers[str(room)] = list
	var j: Variant = d.get("journal", {})
	if j is Dictionary:
		for idea: Variant in j:
			var e: Variant = j[idea]
			if e is Dictionary:
				p.journal[str(idea)] = {"shown": int(e.get("shown", 0)), "helped": int(e.get("helped", 0)),
					"rooms": (e.get("rooms", []) as Array).map(func(r: Variant) -> String: return str(r)),
					"misses": (e.get("misses", {}) as Dictionary).duplicate()}
	p.stage = clampi(int(d.get("stage", 0)), 0, AltarRunes.RUNES)
	p.in_a_row = int(d.get("in_a_row", 0))
	return p


## The fade's stage, set from the grade the first time (AltarHalls.start_stage); after that, the child's play moves it.
func begin_stage(grade: int) -> int:
	if stage == 0:
		stage = AltarHalls.start_stage(grade)
	return stage


## One judged altar's kind moves the fade: three freed first time in a row, the next stage; two helped in a row, back
## one (never below pictures, never past the runes). The stage after it.
func note_altar(kind: String) -> int:
	if stage == 0:
		stage = AltarRunes.PICTURES
	if SkillShown.COUNTS.has(kind):
		in_a_row = maxi(in_a_row, 0) + 1
		if in_a_row >= UP_AFTER:
			stage = mini(stage + 1, AltarRunes.RUNES)
			in_a_row = 0
	else:
		in_a_row = mini(in_a_row, 0) - 1
		if in_a_row <= -DOWN_AFTER:
			stage = maxi(stage - 1, AltarRunes.PICTURES)
			in_a_row = 0
	return stage


## A Glimmer freed (kept at once: stopping for now never loses it).
func free_glimmer(room_id: String, altar_n: int) -> void:
	var list: Array = glimmers.get(room_id, [])
	if not list.has(altar_n):
		list.append(altar_n)
		list.sort()
	glimmers[room_id] = list


func glimmers_freed(room_id: String) -> Array[int]:
	var out: Array[int] = []
	for n: Variant in glimmers.get(room_id, []):
		out.append(int(n))
	return out


## A room ended (not stopped): it is lit, and its judged altars ({form, kind, note}) go in the journal.
func finish(room_id: String, results: Array) -> void:
	if AltarHalls.room(room_id).is_empty():
		return
	if not done.has(room_id):
		done.append(room_id)
	for r: Dictionary in results:
		var form := str(r.get("form", "")).trim_suffix("_L").trim_suffix("_R")
		var counts := SkillShown.COUNTS.has(str(r.get("kind", "")))
		for idea: String in _IDEAS_OF.get(form, [TWIN]):
			var e: Dictionary = journal.get(idea, {"shown": 0, "helped": 0, "rooms": [], "misses": {}})
			if counts:
				e.shown = int(e.shown) + 1
				if not (e.rooms as Array).has(room_id):
					(e.rooms as Array).append(room_id)
			else:
				e.helped = int(e.helped) + 1
			for note: String in str(r.get("note", "")).split(", ", false):
				if [AltarMoves.ONE_PAN, AltarMoves.ACROSS, AltarMoves.UNFAIR, AltarMoves.NO_TWIN].has(note):
					e.misses[note] = int((e.misses as Dictionary).get(note, 0)) + 1
			journal[idea] = e


func lit(room_id: String) -> bool:
	return done.has(room_id)


## The board's open rooms, in order.
func open_rooms() -> Array[String]:
	var out: Array[String] = []
	for id in AltarHalls.ids():
		if AltarHalls.unlocked(id, done):
			out.append(id)
	return out


func shown(idea: String) -> int:
	return int((journal.get(idea, {}) as Dictionary).get("shown", 0))


func helped(idea: String) -> int:
	return int((journal.get(idea, {}) as Dictionary).get("helped", 0))


func rooms(idea: String) -> Array:
	return (journal.get(idea, {}) as Dictionary).get("rooms", [])


## The misconceptions seen while an idea was shown ({note: times}).
func misses(idea: String) -> Dictionary:
	return (journal.get(idea, {}) as Dictionary).get("misses", {})


func to_dict() -> Dictionary:
	return {"version": VERSION, "done": done, "glimmers": glimmers, "journal": journal, "stage": stage,
		"in_a_row": in_a_row}


func save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()
