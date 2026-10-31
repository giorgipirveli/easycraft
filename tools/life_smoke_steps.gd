extends Node
## The steps of tools/life_smoke.gd (owner #112): for every Experience and track, a run per mode ("flat": the normal
## try with fingers; "expert": the Expert try with fingers; "vr": the normal try in a simulated headset with hands, the
## head and the laser), each through the Life screen: TRY IT, the before-check, the practice room played to its end, the
## "name it" card, the after-check and the result. Each run checks: the room finished with no hint (By myself; Expert
## on the Expert try), the Passport's stamps saved, the Experience's gold paid once, the screen it came from shown again,
## the device's measurements written. Time runs SPEED times faster (the room's clocks, pauses and beats all follow it).
## Life L2: the looks (LOOK buttons; the head's turn in VR), the crossings (only when the room's traffic says it is safe:
## a smoke child never steps out in front of a car), rubbing, pouring to the line, balloon breathing, the pedal's needle,
## the feelings, and the hand's own path for the knife, the whisk and the cloth.
## Life L3a (owner #118): the debrief page after an emergency Experience (NEXT); and two more modes, "mistake" (flat) and
## "mistake_vr", run only where a track has safe mistakes to try: the child first tries each wrong way once (the try's
## target pressed or pointed at, STAND UP on the ice or the head coming up in VR, the mistake's picture), the room must
## freeze, GOT IT goes on, then the child does it right. Each such run checks that every mistake froze the room and that
## none cost a hint (the By myself stamp).
## Life L3b (owner #118): an "unsafe" wrong way (the crossing at the wrong moment) waits for a car or the red man, then
## presses (flat) or pulls the trigger (VR); be a tree in VR is the head tipped down and the arms folded in, still.
## Life L3c (owner #112, #118): in VR a held device (Online City's play tablet) must stay in the off hand every frame it is
## held (the other hand presses its buttons), and a run that tries no wrong way must never freeze (Home Helper's chores
## have no safe mistakes; a kind miss is never a freeze).

const SPEED := 5.0
const RUN_LIMIT := 60.0   # real seconds a run may take
const MEASURE := "user://life_smoke_measure.json"

