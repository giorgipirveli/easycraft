extends Node
## The steps of tools/academy_shots.gd (the learning places' look): its header says what it does and how to run it.

const SEED := 12345
const DAY := 0.42
const NIGHT := 0.0
const SETTLE := 1.2
const MEASURE := 6

var _tag := "after"
var _vr := false
var _style := "blocky"
var _only: Array[String] = []
var _out := ""
var _rows: Array[String] = []
var _sb: Node
var _p: Player
var _d: DiscoveryDirector


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			_tag = a.trim_prefix("--tag=")
		elif a == "--vr":
			_vr = true
		elif a.begins_with("--style="):
			_style = a.trim_prefix("--style=")
		elif a.begins_with("--only="):
			_only.assign(a.trim_prefix("--only=").split(",", false))
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	BlockLibrary.set_style(_style)
	Profile.data.settings.style = _style   # the world applies the child's own setting
	if _vr:
		PlatformRules.simulated = PlatformRules.detect()
		for tag: String in [PlatformRules.MOBILE, PlatformRules.ANDROID, PlatformRules.QUEST]:
			PlatformRules.simulated[tag] = true
		await get_tree().process_frame
		Vr.preview(true)
	_out = "%s/academy_shots/%s/%s/%s" % [OS.get_environment("XDG_DATA_HOME"), _tag, "vr" if _vr else "flat", _style]
	DirAccess.make_dir_recursive_absolute(_out)
	print("ACADEMY_SHOT dir %s renderer=%s" % [_out, RenderingServer.get_current_rendering_method()])
	WorldSaves.delete("sandbox_1")
	Profile.data.school.grade = 4
	Game.new_world_seed = SEED
	var old := get_tree().current_scene
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	var until := Time.get_ticks_msec() + 150000
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
		var sb := get_tree().current_scene
		if sb != null and sb != old and sb.get("player") is Player and (sb.get("player") as Player).is_spawned():
			_sb = sb
			break
	if _sb == null:
		print("ACADEMY_SHOT timeout: the child never stood")
		get_tree().quit(1)
		return
	_p = _sb.player
	_d = _sb.get("discovery")
	while Time.get_ticks_msec() < until and (_d.academy == null or not _d.academy.stood):
		await _hold(0.2)
	if _d.academy == null or not _d.academy.stood:
		print("ACADEMY_SHOT timeout: the Academy never stood")
		get_tree().quit(1)
		return
	var ac: AcademyPlacer = _d.academy
	var site: Dictionary = ac.site
	var floors: Dictionary = ac.buildings.floors
	var y0 := float((site.pos as Vector3i).y)
	var tower := LifeTown.to_world_point(site, Vector2.ZERO, y0 + float(floors.get("tower", 0.0)))
	print("ACADEMY_SHOT the Academy at %s facing %d%s" % [site.pos, int(site.facing), " (island)" if site.get("island", false) else ""])
	var spawn: Vector2i = (_sb.world as WorldService).spawn_column()
	# [name, where (local), how high over the ground (0: standing), what it looks at (world), the time, measured]
	var top := tower + Vector3.UP * 17.5
	var views := [
		["from_spawn", Vector2.INF, 0.0, tower + Vector3.UP * 9.0, DAY, true],
		["overview", Vector2(14, 26), 14.0, tower + Vector3.UP * 7.0, DAY, true],
		["plaza", Vector2(0, 10.9), 0.0, tower + Vector3.UP * 5.0, DAY, true],
		["courtyard", Vector2(-5.4, 1.2), 0.0, LifeTown.to_world_point(site, Vector2(2.4, 5.0), y0 + 0.8), DAY, true],
		["hoot_perched", Vector2(4, 11), 15.0, top + Vector3.UP * 1.2, DAY, false],
		["temple", Vector2(12, -20), 16.0, LifeTown.to_world_point(site, Vector2(0, -6.5), y0 + 24.0), DAY, false],
	]
	for door: String in AcademyPlaza.DOORS:
		var s: Dictionary = AcademyPlaza.SPOTS[door]
		var spot: Vector2 = s.door
		var gate := spot.normalized() * AcademyPlaza.RING
		var gy := y0 + float(floors.get(door, 0.0))
		views.append(["gate_" + door, spot * (1.0 + 2.4 / spot.length()), 0.0, LifeTown.to_world_point(site, gate, gy + 2.6), DAY,
			false])
	views.append(["night_overview", Vector2(14, 26), 14.0, tower + Vector3.UP * 7.0, NIGHT, true])
	views.append(["night_plaza", Vector2(0, 10.9), 0.0, tower + Vector3.UP * 5.0, NIGHT, false])
	for v: Array in views:
		if not _only.is_empty() and not _only.has(str(v[0])):
			continue
		var local: Vector2 = v[1]
		var at := Vector3(spawn.x + 0.5, 0, spawn.y + 0.5) if not local.is_finite() else LifeTown.to_world_point(site, local, y0)
		await _view(str(v[0]), at, float(v[2]), v[3], float(v[4]), bool(v[5]))
	if _only.is_empty() or _only.has("crystal") or _only.has("hoot"):
		await _crystal_and_hoot(LifeTown.to_world_point(site, Vector2(-5.0, -1.4), y0), LifeTown.to_world_point(site,
			Vector2(-5.0, 6.0), y0 + 1.0))   # in the courtyard (cleared): the forest round it hides what is in it
	print("ACADEMY_SHOT table (%s, %s, %s)" % [_tag, "vr" if _vr else "flat", _style])
	for r in _rows:
		print(r)
	if _vr:
		Vr.preview(false)
	get_tree().quit()


