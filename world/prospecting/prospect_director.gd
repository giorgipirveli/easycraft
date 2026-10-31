class_name ProspectDirector
extends Node
## Prospecting in a played world (spec §26; the sandbox's node "Prospecting", Green Meadows and the Sandstorm Desert, in
## the Sandbox and Survivor, never in Monster Wave's arena). For this game's child:
## - Gemma's camp a short walk from the spawn (ProspectCamp, from the seed, on a worker: the same place on every game);
##   walking up to her opens her board (ProspectBoard), as DIG in MORE and J on a PC do anywhere;
## - a quest started leads to the nearest deposit of its kind this world has and nobody found here (DepositRules, on a
##   worker; the next one is farther on); its steps (ProspectQuests) move on as the child answers them on the board or
##   walks there and finds the sign (a real fact on the screen); the HUD's compass points to the step's place;
## - MARK IT: the deposit goes on MY MAP (marks are kept in the world's save and put back every game), the quest pays
##   its gold (ProspectRewards: EarnRules' lines; Survivor through the host's wallet, the Sandbox into the profile like
##   the School), an oil quest stands an oil well (OilWell) whose pump jack fills drums of crude oil into a Survivor bag;
## - with the Gold Shop's Metal Detector, metal near the child beeps faster as they come closer.
## The world's part is saved in WorldMeta.prospect (ProspectState), the child's in ProfileData.prospect. A LAN guest sees
## the camp and the wells but prospects in their own world (a ruling: the deposits and their gold are the host's world's).
## Nothing per frame but a quarter-second look (and the detector's beeps).
## Spec §26.5: on the Moon and Mars the same, with Gemma the space geologist's camp by the landing pad (a spacesuit, a
## little habitat; off the colony's ground), the planet's own five quests, and the Ice Finder's clicks near ice; the
## planet guide's compass asks quest_target first (the sandbox).

signal changed

const TICK := 0.25
const SEARCH_RINGS: Array[int] = [1, 2, 3]
## Spec §26.5: her name and her hello on the Moon and Mars.
const SPACE_WHO := "Gemma the space geologist"
const SPACE_HELLO := "Hello, explorer! Out here we live off the land: ice gives water, air and rocket fuel. Pick a quest, and I'll teach you to find the riches of %s."


# --- Injected by the sandbox (tests use stand-ins) ---
var universe := 1
var host := true
var survivor := false
var player_position: Callable = func() -> Vector3: return Vector3.INF
var overlay_open: Callable = func() -> bool: return false
var toast: Callable = func(_text: String) -> void: pass
var mark_map: Callable = func(_entry: Dictionary) -> void: pass
## (gold) -> void: pays this child (Survivor: Session.gold_add; the Sandbox: EarnRules.credit, like the School).
var pay: Callable = func(_gold: int) -> void: pass
## () -> int: an exercise right the first time (EarnRules.answer_gold, the School's cap).
var answer_gold: Callable = func() -> int: return 0
## (id, n) -> bool: into this child's Survivor bag.
var give: Callable = func(_id: int, _n: int) -> bool: return false
var save_profile: Callable = func() -> void: Profile.save()
var today: Callable = func() -> int: return SchoolClock.today()
var has_detector: Callable = func() -> bool: return ProspectGear.has_detector(Profile.data)
## Spec §26.5: the Gold Shop's Ice Finder (it clicks near the Moon's and Mars's ice).
var has_ice_finder: Callable = func() -> bool: return ProspectGear.has_ice_finder(Profile.data)
var gold: Callable = func() -> int: return Profile.data.survivor_gold
var beep: Callable = func() -> void: Audio.play(&"beep", Vector3.INF, -8.0)
var auto_tick := true
## Find the camp and the deposits on a worker thread (tests: at once).
var search_later := true

# --- The world's prospecting ---
var shape: MeadowsShape
var deposits: DepositRules
var state := ProspectState.new()
var data := ProspectData.new()
var meta: WorldMeta
var camp: ProspectCamp
var camp_at := Vector3.INF
var board: ProspectBoard
var wells := {}                   # deposit id -> OilWell
var world_seed := 0

