extends Node
## The steps of tools/anim_shots.gd (owner #94): its header says what it shows and how to run it.

const SAMPLES: Array[Dictionary] = [
	{"kind": "water_cycle"},
	{"kind": "moon_phases", "names": true},
	{"kind": "moon_phases", "show": "row", "names": true},
	{"kind": "orbit", "planets": ["Mercury", "Venus", "Earth", "Mars"], "moon": true, "labels": true, "arrows": true},
	{"kind": "orbit", "centre": "earth", "arrows": true, "labels": true},
	{"kind": "pendulum", "lengths": [1, 3], "labels": true},
	{"kind": "pendulum", "energy": true, "labels": true},
	{"kind": "rocket_stages", "labels": true},
	{"kind": "gears", "gears": [10, 30, 20], "turn": "cw", "marks": true, "arrows": "all"},
	{"kind": "lever", "pivot": 5, "load": 1, "effort": 9},
	{"kind": "circuit", "parts": ["cell", "bulb", "switch", "motor"], "lit": true, "names": true},
	{"kind": "food_web", "nodes": [["grass", 0, 3], ["rabbit", 0, 2], ["fox", 1, 1], ["seeds", 2, 3], ["mouse", 2, 2],
		["owl", 2, 0]], "links": [[0, 1], [1, 2], [3, 4], [4, 2], [4, 5]]},
]
const TIMES: Array[float] = [0.0, 1.3, 3.1]
const CELL := Vector2(420, 240)

var _out := ""


func _ready() -> void:
	_out = OS.get_user_data_dir().path_join("anim_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	get_window().size = Vector2i(1280, 720)
	var bg := ColorRect.new()
	bg.color = Color("233047")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	await get_tree().process_frame
	var sheet := 0
	for start in range(0, SAMPLES.size(), 3):
		var pics: Array[SchoolPicture] = []
		for row in 3:
			var i := start + row
			if i >= SAMPLES.size():
				break
			for col in TIMES.size():
				var p := SchoolPicture.new(SAMPLES[i], CELL - Vector2(8, 8))
				p.position = Vector2(col * CELL.x + 4, row * CELL.y + 4)
				p.size = CELL - Vector2(8, 8)
				p.time = TIMES[col]
				add_child(p)
				pics.append(p)
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var path := _out.path_join("sheet_%d.png" % sheet)
		image.save_png(path)
		print("ANIM_SHOT %s" % path)
		for p in pics:
			p.queue_free()
		sheet += 1
	get_tree().quit()
