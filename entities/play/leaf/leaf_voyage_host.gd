class_name LeafVoyageHost
extends PlayHost
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5, §3.5b, §3.8, §3.10, §4.4; the B2 brief; notes B2.1): Inside a
## Leaf's own host, the first deep game opened through PlaySignature (data/play/mechanics.json's "leaf_voyage"). A
## PlayHost subclass, so the School, DISCOVER and the menu treat a voyage exactly as a round: setup (the voyage from the
## unit's play block, `play.params.voyage`, or `--leaf-voyage=5.1|5.T1` for developers), open (the place far above the
## world, the screen it came from hidden, in PlayHost.GROUP: Back is the voyage's), close, the `finished` and `stopped`
## signals. The voyage is LeafJourney (the garden's hook, the dive, under the leaf, inside: B1's LeafRun, the return, the
## world's answer, the end card), shown in B1's places:
## - Flat: in the garden the camera is the child's eyes (a tap on the can pours it, a tap on the leaf dives); inside, the
##   tiny avatar: one tap glides it to a thing (at most GLIDE_MAX s) and acts (a door squeezed, a sugar picked up, the
##   gold pipe fed), the camera gliding with it to the thing's own view and back to the overview after DWELL s (where
##   every thing to tap is in the free band); a drag looks; the camera button gives the avatar's eyes; keys, a mouse and
##   a game controller fly it (the left stick flies, the right looks, A acts on the thing in the middle).
## - VR (LeafVrHands): the child stands at each place's stand; the can is lifted and tilted; touching the leaf grows the
##   garden round the feet; inside, swimming, the laser grapple, two-hand squeezes, sugar carried by hand.
## - The voice: every Hoot line spoken by itself (PlayVoice, through LeafHud's bar: no words on the screen); the ghost
##   (the finger flat, the hands in VR) shows each first step.
## - The record: each judged beat is a SkillShown event for the unit (the outcome's `shown`), each solved one paid at once
##   (`first_try_gold`, EarnRules); recorded by the caller when the child leaves the end card (`finished`: right_first,
##   total, world_task, shown, voyage, then); STOP FOR NOW records nothing (the plant keeps the bud's fill: LeafProgress).

const POUR_TIME := 1.4
const GLIDE_MAX := 1.2
const DWELL := 1.4
## A thing nearer the avatar than this acts at once (no glide).
const REACH := 0.4
const AGAIN := "again"
const NEXT := "next"
const BACK := "back"
const DEV_ARG := "--leaf-voyage="
## Where each stage stands from ROOM_ORIGIN: far enough apart that one never sees another (the camera sees 60 m).
const GARDEN_AT := Vector3.ZERO
const DIVE_AT := Vector3(0, 0, -150)
const LEAF_AT := Vector3(0, 0, -300)
## Keys and a game controller: flying speed (m/s), looking speed (rad/s), the drag's look (rad a pixel).
const FLY_SPEED := 3.0
const LOOK_SPEED := 1.6
const DRAG_LOOK := 0.005
const AVATAR_RADIUS := 0.4
## The answer's bloom takes this long.
const BLOOM_TIME := 5.0
## VR's dive: the garden grows round the child's feet to this many times its size.
const GROW_TO := 9.0
## Things say their names the first time they are touched (spoken, never written).
const NAMES := {"door": "A door", "sugar": "Sugar", "gold_pipe": "The gold pipe", "blue_pipe": "The blue pipe"}

var voyage_id := "5.1"
var journey: LeafJourney
var progress: LeafProgress
var progress_path := LeafProgress.FILE
var garden: LeafGarden
var dive: LeafDive
var place: LeafPlace
var avatar: LeafAvatar
var hoot: Node3D
var leaf_hud: LeafHud
var vr_hands: LeafVrHands
var first_person := false
var gold_earned := 0
## The outcome given when the child left the end card ({} before).
var outcome := {}

var _root: Node3D
var _pour_t := -1.0
var _cam_from := Transform3D()
var _cam_to := Transform3D()
var _cam_t := -1.0
var _cam_time := 1.0
var _look := Vector2.ZERO
var _dragging := false
var _queue: Array[String] = []
var _acting := ""
var _dwell := -1.0
var _ghost_steps: Array[String] = []
var _ghost_wait := 0.0
var _answer_t := 0.0
var _recorded := false
var _named := {}
var _flying := false


