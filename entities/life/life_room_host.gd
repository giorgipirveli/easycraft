class_name LifeRoomHost
extends Node
## Owner #112, #113 (docs/design/life-skills.md §3, §4, §10): runs one try of an Experience in its practice room, flat
## or in VR, and says how it went (`finished`) or that the child stopped for now (`stopped`).
##
## The room is its own small space far above the menu's world (ROOM_ORIGIN, its own sky and light: the head and the
## flat camera draw it with the room's environment). While it shows, the screen it was opened from is hidden (its
## CanvasLayer), and the HUD (LifeRoomHud) is routed like every layer (UiLayers.route: in VR on the panel).
## - Flat: the room's camera glides between the steps' views (a jump with Reduce motion); a finger on the tap area picks
##   the nearest thing under it (LifeReach.screen_pick: never smaller than a fingertip); a held finger holds; a drag
##   across sweeps; GET LOW lowers the view.
## - VR (Vr.active()): the child stands at the view's spot (Vr.anchor: a jump to another spot blinks); "the hand is here
##   and squeezing" (a hand within reach of a thing with its grip or trigger squeezed) presses and holds; the laser and
##   the trigger press things further away and aim; the head's height is "low"; both hands on the chest push (LifeBeat's
##   Pusher), and the controllers buzz on each good push; hands at the face cover it; the head side to side while low
##   rolls; the ghost hands show the step.
## Every frame becomes one LifeCheck sample for the run (LifeRun): the coach shows after 10 s without progress, SHOW ME
## and a miss show it too; the one next thing glows. I NEED A BREAK holds everything; STOP FOR NOW ends calmly.
## Life L2 (owner #112): flat, a LOOK swipe (or LOOK LEFT / LOOK RIGHT) looks that way and the view turns there and back;
## a finger moving on the target rubs; a finger held pours, breathes in and presses a pedal. VR: the head's turn looks
## (look_yaw); both hands moving at the target rub; the hand at a jug, squeezing and tilted, pours; the hands rising
## breathe in (or a squeeze, for a child who sits still); a "trigger" reach is the trigger itself (the practice car's
## pedals at the child's feet; crossing the road: the choice is when, the way is straight across); a "hand" reach sweep follows the hand's own path across the target (a knife, a whisk, a
## cloth). A cross step asks the room whether it is safe now (its traffic); a miss plays the step's "on_miss" event.
## Life L3a (owner #118, design §14): a step's safe mistake tried (LifeCheck's `mistake`) freezes the room (LifeRoom.freeze:
## its own time and tweens stop), the scene softens over FREEZE_FADE (flat: the HUD's soft veil; VR: the view dims to
## MISTAKE_DIM, under the panel), the room shows its gentle picture (show_mistake) and the HUD the coach's card with the
## calm why and the right way; GOT IT (unfreeze) takes it all away, the right thing glows and the coach shows it. The
## room's time on a danger step is `danger_scale` (LifeRun.time_scale: slow on the first tries, real on the Expert try
## and with "more real"); a step with `glow: false` never glows (the coach still shows on SHOW ME).
## Tests drive it with finger_down/up at a target's screen point (screen_of) or with Vr.simulate's hands.

signal finished(outcome: Dictionary)
signal stopped(outcome: Dictionary)

const ROOM_ORIGIN := Vector3(0, 1500, 0)
## Every open room host is in this group (the menu's Android Back asks it first: owner #112, L1's follow-up).
const GROUP := &"life_room_host"
const GLIDE := 0.6
## The pause after a step is done (its kind words show) before the next one starts.
const DONE_PAUSE := 1.3
const SQUEEZE_ON := 0.6
const SQUEEZE_OFF := 0.35
## The head is near a thing (the breathing check: "the head counts the breaths' check") within this much of its radius.
const HEAD_REACH := 0.3
const STILL_SECONDS := 0.8
const STILL_MOVE := 0.06
const LASER := 8.0   # the laser reaches across the market square and the practice street (Life L2)
## Life L2: a flat look turns the view this far (rad), holds it, and turns back.
const LOOK_TURN := 1.15
const LOOK_HOLD := 0.9
## A swipe this long (px), mostly sideways, is a look that way.
const SWIPE_PX := 110.0
## A finger that moved within this long (s) is rubbing; hands moving faster than RUB_SPEED (m/s) at the target rub.
const RUB_GAP := 0.3
const RUB_SPEED := 0.12
## A hand tilted this far from upright pours (rad).
const POUR_TILT := 0.7
## The hands above this far under the eye breathe in, below BREATHE_OUT under it breathe out (m).
const BREATHE_IN := 0.40
const BREATHE_OUT := 0.55
## Life L3a: a safe mistake's freeze: how long the scene takes to soften (s, never sudden), and how dim VR's view goes.
const FREEZE_FADE := 0.8
const MISTAKE_DIM := 0.35
## Life L3b: be a tree in VR: the look this far down (the view's forward's y, about 20 degrees), and each hand at least
## TREE_HANDS_LOW under the head and within TREE_HANDS_IN of it across (the arms folded in), held still.
const TREE_LOOK_DOWN := 0.35
const TREE_HANDS_LOW := 0.3
const TREE_HANDS_IN := 0.38

