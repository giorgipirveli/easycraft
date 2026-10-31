class_name PlayHost
extends Node
## Owner #122 (G0; docs/design/learning-is-play.md §4; docs/devlog/parts/play-g0.md §1): plays one unit of the School in
## the play arena, flat or in VR, and says how it went (`finished`: {right_first, total, world_task}, what
## MasteryRules.after_round takes, as a quiz round gave it) or that the child stopped for now (`stopped`: nothing is
## recorded).
##
## The loop (PlayLoop): the HOOK (the problem in the place: its words in the coach's bar; the try is already there and the
## first act starts it), the TRY (the round's first challenge, before any words), WHY (the coach's one line, after the
## try), PLAY (the rest), then the end with the world task. Each challenge builds its mechanic's station in the arena;
## `check` asks ExerciseCheck (the referee) about the station's response: right (the world's happy answer, Professor Hoot's
## praise, and the coach's next line), NOT_YET (the world's answer and the hint), GHOST (the coach's ghost does one step
## in the game: shown, not told; for a choice or a claim it only shows, the child does it), SHOWN (the worked answer in
## the place, and in words). SHOW ME does one step at any time (that challenge no longer counts). Gold for an answer right
## the first time comes from `first_try_gold` (the School's EarnRules).
##
## Like Life's rooms (LifeRoomHost): the place is far above the menu's world (ROOM_ORIGIN, its own sky and light); the
## screen it was opened from hides while it shows; the HUD (PlayHud) is routed like every layer (in VR on the panel).
## - Flat: the place's camera looks over the child's shoulder; a finger on a thing taps it (LifeReach.screen_pick: never
##   smaller than a fingertip); a drag from a thing to its place carries it there.
## - VR (Vr.active()): the child stands at the station (Vr.anchor; a new spot blinks); a hand squeezing at a thing picks it
##   up (it follows the hand) and letting go over its place puts it there (elsewhere: it goes home); a hand squeezing at
##   anything else presses it; the laser's trigger taps what it points at; the coach's ghost hands show the step.
## Owner #133, rule 0 (the foundation, docs/design/future-lessons.md §7): only what plays without reading comes into play
## (PlayLoop, PlayReadless); every line is spoken by itself (PlayVoice; the HUD shows a caption and pictures); a thing
## says its name when it is touched; a new unit's first challenge of each kind is shown one step first (`DEMO_WAIT`
## after the question is heard: the ghost does one step, or shows it, then "Your turn!"; the challenge still counts);
## every challenge judged is a SkillShown event (`shown`, in the outcome), the bridge to MasteryRules.

signal finished(outcome: Dictionary)
signal stopped(outcome: Dictionary)

const ROOM_ORIGIN := Vector3(400, 1500, 0)
const GROUP := &"play_host"
const FOV := 72.0
const LASER := 8.0
const GLIDE := 0.6
const SQUEEZE_ON := 0.6
const SQUEEZE_OFF := 0.35
## A finger that moved this far (px) from where it went down is carrying a thing (let go over its place: it goes there).
const DRAG_PX := 30.0
## The ghost shows each tap this long before it happens.
const GHOST_TAP := 1.1
## How near (m) a hand letting go must be to a place for the thing to go there.
const DROP_REACH := 0.14
## The hook's words stay this long (s) before the try's own come (the child's first act ends it sooner).
const HOOK_TIME := 4.0
## Life's way for a child who doesn't know what to touch: after IDLE_HINT s without an act, the things to act with glow
## for HINT_TIME s (every one of them: never the answer, and no help: the challenge still counts).
const IDLE_HINT := 10.0
const HINT_TIME := 3.0
## Owner #133 ("Show"): the demonstration starts this long after the question has been heard.
const DEMO_WAIT := 0.6
const YOUR_TURN_WORDS := "Your turn!"