## Owner #133, #134: the unit to play (call before open); the voyage comes from the unit's play block
## (`play.params.voyage`: "5.1" or "5.T1"), a developer's `--leaf-voyage=` overrides it. `count` (a crystal's short
## round) means nothing to a voyage: it is always whole.
func setup(id: String, unit_content: Dictionary, run_seed: int, unit_stars: int, outline: Dictionary = {},
		count: int = 0) -> void:
	unit_id = id
	content = unit_content
	seed = run_seed
	stars = unit_stars
	unit = outline
	praise_from = posmod(run_seed, 9973)
	voyage_id = voyage_of(unit_content)
	journey = LeafJourney.make(voyage_id, run_seed)
	shown = SkillShown.begin()
	if count > 0:
		pass   # a whole voyage, whatever the crystal asked


## The voyage a unit's content opens: a developer's argument, else its play block's, else 5.1.
static func voyage_of(unit_content: Dictionary) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(DEV_ARG) and not LeafVoyages.voyage(arg.trim_prefix(DEV_ARG)).is_empty():
			return arg.trim_prefix(DEV_ARG)
	var v := str(PlayBlock.params(unit_content).get("voyage", "5.1"))
	return v if not LeafVoyages.voyage(v).is_empty() else "5.1"


func open(parent: Node) -> void:
	name = "LeafVoyageHost"
	add_to_group(GROUP)
	parent.add_child(self)
	vr = Vr.active()
	_hide_screen(parent)
	progress = LeafProgress.open_at(progress_path)
	_root = Node3D.new()
	_root.name = "Voyage"
	_root.position = ROOM_ORIGIN
	add_child(_root)
	garden = LeafGarden.new(plant_name())
	garden.position = GARDEN_AT
	garden.plant_blocks = int(progress.plant(plant_name()).get("blocks", LeafProgress.START_BLOCKS))
	_root.add_child(garden)
	garden.show_stage(LeafProgress.DROOP, false)
	place = LeafPlace.new(str(journey.voyage.get("dressing", "sunflower")), seed)   # built a step a frame in the garden
	place.staged = true
	place.position = LEAF_AT
	place.visible = false
	_root.add_child(place)
	if not vr:
		dive = LeafDive.new()
		dive.staged = true
		dive.position = DIVE_AT
		dive.visible = false
		_root.add_child(dive)
	camera = Camera3D.new()
	camera.name = "LeafCamera"
	camera.fov = FOV
	camera.near = 0.05
	camera.far = 60.0
	add_child(camera)
	stand = Node3D.new()
	stand.name = "Stand"
	add_child(stand)
	leaf_hud = LeafHud.new()
	hud = leaf_hud
	UiLayers.route(hud, self)
	hud.set_vr(vr)
	hud.set_voice(PlayVoice.on())
	hud.finger.connect(_on_finger)
	hud.show_me.connect(show_me)
	hud.break_changed.connect(func(open_now: bool) -> void: paused = open_now)
	hud.stop_for_now.connect(stop_for_now)
	leaf_hud.camera_pressed.connect(toggle_camera)
	leaf_hud.end_chosen.connect(end_choice)
	_was_camera = get_viewport().get_camera_3d()
	leaf_hud.show_camera(false)
	_use_env(garden.env)
	_cam_to = garden.camera_transform(LeafGarden.GARDEN)
	camera.global_transform = _cam_to
	if vr:
		ghost_hands = LifeGhostHands.new()
		add_child(ghost_hands)
		beam = _make_beam()
		add_child(beam)
		vr_hands = LeafVrHands.new(self)
		Vr.view_like(camera)
		stand_at(garden, LeafGarden.GARDEN, true)
	else:
		camera.make_current()
	journey.start()
	_take_cues()


## The plant the voyage's garden holds ("sunflower" or "cactus").
func plant_name() -> String:
	return str(journey.voyage.get("plant", "sunflower"))


## The place the child is in now: the garden or the leaf.
func room() -> LeafRoom:
	match journey.stage:
		LeafJourney.UNDER, LeafJourney.INSIDE:
			return place
	return garden


func stage() -> String:
	return journey.stage


# --- Every frame ---------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	step(delta)