var experience := ""
var track := "little"
var expert := false
var seed := 0
var region := LifeRegion.DEFAULT
var vars := {}
var run: LifeRun
var room: LifeRoom
var hud: LifeRoomHud
var camera: Camera3D
var stand: Node3D
var ghost: LifeGhostHands
var beam: MeshInstance3D
var vr := false
var low_on := false
var view_name := ""
var paused := false
var closed := false
var outcome := {}
## Life L3a (owner #118): the grown-up's intensity for this try, the skill's finished runs before it, the room's time
## on a danger step, and the freeze of a safe mistake (its data while frozen).
var intensity := LifeData.GENTLE
var tries := 0
var danger_scale := 1.0
var frozen := false
var mistake := {}

var _dim := 0.0
var _dim_tween: Tween
var _was_camera: Camera3D
var _hidden: Array[CanvasLayer] = []
var _pause := 0.0
var _started := false
var _pressed: Array[String] = []
var _answer := -1
var _ok := false
var _action := ""
var _action_tap := false
var _pushes := 0
var _finger_on := false
var _finger_at := Vector2.ZERO
var _finger_target := ""
var _finger_moved := false
var _squeezing := {}
var _trigger_was := false
var _pusher := LifeBeat.Pusher.new()
var _roll := LifeReach.Roll.new()
var _head_track: Array = []
var _cam_tween: Tween
var _low_since_coach := 0
var _looked := ""
var _down_at := Vector2.ZERO
var _last_move_t := -INF
var _hand_was := {}
var _breathing_in := false
var _trigger_held := false
var _trigger_was_any := false


## The try to run (call before open). Life L3a: `run_intensity` (the grown-up's, already for this track:
## LifeData.intensity_for) and `runs_before` (the skill's finished runs) set the room's time on danger steps.
func setup(exp_id: String, run_track: String, expert_try: bool, run_seed: int, run_region: String,
		run_intensity: String = LifeData.GENTLE, runs_before: int = 0) -> void:
	experience = exp_id
	track = run_track
	expert = expert_try
	seed = run_seed
	region = run_region
	intensity = run_intensity if LifeData.INTENSITIES.has(run_intensity) else LifeData.GENTLE
	tries = maxi(runs_before, 0)
	danger_scale = LifeRun.time_scale(tries, expert, intensity == LifeData.REAL)
	vars = LifeExperience.vars(exp_id, run_track, run_seed, run_region, intensity)


## A practice room shows now somewhere in `tree` (Android Back belongs to its calm card then).
static func any_open(tree: SceneTree) -> bool:
	if tree == null:
		return false
	for h in tree.get_nodes_in_group(GROUP):
		if h is LifeRoomHost and not (h as LifeRoomHost).closed:
			return true
	return false


## Opens the room under `parent` (the screen it came from, which hides while the room shows).
func open(parent: Node) -> void:
	name = "LifeRoomHost"
	add_to_group(GROUP)
	parent.add_child(self)
	vr = Vr.active()
	_hide_screen(parent)
	room = LifeRooms.make(str(LifeExperience.data(experience).get("room", "")), track, vars)
	room.position = ROOM_ORIGIN
	add_child(room)
	camera = Camera3D.new()
	camera.name = "RoomCamera"
	camera.fov = 72.0
	camera.near = 0.05
	camera.far = 80.0
	camera.environment = room.env
	add_child(camera)
	stand = Node3D.new()
	stand.name = "Stand"
	add_child(stand)
	hud = LifeRoomHud.new()
	hud.track = track
	UiLayers.route(hud, self)
	hud.set_vr(vr)
	_connect_hud()
	run = LifeRun.new(LifeExperience.steps(experience, track, expert, seed, region), expert)
	_was_camera = get_viewport().get_camera_3d()
	if vr:
		ghost = LifeGhostHands.new()
		add_child(ghost)
		beam = _make_beam()
		add_child(beam)
		Vr.view_like(camera)
	else:
		camera.make_current()
	_start_step(true)


