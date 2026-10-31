class_name TutorialDirector
extends Node
## The tutorial with Pip (M3 Task 15, spec §14.9, §5.10): the sandbox's node "Tutorial", on this game only (it
## plays only in a solo Survivor world, so nothing of it goes over the network).
## - The first solo Survivor start offers PLAY WITH PIP / SKIP (TutorialOffer); owner #37's first-time shop tip
##   waits meanwhile (TradeDirector.hold_tip) and comes after a SKIP, a stop or a "later". SETTINGS' replay flag
##   starts it without the card (looked at once a second while it isn't playing).
## - Playing: "Pip's playground" (TutorialCourse: its site worked out on a worker thread; TutorialProps: its cells)
##   goes into the world once that part is loaded and the child isn't standing where it goes. Every changed cell is
##   recorded in WorldMeta.tutorial_props and the meta saved BEFORE the world changes, so a crash never keeps it; a
##   site with a child's build on it is turned down for another. A visiting Pip (the profile's own when there is
##   one) rolls beside the child. Each step shows TutorialCard (picture, words, dots, speaker, X), is said aloud
##   ("Read to me") and babbled by Pip, lights its cells (one BuildOutline), and is checked ten times a second from
##   the child's real actions (TutorialChecks). The arrow points at the step's place when the child is far off.
## - The end pays once (500 gold, Pip's Cap, Pip for keeps) and puts every cell back; blocks the child built into
##   it go back to their bag. The X stops it the same way (the visiting Pip goes home); it goes on from that step.
## - A crash's record is put back at the next start of that world (host or solo), before anything else is laid out.
## Everything the world, the player and the other directors do comes in as callables (tests use stand-ins).

signal step_started(i: int)
signal step_done(i: int)
signal finished(rewarded: bool)
signal stopped

const TICK := 0.1
const FAR_OFF := 12.0            # this far from the step's place, the arrow points there
const NEAR_START := 3.0          # the move step ends this close to the playground's start
const REPLAY_LOOK := 1.0         # seconds between looks at SETTINGS' replay while not playing
const BRIDGE_GIFT := 3
const PLACE_EVERY := 0.5         # seconds between tries to lay the playground out

# --- Given by the sandbox ---
## Where it plays (TutorialDirector.plays_now() in the sandbox): a solo Survivor world.
var here := false
var profile: ProfileData
var save_profile: Callable = func() -> void: Profile.save()
var meta: WorldMeta
var save_meta: Callable = func() -> void: pass
var world: WorldService
## (origin, size) -> Callable(Vector3i) -> int: one bulk copy of a box (WorldService.box_reader, instead of ~5,000 locked
## get_voxel reads; a worker thread may read it). Tests read the world directly.
var box_reader: Callable = func(origin: Vector3i, size: Vector3i) -> Callable: return world.box_reader(origin, size)
var player: Player
var hud: Hud
## The playground's site: () -> Dictionary, run on a worker thread. Unset: TutorialCourse.pick_for over `shape`
## around `spawn`, clear of avoid.call() and of sites turned down.
var pick_site := Callable()
var shape: MeadowsShape
var spawn := Vector2i.ZERO
var avoid: Callable = func() -> Array: return []
var on_floor: Callable = func() -> bool: return is_instance_valid(player) and player.is_on_floor()
## (record) -> void: a Pip comes beside the child (PetDirector.on_pip); () -> Node3D: this child's Pip or null.
var bring_pip: Callable = func(_record: Dictionary) -> void: pass
var pip_node: Callable = func() -> Node3D: return null
var send_pip_home: Callable = func(p: Node3D) -> void: p.queue_free()
## (pos, yaw) -> Node3D: the practice slime (a Monster with "practice"); (m) -> void: it puffs away.
var spawn_slime: Callable = func(_pos: Vector3, _yaw: float) -> Node3D: return null
var puff: Callable = func(m: Node3D) -> void: m.queue_free()
var gold_add: Callable = func(_n: int) -> void: pass
## () -> Inventory: this child's bag (the host's copy; solo).
var bag: Callable = func() -> Inventory: return Inventory.new()
## Owner #37's picture tip and arrow at Tilly (true when she is there); the held first-time tip, let go.
var show_tip: Callable = func() -> bool: return false
var release_tip: Callable = func() -> void: pass
var tilly: Callable = func() -> Node3D: return null
var point_at: Callable = func(_what: String, _pos: Vector3) -> void: pass
var stop_arrow: Callable = func() -> void: pass
## (text) -> void: a line said aloud ("Read to me") and babbled by Pip.
var say: Callable = _say
var auto_tick := true
var threaded := true
## Cells written a tick (10 a second). Right after a world loads a batch of 32 took 9-44 ms on the desktop (clearing
## later: 0.7 ms), so 16 keep a phone's frame small (~200 cells: under 1.5 s). Tests write everything at once.
var write_batch := 16

