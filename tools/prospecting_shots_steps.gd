extends Node
## The steps of tools/prospecting_shots.gd: new Sandbox worlds in Green Meadows and the desert, then views of Gemma's
## camp, the deposits' signs where the generator wrote them, her board, and an oil well.

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
var _universe := 1
var _planned := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	WorldSaves.delete("sandbox_1")
	WorldSaves.delete(ModeRules.slot(ModeRules.SANDBOX, 2))
	Profile.data.settings.keys_seen = true   # owner #84: no KEYS card over the pictures
	_out = OS.get_environment("XDG_DATA_HOME").path_join("prospecting_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	_start(1)


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
		if _universe == 1:
			_start(2)
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
			hud.visible = v.has("board")
			if v.has("before"):
				(v.before as Callable).call(pd)
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
	var front := Vector3(-sin(pd.camp.rotation.y), 0, -cos(pd.camp.rotation.y))   # Gemma's front, towards the spawn
	for style: StringName in [&"blocky", &"realistic"]:
		_views.append({"name": "camp", "style": style, "stand": camp + front * 7.0 + Vector3(2, 2.6, 0),
			"look": camp + Vector3(0, 1.2, 0) - front * 1.5})
	for kind in DepositKinds.in_universe(_universe):
		var d := pd.deposits.nearest(kind, camp)
		if d.is_empty():
			continue
		for i in (d.signs as Array).size():
			var signs: Array = d.signs[i]
			if signs.is_empty():
				continue
			var at := Vector3(signs[signs.size() / 2] as Vector3i) + Vector3(0.5, 0.5, 0.5)
			var away := Vector3(at.x - camp.x, 0, at.z - camp.z).normalized()
			if kind == DepositKinds.GOLD and i == 1:
				var gravel := Vector3(d.signs[0][0] as Vector3i)
				away = Vector3(gravel.x - at.x, 0, gravel.z - at.z).normalized()   # the hill seen from the river
			elif kind == DepositKinds.COPPER:
				var inside := Vector3(d.anchor) - Vector3(d.spots[0] as Vector3i)
				away = -Vector3(inside.x, 0, inside.z).normalized()   # the mesa's face seen from the desert
			elif kind == DepositKinds.COAL:
				var uphill := Vector3(d.anchor) - Vector3(d.spots[0] as Vector3i)
				away = -Vector3(uphill.x, 0, uphill.z).normalized()   # the hillside seen from its foot
			var styles: Array = [&"blocky", &"realistic"] if i == 0 else [&"blocky"]
			for style in styles:
				var back := 6.0 if kind in [DepositKinds.GOLD, DepositKinds.COAL] else 9.0
				_views.append({"name": "%s_%d" % [kind, i], "style": style, "stand": at + away * back + Vector3(0, 3, 0),
					"look": at})
	if _universe == 1:
		_views.append({"name": "board_quests", "style": &"blocky", "stand": camp + front * 3.0 + Vector3(0, 1.1, 0),
			"look": camp + Vector3(0, 1.2, 0), "board": func(p: ProspectDirector) -> void: p.board.open_quests()})
		_views.append({"name": "board_map", "style": &"blocky", "stand": camp + front * 3.0 + Vector3(0, 1.1, 0),
			"look": camp + Vector3(0, 1.2, 0), "board": func(p: ProspectDirector) -> void:
				p.search_later = false
				p.start(DepositKinds.GOLD)})
		_views.append({"name": "board_find", "style": &"blocky", "stand": camp + front * 3.0 + Vector3(0, 1.1, 0),
			"look": camp + Vector3(0, 1.2, 0), "board": func(p: ProspectDirector) -> void:
				p.board.open_quests()
				p.board.show_done(DepositKinds.GOLD, "+100 gold: you found your first gold!", "gold vein")})
	else:
		var oil := pd.deposits.nearest(DepositKinds.OIL, camp)
		var a := Vector3(oil.anchor) + Vector3(0.5, 1.0, 0.5)
		var before := func(p: ProspectDirector) -> void:
			if not p.wells.has(oil.id):
				p.search_later = false
				p.start(DepositKinds.OIL)
				p.state.quests["oil"].step = p.steps_of(DepositKinds.OIL).size() - 1
				p.mark(DepositKinds.OIL)
				p.board.close()
		for style: StringName in [&"blocky", &"realistic"]:
			_views.append({"name": "oil_well", "style": style, "stand": a + Vector3(-8, 6, 9), "look": a + Vector3(2, 2, 0),
				"before": before})


func _aim(p: Player, target: Vector3) -> void:
	var eye := p.eye_position()
	var d := target - eye
	p.rig.yaw = atan2(-d.x, -d.z)
	p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)
