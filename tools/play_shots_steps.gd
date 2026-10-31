extends Node
## The steps of tools/play_shots.gd (a Node, so it may use the autoloads and the game's classes).

const SAMPLES := {
	"make_tower": {"type": "number", "prompt": "How many cubes are in the picture?", "answer": "12", "hint": "Count.",
		"picture": {"kind": "blocks", "tens": 1, "ones": 2}},
	"make_base_ten": {"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Parts."},
	"make_decimal": {"type": "number", "prompt": "3 + 0.75 = ?", "answer": "3.75", "hint": "Tenths."},
	"make_coins": {"type": "number", "prompt": "Tilly pays 65 gold from 100 gold. How much change?", "answer": "35",
		"hint": "Count up."},
	"make_jug": {"type": "number", "prompt": "How many ml are left in the jug?", "answer": "750", "hint": "Take away."},
	"make_scale": {"type": "number", "prompt": "How many g does the cake weigh?", "answer": "450", "hint": "Add."},
	"make_fraction": {"type": "number", "prompt": "1/2 + 1/4 = ?", "answer": "3/4", "hint": "Quarters."},
	"make_frog": {"type": "number", "prompt": "5 - 17 = ?", "answer": "-12", "hint": "Below zero."},
	"make_dial": {"type": "number", "prompt": "Write 2 out of 97 as a fraction.", "answer": "2/97", "hint": "Out of 97."},
	"sort": {"type": "sort", "prompt": "Living or not living?", "hint": "Does it grow?", "groups": ["living", "not living"],
		"items": ["a tall oak tree", "a rock", "a frog", "a cloud", "a mushroom", "a river"], "answer": [0, 1, 0, 1, 0, 1]},
	"sort_long": {"type": "sort", "prompt": "Which of these happened before the year 1000, and which after?", "hint": "Dates.",
		"groups": ["before 1000", "after 1000"], "items": ["The Romans build Hadrian's Wall in Britain",
		"The first printed books with movable type", "Vikings sail to North America", "Columbus crosses the Atlantic",
		"The Great Pyramid at Giza is finished", "People first walk on the Moon"], "answer": [0, 1, 0, 1, 0, 1]},
	"order": {"type": "order", "prompt": "Put them smallest first.", "hint": "Hundreds.", "items": ["4,210", "4,021", "4,201",
		"4,012"], "answer": [3, 1, 2, 0]},
	"match": {"type": "match", "prompt": "Match each animal with its young.", "hint": "A baby cat?",
		"items": ["cat", "dog", "cow", "sheep"], "matches": ["puppy", "calf", "kitten", "lamb"], "answer": [2, 0, 1, 3]},
	"label": {"type": "label", "prompt": "Label the blocks.", "hint": "Top first.", "picture": {"kind": "blocks", "tens": 1,
		"ones": 3}, "spots": [[0.2, 0.2], [0.8, 0.8]], "labels": ["a ten", "ones"], "answer": [1, 0]},
	"build": {"type": "build", "prompt": "Build 2 rows of 3.", "board": {"cols": 6, "rows": 3, "block": 9, "given": []},
		"goal": {"kind": "array", "rows": 2, "cols": 3}, "hint": "A row of 3 first."},
	"robot": {"type": "robot", "prompt": "Write the steps that take the robot to the flag.", "hint": "Which way does it face?",
		"board": {"cols": 4, "rows": 3, "start": [0, 1], "facing": "N", "goal": [3, 1], "walls": [[2, 0]], "gems": [[1, 1]]}},
	"rhythm": {"type": "rhythm", "prompt": "Listen, then copy the rhythm.", "hint": "Listen again.",
		"sound": {"kind": "rhythm", "pattern": "x-x-xx--", "tempo": 90}},
	"mix": {"type": "mix", "prompt": "Mix orange paint.", "hint": "Two primary colours.", "target": "orange"},
	"point": {"type": "point", "prompt": "Find the point (2, 5).", "grid": {"x_max": 6, "y_max": 6}, "answer": [2, 5],
		"hint": "2 along, then 5 up."},
	"choice_give": {"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325", "30,205"],
		"answer": 0, "hint": "No hundreds."},
	"choice_path": {"type": "choice", "prompt": "Which animal is a mammal?", "choices": ["a shark", "a whale", "a trout"],
		"answer": 1, "hint": "It breathes air."},
	"choice_pictures": {"type": "choice", "prompt": "Which shows 13?", "choices": [{"picture": {"kind": "blocks", "tens": 1,
		"ones": 3}}, {"picture": {"kind": "blocks", "tens": 3, "ones": 1}}], "answer": 0, "hint": "One ten."},
	"truefalse": {"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": true, "hint": "Tens place."},
}
const COSTUMES := {"choice_give": "give", "choice_path": "path", "choice_pictures": "give"}

var _out := ""
var _layer: CanvasLayer
var _holder: Control


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var only: Array = []
	var unit := ""
	for a in args:
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		if a.begins_with("--unit="):
			unit = a.trim_prefix("--unit=")
	get_window().size = Vector2i(1600, 720) if args.has("--wide") else Vector2i(1280, 720)
	_out = ProjectSettings.globalize_path("user://play_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	_layer = CanvasLayer.new()
	add_child(_layer)
	_holder = Control.new()
	_layer.add_child(_holder)
	if unit != "":
		await _unit(unit)
		get_tree().quit()
		return
	for key: String in SAMPLES:
		if not only.is_empty() and not only.has(key):
			continue
		var ex: Dictionary = SAMPLES[key].duplicate(true)
		var content := {"id": "g4.maths.shots", "lesson": [{"text": "A digit's place tells what it is worth."}],
			"exercises": [ex]}
		if COSTUMES.has(key):
			content.play = {"params": {"costume": COSTUMES[key]}}
		var host := PlayHost.new()
		host.setup("g4.maths.shots", content, 5, 0, {"title": "Shots"})
		host.open(_holder)
		await _wait(0.4)
		host.end_hook()
		await _wait(0.6)
		await _save(key)
		host.station().show_answer()
		host.station().react(PlayLoop.RIGHT)
		await _wait(0.9)
		await _save(key + "_answer")
		host.close()
		await _wait(0.2)
	get_tree().quit()


func _unit(id: String) -> void:
	var host := PlayHost.new()
	host.setup(id, Curriculum.content(id), 5, 0, Curriculum.unit(id))
	host.open(_holder)
	await _wait(0.5)
	await _save("unit_hook")
	host.end_hook()
	for i in host.loop.total():
		await _wait(0.6)
		await _save("unit_%d_%s" % [i + 1, host.station().mechanic])
		host.station().show_answer()
		host.check()
		await _wait(0.4)
		await _save("unit_%d_answered" % (i + 1))
		host.next()
		await _wait(0.2)
		if host.loop.phase == PlayLoop.WHY:
			await _save("unit_why")
			host.play_on()
		if host.closed:
			break


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _save(shot: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _out.path_join(shot + ".png")
	image.save_png(path)
	print("PLAY_SHOT %s %dx%d" % [path, image.get_width(), image.get_height()])