# --- This game's pieces ---
var card: TutorialCard
var offer: TutorialOffer
var outline: BuildOutline
var site := {}
## The playground's cells in the world now (TutorialProps' record).
var record: Array = []
var step := -1

var _running := false
var _want := &""                  # &"offer" or &"start": waiting for a site
var _holding := false             # owner #37's first-time tip waits
var _visiting := false            # the Pip beside the child is a visitor (he goes home when it stops)
var _leftovers: Array = []
var _rejected: Array[Vector3i] = []
var _task := -1
var _task_box: Array = []
var _acc := 0.0
var _look_t := 0.0
var _arrow_on := false
var _look := TutorialChecks.LookWatch.new()
var _jump := TutorialChecks.JumpWatch.new()
var _hide := TutorialChecks.HideWatch.new()
var _slime: Node3D
var _crafted := false
var _said_seen := false
var _no_tilly := false
var _place_t := 0.0
var _said_step_back := false
var _pick_us := 0
var _pick_wait_ms := 0.0   # M5 Task 3: how long the last search waited for a worker thread
var _plan_task := -1
var _plan_box: Array = []
var _plan_us := 0
## Cells still to write ([[Vector3i, id], ...]): the playground going in (_placing) or going back (_clearing).
var _queue: Array = []
var _placing := false
var _clearing := false
var _write_ms := 0.0


## Where the tutorial plays now: a solo Survivor world (never LAN, online, Sandbox, Monster Wave or Build to
## Survive), in a universe with ground for the playground.
static func plays_now() -> bool:
	return TutorialRules.plays_here(Game.mode, Game.net_mode, Session.is_online() or Session.wants_online(),
		Game.survivor_game, UniverseRegistry.ladder_name(Game.universe))


func _ready() -> void:
	name = "Tutorial"


func _exit_tree() -> void:
	for t: int in [_task, _plan_task]:
		if t != -1:
			WorkerThreadPool.wait_for_task_completion(t)
	_task = -1
	_plan_task = -1


func _process(delta: float) -> void:
	if not auto_tick:
		return
	_acc += delta
	if _acc >= TICK:
		tick(_acc)
		_acc = 0.0


## This game's cards in `layer` (under the pause menu), the step's glow, the craft and palette hooks. Before the
## player spawns: the shop tip waits from here on when the tutorial is due.
func setup_local(layer: Node) -> void:
	if profile == null:
		profile = Profile.data
	card = TutorialCard.new()
	layer.add_child(card)
	card.stop_pressed.connect(stop)
	offer = TutorialOffer.new()
	offer.name = "TutorialOffer"
	layer.add_child(offer)
	offer.play.connect(play)
	offer.skip.connect(skip_offer)
	offer.later.connect(_let_go)
	outline = BuildOutline.new()
	outline.name = "TutorialGlow"
	add_child(outline)
	if is_instance_valid(hud):
		hud.look_area.blockers.append_array(card.blockers())
		hud.palette.visibility_changed.connect(_on_palette)
		hud.visibility_changed.connect(_show_card)   # photo mode hides the HUD (and pauses): the card and glow too
	Session.craft_done.connect(_on_craft_done)
	_holding = TutorialRules.holds_tip(profile.tutorial, here)


## The player stands in the world: a crash's leftovers to put back; the offer, or SETTINGS' replay.
func start_session() -> void:
	if meta and not meta.tutorial_props.is_empty():
		_leftovers = TutorialProps.clean(meta.tutorial_props)
	if TutorialRules.starts_now(profile.tutorial, here):
		_holding = true
		_want = &"start"
		_pick()
	elif TutorialRules.wants_offer(profile.tutorial, here):
		_want = &"offer"
		_pick()


func is_running() -> bool:
	return _running


## The whole playground is in the world (the steps go on only then).
func is_laid_out() -> bool:
	return not record.is_empty() and _queue.is_empty()


## Cells are still going back (after the end or the X).
func is_clearing() -> bool:
	return _clearing


## True while owner #37's first-time shop tip must wait (the offer or the lessons are on).
func holds_tip() -> bool:
	return _holding