var unit_id := ""
var content := {}
var unit := {}
var seed := 0
var stars := 0
var loop: PlayLoop
var arena: PlayArena
var hud: PlayHud
var camera: Camera3D
var stand: Node3D
var ghost_hands: LifeGhostHands
var beam: MeshInstance3D
var vr := false
var paused := false
var closed := false
## () -> int: gold paid for an answer right the first time (the School sets it: EarnRules).
var first_try_gold := Callable()
## Where Professor Hoot's praise starts (the round's seed: it changes from round to round).
var praise_from := 0
## Owner #134: what the child showed, challenge by challenge (the outcome's "shown": SkillShown.record takes it).
var shown := SkillShown.begin()

var _was_camera: Camera3D
var _hidden: Array[CanvasLayer] = []
var _ghost: Array[String] = []
var _ghost_apply := true
var _ghost_first := ""
var _ghost_t := 0.0
var _finger_on := false
var _down_at := Vector2.ZERO
var _finger_at := Vector2.ZERO
var _squeezing := {}
var _holding := {}
var _trigger_was := false
var _hook_t := 0.0
var _idle_t := 0.0
var _hint_t := 0.0
## Owner #133: the mechanics shown first already in this round; the wait before this challenge's demonstration (< 0:
## none); a demonstration is running.
var _demoed := {}
var _demo_wait := -1.0
var _demo_on := false


## The unit to play (call before open): its id, content (Curriculum's), the round's seed, its stars (how hard the round
## is: RoundPlan), its outline entry (title, goals) and, for a short round (a discovery crystal's minute), how many
## challenges (`count`; 0: a whole round).
func setup(id: String, unit_content: Dictionary, run_seed: int, unit_stars: int, outline: Dictionary = {},
		count: int = 0) -> void:
	unit_id = id
	content = unit_content
	seed = run_seed
	stars = unit_stars
	unit = outline
	praise_from = posmod(run_seed, 9973)
	loop = PlayLoop.make(content, seed, stars, unit, count)
	shown = SkillShown.begin()


## Owner #133, #134: the unit has enough to play without reading (its page offers PLAY; a crystal may start it).
static func plays(unit_content: Dictionary) -> bool:
	return PlayReadless.unit_plays(unit_content)


## A play place shows now somewhere in `tree` (Android Back belongs to its calm card then).
static func any_open(tree: SceneTree) -> bool:
	if tree == null:
		return false
	for h in tree.get_nodes_in_group(GROUP):
		if h is PlayHost and not (h as PlayHost).closed:
			return true
	return false


## Opens the place under `parent` (the screen it came from, which hides while the place shows).
func open(parent: Node) -> void:
	name = "PlayHost"
	add_to_group(GROUP)
	parent.add_child(self)
	vr = Vr.active()
	_hide_screen(parent)
	arena = PlayArena.new(SchoolUi.SUBJECT_COLORS.get(str(unit_id.get_slice(".", 1)), UiKit.BLUE))
	arena.position = ROOM_ORIGIN
	add_child(arena)
	camera = Camera3D.new()
	camera.name = "PlayCamera"
	camera.fov = FOV
	camera.near = 0.05
	camera.far = 60.0
	camera.environment = arena.env
	add_child(camera)
	stand = Node3D.new()
	stand.name = "Stand"
	add_child(stand)
	hud = PlayHud.new()
	UiLayers.route(hud, self)
	hud.set_vr(vr)
	hud.set_voice(PlayVoice.on())
	_connect_hud()
	_was_camera = get_viewport().get_camera_3d()
	if vr:
		ghost_hands = LifeGhostHands.new()
		add_child(ghost_hands)
		beam = _make_beam()
		add_child(beam)
		Vr.view_like(camera)
	else:
		camera.make_current()
	_show_challenge()
	_say_challenge()   # the try's test button and count are ready ...
	hud.say(loop.hook_line)   # ... but the bar says the hook: the problem appears in the place (the try is there to act on)


func _connect_hud() -> void:
	hud.finger.connect(_on_finger)
	hud.go.connect(check)
	hud.next.connect(next)
	hud.play_on.connect(play_on)
	hud.show_me.connect(show_me)
	hud.break_changed.connect(func(open_now: bool) -> void: paused = open_now)
	hud.stop_for_now.connect(stop_for_now)


