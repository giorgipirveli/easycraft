extends Node
## The steps of tools/ride_smoke.gd (M3 Task 20a), on real terrain through the real systems (a new Sandbox world,
## solo: this game is the host). A stone pad is laid at the spawn first (O: the player's feet cell), then:
##   a dragon built sideways (body along x, wings along z, a SADDLE on its back) at x 3..5, z -2..2;
##   a car (four wheels, a body, a SADDLE on top) at x 3..5, z -7..-5, and its road ahead (x 2..6, on to z -46): level,
##   then a 1-block step up from z -22, then a 2-block wall across at z -46.
## The wand wakes the dragon; RIDE gets on; it flies 60 s ahead (-z) over the terrain, keeping about 14 blocks above
## the ground ahead (JUMP climbs, CROUCH dives); it lands and HOP OFF gets off. Then the car is woken back on the
## pad and driven up its road (it climbs the step and bumps off the wall), then left with JUMP. Frame times, the physics step and the ridden buddy's own step
## (timed here: its engine step is off while measured) are printed for a standing phase, the flight and the drive.

const TIMEOUT := 300.0
const STAND_SECONDS := 5.0
const FLY_SECONDS := 60.0
const DRIVE_SECONDS := 10.0
const STEP_Z := -22
const WALL_Z := -46
const CRUISE := 14.0   # blocks above the highest ground ahead


class Cost:
	extends RefCounted
	var frames := 0
	var time := 0.0
	var worst := 0.0
	var over_100 := 0
	var physics_sum := 0.0
	var physics_worst := 0.0
	var steps := 0
	var step_sum := 0.0
	var step_worst := 0.0
	var steps_over_2ms := 0
	var psteps := 0
	var pstep_sum := 0.0
	var pstep_worst := 0.0
	var psteps_over_2ms := 0


var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _o := Vector3i.ZERO
var _said: Array[String] = []
var _dragon: Buddy
var _car: Buddy
var _timed: Buddy          # the ridden buddy whose step this node runs and times
var _timed_player: Player  # the player, the same (a rider's step; a flying player's step for comparison)
var _phase := &""
var _costs := {}
var _start := Vector3.ZERO
var _top_speed := 0.0
var _lowest := INF
var _stood := false
var _climbed := false
var _bumped := false
var _past_wall := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--smoke-seed="):
			Game.new_world_seed = arg.trim_prefix("--smoke-seed=").to_int()   # repeat a world
	Game.start_new_world = true
	Game.start_world(ModeRules.SANDBOX, true)
	Session.magic_feedback.connect(func(text: String) -> void:
		_said.append(text)
		print("RIDE_SMOKE feedback: %s" % text))
	print("RIDE_SMOKE begin load=%s" % _load())


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _phase != &"":
		_measure(delta)
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox)


## The ridden buddy's own physics step and the player's, run and timed here while a phase is measured (their
## engine steps are off meanwhile).
func _physics_process(delta: float) -> void:
	if _phase == &"":
		return
	var c: Cost = _costs[_phase]
	if is_instance_valid(_timed) and not _timed.is_physics_processing():
		var t0 := Time.get_ticks_usec()
		_timed._physics_process(delta)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		c.steps += 1
		c.step_sum += ms
		c.step_worst = maxf(c.step_worst, ms)
		if ms > 2.0:
			c.steps_over_2ms += 1
	if is_instance_valid(_timed_player) and not _timed_player.is_physics_processing():
		var t1 := Time.get_ticks_usec()
		_timed_player._physics_process(delta)
		var pms := (Time.get_ticks_usec() - t1) / 1000.0
		c.psteps += 1
		c.pstep_sum += pms
		c.pstep_worst = maxf(c.pstep_worst, pms)
		if pms > 2.0:
			c.psteps_over_2ms += 1


func _time_player(p: Player, on: bool) -> void:
	p.set_physics_process(not on)
	_timed_player = p if on else null


