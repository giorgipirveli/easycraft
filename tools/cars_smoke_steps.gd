extends Node
## The steps of tools/cars_smoke.gd (owner #109), on real terrain through the real systems (a new Sandbox world, solo:
## this game is the host). A straight stone road 7 wide runs from the spawn along -z, laid ahead of the car as it goes
## (where the world is loaded; 4 blocks of air above it), at the spawn's height: a cut through hills, a bridge over
## dips. For each kind in the garage's order: the garage's request brings the car in front of the child (the camera
## looks along -z), the child gets in (the RIDE button for the first, a tap's request after), drives (the stick as Input
## actions; the run steers along the road) or flies (JUMP up to about 12 blocks, then ahead; LAND through the HUD's
## FLY / LAND button) 300 m, and hops off with the RIDE button. The child keeps the cars where they were left (the
## garage sends the oldest home past 4), and the save keeps 4.

const TIMEOUT := 560.0
const RUN := 300.0
const ROAD_HALF := 3
const ROAD_AIR := 4
const LAY_AHEAD := 32
const AHEAD := 24.0          # the ground this far ahead must be ready while a car goes fast
const FAST := 8.0
const SAMPLE_EVERY := 0.25
const FLY_UP := 12.0


class Cost:
	extends RefCounted
	var frames := 0
	var time := 0.0
	var worst := 0.0
	var over_100 := 0
	var physics_sum := 0.0
	var steps := 0
	var step_sum := 0.0
	var step_worst := 0.0
	var distance := 0.0
	var top := 0.0
	var samples := 0
	var misses := 0
	var unlaid := 0
	var highest := -INF
	var ceiling_over := 0.0


var _t := 0.0
var _step := 0
var _wait := 0.0
var _phase_t := 0.0
var _fails: Array[String] = []
var _said: Array[String] = []
var _o := Vector3i.ZERO
var _y0 := 0
var _laid := 0              # the road is laid down to this z (it runs along -z)
var _kinds: Array[StringName] = []
var _k := 0
var _car: Vehicle
var _cost: Cost
var _costs := {}
var _last := Vector3.INF
var _sample := 0.0
var _flying_up := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_kinds = CarKinds.ORDER.duplicate()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--smoke-seed="):
			Game.new_world_seed = arg.trim_prefix("--smoke-seed=").to_int()
		elif arg.begins_with("--kinds="):
			_kinds.clear()
			for k in arg.trim_prefix("--kinds=").split(","):
				if CarKinds.exists(StringName(k)):
					_kinds.append(StringName(k))
	Game.start_new_world = true
	Game.start_world(ModeRules.SANDBOX, true)
	Session.magic_feedback.connect(func(text: String) -> void:
		_said.append(text)
		print("CARS_SMOKE feedback: %s" % text))
	print("CARS_SMOKE begin load=%s kinds=%s" % [_load(), ",".join(PackedStringArray(_kinds))])


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d (%s)" % [_step, _kind_name()])
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _cost:
		_measure(delta)
	_lay_road(sandbox.player.world)
	if _wait > 0.0:
		_wait -= delta
		return
	_phase_t += delta
	_run_step(sandbox)


## The car's own physics step, run and timed here while it drives (its engine step is off meanwhile).
func _physics_process(delta: float) -> void:
	if not is_instance_valid(_car) or _car.is_physics_processing() or _cost == null:
		return
	var t0 := Time.get_ticks_usec()
	_car.host_step(delta)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	_cost.steps += 1
	_cost.step_sum += ms
	_cost.step_worst = maxf(_cost.step_worst, ms)


