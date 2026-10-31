extends Node
## The steps of tools/creature_shots.gd: a new Sandbox world of universe N, then close views of its robots and aliens.

const SEED := 12345
const SETTLE := 1.5
const MAX_WAIT := 15.0
const SHOT_SIZE := Vector2i(640, 360)

var _views: Array[Dictionary] = []
var _i := 0
var _phase := 0
var _wait := 0.0
var _waited := 0.0
var _out := ""
var _t := 0.0
var _u := 19


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--universe="):
			_u = int(a.get_slice("=", 1))
	Game.mode = ModeRules.SANDBOX
	Game.universe = _u
	Game.start_new_world = true
	Game.new_world_seed = SEED
	_out = OS.get_environment("XDG_DATA_HOME").path_join("creature_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > 600.0:
		print("CREATURE_SHOT timeout")
		get_tree().quit(1)
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var p: Player = sandbox.player
	var c: SpaceCreatures = sandbox.get("creatures")
	if c == null:
		print("CREATURE_SHOT no creatures in universe %d" % _u)
		get_tree().quit(1)
		return
	if _views.is_empty():
		_plan(c)
		if not p.rig.first_person:
			p.toggle_camera()
		p.set_physics_mode(PhysicsMode.Mode.FLY)
		(sandbox.get("hud") as Control).visible = false
		(sandbox.get("_layer") as CanvasLayer).visible = false   # the guide card, the KEYS card: only the world
		for n: Node in [c.rover, c.drone]:
			n.set_process(false)   # they would follow the camera; they pose for their picture instead
		_wait = 2.0
	if _wait > 0.0:
		_wait -= delta
		return
	if _i >= _views.size():
		print("CREATURE_SHOT done views=%d" % _views.size())
		get_tree().quit(0)
		return
	var v := _views[_i]
	match _phase:
		0:
			p.world.apply_style(v.style)
			(sandbox.get("sky") as SkyCycle).set_time(0.4)
			for n in c.get_tree().get_nodes_in_group(SpaceCreature.GROUP):
				(n as SpaceCreature).check_style()
			if v.has("pose"):
				(v.pose as Callable).call()
			var layer := sandbox.get("_layer") as CanvasLayer
			layer.visible = v.has("card")
			if v.has("card"):   # a creature's card over the world (the other cards closed)
				for n in layer.get_children():
					if n != c.card and n is Control and (n as Control).visible and not n is Hud and n.has_method(&"close"):
						n.call(&"close")
				(v.card as Callable).call()
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
			var path := _out.path_join("%d_%02d_%s_%s.jpg" % [_u, _i, v.name, v.style])
			img.save_jpg(path, 0.85)
			print("CREATURE_SHOT %s %s %s" % [v.name, v.style, path])
			_i += 1
			_phase = 0


## The views: each creature from in front of it (between it and the pad), the camp or village from a little way off.
func _plan(c: SpaceCreatures) -> void:
	var pad := c.shape.spawn_column()
	var pad3 := Vector3(pad.x + 0.5, 0, pad.y + 0.5)
	var robot := c.robot.global_position
	var front := Vector3(pad3.x - robot.x, 0, pad3.z - robot.z).normalized()
	var rover_at := robot + front.rotated(Vector3.UP, 1.3) * 2.2
	rover_at.y = float(c.ground_y.call(floori(rover_at.x), floori(rover_at.z)))
	var pose := func() -> void:   # the rover and the drone beside the robot, facing the camera
		c.rover.global_position = rover_at
		c.rover.body.rotation.y = atan2(front.x, front.z) + PI
		c.drone.global_position = robot + front * 1.2 + Vector3(0, 2.6, 0)
		c.drone.body.rotation.y = c.rover.body.rotation.y
	var site: Vector3 = c.site.pos
	var to_pad := Vector3(pad3.x - site.x, 0, pad3.z - site.z).normalized()
	var list: Array[Dictionary] = [
		{"name": "robots", "stand": robot + front * 5.5 + Vector3(0, 2.2, 0), "look": robot + Vector3(0, 1.2, 0), "pose": pose},
		{"name": "robot", "stand": robot + front * 3.0 + Vector3(0, 1.4, 0), "look": robot + Vector3(0, 1.0, 0), "pose": pose},
		{"name": "aliens_place", "stand": site + to_pad * 15.0 + Vector3(0, 6.0, 0), "look": site + Vector3(0, 1.5, 0)},
		{"name": "aliens_close", "stand": site + to_pad * 8.0 + Vector3(0, 3.0, 0), "look": site + Vector3(0, 1.5, 0)},
	]
	var aliens: Array[Alien] = c.camp.aliens() if c.camp else c.village.aliens()
	for a in aliens:
		var at := a.global_position
		var toward := Vector3(pad3.x - at.x, 0, pad3.z - at.z).normalized()
		list.append({"name": "alien_" + String(a.creature_id), "stand": at + toward * 3.2 + Vector3(0, 1.3, 0),
			"look": at + Vector3(0, 1.0, 0)})
		if c.village:
			break   # a village's chief close up; the villagers stroll (the village view shows them)
	var at_robot: Dictionary = list[1]
	list.append({"name": "robot_card", "stand": at_robot.stand, "look": at_robot.look, "pose": pose,
		"card": func() -> void: c.robot.tapped()})
	var first: Alien = aliens[0] if c.village else c.camp.trader
	var toward := Vector3(pad3.x - first.global_position.x, 0, pad3.z - first.global_position.z).normalized()
	list.append({"name": "alien_card", "stand": first.global_position + toward * 3.2 + Vector3(0, 1.3, 0),
		"look": first.global_position + Vector3(0, 1.0, 0), "card": func() -> void: first.tapped()})
	for style: StringName in [&"blocky", &"realistic"]:
		for v in list:
			var copy := v.duplicate()
			copy.style = style
			_views.append(copy)


func _aim(p: Player, target: Vector3) -> void:
	var eye := p.eye_position()
	var d := target - eye
	p.rig.yaw = atan2(-d.x, -d.z)
	p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)
