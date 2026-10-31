class_name RocketFlight
extends Node3D
## The rocket flight (owner #79: "when ship is built, you just sit into it at steering wheel and fly to moon, you actually
## fly into moon, here we need real animations and visuals"; #86 movie-style moments; #87 a real landing; spec §25.3,
## §21d.4). The sandbox adds one where the rocket stands (this node's origin is the pad's corner: the rocket's cells are
## relative to it) and calls:
##   start(rocket, from_world): the whole flight in the rocket the child built (RocketStages' description, from the
##     missions' RocketCheck): the camera glides into the capsule, the countdown, lift-off from the pad in the real
##     world, up through the clouds into the flight's own space (FlightSet: the Earth, the destination, the Sun, stars),
##     the stages falling away, orbit, the trip (the movie-style moments to far worlds: FlightMoments), the slow-down, a
##     fiery entry and the parachute where there is air, the landing;
##   land(destination, lander = {}): the landing on its own (the Star Map's LAND): ~14 s from orbit to touchdown;
##   abort(): the pause menu's QUIT, or a trip that cannot go on: everything is put back, `ended` is sent.
## `landed(destination)` is sent when it touched down (the screen has faded): the sandbox loads that world (and stands
## the lander by the pad: FlightTicket.parked). FlightPlan's steps are played by a FlightRun; FlightShots says what shows;
## the child steers (FlightSteering), pushes the throttle, presses STAGE, LEGS, CHUTE on the cockpit (FlightCockpit, over
## the game; keys on a PC). The player stays hidden on the pad and safe (the sandbox's hooks below) while away.
## Owner #106: the last 120 m are the child's (FlightDescent through FlightRun: the throttle or a held BURN against the
## world's pull; the cockpit's big dials, colours, beeps and words; the first try's hint card). Too fast is a crash: the
## way home plays (the crew's capsule back to Earth, its parachute down beside the pad in the real world, the rocket
## falling by the Launch Site: `wreck` breaks the pad's parts then; in VR a fade cut) and `crashed(destination)` is sent
## instead of `landed`; the flight puts everything back and frees itself. The Star Map's LAND is a practice descent.

signal landed(destination: int)
## Owner #106: the descent crashed and the way home is over (the screen faded): the sandbox stands the child by the
## Launch Site (half the hearts where hearts count); everything is put back, the flight frees itself.
signal crashed(destination: int)
## Aborted: everything is back as it was (the sandbox forgets the flight).
signal ended
signal pause_requested

## The flight's space set and its moments: only the flight's camera in space sees this layer (visual layer 20).
const LAYER := 1 << 19
## The rocket itself (visual layer 19): the inside camera does not see it.
const ROCKET_LAYER := 1 << 18
const WORLD_MASK := 0xFFFFF
## Where the space set is: far over the world (no world block is ever near it).
const SET_OFFSET := Vector3(0, 60000, 0)
const SPACE_FAR := 100000.0
const WORLD_FAR := 1500.0
const BLEND_SECONDS := 0.7
const FADE_FROM := 0.55           # of the last step: the screen fades to black before `landed`
const SEAT_GAP := 0.35            # crew flights: metres between two crew members' seats (their inside cameras)
const VR_SPOT_EYE := 1.6          # owner #106/#108, VR: the eye over the ground at the way home's spot by the pad
const VR_DIP := 0.6               # seconds of the re-entry's end dipping to black before that spot (VR)
const VR_CLOUD_DARK := 0.75       # VR: the clouds' white-out from here up dips to black (the world/space change)


## (on: bool) -> void: hide the player and the HUD and hold the player still (true), or put them back (false).
var take_over: Callable = func(_on: bool) -> void: pass
## (on: bool) -> void: the world's sun (off while the flight is in its own space).
var world_light: Callable = func(_on: bool) -> void: pass
## (climb: float) -> void: the world's sky toward space's black (SkyCycle.set_space_climb), while still in the world.
var sky_climb: Callable = func(_c: float) -> void: pass
## () -> void: now and then: the player on the pad cannot be hurt while the child flies.
var keep_safe: Callable = func() -> void: pass
## (x, z) -> float: the ground's height there (the launch camera stands on it); NAN: the pad's.
var ground_at: Callable = func(_x: float, _z: float) -> float: return NAN
## Where the cockpit goes (the sandbox's UI layer); none: a layer of the flight's own.
var ui_parent: Node
## The camera the flight starts from (it glides from there into the capsule); none: the current one.
var from_camera: Camera3D
## SKIP shows (owner #87: repeat visits: the destination was landed on before).
var skippable := false
## Tests: false, and tick() by hand.
var auto_tick := true
## Crew flights (spec §21d.6 phase 2): a crew member's flight plays the pilot's (follow_pilot), never its own: the
## cockpit's throttle, ACTION and SKIP go, the words say what the pilot does, the aim follows the pilot's steering. The
## pilot's own flight is the one that counts (its `landed` moves the world); a crew member's `landed` only fades out.
var crew_follow := false
## The pilot's name, for a crew member's words ("Anna lets the empty stage go!").
var pilot := ""
## The seat this child sits in (0: the pilot's) of `crew_size`: the inside camera sits a little to its side.
var seat := 0
var crew_size := 1
## () -> float: seconds now (tests set their own).
var clock: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0
## Owner #106: the child never landed on this world: the easy first try with its hint card (the pilot's flight only).
var first_try := false
## Owner #106: () -> Dictionary: the falling rocket hit the ground by the Launch Site (the sandbox breaks the pad's parts:
## CrashRules) and says what broke ({"count", "gold"}; {}: nothing to say). Called once per crash, VR too.
var wreck: Callable = func() -> Dictionary: return {}
## Owner #106: the rocket falling by the Launch Site (WRECK), else null.
var wreck_node: Node3D

var rocket := {}
var destination := SpaceRules.MOON
var from_world := 1
## A whole flight (true) or a landing on its own.
var flown := true
var run: FlightRun
var steering := FlightSteering.new(20260929)
var camera: Camera3D
var cockpit: FlightCockpit
var body: RocketBody
var space: FlightSet
var moments: FlightMoments
var pad_smoke: CPUParticles3D
## The child's own camera pick (&"": the story's).
var view: StringName = &""
var pose := {}