func _c(x: int, y: int, z: int) -> Vector3i:
	return _o + Vector3i(x, y, z)


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var w: WorldService = p.world
	var hud: Hud = sandbox.hud
	match _step:
		0:
			print("RIDE_SMOKE world seed=%d (repeat it with -- --smoke-seed=%d)" % [sandbox.meta.seed, sandbox.meta.seed])
			_o = Vector3i(floori(p.global_position.x), roundi(p.global_position.y), floori(p.global_position.z))
			for x in range(-4, 13):
				for z in range(-9, 6):
					w.set_block(_c(x, -1, z), BlockIds.STONE)
					for y in range(0, 7):
						w.set_block(_c(x, y, z), BlockIds.AIR)
			for cell: Vector3i in _dragon_cells():
				w.set_block(_c(cell.x, cell.y, cell.z), BlockIds.PLANKS)
			for cell: Vector3i in _car_cells():
				w.set_block(_c(cell.x, cell.y, cell.z), BlockIds.PLANKS)
			w.set_block(_c(4, 1, -6), BlockIds.SADDLE)   # the car's seat
			for x in range(2, 7):   # the car's road
				for z in range(WALL_Z, -9):
					w.set_block(_c(x, -1, z), BlockIds.STONE)
					w.set_block(_c(x, 0, z), BlockIds.STONE if z <= STEP_Z else BlockIds.AIR)
					for y in range(1, 7):
						w.set_block(_c(x, y, z), BlockIds.STONE if z == WALL_Z and y <= 2 else BlockIds.AIR)
			_stand(p, Vector3(1.0, 0.0, 0.5))
			_check(Session.request_set_block(_c(4, 2, 0), BlockIds.SADDLE), "a saddle placed through the host's edit path")
			_next(1.5)
		1:
			if not _stood:   # the pad's collision is rebuilt after the edits: stand the player on it again
				_stood = true
				_stand(p, Vector3(1.0, 0.0, 0.5))
				_wait = 0.8
				return
			_check(w.get_block(_c(4, 2, 0)) == BlockIds.SADDLE, "the saddle is on the dragon's back")
			Session.request_spark(_c(4, 2, 0))
			_dragon = _only_buddy(sandbox)
			_check(_dragon != null and _dragon.ride_kind == RideRules.Kind.FLY, "the wand wakes a flying dragon")
			_check(_said.has("%s is alive! Your dragon can fly!" % (_dragon.buddy_name if _dragon else "")), "the wake line")
			_check(_dragon != null and absf(angle_difference(_dragon.rotation.y, -PI * 0.5)) < 0.01,
				"built sideways, it turned to fly forwards")
			_check(w.get_block(_c(4, 2, 0)) == BlockIds.AIR, "its blocks left the world")
			_check(_dragon != null and _dragon.find_children("*", "CollisionShape3D", true, false).size() == 1,
				"one collision shape (owner feedback #9)")
			_next(Buddy.WAKE_TIME + 0.4)
		2:
			_begin(&"stand")
			_next(STAND_SECONDS)
		3:
			_end_phase()
			_check(hud.ride_button.visible and hud.ride_button.text == "RIDE", "RIDE shows next to the saddled dragon")
			hud.ride_button.pressed.emit()
			_check(_dragon.rider_peer == p.peer_id and p.is_riding(), "RIDE: on the saddle")
			_check(_said.has(RideRules.mount_line(RideRules.Kind.FLY)), "the rider hears how to fly")
			Session.request_sleep(String(_dragon.name))
			_check(is_instance_valid(_dragon) and not _dragon.is_queued_for_deletion(), "the wand can't put a ridden buddy to sleep")
			_next(0.3)
		4:
			_check(hud.ride_button.visible and hud.ride_button.text == "HOP OFF", "HOP OFF shows while riding")
			_check(hud.jump_button.text == "UP", "UP climbs on a dragon")
			p.rig.yaw = 0.0   # ahead is -z
			_start = _dragon.global_position
			_timed = _dragon
			_dragon.set_physics_process(false)
			_time_player(p, true)
			Input.action_press(&"move_forward")
			_begin(&"fly")
			_next(0.0)
		5:
			_fly_ahead(w)
			if _step_t < FLY_SECONDS:
				return
			_end_phase()
			Input.action_release(&"move_forward")
			Input.action_release(&"jump")
			var flown := Vector2(_dragon.global_position.x - _start.x, _dragon.global_position.z - _start.z).length()
			_check(flown > 300.0, "it flew %.0f m over the terrain" % flown)
			_check(_top_speed <= Player.FLY_SPEED + 0.01, "never faster than paid Fly (top %.2f m/s)" % _top_speed)
			_check(p.is_riding() and p.global_position.distance_to(_dragon.seat_position()) < 0.01, "the rider stayed on the saddle")
			print("RIDE_SMOKE flight distance=%.0f top_speed=%.2f lowest_above_ground=%.1f" % [flown, _top_speed, _lowest])
			_dragon.set_physics_process(true)   # the engine steps it again
			_timed = null
			_time_player(p, false)
			Input.action_press(&"crouch")
			_next(0.0)
		6:
			if not _dragon.resting() and _step_t < 25.0:
				return
			Input.action_release(&"crouch")
			_check(_dragon.resting(), "CROUCH dove down to land (%s)" % ("on the ground" if _dragon.is_on_floor() else "on water"))
			_check(p.is_riding(), "Sandbox: still riding on the ground")
			hud.ride_button.pressed.emit()
			_check(not p.is_riding() and _dragon.rider_peer == 0, "HOP OFF")
			_check(_free(w, p.global_position), "off beside it, never inside blocks (%s)" % p.global_position)
			_check(p.global_position.distance_to(_dragon.global_position) < 6.0, "next to the dragon")
			_next(2.0)
		7:
			_check(p.is_on_floor() or p.water_state >= SwimRules.State.SWIMMING,
				"standing on the ground (or swimming, off a dragon on a lake): %s" % p.global_position)
			sandbox.call("save_world")
			var saved := WorldSaves.load_meta(Game.slot())
			var saddles := 0
			for bud: Dictionary in saved.buddies:
				for e: Array in bud.blocks:
					saddles += 1 if int(e[3]) == BlockIds.SADDLE else 0
			_check(saddles == 1, "the dragon and its saddle are saved (%d saddle)" % saddles)
			# The same flight without a dragon, for comparison: the player flies (Sandbox's free Fly) as fast, over
			# new terrain the other way (+x), at the same height above the ground.
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.rig.yaw = -PI * 0.5
			_start = p.global_position
			Input.action_press(&"move_forward")
			_time_player(p, true)
			_begin(&"fly_plain")
			_step = 70
			_step_t = 0.0
		70:
			_fly_plain(w, p)
			if _step_t < FLY_SECONDS:
				return
			_end_phase()
			_time_player(p, false)
			for a: StringName in [&"move_forward", &"jump", &"fly_down"]:
				Input.action_release(a)
			print("RIDE_SMOKE plain flight distance=%.0f" % Vector2(p.global_position.x - _start.x, p.global_position.z - _start.z).length())
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			_stand(p, Vector3(1.0, 0.0, -5.5))   # back to the pad and the car
			_stood = false
			_step = 8
			_wait = 1.0
			_step_t = 0.0
		8:
			if not w.is_area_ready(p.global_position) and _step_t < 20.0:
				return
			if not _stood:
				_stood = true
				_stand(p, Vector3(1.0, 0.0, -5.5))
				_wait = 1.0
				return
			_check(w.get_block(_c(4, 1, -6)) == BlockIds.SADDLE, "the car waits on the pad")
			Session.request_spark(_c(4, 1, -6))
			for b: Buddy in sandbox.call("_buddy_nodes"):
				if b != _dragon:
					_car = b
			_check(_car != null and _car.ride_kind == RideRules.Kind.DRIVE, "the wand wakes a car")
			_check(_said.has("%s is alive! Vroom! A car!" % (_car.buddy_name if _car else "")), "the car's line")
			_next(Buddy.WAKE_TIME + 0.4)
		9:
			Session.request_ride(String(_car.name))
			_check(_car.rider_peer == p.peer_id, "on the car")
			p.rig.yaw = 0.0
			_start = _car.global_position
			_top_speed = 0.0
			_timed = _car
			_car.set_physics_process(false)
			_time_player(p, true)
			Input.action_press(&"move_forward")
			_begin(&"drive")
			_next(0.0)
		10:
			_top_speed = maxf(_top_speed, Vector2(_car.velocity.x, _car.velocity.z).length())
			_climbed = _climbed or _car.global_position.y > _o.y + 0.9
			_bumped = _bumped or _car.velocity.z > 0.5   # thrown back while driving ahead
			_past_wall = _past_wall or _car.global_position.z < _o.z + WALL_Z + 0.5
			if _step_t < DRIVE_SECONDS:
				return
			_end_phase()
			Input.action_release(&"move_forward")
			var driven := Vector2(_car.global_position.x - _start.x, _car.global_position.z - _start.z).length()
			_check(driven > 20.0, "it drove %.0f m up its road" % driven)
			_check(_top_speed <= 10.01, "a car's top speed (%.2f m/s)" % _top_speed)
			_check(_climbed, "it climbed the 1-block step")
			_check(_bumped and not _past_wall, "it bumped off the 2-block wall and never got past it (at z %.1f)"
				% (_car.global_position.z - _o.z))
			_car.set_physics_process(true)
			_timed = null
			_time_player(p, false)
			Input.action_press(&"jump")
			_next(0.2)
		11:
			Input.action_release(&"jump")
			_check(not p.is_riding() and _car.rider_peer == 0, "JUMP hops off the car")
			_check(_free(w, p.global_position), "off beside the car, never inside blocks (%s)" % p.global_position)
			_next(0.5)
		12:
			_finish()