var _t := 0.0
var _beep_t := 0.0
var _near_gemma := false
var _dismissed := false
var _near_well := ""
var _pending_step := &""          # a quest whose next step waits for the board (another menu was open)
var _camp_task := -1
var _camp_found: Array = [{}]
var _search_task := -1
var _search_found: Array = [{}]
var _search_kind := &""
var _steps_cache := {}            # "kind|deposit|camp" -> the quest's steps
var _metal := {}                  # the detector's last look (compass_target)
var _metal_at_ms := -100000
var _metal_from := Vector3.INF


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## The world's prospecting: its terrain and deposits (the generator's own, shared), the host's save (null on a guest),
## this child's profile part, and where the board goes. `launch_pad`: the Launch Site's pad (INF: none or not known).
func setup(p_shape: MeadowsShape, p_deposits: DepositRules, p_meta: WorldMeta, p_data: ProspectData, ui_parent: Node,
		launch_pad: Vector3 = Vector3.INF) -> void:
	shape = p_shape
	deposits = p_deposits
	meta = p_meta
	world_seed = p_shape.seed if p_shape else 0
	if p_data != null:
		data = p_data
	if meta != null and host:
		state = ProspectState.from_dict(meta.prospect)
	board = ProspectBoard.new()
	board.guest = not host
	if shape is SpaceShape:   # spec §26.5: Gemma the space geologist
		board.who = SPACE_WHO
		board.hello_words = SPACE_HELLO % UniverseRegistry.display_name(universe).replace("The ", "the ")
	board.quests = quest_cards
	board.step_view = step_view
	board.finds = found_list
	board.distance_to = distance_to_step
	board.first_try_gold = answer_gold
	board.gold = gold
	var s := shape
	board.map_sampler = func(x: float, z: float) -> Color: return ProspectMap.terrain_colour(s, x, z)
	if shape is SpaceShape:   # spec §26.5: the Moon's craters drawn once per map, fewer samples
		var craters := [SpaceDepositSites.Cols.new(shape as SpaceShape)]
		board.map_samples = ProspectMap.SPACE_SAMPLES
		board.map_sampler = func(x: float, z: float) -> Color:
			if (craters[0] as SpaceDepositSites.Cols).cells() > 4096:
				craters[0] = SpaceDepositSites.Cols.new(s as SpaceShape)   # many maps later: start afresh
			return ProspectMap.terrain_colour(s, x, z, craters[0])
	board.start_pressed.connect(start)
	board.step_answered.connect(answered)
	board.mark_pressed.connect(mark)
	board.closed.connect(func() -> void: _dismissed = _near_gemma)
	if ui_parent:
		ui_parent.add_child(board)
	_find_camp(launch_pad)
	for id in state.found:
		_show_found(id)


func _exit_tree() -> void:
	for t: int in [_camp_task, _search_task]:
		if t != -1:
			WorkerThreadPool.wait_for_task_completion(t)
	_camp_task = -1
	_search_task = -1


func _find_camp(launch_pad: Vector3) -> void:
	if shape == null or deposits == null:
		return
	var s := shape
	var sp := deposits.spawn
	var u := universe
	var seed_ := world_seed
	var pad_known := launch_pad
	var job := func() -> Dictionary:
		var pad := pad_known
		if not pad.is_finite() and SpaceRules.is_home(u):   # a home world's Launch Site, from the seed (LaunchDirector's)
			var site := LaunchSite.pick_for(s, TheaterSite.pick_for(s))
			if not site.is_empty():
				pad = Vector3(site.pos as Vector3i)
		return ProspectCamp.spot_for_world(seed_, s, sp, u, pad)
	if not search_later:
		_stand_camp(job.call())
		return
	var out := _camp_found
	_camp_task = WorkerThreadPool.add_task(func() -> void: out[0] = job.call(), true, "Gemma's camp")


func _stand_camp(spot: Dictionary) -> void:
	if spot.is_empty():
		return
	camp_at = spot.pos
	if camp:
		camp.queue_free()
	camp = ProspectCamp.new()
	camp.player_position = player_position
	add_child(camp)
	camp.setup(spot)
	_update_bubble()


func _process(delta: float) -> void:
	if _camp_task != -1 and WorkerThreadPool.is_task_completed(_camp_task):
		WorkerThreadPool.wait_for_task_completion(_camp_task)
		_camp_task = -1
		_stand_camp(_camp_found[0])
	if _search_task != -1 and WorkerThreadPool.is_task_completed(_search_task):
		WorkerThreadPool.wait_for_task_completion(_search_task)
		_search_task = -1
		_begin(_search_kind, _search_found[0])
	if not auto_tick:
		return
	_t += delta
	if _t >= TICK:
		_t = 0.0
		tick()
	_beep_step(delta)


