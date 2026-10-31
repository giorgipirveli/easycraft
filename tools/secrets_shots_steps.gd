extends Node
## The steps of tools/secrets_shots.gd (M2 Task 16): stands at each secret near the spawn of seed 12345,
## looks at it in first person and saves a screenshot: the treasure X, a hidden room (after a knock), a
## temple outside and inside (plate pictures, the note), its open vault, the Wanderer, a sky island and a
## crystal geode.

const SEED := 12345
const SETTLE := 2.5               # seconds for the terrain around a new spot to mesh
const TIMEOUT := 400.0

var _views: Array[Dictionary] = []
var _i := 0
var _phase := 0
var _wait := 0.0
var _t := 0.0
var _rules: SecretRules
var _out := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	Game.new_world_seed = SEED
	_out = OS.get_environment("XDG_DATA_HOME").path_join("secret_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		print("SECRETS_SHOT timeout at view %d" % _i)
		get_tree().quit(1)
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var p: Player = sandbox.player
	var secrets: SecretDirector = sandbox.get_node("Secrets")
	if _views.is_empty():
		_plan(p)
		if not p.rig.first_person:
			p.toggle_camera()
	if _wait > 0.0:
		_wait -= delta
		return
	if _i >= _views.size():
		print("SECRETS_SHOT done views=%d" % _views.size())
		get_tree().quit(0)
		return
	var v := _views[_i]
	match _phase:
		0:
			if v.has("before"):
				(v.before as Callable).call(sandbox, secrets)
			p.spawn_at(v.stand)
			_phase = 1
			_wait = 0.3
		1:
			_aim(p, v.look)
			p.velocity = Vector3.ZERO
			_phase = 2
			_wait = SETTLE
		2:
			var w := secrets.wanderer()
			_aim(p, w.global_position + Vector3(0, 1.3, 0) if v.get("at_wanderer", false) and w else v.look)
			_phase = 3
			_wait = 0.2
		3:
			var path := _out.path_join("%02d_%s.png" % [_i, v.name])
			get_viewport().get_texture().get_image().save_png(path)
			print("SECRETS_SHOT %s %s" % [v.name, path])
			_i += 1
			_phase = 0


func _aim(p: Player, target: Vector3) -> void:
	var eye := p.eye_position()
	var d := target - eye
	p.rig.yaw = atan2(-d.x, -d.z)
	p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)


func _plan(p: Player) -> void:
	_rules = SecretRules.new(SEED, p.world.generator_shape())   # owner #45b: the world's own terrain
	var home := Vector3(_rules.spawn.x, 40, _rules.spawn.y)
	var t := _nearest(home, SecretRules.TREASURE)
	var r := _nearest(home, SecretRules.ROOM)
	var tm := _nearest(home, SecretRules.TEMPLE)
	var isl := _nearest(home, SecretRules.ISLAND)
	var g := _nearest(home, SecretRules.GEODE)
	if not t.is_empty():
		var c: Vector3i = t.chest
		var h := _rules.shape.height_at(c.x + 4, c.z + 4)
		_views.append({"name": "treasure_x", "stand": Vector3(c.x + 4.5, h + 0.5, c.z + 4.5),
			"look": Vector3(c.x + 0.5, _rules.shape.height_at(c.x, c.z), c.z + 0.5)})
	if not r.is_empty():
		var wall: Vector3i = r.fake_wall[0]
		var dir: Vector3i = r.dir
		_views.append({"name": "room_stairs", "stand": Vector3(r.stairs_top + dir * 2) + Vector3(0.5, 1.0, 0.5),
			"look": Vector3(wall) + Vector3(0.5, 0.5, 0.5)})
		_views.append({"name": "room_inside", "stand": Vector3(wall + dir) + Vector3(0.5, 0.0, 0.5),
			"look": Vector3(r.chest) + Vector3(0.5, 0.3, 0.5),
			"before": func(_s: Node, _d: SecretDirector) -> void: Session.request_knock(wall)})
	if not tm.is_empty():
		var a: Vector3i = tm.anchor
		var dir: Vector3i = tm.dir
		var out := a + dir * 14
		_views.append({"name": "temple_outside", "stand": Vector3(out.x + 0.5, _rules.shape.height_at(out.x, out.z) + 0.5, out.z + 0.5),
			"look": Vector3(a) + Vector3(0.5, 1.5, 0.5)})
		_views.append({"name": "temple_inside", "stand": Vector3(a + dir * 4) + Vector3(0.5, 0.0, 0.5),
			"look": Vector3(tm.plates[1]) + Vector3(0.5, 0.0, 0.5)})
		_views.append({"name": "temple_vault_open", "stand": Vector3(a + dir * 2) + Vector3(0.5, 0.0, 0.5),
			"look": Vector3(tm.chest) + Vector3(0.5, 0.4, 0.5),
			"before": func(_s: Node, d: SecretDirector) -> void: d._solve(tm, p.peer_id)})
		_views.append({"name": "wanderer", "stand": Vector3(a + dir * 4) + Vector3(0.5, 0.0, 0.5),
			"look": Vector3(a) + Vector3(0.5, 1.5, 0.5), "at_wanderer": true,
			"before": func(s: Node, _d: SecretDirector) -> void: s.set_time_of_day(DayCycle.DUSK_START - 0.001)})
	if not isl.is_empty():
		var c: Vector3i = isl.chest
		_views.append({"name": "sky_island", "stand": Vector3(c) + Vector3(3.5, 0.0, 2.5), "look": Vector3(c) + Vector3(0.5, 0.3, 0.5)})
	if not g.is_empty():
		var c: Vector3i = g.anchor
		_views.append({"name": "geode", "stand": Vector3(c) + Vector3(0.5, -1.0, 0.5), "look": Vector3(c) + Vector3(3.5, 0.5, 0.5)})


func _nearest(from: Vector3, kind: StringName) -> Dictionary:
	var best := {}
	var best_d := INF
	for s: Dictionary in _rules.secrets_near(from, 700.0):
		var d := Vector2(s.anchor.x - from.x, s.anchor.z - from.z).length()
		if s.kind == kind and d < best_d:
			best_d = d
			best = s
	return best