## Keeps the dragon about CRUISE blocks above the highest ground ahead: JUMP climbs, CROUCH dives.
func _fly_ahead(w: WorldService) -> void:
	var pos := _dragon.global_position
	var ground := -1000
	for d: float in [0.0, 12.0, 24.0, 36.0]:
		ground = maxi(ground, w.surface_height(floori(pos.x), floori(pos.z - d)))
	_lowest = minf(_lowest, pos.y - w.surface_height(floori(pos.x), floori(pos.z)))
	_top_speed = maxf(_top_speed, Vector2(_dragon.velocity.x, _dragon.velocity.z).length())
	if pos.y < ground + CRUISE:
		Input.action_press(&"jump")
		Input.action_release(&"crouch")
	elif pos.y > ground + CRUISE + 8.0:
		Input.action_release(&"jump")
		Input.action_press(&"crouch")
	else:
		Input.action_release(&"jump")
		Input.action_release(&"crouch")


## The comparison flight: the player keeps CRUISE blocks above the ground ahead (+x) with JUMP and DOWN.
func _fly_plain(w: WorldService, p: Player) -> void:
	var pos := p.global_position
	var ground := -1000
	for d: float in [0.0, 12.0, 24.0, 36.0]:
		ground = maxi(ground, w.surface_height(floori(pos.x + d), floori(pos.z)))
	if pos.y < ground + CRUISE:
		Input.action_press(&"jump")
		Input.action_release(&"fly_down")
	elif pos.y > ground + CRUISE + 8.0:
		Input.action_release(&"jump")
		Input.action_press(&"fly_down")
	else:
		Input.action_release(&"jump")
		Input.action_release(&"fly_down")