var _active := false
var _finished := false
var _in_space := false
var _prev_camera: Camera3D
var _safe_t := 0.0
var _blend := 1.0
var _blend_from := Transform3D()
var _last_view: StringName = &""
var _engine: AudioStreamPlayer
var _count := -1
var _shake := RandomNumberGenerator.new()
var _last_sky := -1.0
var _layer_node: CanvasLayer
var _prewarm: Node3D
var _prewarm_frames := 0
var _prewarm_left: Array = []   # [() -> Material, instanced (particles)]
var _later: Array[Callable] = []
var _pilot_state := {}     # crew: the pilot's latest word (FlightRun.snapshot + its aim)
var _pilot_at := 0.0       # when it came (clock)
var _beep_t := 0.0         # owner #106: seconds to the descent's next beep
var _descent_words := ""   # the descent's words shown now
var _spoke_at := -100.0    # when the descent's words were last read aloud (run.time)
var _wreck_hit := false
var _broke := {}           # what the wreck hook said ({"count", "gold"})
var _tick_delta := 0.0
var _stage_meshes: Array[Mesh] = []   # owner #106: every stage's mesh, kept for the rocket falling by the Launch Site
## Owner #101 (VR on the Meta Quest, P3): in a headset the child sits in the capsule. VrSeat is the seat (the inside
## camera's place, a seat each in a crew flight) whose turn follows the rocket's at most VrRules.SEAT_TURN_DEGREES a
## second (no shake, no look_pitch); Vr anchors the origin to it (&"seat") and the capsule (VrCapsule) rides on it.
var _vr_seat: Node3D
var _vr_capsule: VrCapsule
var _vr_basis := Basis()
var _vr_held := false      # owner #106/#108: the flight holds the headset's black now (a fade it lets go of fades in)
var _vr_retry_t := 0.0     # seconds on the ground before a practice's next try (its dip to black)
var _vr_step := -1         # the step the headset's fades last saw, and seconds since it started there
var _vr_step_t := 0.0
## Owner #110 (VR round 4, idea 8: the cockpit you touch): the cabin lights (LIGHTS on the dashboard; off, the capsule
## goes dark and the stars show better), every buzz sent ([run time, amplitude, seconds, Hz], newest last, the last
## HAPTIC_LOG: tests), the burn's rumble's clock, each fingertip's poke (CockpitTouchRules.poke's state) and the hand
## that pokes now.
var cabin_lights := true
var vr_haptic_log: Array = []
var _rumble_t := 0.0
var _pokes := {}
var _poking_side: StringName = VrRules.RIGHT
const HAPTIC_LOG := 200
const CABIN_ON := Color(0.13, 0.15, 0.21)
const CABIN_OFF := Color(0.035, 0.04, 0.06)
const RIM_ON := Color(1.0, 0.78, 0.35)
const RIM_OFF := Color(0.42, 0.3, 0.13)


## The lander standing by the pad after it landed (its blocks' mesh, its origin the middle of its foot; a box to bump
## into, not to walk through).
static func stand(cells: Dictionary) -> Node3D:
	var root := StaticBody3D.new()
	root.name = "Lander"
	var pivot := RocketStages.pivot(cells)
	var m := MeshInstance3D.new()
	m.mesh = RocketMesh.build(cells, pivot)
	root.add_child(m)
	var b := RocketStages.bounds(cells)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(b.size.x - 2.0, 1.0), b.size.y, maxf(b.size.z - 2.0, 1.0))   # its body, not its legs
	shape.shape = box
	shape.position = Vector3(0, b.size.y * 0.5, 0)
	root.add_child(shape)
	return root


## The whole flight in `r` (RocketStages' description) from world `from`.
func start(r: Dictionary, from: int) -> void:
	rocket = RocketStages.normalize(r)
	destination = rocket.destination
	from_world = from
	flown = true
	_begin(FlightPlan.steps(destination, RocketStages.stage_count(rocket)))


## The landing on its own (owner #87; the Star Map's LAND): `lander` (a rocket description; {}: the small default lander)
## comes down from orbit over world `dest` and touches down on its pad.
func land(dest: int, lander: Dictionary = {}) -> void:
	destination = dest
	var r := RocketStages.normalize(lander) if not lander.is_empty() else RocketStages.default_lander(dest)
	var top := RocketStages.lander(r)
	var cells: Array[Vector3i] = []
	cells.assign(top.keys())
	rocket = RocketStages.normalize({"destination": dest, "cells": top, "stages": [cells], "seats": r.seats})
	flown = false
	_begin(FlightPlan.landing_steps(dest))


func is_active() -> bool:
	return _active


## What the child steers at, in a sentence: the green ring (the climb, the asteroids), the destination, the landing pad.
static func target_words(target: StringName, dest: int) -> String:
	match target:
		&"ring":
			return "the green ring"
		&"pad":
			return "the landing pad"
	return FlightPlan.body_name(dest)


## The pause menu's QUIT, or a trip that cannot go on: everything back as it was, `ended`, and the flight frees itself.
func abort() -> void:
	if not _active and not _finished:
		return
	_active = false
	_finished = false
	_restore()
	ended.emit()
	queue_free()


## SKIP (repeat visits): a whole flight jumps to its landing; a landing on its own touches down now.
func skip() -> void:
	if not _active or not skippable or crew_follow:
		return
	if not flown:
		_finish()
		return
	while not _later.is_empty():
		(_later.pop_front() as Callable).call()
	for i in run.steps.size():
		if run.steps[i].phase in [FlightPlan.DEORBIT, FlightPlan.ENTRY]:
			if i > run.index:
				run.jump_to(i)
				while body.dropped < RocketStages.stage_count(rocket) - 1:
					body.drop_next(space)
			return


func _begin(steps: Array[Dictionary]) -> void:
	if _active:
		return
	_active = true
	run = FlightRun.new(steps, RocketStages.stage_count(rocket))
	run.destination = destination   # owner #106: the descent's world, its first try, the lander's own tanks, a practice
	run.descent_easy = first_try and not crew_follow
	run.lander_tanks = FlightDescent.tanks_of(RocketStages.lander(rocket))
	run.practice = not flown
	run.step_started.connect(_on_step)
	run.action_needed.connect(_on_action_needed)
	run.action_done.connect(_on_action_done)
	run.descent_over.connect(_on_descent_over)
	run.finished.connect(_finish)
	steering.target_name = FlightPlan.body_name(destination)
	_build()
	if is_inside_tree():
		_prev_camera = get_viewport().get_camera_3d()
	if from_camera == null:
		from_camera = _prev_camera
	take_over.call(true)
	camera.make_current()
	_blend = 1.0
	run.start()
	tick(0.0)
	if _vr_seat:
		Vr.sit(_vr_seat)   # owner #101: a fade cut into the capsule (never the boarding's glide)
		_vr_place(0.0, true)