## PLAY WITH PIP.
func play() -> void:
	if _running:
		return
	if site.is_empty():
		_want = &"start"
		_pick()
		return
	_begin()


## SKIP: no reward, never asked again.
func skip_offer() -> void:
	TutorialRules.skip(profile.tutorial)
	save_profile.call()
	_let_go()


## The small X: everything goes (nothing lost), it goes on from this step next time.
func stop() -> void:
	if not _running:
		return
	_leave(step)
	_close_down(true)
	_running = false
	save_profile.call()
	_let_go()
	stopped.emit()


# --- The site -----------------------------------------------------------------------------------------------------

func _pick() -> void:
	if _task != -1:
		return
	_pick_us = Time.get_ticks_usec()
	var job: Callable = pick_site if pick_site.is_valid() else _picker(shape, spawn, avoid.call(), _rejected.duplicate())
	if not threaded:
		_on_picked(job.call())
		return
	var box := [{}, _pick_us]
	_task_box = box
	# M5 Task 3: high priority. A 4-core phone has one low-priority worker slot, shared with resource loading and the
	# world's other searches; on the emulator the first search waited there while the world streamed in (20 s).
	_task = WorkerThreadPool.add_task(func() -> void:
		box[1] = Time.get_ticks_usec()   # when a worker took it
		box[0] = job.call(), true, "Pip's playground")


static func _picker(sh: MeadowsShape, sp: Vector2i, av: Array, rejected: Array[Vector3i]) -> Callable:
	return func() -> Dictionary:
		if sh == null:
			return {}
		return TutorialCourse.pick_for(sh, sp, av, func(s: Dictionary) -> bool: return not rejected.has(s.origin))


func _on_picked(s: Dictionary) -> void:
	var want := _want
	_want = &""
	if s.is_empty():
		print("TUTORIAL no playground here")
		if _running:
			stop()
		else:
			_let_go()
		return
	site = s
	print("TUTORIAL playground at %s dir %d (%.1f ms to find, %.1f ms of it waiting for a worker)" % [s.origin, s.dir,
		(Time.get_ticks_usec() - _pick_us) / 1000.0, _pick_wait_ms])
	if want == &"offer":
		offer.offer(TutorialRules.is_resume(profile.tutorial))
	elif want == &"start":
		_begin()
	elif _running and TutorialRules.step_id(step) == &"move":
		point_at.call(TutorialRules.PLAYGROUND, TutorialCourse.start_pos(site))   # another site: the arrow follows
		_arrow_on = true


# --- Every tenth of a second ------------------------------------------------------------------------------------

func tick(delta: float) -> void:
	if profile == null:
		return   # not set up yet: a guest's player (and the sandbox's setup) comes from the host a moment later
	if _task != -1 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_pick_wait_ms = (int(_task_box[1]) - _pick_us) / 1000.0
		_on_picked(_task_box[0])
	if not _leftovers.is_empty() and _queue.is_empty():
		_clear_leftovers()
	_write_some()
	if not _running:
		_look_t += delta
		if _look_t >= REPLAY_LOOK:
			_look_t = 0.0
			if _want == &"" and _task == -1 and TutorialRules.starts_now(profile.tutorial, here):
				_holding = true
				_want = &"start"
				_pick()
		return
	if not is_instance_valid(player) or not player.is_spawned():
		return
	if record.is_empty():
		_try_place(delta)
	_show_card()
	if record.is_empty() or not _queue.is_empty():
		return   # the steps wait until the whole playground is in
	_arrow()
	_rescue_pip()
	if _check(step, delta):
		_done()


# --- The playground in the world ---------------------------------------------------------------------------------
# One bulk copy of the course's box (main thread, ~0.1 ms); the natural check and the plan read it on a worker thread
# (~140 ms on the desktop under load); the cells go into the world `write_batch` a tick (all ~200 at once took ~115 ms
# on one frame), the record saved in the meta before the first; putting back the same way.