func station() -> PlayStation:
	return arena.station if arena != null else null


# --- The loop ------------------------------------------------------------------------------------------------------

## The hook is over (its time, or the child's first act): the try's own words.
func end_hook() -> void:
	if loop.phase != PlayLoop.HOOK:
		return
	loop.start()
	_say_challenge()


func _show_challenge() -> void:
	_cancel_ghost()
	_idle_t = 0.0
	_hint_t = 0.0
	var ex := loop.current()
	var st := arena.show_challenge(ex, seed + loop.index * 7919, PlayBlock.params(content),
		str(PlayBlock.of(content).get("game", "")))
	_demo_wait = DEMO_WAIT if _wants_demo(st) else -1.0
	st.changed.connect(_on_changed)
	st.acted.connect(check)
	st.go_pressed.connect(check)
	_go_to_view(loop.index == 0)
	if loop.phase != PlayLoop.HOOK:
		_say_challenge()
	hud.set_readout(st.readout())


func _say_challenge() -> void:
	var st := station()
	hud.set_voice(PlayVoice.on())
	hud.show_challenge(str(loop.current().get("prompt", "")), loop.index, loop.total(),
		"" if st.answers_by_acting() else st.go_words(), PlayVoice.caption(loop.current()))


## Tests and the smoke run: puts `ex` in the place as the current challenge.
func show_exercise(ex: Dictionary) -> void:
	loop.challenges[loop.index] = ex
	_show_challenge()


func _on_changed() -> void:
	end_hook()
	hud.set_readout(station().readout())


## The world's test: ExerciseCheck judges the station's response, and the place and the coach answer.
func check() -> void:
	if closed or paused or loop.answered:
		return
	end_hook()
	var st := station()
	if not st.is_ready():
		hud.line("Put something in its place first, then test it.", false)
		return
	_cancel_ghost()
	var ex := loop.current()
	var right := ExerciseCheck.is_right(ex, st.response())
	var outcome := loop.answer(right)
	if outcome == PlayLoop.RIGHT:   # owner #134: what the child showed (SkillShown)
		shown.add(unit_id, SkillShown.SOLVED if loop.first_try else SkillShown.HELPED)
	elif outcome == PlayLoop.SHOWN:
		shown.add(unit_id, SkillShown.SHOWN)
	st.react(outcome)
	hud.set_readout(st.readout())
	var n := loop.index + praise_from
	match outcome:
		PlayLoop.RIGHT:
			var words := SchoolWords.right(n) if loop.first_try else SchoolWords.right_after_help(n)
			var why := str(ex.get("explain", "")).strip_edges()
			if not loop.first_try and why != "":
				words += " %s %s" % [SchoolWords.HERE_IS_WHY, why]
			elif loop.phase == PlayLoop.PLAY and loop.why_after(loop.index) != "":
				words += " " + loop.why_after(loop.index)   # the coach's next line: one idea, after the act
			hud.line(words, true)
			Audio.play(&"ding")
			if loop.first_try and first_try_gold.is_valid():
				var g := int(first_try_gold.call())
				if g > 0:
					hud.gold(EarnRules.answer_words(g), g)
			st.lock()
			hud.answered()
			_buzz(0.5, 0.12)
		PlayLoop.NOT_YET, PlayLoop.GHOST:
			var world := st.world_words()   # the world answers first ("Not enough yet."), then the hint
			hud.line(("%s %s %s" % [world, SchoolWords.not_yet(n), str(ex.get("hint", ""))]).strip_edges(), false)
			Audio.play(&"ui_tick")
			if outcome == PlayLoop.GHOST:
				_ghost_step()
		PlayLoop.SHOWN:
			var lines: Array[String] = [SchoolWords.SHOW_HOW]
			var how := str(ex.get("explain", ""))
			if how != "":
				lines.append(how)
			var answer := ExerciseCheck.answer_text(ex).trim_suffix(".")
			if answer != "" and not how.to_lower().contains(answer.to_lower()):
				lines.append("The answer is %s." % answer)
			hud.line(" ".join(lines), false)
			st.lock()
			hud.answered()