func _build() -> void:
	name = "RocketFlight" if name == "" else name
	body = RocketBody.new()
	body.name = "Rocket"
	add_child(body)
	body.setup(rocket, ROCKET_LAYER)
	for s in body.stages:
		_stage_meshes.append(s.mesh)
	space = FlightSet.new()
	space.name = "Space"
	space.position = SET_OFFSET
	add_child(space)
	space.visible = false
	moments = FlightMoments.new()
	space.add_child(moments)
	if flown:   # the space set is built over the boarding's next frames (a flight's first frame stays short)
		_later = [body.finish_setup]
		_later.append_array(space.parts(destination, LAYER))
		_later.append_array(moments.parts(LAYER))
	else:   # a landing starts in space (and has no movie moments): the stars and the world now, the Sun and the ground
		var parts := space.parts(destination, LAYER)   # over the next frames
		for part: Callable in parts.slice(1, 3):
			part.call()
		_later = [parts[0], body.finish_setup, parts[3]]
	_add_pad_smoke()
	camera = Camera3D.new()
	camera.name = "FlightCamera"
	camera.fov = 70.0
	camera.near = 0.1
	camera.far = WORLD_FAR
	add_child(camera)
	_engine = AudioStreamPlayer.new()
	_engine.name = "Engine"
	_engine.stream = FlightSounds.engine()
	_engine.bus = Audio.BUS
	_engine.volume_db = -40.0
	add_child(_engine)
	cockpit = FlightCockpit.new()
	cockpit.name = "Cockpit"
	cockpit.destination = destination
	cockpit.skippable = skippable and not crew_follow
	cockpit.crew_member = crew_follow
	cockpit.action_pressed.connect(_on_action_pressed)
	cockpit.view_pressed.connect(_on_view_pressed)
	cockpit.pause_pressed.connect(func() -> void: pause_requested.emit())
	cockpit.skip_pressed.connect(skip)
	cockpit.go_pressed.connect(func() -> void:   # owner #106: the first try's hint card
		if run and run.descent != null:
			run.descent.release())
	if ui_parent:
		ui_parent.add_child(cockpit)
	else:
		_layer_node = CanvasLayer.new()
		_layer_node.layer = 5
		UiLayers.route(_layer_node, self)   # owner #101: in VR the cockpit's own layer goes into the VR canvas
		_layer_node.add_child(cockpit)
	if Vr.active():
		_build_vr()
	_start_prewarm()


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


func _exit_tree() -> void:
	FlightLooks.settle()
	_vr_leave()


func tick(delta: float) -> void:
	if not _active:
		return
	_tick_delta = delta
	if crew_follow:
		_follow_tick(delta)
	else:
		if cockpit:
			run.throttle = cockpit.throttle
			if cockpit.action_held and run.waiting_for() in [FlightPlan.BURN, FlightPlan.DESCEND]:
				run.throttle = 1.0   # a held BURN: full throttle (owner #106: in the descent too)
		run.tick(delta)
	if not _active:
		return
	var s := run.step()
	steering.active = bool(s.get("steer", false))
	if crew_follow:   # the pilot's aim, smoothly between its words
		steering.off = steering.off.move_toward(Vector2(_pilot_state.get("off", Vector2.ZERO)),
			FlightSteering.TURN_RATE * 2.0 * delta)
	else:
		steering.tick(delta, cockpit.stick if cockpit else Vector2.ZERO)
	pose = FlightShots.pose(run.phase(), run.progress(), _info())
	steering.target_name = target_words(pose.target, destination)
	_apply(delta)
	_safe_t -= delta
	if _safe_t <= 0.0:
		_safe_t = 2.0
		keep_safe.call()
	_update_cockpit()
	if _vr_seat:   # owner #110: the dashboard's buttons under the fingertips, the engines' rumble in the hands
		_vr_touch()
		_vr_rumble(delta)
	if not _later.is_empty():
		(_later.pop_front() as Callable).call()
	else:
		_prewarm_tick()
	FlightLooks.poll()   # the big maps, as their threads finish (the cockpit's hologram may ask for one later)


## Crew flights: the pilot's flight for its crew (FlightRun.snapshot and the aim), sent a few times a second.
func crew_state() -> Dictionary:
	var s := run.snapshot() if run else {}
	s["off"] = steering.off
	return s


## Crew flights: the pilot's latest word (crew_state on the pilot's game); this crew member's flight follows it.
func follow_pilot(state: Dictionary) -> void:
	_pilot_state = state
	_pilot_at = float(clock.call())


## A crew member's run: the pilot's step and time (a little past its last word, never farther: CrewFlightRules.upto).
## Nothing from the pilot yet: the boarding waits for it.
func _follow_tick(delta: float) -> void:
	if _pilot_state.is_empty():
		return
	var since := float(clock.call()) - _pilot_at
	run.follow(delta, _pilot_state, CrewFlightRules.upto(float(_pilot_state.get("t", 0.0)), since))


func _info() -> Dictionary:
	var s := run.step()
	var burn_at := float(s.at) / float(s.seconds) if s.get("action", &"") == FlightPlan.BURN else 1.0
	var nth := 0
	for i in run.index:
		if run.steps[i].phase == FlightPlan.STAGING:
			nth += 1
	var info := {"destination": destination, "time": run.time, "waiting": run.waiting_for(),
		"done": run.action_done_here(), "throttle": run.throttle, "auto_burn": run.autopilot_burning(), "flown": flown,
		"burn_at": burn_at, "nth": nth,
		"vr": _vr_seat != null,   # owner #101: no shake, softer flashes (FlightShots.vr_pose)
		"descent_from": FlightDescent.EASY_HEIGHT if run.descent_easy else FlightDescent.START_HEIGHT}
	if run.descent != null:   # owner #106: the child's descent
		var d := run.descent
		info["descent"] = {"h": d.height, "v": d.speed, "thr": d.throttle, "state": d.state, "fuel": d.fuel}
		info["descent_from"] = FlightDescent.EASY_HEIGHT if d.easy else FlightDescent.START_HEIGHT
	return info


func _apply(delta: float) -> void:
	var in_world := bool(pose.world)
	if in_world == _in_space or (not in_world and not space.visible):
		_set_space(not in_world)
	while body.dropped < run.dropped():
		body.drop_next(space)
		Audio.play(&"thud", Vector3.INF, -4.0)
		Audio.play(&"whoosh", Vector3.INF, -6.0)
		_vr_buzz(CockpitTouchRules.THUMP)   # owner #110: the stage separation is a thump in both hands
	var pivot := body.pivot
	var basis := _rocket_basis()
	if in_world:   # (owner #106: coming home, `side` metres beside the pad)
		body.transform = Transform3D(basis, pivot + Vector3(float(pose.get("side", 0.0)), float(pose.rise), 0))
		if absf(float(pose.sky) - _last_sky) >= 0.02 or (pose.sky == 0.0 and _last_sky != 0.0):
			_last_sky = float(pose.sky)
			sky_climb.call(_last_sky)
	else:
		body.transform = Transform3D(basis, SET_OFFSET)
	body.set_fire(float(pose.fire))
	body.set_trail(in_world and float(pose.fire) > 0.1 and float(pose.rise) > 2.0)
	body.set_legs(float(pose.legs))
	body.set_chute(float(pose.chute))
	body.set_heat(float(pose.heat))
	if pad_smoke.emitting != (in_world and bool(pose.smoke)):
		pad_smoke.emitting = in_world and bool(pose.smoke)
	_place_camera(delta)
	if not in_world:
		var high := clampf(float(pose.ground_h) / FlightShots.LAND_FROM, 0.0, 1.0)
		space.pad_offset = Vector3(steering.off.x, 0.0, -steering.off.y) * 0.8 * high if pose.target == &"pad" else \
			space.pad_offset.move_toward(Vector3.ZERO, delta * 10.0)
		space.apply(pose, camera.global_position, run.time)
		var near_ground := bool(pose.ground) and float(pose.ground_h) < 30.0 and float(pose.fire) > 0.05
		if space.dust and space.dust.emitting != near_ground:
			space.dust.emitting = near_ground
		if space.dust:
			space.dust.position = space.pad_offset + Vector3(0, 0.2, 0)
	moments.apply(pose, delta)
	if float(pose.get("wreck", -1.0)) >= 0.0:
		_wreck_tick(float(pose.wreck), delta)
	_sound()