## Lays the playground out: at most every PLACE_EVERY a plan is asked for; its answer is taken on the main thread.
func _try_place(delta: float) -> void:
	if _plan_task != -1:
		if not WorkerThreadPool.is_task_completed(_plan_task):
			return
		WorkerThreadPool.wait_for_task_completion(_plan_task)
		_plan_task = -1
		_take_plan(_plan_box[0])
		return
	_place_t -= delta
	if _place_t > 0.0 or site.is_empty() or not _leftovers.is_empty() or not _queue.is_empty() or _task != -1 \
			or not _loaded(site):
		return
	_place_t = PLACE_EVERY
	_plan_us = Time.get_ticks_usec()
	var box: Array = TutorialCourse.box(site)
	var job := _plan_job(site.duplicate(), box_reader.call(box[0], box[1]))
	if not threaded:
		_take_plan(job.call())
		return
	var out := [{}]
	_plan_box = out
	_plan_task = WorkerThreadPool.add_task(func() -> void: out[0] = job.call(), true, "Pip's playground plan")   # M5 Task 3


## The natural check and the plan over one copy of the course's box (safe on a worker thread).
static func _plan_job(s: Dictionary, read: Callable) -> Callable:
	return func() -> Dictionary:
		if not TutorialProps.natural(s, read):
			return {"origin": s.origin, "natural": false}
		return {"origin": s.origin, "natural": true, "plan": TutorialProps.plan(s, read)}


func _take_plan(res: Dictionary) -> void:
	if not _running or site.is_empty() or res.get("origin") != site.origin:
		return   # stopped meanwhile, or another site
	if not bool(res.natural):
		_rejected.append(site.origin)   # a child's build: another site
		site = {}
		_place_t = 0.0
		_pick()
		return
	var plan: Array = res.plan
	if TutorialProps.touches(plan, player.global_position):
		if not _said_step_back:   # never a hole under the child or a wall through them: it waits
			_said_step_back = true
			_tell(&"tutorial_step_back")
		return
	record = plan
	meta.tutorial_props = record.duplicate(true)   # saved before the world changes: a crash never keeps it
	save_meta.call()
	print("TUTORIAL playground planned: %d cells in %.1f ms (a worker thread)" % [record.size(),
		(Time.get_ticks_usec() - _plan_us) / 1000.0])
	_queue.append_array(TutorialProps.changes_of(record))
	_placing = true
	_write_some()


## Writes the next `write_batch` cells; when the queue is empty, what it was for is done.
func _write_some() -> void:
	if not _queue.is_empty():
		var t0 := Time.get_ticks_usec()
		var n := mini(write_batch, _queue.size())
		world.set_blocks(_queue.slice(0, n))
		_queue = _queue.slice(n)
		_write_ms = maxf(_write_ms, (Time.get_ticks_usec() - t0) / 1000.0)
	if not _queue.is_empty():
		return
	if _placing:
		_placing = false
		print("TUTORIAL playground in: %d cells, the slowest batch %.1f ms" % [record.size(), _write_ms])
		_write_ms = 0.0
		_props_for(step)
	if _clearing:
		_clearing = false
		_write_ms = 0.0
		if meta:
			meta.tutorial_props = []   # every cell is back: nothing left to put back after a crash
			save_meta.call()


## The course's corners and middle are loaded (editable).
func _loaded(s: Dictionary) -> bool:
	for a: int in [TutorialCourse.A_MIN, floori((TutorialCourse.A_MIN + TutorialCourse.A_MAX) * 0.5), TutorialCourse.A_MAX]:
		for side: int in [-TutorialCourse.S_HALF, TutorialCourse.S_HALF]:
			for dy: int in [-TutorialCourse.FILL_DOWN - 1, TutorialCourse.CLEAR_UP - 1]:
				if not world.is_editable(TutorialCourse.cell(s, a, side, dy)):
					return false
	return true


func _clear_props() -> void:
	if record.is_empty():
		return
	if not _loaded(site):
		_queue.clear()   # far away: it goes when that part of the world is loaded again (the meta keeps it)
		_placing = false
		_leftovers = record
		record = []
		return
	_put_back(record)
	record = []


func _clear_leftovers() -> void:
	var box := TutorialProps.box(_leftovers)
	for p: Vector3 in [box.position, box.end - Vector3.ONE, box.get_center()]:
		if not world.is_editable(Vector3i(p.floor())):
			return
	_put_back(_leftovers)
	_leftovers = []


## Every recorded cell back to what it held (a batch a tick; the meta keeps the record until the last); the child's
## own blocks in it back to their bag at once, and their cells in the same frame (M5 Task 6 review: never given twice
## when the game closes before the last batch). Cells of a placement not written yet are simply never written.
func _put_back(cells: Array) -> void:
	_queue.clear()
	_placing = false
	var box := TutorialProps.box(cells)
	var out := TutorialProps.clear(cells, box_reader.call(Vector3i(box.position), Vector3i(box.size)))
	var theirs: int = out.theirs
	if theirs > 0:
		world.set_blocks((out.changes as Array).slice(0, theirs))
	var inv: Inventory = bag.call()
	for id: int in out.returns:
		inv.add(id, int(out.returns[id]))
	_queue.append_array((out.changes as Array).slice(theirs))
	_clearing = true
	_write_some()