## NEXT: the next challenge (after the try: the coach's see-why card first; after the last: the end).
func next() -> void:
	if closed or not loop.answered:
		return
	var phase := loop.next()
	match phase:
		PlayLoop.WHY:
			var line := loop.see_why()
			if line == "":
				play_on()
			else:
				hud.show_why(line)
		PlayLoop.WORLD:
			_finish()
		_:
			_show_challenge()


## LET'S PLAY!: the rest of the round.
func play_on() -> void:
	if loop.phase != PlayLoop.WHY:
		return
	loop.play_on()
	_show_challenge()


## SHOW ME: the coach's ghost does one step (that challenge no longer counts as right the first time).
func show_me() -> void:
	if paused or closed or loop.answered:
		return
	end_hook()
	loop.show_me()
	_ghost_step()


func stop_for_now() -> void:
	if closed:
		return
	closed = true
	stopped.emit({"right_first": loop.right_first, "answered": loop.index})
	close()


func _finish() -> void:
	if closed:
		return
	loop.finish()
	closed = true
	finished.emit({"right_first": loop.right_first, "total": loop.total(), "world_task": loop.world_task,
		"shown": shown})
	close()


# --- The coach's ghost ---------------------------------------------------------------------------------------------

## One step shown in the game (flat: the ghost finger; VR: the ghost hands), then done, unless the act itself answers
## (a choice, a claim): then it only shows, and the child does it.
func _ghost_step() -> void:
	var st := station()
	if st.carried != "":
		st.put_home()
	_ghost = st.ghost()
	_ghost_apply = not st.answers_by_acting()
	_ghost_first = _ghost[0] if not _ghost.is_empty() else ""
	_ghost_t = 0.0
	if not _ghost.is_empty():
		_show_ghost_at(_ghost[0])
		arena.glow([_ghost[0]] as Array[String])


func ghost_busy() -> bool:
	return not _ghost.is_empty()


func _cancel_ghost() -> void:
	_ghost.clear()
	_demo_on = false


# --- Show, then do (owner #133) ------------------------------------------------------------------------------------

## A new unit's (no stars yet) first challenge of each mechanic in the round is shown first, unless one act answers it.
func _wants_demo(st: PlayStation) -> bool:
	return stars == 0 and not _demoed.has(st.mechanic) and st.demo_kind() != PlayStation.DEMO_NONE


## Counts down once the question has been heard (never in the hook, a break, or once the child has acted).
func _step_demo(delta: float) -> void:
	if _demo_wait < 0.0 or loop.answered or loop.phase not in [PlayLoop.TRY, PlayLoop.PLAY] or not _ghost.is_empty() \
			or hud.break_open() or (PlayVoice.on() and ReadAloud.voice.is_speaking()):
		return
	_demo_wait -= delta
	if _demo_wait <= 0.0:
		_demo()


## The coach's ghost does the next step (DEMO_DO) or shows it over the right things (DEMO_SHOW); then "Your turn!".
func _demo() -> void:
	_demo_wait = -1.0
	var st := station()
	_demoed[st.mechanic] = true
	var kind := st.demo_kind()
	var steps := st.ghost()
	if kind == PlayStation.DEMO_NONE or steps.is_empty():
		return
	_ghost = steps.duplicate()
	_ghost_apply = kind == PlayStation.DEMO_DO
	_ghost_first = steps[0]
	_ghost_t = 0.0
	_demo_on = true
	_show_ghost_at(steps[0])
	arena.glow([steps[0]] as Array[String])


func _show_ghost_at(t: String) -> void:
	if not arena.has_target(t):
		return
	if vr and ghost_hands != null:
		ghost_hands.demonstrate("touch", arena.target_position(t), Vr.head_transform())
	elif not vr:
		hud.ghost.show_at(screen_of(t), "tap")