func _connect_hud() -> void:
	hud.ok.connect(func() -> void: _ok = true)
	hud.answered.connect(func(i: int) -> void: _answer = i)
	hud.action_pressed.connect(func(a: String) -> void:
		_action = a
		_action_tap = true)
	hud.low_toggled.connect(set_low)
	hud.coins_back.connect(func() -> void: _pressed.append("coins_back"))
	hud.pay.connect(func() -> void: _pressed.append("till"))
	hud.show_me.connect(show_me)
	hud.break_changed.connect(func(open_now: bool) -> void: paused = open_now)
	hud.stop_for_now.connect(stop_for_now)
	hud.finger.connect(_on_finger)
	hud.look_pressed.connect(func(side: String) -> void: _looked = side)
	hud.mistake_ok.connect(unfreeze)   # Life L3a: GOT IT


# --- Steps ---------------------------------------------------------------------------------------------------------

func _start_step(first: bool = false) -> void:
	if run.finished:
		return
	var step := run.current()
	if str(step.get("react", "")) != "":
		room.react(str(step.react))
	room.step_started(step)
	if bool(step.get("stand", false)) and low_on:   # outside: "You can stand up now"
		low_on = false
		hud.low_button.set_pressed_no_signal(false)
		hud.low_button.text = "GET LOW"
	if bool(step.get("stand", false)):
		hud.set_low_visible(false)
	_go_to_view(str(step.get("view", room.start_view)), first)
	hud.show_step(step, run.index, run.steps.size())
	# Life L3a: a danger step's moment runs at the try's room time (slow on the first tries); the HUD says so
	room.time_scale = danger_scale if bool(step.get("danger", false)) else 1.0
	hud.set_slow(room.time_scale < 0.999)
	_after_progress(step, run.state, false)
	_started = true


func _go_to_view(v: String, instant: bool) -> void:
	if v == "":
		v = room.start_view
	var moved := view_name != "" and room.moves_in_vr(view_name, v)
	view_name = v
	if vr:
		stand.global_transform = room.vr_stand(v)
		if instant or Vr.anchor_node() != stand:
			Vr.anchor(stand, &"life")
		elif moved:
			Vr.face(VrRules.yaw_of(stand.global_basis))   # a new spot faces its way, behind the blink
			Vr.blink()
		return
	var to := _camera_target()
	if _cam_tween:
		_cam_tween.kill()
	if instant or UiMotion.calm() or not is_inside_tree():
		camera.global_transform = to
	else:
		_cam_tween = create_tween().set_trans(Tween.TRANS_SINE)
		_cam_tween.tween_property(camera, "global_transform", to, GLIDE)


func _camera_target() -> Transform3D:
	var t := room.camera_transform(view_name)
	if low_on:
		t.origin.y -= room.low_drop()
	return t


## GET LOW (flat: the view drops under the smoke; VR: the button for a child who can't crouch).
func set_low(on: bool) -> void:
	low_on = on
	if not vr and room != null and view_name != "":
		_go_to_view(view_name, false)


func show_me() -> void:
	if paused or run.finished:
		return
	run.show_me()
	_coach()


func stop_for_now() -> void:
	if closed:
		return
	closed = true
	outcome = run.outcome()
	outcome.log = run.steps_log
	stopped.emit(outcome)
	close()


# --- Every frame ---------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if closed or run == null or not _started:
		return
	if vr and not Vr.active():
		vr = false   # the headset came off and VR ended: carry on flat
		hud.set_vr(false)
		camera.make_current()
		room.rest_held()   # Life L3c: the tablet back in front of the flat view
		_go_to_view(view_name, true)
	if paused or frozen:   # Life L3a: a safe mistake's freeze waits for GOT IT
		_clear_frame()
		return
	if _pause > 0.0:
		_pause -= delta
		_clear_frame()
		if _pause <= 0.0:
			if run.finished:
				_finish()
			else:
				_start_step()
		return
	var step := run.current()
	var state := run.state   # the step's own state: the run starts a new one when the step is done
	var sample := _vr_sample(step, delta) if vr else _flat_sample(step, delta)
	sample["room_dt"] = delta * room.time_scale   # Life L3a: a danger moment's "within" counts the room's own time
	_clear_frame()
	var e := run.feed(sample)
	if bool(e.get("mistake", false)):
		freeze_for(step)
		return
	if sample.has("looked") and not vr:
		_turn_look(str(sample.looked))
	if e.miss and str(step.get("on_miss", "")) != "":
		room.react(str(step.on_miss))   # Life L2: a car stops gently for a child who stepped out
	if e.progress or e.done:
		_after_progress(step, state, bool(e.done))
	elif str(step.get("kind", "")) == "cross":
		room.glow(run.next_targets())   # the other side glows only while it is safe
	if str(e.said) != "":
		hud.pop_line(str(e.said), not e.miss and str(e.said) != LifeCheck.STAY_LOW)
	if e.coach:
		_coach()
	if e.done:
		_step_done(step)