# --- The steps ------------------------------------------------------------------------------------------------------

func _begin() -> void:
	step = TutorialRules.begin(profile.tutorial)
	save_profile.call()
	_running = true
	_holding = true
	_place_t = 0.0
	_said_step_back = false
	if pip_node.call() == null:
		_visiting = profile.pip.is_empty()
		bring_pip.call(PetRules.pip_record(PetRules.PIP_NAME, PetRules.OWNER_COLOUR, PetRules.HAPPY_START)
			if _visiting else profile.pip)
	_enter(step)


func _enter(i: int) -> void:
	_look = TutorialChecks.LookWatch.new()
	_jump = TutorialChecks.JumpWatch.new()
	_hide = TutorialChecks.HideWatch.new()
	_crafted = false
	_said_seen = false
	_no_tilly = false
	card.show_step(i, TutorialRules.count())
	say.call(TutorialRules.words(i))
	_stop_arrow()
	match TutorialRules.step_id(i):
		&"move":
			point_at.call(TutorialRules.PLAYGROUND, TutorialCourse.start_pos(site))
			_arrow_on = true
		&"bridge":
			_gift_blocks()
		&"craft":
			_on_palette()
		&"tilly":
			_no_tilly = not bool(show_tip.call())
	_props_for(i)
	step_started.emit(i)


## The step's cells glow and the practice slime comes (once the playground is all in the world).
func _props_for(i: int) -> void:
	if record.is_empty() or site.is_empty() or not _queue.is_empty():
		return
	var id := TutorialRules.step_id(i)
	var cells := {}
	for c: Vector3i in TutorialCourse.outline(site, id):
		cells[c] = 1
	outline.show_blocks(cells)
	if id == &"hide" and not is_instance_valid(_slime):
		_come_slime()


func _come_slime() -> void:
	var at := TutorialCourse.spot(site, TutorialCourse.SLIME.x, TutorialCourse.SLIME.y) + Vector3(0, 0.1, 0)
	var to := player.global_position - at
	_slime = spawn_slime.call(at, atan2(-to.x, -to.z))


func _check(i: int, delta: float) -> bool:
	var feet := player.global_position
	match TutorialRules.step_id(i):
		&"move":
			_look.feed(feet, player.rig.yaw)
			var start := TutorialCourse.start_pos(site)
			return _look.done() and Vector2(feet.x - start.x, feet.z - start.z).length() <= NEAR_START
		&"jump":
			var done: bool = _jump.feed(TutorialCourse.zone(site, feet), on_floor.call())
			if _jump.fell:
				_jump.fell = false
				_tell(&"tutorial_jump_again")
			return done
		&"bridge":
			return TutorialChecks.bridge_done(site, world.get_block)
		&"wall":
			return TutorialChecks.wall_open(site, world.get_block)
		&"hide":
			if not is_instance_valid(_slime) or _slime.is_queued_for_deletion():
				_come_slime()   # it went far away: another comes
				return false
			var near := _slime.global_position.distance_to(feet) <= TutorialChecks.SLIME_NEAR
			var mark: Variant = _slime.get(&"alert")
			var whom: Variant = _slime.get(&"alert_peer")
			var sees: bool = mark is int and mark == StealthRules.MARK_BANG and whom is int and whom == player.peer_id
			if sees and not player.is_hidden() and not _said_seen:
				_said_seen = true
				_tell(&"tutorial_hide_seen")
			return _hide.feed(delta, player.is_hidden(), near, sees)
		&"craft":
			return _crafted
		&"tilly":
			var t: Node3D = tilly.call()
			return _no_tilly or t == null or TutorialChecks.at_tilly(player.eye_position(), t.global_position)
	return false


func _done() -> void:
	var i := step
	_tell(TutorialRules.praise(i))
	var p: Node3D = pip_node.call()
	if p and p.has_method(&"cheer"):
		p.call(&"cheer")
	_leave(i)
	TutorialRules.advance(profile.tutorial, i)
	save_profile.call()
	step_done.emit(i)
	if i + 1 >= TutorialRules.count():
		_finish()
	else:
		step = i + 1
		_enter(step)