func _step_ghost(delta: float) -> void:
	if _ghost.is_empty():
		return
	_ghost_t += delta
	if _ghost_t < GHOST_TAP:
		return
	_ghost_t = 0.0
	var t: String = _ghost.pop_front()
	if _ghost_apply:
		station().tap(t)
	if not _ghost.is_empty():
		_show_ghost_at(_ghost[0])
		arena.glow([_ghost[0]] as Array[String])
	else:
		if not _ghost_apply:
			arena.glow([_ghost_first] as Array[String])   # the right thing keeps glowing: the child does it
		elif _demo_on:
			arena.glow([] as Array[String])
		if _demo_on:
			_demo_on = false
			PlayVoice.say(YOUR_TURN_WORDS)


# --- Every frame ---------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if closed or arena == null:
		return
	if vr and not Vr.active():
		vr = false   # the headset came off: carry on flat
		hud.set_vr(false)
		camera.make_current()
		_go_to_view(true)
	if paused:
		return
	if loop.phase == PlayLoop.HOOK:
		_hook_t += delta
		if _hook_t >= HOOK_TIME:
			end_hook()
	_step_demo(delta)
	_step_ghost(delta)
	_step_idle(delta)
	if vr:
		_vr_frame()


## The idle cue (IDLE_HINT): the things to act with glow for a moment; any act starts the wait again.
func _step_idle(delta: float) -> void:
	if _hint_t > 0.0:
		_hint_t -= delta
		if _hint_t <= 0.0 and _ghost.is_empty():
			arena.glow([] as Array[String])
	if loop.answered or loop.phase not in [PlayLoop.TRY, PlayLoop.PLAY] or not _ghost.is_empty() or hud.break_open():
		_idle_t = 0.0
		return
	_idle_t += delta
	if _idle_t >= IDLE_HINT:
		_idle_t = 0.0
		var lit := station().hint_targets()
		if not lit.is_empty():
			arena.glow(lit)
			_hint_t = HINT_TIME


func _acted() -> void:
	_idle_t = 0.0


func _go_to_view(instant: bool) -> void:
	if vr:
		stand.global_transform = arena.vr_stand(PlayArena.VIEW)
		if instant or Vr.anchor_node() != stand:
			Vr.anchor(stand, &"life")
		arena.face_board(stand.global_position)   # the picture faces the child's eyes
		return
	var to := arena.camera_transform(PlayArena.VIEW)
	if instant or UiMotion.calm() or not is_inside_tree():
		camera.global_transform = to
	else:
		create_tween().set_trans(Tween.TRANS_SINE).tween_property(camera, "global_transform", to, GLIDE)


# --- Flat: fingers -------------------------------------------------------------------------------------------------

func _on_finger(kind: String, pos: Vector2) -> void:
	match kind:
		"down":
			finger_down(pos)
		"move":
			_finger_at = pos
		"up":
			finger_up(pos)


func finger_down(pos: Vector2) -> void:
	if closed or paused or not _ghost.is_empty() and _ghost_apply:
		return
	_finger_on = true
	_down_at = pos
	_finger_at = pos
	var t := pick(pos)
	if t == "":
		return
	end_hook()
	_tap(t)


## One act on a thing of the place: the board shows its picture big; anything else is the station's.
func _tap(t: String) -> void:
	_acted()
	_demo_wait = -1.0   # the child is already doing it: no demonstration
	if t == PlayArena.BOARD and arena.board != null:
		hud.show_picture(arena.board.picture.data)
		return
	var st := station()
	st.tap(t)
	if st.carried == t or (st.carried == "" and st.spot_names().has(t)):   # owner #133: a thing says its name
		PlayVoice.say(st.spoken_name(t))


## A finger lifted: after a drag, the carried thing goes to the place under the finger.
func finger_up(pos: Vector2) -> void:
	if not _finger_on:
		return
	_finger_on = false
	var st := station()
	if closed or paused or st.carried == "" or pos.distance_to(_down_at) < DRAG_PX:
		return
	var t := pick(pos)
	if st.spots_for(st.carried).has(t):
		st.tap(t)