## One frame of `delta` seconds (tests call it with their own time).
func step(delta: float) -> void:
	if closed:
		return
	if vr and not Vr.active():
		vr = false   # the headset came off: carry on flat
		hud.set_vr(false)
		camera.make_current()
	_step_builds()
	if paused:
		return
	journey.step(delta)
	_take_cues()
	_step_stage(delta)
	_step_acts(delta)
	_step_keys(delta)
	_step_camera(delta)
	_step_ghost_finger(delta)
	if vr and vr_hands != null:
		vr_hands.step(delta)


func _take_cues() -> void:
	for c: Dictionary in journey.take_cues():
		if c.has("say"):
			_say_line(str(c.say))
		elif c.has("glow"):
			var names: Array[String] = []
			for t: Variant in c.glow:
				names.append(str(t))
			if room() != null:
				room().glow(names)
		elif c.has("ghost"):
			_ghost_cue(c)
		elif c.has("stage"):
			_on_stage(str(c.stage))
		elif c.has("beat"):
			_on_beat(c.beat)


func _say_line(id: String) -> void:
	var text := LeafVoyages.line(id)
	if text != "":
		hud.say(text, -1, 0, "")


## A judged beat: each solved one pays the School's first-try gold at once (EarnRules; the daily cap holds).
func _on_beat(r: Dictionary) -> void:
	if SkillShown.COUNTS.has(str(r.get("kind", ""))) and first_try_gold.is_valid():
		gold_earned += int(first_try_gold.call())


# --- The stages ----------------------------------------------------------------------------------------------------

func _on_stage(s: String) -> void:
	match s:
		LeafJourney.DIVE:
			_begin_dive()
		LeafJourney.UNDER:
			if dive:
				dive.visible = false
			place.visible = true
			_use_env(place.env)
			_camera_to(place.camera_transform(LeafPlace.UNDER), 0.0)
			if vr:
				_end_growth()
				stand_at(place, LeafPlace.UNDER, true)
		LeafJourney.INSIDE:
			_begin_inside()
		LeafJourney.RETURN:
			_record()
			leaf_hud.show_camera(false)
			if not vr and dive:
				dive.visible = true
				_use_env(dive.env)
			place.visible = false
			if avatar:
				avatar.visible = false
		LeafJourney.ANSWER:
			if dive:
				dive.visible = false
			garden.visible = true
			_use_env(garden.env)
			garden.set_evening(true)
			garden.set_blocks(garden.plant_blocks + LeafProgress.GROWTH, garden.soil_blocks)
			garden.set_bloom(0.0)
			_answer_t = 0.0
			_camera_to(garden.camera_transform(LeafGarden.GARDEN), 0.0)
			if vr:
				stand_at(garden, LeafGarden.GARDEN, true)
		LeafJourney.END:
			garden.set_bloom(1.0)
			leaf_hud.show_end(plant_name(), _stars_after(), _gold_after())


func _begin_dive() -> void:
	garden.glow([] as Array[String])
	_cancel_ghost_finger()
	if _pour_t >= 0.0:   # the leaf touched mid-pour: the can is home again
		_pour_t = -1.0
		garden.can_home()
	_finish_builds()
	if vr:
		return
	dive.visible = true
	garden.visible = false
	_use_env(dive.env)


## The leaf's place and the dive are built a step a frame while the child is in the garden (a phone never stops for a
## whole place at once); a child who dives at once waits for what is left.
func _step_builds() -> void:
	if place != null and not place.built:
		place.build_step()
	elif dive != null and not dive.built:
		dive.build_step()


func _finish_builds() -> void:
	while place != null and not place.built:
		place.build_step()
	while dive != null and not dive.built:
		dive.build_step()


func _begin_inside() -> void:
	place.visible = true
	place.glow([] as Array[String])
	if vr:
		stand_at(place, LeafPlace.WORK, true)
		return
	avatar = LeafAvatar.new()
	place.add_child(avatar)
	var v := place.view(LeafPlace.WORK)
	avatar.global_position = place.to_global(v.feet)
	avatar.rotation.y = PI
	hoot = LeafKit.hoot(avatar, Vector3(0.62, 1.2, -0.15), PI, 0.7)
	_camera_to(_overview(), GLIDE_MAX)
	leaf_hud.show_camera(true)