## One look: Gemma, the wells, the quest's walking step, a step waiting for the board.
func tick() -> void:
	var feet: Vector3 = player_position.call()
	var paused := is_inside_tree() and get_tree().paused
	var busy: bool = paused or overlay_open.call()
	# Gemma: walking up opens her board (after X it stays closed until the child walks away and back).
	var near := not paused and ProspectCamp.near_gemma(camp_at, feet)
	if near and not _near_gemma and not _dismissed and not busy and board and not board.is_open():
		if state.active != &"" and not _walking(state.active):
			board.open_step(state.active)
		else:
			board.open_quests()
	if not near:
		_dismissed = false
	_near_gemma = near
	# An oil well: walking up to its pump jack pumps a drum.
	var well := ""
	for id: String in wells:
		if (wells[id] as OilWell).near(feet):
			well = id
	if well != "" and well != _near_well:
		pump(well)
	_near_well = well
	# The quest's walking step.
	if host and state.active != &"":
		arrive_check(feet)
	if _pending_step != &"" and not busy and board and not board.is_open():
		var k := _pending_step
		_pending_step = &""
		board.open_step(k)


# --- The quests -------------------------------------------------------------------------------------------------------

## What Gemma's cards show: the kinds of this world's place (Earth's six, this world's first; a planet's own five).
func quest_cards() -> Array:
	var out: Array = []
	for kind in DepositKinds.told_in(universe):
		var q := ProspectQuests.quest(kind)
		var here := DepositKinds.universe_of(kind) == universe
		var status := "going" if state.has_quest(kind) else ("done" if data.has_done(kind) else "new")
		var found := 0
		for id in state.found:
			if id.begins_with(String(kind) + ":"):
				found += 1
		var steps: Array[Dictionary] = steps_of(kind) if state.has_quest(kind) else ([] as Array[Dictionary])
		out.append({"kind": kind, "title": q.get("title", ""), "story": q.get("story", ""), "here": here,
			"where": "the Sandstorm Desert" if DepositKinds.universe_of(kind) == 2 else "Green Meadows",
			"status": status, "step": state.step_of(kind), "steps": steps.size(), "found": found})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return bool(a.here) and not bool(b.here))
	return out


## The quest's steps in this world (the same every game: its deposit, the camp, the seed's roll). Worked out once
## per deposit and camp (the HUD's compass asks every frame).
func steps_of(kind: StringName) -> Array[Dictionary]:
	var camp := camp_at if camp_at.is_finite() else _spawn3()
	var key := "%s|%s|%s" % [kind, state.deposit_of(kind), camp]
	if _steps_cache.has(key):
		return _steps_cache[key]
	var steps := ProspectQuests.steps(kind, deposit_of(kind), camp, roll(kind))
	if _steps_cache.size() > 16:
		_steps_cache.clear()
	_steps_cache[key] = steps
	return steps


func deposit_of(kind: StringName) -> Dictionary:
	return deposits.find(state.deposit_of(kind)) if deposits else {}


func roll(kind: StringName) -> int:
	return absi(hash("%d:%s" % [world_seed, kind])) % 1000


## The board's view of a quest's step now ({} when it has none).
func step_view(kind: StringName) -> Dictionary:
	if not state.has_quest(kind):
		return {}
	var steps := steps_of(kind)
	var i := state.step_of(kind)
	if i < 0 or i >= steps.size():
		return {}
	return {"kind": kind, "title": ProspectQuests.quest(kind).get("title", ""), "index": i, "count": steps.size(),
		"step": steps[i]}


func current_step(kind: StringName) -> Dictionary:
	var v := step_view(kind)
	return v.get("step", {})


## START / GO ON / FIND ANOTHER: the quest goes on where it was, or looks for its next deposit (on a worker).
func start(kind: StringName) -> bool:
	if not host:
		toast.call("These rocks belong to your friend's world. Start a quest in your own world!")
		return false
	if DepositKinds.universe_of(kind) != universe or deposits == null:
		return false
	if state.has_quest(kind):
		state.start(kind, state.deposit_of(kind))
		_saved()
		board.open_step(kind)
		return true
	if _search_task != -1:
		return false
	var rules := deposits
	var from := camp_at if camp_at.is_finite() else _spawn3()
	var skip: Array = state.found.duplicate()
	var job := func() -> Dictionary:
		for rings in SEARCH_RINGS:
			var d := rules.nearest(kind, from, skip, rings)
			if not d.is_empty():
				return d
		return {}
	_search_kind = kind
	if not search_later:
		return _begin(kind, job.call())
	var out := _search_found
	_search_task = WorkerThreadPool.add_task(func() -> void: out[0] = job.call(), true, "Gemma's map")
	return true