func _clear_frame() -> void:
	_looked = ""
	_pressed.clear()
	_answer = -1
	_ok = false
	_action = ""
	_action_tap = false
	_pushes = 0


## A step moved on (or began): the room shows it, the one next thing glows, the HUD's bar and meters follow.
func _after_progress(step: Dictionary, state: Dictionary, done: bool) -> void:
	room.progress(step, state)
	var next: Array[String] = []
	if not done and bool(step.get("glow", true)):   # Life L3a: `glow: false` (an Expert try) never glows
		next = run.next_targets()
	room.glow(next)
	hud.set_fraction(1.0 if done else LifeCheck.fraction(step, state))
	match str(step.get("kind", "")):
		"rhythm":
			hud.set_rate(LifeBeat.rate(state.get("times", [])), int(state.get("count", 0)), int(step.get("pushes", 30)))
		"coins":
			hud.set_sum("Coins given: %d of %d" % [int(state.get("sum", 0)), int(step.get("sum", 0))])
		"basket":   # Life L3a: a basket's own words (the emergency bag's spaces)
			hud.set_sum("%s: %d of %d %s" % [str(step.get("label", "Basket")), LifeCheck.basket_total(step, state),
				int(step.get("budget", 0)), str(step.get("unit", "coins"))])
		"pour":
			var want := float(step.get("want", 0.5))
			var tol := float(step.get("tol", 0.07))
			hud.set_gauge(float(state.get("level", 0.0)), want - tol, want + tol, float(step.get("full", 1.0)),
				LifeRoomHud.amount_words(float(state.get("level", 0.0)), str(step.get("unit", "")), want))
		"steady":
			var v := float(state.get("value", 0.0))
			hud.set_gauge(v, float(step.get("lo", 0.0)), float(step.get("hi", 0.0)), float(step.get("top", 1.0)),
				"%d %s" % [roundi(v), str(step.get("unit", ""))])
		"breathe":
			hud.set_breath(str(state.get("phase", "rest")), int(state.get("count", 0)), int(step.get("breaths", 3)))


func _step_done(step: Dictionary) -> void:
	room.glow([])
	if str(step.get("after", "")) != "":
		room.react(str(step.after))
	room.step_done(step)
	if vr:
		_buzz(0.5, 0.12)
	var words := str(step.get("done", ""))
	if words != "":
		hud.pop_line(words)
	var goes := str(step.get("goes", ""))
	if goes == "" and str(step.get("kind", "")) == "go" and room.views.has(str(step.target)):
		goes = str(step.target)
	if goes != "":
		_go_to_view(goes, false)
	_pause = DONE_PAUSE if words != "" or goes != "" else 0.3


func _finish() -> void:
	if closed:
		return
	closed = true
	outcome = run.outcome()
	outcome.log = run.steps_log
	finished.emit(outcome)
	close()


## The coach shows the step: a ghost finger (flat) or ghost hands (VR) at the one next thing, its words again.
func _coach() -> void:
	hud.coached()
	var step := run.current()
	hud.pop_line(str(step.get("say", "")), false)
	var kind := str(step.get("kind", ""))
	if kind == "choose" or kind == "count":
		var right := int(step.get("answer", 0))
		if vr:
			pass   # the right picture pulses on the panel (the HUD's own pop); the laser picks it
		else:
			hud.ghost.show_at(hud.choice_centre(right), "tap")
		return
	var next := run.next_targets()
	if next.is_empty():
		return
	if kind == "look" and not vr:   # the coach presses the LOOK button of the way to look
		hud.ghost.show_at(hud.look_centre(next[0].trim_prefix("look_")), "tap")
		return
	if vr:
		var shown := {"look": "point", "rub": "sweep", "pour": "hold", "breathe": "hold", "steady": "hold"}.get(kind, kind) as String
		ghost.demonstrate(shown, room.target_position(next[0]), Vr.head_transform())
	else:
		var at := screen_of(next[0])
		var how := {"hold": "hold", "hands": "hold", "taps": "taps", "rhythm": "beat", "sweep": "drag", "rub": "drag",
			"pour": "hold", "breathe": "hold", "steady": "hold"}.get(kind, "tap") as String
		hud.ghost.show_at(at, how)


# --- Flat: fingers on the screen -----------------------------------------------------------------------------------

## A finger went down, moved or lifted on the tap area (canvas pixels).
func _on_finger(kind: String, pos: Vector2) -> void:
	match kind:
		"down":
			finger_down(pos)
		"move":
			finger_move(pos)
		"up":
			finger_up()