## The card (and the glow) show while it plays and the HUD shows; the card steps aside for a picture hint.
func _show_card() -> void:
	var shown := _running and not (is_instance_valid(hud) and not hud.visible)
	if is_instance_valid(card):
		card.visible = shown and not (is_instance_valid(hud) and hud.picture_hint.visible)
	if outline:
		outline.visible = shown


## What step i put out goes: the slime puffs, the glow and the arrow go.
func _leave(i: int) -> void:
	if TutorialRules.step_id(i) == &"hide" and is_instance_valid(_slime):
		puff.call(_slime)
	_slime = null
	if outline:
		outline.clear()
	_stop_arrow()


func _finish() -> void:
	var due := TutorialRules.finish(profile.tutorial)
	if due:
		gold_add.call(TutorialRules.REWARD_GOLD)
		AvatarUnlocks.earn(profile, TutorialRules.EARN)
		PetRules.give_pip(profile)
		_visiting = false   # Pip stays: he is the child's now
		var p: Node3D = pip_node.call()
		if p and p.has_method(&"cheer"):
			p.call(&"cheer", true)
	save_profile.call()
	_close_down(false)
	_running = false
	_holding = false
	offer.reward(due)
	finished.emit(due)


func _close_down(pip_home: bool) -> void:
	if card:
		card.visible = false
	if outline:
		outline.clear()
	_stop_arrow()
	_clear_props()
	if is_instance_valid(_slime):
		puff.call(_slime)
	_slime = null
	if pip_home and _visiting:
		var p: Node3D = pip_node.call()
		if p:
			send_pip_home.call(p)
		_visiting = false


func _let_go() -> void:
	if _holding:
		_holding = false
		release_tip.call()


# --- Helpers -------------------------------------------------------------------------------------------------------

## The arrow at the step's place while the child is far off (again once they came close and went away).
func _arrow() -> void:
	var at := TutorialCourse.station(site, TutorialRules.step_id(step))
	if not at.is_finite():
		return
	var d := Vector2(player.global_position.x - at.x, player.global_position.z - at.z).length()
	if d > FAR_OFF and not _arrow_on:
		point_at.call(TutorialRules.PLAYGROUND, at)
		_arrow_on = true
	elif d < FAR_OFF * 0.5 and _arrow_on and TutorialRules.step_id(step) != &"move":
		_arrow_on = false


func _stop_arrow() -> void:
	if _arrow_on:
		stop_arrow.call()
		_arrow_on = false


## The bridge needs 3 blocks: a child without any gets 3 of the ground's own.
func _gift_blocks() -> void:
	var inv: Inventory = bag.call()
	var have := 0
	for id: int in inv.ids():
		if BlockIds.is_valid(id) and BlockIds.is_solid(id):
			have += inv.count(id)
	if have < BRIDGE_GIFT:
		inv.add(BlockIds.DIRT, BRIDGE_GIFT)
		_tell(&"tutorial_bridge_gift")


## Pip fell into a hole: back up beside the child (a robot on wheels can't climb out).
func _rescue_pip() -> void:
	var p: Node3D = pip_node.call()
	if p == null or not TutorialCourse.on_footprint(site, p.global_position, 0):
		return
	if p.global_position.y < TutorialCourse.level(site) - 0.5:
		p.global_position = player.global_position + Vector3(0.8, 0.3, 0.8)


## A short line: a toast (read aloud with "Read to me") and Pip's babble.
func _tell(line: StringName) -> void:
	var text := TutorialRules.line(line)
	if is_instance_valid(hud):
		hud.toast(text, 3.0)
	_babble(text)


func _say(text: String) -> void:
	ReadAloud.auto(text)
	_babble(text)


func _babble(text: String) -> void:
	var p: Node3D = pip_node.call()
	if p and p.is_inside_tree():
		BabbleVoices.say(p, &"pet", 1.0, Lang.t(text), true, "Pip")


func _on_craft_done(ok: bool, _text: String, id: int, _count: int) -> void:
	if _running and TutorialRules.step_id(step) == &"craft" and TutorialChecks.crafted_stick(ok, id):
		_crafted = true


## The craft step: the bag opens on its CRAFT page.
func _on_palette() -> void:
	if not _running or not is_instance_valid(hud) or TutorialRules.step_id(step) != &"craft":
		return
	if hud.palette.visible and hud.palette.counted:
		hud.palette.show_page(BlockPalette.CRAFT_PAGE)