func _set_space(on: bool) -> void:
	while flown and not _later.is_empty():   # a flight's set is whole by the clouds (a landing builds on as it goes)
		(_later.pop_front() as Callable).call()
	_in_space = on
	space.visible = on
	world_light.call(not on)
	if on:
		camera.environment = space.env
		camera.far = SPACE_FAR
		sky_climb.call(0.0)
		_last_sky = 0.0
	else:
		camera.environment = null
		camera.far = WORLD_FAR
	_mask()


func _mask() -> void:
	var inside := _view() == FlightPlan.INSIDE
	var rocket_bit := 0 if inside else ROCKET_LAYER
	camera.cull_mask = (LAYER | rocket_bit) if _in_space else ((WORLD_MASK & ~ROCKET_LAYER & ~LAYER) | rocket_bit | LAYER)


## The rocket's turn: leaning over on the climb, turned round to slow down, stood up to land; the child's steering turns
## its nose away from the target by as much as the target is off.
func _rocket_basis() -> Basis:
	var b := Basis(Vector3.RIGHT, -deg_to_rad(float(pose.pitch)))
	if float(pose.turn) > 0.0:
		b = Basis(Vector3.UP, PI * float(pose.turn)) * b
	if float(pose.upright) > 0.0:
		b = Basis(Quaternion(b).slerp(Quaternion.IDENTITY, float(pose.upright)))
	var off := steering.off
	if float(pose.upright) < 0.5:
		b = Basis(Vector3.UP, deg_to_rad(off.x)) * Basis(Vector3.RIGHT, deg_to_rad(-off.y)) * b
	var tilt := float(pose.get("tilt", 0.0))
	if tilt != 0.0:   # owner #106: a lander that came down too fast tips over
		b = Basis(Vector3.BACK, deg_to_rad(tilt)) * b
	return b


func _view() -> StringName:
	if _vr_seat:   # owner #101: in VR the child sits inside (no chase nor launch camera moves); owner #106/#108: the way
		return FlightPlan.LAUNCH if _vr_watching() else FlightPlan.INSIDE   # home's end from a still spot by the pad
	var story: StringName = run.step().get("view", FlightPlan.INSIDE) if run else FlightPlan.INSIDE
	if run and run.phase() == FlightPlan.BOARD:
		return FlightPlan.INSIDE
	if view != &"":
		return view
	if story == FlightPlan.LAUNCH and not bool(pose.get("world", false)):
		return FlightPlan.CHASE
	return story


func _place_camera(delta: float) -> void:
	var v := _view()
	if v != _last_view:
		if _last_view != &"":
			_blend_from = camera.global_transform
			_blend = 0.0
		_last_view = v
		_mask()
	var target := _camera_target(v)
	if run.phase() == FlightPlan.BOARD and from_camera and is_instance_valid(from_camera):
		target = from_camera.global_transform.interpolate_with(target, smoothstep(0.0, 1.0, run.progress()))
	elif _blend < 1.0:
		_blend = minf(_blend + delta / BLEND_SECONDS, 1.0)
		target = _blend_from.interpolate_with(target, smoothstep(0.0, 1.0, _blend))
	var shake := float(pose.shake) * (0.25 if bool(Profile.data.settings.get("reduce_motion", false)) else 1.0)
	if shake > 0.0:
		target.origin += Vector3(_shake.randf_range(-1, 1), _shake.randf_range(-1, 1), _shake.randf_range(-1, 1)) \
			* shake * (0.12 if v == FlightPlan.INSIDE else 0.35)
	camera.global_transform = target
	if _vr_seat:
		_vr_place(delta)


func _camera_target(v: StringName) -> Transform3D:
	var bxf := body.global_transform
	var off := steering.off
	var size := clampf(body.height() / 12.0, 0.45, 3.0)
	match v:
		FlightPlan.INSIDE:
			var side := (float(seat) - float(crew_size - 1) * 0.5) * SEAT_GAP   # crew flights: a seat each
			var at_seat := bxf * (body.seat() + Vector3(side, 0.0, 0.0))
			var b := Basis(Vector3.UP, deg_to_rad(off.x)) * Basis(Vector3.RIGHT, deg_to_rad(float(pose.look_pitch) - off.y))
			return Transform3D(b, at_seat)
		FlightPlan.LAUNCH:
			var pad := global_position + body.pivot
			if pose.get("look", &"") == &"pad":   # owner #106: the pad, the capsule beside it and the rocket falling by it
				var from := pad + Vector3(6.0, 0.0, 34.0) * maxf(size, 1.0)
				var ground: float = ground_at.call(from.x, from.z)
				from.y = maxf((ground if is_finite(ground) else pad.y) + 2.5, pad.y + 1.5)
				return Transform3D(Basis.looking_at(pad + Vector3(0.0, 7.0, 0.0) - from, Vector3.UP), from)
			var at := pad + Vector3(22.0, 0.0, 26.0) * size
			var g: float = ground_at.call(at.x, at.z)
			at.y = (g if is_finite(g) else pad.y) + 1.7
			at.y = maxf(at.y, pad.y + 1.0)
			var centre := bxf.origin + bxf.basis.y.normalized() * body.height() * 0.45
			return Transform3D(Basis.looking_at(centre - at, Vector3.UP), at)
	var centre := bxf.origin + bxf.basis.y.normalized() * body.height() * 0.5
	var offset := Vector3(6.0, 8.0, 30.0)
	match pose.get("chase", &"behind"):
		&"front":
			offset = Vector3(14.0, 6.0, -34.0)
		&"side":
			offset = Vector3(30.0, 5.0, 10.0)
		&"above":
			offset = Vector3(22.0, 20.0, 18.0)
	var at := centre + offset * size
	return Transform3D(Basis.looking_at(centre - at, Vector3.UP), at)