func finger_down(pos: Vector2) -> void:
	_finger_on = true
	_finger_at = pos
	_down_at = pos
	_finger_moved = false
	_finger_target = pick(pos)
	if _finger_target != "":
		_pressed.append(_finger_target)


func finger_move(pos: Vector2) -> void:
	if pos.distance_to(_finger_at) > 2.0 and run != null:
		_last_move_t = run.clock
	_finger_at = pos
	_finger_moved = true


func finger_up() -> void:
	if _finger_on and run != null and str(run.current().get("kind", "")) == "look":   # a LOOK swipe
		var d := _finger_at - _down_at
		if absf(d.x) >= SWIPE_PX and absf(d.x) > absf(d.y) * 1.5:
			_looked = "left" if d.x < 0.0 else "right"
	_finger_on = false
	_finger_target = ""


## Flat: the view turns the way the child looked, holds a moment, and turns back (a jump with Reduce motion).
func _turn_look(side: String) -> void:
	if side not in LifeCheck.SIDES or camera == null:
		return
	var base := _camera_target()
	var turned := Transform3D(Basis(Vector3.UP, LOOK_TURN if side == "left" else -LOOK_TURN) * base.basis, base.origin)
	if _cam_tween:
		_cam_tween.kill()
	if not is_inside_tree():
		return
	var glide := 0.0 if UiMotion.calm() else 0.35
	_cam_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_cam_tween.tween_property(camera, "global_transform", turned, maxf(glide, 0.01))
	_cam_tween.tween_interval(LOOK_HOLD)
	_cam_tween.tween_property(camera, "global_transform", base, maxf(glide, 0.01))


## The thing under a canvas point: the nearest visible target of the room in reach of a finger ("" none).
func pick(pos: Vector2) -> String:
	var at := {}
	var radius := {}
	for t in room.target_names():
		var n := room.target_node(t)
		if n == null or not n.is_visible_in_tree():
			continue
		var p := room.target_position(t)
		if camera.is_position_behind(p):
			continue
		at[t] = camera.unproject_position(p)
		radius[t] = (camera.unproject_position(p + camera.global_basis.x * room.target_radius(t)) - at[t]).length()
	return LifeReach.screen_pick(pos, at, radius)


## Where a target is on the canvas (for the ghost finger and the tests).
func screen_of(target: String) -> Vector2:
	return camera.unproject_position(room.target_position(target))


func _flat_sample(step: Dictionary, delta: float) -> Dictionary:
	var s := {"dt": delta, "low": low_on}
	var kind := str(step.get("kind", ""))
	var target := str(step.get("target", ""))
	var pressed: Array = _pressed.duplicate()
	if kind == "rhythm":
		_pushes += pressed.count(target)
		pressed.erase(target)
		s.pushes = _pushes
	s.pressed = pressed
	if _finger_on and _finger_target != "":
		s.held = [_finger_target]
	if kind == "sweep" and _finger_on and _finger_target == target:
		var c := screen_of(target)
		var half := maxf((camera.unproject_position(room.target_position(target) + camera.global_basis.x * room.target_width(target))
			- c).length(), 30.0)
		s.sweep_u = clampf((_finger_at.x - c.x) / half, -1.0, 1.0)
	if _answer >= 0:
		s.answer = _answer
	s.ok = _ok
	if _action != "":
		s.action = _action
		s.action_tap = _action_tap
	if _looked != "":
		s.looked = _looked
	match kind:
		"cross":
			s.safe = room.safe_now(step)
		"rub":
			if _finger_on and _finger_target == target and run.clock - _last_move_t <= RUB_GAP:
				s.rubbing = [target]
	return s


# --- VR: hands, the laser and the head -----------------------------------------------------------------------------