func _begin(kind: StringName, d: Dictionary) -> bool:
	if d.is_empty():
		toast.call("Gemma: I haven't spotted any more of it near here. We'll look again later!")
		return false
	state.start(kind, d.id)
	_saved()
	board.open_step(kind)
	return true


## Every exercise of step `step` was answered on the board: the quest moves on.
func answered(kind: StringName, step: int) -> void:
	var s := current_step(kind)
	if s.is_empty() or state.step_of(kind) != step or ProspectQuests.exercises(s).is_empty():
		return
	_advance(kind, step)
	if board and board.is_open():
		board.show_step(kind)


## A walking step done by feet at `feet` (the quest being followed): true when it moved on.
func arrive_check(feet: Vector3) -> bool:
	var kind := state.active
	var s := current_step(kind)
	if s.is_empty() or not s.type in [ProspectQuests.REACH, ProspectQuests.SIGN]:
		return false
	if not ProspectQuests.arrived(s, deposit_of(kind), feet):
		return false
	var step := state.step_of(kind)
	_advance(kind, step)
	Audio.play(&"sparkle")
	if s.type == ProspectQuests.SIGN:
		toast.call("You found it! %s" % str(s.get("fact", "")))
	else:
		toast.call("You're there!")
	var next := current_step(kind)
	if next.is_empty():
		return true
	if next.type in [ProspectQuests.REACH, ProspectQuests.SIGN]:
		if s.type != ProspectQuests.SIGN:
			toast.call(str(next.words) + "!")
	else:
		_pending_step = kind   # the board opens on it as soon as nothing else covers the screen
	return true


func _advance(kind: StringName, step: int) -> void:
	state.advance(kind, step, steps_of(kind).size())
	_saved()


## MARK IT: the deposit goes on MY MAP, the quest pays its gold, an oil well stands on its dome.
func mark(kind: StringName) -> int:
	var s := current_step(kind)
	if s.is_empty() or s.type != ProspectQuests.MARK:
		return -1
	var first := not data.has_done(kind)
	var id := state.finish(kind)
	if id == "":
		return -1
	var gold_now := ProspectRewards.finish(data, kind, int(today.call()))
	if gold_now > 0:
		pay.call(gold_now)
	save_profile.call()
	_show_found(id)
	_saved()
	var d := deposits.find(id)
	var map_name := DepositKinds.mark_words(kind)
	if board:
		board.show_done(kind, ProspectRewards.words(gold_now, kind, first), map_name)
	print("PROSPECT %s found %s (+%d gold)" % [kind, id, gold_now])
	if kind == DepositKinds.OIL and not d.is_empty():
		toast.call("An oil well now stands on the dome: walk up to its pump jack!")
	return gold_now


## Pumps a drum from an oil well into a Survivor bag (the Sandbox shows how it works).
func pump(id: String) -> bool:
	if not host:
		return false
	if state.drums_left(id) <= 0:
		toast.call("This well is empty. Another oil quest finds more oil!")
		return false
	if not survivor:
		toast.call("The pump jack nods and lifts oil from deep down. In a Survivor world, it fills drums for you to refine!")
		return false
	if not give.call(BlockIds.CRUDE_OIL, 1):
		toast.call("Your bag is full of oil drums!")
		return false
	state.pump(id)
	_saved()
	toast.call("+1 Crude Oil! %d drums left in this well. A Refinery turns it into kerosene and plastic." % state.drums_left(id))
	Audio.play(&"pickup")
	return true


## What the found deposits are: [{kind, name, pos}], in the order they were found.
func found_list() -> Array:
	var out: Array = []
	for id in state.found:
		var d := deposits.find(id) if deposits else {}
		if d.is_empty():
			continue
		out.append({"kind": d.kind, "name": str(DepositKinds.data(d.kind).get("map", "")), "pos": Vector3(d.anchor)})
	return out


## The compass's target (TreasureCompass.guide): the quest's walking step's place; else, with the Metal Detector (and
## spec §26.5's Ice Finder), what it hears; else {}.
func compass_target(from: Vector3) -> Dictionary:
	var q := quest_target(from)
	if not q.is_empty():
		return q
	if has_detector.call() or has_ice_finder.call():
		var now := Time.get_ticks_msec()
		if now - _metal_at_ms > 500 or not _metal_from.is_equal_approx(from.snapped(Vector3.ONE * 4.0)):
			_metal_at_ms = now   # the compass asks every frame: look again twice a second (or after a few steps)
			_metal_from = from.snapped(Vector3.ONE * 4.0)
			_metal = _heard(from)
		if not _metal.is_empty():
			return {"chest": Vector3i((_metal.pos as Vector3).floor())}
	return {}


