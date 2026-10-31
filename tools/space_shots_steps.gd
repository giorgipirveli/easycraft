extends Node
## The steps of tools/space_shots.gd: a new Sandbox world of universe N, then views from above the landing pad.

const SEED := 12345
const SETTLE := 2.0
const MAX_WAIT := 15.0
const SHOT_SIZE := Vector2i(640, 360)

var _views: Array[Dictionary] = []
var _i := 0
var _phase := 0
var _wait := 0.0
var _waited := 0.0
var _out := ""
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var u := 19
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--universe="):
			u = int(a.get_slice("=", 1))
	Game.mode = ModeRules.SANDBOX
	Game.universe = u
	Game.start_new_world = true
	Game.new_world_seed = SEED
	_out = OS.get_environment("XDG_DATA_HOME").path_join("space_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > 600.0:
		print("SPACE_SHOT timeout")
		get_tree().quit(1)
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var p: Player = sandbox.player
	if _views.is_empty():
		var home := p.world.spawn_column()
		var h := p.global_position.y
		for style: StringName in [&"blocky", &"realistic"]:
			if OS.get_cmdline_user_args().has("--colony"):   # spec §21c: only the colony's views
				_colony_views(p, style, home)
				continue
			if OS.get_cmdline_user_args().has("--nature") and p.world.generator_shape() is WondersShape:
				_nature_views(style)   # owner #78's third tour: only nature's views
				continue
			for d: Array in [["north", Vector3(0, 0, -1)], ["east", Vector3(1, 0, 0)], ["south", Vector3(0, 0, 1)],
					["west", Vector3(-1, 0, 0)]]:
				_views.append({"name": d[0], "style": style, "time": 0.4, "stand": Vector3(home.x + 0.5, h + 22, home.y + 0.5),
					"look": Vector3(home.x + 0.5, h + 10, home.y + 0.5) + (d[1] as Vector3) * 80.0})
			_views.append({"name": "sunset", "style": style, "time": 0.84, "stand": Vector3(home.x + 0.5, h + 22, home.y + 0.5),
				"look": Vector3(home.x + 80.5, h + 22, home.y + 0.5)})
			_views.append({"name": "night", "style": style, "time": 0.0, "stand": Vector3(home.x + 0.5, h + 22, home.y + 0.5),
				"look": Vector3(home.x + 0.5, h + 60, home.y - 60.5)})
			if OS.get_cmdline_user_args().has("--sights"):   # cosmos: each big sight, from its side toward the pad
				_sight_views(p, style, home)
			if OS.get_cmdline_user_args().has("--close") and p.world.generator_shape() is WondersShape:
				_wonder_close_views(style)
		if not p.rig.first_person:
			p.toggle_camera()
		p.set_physics_mode(PhysicsMode.Mode.FLY)
		(sandbox.get("hud") as Control).visible = false
		for card_name: String in ["PlanetGuideCard", "KeysCard"]:   # the explorer's card and a PC's KEYS card: out of view
			var card := sandbox.find_child(card_name, true, false) as Control
			if card != null:
				card.visible = false
		var keys: Variant = sandbox.get("keys_card")
		if keys is Control:
			(keys as Control).visible = false
	if _wait > 0.0:
		_wait -= delta
		return
	if _i >= _views.size():
		print("SPACE_SHOT done views=%d" % _views.size())
		get_tree().quit(0)
		return
	var v := _views[_i]
	match _phase:
		0:
			p.world.apply_style(v.style)
			(sandbox.get("sky") as SkyCycle).set_time(float(v.time))
			p.spawn_at(v.stand)
			p.velocity = Vector3.ZERO
			_waited = 0.0
			_phase = 1
			_wait = 0.3
		1:
			p.global_position = v.stand
			p.velocity = Vector3.ZERO
			_aim(p, v.look)
			_waited += delta
			if p.world.is_area_ready(v.look) or _waited > MAX_WAIT:
				_phase = 2
				_wait = SETTLE
		2:
			p.global_position = v.stand
			_aim(p, v.look)
			var img := get_viewport().get_texture().get_image()
			img.resize(SHOT_SIZE.x, SHOT_SIZE.y, Image.INTERPOLATE_LANCZOS)
			var path := _out.path_join("%02d_%s_%s.jpg" % [_i, v.name, v.style])
			img.save_jpg(path, 0.82)
			print("SPACE_SHOT %s %s %s" % [v.name, v.style, path])
			_i += 1
			_phase = 0


## With `--close` in world 41 (owner #78, the second tour): the New Seven as a child sees them up close, each [stand,
## look] in its own frame (y over the tour's ground): the Great Wall's walkway, Petra's court before the Treasury, the
## Colosseum's arena, El Castillo's north stair, Machu Picchu's plaza with Huayna Picchu, the Taj Mahal's garden, the
## statue from Corcovado's summit.
const CLOSE := {&"great_wall": [Vector3(-12, 12.7, 0), Vector3(30, 10, 0)], &"petra": [Vector3(0, 1.7, 0), Vector3(0, 12, 14)],
	&"colosseum": [Vector3(0, 2.7, -12), Vector3(0, 8, 25)], &"chichen_itza": [Vector3(0, 3, -42), Vector3(0, 10, 0)],
	&"machu_picchu": [Vector3(0, 13.7, -9), Vector3(0, 24, 44)], &"taj_mahal": [Vector3(0, 2.7, -34), Vector3(0, 14, 13)],
	&"christ_redeemer": [Vector3(0, 41.7, -7), Vector3(0, 62, 0)]}


func _wonder_close_views(style: StringName) -> void:
	for id: StringName in CLOSE:
		var at := func(v: Vector3) -> Vector3:
			var q := WonderTour.to_world(id, Vector2i(roundi(v.x), roundi(v.z)))
			return Vector3(q.x + 0.5, WonderTour.BASE_Y + v.y, q.y + 0.5)
		_views.append({"name": "close_" + String(id), "style": style, "time": 0.4, "stand": at.call(CLOSE[id][0]),
			"look": at.call(CLOSE[id][1])})


## With `--nature` in world 41 (owner #78, the third tour): the Seven Natural Wonders as a child sees them, each [name,
## wonder, stand, look (its own frame, y over the tour's ground), time of day]: the canyon from its rim and from the
## glass walk, the reef's cay from the jetty and its corals from the underwater room, the Sugarloaf from the promenade and
## the bay from its lookout, Everest from base camp and from its summit, the frozen lake by day and the northern lights
## at night, Parícutin from its farm track and its crater from the rim, Victoria Falls from the rainforest path; then the
## region from high over the nature square.
const NATURE := [["canyon_rim", &"grand_canyon", Vector3(0, 13.7, -30), Vector3(0, 6, 14), 0.4],
	["canyon_glass", &"grand_canyon", Vector3(19, 13.7, -17), Vector3(19, -10, 4), 0.4],
	["reef_jetty", &"barrier_reef", Vector3(0, -4.3, -24), Vector3(0, -6, 0), 0.45],
	["reef_room", &"barrier_reef", Vector3(4, -11.3, -11), Vector3(14, -13, -6), 0.45],
	["rio_promenade", &"rio_harbour", Vector3(-18, 1.7, -22), Vector3(11, 18, 22), 0.4],
	["rio_lookout", &"rio_harbour", Vector3(11, 29.7, 20), Vector3(-6, 0, -12), 0.4],
	["everest_camp", &"everest", Vector3(28, 1.7, -70), Vector3(0, 80, 0), 0.4],
	["everest_summit", &"everest", Vector3(0, 89.7, 0), Vector3(40, 70, 0), 0.4],
	["lake_day", &"northern_lights", Vector3(0, 2.7, -5), Vector3(0, 0, 14), 0.4],
	["aurora_night", &"northern_lights", Vector3(0, 2.7, -5), Vector3(-80, 105, 30), 0.0],
	["paricutin_track", &"paricutin", Vector3(0, 1.7, -50), Vector3(0, 18, 0), 0.4],
	["paricutin_crater", &"paricutin", Vector3(0, 27.7, -8), Vector3(0, 14, 2), 0.4],
	["falls_path", &"victoria_falls", Vector3(-4, 4.7, -9), Vector3(4, -8, 3), 0.42],
	["falls_pool", &"victoria_falls", Vector3(-6, -20.3, -2), Vector3(12, -10, 3), 0.42],
	["falls_above", &"victoria_falls", Vector3(-30, 24, -34), Vector3(0, -6, 3), 0.42]]


func _nature_views(style: StringName) -> void:
	for n: Array in NATURE:
		var id: StringName = n[1]
		var at := func(v: Vector3) -> Vector3:
			var q := WonderTour.to_world(id, Vector2i(roundi(v.x), roundi(v.z)))
			return Vector3(q.x + 0.5, WonderTour.BASE_Y + v.y, q.y + 0.5)
		_views.append({"name": "nature_" + str(n[0]), "style": style, "time": float(n[4]), "stand": at.call(n[2]),
			"look": at.call(n[3])})
	var s := WonderTour.NATURE_SQUARE
	_views.append({"name": "nature_region", "style": style, "time": 0.4, "stand": Vector3(s.x - 20, 100, s.y - 110),
		"look": Vector3(s.x, 32, s.y + 40)})


## With `--sights`: a view of each of the world's big sights (SpaceShape.sights: Mars's volcano, Europa's ocean well,
## ...) from 30 blocks toward the landing pad and 14 over the ground there, looking at it.
func _sight_views(p: Player, style: StringName, home: Vector2i) -> void:
	if p.world.generator_shape() is WondersShape:   # owner #78: each wonder, from 55 blocks toward its tour's square
		for id in WonderTour.ids():
			var c := WonderTour.centre(id)
			var sq := WonderTour.square_of(id)
			var to_pad := Vector2(sq.x - c.x, sq.y - c.z).normalized() * 55.0
			var tall := float((WonderBuilds.bounds(id)[1] as Vector3i).y - WonderTour.BASE_Y)   # (the second tour: Corcovado)
			_views.append({"name": "wonder_" + String(id), "style": style, "time": 0.4,
				"stand": Vector3(c.x + to_pad.x, WonderTour.BASE_Y + maxf(22.0, tall * 0.6), c.z + to_pad.y),
				"look": c + Vector3(0, maxf(12.0, tall * 0.45), 0)})
		return
	var shape := p.world.generator_shape() as SpaceShape
	if shape == null:
		return
	for s: Dictionary in shape.sights():
		var at: Vector3 = s.pos
		var to_pad := Vector2(home.x - at.x, home.y - at.z).normalized() * 30.0
		var stand := Vector3(at.x + to_pad.x, 0.0, at.z + to_pad.y)
		var ground := float(shape.height_at(floori(stand.x), floori(stand.z)))
		stand.y = maxf(ground, at.y) + 14.0
		if at.y < ground - 4.0:   # down in a hole (Europa's ocean well): from high over its rim, looking down into it
			stand = Vector3(at.x + to_pad.x * 0.2, ground + 22.0, at.z + to_pad.y * 0.2)
		_views.append({"name": "sight_" + String(s.id), "style": style, "time": 0.4, "stand": stand,
			"look": at + Vector3(0, 2, 0)})
	if shape.ganymede != null:   # cosmos: Ganymede's auroras at night, from the Aurora Watch on the frost, looking north
		var w := shape.ganymede.watch
		var gy := float(shape.ganymede.watch_y)
		_views.append({"name": "aurora_frost", "style": style, "time": 0.0, "stand": Vector3(w.x + 0.5, gy + 4.0, w.y + 30.5),
			"look": Vector3(w.x + 0.5, gy + 60.0, w.y - 50.5)})


## Spec §21c, with `--colony` (only these): the Moon's or Mars's colony seen from the landing pad, from above, under the
## Great Dome by day and by night, in the homes and the control room, the big rocket and the ice mine.
func _colony_views(p: Player, style: StringName, home: Vector2i) -> void:
	var shape := p.world.generator_shape() as SpaceShape
	if shape == null or shape.colony == null:
		return
	var c := shape.colony
	var g := float(c.ground)
	var at := func(a: int, b: int, dy: float) -> Vector3:
		var w := c.world(a, b)
		return Vector3(w.x + 0.5, g + dy, w.y + 0.5)
	var eye := CameraRig.HEAD_HEIGHT
	var views := [
		["colony_from_pad", 0.4, Vector3(home.x + 0.5, g, home.y + 0.5), at.call(0, 0, 6.0)],
		["colony_above", 0.4, at.call(60, 20, 45.0), at.call(-10, 0, 0.0)],
		["colony_dome", 0.4, at.call(7, 1, 0.0), at.call(-6, 0, eye)],
		["colony_dome_night", 0.0, at.call(7, 1, 0.0), at.call(-6, 0, eye)],
		["colony_homes", 0.4, at.call(0, -15, 0.0), at.call(0, -21, 1.0)],
		["colony_control", 0.4, at.call(-15, 0, 0.0), at.call(-21, 0, eye)],
		["colony_rocket", 0.4, at.call(-10, 34, 6.0), at.call(ColonyLayout.ROCKET.x, ColonyLayout.ROCKET.y, 14.0)],
		["colony_mine", 0.4, at.call(-24, -4, 7.0), at.call(ColonyLayout.MINE.x, ColonyLayout.MINE.y, -3.0)],
	]
	for v: Array in views:
		_views.append({"name": v[0], "style": style, "time": v[1], "stand": v[2], "look": v[3]})


func _aim(p: Player, target: Vector3) -> void:
	var eye := p.eye_position()
	var d := target - eye
	p.rig.yaw = atan2(-d.x, -d.z)
	p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)