func _on_step(_i: int) -> void:
	var s := run.step()
	var said := CrewFlightRules.crew_words(s, pilot) if crew_follow else str(s.words)
	if cockpit:
		cockpit.say(said)
	ReadAloud.auto(said)
	match run.phase():
		FlightPlan.LANDED:
			var at := body.global_position
			var burst := Fx.burst(get_tree().root if is_inside_tree() else self, at + Vector3(0, 0.3, 0),
				(FlightLooks.look(destination).ground as Color).lightened(0.2), 44, 7.0, 0.35, 1.3, 2.0, 80.0)
			burst.layers = LAYER
			Audio.play(&"thud")
			Audio.play(&"fanfare", Vector3.INF, -6.0)
		FlightPlan.JUMP, FlightPlan.WORMHOLE:
			Audio.play(&"portal_whoosh")
		FlightPlan.WARP:
			Audio.play(&"rocket_whoosh")
		FlightPlan.HOME_CHUTE:
			Audio.play(&"pop")
			Audio.play(&"whoosh", Vector3.INF, -4.0)
		FlightPlan.WRECK:
			Audio.play(&"whoosh", Vector3.INF, -2.0)
		FlightPlan.HOME:
			if not _broke.is_empty():
				var broke := "1 part broke" if int(_broke.get("count", 0)) == 1 else "%d parts broke" % int(_broke.count)
				var words_now := "%s: rebuilding costs %d gold. Rebuild at the Mission Board and try again!" % [broke,
					int(_broke.get("gold", 0))] if int(_broke.get("gold", 0)) > 0 \
					else "%s: your spare parts cover them. Rebuild at the Mission Board and try again!" % broke
				if cockpit:
					cockpit.say(words_now)
				ReadAloud.auto(words_now)


func _on_action_needed(_action: StringName) -> void:
	if crew_follow:
		return   # the pilot acts: the step's words already said so
	var prompt := str(run.step().get("prompt", ""))
	if prompt != "" and cockpit:
		cockpit.say(prompt)
		ReadAloud.auto(prompt)


func _on_action_done(action: StringName, _by_autopilot: bool) -> void:
	if action == FlightPlan.DESCEND:
		return   # owner #106: the touchdown's words are _on_descent_over's (soft, or a crash)
	var after := str(run.step().get("after", ""))
	if after != "" and cockpit:
		cockpit.say(after)
		ReadAloud.auto(after)
	match action:
		FlightPlan.THROTTLE:
			Audio.play(&"rocket_whoosh")
			if run.phase() == FlightPlan.LIFTOFF:
				ReadAloud.speak(Lang.t("Lift-off!"))
		FlightPlan.LEGS:
			Audio.play(&"whirr")
		FlightPlan.PARACHUTE:
			Audio.play(&"pop")
			Audio.play(&"whoosh", Vector3.INF, -4.0)


func _on_action_pressed() -> void:
	if crew_follow:
		return
	if run.descent != null and run.descent.held():   # owner #106: ACTION (Space) is GO on the hint card too
		run.descent.release()
		return
	var waiting := run.waiting_for()
	if waiting == FlightPlan.THROTTLE or (waiting == &"" and run.step().get("action", &"") == FlightPlan.THROTTLE):
		run.act(FlightPlan.THROTTLE)
	elif waiting != &"" and waiting not in [FlightPlan.BURN, FlightPlan.DESCEND]:   # (held, never pressed done)
		run.act(waiting)


## Owner #106: the descent touched down. Soft: the touchdown's words and sounds. Too fast: the crash's bump and dust
## (a mission's way home follows: FlightPlan.crash_steps' words); a practice tries again, and its last try is
## Mission Control's.
func _on_descent_over(soft: bool) -> void:
	var d := run.descent
	var v := d.touchdown_speed if d != null else 0.0
	var words := ""
	if soft:
		words = "Mission Control landed this one for you. Practise again next time!" if run.helped() \
			else "Touchdown at %.1f m/s: a soft landing! You landed it yourself!" % v
		Audio.play(&"thud", Vector3.INF, -4.0)
		_vr_buzz(VrRules.HAPTIC_TOUCHDOWN)
	else:
		Audio.play(&"rock_crash")
		Audio.play(&"thud")
		_dust_burst(Color(0.75, 0.7, 0.62))
		_vr_buzz(VrRules.HAPTIC_CRASH)
		if not run.crashed():
			words = "Bump! %.1f m/s is too fast: slower than 3 m/s is safe. Try again from the top!" % v
	if cockpit and words != "":
		cockpit.say(words)
	if words != "":
		ReadAloud.auto(words)


## Owner #106: the rocket falling by the Launch Site (WRECK, `q` 0..1 through it): a copy of the whole rocket drops from
## the sky beside the pad, tumbling, and hits the ground at FlightShots.WRECK_HIT (dust, a crash: the sandbox's `wreck`
## breaks the pad's parts then), then it is gone in the dust (the damaged rocket stands on the pad).
func _wreck_tick(q: float, _delta: float) -> void:
	if wreck_node == null and not _wreck_hit:
		wreck_node = Node3D.new()
		wreck_node.name = "Wreck"
		for mesh in _stage_meshes:   # the stages' own meshes (built at the start: nothing is built now)
			var m := MeshInstance3D.new()
			m.mesh = mesh
			m.layers = ROCKET_LAYER
			wreck_node.add_child(m)
		add_child(wreck_node)
	if wreck_node != null:
		var spot := _wreck_spot()
		var fall := clampf(q / FlightShots.WRECK_HIT, 0.0, 1.0)
		wreck_node.position = spot + Vector3(0.0, 90.0 * (1.0 - fall * fall), 0.0)
		wreck_node.rotation = Vector3(0.6 * fall, 0.0, 1.3 * fall)
		wreck_node.visible = q < FlightShots.WRECK_HIT + 0.02
	if q >= FlightShots.WRECK_HIT and not _wreck_hit:
		_hit_ground()


## Where the falling rocket hits (this node's space): beside the pad, on the other side from the capsule.
func _wreck_spot() -> Vector3:
	var spot := body.pivot + Vector3(-(FlightShots.HOME_SIDE + body.width() * 0.5), 0.0, 5.0)
	var g: float = ground_at.call(global_position.x + spot.x, global_position.z + spot.z)
	if is_finite(g):
		spot.y = g - global_position.y
	return spot


## The falling rocket hits the ground (once a crash): the dust and the sound, and the sandbox breaks the pad's parts.
func _hit_ground() -> void:
	_wreck_hit = true
	var said: Variant = wreck.call()
	_broke = said if said is Dictionary else {}
	if wreck_node != null and is_inside_tree():
		var at := wreck_node.global_position
		var burst := Fx.burst(get_tree().root, at + Vector3(0, 0.5, 0), Color(0.62, 0.58, 0.52), 56, 10.0, 0.5, 1.6, 2.4, 90.0)
		burst.layers = LAYER
		Audio.play(&"rock_crash")
		Audio.play(&"smash", Vector3.INF, -3.0)
		wreck_node.visible = false
		_vr_buzz(VrRules.HAPTIC_WRECK)