func _kind_name() -> String:
	return String(_kinds[_k]) if _k < _kinds.size() else "-"


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var w: WorldService = p.world
	var cars: VehicleDirector = sandbox.vehicles
	var rides: RideDirector = sandbox.get("_rides")
	match _step:
		0:
			print("CARS_SMOKE world seed=%d (repeat it with -- --smoke-seed=%d)" % [sandbox.meta.seed, sandbox.meta.seed])
			_o = Vector3i(floori(p.global_position.x), roundi(p.global_position.y), floori(p.global_position.z))
			_y0 = _o.y
			_laid = _o.z + 4
			_next(1.0)
		1:   # the next car comes
			if _k >= _kinds.size():
				_step = 10
				return
			var kind := _kinds[_k]
			p.rig.yaw = 0.0   # the child looks along the road (-z)
			if CarKinds.flies(kind):   # open sky over the start (the road may run through a hill here)
				var at := Vector3i(p.global_position.floor())
				for x in range(_o.x - ROAD_HALF - 1, _o.x + ROAD_HALF + 2):
					for z in range(at.z - 9, at.z + 3):
						for y in range(_y0, _y0 + 40):
							if w.is_editable(Vector3i(x, y, z)) and w.get_block(Vector3i(x, y, z)) != BlockIds.AIR:
								w.set_block(Vector3i(x, y, z), BlockIds.AIR)
			cars.request_car(kind, _k % CarKinds.COLOURS)
			_next(0.6)
		2:
			var kind := _kinds[_k]
			_car = cars.car_of(cars.name_of(p.peer_id), kind)
			_check(_car != null, "%s: the garage brought it" % kind)
			if _car == null:
				_k += 1
				_step = 1
				return
			if _k == 0:
				rides.scan()
				_check(rides.nearby == _car, "%s: RIDE is for the car in front" % kind)
				_check(sandbox.hud.ride_button.text == "DRIVE", "%s: RIDE says DRIVE (%s)" % [kind, sandbox.hud.ride_button.text])
				rides.press_ride()
			else:
				cars.request_get_in(String(_car.name))   # a tap on the car
			_next(0.4)
		3:
			var kind := _kinds[_k]
			_check(p.in_car() and _car.driver() == p.peer_id, "%s: the child drives it" % kind)
			if not p.in_car():
				_k += 1
				_step = 1
				return
			_cost = Cost.new()
			_costs[kind] = _cost
			_last = _car.global_position
			_car.set_physics_process(false)   # timed here
			_flying_up = CarKinds.flies(kind)
			if _flying_up:
				Input.action_press(&"jump")
			_phase_t = 0.0
			_step = 4
		4:   # driving or flying RUN metres
			var kind := _kinds[_k]
			_follow(p, kind, w)
			var limit := RUN / maxf(CarKinds.speed(kind) if not CarKinds.flies(kind) else CarKinds.fly_speed(kind), 1.0) + 25.0
			if _cost.distance >= RUN or _phase_t > limit:
				_check(_cost.distance >= RUN, "%s: went %.0f m (in %.1f s)" % [kind, _cost.distance, _phase_t])
				for a: StringName in [&"move_forward", &"move_left", &"move_right", &"jump", &"crouch"]:
					Input.action_release(a)
				if CarKinds.flies(kind):
					_check(_car.flying, "%s: it flew" % kind)
					sandbox.hud.car_fly_button.pressed.emit()   # LAND
					_phase_t = 0.0
					_step = 5
				else:
					_phase_t = 0.0
					_step = 8   # it stops before the child hops off
		5:   # a flying car lands
			if not _car.flying or _phase_t > 20.0:
				_check(not _car.flying, "%s: LAND brought it down" % _kinds[_k])
				_phase_t = 0.0
				_step = 8
		8:   # stopped (or 6 s)
			var flat := Vector2(_car.velocity.x, _car.velocity.z).length()
			if flat < 0.3 or _phase_t > 6.0:
				_step = 6
				_wait = 0.3
		6:   # HOP OFF
			var kind := _kinds[_k]
			_report(kind)
			_car.set_physics_process(true)
			rides.press_ride()
			_next(0.5)
		7:
			var kind := _kinds[_k]
			_check(not p.in_car(), "%s: HOP OFF got out" % kind)
			var feet := Vector3i(p.global_position.floor())
			_check(not BlockIds.is_solid(w.get_block(feet)) and not BlockIds.is_solid(w.get_block(feet + Vector3i.UP)),
				"%s: never inside blocks (%s)" % [kind, p.global_position])
			var box := VehicleRules.car_aabb(_car.global_position, _car.rotation.y, _car.kind)
			_check(not box.has_point(p.global_position + Vector3(0, 0.5, 0)), "%s: beside the car, not in it" % kind)
			# the child walks on along the road, past the car it left (a flying car's landing: back to the road under it)
			var ahead := _car.global_position.z - CarKinds.size(kind).z * 0.5 - 2.5
			p.global_position = Vector3(_o.x + 0.5, _y0 + 0.05, floorf(ahead) + 0.5)
			p.velocity = Vector3.ZERO
			_cost = null
			_car = null
			_k += 1
			_step = 1
		10:   # the save
			sandbox.save_world()
			var mine := 0
			for c: Dictionary in sandbox.meta.cars:
				if str(c.owner) == cars.name_of(p.peer_id):
					mine += 1
			var want := mini(_kinds.size(), VehicleRules.PER_PLAYER)
			_check(mine == want, "the save keeps the child's %d cars out (%d)" % [want, mine])
			_finish()