func _vr_sample(step: Dictionary, delta: float) -> Dictionary:
	var s := {"dt": delta}
	var kind := str(step.get("kind", ""))
	var target := str(step.get("target", ""))
	var reach := str(step.get("reach", "any"))
	var head := Vr.head_transform()
	var hands := {}
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var squeeze := maxf(Vr.grip(side), Vr.trigger(side))
		var was := bool(_squeezing.get(side, false))
		var on := squeeze >= SQUEEZE_ON or (was and squeeze > SQUEEZE_OFF)
		_squeezing[side] = on
		hands[side] = {"at": Vr.hand_grip(side).origin, "squeeze": on, "edge": on and not was}
	var pressed: Array = _pressed.duplicate()
	var held: Array = []
	var aimed: Array = []
	var holder := _hold_device(head)   # Life L3c: Online City's tablet in the off hand
	# each hand squeezes the one thing nearest to it that it touches (the phone's keys sit close together)
	for side: StringName in hands:
		var h: Dictionary = hands[side]
		var nearest := ""
		var best := INF
		for t in room.target_names():
			var n := room.target_node(t)
			if n == null or not n.is_visible_in_tree():
				continue
			if side == holder and room.is_held_target(t):
				continue   # the hand holding the tablet never presses its own buttons
			var p := room.target_position(t)
			var d := (h.at as Vector3).distance_to(p) - room.target_radius(t)
			if LifeReach.touching(h.at, p, room.target_radius(t)) and d < best:
				best = d
				nearest = t
		if nearest == "":
			continue
		if bool(h.edge):
			pressed.append(nearest)
		if bool(h.squeeze) and not held.has(nearest):
			held.append(nearest)
	if room.has_target(target):
		var p := room.target_position(target)
		var both := 0
		for side: StringName in hands:
			if LifeReach.touching(hands[side].at, p, room.target_radius(target)):
				both += 1
		if kind == "hands" and both >= 2 and not held.has(target):
			held.append(target)
		if reach == "head" and head.origin.distance_to(p) <= room.target_radius(target) + HEAD_REACH and not held.has(target):
			held.append(target)
	# the laser: the pointing hand's trigger presses what it points at (further things), and aims
	var ray := Vr.pointer_ray()
	var trigger_now := Vr.trigger_pressed(Vr.pointing_hand())
	var over_panel := Vr.ui_wants_pointer()
	var pointed := ""
	if not ray.is_empty() and not over_panel:
		var best := INF
		for t in room.target_names():
			var n := room.target_node(t)
			if n == null or not n.is_visible_in_tree():
				continue
			var d := LifeReach.ray_hit(ray[0], ray[1], room.target_position(t), room.target_radius(t))
			if d >= 0.0 and d < best and d <= LASER:
				best = d
				pointed = t
		if pointed != "":
			aimed.append(pointed)
			if trigger_now and not _trigger_was and reach != "hand" and not pressed.has(pointed):
				pressed.append(pointed)
		_show_beam(ray, best if pointed != "" else LASER)
	elif beam:
		beam.visible = false
	_trigger_was = trigger_now
	if kind == "rhythm":
		var on_chest := []
		for side: StringName in hands:
			if LifeReach.touching(hands[side].at, room.target_position(target), room.target_radius(target)):
				on_chest.append(hands[side].at)
		if not on_chest.is_empty():
			var y := 0.0
			for at: Vector3 in on_chest:
				y += at.y
			if _pusher.feed(y / on_chest.size()):
				_pushes += 1
		pressed.erase(target)
		s.pushes = _pushes
	if kind == "sweep" and reach != "hand" and pointed == target and (bool(hands[Vr.pointing_hand()].squeeze) or trigger_now):
		var right := stand.global_basis.x
		s.sweep_u = LifeReach.across(ray[0], ray[1], room.target_position(target), right, room.target_width(target))
	_vr_l2(step, s, head, hands, held, pressed, delta)
	s.pressed = pressed
	s.held = held
	s.aimed = aimed
	var low := LifeReach.head_low(head.origin.y, stand.global_position.y) or low_on
	s.low = low
	var act := _body_action(head, hands, low)
	if _action != "":
		s.action = _action
		s.action_tap = _action_tap
	elif act != "":
		s.action = act
		s.action_tap = act == "roll"
	if _answer >= 0:
		s.answer = _answer
	s.ok = _ok
	if (s.pushes if s.has("pushes") else 0) > 0:
		var good := LifeBeat.good(LifeBeat.rate((run.state.get("times", []) as Array) + [run.clock + delta]))
		_buzz(0.7 if good else 0.25, 0.06)
	elif not pressed.is_empty():
		_buzz(0.35, 0.05)
	return s


## Life L3c (owner #112, Online City: "VR: the tablet held in the hand"): a device the room lets the child hold (its
## `held`, once `holding`) follows the off hand (the one that doesn't point), facing the eyes; returns that hand (&"" for
## none). The pointing hand and the laser press its buttons.
func _hold_device(head: Transform3D) -> StringName:
	if not room.holding or not is_instance_valid(room.held):
		return &""
	var side: StringName = VrRules.LEFT if Vr.pointing_hand() == VrRules.RIGHT else VrRules.RIGHT
	room.held.global_transform = room.hold_pose(Vr.hand_grip(side), head)
	return side