func _step_stage(dt: float) -> void:
	match journey.stage:
		LeafJourney.HOOK:
			_step_pour(dt)
		LeafJourney.DIVE:
			if vr:
				_grow_garden(journey.progress())
			elif dive:
				dive.pose(journey.progress())
				_camera_to(dive.camera_transform(), 0.0)
		LeafJourney.INSIDE:
			var run := journey.run
			place.show_sim(run.sim, run.weather_now(), dt)
			if avatar:
				avatar.set_carried(run.carried())
		LeafJourney.RETURN:
			if not vr and dive:
				dive.pose(1.0 - journey.progress())
				_camera_to(dive.camera_transform(), 0.0)
		LeafJourney.ANSWER:
			_answer_t += dt
			garden.set_bloom(_answer_t / BLOOM_TIME)


func _step_pour(dt: float) -> void:
	if _pour_t < 0.0:
		return
	_pour_t += dt
	garden.set_pour(_pour_t / POUR_TIME)
	if _pour_t >= POUR_TIME * 0.6 and not journey.watered:
		water_now()
	if _pour_t >= POUR_TIME:
		_pour_t = -1.0
		garden.can_home()


## The soil is watered (the flat can's pour, or the VR hands' tilt).
func water_now() -> void:
	if journey.water():
		garden.show_stage(LeafProgress.DROOP, true)


## VR: the garden grows round the child's feet (the head never moves): its root scaled about the stand's feet point.
func _grow_garden(p: float) -> void:
	var s := lerpf(1.0, GROW_TO, smoothstep(0.0, 1.0, p))
	var feet := stand.global_position - Vector3(0, LifeRoom.EYE, 0)
	garden.scale = Vector3.ONE * s
	garden.global_position = feet + (ROOM_ORIGIN + GARDEN_AT - feet) * s


func _end_growth() -> void:
	garden.visible = false
	garden.scale = Vector3.ONE
	garden.position = GARDEN_AT


# --- The record and the end ------------------------------------------------------------------------------------------

func _record() -> void:
	if _recorded:
		return
	_recorded = true
	journey.run.record(shown)
	progress.finish(voyage_id, journey.run.beats.results)
	progress.save()


## The end card's stars: the unit's after this voyage counts (as SkillShown.record_round will count it).
func _stars_after() -> int:
	var total := shown.total(unit_id)
	var right := shown.right_first(unit_id)
	if total < MasteryRules.ROUND_SIZE and stars < MasteryRules.MASTERED:
		return stars
	if MasteryRules.is_mastery(right, total):
		return maxi(stars, MasteryRules.MASTERED)
	return maxi(stars, 1)


## The end card's gold: what the solved beats paid, and the unit's gold when this voyage masters it.
func _gold_after() -> int:
	var unit_gold := MasteryRules.UNIT_GOLD if stars < MasteryRules.MASTERED and _stars_after() >= MasteryRules.MASTERED \
		else 0
	return gold_earned + unit_gold


## The end card's (and the board's) choice: AGAIN (this voyage again), NEXT (the voyage board), BACK, or a voyage id.
func end_choice(what: String) -> void:
	if closed or journey.stage != LeafJourney.END:
		return
	match what:
		AGAIN:
			_finish_voyage({"voyage": voyage_id})
		NEXT:
			leaf_hud.show_board(board_open_voyages())
		BACK:
			_finish_voyage({})
		_:
			if board_open_voyages().has(what):
				_finish_voyage({"voyage": what})


## The voyages the board offers now (5.1 always; 5.T1 once 5.1 is done).
func board_open_voyages() -> Array[String]:
	return progress.open_voyages()


func _finish_voyage(then: Dictionary) -> void:
	if closed:
		return
	_record()
	closed = true
	var task := str(PlayBlock.of(content).get("world_task", ""))
	outcome = {"right_first": shown.right_first(unit_id), "total": shown.total(unit_id), "world_task": task,
		"shown": shown, "voyage": voyage_id, "then": then}
	finished.emit(outcome)
	close()


## STOP FOR NOW: nothing recorded, but the plant keeps the bud's fill (never less plant). After the voyage's end it is
## the end card's BACK: a finished voyage is never lost.
func stop_for_now() -> void:
	if closed:
		return
	if _recorded:
		_finish_voyage({})
		return
	var bud := float(journey.voyage.get("sim", {}).get("bud", 12.0))
	progress.keep(voyage_id, clampf(journey.run.sim.bud / maxf(bud, 1.0), 0.0, 1.0))
	progress.save()
	closed = true
	stopped.emit({"right_first": 0, "answered": 0, "voyage": voyage_id})
	close()