## A puff of the ground's dust round the rocket's feet (the flight's own layer).
func _dust_burst(tint: Color) -> void:
	if body == null:
		return
	var at := body.global_position
	var burst := Fx.burst(get_tree().root if is_inside_tree() else self, at + Vector3(0, 0.3, 0),
		tint.lerp((FlightLooks.look(destination).ground as Color), 0.5), 40, 8.0, 0.4, 1.4, 2.0, 80.0)
	burst.layers = LAYER


func _on_view_pressed() -> void:
	if _vr_seat:
		return   # owner #101: INSIDE only in VR
	var now := _view()
	view = FlightPlan.CHASE if now == FlightPlan.INSIDE else FlightPlan.INSIDE


func _update_cockpit() -> void:
	if cockpit == null:
		return
	var s := run.step()
	var descent := {}
	if run.descent != null:   # owner #106: the child's descent (its metres, and the lander's fuel from then on)
		descent = {"h": run.descent.height, "v": run.descent.speed, "fuel": run.descent.fuel_fraction()}
	var d := FlightDials.read(run.steps, run.index, run.progress(), destination, RocketStages.stage_count(rocket),
		1.0 if run.action_done_here() else run.burn_progress(), run.dropped(), descent)
	var count := -1
	if run.phase() == FlightPlan.COUNTDOWN:
		count = clampi(10 - floori(run.progress() * 10.0), 1, 10)
		if count != _count:
			_count = count
			Audio.play(&"beep", Vector3.INF, -2.0, 1.0 + (10 - count) * 0.03)
			ReadAloud.speak(str(count))
			if count <= CockpitTouchRules.TICKS_FROM:
				_vr_buzz(CockpitTouchRules.TICK)   # owner #110: the last three seconds tick on the hands
	var last := run.index == run.steps.size() - 1
	var fade := clampf((run.progress() - FADE_FROM) / (1.0 - FADE_FROM), 0.0, 1.0) if last else 0.0
	var state := {"dials": d, "waiting": run.waiting_for(), "throttle": run.throttle, "view": _view(),
		"countdown": count, "cloud": float(pose.cloud), "flash": float(pose.flash), "fade": fade, "off": steering.off,
		"steer": steering.active, "target": pose.target, "target_name": steering.target_name, "hint": steering.hint(),
		"burn": run.burn_progress(), "auto_burn": run.autopilot_burning(), "phase": run.phase(), "time": run.time,
		"stages": RocketStages.stage_count(rocket), "action": s.get("action", &""), "done": run.action_done_here()}
	if run.phase() == FlightPlan.DESCENT and run.descent != null:
		_descent_state(state, d)
	cockpit.show_state(state)


## Owner #106: the descent's big dials (height in metres, falling speed in m/s with its colour, the lander's fuel), its
## short words on the hint line (read aloud when they change, at most every 2.5 s), its beep quickening near the ground,
## and the first try's hint card.
func _descent_state(state: Dictionary, dials: Dictionary) -> void:
	var dd := run.descent
	var fuel: Array = dials.get("fuel", [])
	state["descent"] = {"h": dd.height, "v": dd.speed, "zone": dd.zone(), "fuel": float(fuel.back()) if not fuel.is_empty()
		else dd.fuel_fraction(), "safe": FlightDescent.SAFE_SPEED, "state": dd.state, "held": dd.held()}
	state["descent_held"] = dd.held() and not crew_follow
	var words := dd.words() if dd.state == FlightDescent.FLYING else ""
	if words != "":
		state["hint"] = words
	if words != _descent_words:
		_descent_words = words
		if words != "" and run.time - _spoke_at >= 2.5:
			_spoke_at = run.time
			ReadAloud.auto(words)
	if dd.state != FlightDescent.FLYING or dd.held():
		return
	_beep_t -= _tick_delta
	if _beep_t <= 0.0:
		_beep_t = dd.beep_every()
		var red := dd.zone() == FlightDescent.RED
		Audio.play(&"beep", Vector3.INF, -9.0 if not red else -5.0, 1.35 if red else 1.0 + 0.2 * (1.0 - clampf(
			dd.height / FlightDescent.START_HEIGHT, 0.0, 1.0)))


func _sound() -> void:
	var f := float(pose.fire)
	if f > 0.02:
		if not _engine.playing:
			_engine.play()
		_engine.volume_db = linear_to_db(0.12 + 0.75 * f) - (6.0 if _in_space else 0.0)
		_engine.pitch_scale = 0.75 + 0.35 * f
	elif _engine.playing:
		_engine.stop()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_active = false
	if _engine:
		_engine.stop()
	if run.crashed():   # owner #106: home by the Launch Site; everything back, and the flight frees itself
		if not _wreck_hit:
			_hit_ground()   # (a way home cut short still breaks the rocket once)
		crashed.emit(destination)
		_restore()
		queue_free()
		return
	FlightTicket.parked = {"destination": destination, "cells": RocketStages.lander(rocket)}
	landed.emit(destination)


func _restore() -> void:
	_vr_leave()
	if _engine:
		_engine.stop()
	world_light.call(true)
	sky_climb.call(0.0)
	take_over.call(false)
	if camera and camera.is_inside_tree():
		camera.clear_current(false)
	if _prev_camera and is_instance_valid(_prev_camera) and _prev_camera.is_inside_tree():
		_prev_camera.make_current()
	if cockpit and is_instance_valid(cockpit):
		cockpit.queue_free()
	cockpit = null


func _add_pad_smoke() -> void:
	pad_smoke = CPUParticles3D.new()
	pad_smoke.name = "PadSmoke"
	pad_smoke.layers = LAYER
	pad_smoke.amount = Fx.scaled(56)
	pad_smoke.lifetime = 3.5
	pad_smoke.local_coords = false
	pad_smoke.emitting = false
	pad_smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	pad_smoke.emission_ring_axis = Vector3.UP
	var w := body.width() * 0.5
	pad_smoke.emission_ring_radius = w + 1.0
	pad_smoke.emission_ring_inner_radius = w * 0.5
	pad_smoke.emission_ring_height = 0.5
	pad_smoke.direction = Vector3(1, 0.35, 0)
	pad_smoke.spread = 180.0
	pad_smoke.flatness = 0.7
	pad_smoke.initial_velocity_min = 4.0
	pad_smoke.initial_velocity_max = 9.0
	pad_smoke.damping_min = 1.5
	pad_smoke.damping_max = 2.5
	pad_smoke.gravity = Vector3(0, 0.8, 0)
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	box.material = Fx.material()
	pad_smoke.mesh = box
	pad_smoke.color = Color(0.9, 0.9, 0.92)
	var grow := Curve.new()
	grow.max_value = 3.0
	grow.add_point(Vector2(0.0, 0.7))
	grow.add_point(Vector2(1.0, 2.8))
	pad_smoke.scale_amount_curve = grow
	pad_smoke.position = RocketStages.pivot(rocket.cells) + Vector3(0, 0.4, 0)
	add_child(pad_smoke)