## The thing under a canvas point: the nearest visible target in reach of a finger ("" none).
func pick(pos: Vector2) -> String:
	var at := {}
	var radius := {}
	for t in arena.target_names():
		var n := arena.target_node(t)
		if n == null or not n.is_visible_in_tree():
			continue
		var p := arena.target_position(t)
		if camera.is_position_behind(p):
			continue
		at[t] = camera.unproject_position(p)
		radius[t] = (camera.unproject_position(p + camera.global_basis.x * arena.target_radius(t)) - at[t]).length()
	return LifeReach.screen_pick(pos, at, radius)


func screen_of(t: String) -> Vector2:
	return camera.unproject_position(arena.target_position(t))


# --- VR: hands and the laser ---------------------------------------------------------------------------------------

func _vr_frame() -> void:
	var st := station()
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var squeeze := maxf(Vr.grip(side), Vr.trigger(side))
		var was := bool(_squeezing.get(side, false))
		var on := squeeze >= SQUEEZE_ON or (was and squeeze > SQUEEZE_OFF)
		_squeezing[side] = on
		var hand := Vr.hand_grip(side).origin
		if on and not was:
			var t := _touching(hand)
			if t != "":
				end_hook()
				_tap(t)
				if st.carried == t:
					_holding[side] = t
				_buzz(0.35, 0.05)
		elif was and not on and _holding.has(side):
			var held: String = _holding[side]
			_holding.erase(side)
			if st.carried == held:
				var spot := st.spot_near(hand, DROP_REACH)
				if spot != "":
					st.tap(spot)
					_buzz(0.5, 0.08)
				else:
					st.put_home()
		if _holding.has(side) and st.carried == str(_holding[side]) and st.carried_node() != null:
			st.carried_node().global_position = hand
	_laser(st)


## The thing a hand touches (its nearest).
func _touching(hand: Vector3) -> String:
	var best := ""
	var best_d := INF
	for t in arena.target_names():
		var n := arena.target_node(t)
		if n == null or not n.is_visible_in_tree():
			continue
		var p := arena.target_position(t)
		var d := hand.distance_to(p) - arena.target_radius(t)
		if LifeReach.touching(hand, p, arena.target_radius(t)) and d < best_d:
			best_d = d
			best = t
	return best


func _laser(st: PlayStation) -> void:
	var ray := Vr.pointer_ray()
	var trigger_now := Vr.trigger_pressed(Vr.pointing_hand())
	if ray.is_empty() or Vr.ui_wants_pointer() or _holding.has(Vr.pointing_hand()):
		if beam:
			beam.visible = false
		_trigger_was = trigger_now
		return
	var pointed := ""
	var best := INF
	for t in arena.target_names():
		var n := arena.target_node(t)
		if n == null or not n.is_visible_in_tree():
			continue
		var d := LifeReach.ray_hit(ray[0], ray[1], arena.target_position(t), arena.target_radius(t))
		if d >= 0.0 and d < best and d <= LASER:
			best = d
			pointed = t
	_show_beam(ray, best if pointed != "" else LASER)
	if pointed != "" and trigger_now and not _trigger_was:
		end_hook()
		_tap(pointed)
		_buzz(0.35, 0.05)
	_trigger_was = trigger_now


func _buzz(amplitude: float, seconds: float) -> void:
	if not vr:
		return
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		Vr.haptic(side, amplitude, seconds)


func _make_beam() -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = "PlayLaser"
	var b := BoxMesh.new()
	b.size = Vector3(0.006, 0.006, 1.0)
	m.mesh = b
	m.material_override = LifeRoomKit.material(Color(1, 1, 1, 0.55), true)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visible = false
	return m


func _show_beam(ray: Array, length: float) -> void:
	if beam == null:
		return
	beam.visible = true
	var from: Vector3 = ray[0]
	var dir: Vector3 = (ray[1] as Vector3).normalized()
	beam.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.FORWARD),
		from + dir * length * 0.5)
	beam.scale = Vector3(1, 1, length)


# --- Showing and closing -------------------------------------------------------------------------------------------

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