## SHOW ME: the ghost does one step (that beat is helped): in the garden the next thing glows and the ghost shows it.
func show_me() -> void:
	if closed or paused:
		return
	if journey.stage == LeafJourney.INSIDE:
		journey.run.show_me()
		_take_cues()
	elif journey.stage == LeafJourney.HOOK:
		_ghost_cue({"ghost": "can" if journey.has_can() and not journey.watered else "leaf"})


func close() -> void:
	if vr_hands != null:
		vr_hands.release()
	super()


# --- Flat: taps, glides, the camera ----------------------------------------------------------------------------------

func _on_finger(kind: String, pos: Vector2) -> void:
	match kind:
		"down":
			finger_down(pos)
		"move":
			_drag(pos)
		"up":
			finger_up(pos)


func finger_down(pos: Vector2) -> void:
	if closed or paused:
		return
	_finger_on = true
	_dragging = false
	_down_at = pos
	_finger_at = pos


func _drag(pos: Vector2) -> void:
	if not _finger_on:
		return
	if not _dragging and pos.distance_to(_down_at) >= DRAG_PX:
		_dragging = true
	if _dragging:
		var d := pos - _finger_at
		_look.x = clampf(_look.x - d.x * DRAG_LOOK, -1.0, 1.0)
		_look.y = clampf(_look.y - d.y * DRAG_LOOK, -0.6, 0.6)
	_finger_at = pos


## A finger lifted without a drag: a tap on the thing under it.
func finger_up(pos: Vector2) -> void:
	if not _finger_on:
		return
	_finger_on = false
	if _dragging:
		_dragging = false
		return
	var t := pick(pos)
	if t != "":
		tap_target(t)


## The thing to tap under a canvas point: the nearest of the view's things in reach of a finger ("" none).
func pick(pos: Vector2) -> String:
	var r := room()
	if r == null or camera == null:
		return ""
	var at := {}
	var radius := {}
	for t: String in _tappable():
		if not r.has_target(t):
			continue
		var p := r.target_position(t)
		if camera.is_position_behind(p):
			continue
		at[t] = camera.unproject_position(p)
		radius[t] = (camera.unproject_position(p + camera.global_basis.x * r.target_radius(t)) - at[t]).length()
	return LifeReach.screen_pick(pos, at, radius)


func screen_of(t: String) -> Vector2:
	return camera.unproject_position(room().target_position(t))


## What a tap can act on now: the garden's things in the hook; inside, the doors, the pipes and the sugar waiting.
func _tappable() -> Array[String]:
	var out: Array[String] = []
	match journey.stage:
		LeafJourney.HOOK:
			out = garden.flat_targets(LeafGarden.GARDEN)
		LeafJourney.INSIDE:
			for t: String in place.flat_targets(LeafPlace.WORK):
				if not t.begins_with("sugar_"):
					out.append(t)
			for k: int in place.waiting_spots():
				out.append("sugar_%d" % k)
	return out


## The sugar a tap would take (the first shown; "" when none waits).
func waiting_sugar() -> String:
	var spots := place.waiting_spots() if place else ([] as Array[int])
	return "sugar_%d" % spots[0] if not spots.is_empty() else ""


## One tap on a thing: in the garden the can pours and the leaf dives; inside, the avatar glides there and acts.
func tap_target(t: String) -> void:
	if closed or paused:
		return
	match journey.stage:
		LeafJourney.HOOK:
			if t == "can" or t == "soil":
				if journey.has_can() and not journey.watered and _pour_t < 0.0:
					_pour_t = 0.0
					_cancel_ghost_finger()
			elif t == "leaf":
				journey.touch_leaf()
				_take_cues()
		LeafJourney.INSIDE:
			if _queue.size() < 3 and not _queue.has(t) and _acting != t:
				_queue.append(t)
				_name_once(t)


func _name_once(t: String) -> void:
	var kind := "door" if t.begins_with("door_") else "sugar" if t.begins_with("sugar_") else t
	if NAMES.has(kind) and not _named.has(kind):
		_named[kind] = true
		PlayVoice.say(str(NAMES[kind]))


## The avatar is gliding or has acts waiting.
func busy() -> bool:
	return _acting != "" or not _queue.is_empty() or _pour_t >= 0.0