# --- The flight's own warm-up (the OpenGL renderer compiles a shader the first time it is drawn) --------------------

## Every look the flight draws (the planet and tunnel shaders, the ground, the Sun and the nebula's puffs, the flame
## and the smoke as particles), each made and drawn tiny in front of the camera in a frame of its own during the
## boarding's glide, so no shader is first compiled mid-flight (a 100+ ms frame on the emulator: DEVELOPMENT.md §8).
## In a browser and on the OpenGL renderer the census has them too (tools/flight_census.gd): the menu warms them.
func _start_prewarm() -> void:
	_prewarm = Node3D.new()
	_prewarm.name = "Prewarm"
	camera.add_child(_prewarm)
	_prewarm.position = Vector3(0, 0, -2.0)
	var dest := destination
	var looks: Array[Callable] = [FlightLooks.earth_material, func() -> Material: return FlightLooks.planet_material(dest),
		func() -> Material: return FlightLooks.tunnel_material(&"warp"),
		func() -> Material: return FlightLooks.tunnel_material(&"wormhole"), FlightLooks.ground_material,
		FlightLooks.sun_material, FlightLooks.night_material]
	for c: Color in FlightMoments.NEBULA_COLORS:
		looks.append(func() -> Material: return FlightLooks.puff_material(c))
	_prewarm_left.clear()
	for f in looks:
		_prewarm_left.append([f, false])
	for m: Material in [GolemModels.glow_material(), Fx.material()]:   # the flame and the smoke: particles, instanced
		_prewarm_left.append([func() -> Material: return m, true])
	_prewarm_frames = 0


## One look drawn a frame (a new shader's compile is a long frame of its own, never several at once).
func _prewarm_tick() -> void:
	if _prewarm == null:
		return
	_prewarm_frames += 1
	if _prewarm_left.is_empty():
		if _prewarm_frames > 2:
			_prewarm.queue_free()
			_prewarm = null
		return
	_prewarm_frames = 0
	for c in _prewarm.get_children():
		c.queue_free()
	var next: Array = _prewarm_left.pop_front()
	var look: Material = (next[0] as Callable).call()   # each look made in its own frame too
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 0.01
	if next[1]:
		var p := CPUParticles3D.new()
		quad.material = look
		p.mesh = quad
		p.amount = 1
		p.lifetime = 0.2
		p.gravity = Vector3.ZERO
		p.initial_velocity_min = 0.0
		p.initial_velocity_max = 0.0
		p.layers = LAYER | 1
		_prewarm.add_child(p)
		return
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = look
	mi.layers = LAYER | 1
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_prewarm.add_child(mi)

# --- Owner #101: the flight in a headset (P3; docs/devlog/parts/vr-rig.md) ----------------------------------------

## The seat and the capsule (VR only): the origin rides the seat (Vr.sit), the capsule's window looks ahead.
func _build_vr() -> void:
	_vr_seat = Node3D.new()
	_vr_seat.name = "VrSeat"
	add_child(_vr_seat)
	_vr_capsule = VrCapsule.new(LAYER)
	_vr_seat.add_child(_vr_capsule)
	_vr_basis = Basis()
	if cockpit:
		cockpit.analog_throttle = true   # owner #106/#108: the trigger is the throttle lever, as far as it is squeezed
		cockpit.poked.connect(_on_poked)   # owner #110: STAGE, LEGS, LIGHTS under a fingertip
	_apply_cabin_lights()


## Where VR-UI's dashboard quad goes (RocketFlight/VrSeat/VrCapsule/Dashboard; null off VR).
func vr_dashboard() -> Node3D:
	return _vr_capsule.dashboard if _vr_capsule else null


## The capsule round the seated child (null off VR).
func vr_capsule() -> VrCapsule:
	return _vr_capsule


## The seat at the inside camera's place (a seat each in a crew flight), turned like the inside camera without its
## scripted look, at most SEAT_TURN_DEGREES a second (`at_once`: the first placing); the head draws what the flight's
## camera would (its layers, space's environment, the far plane). Owner #106/#108: the way home's end (the parachute,
## the rocket's fall, home) is watched from a still spot by the pad instead, out of the capsule's round room; the
## headset's black is the flight's own fade cuts (_vr_black).
func _vr_place(delta: float, at_once: bool = false) -> void:
	var watching := _vr_watching()
	if watching:
		_vr_seat.global_transform = _vr_spot()
	else:
		var bxf := body.global_transform
		var side := (float(seat) - float(crew_size - 1) * 0.5) * SEAT_GAP
		var at := bxf * (body.seat() + Vector3(side, 0.0, 0.0))
		var off := steering.off
		var want := Basis(Vector3.UP, deg_to_rad(off.x)) * Basis(Vector3.RIGHT, deg_to_rad(-off.y))
		_vr_basis = want if at_once else VrRules.turn_toward(_vr_basis, want,
			deg_to_rad(VrRules.SEAT_TURN_DEGREES) * delta)
		_vr_seat.global_transform = Transform3D(_vr_basis, at)
	_vr_capsule.show_shell(not watching)
	Vr.view_like(camera)
	Vr.follow_now()
	if run and run.index != _vr_step:
		_vr_step = run.index
		_vr_step_t = 0.0
	else:
		_vr_step_t += delta
	var black := _vr_black(delta)
	if black >= 0.0:
		Vr.hold_fade(black)
		_vr_held = black > 0.0
	elif _vr_held:   # a dip the flight held is over: it fades in
		_vr_held = false
		Vr.fade_in()


## Owner #106/#108: the way home's end in VR (after a crash: the parachute, the rocket's fall, home).
func _vr_watching() -> bool:
	return run != null and run.crashed() and run.phase() in [FlightPlan.HOME_CHUTE, FlightPlan.WRECK, FlightPlan.HOME]


## Where the child watches the way home's end from: a still spot on the ground by the pad, where the flat game's still
## shot of the pad looks from (the capsule coming down beside the pad, the rocket falling on its other side), an eye's
## height over the ground, level and facing the pad (the child's own head looks up at the parachute); a crew a seat's
## gap apart.
func _vr_spot() -> Transform3D:
	var pad := global_position + body.pivot
	var size := clampf(body.height() / 12.0, 0.45, 3.0)
	var at := pad + Vector3(6.0, 0.0, 34.0) * maxf(size, 1.0)
	var g: float = ground_at.call(at.x, at.z)
	at.y = (g if is_finite(g) else pad.y) + VR_SPOT_EYE
	var b := Basis(Vector3.UP, atan2(at.x - pad.x, at.z - pad.z))
	return Transform3D(b, at + b.x * (float(seat) - float(crew_size - 1) * 0.5) * SEAT_GAP)


