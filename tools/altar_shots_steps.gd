extends Node
## The steps of tools/altar_shots.gd (a Node, so it may use the autoloads and the game's classes). Each shot builds its
## place far from everything, sets the moment, lets it settle, and saves what the camera sees. The child in the wide
## pictures is a picture prop for scale (B2's host brings the real avatar).

const SHOTS := ["arrival", "arrival_door", "hall", "altar", "altar_close", "freed", "great", "up", "sky", "sky_wide"]

var _out := ""
var _cam: Camera3D
var _stage: Node3D


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var only: Array = []
	for a in args:
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	get_window().size = Vector2i(1600, 720) if args.has("--wide") else Vector2i(1280, 720)
	_out = ProjectSettings.globalize_path("user://altar_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	for shot: String in SHOTS:
		if not only.is_empty() and not only.has(shot):
			continue
		await call(shot)
	get_tree().quit()


# --- The shots -----------------------------------------------------------------------------------------------------

func arrival() -> void:
	var a := TempleArrival.new()
	_open(a)
	_child(a, Vector3(0.4, -5.4, 30.6), PI)
	await _look(a.camera_transform("foot"), 0.6)
	await _save("arrival")
	await _close()


func arrival_door() -> void:
	var a := TempleArrival.new()
	_open(a)
	a.set_door_open(true)
	_child(a, Vector3(0.3, 1.0, 14.6), PI)
	await _look(a.camera_transform("door"), 0.6)
	await _save("arrival_door")
	await _close()


func hall() -> void:
	var h := TempleHall.new()
	_open(h)
	h.set_active(2, "bird")
	h.set_freed([0, 1])
	h.set_lit(2)
	h.show_altar(AltarState.make(1, 3, 0, 7, 4))
	h.show_hoot(true)
	await _look(h.camera_transform("wide"), 0.6)
	await _save("hall")
	await _close()


func altar() -> void:
	var h := TempleHall.new()
	_open(h)
	h.set_active(2, "bird")
	h.set_freed([0, 1])
	h.set_lit(2)
	h.show_altar(AltarState.make(1, 3, 0, 7, 4), {"pan": 0, "verb": "lift", "kind": "gem", "count": 1, "twins": 0})
	h.show_hoot(true)
	await _look(h.camera_transform(AltarRoom.ALTAR_VIEW), 0.6)
	await _save("altar")
	await _close()


func altar_close() -> void:
	var h := TempleHall.new()
	_open(h)
	h.set_active(5, "cat")
	h.set_freed([0, 1, 2, 3, 4])
	h.altar.stage = AltarRunes.NUMBERS
	h.show_altar(AltarState.make(3, 0, 0, 12, 4))
	var at := h.altar.global_transform
	var eye := at * Vector3(-0.32, 0.98, 0.62)
	var look := at * Vector3(-0.3, 0.66, -0.02)
	await _look(Transform3D(Basis.looking_at(look - eye, Vector3.UP), eye), 0.6)
	await _save("altar_close")
	await _close()


func freed() -> void:
	var h := TempleHall.new()
	_open(h)
	h.set_active(0, "fox")
	h.set_lit(1)
	h.show_altar(AltarState.make(1, 0, 0, 3, 3), {}, true)
	h.show_hoot(true)
	await _look(h.camera_transform(AltarRoom.ALTAR_VIEW), 0.6)
	await _save("freed")
	await _close()


func great() -> void:
	var h := TempleHall.new()
	_open(h)
	h.set_freed([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
	h.set_lit(10)
	h.raise_great(1.0)
	h.altar.stage = AltarRunes.NUMBERS
	h.show_altar(AltarState.make(2, 1, 0, 7, 3))
	h.show_hoot(true)
	await _look(h.camera_transform("great"), 0.6)
	await _save("great")
	await _close()


func up() -> void:
	var h := TempleHall.new()
	_open(h)
	h.set_freed([0, 1, 2, 3, 4, 5, 6])
	h.set_lit(7)
	await _look(h.camera_transform("up"), 0.6)
	await _save("up")
	await _close()


func sky() -> void:
	var s := SkyRoom.new()
	_open(s)
	s.set_active(0, "bird")
	s.show_altar(AltarState.make(1, -3, 0, 5, 8), {"pan": 0, "verb": "place", "kind": "gem", "count": 1, "twins": 0})
	s.show_hoot(true)
	await _look(s.camera_transform(AltarRoom.ALTAR_VIEW), 0.6)
	await _save("sky")
	await _close()


func sky_wide() -> void:
	var s := SkyRoom.new()
	_open(s)
	s.set_active(0, "bird")
	s.set_freed([1])
	s.show_altar(AltarState.make(1, -3, 0, 5, 8))
	s.show_hoot(true)
	_child(s, Vector3(0.5, 0, 4.75), PI + 0.3)
	await _look(s.camera_transform("wide"), 0.6)
	await _save("sky_wide")
	await _close()


# --- Helpers -------------------------------------------------------------------------------------------------------

func _open(place: AltarRoom) -> void:
	_stage = Node3D.new()
	_stage.name = "ShotStage"
	_stage.position = Vector3(400, 1500, 0)
	add_child(_stage)
	_stage.add_child(place)
	_cam = Camera3D.new()
	_cam.fov = PlayHost.FOV
	_cam.near = 0.05
	_cam.far = 200.0
	_cam.environment = place.env
	add_child(_cam)
	_cam.make_current()


func _close() -> void:
	_cam.queue_free()
	_stage.queue_free()
	await get_tree().process_frame


## A picture prop for scale: a blocky child (about 1.4 m) standing at `at`, facing `yaw`.
func _child(place: Node3D, at: Vector3, yaw: float) -> void:
	var m := AltarKit.Mesher.new()
	var skin := Color("f1c7a1")
	var shirt := Color("2fb6a8")
	var trousers := Color("3a4c9a")
	m.box(Transform3D(Basis(), Vector3(0, 1.22, 0)), Vector3(0.32, 0.32, 0.32), skin, skin.lightened(0.05))
	m.box(Transform3D(Basis(), Vector3(0, 1.4, 0.0)), Vector3(0.34, 0.08, 0.34), Color("5a3a22"), Color("6b4428"))
	m.box(Transform3D(Basis(), Vector3(0, 0.84, 0)), Vector3(0.34, 0.42, 0.2), shirt, shirt.lightened(0.1))
	for side: float in [-1.0, 1.0]:
		m.box(Transform3D(Basis(), Vector3(side * 0.24, 0.86, 0)), Vector3(0.12, 0.4, 0.14), shirt, shirt)
		m.box(Transform3D(Basis(), Vector3(side * 0.09, 0.32, 0)), Vector3(0.15, 0.64, 0.17), trousers, trousers)
		m.box(Transform3D(Basis(), Vector3(side * 0.07, 1.24, 0.161)), Vector3(0.05, 0.05, 0.01), Color("2b2b2b"), Color("2b2b2b"))
	var kid := AltarKit.mesh(place, "PictureChild", m.commit(), AltarKit.lit())
	kid.position = at
	kid.rotation.y = yaw


func _look(xf: Transform3D, seconds: float) -> void:
	_cam.global_transform = xf
	var t := 0.0
	while t < seconds:
		await get_tree().process_frame
		t += maxf(get_process_delta_time(), 1.0 / 60.0)


func _save(shot: String) -> void:
	await RenderingServer.frame_post_draw
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var image := get_viewport().get_texture().get_image()
	var path := _out.path_join(shot + ".png")
	image.save_png(path)
	image.save_jpg(_out.path_join(shot + ".jpg"), 0.86)   # the notes keep small JPGs (docs/devlog/parts/game-altar-b/)
	print("ALTAR_SHOT %s %dx%d draws=%d fps=%d" % [path, image.get_width(), image.get_height(), draws,
		Engine.get_frames_per_second()])