func _step_acts(dt: float) -> void:
	if avatar == null or journey.stage != LeafJourney.INSIDE:
		return
	avatar.step(dt)
	if _acting != "" and not avatar.gliding():
		_act(_acting)
		_acting = ""
		_dwell = DWELL
	if _acting == "" and not _queue.is_empty():
		var t: String = _queue.pop_front()
		var v := place.view(_view_of(t))
		var feet: Vector3 = place.to_global(v.feet) if (v.get("feet", Vector3.INF) as Vector3).is_finite() \
			else place.target_position(t)
		_acting = t
		var yaw := float(v.get("yaw", NAN))
		var time := avatar.glide_to(feet, yaw + PI if not is_nan(yaw) else NAN, GLIDE_MAX)   # facing the thing
		if not first_person and place.views.has(_view_of(t)):
			_camera_to(place.camera_transform(_view_of(t)), maxf(time, 0.3))
	if _dwell >= 0.0 and _acting == "" and _queue.is_empty():
		_dwell -= dt
		if _dwell < 0.0 and not first_person:
			_camera_to(_overview(), GLIDE_MAX)


func _act(t: String) -> void:
	var run := journey.run
	if t.begins_with("door_"):
		run.toggle(int(t.get_slice("_", 1)))
	elif t.begins_with("sugar_"):
		if run.carried() < LeafAvatar.MAX_CARRY and run.take():
			place.take_sugar(int(t.get_slice("_", 1)))
	elif t == "gold_pipe":
		run.deliver("gold")
	elif t == "blue_pipe":
		run.deliver("blue")
	avatar.set_carried(run.carried())
	_take_cues()


## A target's own view in the place (its pipe's view has the pipe's colour for a name).
static func _view_of(t: String) -> String:
	if t == "gold_pipe":
		return "gold"
	if t == "blue_pipe":
		return "blue"
	if t.ends_with("_a") or t.ends_with("_b"):
		return t.left(-2)
	return t


func _overview() -> Transform3D:
	return place.camera_transform(LeafPlace.WORK)


## The camera button: the avatar's eyes, or back over its shoulder.
func toggle_camera() -> void:
	if vr:
		return
	first_person = not first_person
	_look = Vector2.ZERO
	if avatar and avatar.body:
		avatar.body.visible = not first_person   # the avatar's own eyes: its body is not in the way
	if journey.stage == LeafJourney.INSIDE and avatar:
		_camera_to(_eyes_view() if first_person else _overview(), GLIDE_MAX)


func _eyes_view() -> Transform3D:
	var from := avatar.eyes()
	var ahead := avatar.global_basis.z
	ahead.y = 0.0
	if ahead.length() < 0.01:
		ahead = Vector3.FORWARD
	var to := from + ahead.normalized() * 3.0 + Vector3(0, -0.6, 0)
	return Transform3D(Basis.looking_at(to - from, Vector3.UP), from)


func _camera_to(xf: Transform3D, seconds: float) -> void:
	_cam_from = camera.global_transform if camera else xf
	_cam_to = xf
	_cam_time = seconds
	_cam_t = 0.0 if seconds > 0.0 and not UiMotion.calm() else -1.0
	if _cam_t < 0.0 and camera:
		camera.global_transform = xf


func _step_camera(dt: float) -> void:
	if vr or camera == null:
		return
	var base := _cam_to
	if first_person and journey.stage == LeafJourney.INSIDE and avatar and _cam_t < 0.0:
		base = _eyes_view()
	if _cam_t >= 0.0:
		_cam_t += dt
		var k := smoothstep(0.0, 1.0, clampf(_cam_t / maxf(_cam_time, 0.001), 0.0, 1.0))
		base = _cam_from.interpolate_with(_cam_to, k)
		if _cam_t >= _cam_time:
			_cam_t = -1.0
	if _look != Vector2.ZERO:
		base.basis = Basis(Vector3.UP, _look.x) * base.basis * Basis(Vector3.RIGHT, _look.y)
	camera.global_transform = base