## How black the flight holds the headset now (-1: it holds nothing). A practice's next try dips to black on the ground
## (the lander back at the top is a jump). After a crash the way home is fade cuts, never one long black: the crash dims
## to black (the rescue rockets lift it away), the capsule heading home fades in (seen from the seat) and dips to black
## at its end, the re-entry fades in and dips, and the spot by the pad fades in; the last step fades as the flat screen
## does.
func _vr_black(delta: float) -> float:
	if run == null:
		return -1.0
	var own := _vr_cuts(delta)
	# (the clouds' thickest, where the world and the space set change places: a headset's white-out is softer,
	# FlightShots.VR_CLOUD, so the change itself is a dip to black)
	var cloud := smoothstep(VR_CLOUD_DARK, 1.0, float(pose.get("cloud", 0.0)) / FlightShots.VR_CLOUD)
	return maxf(own, cloud) if cloud > 0.0 else own


func _vr_cuts(delta: float) -> float:
	var phase := run.phase()
	var retry := phase == FlightPlan.DESCENT and run.descent != null and run.descent.state == FlightDescent.CRASHED \
		and not run.crashed()
	_vr_retry_t = _vr_retry_t + delta if retry else 0.0
	if retry:
		return smoothstep(0.35, 0.9, _vr_retry_t / FlightRun.RETRY_SECONDS)
	var q := run.progress()
	if run.crashed():
		match phase:
			FlightPlan.CRASH:
				return smoothstep(0.4, 1.0, q)
			FlightPlan.ESCAPE, FlightPlan.HOME_ENTRY:   # (the rocket turns round at once between the two: a cut)
				return maxf(_vr_cut_in(), smoothstep(1.0 - VR_DIP / maxf(float(run.step().get("seconds", 1.0)), VR_DIP),
					1.0, q))
			FlightPlan.HOME_CHUTE:
				return _vr_cut_in()
	if run.index == run.steps.size() - 1 and q > FADE_FROM:   # the screen's fade before `landed` (or `crashed`)
		return (q - FADE_FROM) / (1.0 - FADE_FROM)
	return 0.0 if run.crashed() and phase != FlightPlan.DESCENT else -1.0


## A cut's other side: black on the step's first frame, then it fades in.
func _vr_cut_in() -> float:
	return clampf(1.0 - _vr_step_t / VrRules.FADE_IN, 0.0, 1.0)


## Owner #106/#108: a buzz in both hands (VR only; the touchdown, the crash, the rocket hitting the ground). Owner #110:
## `pulse` [amplitude, seconds, Hz?] (no Hz: the runtime's own), in `sides` only; logged (vr_haptic_log).
func _vr_buzz(pulse: Array, sides: Array = [VrRules.LEFT, VrRules.RIGHT]) -> void:
	if _vr_seat == null:
		return
	var hz := float(pulse[2]) if pulse.size() > 2 else 0.0
	for side: StringName in sides:
		Vr.haptic(side, float(pulse[0]), float(pulse[1]), hz)
	vr_haptic_log.append([run.time if run else 0.0, float(pulse[0]), float(pulse[1]), hz])
	if vr_haptic_log.size() > HAPTIC_LOG:
		vr_haptic_log.pop_front()

# --- Owner #110 (VR round 4, idea 8): the cockpit you touch ---------------------------------------------------------

## The fingertips on the dashboard (VR): a poke in through the panel's face over a button presses it; the closest one
## over a button makes it glow; the hand's picture stops with its fingertip on the panel (never through it).
func _vr_touch() -> void:
	var dash := vr_dashboard()
	if dash == null or cockpit == null or not cockpit.dashboard_mode:
		return
	var rects := cockpit.poke_rects()
	var band := FlightCockpit.dashboard_rect(cockpit.size)
	band.position += cockpit.get_global_rect().position
	var to_dash := dash.global_transform.affine_inverse()
	var hover := &""
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var tip := CockpitTouchRules.fingertip(Vr.hand_grip(side), side, Vr.trigger(side), Vr.world_scale())
		var local := to_dash * tip
		var at := CockpitTouchRules.to_canvas(local, band)
		var on_panel := band.grow(24.0).has_point(at)
		if not _pokes.has(side):
			_pokes[side] = {}
		var pressed := CockpitTouchRules.poke(_pokes[side], local.z if on_panel else 1.0, at, rects)
		if pressed != &"":
			_poking_side = side
			cockpit.poke(pressed)
		if hover == &"" and on_panel:
			hover = CockpitTouchRules.hover(local.z, at, rects)
		var model := Vr.hand_models.get(side) as VrHandModel
		if model != null and on_panel and local.z < 0.0 and local.z > -CockpitTouchRules.BEHIND:
			model.global_position += dash.global_basis.z * -local.z   # touch limiting: the picture stops at the panel
	cockpit.set_poke_hover(hover)


## A dashboard button was poked: STAGE or LEGS when the flight waits for it (never a crew member's: the pilot flies)
## with a click in that hand, else a soft click; LIGHTS turns the cabin lights off or on.
func _on_poked(button: StringName) -> void:
	var hand := [_poking_side]
	if button == CockpitTouchRules.LIGHTS:
		cabin_lights = not cabin_lights
		_apply_cabin_lights()
		_vr_buzz(CockpitTouchRules.CLICK, hand)
		return
	if not crew_follow and run != null and run.waiting_for() == button and run.act(button):
		_vr_buzz(CockpitTouchRules.CLICK, hand)
	else:
		_vr_buzz(CockpitTouchRules.DARK, hand)


## The capsule's cabin lights: on, its walls and the window's warm ring as VrCapsule draws them; off, dark.
func _apply_cabin_lights() -> void:
	var mat := _vr_capsule.material_override as ShaderMaterial if _vr_capsule else null
	if mat:
		mat.set_shader_parameter(&"shell", CABIN_ON if cabin_lights else CABIN_OFF)
		mat.set_shader_parameter(&"rim", RIM_ON if cabin_lights else RIM_OFF)
	if cockpit:
		cockpit.set_lights(cabin_lights)


## The engines' rumble in both hands while they burn: a short pulse every RUMBLE_EVERY, as strong as the fire.
func _vr_rumble(delta: float) -> void:
	_rumble_t -= delta
	var amp := CockpitTouchRules.rumble(float(pose.get("fire", 0.0)))
	if amp <= 0.0:
		_rumble_t = 0.0   # the next burn starts with a pulse
		return
	if _rumble_t <= 0.0:
		_rumble_t = CockpitTouchRules.RUMBLE_EVERY
		_vr_buzz([amp, CockpitTouchRules.RUMBLE_PULSE, CockpitTouchRules.RUMBLE_HZ])


## The flight is over (landed, aborted, freed): the head goes back to where it was, drawing the world as before.
func _vr_leave() -> void:
	if _vr_seat == null:
		return
	Vr.release(_vr_seat)
	Vr.view_default()
