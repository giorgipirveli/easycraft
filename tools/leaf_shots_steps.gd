extends Node
## The steps of tools/leaf_shots.gd (a Node, so it may use the autoloads and the game's classes). Each shot builds its
## place far from everything, sets the moment, lets it play a few seconds, and saves what the camera sees. The child and
## Hoot in the places' shots are picture props for scale; the `host_` shots are B2's voyage itself (LeafVoyageHost, its
## HUD, the child's avatar and Hoot): the garden's hook, the overview, a door glided to, the avatar's eyes, the desert's
## night, the end card and the voyage board.

const SHOTS := ["garden_droop", "garden_bloom", "dive_leaf", "dive_hairs", "dive_skin", "under", "inside_act1",
	"inside_cloud", "inside_blaze", "inside_up", "desert_day", "desert_night", "desert_up",
	"host_garden", "host_overview", "host_door", "host_first", "host_desert", "host_end", "host_board"]

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
	_out = ProjectSettings.globalize_path("user://leaf_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	for shot: String in SHOTS:
		if not only.is_empty() and not only.has(shot):
			continue
		await call(shot)
	get_tree().quit()


# --- The shots -----------------------------------------------------------------------------------------------------

func garden_droop() -> void:
	var g := LeafGarden.new()
	_open(g, g.env)
	g.show_stage(LeafProgress.DROOP, false)
	g.glow(["can"] as Array[String])
	await _look(g.camera_transform(LeafGarden.GARDEN), 1.2)
	await _save("garden_droop")
	_close()


func garden_bloom() -> void:
	var g := LeafGarden.new()
	_open(g, g.env)
	g.show_stage(LeafProgress.BLOOM, true)
	await _look(g.camera_transform(LeafGarden.GARDEN), 1.2)
	await _save("garden_bloom")
	_close()


func dive_leaf() -> void:
	await _dive(0.0, "dive_leaf")


func dive_hairs() -> void:
	await _dive(0.5, "dive_hairs")


func dive_skin() -> void:
	await _dive(1.0, "dive_skin")


func _dive(p: float, shot: String) -> void:
	var d := LeafDive.new()
	_open(d, null)
	_cam.environment = d.env
	d.pose(p)
	await _look(d.camera_transform(), 2.0)
	await _save(shot)
	_close()


func under() -> void:
	var place := LeafPlace.new("sunflower")
	_open(place, place.env)
	var sim := _sim("5.1", true, 0.5)
	await _play(place, sim, {"kind": "blaze", "heat": 1.0, "light": 1.0}, 2.5)
	await _look(place.camera_transform(LeafPlace.UNDER), 0.2)
	await _save("under")
	_close()


func inside_act1() -> void:
	var place := LeafPlace.new("sunflower")
	_open(place, place.env)
	_props(place)
	var sim := _sim("5.1", true, 0.5)
	await _play(place, sim, {"kind": "blaze", "heat": 1.0, "light": 1.0}, 3.0)
	await _look(place.camera_transform(LeafPlace.WORK), 0.2)
	await _save("inside_act1")
	_close()


func inside_cloud() -> void:
	var place := LeafPlace.new("sunflower")
	_open(place, place.env)
	_props(place)
	var sim := _sim("5.1", true, 0.85)
	sim.air = 1.0
	sim.made = 5.2
	await _play(place, sim, {"kind": "cloud", "heat": 0.25, "light": 0.7}, 6.0)
	await _look(place.camera_transform(LeafPlace.WORK), 0.2)
	await _save("inside_cloud")
	_close()


func inside_blaze() -> void:
	var place := LeafPlace.new("sunflower")
	_open(place, place.env)
	_props(place)
	var sim := _sim("5.1", false, 0.92)
	sim.made = 3.4
	sim.delivered = 6
	sim.taken = 0
	sim.bud = 6.0
	await _play(place, sim, {"kind": "blaze", "heat": 1.0, "light": 1.0}, 4.0)
	await _look(place.camera_transform(LeafPlace.WORK), 0.2)
	await _save("inside_blaze")
	_close()


func inside_up() -> void:
	var place := LeafPlace.new("sunflower")
	_open(place, place.env)
	var sim := _sim("5.1", false, 0.92)
	sim.air = 1.0
	sim.made = 2.0
	sim.delivered = 8
	sim.bud = 8.0
	await _play(place, sim, {"kind": "blaze", "heat": 1.0, "light": 1.0}, 3.0)
	await _look(place.camera_transform(LeafPlace.UP), 0.2)
	await _save("inside_up")
	_close()


func desert_day() -> void:
	var place := LeafPlace.new("cactus")
	_open(place, place.env)
	_props(place)
	var sim := _sim("5.T1", false, 0.8)
	sim.jars = 4.5
	sim.made = 2.2
	await _play(place, sim, {"kind": "desert_day", "heat": 1.3, "light": 1.0}, 3.0)
	await _look(place.camera_transform(LeafPlace.WORK), 0.2)
	await _save("desert_day")
	_close()


func desert_night() -> void:
	var place := LeafPlace.new("cactus")
	_open(place, place.env)
	_props(place)
	var sim := _sim("5.T1", true, 0.78)
	sim.jars = 5.4
	await _play(place, sim, {"kind": "desert_night", "heat": 0.05, "light": 0.0, "night": true}, 6.0)
	await _look(place.camera_transform(LeafPlace.WORK), 0.2)
	await _save("desert_night")
	_close()


func desert_up() -> void:
	var place := LeafPlace.new("cactus")
	_open(place, place.env)
	var sim := _sim("5.T1", true, 0.78)
	sim.jars = 7.0
	await _play(place, sim, {"kind": "desert_night", "heat": 0.05, "light": 0.0, "night": true}, 3.0)
	await _look(place.camera_transform(LeafPlace.UP), 0.2)
	await _save("desert_up")
	_close()


# --- Helpers -------------------------------------------------------------------------------------------------------

func _sim(voyage: String, open: bool, water: float) -> LeafSim:
	var sim := LeafSim.make(LeafVoyages.voyage(voyage).sim)
	for i in sim.doors.size():
		sim.set_door(i, open)
	sim.water = water
	return sim


## Plays the place's moment for `seconds` (real frames): the leaf lives (the workshops build, the air comes in) but its
## water is held where the moment wants it.
func _play(place: LeafPlace, sim: LeafSim, w: Dictionary, seconds: float) -> void:
	var t := 0.0
	var water := sim.water
	var made := sim.made
	while t < seconds:
		var dt := maxf(get_process_delta_time(), 1.0 / 60.0)
		sim.step(dt, w)
		sim.water = water
		sim.made = maxf(made, sim.made) if made > 0.0 else sim.made
		place.show_sim(sim, w, dt)
		await get_tree().process_frame
		t += dt


func _open(place: Node3D, env: Environment) -> void:
	_stage = Node3D.new()
	_stage.name = "ShotStage"
	_stage.position = Vector3(400, 1500, 0)
	add_child(_stage)
	_stage.add_child(place)
	_cam = Camera3D.new()
	_cam.fov = PlayHost.FOV
	_cam.near = 0.05
	_cam.far = 80.0
	if env:
		_cam.environment = env
	add_child(_cam)
	_cam.make_current()


func _close() -> void:
	_cam.queue_free()
	_stage.queue_free()
	await get_tree().process_frame


## Picture props for scale: a tiny blocky child at the leaf's way in, and Hoot at their shoulder.
func _props(place: LeafPlace) -> void:
	var kid := Node3D.new()
	kid.name = "PictureChild"
	var at := place.space.start + Vector3(0.9, -0.55, 0.6)
	kid.position = at
	kid.rotation.y = 0.5
	var m := LeafKit.Mesher.new()
	var skin := Color("f1c7a1")
	var shirt := Color("2fb6a8")
	var trousers := Color("3a4c9a")
	m.box(Transform3D(Basis(), Vector3(0, 1.32, 0)), Vector3(0.36, 0.36, 0.36), skin, skin.lightened(0.05))
	m.box(Transform3D(Basis(), Vector3(0, 1.5, 0.02)), Vector3(0.38, 0.1, 0.38), Color("5a3a22"), Color("6b4428"))
	m.box(Transform3D(Basis(), Vector3(0, 0.92, 0)), Vector3(0.38, 0.46, 0.22), shirt, shirt.lightened(0.1))
	for side: float in [-1.0, 1.0]:
		m.box(Transform3D(Basis(Vector3.FORWARD, side * 0.5), Vector3(side * 0.3, 1.0, 0)), Vector3(0.14, 0.44, 0.16), shirt,
			shirt)
		m.box(Transform3D(Basis(Vector3.RIGHT, side * 0.25), Vector3(side * 0.1, 0.45, 0)), Vector3(0.16, 0.5, 0.18),
			trousers, trousers)
	for side: float in [-1.0, 1.0]:
		m.box(Transform3D(Basis(), Vector3(side * 0.08, 1.35, 0.181)), Vector3(0.06, 0.06, 0.01), Color("2b2b2b"), Color("2b2b2b"))
	LeafKit.mesh(kid, "Body", m.commit(), LeafKit.lit())
	place.add_child(kid)
	LeafKit.hoot(place, at + Vector3(0.6, 1.1, 0.1), 0.5, 0.5).name = "PictureHoot"


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
	print("LEAF_SHOT %s %dx%d draws=%d fps=%d" % [path, image.get_width(), image.get_height(), draws,
		Engine.get_frames_per_second()])


# --- B2: the voyage itself (LeafVoyageHost) ----------------------------------------------------------------------------

var _host: LeafVoyageHost
var _host_layer: CanvasLayer


func _open_host(voyage: String) -> void:
	_host_layer = CanvasLayer.new()
	add_child(_host_layer)
	var screen := Control.new()
	_host_layer.add_child(screen)
	_host = LeafVoyageHost.new()
	_host.progress_path = "user://leaf_shots_progress.json"
	_host.setup("g5.science.plants_air_water", {"id": "g5.science.plants_air_water", "exercises": [],
		"play": {"game": "leaf_voyage", "params": {"voyage": voyage}}}, 7, 0, {})
	_host.open(screen)
	await get_tree().process_frame


## Moves the voyage on by `seconds` (in steps of `dt`), then lets it draw for `hold` s.
func _host_run(seconds: float, hold: float = 1.0, dt: float = 0.1) -> void:
	_host.set_process(false)
	var t := 0.0
	while t < seconds:
		_host.step(dt)
		t += dt
	_host.set_process(true)
	var h := 0.0
	while h < hold:
		await get_tree().process_frame
		h += maxf(get_process_delta_time(), 1.0 / 60.0)


func _host_inside() -> void:
	_host.water_now()
	_host.tap_target("leaf")
	await _host_run(LeafJourney.DIVE_TIME + LeafJourney.UNDER_TIME + LeafVoyageHost.GLIDE_MAX + 0.4, 0.5)


func _close_host() -> void:
	if is_instance_valid(_host) and not _host.closed:
		_host.close()
	_host_layer.queue_free()
	await get_tree().process_frame


func host_garden() -> void:
	await _open_host("5.1")
	await _host_run(0.5, 1.2)
	await _save("host_garden")
	await _close_host()


func host_overview() -> void:
	await _open_host("5.1")
	await _host_inside()
	await _host_run(2.0, 1.5)
	await _save("host_overview")
	await _close_host()


func host_door() -> void:
	await _open_host("5.1")
	await _host_inside()
	_host.tap_target("door_2")
	await _host_run(0.0, 1.6)
	await _save("host_door")
	await _close_host()


func host_first() -> void:
	await _open_host("5.1")
	await _host_inside()
	_host.journey.run.sim.made = 3.0
	_host.toggle_camera()
	await _host_run(0.5, 1.6)
	await _save("host_first")
	await _close_host()


func host_desert() -> void:
	await _open_host("5.T1")
	await _host_inside()
	_host.journey.run.t = _host.journey.run.weather.start_of(_host.journey.run.weather.index_of("night1")) + 6.0
	_host.avatar.set_carried(2)
	await _host_run(1.0, 2.0)
	await _save("host_desert")
	await _close_host()


func host_end() -> void:
	await _open_host("5.1")
	await _host_inside()
	_host.journey.run.phase = LeafRun.DONE
	await _host_run(LeafJourney.RETURN_TIME + LeafJourney.ANSWER_GAP * 6.0, 1.5)
	await _save("host_end")
	await _close_host()


func host_board() -> void:
	await _open_host("5.1")
	await _host_inside()
	_host.journey.run.phase = LeafRun.DONE
	await _host_run(LeafJourney.RETURN_TIME + LeafJourney.ANSWER_GAP * 6.0, 0.3)
	_host.end_choice(LeafVoyageHost.NEXT)
	await _host_run(0.0, 1.0)
	await _save("host_board")
	await _close_host()