## Keys (WASD and the arrows, Space and E up, C and Q down), a mouse's drag and a game controller (the left stick flies,
## the right stick looks): free flight inside the leaf; the camera follows over the avatar's shoulder.
func _step_keys(dt: float) -> void:
	if vr or journey.stage != LeafJourney.INSIDE or avatar == null:
		return
	var look := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if look != Vector2.ZERO:
		_look.x = clampf(_look.x - look.x * LOOK_SPEED * dt, -1.0, 1.0)
		_look.y = clampf(_look.y - look.y * LOOK_SPEED * dt, -0.6, 0.6)
	var move := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var up := (1.0 if Input.is_action_pressed(&"fly_up") or Input.is_physical_key_pressed(KEY_SPACE) else 0.0) \
		- (1.0 if Input.is_action_pressed(&"fly_down") or Input.is_action_pressed(&"crouch") else 0.0)
	if move == Vector2.ZERO and up == 0.0:
		if _flying:
			_flying = false
			_dwell = DWELL
		return
	_flying = true
	_queue.clear()
	_acting = ""
	var yaw := VrRules.yaw_of(camera.global_basis)
	var v := Basis(Vector3.UP, yaw) * Vector3(move.x, 0.0, move.y) * FLY_SPEED + Vector3(0, up * FLY_SPEED, 0)
	avatar.fly(v, dt)
	var local := place.to_local(avatar.global_position + Vector3(0, LeafAvatar.HEIGHT * 0.5, 0))
	var free := place.space.push_out(local, AVATAR_RADIUS)
	avatar.global_position = place.to_global(free) - Vector3(0, LeafAvatar.HEIGHT * 0.5, 0)
	if not first_person:
		var behind := avatar.global_position + Basis(Vector3.UP, yaw) * Vector3(0, 2.6, 3.2)
		var at := avatar.global_position + Vector3(0, 0.9, 0)
		_camera_to(Transform3D(Basis.looking_at(at - behind, Vector3.UP), behind), 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if closed or paused or vr:
		return
	if event.is_action_pressed(&"camera_toggle"):
		toggle_camera()
		get_viewport().set_input_as_handled()
	elif (event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == JOY_BUTTON_A
			and event.is_pressed()) or (event is InputEventKey and (event as InputEventKey).pressed
			and (event as InputEventKey).keycode in [KEY_ENTER, KEY_KP_ENTER]):
		var t := pick(get_viewport().get_visible_rect().size * 0.5)
		if t != "":
			tap_target(t)
			get_viewport().set_input_as_handled()


# --- The ghost (flat: a finger; VR: the hands) -----------------------------------------------------------------------

func _ghost_cue(c: Dictionary) -> void:
	var steps: Array[String] = []
	match str(c.ghost):
		"can", "leaf":
			steps = [str(c.ghost)]
		"door":
			steps = ["door_%d" % int(c.get("door", 0))]
		"carry":
			var sugar := waiting_sugar()
			if sugar != "":
				steps = [sugar, "gold_pipe"]
	if steps.is_empty():
		return
	if vr:
		if ghost_hands != null and room() != null and room().has_target(steps[0]):
			ghost_hands.demonstrate("hands" if steps[0].begins_with("door_") else "touch",
				room().target_position(steps[0]), Vr.head_transform())
		return
	_ghost_steps = steps
	_ghost_wait = 0.0
	_show_ghost_finger(steps[0])


func _show_ghost_finger(t: String) -> void:
	if room() != null and room().has_target(t):
		hud.ghost.show_at(screen_of(t), "tap")


func _step_ghost_finger(dt: float) -> void:
	if _ghost_steps.is_empty():
		return
	_ghost_wait += dt
	if _ghost_wait < GHOST_TAP:
		return
	_ghost_wait = 0.0
	_ghost_steps.pop_front()
	if not _ghost_steps.is_empty():
		_show_ghost_finger(_ghost_steps[0])


func _cancel_ghost_finger() -> void:
	_ghost_steps.clear()


# --- VR stands -----------------------------------------------------------------------------------------------------

## VR: the child stands at `view`'s stand in `r` (`blink`: behind a blink, never glided across).
func stand_at(r: LifeRoom, view_name: String, blink: bool) -> void:
	stand.global_transform = r.vr_stand(view_name)
	if Vr.anchor_node() != stand:
		Vr.anchor(stand, &"life")
	if blink:
		Vr.blink()


# --- Showing ---------------------------------------------------------------------------------------------------------

func _use_env(env: Environment) -> void:
	if camera:
		camera.environment = env
	if vr:
		Vr.view_like(camera)
