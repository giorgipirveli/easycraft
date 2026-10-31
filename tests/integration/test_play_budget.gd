extends GutTest
## Owner #122 (G0; DEVELOPMENT.md §7: the phones' and the Quest's budget): the play arena stays as small as Life's rooms.
## With the heaviest exercise each station meets in the School (the biggest boards, the most things, every piece of a
## build made), the place draws at most MAX_DRAWS things (a mesh or a 3D label: one draw each; the Quest's budget is
## about 100 a frame), draws no shadows, has at most one light, and its pictures' canvases draw once (only a moving
## picture redraws).

const MAX_DRAWS := 100

const HEAVY := {
	"base ten 9,999": {"type": "number", "prompt": "Make 9,999.", "answer": "9999", "hint": "Thousands first."},
	"fraction 11/4": {"type": "number", "prompt": "11 quarters = ?", "answer": "11/4", "hint": "Quarters."},
	"scale 999 g": {"type": "number", "prompt": "How many g?", "answer": "999", "hint": "Weights."},
	"coins 4,999 gold": {"type": "number", "prompt": "How much gold?", "answer": "4999", "hint": "Coins."},
	"build 12 by 10": {"type": "build", "prompt": "Build 30 blocks.", "board": {"cols": 12, "rows": 10, "block": 9,
		"given": [[0, 0], [1, 0], [2, 0]]}, "goal": {"kind": "count", "n": 30}, "hint": "Count."},
	"robot 8 by 8": {"type": "robot", "prompt": "Reach the flag.", "hint": "Plan.", "board": {"cols": 8, "rows": 8,
		"start": [0, 0], "facing": "E", "goal": [7, 7], "walls": [[2, 0], [2, 1], [2, 2], [5, 5], [5, 6], [4, 3],
		[6, 2]], "gems": [[1, 1], [6, 6]]}},
	"sort 6 in 3": {"type": "sort", "prompt": "Sort them.", "hint": "Look.", "groups": ["solid", "liquid", "gas"],
		"items": ["ice cube", "water", "steam", "a rock", "milk", "air"], "answer": [0, 1, 2, 0, 1, 2]},
	"order 6": {"type": "order", "prompt": "Oldest first.", "hint": "Dates.", "items": ["1066", "1215", "1492", "1588",
		"1666", "1805"], "answer": [0, 1, 2, 3, 5, 4]},
	"match 5": {"type": "match", "prompt": "Match.", "hint": "Pairs.", "items": ["cat", "dog", "cow", "sheep", "horse"],
		"matches": ["puppy", "calf", "kitten", "lamb", "foal"], "answer": [2, 0, 1, 3, 4]},
	"label 5": {"type": "label", "prompt": "Label it.", "hint": "Look.", "picture": {"kind": "blocks", "hundreds": 1},
		"spots": [[0.1, 0.1], [0.3, 0.5], [0.5, 0.9], [0.7, 0.5], [0.9, 0.1]], "labels": ["a", "b", "c", "d", "e"],
		"answer": [1, 0, 2, 4, 3]},
	"point 12 by 12": {"type": "point", "prompt": "Find (3, 4).", "grid": {"x_max": 12, "y_max": 12,
		"points": [{"x": 1, "y": 1, "label": "A"}, {"x": 5, "y": 7, "label": "B"}]}, "answer": [3, 4], "hint": "Along, up."},
	"rhythm 8": {"type": "rhythm", "prompt": "Copy it.", "hint": "Listen.", "sound": {"kind": "rhythm", "pattern": "x-xxx-xx"}},
	"mix": {"type": "mix", "prompt": "Mix brown.", "hint": "All three.", "target": "brown"},
	"choice 5 pictures": {"type": "choice", "prompt": "Which?", "hint": "Look.", "answer": 0, "choices": [
		{"picture": {"kind": "blocks", "tens": 1}}, {"picture": {"kind": "blocks", "tens": 2}},
		{"picture": {"kind": "blocks", "tens": 3}}, {"picture": {"kind": "blocks", "tens": 4}},
		{"picture": {"kind": "blocks", "tens": 5}}]},
	"truefalse": {"type": "truefalse", "prompt": "True?", "answer": true, "hint": "Think."},
	"dial": {"type": "number", "prompt": "Write it.", "answer": "-2/97", "hint": "Out of 97."},
}

var arena: PlayArena


func before_all() -> void:
	Profile.data.settings.reduce_motion = true


func after_all() -> void:
	Profile.data.settings.reduce_motion = false


func _draws(root: Node) -> int:
	var n := 0
	for g: Node in root.find_children("*", "GeometryInstance3D", true, false):
		if (g as GeometryInstance3D).is_visible_in_tree() and g.get_viewport() == root.get_viewport():
			n += 1
	return n


func test_every_station_at_its_heaviest_stays_within_the_budget() -> void:
	for key: String in HEAVY:
		var ex: Dictionary = HEAVY[key].duplicate(true)
		assert_eq(ExerciseCheck.problem(ex), "", key)
		arena = PlayArena.new()
		add_child_autofree(arena)
		var ex_with_picture := ex.duplicate(true)
		if not ex_with_picture.has("picture"):
			ex_with_picture.picture = {"kind": "blocks", "hundreds": 3, "tens": 4, "ones": 7}   # and a board
		var st := arena.show_challenge(ex_with_picture, 3, {"costume": "give"})
		st.show_answer()   # every piece made, every thing placed
		var n := _draws(arena)
		gut.p("PLAY_BUDGET %s: %d draws" % [key, n])
		assert_lte(n, MAX_DRAWS, "%s draws %d" % [key, n])
		var lights := arena.find_children("*", "Light3D", true, false)
		assert_lte(lights.size(), 1, "%s: one light" % key)
		for c: Node in arena.find_children("*", "SubViewport", true, false):
			var moving := (c as SubViewport).render_target_update_mode == SubViewport.UPDATE_ALWAYS
			assert_false(moving, "%s: a still picture draws once" % key)
		arena.free()