var _plan: Array = []
var _results: Array[String] = []
var _fails := 0
var _run := {}
var _screen: LifeScreen
var _layer: CanvasLayer
var _profile: ProfileData
var _t := 0.0
var _phase := ""
var _down := false
var _down_step := -1
var _last_push := -INF
var _push_phase := 0
var _sweep_t := 0.0
var _sweep_side := 1.0
var _grip := false
var _trigger := false
## Life L3a's mistake modes: the step index being tried the wrong way, the last one tried, frames into the try.
var _trying := -1
var _tried := -1
var _try_frames := 0
var _freezes := 0
## Life L3c: frames a held device was checked in VR, frames it was away from the off hand, freezes with no wrong way tried.
var _held_frames := 0
var _held_far := 0
var _stray_freezes := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var only := ""
	var modes: Array[String] = ["flat", "expert", "vr", "mistake", "mistake_vr"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		elif a.begins_with("--modes="):
			modes.assign(a.trim_prefix("--modes=").split(","))
	for id in LifeExperience.IDS:
		if id == RealBuilder.ID:
			continue   # its own smoke (tools/real_builder_smoke.gd): the real motions (owner #116)
		for track in LifeData.TRACKS:
			if only != "" and not (only.split(",") as Array).any(func(o: String) -> bool:
					return o == id or o == LifeExperience.skill_id(id, track)):
				continue   # --only= a skill (fire_escape.middle), an Experience (kitchen), or several, comma-separated
			for mode in modes:
				if mode.begins_with("mistake") and _mistakes_in(id, track) == 0:
					continue   # Life L3a: only a track with safe mistakes to try
				_plan.append({"experience": id, "track": track, "mode": mode})
	if FileAccess.file_exists(MEASURE):
		DirAccess.remove_absolute(MEASURE)
	Engine.time_scale = SPEED
	print("LIFE_SMOKE start runs=%d speed=%.0f" % [_plan.size(), SPEED])
	_next_run()


## Life L3a: how many safe mistakes a normal try of the skill lets the child try.
func _mistakes_in(id: String, track: String, seed: int = 1) -> int:
	var n := 0
	for s in LifeExperience.steps(id, track, false, seed, "ge"):
		if LifeCheck.tries_mistake(s):
			n += 1
	return n


func _next_run() -> void:
	if _plan.is_empty():
		_finish()
		return
	_run = _plan.pop_front()
	_run.start = Time.get_ticks_msec()
	_run.seed = 11 + _plan.size()
	_trying = -1
	_tried = -1
	_try_frames = 0
	_freezes = 0
	_held_frames = 0
	_held_far = 0
	_stray_freezes = 0
	var vr := str(_run.mode) in ["vr", "mistake_vr"]
	if vr != Vr.active():
		Vr.simulate(vr)
	_profile = ProfileData.new()
	_profile.life.track = str(_run.track)
	_layer = CanvasLayer.new()
	_layer.name = "SmokeLayer"
	add_child(_layer)
	_screen = LifeScreen.new()
	_screen.profile = _profile
	_screen.save_profile = func() -> void: pass
	_screen.today = func() -> int: return 20_000
	_screen.next_seed = func() -> int: return int(_run.seed)
	_screen.locale = "ka_GE"
	_screen.measure = LifeMeasure.new(MEASURE)
	_layer.add_child(_screen)
	_phase = "start"
	_t = 0.0
	_down = false
	_down_step = -1
	_last_push = -INF


func _process(delta: float) -> void:
	if _run.is_empty() or _screen == null:
		return
	_t += delta / SPEED
	if _t > RUN_LIMIT:
		var where := str(_screen.host.run.current().get("id", "")) if is_instance_valid(_screen.host) and _screen.host.run else ""
		var state := str(_screen.host.run.state) if is_instance_valid(_screen.host) and _screen.host.run else ""
		if is_instance_valid(_screen.host) and _screen.host.room is StreetRoom:
			var cars: Array = []
			for c: Dictionary in (_screen.host.room as StreetRoom).traffic.cars:
				cars.append("x %.1f v %.1f hold %.1f %s" % [float(c.x), float(c.v), float(c.hold), c.why])
			state += " cars %s" % [cars]
		if Vr.active() and is_instance_valid(_screen.host):
			var ray := Vr.pointer_ray()
			var h := _screen.host
			var hits: Array = []
			if not ray.is_empty():
				for tn in h.room.target_names():
					var d := LifeReach.ray_hit(ray[0], ray[1], h.room.target_position(tn), h.room.target_radius(tn))
					if d >= 0.0:
						hits.append("%s %.1f" % [tn, d])
			state += " ui_wants_pointer %s ray %s hits %s" % [Vr.ui_wants_pointer(), ray, hits]
		_end_run(false, "timeout on page %s step %s, its state %s" % [_screen.page, where, state])
		return
	match _phase:
		"start":
			if not _screen.is_node_ready():
				return
			_screen.start_experience(str(_run.experience), str(_run.track), str(_run.mode) == "expert")
			_phase = "flow"
		"flow":
			_flow()


func _flow() -> void:
	match _screen.page:
		LifeScreen.CHECK:
			var q: Dictionary = _screen.check_questions[_screen.check_index]
			_screen.answer_check(int(q.answer))
		LifeScreen.ROOM:
			var host := _screen.host
			if not is_instance_valid(host) or host.closed or host.run == null:
				return
			if host.vr:
				_drive_vr(host)
			else:
				_drive_flat(host)
		LifeScreen.CARD, LifeScreen.DEBRIEF:   # Life L3a: the calm debrief after an emergency practice, then the card
			var next := _button("NEXT")
			if next:
				next.pressed.emit()
		LifeScreen.RESULT:
			_check_result()
		LifeScreen.CALM:
			_end_run(false, "the run stopped")


func _button(text: String) -> Button:
	for b in _screen.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


# --- Flat: a finger on the targets' screen points ------------------------------------------------------------------

func _drive_flat(host: LifeRoomHost) -> void:
	if host.run.finished:
		return
	if host.frozen:   # Life L3a: a safe mistake's freeze: GOT IT
		_lift(host)
		_frozen_seen()
		host.hud.mistake_ok.emit()
		return
	if host._pause > 0.0 or host.paused:
		_lift(host)
		return
	var step := host.run.current()
	if _down_step != host.run.index:
		_lift(host)
	if _down and step.has("target") and host._finger_target != str(step.target) \
			and str(step.kind) in ["hold", "hands", "pour", "breathe", "steady", "rub", "sweep"]:
		_lift(host)   # it went down while the view still glided there: again, on the thing
	var kind := str(step.kind)
	var wants_low := bool(step.get("low", false)) or (kind == "action" and str(step.get("action", "")) == "low")
	if wants_low and not host.low_on:
		host.hud.low_button.button_pressed = true
	if str(_run.mode) == "mistake" and LifeCheck.tries_mistake(step) and _tried != host.run.index:
		_try_wrong_flat(host, step)   # Life L3a: the wrong way first, safely
		return
	match kind:
		"info":
			host.hud.ok.emit()
		"choose", "count":
			host.hud.answered.emit(int(step.answer))
		"feel":
			host.hud.answered.emit(0)
		"look":
			var sides: Array = step.get("sides", [])
			if int(host.run.state.get("i", 0)) < sides.size():
				host.hud.look_pressed.emit(str(sides[int(host.run.state.i)]))
		"cross":
			if _down:
				_lift(host)
			elif host.room.safe_now(step):
				_press(host, str(step.target))
		"rub":
			if not _down:
				_press(host, str(step.target))
			else:
				_sweep_side = -_sweep_side
				host.finger_move(host.screen_of(str(step.target)) + Vector2(24.0 * _sweep_side, 0))
		"pour", "breathe", "steady":
			var want := _wants_hold(step, host.run.state)
			if want and not _down:
				_press(host, str(step.target))
			elif not want and _down:
				_lift(host)
		"action":
			if str(step.action) != "low":
				host.hud.action_pressed.emit(str(step.action))
		"hold", "hands":
			if not _down:
				_press(host, str(step.target))
		"rhythm":
			if _down:
				_lift(host)
			elif host.run.clock - _last_push >= LifeBeat.BEAT_SECONDS:
				_last_push = host.run.clock
				_press(host, str(step.target))
		"sweep":
			if not _down:
				_press(host, str(step.target))
				_sweep_t = 0.0
			else:
				_sweep_t += get_process_delta_time()
				if _sweep_t >= 0.15:
					_sweep_t = 0.0
					_sweep_side = -_sweep_side
				host.finger_move(host.screen_of(str(step.target)) + Vector2(70.0 * _sweep_side, 0))
		"timelapse":
			pass
		_:
			if _down:
				_lift(host)
			else:
				var next := host.run.next_targets()
				if not next.is_empty():
					_press(host, next[0])


## Life L3a: the room froze on the wrong way tried (counted once per try).
func _frozen_seen() -> void:
	if _trying < 0:
		_stray_freezes += 1   # Life L3c: frozen though the child tried no wrong way
	if _trying >= 0:
		_freezes += 1
		_tried = _trying
		_trying = -1


## Life L3a, flat: the step's wrong way: its picture, its body action's button (STAND UP), or its target tapped.
func _try_wrong_flat(host: LifeRoomHost, step: Dictionary) -> void:
	_trying = host.run.index
	var m: Dictionary = step.safe_mistake
	var try := str(m.get("try", ""))
	if str(step.kind) in ["choose", "count"]:
		var choices: Array = step.choices
		for i in choices.size():
			if bool((choices[i] as Dictionary).get("mistake", false)):
				host.hud.answered.emit(i)
				return
	elif try.begins_with("action:"):
		host.hud.action_pressed.emit(try.trim_prefix("action:"))
	elif try == LifeCheck.UNSAFE:   # Life L3b: the right target at the wrong moment (a car coming, the red man)
		if _down:
			_lift(host)
		elif not host.room.safe_now(step):
			_press(host, str(step.target))
	elif _down:
		_lift(host)
	else:
		_press(host, try)


## Life L3a, VR: the wrong way with the body: the head coming up on the ice (after a moment low), the mistake's picture,
## or a hand on its target, squeezing.
func _try_wrong_vr(host: LifeRoomHost, step: Dictionary, rest_l: Vector3, rest_r: Vector3) -> void:
	if _trying != host.run.index:
		_try_frames = 0
	_trying = host.run.index
	_try_frames += 1
	var try := str((step.safe_mistake as Dictionary).get("try", ""))
	_rest(rest_l, rest_r)
	if str(step.kind) in ["choose", "count"]:
		var choices: Array = step.choices
		for i in choices.size():
			if bool((choices[i] as Dictionary).get("mistake", false)):
				host.hud.answered.emit(i)
		_vr_inputs(false, false)
		return
	if try == "action:stand":
		if _try_frames > 8:   # low a moment first (as the child lay on the ice), then the head comes up
			_head(host.stand.global_position, host.stand.global_basis)
		_vr_inputs(false, false)
		return
	if try.begins_with("action:"):
		host.hud.action_pressed.emit(try.trim_prefix("action:"))
		return
	if try == LifeCheck.UNSAFE:   # Life L3b: the trigger (the crossing) while a car comes or the man is red
		_vr_inputs(false, not host.room.safe_now(step) and not _trigger)
		return
	_hand(VrRules.RIGHT, host.room.target_position(try))
	_vr_inputs(not _grip, false)


## Whether the finger (or the hand, or the trigger) should be held now: pour to the line, breathe in for long enough
## and out for long enough, keep the needle in its band (LifeAuto's own rules).
func _wants_hold(step: Dictionary, state: Dictionary) -> bool:
	match str(step.kind):
		"pour":
			return float(state.get("level", 0.0)) < float(step.get("want", 0.5))
		"breathe":
			var phase := str(state.get("phase", "rest"))
			if phase == "out":
				return float(state.get("t", 0.0)) >= float(step.get("out", 3.0)) + 0.1
			return phase == "rest" or (phase == "in" and float(state.get("t", 0.0)) < float(step.get("in", 3.0)) + 0.2)
		"steady":
			return float(state.get("value", 0.0)) < (float(step.get("lo", 0.0)) + float(step.get("hi", 0.0))) * 0.5
	return false


func _press(host: LifeRoomHost, target: String) -> void:
	host.finger_down(host.screen_of(target))
	_down = true
	_down_step = host.run.index


func _lift(host: LifeRoomHost) -> void:
	if _down:
		host.finger_up()
	_down = false


# --- VR: simulated hands, head and laser ---------------------------------------------------------------------------

func _to_play(world: Transform3D) -> Transform3D:
	return Vr.rig.global_transform.affine_inverse() * world


func _hand(side: StringName, at: Vector3, look: Vector3 = Vector3.INF) -> void:
	var b := Basis()
	if look.is_finite() and (look - at).length() > 0.01:
		b = Basis.looking_at((look - at).normalized(), Vector3.UP if absf((look - at).normalized().y) < 0.98 else Vector3.BACK)
	Vr.sim_hand(side, _to_play(Transform3D(b, at)))


func _head(world: Vector3, basis: Basis = Basis()) -> void:
	Vr.sim_head(_to_play(Transform3D(basis, world)))


func _drive_vr(host: LifeRoomHost) -> void:
	if host.run.finished:
		return
	if host.room.holding and is_instance_valid(host.room.held):   # Life L3c: the tablet stays in the off hand
		var off: StringName = VrRules.LEFT if Vr.pointing_hand() == VrRules.RIGHT else VrRules.RIGHT
		_held_frames += 1
		if host.room.held.global_position.distance_to(Vr.hand_grip(off).origin) > 0.3:
			_held_far += 1
	if host.frozen:   # Life L3a: GOT IT (the A button's or the panel's)
		_vr_inputs(false, false)
		_frozen_seen()
		host.hud.mistake_ok.emit()
		return
	var step := host.run.current()
	var kind := str(step.kind)
	var stand := host.stand.global_position
	var low := _vr_low(host)
	var head := stand + Vector3(0, -0.45 if low else 0.0, 0)
	var head_basis := Basis()
	if kind == "look":   # the head turns the way to look next
		var sides: Array = step.get("sides", [])
		var i := int(host.run.state.get("i", 0))
		if i < sides.size():
			head_basis = host.stand.global_basis * Basis(Vector3.UP, deg_to_rad(50.0) * (1.0 if str(sides[i]) == "left" else -1.0))
	if kind == "action" and str(step.action) == "tree":   # Life L3b: be a tree: looking down at the feet
		head_basis = host.stand.global_basis * Basis(Vector3.RIGHT, -0.7)
	if kind == "action" and str(step.action) == "roll":
		head = stand + Vector3(0, -0.45, 0) + host.stand.global_basis.x * (0.2 if fmod(host.run.clock, 0.6) < 0.3 else -0.2)
	if kind == "hold" and str(step.get("reach", "")) == "head":
		head = host.room.target_position(str(step.target)) + Vector3(0, 0.2, 0.15)
	_head(head, head_basis)
	var rest_l := head + host.stand.global_basis * Vector3(-0.2, -0.4, -0.3)
	var rest_r := head + host.stand.global_basis * Vector3(0.2, -0.4, -0.3)
	if host._pause > 0.0 or host.paused:
		_vr_inputs(false, false)
		_hand(VrRules.LEFT, rest_l)
		_hand(VrRules.RIGHT, rest_r)
		return
	if str(_run.mode) == "mistake_vr" and LifeCheck.tries_mistake(step) and _tried != host.run.index:
		_try_wrong_vr(host, step, rest_l, rest_r)   # Life L3a: the wrong way first, safely
		return
	match kind:
		"info":
			host.hud.ok.emit()
			_rest(rest_l, rest_r)
		"choose", "count":
			host.hud.answered.emit(int(step.answer))
			_rest(rest_l, rest_r)
		"feel":
			host.hud.answered.emit(0)
			_rest(rest_l, rest_r)
		"look":
			_rest(rest_l, rest_r)
			_vr_inputs(false, false)
		"cross":   # the trigger when it is safe (crossing's choice is when: the way is straight across)
			_rest(rest_l, rest_r)
			_vr_inputs(false, host.room.safe_now(step) and not _trigger)
		"rub":
			var c := host.room.target_position(str(step.target))
			_sweep_side = -_sweep_side
			_hand(VrRules.LEFT, c + host.stand.global_basis.x * (-0.04 + 0.05 * _sweep_side))
			_hand(VrRules.RIGHT, c + host.stand.global_basis.x * (0.04 - 0.05 * _sweep_side))
			_vr_inputs(false, false)
		"pour":
			var c := host.room.target_position(str(step.target))
			var tilt := Basis(Vector3.FORWARD, deg_to_rad(70.0)) if str(step.get("motion", "")) == "pour" else Basis()
			Vr.sim_hand(VrRules.RIGHT, _to_play(Transform3D(tilt, c)))
			_hand(VrRules.LEFT, rest_l)
			_vr_inputs(_wants_hold(step, host.run.state), false)
		"breathe":
			var up := _wants_hold(step, host.run.state)
			var fwd := -host.stand.global_basis.z * 0.3
			_hand(VrRules.LEFT, stand + fwd + Vector3(-0.1, -0.3 if up else -0.7, 0))
			_hand(VrRules.RIGHT, stand + fwd + Vector3(0.1, -0.3 if up else -0.7, 0))
			_vr_inputs(false, false)
		"steady":
			_rest(rest_l, rest_r)
			_vr_inputs(false, _wants_hold(step, host.run.state))
		"action":
			match str(step.action):
				"cover":
					_hand(VrRules.LEFT, head + host.stand.global_basis * Vector3(-0.07, 0, -0.12))
					_hand(VrRules.RIGHT, head + host.stand.global_basis * Vector3(0.07, 0, -0.12))
				"tree":   # Life L3b: the arms folded in, close to the body
					_hand(VrRules.LEFT, head + host.stand.global_basis * Vector3(-0.12, -0.55, -0.12))
					_hand(VrRules.RIGHT, head + host.stand.global_basis * Vector3(0.12, -0.55, -0.12))
				_:
					_rest(rest_l, rest_r)
			_vr_inputs(false, false)
		"hold":
			if str(step.get("reach", "")) == "trigger":   # the practice car's pedal: the trigger itself
				_rest(rest_l, rest_r)
				_vr_inputs(false, true)
			else:
				_hand(VrRules.RIGHT, host.room.target_position(str(step.target)))
				_hand(VrRules.LEFT, rest_l)
				_vr_inputs(true, false)
		"hands":
			var c := host.room.target_position(str(step.target))
			_hand(VrRules.LEFT, c + Vector3(-0.03, 0, 0))
			_hand(VrRules.RIGHT, c + Vector3(0.03, 0.02, 0))
			_vr_inputs(false, false)
		"rhythm":
			var c := host.room.target_position(str(step.target))
			# one push per beat: down 5 cm, then back up (the Pusher reads the hands' height)
			var since := host.run.clock - _last_push
			var dy := 0.0
			if since >= LifeBeat.BEAT_SECONDS:
				_last_push = host.run.clock
			elif since < LifeBeat.BEAT_SECONDS * 0.45:
				dy = -0.05
			_hand(VrRules.LEFT, c + Vector3(-0.03, dy, 0))
			_hand(VrRules.RIGHT, c + Vector3(0.03, dy + 0.02, 0))
			_vr_inputs(false, false)
		"go", "point":
			var t := host.room.target_position(str(step.target))
			var from := head + host.stand.global_basis * Vector3(0.2, -0.3, -0.2)
			_hand(Vr.pointing_hand(), from, t)
			_vr_inputs(false, not _trigger if kind == "go" else true)
		"sweep":
			var t := host.room.target_position(str(step.target))
			_sweep_t += get_process_delta_time()
			if _sweep_t >= 0.15:
				_sweep_t = 0.0
				_sweep_side = -_sweep_side
			if str(step.get("reach", "")) == "hand":   # the knife, the whisk, the cloth: the hand's own path
				_hand(VrRules.RIGHT, t + host.stand.global_basis.x * 0.1 * _sweep_side)
				_hand(VrRules.LEFT, rest_l)
				_vr_inputs(true, false)
			else:
				var from := head + host.stand.global_basis * Vector3(0.2, -0.3, -0.2)
				_hand(Vr.pointing_hand(), from, t + host.stand.global_basis.x * 0.22 * _sweep_side)
				_vr_inputs(false, true)
		"timelapse":
			_rest(rest_l, rest_r)
			_vr_inputs(false, false)
		_:
			# a press: the hand on the next thing, squeezing on one frame and letting go on the next
			var next := host.run.next_targets()
			if next.is_empty():
				return
			if str(step.get("reach", "")) == "trigger":   # a pedal pressed: the trigger, on one frame and off the next
				_rest(rest_l, rest_r)
				_vr_inputs(false, not _trigger)
				return
			_hand(VrRules.RIGHT, host.room.target_position(next[0]))
			_hand(VrRules.LEFT, rest_l)
			_vr_inputs(not _grip, false)


## Once a step asked the child to get low, stay low (crouched) until a step says "stand".
var _was_low := false


func _vr_low(host: LifeRoomHost) -> bool:
	var step := host.run.current()
	if bool(step.get("stand", false)):
		_was_low = false
	elif bool(step.get("low", false)) or (str(step.kind) == "action" and str(step.get("action", "")) == "low"):
		_was_low = true
	return _was_low


func _rest(l: Vector3, r: Vector3) -> void:
	_hand(VrRules.LEFT, l)
	_hand(VrRules.RIGHT, r)


func _vr_inputs(grip: bool, trigger: bool) -> void:
	_grip = grip
	_trigger = trigger
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0 if grip else 0.0)
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 1.0 if trigger else 0.0)