## What the body does now: low, still (the head barely moved for a moment), cover (both hands at the face), roll (the
## head side to side while low: once, then it starts again).
func _body_action(head: Transform3D, hands: Dictionary, low: bool) -> String:
	_head_track.append([run.clock, head.origin])
	while _head_track.size() > 2 and float(run.clock) - float(_head_track[0][0]) > STILL_SECONDS:
		_head_track.pop_front()
	var still := float(run.clock) - float(_head_track[0][0]) >= STILL_SECONDS * 0.9
	for e: Array in _head_track:
		if (e[1] as Vector3).distance_to(head.origin) > STILL_MOVE:
			still = false
	var step := run.current()
	var want := str(step.get("action", ""))
	if want == "cover" and LifeReach.hands_at_face(hands[VrRules.LEFT].at, hands[VrRules.RIGHT].at, head):
		return "cover"
	if want == "roll" and low:
		var x := (head.origin - stand.global_position).dot(stand.global_basis.x)
		if _roll.feed(x):
			_roll = LifeReach.Roll.new()
			return "roll"
	if want == "still" and still:
		return "still"
	if want == "tree" and still and _tree_pose(head, hands):   # Life L3b (owner #118): be a tree
		return "tree"
	return ""


## Life L3b (owner #118): be a tree: looking down at the feet, both arms folded in (the hands close to the body, below the
## head), and still (the caller's check).
func _tree_pose(head: Transform3D, hands: Dictionary) -> bool:
	if (-head.basis.z).normalized().y > -TREE_LOOK_DOWN:
		return false
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var at: Vector3 = hands[side].at
		var d := at - head.origin
		if d.y > -TREE_HANDS_LOW or Vector2(d.x, d.z).length() > TREE_HANDS_IN:
			return false
	return true


func _buzz(amplitude: float, seconds: float) -> void:
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		Vr.haptic(side, amplitude, seconds)


func _make_beam() -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = "LifeLaser"
	var b := BoxMesh.new()
	b.size = Vector3(0.006, 0.006, 1.0)
	m.mesh = b
	var mat := LifeRoomKit.material(Color(1, 1, 1, 0.55), true)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visible = false
	return m


func _show_beam(ray: Array, length: float) -> void:
	if beam == null:
		return
	beam.visible = true
	var from: Vector3 = ray[0]
	var dir: Vector3 = (ray[1] as Vector3).normalized()
	var mid := from + dir * length * 0.5
	beam.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.FORWARD), mid)
	beam.scale = Vector3(1, 1, length)


# --- Life L3a (owner #118): a safe mistake, safely -----------------------------------------------------------------

## The wrong way was tried: time freezes. The room stills (its own time and tweens), the scene softens over FREEZE_FADE
## (flat: the HUD's soft veil; VR: the view dims a little, under the panel), the room shows what would happen (never an
## injury) and the coach's card says the calm why and the right way. Nothing moves on until GOT IT (unfreeze); I NEED A
## BREAK and STOP FOR NOW still work.
func freeze_for(step: Dictionary) -> void:
	if frozen or closed:
		return
	frozen = true
	var m: Variant = step.get("safe_mistake", {})
	mistake = (m as Dictionary).duplicate() if m is Dictionary else {}
	room.glow([] as Array[String])
	room.freeze(true)
	room.show_mistake(str(mistake.get("event", "")), true)
	hud.show_mistake(mistake)
	if vr:
		_fade_dim(MISTAKE_DIM)
	if is_inside_tree():
		Audio.play(&"chime", Vector3.INF, -8.0)   # a soft chime: calm, never an alarm


## GOT IT: the picture goes, the room moves again, the right thing glows and the coach shows it (never a hint).
func unfreeze() -> void:
	if not frozen:
		return
	frozen = false
	room.show_mistake(str(mistake.get("event", "")), false)
	room.freeze(false)
	hud.hide_mistake()
	if vr or _dim > 0.0:
		_fade_dim(0.0)
	var step := run.current()
	_after_progress(step, run.state, false)
	var right := str(mistake.get("right", ""))
	mistake = {}
	hud.pop_line(right, true)
	_show_right(step)


## The coach shows the right way after a safe mistake (a showing, never a hint).
func _show_right(step: Dictionary) -> void:
	var kind := str(step.get("kind", ""))
	if kind in ["choose", "count"]:
		if not vr:
			hud.ghost.show_at(hud.choice_centre(int(step.get("answer", 0))), "tap")
		return
	var next := run.next_targets()
	if next.is_empty() or not room.has_target(next[0]):
		return
	if vr:
		ghost.demonstrate({"go": "point"}.get(kind, kind), room.target_position(next[0]), Vr.head_transform())
	else:
		hud.ghost.show_at(screen_of(next[0]), "hold" if kind in ["hold", "hands"] else "tap")


func _fade_dim(to: float) -> void:
	if _dim_tween:
		_dim_tween.kill()
	if not is_inside_tree() or UiMotion.calm():
		_apply_dim(to)
		return
	_dim_tween = create_tween()
	_dim_tween.tween_method(_apply_dim, _dim, to, FREEZE_FADE)


