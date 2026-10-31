extends Node
## tools/room_shots.gd's steps (a Node, so it may use the autoloads and the rooms' classes): its header says what it
## does and how to run it.

const WORLD_SCENE := "res://world/world.tscn"
## Frames waited after a room opens (its first view is instant) and frames whose draws are read.
const SETTLE := 8
const MEASURE := 6

var _only: Array[String] = []
var _tracks: Array[String] = ["little", "middle", "big"]
var _tag := "now"
var _vr := false
var _style := "blocky"
var _shots := true
var _sun := true
var _out := ""
var _parent: Node
var _rows: Array[String] = []
## --play: G0's play place (PlayArena) with a few stations instead of the Experiences' rooms.
var _play := false
const PLAY_SAMPLES := {
	"make": {"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Parts.",
		"picture": {"kind": "blocks", "hundreds": 3, "tens": 4, "ones": 7}},
	"sort": {"type": "sort", "prompt": "Living or not?", "hint": "Does it grow?", "groups": ["living", "not living"],
		"items": ["a tree", "a rock", "a frog", "a cloud"], "answer": [0, 1, 0, 1]},
	"path": {"type": "choice", "prompt": "Which is a mammal?", "choices": ["a shark", "a whale", "a trout", "an eel"],
		"answer": 1, "hint": "It breathes air."},
	"build": {"type": "build", "prompt": "Build 2 rows of 3.", "board": {"cols": 6, "rows": 3, "block": 9, "given": []},
		"goal": {"kind": "array", "rows": 2, "cols": 3}, "hint": "A row of 3 first."},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_only.assign(a.trim_prefix("--only=").split(",", false))
		elif a.begins_with("--tracks="):
			_tracks.assign(a.trim_prefix("--tracks=").split(",", false))
		elif a.begins_with("--tag="):
			_tag = a.trim_prefix("--tag=")
		elif a == "--vr":
			_vr = true
		elif a.begins_with("--style="):
			_style = a.trim_prefix("--style=")
		elif a == "--no-shots":
			_shots = false
		elif a == "--no-sun":
			_sun = false
		elif a == "--play":
			_play = true
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	Profile.data.settings.reduce_motion = true   # every view at once
	BlockLibrary.set_style(_style)
	if _sun:
		_add_menu_sun()
	if _vr and not _play:   # the play place's VR view is its own camera at the child's eye (the preview's would take over)
		PlatformRules.simulated = PlatformRules.detect()
		for tag: String in [PlatformRules.MOBILE, PlatformRules.ANDROID, PlatformRules.QUEST]:
			PlatformRules.simulated[tag] = true
		await get_tree().process_frame
		Vr.preview(true)
	_out = "%s/room_shots/%s/%s/%s" % [OS.get_environment("XDG_DATA_HOME"), _tag, "vr" if _vr else "flat", _style]
	DirAccess.make_dir_recursive_absolute(_out)
	print("ROOM_SHOT dir %s renderer=%s" % [_out, RenderingServer.get_current_rendering_method()])
	_parent = Node.new()
	_parent.name = "RoomShots"
	add_child(_parent)
	if _play:
		await _play_place()
		get_tree().quit()
		return
	for id: String in LifeExperience.IDS:
		if not _only.is_empty() and not _only.has(id):
			continue
		for track: String in _tracks:
			await _room(id, track)
	print("ROOM_SHOT table (%s, %s, %s)" % [_tag, "vr" if _vr else "flat", _style])
	for r in _rows:
		print(r)
	if _vr:
		Vr.preview(false)
	get_tree().quit()


## The menu world's sun (world/world.tscn's, as the rooms see it over the title screen's world).
func _add_menu_sun() -> void:
	var w: Node = (load(WORLD_SCENE) as PackedScene).instantiate()
	var sun := w.get_node_or_null("Sun") as DirectionalLight3D
	if sun != null:
		w.remove_child(sun)
		sun.owner = null
		sun.shadow_enabled = false
		add_child(sun)
	w.free()


func _room(id: String, track: String) -> void:
	var host := LifeRoomHost.new()
	host.setup(id, track, false, 1, "ge")
	host.open(_parent)
	for i in SETTLE:
		await get_tree().process_frame
	var key := "%s.%s" % [id, track]
	if not _vr:
		var m := await _measure()
		if _shots:
			await _shot(key)
		_line(key, "flat", m, host)
	else:
		var most := {}
		for turn in 4:
			if turn > 0:
				Vr.turn(PI * 0.5)
				for i in 3:
					await get_tree().process_frame
			var m := await _measure()
			if turn == 0 and _shots:
				await _shot(key)
			if most.is_empty() or int(m.draws_3d) + int(m.draws_2d) > int(most.draws_3d) + int(most.draws_2d):
				most = m
		_line(key, "vr", most, host)
	host.close()
	for i in 3:
		await get_tree().process_frame


func _line(key: String, mode: String, m: Dictionary, host: LifeRoomHost) -> void:
	var meshes := host.room.find_children("*", "GeometryInstance3D", true, false).size() if host.room else 0
	var line := "ROOM_SHOT %s mode=%s draws_3d=%d draws_2d=%d primitives=%d objects=%d nodes3d=%d" % [key, mode,
		int(m.draws_3d), int(m.draws_2d), int(m.primitives), int(m.objects), meshes]
	print(line)
	_rows.append(line)


## The most draws of MEASURE frames (the scene's and the canvases'), and the primitives and objects of that frame.
func _measure() -> Dictionary:
	var out := {"draws_3d": 0, "draws_2d": 0, "primitives": 0, "objects": 0}
	for i in MEASURE:
		await RenderingServer.frame_post_draw
		var viewports: Array = [get_tree().root]
		viewports.append_array(get_tree().root.find_children("*", "SubViewport", true, false))
		var split := VrBench.draw_split(viewports)
		if int(split.draws_3d) >= int(out.draws_3d):
			out.draws_3d = int(split.draws_3d)
			out.draws_2d = int(split.draws_2d)
			out.primitives = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
			out.objects = int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	return out


func _shot(key: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var path := "%s/%s.jpg" % [_out, key]
	image.save_jpg(path, 0.88)


## G0's play place: each sample's station from its own view (flat: the station's camera; VR: the child's eye at the
## place's stand looking ahead), no HUD.
func _play_place() -> void:
	var cam := Camera3D.new()
	cam.fov = 100.0 if _vr else 72.0
	cam.near = 0.05
	cam.far = 80.0
	add_child(cam)
	for key: String in PLAY_SAMPLES:
		var arena := PlayArena.new()
		_parent.add_child(arena)
		cam.environment = arena.env
		var params := {"costume": "path"} if key == "path" else {}
		arena.show_challenge((PLAY_SAMPLES[key] as Dictionary).duplicate(true), 3, params)
		cam.global_transform = arena.vr_stand(PlayArena.VIEW) if _vr else arena.camera_transform(PlayArena.VIEW)
		cam.make_current()
		for i in SETTLE:
			await get_tree().process_frame
		var m := await _measure()
		if _shots:
			await _shot("play." + key)
		var line := "ROOM_SHOT play.%s mode=%s draws_3d=%d primitives=%d" % [key, "vr" if _vr else "flat", int(m.draws_3d),
			int(m.primitives)]
		print(line)
		_rows.append(line)
		arena.queue_free()
		for i in 3:
			await get_tree().process_frame
