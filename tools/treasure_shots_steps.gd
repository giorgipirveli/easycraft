extends Node
## The steps of tools/treasure_shots.gd (owner feedback #42): stands at each of the pack's places nearest the
## spawn of seed 12345, looks at it in first person and saves a screenshot; then a rainbow, and the Secret
## Book's "Treasure Hunt" page.

const SEED := 12345
const SETTLE := 2.5               # seconds for the terrain around a new spot to mesh
const TIMEOUT := 600.0

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
	_out = OS.get_environment("XDG_DATA_HOME").path_join("treasure_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		print("TREASURE_SHOT timeout at view %d" % _i)
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
		print("TREASURE_SHOT done views=%d" % _views.size())
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
			if v.has("after"):
				(v.after as Callable).call(sandbox, secrets)
			_aim(p, v.look)
			_phase = 3
			_wait = 0.3
		3:
			var path := _out.path_join("%02d_%s.png" % [_i, v.name])
			get_viewport().get_texture().get_image().save_png(path)
			print("TREASURE_SHOT %s %s" % [v.name, path])
			_i += 1
			_phase = 0


func _aim(p: Player, target: Vector3) -> void:
	var eye := p.eye_position()
	var d := target - eye
	p.rig.yaw = atan2(-d.x, -d.z)
	p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)


## A spot `back` blocks out from `s`'s door along its dir, `up` over the ground there.
func _out_front(s: Dictionary, back: int, up: float = 0.5) -> Vector3:
	var d: Vector3i = s.get("dir", Vector3i(1, 0, 0))
	var c: Vector3i = (s.door as Vector3i) + d * back
	return Vector3(c.x + 0.5, _rules.shape.height_at(c.x, c.z) + up, c.z + 0.5)


func _plan(p: Player) -> void:
	_rules = SecretRules.new(SEED, p.world.generator_shape())   # owner #45b: the world's own terrain
	var home := Vector3(_rules.spawn.x, 40, _rules.spawn.y)
	for kind in TreasurePlaces.PLACED:
		var s := _nearest(home, kind)
		if s.is_empty():
			print("TREASURE_SHOT none %s" % kind)
			continue
		var a := Vector3(s.anchor) + Vector3(0.5, 0.5, 0.5)
		match kind:
			TreasurePlaces.SHIPWRECK:
				var d: Vector3i = s.dir
				var side := Vector3i(-d.z, 0, d.x)
				var at: Vector3i = (s.anchor as Vector3i) - side * 10
				_views.append({"name": "shipwreck", "stand": Vector3(at.x + 0.5, _rules.shape.height_at(at.x, at.z) + 3.0, at.z + 0.5), "look": a})
			TreasurePlaces.SUNKEN:
				var c: Vector3i = s.chest
				_views.append({"name": "sunken", "stand": Vector3(c) + Vector3(3.5, 1.0, 3.5), "look": Vector3(c) + Vector3(0.5, 0.3, 0.5)})
			TreasurePlaces.MINESHAFT:
				_views.append({"name": "mineshaft_way_in", "stand": _out_front(s, -5, 2.0), "look": Vector3(s.door) + Vector3(0.5, 0.0, 0.5)})
				_views.append({"name": "mineshaft_cart", "stand": Vector3(s.anchor) + Vector3(0.5, 0.0, 0.5), "look": Vector3(s.chest) + Vector3(0.5, 0.4, 0.5)})
			TreasurePlaces.VAULT:
				var lever: Vector3i = (s.levers as Array)[1]
				var hall := Vector3(lever + (s.side as Vector3i) * 4 + Vector3i.DOWN) + Vector3(0.5, 0.0, 0.5)
				_views.append({"name": "vault_entrance", "stand": _out_front(s, 5, 2.5), "look": a})
				_views.append({"name": "vault_levers", "stand": hall, "look": Vector3(lever) + Vector3(0.5, 1.0, 0.5)})
				_views.append({"name": "vault_open", "stand": hall, "look": Vector3(s.chest) + Vector3(0.5, 0.4, 0.5),
					"before": func(_s: Node, d: SecretDirector) -> void: d.treasures._open_vault(s, p.peer_id)})
			TreasurePlaces.HAUNTED:
				_views.append({"name": "haunted_outside", "stand": _out_front(s, 7, 1.0), "look": a + Vector3(0, 2, 0)})
				_views.append({"name": "haunted_ghosts", "stand": Vector3(s.door) + Vector3(0.5, 0.0, 0.5), "look": a + Vector3(0, 0.5, 0)})
			TreasurePlaces.HOLLOW:
				_views.append({"name": "hollow_tree", "stand": _out_front(s, 7, 1.0), "look": a + Vector3(0, 3, 0)})
				_views.append({"name": "hollow_inside", "stand": Vector3(s.door) + Vector3(0.5, 0.0, 0.5), "look": Vector3(s.chest) + Vector3(0.5, 0.3, 0.5)})
			TreasurePlaces.WELL:
				var w: Vector3i = s.well
				_views.append({"name": "well", "stand": Vector3(w) + Vector3(4.5, 1.5, 4.5), "look": Vector3(w) + Vector3(0.5, 0.5, 0.5)})
			TreasurePlaces.WATERFALL:
				_views.append({"name": "waterfall", "stand": _out_front(s, 9, 1.0), "look": a + Vector3(0, 2, 0)})
			_:
				_views.append({"name": String(kind), "stand": _out_front(s, 7, 1.5), "look": a})
	var h := _rules.shape.height_at(_rules.spawn.x, _rules.spawn.y)
	var spawn := Vector3(_rules.spawn.x + 0.5, h + 0.5, _rules.spawn.y + 0.5)
	_views.append({"name": "rainbow", "stand": spawn, "look": spawn + Vector3(0, 14, -30),
		"before": func(_s: Node, d: SecretDirector) -> void: d.hint(TreasurePlaces.RAINBOW, spawn),
		"after": func(_s: Node, d: SecretDirector) -> void: _look_at_rainbow(p, d)})
	_views.append({"name": "book_page_2", "stand": spawn, "look": spawn + Vector3(0, 0, -10),
		"after": func(s: Node, _d: SecretDirector) -> void:
			s.hud.secret_book.open()
			s.hud.secret_book.show_page(1)})


func _look_at_rainbow(p: Player, d: SecretDirector) -> void:
	var arch := d.thing("rainbow_%d" % d.state.more.rainbows)
	if arch:
		var along := arch.global_transform.basis.x * (TreasureRules.RAINBOW_SPAN * 0.5)
		_views[_i].look = arch.global_position + along + Vector3(0, 8, 0)
		p.global_position = arch.global_position + along + arch.global_transform.basis.z * 34.0 + Vector3(0, 4, 0)


func _nearest(from: Vector3, kind: StringName) -> Dictionary:
	var best := {}
	var best_d := INF
	for s: Dictionary in _rules.secrets_near(from, 700.0):
		var d := Vector2(s.anchor.x - from.x, s.anchor.z - from.z).length()
		if s.kind == kind and d < best_d:
			best_d = d
			best = s
	return best