func _apply_dim(v: float) -> void:
	_dim = v
	if Vr.active():
		Vr.set_dim(v)


# --- Showing and closing -------------------------------------------------------------------------------------------

## The screen the room was opened from hides (its CanvasLayer) while the room shows.
func _hide_screen(from: Node) -> void:
	var n := from
	while n != null:
		if n is CanvasLayer:
			if (n as CanvasLayer).visible:
				(n as CanvasLayer).visible = false
				_hidden.append(n as CanvasLayer)
			break
		n = n.get_parent()


func close() -> void:
	closed = true
	if frozen or _dim > 0.0:   # Life L3a: the way out at any moment leaves the view clear
		frozen = false
		if _dim_tween:
			_dim_tween.kill()
		_apply_dim(0.0)
	if is_instance_valid(stand) and Vr.anchor_node() == stand:
		Vr.release(stand)
	if Vr.active():
		Vr.view_default()
	if is_instance_valid(_was_camera) and _was_camera.is_inside_tree() and not Vr.active():
		_was_camera.make_current()
	for l in _hidden:
		if is_instance_valid(l):
			l.visible = true
	_hidden.clear()
	if is_inside_tree():
		queue_free()


func _exit_tree() -> void:
	if not closed:
		close()


## Life L2's VR parts of a sample (owner #112): the head's turn, the traffic, rubbing, pouring, breathing, the trigger as a
## pedal, and the hand's own path across a target.
func _vr_l2(step: Dictionary, s: Dictionary, head: Transform3D, hands: Dictionary, held: Array, pressed: Array,
		delta: float) -> void:
	var kind := str(step.get("kind", ""))
	var target := str(step.get("target", ""))
	var reach := str(step.get("reach", "any"))
	var has_target := room.has_target(target)
	var p := room.target_position(target) if has_target else Vector3.ZERO
	if _looked != "":
		s.looked = _looked   # LOOK LEFT / LOOK RIGHT on the tray (after the coach showed it twice: a child who sits still)
	match kind:
		"look":
			var fwd := -stand.global_basis.z
			var look := -head.basis.z
			fwd.y = 0.0
			look.y = 0.0
			if fwd.length() > 0.01 and look.length() > 0.01:
				s.look_yaw = fwd.normalized().signed_angle_to(look.normalized(), Vector3.UP)
		"cross":
			s.safe = room.safe_now(step)
		"rub":
			for side: StringName in hands:
				var at: Vector3 = hands[side].at
				var was: Vector3 = _hand_was.get(side, at)
				if has_target and LifeReach.touching(at, p, room.target_radius(target) + 0.05) \
						and at.distance_to(was) / maxf(delta, 0.001) >= RUB_SPEED:
					s.rubbing = [target]
		"pour":
			if str(step.get("motion", "")) == "pour" and held.has(target):   # the jug tilted, not only held
				var tilted := false
				for side: StringName in hands:
					if bool(hands[side].squeeze) and LifeReach.touching(hands[side].at, p, room.target_radius(target)):
						tilted = tilted or Vr.hand_grip(side).basis.y.normalized().angle_to(Vector3.UP) >= POUR_TILT
				if not tilted:
					held.erase(target)
		"breathe":
			var y := 0.0
			for side: StringName in hands:
				y += (hands[side].at as Vector3).y
			y /= maxf(hands.size(), 1.0)
			var eye := stand.global_position.y
			if y >= eye - BREATHE_IN:
				_breathing_in = true
			elif y <= eye - BREATHE_OUT:
				_breathing_in = false
			var squeezing := false
			for side: StringName in hands:
				squeezing = squeezing or bool(hands[side].squeeze)
			if (_breathing_in or squeezing) and not held.has(target):
				held.append(target)
	if reach == "trigger" and has_target and not Vr.ui_wants_pointer():   # the trigger itself (not at the panel's buttons)
		var tr := maxf(Vr.trigger(VrRules.LEFT), Vr.trigger(VrRules.RIGHT))
		_trigger_held = tr >= SQUEEZE_ON or (_trigger_held and tr > SQUEEZE_OFF)
		if _trigger_held and not held.has(target):
			held.append(target)
		if _trigger_held and not _trigger_was_any and not pressed.has(target):
			pressed.append(target)
		_trigger_was_any = _trigger_held
	if kind == "sweep" and reach == "hand" and has_target:
		for side: StringName in hands:
			if bool(hands[side].squeeze) and LifeReach.touching(hands[side].at, p, room.target_width(target) + 0.12):
				s.sweep_u = clampf((hands[side].at - p).dot(stand.global_basis.x) / maxf(room.target_width(target), 0.05),
					-1.0, 1.0)
	for side: StringName in hands:
		_hand_was[side] = hands[side].at