static func _dragon_cells() -> Array[Vector3i]:
	var cells: Array[Vector3i] = [Vector3i(3, 0, 0), Vector3i(5, 0, 0)]   # legs
	for x in range(3, 6):
		cells.append(Vector3i(x, 1, 0))   # the body along x
		if x != 4:
			cells.append(Vector3i(x, 2, 0))   # (the saddle goes at 4, 2, 0)
		for z: int in [-2, -1, 1, 2]:
			cells.append(Vector3i(x, 2, z))   # wings along z
	return cells


static func _car_cells() -> Array[Vector3i]:
	var cells: Array[Vector3i] = [Vector3i(3, 0, -7), Vector3i(5, 0, -7), Vector3i(3, 0, -5), Vector3i(5, 0, -5)]   # wheels
	for x in range(3, 6):
		for z in range(-7, -4):
			if Vector3i(x, 1, z) != Vector3i(4, 1, -6):   # (the saddle goes in the middle)
				cells.append(Vector3i(x, 1, z))   # the body
	return cells


## Puts the player at O + `at` on the ground, still.
func _stand(p: Player, at: Vector3) -> void:
	p.global_position = Vector3(_o) + at
	p.velocity = Vector3.ZERO


func _only_buddy(sandbox: Node) -> Buddy:
	var list: Array = sandbox.call("_buddy_nodes")
	return list[0] if list.size() == 1 else null


## A world cell pair (feet, head) with nothing solid in it.
static func _free(w: WorldService, at: Vector3) -> bool:
	var feet := Vector3i(at.floor())
	return not BlockIds.is_solid(w.get_block(feet)) and not BlockIds.is_solid(w.get_block(feet + Vector3i.UP))


func _begin(phase: StringName) -> void:
	_phase = phase
	_costs[phase] = Cost.new()


func _measure(delta: float) -> void:
	var c: Cost = _costs[_phase]
	c.frames += 1
	c.time += delta
	c.worst = maxf(c.worst, delta)
	if delta > 0.1:
		c.over_100 += 1
	var physics := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	c.physics_sum += physics
	c.physics_worst = maxf(c.physics_worst, physics)


func _end_phase() -> void:
	var c: Cost = _costs[_phase]
	var frames := maxi(c.frames, 1)
	var steps := maxi(c.steps, 1)
	print("RIDE_SMOKE cost phase=%s avg_fps=%.1f avg_frame_ms=%.2f max_frame_ms=%.1f frames_over_100ms=%d physics_avg_ms=%.3f physics_max_ms=%.2f buddy_steps=%d buddy_step_avg_ms=%.4f buddy_step_max_ms=%.3f buddy_steps_over_2ms=%d player_step_avg_ms=%.4f player_step_max_ms=%.3f player_steps_over_2ms=%d load=%s" % [
		_phase, frames / maxf(c.time, 0.001), c.time * 1000.0 / frames, c.worst * 1000.0, c.over_100,
		c.physics_sum * 1000.0 / frames, c.physics_worst * 1000.0, c.steps, c.step_sum / steps, c.step_worst, c.steps_over_2ms, c.pstep_sum / maxi(c.psteps, 1), c.pstep_worst,
		c.psteps_over_2ms, _load()])
	_phase = &""


static func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("RIDE_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("RIDE_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	for a: StringName in [&"move_forward", &"jump", &"crouch", &"fly_down"]:
		Input.action_release(a)
	Music.reset()
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