## Only the quest's walking step's place ({"chest": cell}), or {} (spec §26.5: the planet guide's compass asks this
## first, then points to the planet's next sight).
func quest_target(_from: Vector3) -> Dictionary:
	var kind := state.active
	if kind == &"":
		return {}
	var s := current_step(kind)
	if not s.is_empty() and s.type in [ProspectQuests.REACH, ProspectQuests.SIGN]:
		var at := ProspectQuests.target(s, deposit_of(kind))
		if at.is_finite():
			return {"chest": Vector3i(at.floor())}
	return {}


## What this child's gear hears nearest from `from`: the Metal Detector's metal, the Ice Finder's ice ({pos, distance}).
func _heard(from: Vector3) -> Dictionary:
	var metal := ProspectGear.nearest_metal(deposits, from) if has_detector.call() else {}
	var ice := ProspectGear.nearest_ice(deposits, from) if has_ice_finder.call() else {}
	if metal.is_empty() or (not ice.is_empty() and float(ice.distance) < float(metal.distance)):
		return ice
	return metal


## Metres from the child to the quest's walking step's place (-1: none).
func distance_to_step(kind: StringName) -> int:
	var s := current_step(kind)
	var feet: Vector3 = player_position.call()
	if s.is_empty() or not feet.is_finite():
		return -1
	var at := ProspectQuests.target(s, deposit_of(kind))
	return roundi(Vector2(at.x - feet.x, at.z - feet.z).length()) if at.is_finite() else -1


## DIG (MORE) and J: the board, on the step being done or the quests.
func open_journal() -> void:
	if board == null:
		return
	if board.is_open():
		board.close()
	elif state.active != &"":
		board.open_step(state.active)
	else:
		board.open_quests()


func close_if_open() -> bool:
	return board != null and board.close_if_open()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo \
			and event.is_action_pressed(&"prospect"):
		open_journal()
		if is_inside_tree():
			get_viewport().set_input_as_handled()


# --- The world's side ---------------------------------------------------------------------------------------------------

## A found deposit: its MY MAP mark, and an oil well on an oil dome.
func _show_found(id: String) -> void:
	var d := deposits.find(id) if deposits else {}
	if d.is_empty():
		return
	var a: Vector3i = d.anchor
	mark_map.call({"id": "deposit_" + id, "kind": ProspectPictures.map_kind(d.kind),
		"name": str(DepositKinds.data(d.kind).get("map", "")), "pos": Vector3(a.x + 0.5, a.y + 1, a.z + 0.5)})
	if d.kind == DepositKinds.OIL and not wells.has(id):
		var w := OilWell.new()
		add_child(w)
		w.setup(id, Vector3(a.x + 0.5, a.y + 1, a.z + 0.5), int(d.get("depth_m", 1000)))
		wells[id] = w


func _saved() -> void:
	if meta != null and host:
		meta.prospect = state.to_dict()
	_update_bubble()
	changed.emit()


func _update_bubble() -> void:
	if camp == null:
		return
	var waiting := false
	for kind in DepositKinds.in_universe(universe):
		if not state.has_quest(kind) and not data.has_done(kind):
			waiting = true
	camp.show_bubble("!" if waiting and host else "")


func _walking(kind: StringName) -> bool:
	var s := current_step(kind)
	return not s.is_empty() and s.type in [ProspectQuests.REACH, ProspectQuests.SIGN]


func _spawn3() -> Vector3:
	var sp := deposits.spawn if deposits else Vector2i.ZERO
	return Vector3(sp.x + 0.5, shape.height_at(sp.x, sp.y) if shape else 0.0, sp.y + 0.5)


## The Metal Detector (and the Ice Finder): beeps at SurveyRules.beeps(distance) a second near metal (ice).
func _beep_step(delta: float) -> void:
	_beep_t -= delta
	if _beep_t > 0.0 or not (has_detector.call() or has_ice_finder.call()):
		return
	_beep_t = 0.5
	var feet: Vector3 = player_position.call()
	var m := _heard(feet)
	if m.is_empty():
		return
	var rate := SurveyRules.beeps(float(m.distance))
	if rate <= 0.0:
		return
	beep.call()
	_beep_t = 1.0 / rate
