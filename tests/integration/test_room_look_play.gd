extends GutTest
## The rooms' look (2026-10-18, the lead's first priority on resuming; docs/devlog/parts/rooms-look.md): G0's play place
## (PlayArena), where every child plays the School's units (a crystal, DISCOVER), gets the practice rooms' shared look: a
## real floor (a meadow garden with a little patio under the table) under a soft sky, lit by its one warm sun (the play
## budget allows one light), its dressing merged per material, and the dressing never on a station's things, across the
## flat view's or the VR eye's line to them, or where the child stands, whichever station is built.

const SAMPLES := {
	"number base ten": {"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Parts."},
	"sort": {"type": "sort", "prompt": "Living or not?", "hint": "Does it grow?", "groups": ["living", "not living"],
		"items": ["a tree", "a rock", "a frog", "a cloud"], "answer": [0, 1, 0, 1]},
	"build": {"type": "build", "prompt": "Build 30 blocks.", "board": {"cols": 12, "rows": 10, "block": 9,
		"given": [[0, 0], [1, 0], [2, 0]]}, "goal": {"kind": "count", "n": 30}, "hint": "Count."},
	"robot": {"type": "robot", "prompt": "Reach the flag.", "hint": "Plan.", "board": {"cols": 8, "rows": 8,
		"start": [0, 0], "facing": "E", "goal": [7, 7], "walls": [[2, 0], [2, 1], [5, 5]]}},
	"choice path": {"type": "choice", "prompt": "Which is a mammal?", "choices": ["a shark", "a whale", "a trout", "an eel",
		"a cod"], "answer": 1, "hint": "It breathes air."},
	"truefalse": {"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": true, "hint": "Tens place."},
	"point": {"type": "point", "prompt": "Find (3, 4).", "grid": {"x_max": 12, "y_max": 12}, "answer": [3, 4], "hint": "Along."},
	"mix": {"type": "mix", "prompt": "Mix orange.", "hint": "Two primary colours.", "target": "orange"},
}
const COSTUMES := {"choice path": "path"}


func before_all() -> void:
	Profile.data.settings.reduce_motion = true


func after_all() -> void:
	Profile.data.settings.reduce_motion = false
	Audio.stop_all()


func _arena() -> PlayArena:
	var a := PlayArena.new()
	add_child_autofree(a)
	return a


func test_the_play_place_stands_on_a_real_floor_under_a_sky() -> void:
	var arena := _arena()
	var skies := arena.look_pieces.filter(func(p: Dictionary) -> bool: return str(p.kind) == LifeRoomDecor.SKY)
	assert_eq(skies.size(), 1, "a sky round the place")
	var feet := PlayArena.FEET
	var floors := arena.look_pieces.filter(func(p: Dictionary) -> bool:
		var b: AABB = p.box
		return str(p.kind) == LifeRoomDecor.SHELL and absf(b.end.y) < 0.12 and b.size.y < 0.6 \
			and feet.x > b.position.x and feet.x < b.end.x and feet.z > b.position.z and feet.z < b.end.z)
	assert_gt(floors.size(), 0, "a real floor where the child stands")
	assert_gt(arena.look_pieces.filter(func(p: Dictionary) -> bool: return str(p.kind) == LifeRoomDecor.DECOR).size(), 20,
		"a place round the table: trees, a fence, flowers")


func test_the_place_has_one_light_its_own_warm_sun() -> void:
	var arena := _arena()
	var lights := arena.find_children("*", "Light3D", true, false)
	assert_eq(lights.size(), 1, "the play budget's one light")
	assert_true(lights[0] is LifeRoomSun, "the place's own sun (the world's is put away while it shows)")


func test_the_dressing_keeps_clear_of_every_stations_things_lines_and_stand() -> void:
	for key: String in SAMPLES:
		var arena := _arena()
		var ex: Dictionary = JSON.parse_string(JSON.stringify(SAMPLES[key]))
		ex.picture = {"kind": "blocks", "hundreds": 3, "tens": 4, "ones": 7}   # and its board
		var st := arena.show_challenge(ex, 3, {"costume": COSTUMES[key]} if COSTUMES.has(key) else {})
		for pass_i in 2:
			var step := {"kind": "taps", "targets": arena.target_names()}
			for clash in LifeRoomLook.in_the_way(arena, step, PlayArena.VIEW):
				fail_test("%s: %s" % [key, clash])
			st.show_answer()   # every piece made, every thing placed
		arena.free()
	pass_test("checked")
