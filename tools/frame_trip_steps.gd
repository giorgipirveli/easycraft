extends Node
## The steps of tools/frame_trip.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
var _t := 0.0
var _phase := 0
var _last := 0
var _arrive_t := -1.0
var _scene: Node
var _added := {}
func _count(n: Node) -> void:
	var key: String = n.get_class()
	var sc: Script = n.get_script()
	if sc and sc.resource_path != "":
		key = sc.resource_path.get_file()
	_added[key] = int(_added.get(key, 0)) + 1
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.MOON)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for s in ["sandbox_1", "sandbox_16"]:
		WorldSaves.delete(s)
	Game.new_world_seed = 12345
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	_last = Time.get_ticks_msec()
	get_tree().node_added.connect(_count)
func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var dt := now - _last
	_last = now
	_t += _delta
	var sb := get_tree().current_scene
	if dt > 50 and _phase >= 2:
		var top := _added.keys()
		top.sort_custom(func(a, b): return _added[a] > _added[b])
		var parts: Array[String] = []
		for k in top.slice(0, 6):
			parts.append("%s x%d" % [k, _added[k]])
		print("TRIP long frame %d ms, %.1f s after arrival: process %.0f ms, physics %.0f ms, nav %.0f ms; added %s" % [dt, (now / 1000.0 - _arrive_t) if _arrive_t > 0 else -1.0,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS) * 1000.0, ", ".join(parts)])
	_added.clear()
	if _t > 150.0:
		print("TRIP timeout"); get_tree().quit(1); return
	if sb == null or sb.get("player") == null or not (sb.player as Player).is_spawned():
		return
	var p: Player = sb.player
	var space = sb.get("space")
	match _phase:
		0:
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			Input.action_press("jump")
			_phase = 1
		1:
			if space and space.panel.visible:
				Input.action_release("jump")
				print("TRIP picker at y=%.1f" % p.global_position.y)
				_scene = sb
				space.panel.body_for(&"moon").pressed.emit()
				space.panel.action_button.pressed.emit()
				print("TRIP chose the Moon at %d ms" % now)
				_phase = 2
		2:
			if sb != _scene:
				_arrive_t = now / 1000.0
				print("TRIP arrived at %d ms (%s)" % [now, Game.slot()])
				_phase = 3
		3:
			if now / 1000.0 - _arrive_t > 30.0:
				print("TRIP done"); get_tree().quit(0)