# --- The result ----------------------------------------------------------------------------------------------------

func _check_result() -> void:
	var skill := LifeExperience.skill_id(str(_run.experience), str(_run.track))
	var p := _profile.life.skill(skill)
	var want := LifeData.SELF | (LifeData.EXPERT if str(_run.mode) == "expert" else 0)
	var problems: Array[String] = []
	var outcome: Dictionary = _screen.last.get("outcome", {})
	if int(outcome.get("hints", -1)) != 0:
		problems.append("%d hints" % int(outcome.get("hints", -1)))
	if int(p.s) & want != want:
		problems.append("stamps %d, wanted %d" % [int(p.s), want])
	var shop_gold := int(_profile.life.success.shop.get("t", 0))   # owner #115 (S3): the shop's customers pay real gold
	if _profile.survivor_gold != ProfileData.START_GOLD + LifePassport.GOLD + _answer_gold() + shop_gold:
		problems.append("gold %d" % _profile.survivor_gold)
	if str(_run.experience) == "my_shop" and shop_gold <= 0:
		problems.append("the shop's customers paid no gold")
	if not _layer.visible:
		problems.append("the screen stayed hidden")
	if int(p.b) < 0 or int(p.l) < 0:
		problems.append("the checks were not kept")
	if _screen.measure.steps.is_empty() or not FileAccess.file_exists(MEASURE):
		problems.append("no measurements")
	if str(_run.mode).begins_with("mistake"):   # Life L3a: every wrong way tried froze the room, and cost no hint
		var want_m := _mistakes_in(str(_run.experience), str(_run.track), int(_run.seed))
		if _freezes != want_m or int(outcome.get("mistakes", -1)) != want_m:
			problems.append("%d freezes and %d mistakes counted, wanted %d" % [_freezes, int(outcome.get("mistakes", -1)),
				want_m])
	if _held_far > 0:   # Life L3c
		problems.append("the held tablet left the off hand on %d of %d frames" % [_held_far, _held_frames])
	if _stray_freezes > 0:
		problems.append("%d freezes with no wrong way tried" % _stray_freezes)
	if str(_run.mode) == "vr" and str(_run.experience) == "online_city" and _held_frames == 0:
		problems.append("the play tablet was never held")
	_end_run(problems.is_empty(), ", ".join(problems))


func _answer_gold() -> int:
	return 0   # no practice round in a smoke run: only the Experience's gold


func _end_run(ok: bool, why: String) -> void:
	var took := (Time.get_ticks_msec() - int(_run.start)) / 1000.0
	var line := "LIFE_SMOKE %s %s.%s %s %.1fs%s" % ["PASS" if ok else "FAIL", _run.experience, _run.track, _run.mode, took,
		"" if ok else " (" + why + ")"]
	print(line)
	_results.append(line)
	if not ok:
		_fails += 1
	if is_instance_valid(_screen) and is_instance_valid(_screen.host):
		_screen.host.close()
	if is_instance_valid(_layer):
		_layer.queue_free()
	_screen = null
	_layer = null
	_run = {}
	_grip = false
	_trigger = false
	_was_low = false
	_next_run.call_deferred()


func _finish() -> void:
	Engine.time_scale = 1.0
	Vr.simulate(false)
	Audio.stop_all()
	print("LIFE_SMOKE done runs=%d failed=%d" % [_results.size(), _fails])
	get_tree().quit(0 if _fails == 0 else 1)