## Stands the child at `at` (on the ground there) looking at `target`, at `time` of day; a picture, and the draws when
## `measure`.
func _view(view_name: String, at: Vector3, air: float, target: Vector3, time: float, measure: bool) -> void:
	(_sb.sky as SkyCycle).set_time(time)
	_first_person(true)   # the place itself, not the child's back
	_p.set_physics_mode(PhysicsMode.Mode.FLY if air > 0.0 else PhysicsMode.Mode.NORMAL)
	_place(at, target, air)
	await _hold(SETTLE)
	_place(at, target, air)
	if measure:
		var m := await _measure()
		var b: Node3D = _d.academy.buildings
		b.visible = false   # the same view without the Academy: what the Academy itself costs
		var without := await _measure()
		b.visible = true
		var line := "ACADEMY_SHOT %s mode=%s draws_3d=%d draws_2d=%d primitives=%d objects=%d academy_draws=%d academy_primitives=%d" % [
			view_name, "vr" if _vr else "flat", int(m.draws_3d), int(m.draws_2d), int(m.primitives), int(m.objects),
			int(m.draws_3d) - int(without.draws_3d), int(m.primitives) - int(without.primitives)]
		print(line)
		_rows.append(line)
	await _shot(view_name)


func _first_person(on: bool) -> void:
	if not _vr and _p.rig.first_person != on:
		_p.rig.toggle_first_person()


func _place(at: Vector3, target: Vector3, air: float = 0.0) -> void:
	var world: WorldService = _sb.world
	_p.global_position = Vector3(at.x, world.find_standing_y(floori(at.x), floori(at.z)) + 0.01 + air, at.z)
	_p.velocity = Vector3.ZERO
	var to := target - (_p.global_position + Vector3.UP * 1.5)
	var yaw := atan2(-to.x, -to.z)
	if _vr:
		Vr.face(yaw)
	else:
		_p.rig.yaw = yaw
		_p.rig.pitch = clampf(atan2(to.y, Vector2(to.x, to.z).length()), -1.0, 1.1)


## Waits `seconds` holding the child on the ground; Hoot's own card and crystals wait (the pictures' own come instead).
func _hold(seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		await get_tree().process_frame
		if _p != null:
			_p.velocity = Vector3.ZERO
		var keys: Variant = _sb.get("keys_card") if _sb != null else null
		if keys is KeysCard and (keys as KeysCard).visible:
			(keys as KeysCard).close()   # a PC's first world shows its KEYS card
		if _d != null:
			_d.set("_play", 0.0)
			_d.set("_stood", 0.0)
			if _d.hoot != null and _d.hoot.visible:
				_d.hoot.not_now.pressed.emit()
			if _d.place_open():   # never walked up to a door (a picture from beside it): its play waits
				_d.place.stop_for_now()


## A crystal rising near the child, waiting, touched; Hoot flying in and landed: in front of the Academy.
func _crystal_and_hoot(at: Vector3, tower: Vector3) -> void:
	(_sb.sky as SkyCycle).set_time(DAY)
	_p.set_physics_mode(PhysicsMode.Mode.NORMAL)
	_place(at, tower + Vector3.UP * 2.0)
	await _hold(SETTLE)
	_place(at, tower + Vector3.UP * 2.0)
	var feet := _p.global_position
	var ahead := (tower - feet)
	ahead.y = 0.0
	ahead = ahead.normalized()
	var right := ahead.cross(Vector3.UP)
	var world: WorldService = _sb.world
	var spot := feet + ahead * 3.4 + right * 0.6
	spot.y = world.find_standing_y(floori(spot.x), floori(spot.z))
	if _only.is_empty() or _only.has("crystal"):
		_first_person(true)   # the child's own eyes on it
		_place(at, spot + Vector3.UP * 1.1)
		var c := DiscoveryCrystal.new()
		_sb.add_child(c)
		c.global_position = spot
		c.rise()
		await _hold(0.45)
		await _shot("crystal_rising")
		await _hold(1.8)
		await _shot("crystal_waiting")
		c.show_challenge({"kind": "make", "labels": ["100", "10", "1"], "gems": [100, 10, 1], "shown": "321"}, feet, "0",
			right)
		await _hold(0.15)
		await _shot("crystal_touched")
		_first_person(false)   # and as the child sees it behind their avatar
		await _hold(0.6)
		await _shot("crystal_third_person")
		c.queue_free()
		await _hold(0.5)
	if _only.is_empty() or _only.has("hoot"):
		_first_person(true)
		var h := HootFlyer.new()
		_sb.add_child(h)
		h.fly_in(spot, feet)
		await _hold(1.1)
		_place(at, h.global_position)   # eyes on him in the air
		await _hold(0.1)
		await _shot("hoot_flying")
		_place(at, spot + Vector3.UP * 0.9)
		await _hold(HootFlyer.IN_SECONDS - 1.2 + 0.5)
		await _shot("hoot_landed")
		_first_person(false)
		await _hold(0.4)
		await _shot("hoot_third_person")
		h.queue_free()


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


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var path := "%s/%s.jpg" % [_out, shot_name]
	image.save_jpg(path, 0.88)
	print("ACADEMY_SHOT picture %s" % path)
