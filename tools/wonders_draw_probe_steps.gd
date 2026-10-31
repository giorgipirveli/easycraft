extends Node
## The steps of tools/wonders_draw_probe.gd: world 41's landing spot, four directions, the renderer's counts per frame.

const SEED := 12345
const SETTLE := 3.0
const MAX_WAIT := 20.0
const FRAMES := 120
const DIRS := [["north", Vector3(0, 0, -1)], ["east", Vector3(1, 0, 0)], ["south", Vector3(0, 0, 1)],
	["west", Vector3(-1, 0, 0)]]

var _i := 0
var _phase := 0
var _wait := 0.0
var _waited := 0.0
var _t := 0.0
var _stand := Vector3.ZERO
var _samples: Array[Dictionary] = []
var _all: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.universe = 41
	Game.start_new_world = true
	Game.new_world_seed = SEED
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > 600.0:
		print("DRAW_PROBE timeout")
		get_tree().quit(1)
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var p: Player = sandbox.player
	if _stand == Vector3.ZERO:
		var at := _at_arg()
		_stand = p.global_position if not at.is_finite() else at
		if at.is_finite():
			p.spawn_at(at)
		if not p.rig.first_person:
			p.toggle_camera()
		p.set_physics_mode(PhysicsMode.Mode.FLY)
		(sandbox.get("sky") as SkyCycle).set_time(0.0 if OS.get_cmdline_user_args().has("--night") else 0.4)
		(sandbox.get("hud") as Control).visible = false
		for card_name: String in ["PlanetGuideCard", "KeysCard"]:
			var card := sandbox.find_child(card_name, true, false) as Control
			if card != null:
				card.visible = false
		_wait = 1.0 if not at.is_finite() else 6.0
		return
	if _wait > 0.0:
		_wait -= delta
		return
	if _i >= DIRS.size():
		_report("all", _all)
		get_tree().quit(0)
		return
	var look: Vector3 = _stand + Vector3(0, 1.5, 0) + (DIRS[_i][1] as Vector3) * 40.0
	p.global_position = _stand
	p.velocity = Vector3.ZERO
	_aim(p, look)
	match _phase:
		0:
			_waited += delta
			if p.world.is_area_ready(look) or _waited > MAX_WAIT:
				_phase = 1
				_wait = SETTLE
				_samples.clear()
		1:
			_samples.append({"draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				"ms": delta * 1000.0})
			if _samples.size() >= FRAMES:
				_report(str(DIRS[_i][0]), _samples)
				_all.append_array(_samples)
				_i += 1
				_phase = 0
				_waited = 0.0


func _report(name: String, s: Array[Dictionary]) -> void:
	var sum := {"draws": 0.0, "objects": 0.0, "primitives": 0.0, "ms": 0.0}
	var worst := 0.0
	for e: Dictionary in s:
		for k: String in sum:
			sum[k] += float(e[k])
		worst = maxf(worst, float(e.ms))
	var n := maxf(s.size(), 1)
	print("DRAW_PROBE %s frames=%d draws=%.0f objects=%.0f primitives=%.0f frame_ms=%.2f worst_ms=%.1f" % [name, s.size(),
		sum.draws / n, sum.objects / n, sum.primitives / n, sum.ms / n, worst])


## `--at=nature` stands on the nature square (owner #78's third tour), `--at=<wonder id>` at that wonder's gate (where
## its path ends); none: the landing spot.
func _at_arg() -> Vector3:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--at="):
			continue
		var name := StringName(a.get_slice("=", 1))
		if name == &"nature":
			var s := WonderTour.NATURE_SQUARE
			return Vector3(s.x + 0.5, WonderTour.BASE_Y + 0.05, s.y + 0.5)
		if WonderTour.has(name):
			var g := WonderTour.gate(name)
			return Vector3(g.x + 0.5, WonderTour.BASE_Y + 0.05, g.y + 0.5)
	return Vector3.INF


func _aim(p: Player, target: Vector3) -> void:
	var d := target - p.eye_position()
	p.rig.yaw = atan2(-d.x, -d.z)
	p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)
