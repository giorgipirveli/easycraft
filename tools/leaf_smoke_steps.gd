extends Node
## The steps of tools/leaf_smoke.gd (a Node, so it may use the autoloads and the game's classes): each run opens a
## LeafVoyageHost, plays it with the rule (flat taps, or simulated hands), leaves the end card and checks the outcome.

const UNIT := "g5.science.plants_air_water"
const DT := 0.1
const LIMIT := 900.0

var _ok := true
var _golds := 0
var _outcomes: Array = []
## The VR bot's hands: what each is doing ("", "can", "pour", "sugar", "door").
var _vr_task := ""
var _vr_t := 0.0
var _vr_door := -1


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var modes := ["flat", "vr"]
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--modes="):
			modes = a.trim_prefix("--modes=").split(",")
	Profile.data.settings.reduce_motion = true
	for mode: String in modes:
		for voyage: String in ["5.1", "5.T1"]:
			await _one(voyage, mode)
	print("LEAF_SMOKE done %s" % ("ok" if _ok else "fail"))
	get_tree().quit(0 if _ok else 1)


func _one(voyage: String, mode: String) -> void:
	_golds = 0
	_outcomes.clear()
	var vr := mode == "vr"
	Vr.simulate(vr)
	await get_tree().process_frame
	await get_tree().process_frame
	var layer := CanvasLayer.new()
	add_child(layer)
	var screen := Control.new()
	layer.add_child(screen)
	var path := "user://leaf_smoke_%s_%s.json" % [voyage, mode]
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var host := LeafVoyageHost.new()
	host.progress_path = path
	host.setup(UNIT, {"id": UNIT, "exercises": [], "play": {"game": "leaf_voyage", "params": {"voyage": voyage}}}, 11, 0,
		{})
	host.first_try_gold = func() -> int:
		_golds += 1
		return 5
	host.finished.connect(func(o: Dictionary) -> void: _outcomes.append(o))
	host.open(screen)
	await get_tree().process_frame
	await get_tree().physics_frame
	host.set_process(false)
	var t := 0.0
	var words := 0
	var start := Time.get_ticks_msec()
	while t < LIMIT and host.journey.stage != LeafJourney.END:
		if vr:
			_vr_bot(host)
		else:
			_flat_bot(host)
		host.step(DT)
		words = maxi(words, host.hud.screen_words())
		t += DT
	var stage := host.journey.stage
	host.end_choice(LeafVoyageHost.BACK)
	var o: Dictionary = _outcomes[0] if not _outcomes.is_empty() else {}
	var shown: SkillShown = o.get("shown") if o.get("shown") is SkillShown else SkillShown.begin()
	var events := shown.total(UNIT)
	var right := shown.right_first(UNIT)
	var transfer := shown.transfer(UNIT)
	var good := stage == LeafJourney.END and events >= MasteryRules.ROUND_SIZE and MasteryRules.is_mastery(right, events) \
		and _golds == right and int(o.get("total", -1)) == events and int(o.get("right_first", -1)) == right \
		and (words == 0 or not PlayVoice.on()) and (voyage != "5.T1" or transfer >= 5)
	_ok = _ok and good
	print("LEAF_SMOKE voyage=%s mode=%s events=%d right_first=%d transfer=%d gold=%d words=%d voice=%s stage=%s seconds=%.1f %s"
		% [voyage, mode, events, right, transfer, _golds, words, "on" if PlayVoice.on() else "off (words as for a reader)",
		stage, t, "ok" if good else "FAIL"])
	print("  (%.1f s of wall time)" % ((Time.get_ticks_msec() - start) / 1000.0))
	layer.queue_free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	Vr.simulate(false)
	await get_tree().process_frame


# --- Flat: taps on the screen ----------------------------------------------------------------------------------------

func _flat_bot(host: LeafVoyageHost) -> void:
	match host.journey.stage:
		LeafJourney.HOOK:
			if host.busy():
				return
			if host.journey.has_can() and not host.journey.watered:
				_tap(host, "can")
			else:
				_tap(host, "leaf")
		LeafJourney.INSIDE:
			if host.busy():
				return
			var t := _rule_target(host)
			if t != "":
				_tap(host, t)


func _tap(host: LeafVoyageHost, t: String) -> void:
	var at := host.screen_of(t)
	host.finger_down(at)
	host.finger_up(at)


## What the rule does next: shut the doors in act 1 and in the heat, open them when it is cool, carry the sugar.
func _rule_target(host: LeafVoyageHost) -> String:
	var run := host.journey.run
	var want := run.phase == LeafRun.PLAY and bool(run.weather_now().open)
	for i in run.sim.doors.size():
		if run.sim.doors[i] != want:
			return "door_%d" % i
	if run.carried() > 0:
		return "gold_pipe"
	if run.sim.waiting() > 0 and run.phase == LeafRun.PLAY:
		return host.waiting_sugar()
	return ""


# --- VR: the hands (simulated) -----------------------------------------------------------------------------------------

func _vr_bot(host: LeafVoyageHost) -> void:
	var right := VrRules.RIGHT
	var other := VrRules.LEFT if Vr.pointing_hand() == VrRules.RIGHT else VrRules.RIGHT
	_vr_t += DT
	match host.journey.stage:
		LeafJourney.HOOK:
			var g := host.garden
			if host.journey.has_can() and not host.journey.watered:
				if _vr_task == "":
					_hand_at(right, g.target_position("can"))
					Vr.sim_input(right, &"grip", 1.0)
					_vr_task = "can"
				elif _vr_task == "can":
					var tilt := Basis(Vector3.RIGHT, -0.9)
					var rose := tilt * (LeafVrHands.CAN_IN_HAND * LeafGarden.ROSE)
					_hand_at(right, g.target_position("soil") + Vector3(0, 0.25, 0) - rose, tilt)
			else:
				if _vr_task == "can":
					Vr.sim_input(right, &"grip", 0.0)
					_vr_task = ""
				_hand_at(other, g.target_position("leaf"))
		LeafJourney.INSIDE:
			_vr_inside(host, right, other)
		_:
			_vr_task = ""


func _vr_inside(host: LeafVoyageHost, right: StringName, other: StringName) -> void:
	var run := host.journey.run
	var place := host.place
	match _vr_task:
		"door":   # the trigger was pressed on a door last step: let go
			Vr.sim_input(other, &"trigger", 0.0)
			_vr_task = ""
			return
		"sugar":
			_hand_at(right, place.target_position("gold_pipe"))
			_vr_task = "deliver"
			return
		"deliver":
			Vr.sim_input(right, &"grip", 0.0)
			_vr_task = "rest"
			return
		"rest":
			_hand_at(right, host.stand.global_position + Vector3(0.3, -0.4, -0.3))
			_vr_task = ""
			return
	var t := _rule_target(host)
	if t.begins_with("door_"):
		_hand_at(other, place.target_position(t))
		Vr.sim_input(other, &"trigger", 1.0)
		_vr_task = "door"
	elif t.begins_with("sugar_"):
		_hand_at(right, place.target_position(t))
		Vr.sim_input(right, &"grip", 1.0)
		_vr_task = "sugar"
	elif t == "gold_pipe":
		_hand_at(right, place.target_position("gold_pipe"))
		Vr.sim_input(right, &"grip", 1.0)
		_vr_task = "deliver"


func _hand_at(side: StringName, world: Vector3, basis: Basis = Basis()) -> void:
	var rig := Vr.rig.global_transform
	Vr.sim_hand(side, Transform3D(rig.basis.inverse() * basis, rig.affine_inverse() * world))