## Steers along the road (its middle line, x of the spawn), full ahead; a flying car first climbs FLY_UP.
func _follow(p: Player, kind: StringName, w: WorldService) -> void:
	var car := _car
	var at := car.global_position
	var target := Vector3(_o.x + 0.5, at.y, at.z - 10.0)
	var want := atan2(-(target.x - at.x), -(target.z - at.z))
	var err := angle_difference(car.rotation.y, want)
	var steer := clampf(-err * 2.5, -1.0, 1.0)
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	if steer > 0.05:
		Input.action_press(&"move_right", steer)
	elif steer < -0.05:
		Input.action_press(&"move_left", -steer)
	if CarKinds.flies(kind):   # the pilot: FLY_UP over the highest ground ahead (JUMP climbs, CROUCH dives)
		var high := _y0
		var fwd := Basis(Vector3.UP, car.rotation.y) * Vector3.FORWARD
		for d in range(0, 40, 4):
			var q := at + fwd * float(d)
			high = maxi(high, w.surface_height(floori(q.x), floori(q.z)) + 1)
		var want_y := minf(high + FLY_UP, VehicleRules.ceiling_y(kind, high) - 2.0)
		Input.action_release(&"jump")
		Input.action_release(&"crouch")
		if at.y < want_y - 1.0:
			Input.action_press(&"jump")
		elif at.y > want_y + 3.0:
			Input.action_press(&"crouch")
		if _flying_up and at.y > _y0 + FLY_UP * 0.5:
			_flying_up = false
		if not _flying_up:
			Input.action_press(&"move_forward")
	else:
		Input.action_press(&"move_forward")
	var moved := Vector3(at.x - _last.x, 0.0, at.z - _last.z)
	if _last.is_finite():
		_cost.distance += moved.length()
	_last = at
	var speed := Vector2(car.velocity.x, car.velocity.z).length()
	_cost.top = maxf(_cost.top, speed)
	if car.flying:
		_cost.highest = maxf(_cost.highest, at.y)
		var ceiling := VehicleRules.ceiling_y(kind, w.surface_height(floori(at.x), floori(at.z)) + 1.0)
		_cost.ceiling_over = maxf(_cost.ceiling_over, at.y - ceiling)
	_sample -= get_process_delta_time()
	if _sample <= 0.0 and speed > FAST:
		_sample = SAMPLE_EVERY
		_cost.samples += 1
		var fwd := Basis(Vector3.UP, car.rotation.y) * Vector3.FORWARD
		if not w.is_area_ready(at + fwd * AHEAD + Vector3(0, -1, 0)):
			_cost.misses += 1


## The road ahead of the car (or the child): stone at the spawn's height, air above, where the world is loaded.
func _lay_road(w: WorldService) -> void:
	if _step == 0 or w == null:
		return
	var front := _car.global_position.z if is_instance_valid(_car) else float(_o.z)
	var to := floori(front) - LAY_AHEAD
	while _laid > to:
		var z := _laid - 1
		var row_ok := true
		for x in range(_o.x - ROAD_HALF, _o.x + ROAD_HALF + 1):
			if not w.is_editable(Vector3i(x, _y0 - 1, z)) or not w.is_editable(Vector3i(x, _y0 + ROAD_AIR, z)):
				row_ok = false
				break
		if not row_ok:
			if _cost and float(z) > front - 20.0:
				_cost.unlaid += 1   # the world wasn't loaded 20 m ahead of the car
			return
		for x in range(_o.x - ROAD_HALF, _o.x + ROAD_HALF + 1):
			w.set_block(Vector3i(x, _y0 - 1, z), BlockIds.STONE)
			for y in range(_y0, _y0 + ROAD_AIR):
				if w.get_block(Vector3i(x, y, z)) != BlockIds.AIR:
					w.set_block(Vector3i(x, y, z), BlockIds.AIR)
		_laid = z


func _report(kind: StringName) -> void:
	var c: Cost = _costs[kind]
	var frames := maxi(c.frames, 1)
	var steps := maxi(c.steps, 1)
	var top_allowed := CarKinds.fly_speed(kind) if CarKinds.flies(kind) else CarKinds.speed(kind)
	top_allowed = maxf(top_allowed, CarKinds.speed(kind))
	_check(c.top <= top_allowed + 0.05, "%s: top speed %.2f m/s (its kind's %.1f)" % [kind, c.top, top_allowed])
	_check(c.top <= CarKinds.GROUND_TOP + 0.05, "%s: never past 14 m/s" % kind)
	if CarKinds.flies(kind):
		_check(c.highest <= VehicleRules.FLY_CEILING + 0.3, "%s: never over the flight ceiling (highest y %.1f)" % [kind,
			c.highest])
		_check(c.ceiling_over <= 3.0, "%s: within its own ceiling over the ground (%.2f over at most, sinking back over a drop)"
			% [kind, c.ceiling_over])
	_check(c.samples == 0 or float(c.misses) / c.samples <= 0.1, "%s: the ground %d m ahead was ready (%d of %d samples missed)"
		% [kind, int(AHEAD), c.misses, c.samples])
	print("CARS_SMOKE cost kind=%s avg_fps=%.1f avg_frame_ms=%.2f max_frame_ms=%.1f frames_over_100ms=%d physics_avg_ms=%.3f car_steps=%d car_step_avg_ms=%.4f car_step_max_ms=%.3f distance_m=%.0f top_mps=%.2f ahead_samples=%d ahead_misses=%d road_unlaid=%d load=%s" % [
		kind, c.frames / maxf(c.time, 0.001), c.time * 1000.0 / frames, c.worst * 1000.0, c.over_100,
		c.physics_sum / frames, c.steps, c.step_sum / steps, c.step_worst, c.distance, c.top, c.samples, c.misses, c.unlaid,
		_load()])


func _measure(delta: float) -> void:
	_cost.frames += 1
	_cost.time += delta
	_cost.worst = maxf(_cost.worst, delta)
	if delta > 0.1:
		_cost.over_100 += 1
	_cost.physics_sum += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0


static func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_phase_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("CARS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("CARS_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	for a: StringName in [&"move_forward", &"move_left", &"move_right", &"jump", &"crouch"]:
		Input.action_release(a)
	Music.reset()
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
