extends Node
## The steps of tools/prospecting_space_shots.gd: new Sandbox worlds on the Moon and Mars, then views of Gemma's space
## camp, the deposits' signs where the generator wrote them, and her board.

const SEED := 12345
const SETTLE := 2.0
const MAX_WAIT := 20.0
const SHOT_SIZE := Vector2i(960, 540)

var _views: Array[Dictionary] = []
var _i := 0
var _phase := 0
var _wait := 0.0
var _waited := 0.0
var _out := ""
var _t := 0.0
var _universe := SpaceRules.MOON
var _planned := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	WorldSaves.delete(ModeRules.slot(ModeRules.SANDBOX, SpaceRules.MOON))
	WorldSaves.delete(ModeRules.slot(ModeRules.SANDBOX, SpaceRules.MARS))
	Profile.data.settings.keys_seen = true   # owner #84: no KEYS card over the pictures
	Profile.data.missions.fly(SpaceRules.MOON)
	Profile.data.missions.fly(SpaceRules.MARS)
	_out = OS.get_environment("XDG_DATA_HOME").path_join("prospecting_space_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	_start(SpaceRules.MOON)


func _start(u: int) -> void:
	_universe = u
	_planned = false
	_views.clear()
	_i = 0
	_phase = 0
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, u)


func _process(delta: float) -> void:
	_t += delta
	if _t > 900.0:
		print("PROSPECT_SHOT timeout")
		get_tree().quit(1)
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if Game.universe != _universe:
		return
	var p: Player = sandbox.player
	var pd: ProspectDirector = sandbox.get("prospecting")
	if pd == null or not pd.camp_at.is_finite():
		return
	if not _planned:
		_planned = true
		_plan(pd)
		if not p.rig.first_person:
			p.toggle_camera()
		p.set_physics_mode(PhysicsMode.Mode.FLY)
		_wait = 1.0
	if _wait > 0.0:
		_wait -= delta
		return
	if _i >= _views.size():
		if _universe == SpaceRules.MOON:
			_start(SpaceRules.MARS)
			return
		print("PROSPECT_SHOT done")
		get_tree().quit(0)
		return
	var v := _views[_i]
	var hud := sandbox.get("hud") as Control
	match _phase:
		0:
			p.world.apply_style(v.style)
			(sandbox.get("sky") as SkyCycle).set_time(0.42)
			pd.board.close()
			for c in get_tree().root.find_children("*", "PlanetGuideCard", true, false):
				c.queue_free()   # the explorer's card over the pictures
			hud.visible = v.has("board")
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
				if v.has("board"):
					(v.board as Callable).call(pd)
				_phase = 2
				_wait = SETTLE
		2:
			p.global_position = v.stand
			_aim(p, v.look)
			var img := get_viewport().get_texture().get_image()
			img.resize(SHOT_SIZE.x, SHOT_SIZE.y, Image.INTERPOLATE_LANCZOS)
			var path := _out.path_join("%d_%02d_%s_%s.jpg" % [_universe, _i, v.name, v.style])
			img.save_jpg(path, 0.85)
			print("PROSPECT_SHOT %s %s %s" % [v.name, v.style, path])
			_i += 1
			_phase = 0


func _plan(pd: ProspectDirector) -> void:
	var camp := pd.camp_at
	var front := Vector3(-sin(pd.camp.rotation.y), 0, -cos(pd.camp.rotation.y))   # Gemma's front, towards the pad
	for style: StringName in [&"blocky", &"realistic"]:
		_views.append({"name": "camp", "style": style, "stand": camp + front * 7.0 + Vector3(2, 2.6, 0),
			"look": camp + Vector3(0, 1.2, 0) - front * 1.5})
	for kind in DepositKinds.in_universe(_universe):
		var d := pd.deposits.nearest(kind, camp, [], 3)
		if d.is_empty():
			continue
		var signs: Array = d.signs[(d.signs as Array).size() - 1]
		var at := Vector3(signs[0] as Vector3i) + Vector3(0.5, 0.5, 0.5)
		var away := Vector3(at.x - camp.x, 0, at.z - camp.z).normalized()
		if (d.spots as Array).size() > 1:   # a crater: seen from its rim
			var rim := Vector3(d.spots[0] as Vector3i)
			away = Vector3(rim.x - at.x, 0, rim.z - at.z).normalized()
		var up := 7.0 if SpaceDepositSites.CRATER_KINDS.has(kind) else 4.0
		for style: StringName in [&"blocky", &"realistic"]:
			_views.append({"name": String(kind), "style": style, "stand": at + away * 9.0 + Vector3(0, up, 0), "look": at})
	var near := camp + front * 3.0 + Vector3(0, 1.1, 0)
	var first: StringName = DepositKinds.in_universe(_universe)[0]
	_views.append({"name": "board_quests", "style": &"blocky", "stand": near, "look": camp + Vector3(0, 1.2, 0),
		"board": func(p: ProspectDirector) -> void: p.board.open_quests()})
	_views.append({"name": "board_map", "style": &"blocky", "stand": near, "look": camp + Vector3(0, 1.2, 0),
		"board": func(p: ProspectDirector) -> void:
			p.search_later = false
			p.start(first)})
	_views.append({"name": "board_find", "style": &"blocky", "stand": near, "look": camp + Vector3(0, 1.2, 0),
		"board": func(p: ProspectDirector) -> void:
			p.board.open_quests()
			p.board.show_done(first, "+100 gold: you found your first %s!" % DepositKinds.display_name(first).to_lower(),
				str(DepositKinds.data(first).map).to_lower())})


func _aim(p: Player, target: Vector3) -> void:
	var eye := p.eye_position()
	var d := target - eye
	p.rig.yaw = atan2(-d.x, -d.z)
	p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)
