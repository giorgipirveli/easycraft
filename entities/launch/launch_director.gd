class_name LaunchDirector
extends Node
## A home world's Launch Site (spec §21d.1; node "LaunchSite" of the sandbox). setup() finds its site (the saved one,
## else a new one: LaunchSite.pick_for on a worker, avoiding the Theater), stands the buildings (LaunchBuildings: every
## device, from the seed like the Theater on a LAN guest) and, on the host, stamps the pad into the world once: when
## its ground is loaded and still the world's own (LaunchSite.natural: a world from before missions never gets concrete
## over a child's build; such a site is passed over), the plaza's concrete goes in a few dozen cells a frame, and the
## save keeps the site as stamped (site_placed). Walking up to the Mission Board opens it on this device; walking away,
## or X and Esc, closes it (after X it stays closed until the child walks away and back). The pad's cells are read for
## the check (read_pad). Nothing here goes over the network: the pad's blocks are ordinary world edits.
##
## Owner #98, BUILD IT FOR ME (build, host only): Mission Control's plan (RocketPlan) goes onto the pad layer by layer,
## at most BUILD_CELLS_PER_FRAME cells a frame and a layer about every BUILD_LAYER_SECONDS, with a caption and a spoken
## line per stage (`say`). The cells already right stay; the other rocket parts in the build box are cleared first (they
## would join the rocket); a child's other blocks are never broken (it refuses and says how many to move first), and a
## cell a child fills meanwhile is left alone. It refuses before the pad is stamped, on a friend's game and while it
## builds; it waits while someone stands in the build box ("Step off the pad…", giving up after BUILD_WAIT_SECONDS) or
## its chunks are not loaded, and while the game is paused. It writes through `write_cells` (the sandbox: Survivor's bag
## pays, no XP, no undo step; no reach limit: the board's own near_board gates it). At the end the board opens on MY
## ROCKET if the child still stands at it.
##
## Owner #106, a crash (crash_damage, host only): the rocket fell by the Launch Site, so a random share of the pad's
## rocket parts breaks (CrashRules: 15-35%, seeded): they are gone from the pad (air; nothing goes back into a bag), a puff
## of dust at each, nothing else touched. notice_crash: the board's line ("Your rocket crashed: 9 parts broke. Rebuild
## them: 120 gold.") opens it on MY ROCKET a moment after the child is home at the board, or at its next walk-up.

## The site the save should keep now ([x, y, z, facing, stamped]; LaunchSite.to_save).
signal site_placed(saved: Array)
## Owner #98: BUILD IT FOR ME ended ("" = the whole plan stands, else why it stopped).
signal build_finished(why: String)
## Owner #98: the site is known on this device (its buildings stand): MY MAP marks it.
signal site_ready

const CHECK_SECONDS := 0.1
const WRITE_BATCH := 48
## Owner #98: BUILD IT FOR ME's pace and words.
const BUILD_LAYER_SECONDS := 0.4
const BUILD_CELLS_PER_FRAME := 16
const BUILD_WAIT_SECONDS := 30.0
const PAD_NOT_READY := "The pad is still being made: wait a moment!"
const BUSY := "Mission Control is already building!"
const ALREADY := "Your rocket is Mission Control's plan already!"
const STEP_OFF := "Step off the pad: Mission Control is building!"
const GAVE_UP := "Mission Control stopped: the pad never cleared. Press BUILD IT FOR ME again."
const STARTED := "Mission Control is building your rocket for %s: watch the pad!"
const DONE := "Your rocket for %s is ready! Check it, then LAUNCH."
## Owner #106: seconds home before the board opens with the crash's line.
const NOTICE_SECONDS := 2.5

## The world (WorldService or a test's stand-in): is_editable, set_blocks, box_reader, copy_box.
var world: Node
var host := true
## Search on a worker thread (the sandbox's; tests search at once).
var search_later := true
var site: Dictionary = {}
var stamped := false
var buildings: LaunchBuildings
var board: MissionBoard
var player_position := Callable()   # () -> Vector3, the local player's feet; INF while not spawned
var overlay_open := Callable()      # () -> bool: another menu covers the screen
## Owner #98, BUILD IT FOR ME's hooks (the sandbox's on the host). (changes [[world cell, id]]) -> String: writes them
## ("" = written, else why the build stops: Survivor's bag ran out); invalid: world.set_blocks.
var write_cells := Callable()
## () -> Array of AABB: the players and bot friends (the build waits while one stands in the build box).
var bodies: Callable = func() -> Array: return []
## (text) -> void: a caption and spoken line for everyone here.
var say: Callable = func(_text: String) -> void: pass
## () -> bool: the game is paused (the solo pause menu): the build waits.
var is_paused: Callable = func() -> bool: return is_inside_tree() and get_tree().paused

var _shape: MeadowsShape
var _theater: Dictionary = {}
var _rejected: Array = []
var _task := -1
var _found: Array = [{}]
var _check_task := -1
var _checked: Array = [false]
var _queue: Array = []
var _inside := false
var _dismissed := false
var _wait := 0.0
var _job := {}   # owner #98: the build under way ({} = none)
## Owner #98: the slowest write of the last build, in ms (its cells and their world updates; the smoke prints it).
var build_slowest_ms := 0.0
## Owner #106: the crash's line for the board (shown once, on MY ROCKET), "" for none.
var crash_notice := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Finds the site (saved: WorldMeta.launch_site; theater: WorldMeta.theater, [] for the seed's) and adds the board
## under `ui_parent`. Returns what the save should keep now.
func setup(shape: MeadowsShape, saved: Array, theater: Array, ui_parent: Node) -> Array:
	_shape = shape
	_theater = TheaterSite.from_save(theater)
	board = MissionBoard.new()
	board.closed.connect(func() -> void: _dismissed = _inside)
	if ui_parent:
		ui_parent.add_child(board)
	var known := LaunchSite.from_save(saved)
	if not known.is_empty():
		site = {"pos": known.pos, "facing": known.facing}
		stamped = bool(known.stamped)
		_stand()
		return LaunchSite.to_save(site, stamped)
	_search()
	return []


func _search() -> void:
	var shape := _shape
	var theater := _theater
	var rejected := _rejected.duplicate()
	var job := func() -> Dictionary:
		var t := theater if not theater.is_empty() else TheaterSite.pick_for(shape)
		return LaunchSite.pick_for(shape, t, [], rejected)
	if not search_later:
		_on_found(job.call())
		return
	var found := _found
	_task = WorkerThreadPool.add_task(func() -> void: found[0] = job.call(), true, "Launch Site")


func _on_found(s: Dictionary) -> void:
	if s.is_empty():
		push_warning("Launch Site: no flat, dry ground near the spawn")
		return
	site = s
	stamped = false
	_stand()
	if host:
		site_placed.emit(LaunchSite.to_save(site, false))


func _stand() -> void:
	if buildings:
		buildings.queue_free()
	buildings = LaunchBuildings.new()
	buildings.name = "LaunchBuildings"
	add_child(buildings)
	buildings.setup(site)
	site_ready.emit()


func _exit_tree() -> void:
	for t: int in [_task, _check_task]:
		if t != -1:
			WorkerThreadPool.wait_for_task_completion(t)
	_task = -1
	_check_task = -1


func _process(delta: float) -> void:
	if _task != -1 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_on_found(_found[0])
	if host:
		_stamp_step()
		_build_step(delta)   # owner #98
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = CHECK_SECONDS
	_follow_player()


## Stamps the pad (host): waits for its ground to load, checks it is the world's own (on a worker), then writes a
## batch of cells a frame; done: the save keeps it stamped.
func _stamp_step() -> void:
	if site.is_empty() or stamped or world == null:
		return
	if not _queue.is_empty():
		var n := mini(WRITE_BATCH, _queue.size())
		world.set_blocks(_queue.slice(0, n))
		_queue = _queue.slice(n)
		if _queue.is_empty():
			stamped = true
			print("LAUNCH pad stamped at %s" % [site.pos])
			site_placed.emit(LaunchSite.to_save(site, true))
		return
	if _check_task != -1:
		if not WorkerThreadPool.is_task_completed(_check_task):
			return
		WorkerThreadPool.wait_for_task_completion(_check_task)
		_check_task = -1
		_take_check(_checked[0])
		return
	if not _loaded():
		return
	var box := LaunchSite.natural_box(site)
	var read: Callable = world.box_reader(box[0], box[1])
	var s := site.duplicate()
	var shape := _shape
	var job := func() -> Dictionary:
		if not LaunchSite.natural(s, read):
			return {"site": s, "natural": false}
		var changes := LaunchSite.clear_changes(s, read)   # its trees and plants first, then the concrete
		changes.append_array(LaunchSite.pad_changes(s, shape.height_at))
		return {"site": s, "natural": true, "changes": changes}
	if not search_later:
		_take_check(job.call())
		return
	var out := _checked
	_check_task = WorkerThreadPool.add_task(func() -> void: out[0] = job.call(), true, "Launch Site's pad")


func _take_check(res: Variant) -> void:
	if not res is Dictionary or (res as Dictionary).get("site") != site:
		return
	if not bool(res.natural):
		var p: Vector3i = site.pos
		_rejected.append(Vector2i(p.x, p.z))   # a child built here: another place
		print("LAUNCH site at %s holds a build: another place" % [p])
		site = {}
		if buildings:
			buildings.queue_free()
			buildings = null
		_search()
		return
	_queue = res.changes


## The plaza's corners and middle are loaded (editable).
func _loaded() -> bool:
	if not world.has_method("is_editable"):
		return true
	var p: Vector3i = site.pos
	for c: Vector2i in [LaunchSite.PLAZA_MIN, LaunchSite.PLAZA_MAX, Vector2i(LaunchSite.PLAZA_MIN.x, LaunchSite.PLAZA_MAX.y),
			Vector2i(LaunchSite.PLAZA_MAX.x, LaunchSite.PLAZA_MIN.y), Vector2i.ZERO]:
		var w := LaunchSite.to_world(site, c)
		for y in [p.y - LaunchSite.PLINTH_DEPTH, p.y + LaunchSite.CLEAR_UP]:
			if not world.is_editable(Vector3i(w.x, y, w.y)):
				return false
	return true


func _follow_player() -> void:
	if board == null or not player_position.is_valid():
		return
	var feet: Vector3 = player_position.call()
	var paused := is_inside_tree() and get_tree().paused
	var inside := not paused and LaunchSite.near_board(site, feet)
	if inside and not _inside and not _dismissed and not (overlay_open.is_valid() and bool(overlay_open.call())):
		if crash_notice != "":   # owner #106
			board.open_on_rocket(crash_notice)
			crash_notice = ""
		else:
			board.open()
	elif not inside and _inside:
		board.close()
		_dismissed = false
	if not inside:
		_dismissed = false
	_inside = inside


# --- Owner #98: BUILD IT FOR ME --------------------------------------------------------------------------------------

## Mission Control is building on the pad now.
func building() -> bool:
	return not _job.is_empty()


## Starts building `plan` (RocketPlan cells, from the pad's corner) on the host's pad, saying `words` (one per stage,
## bottom first) as each stage stands; `place` names the mission's planet. "" when it started, else why not.
func build(plan: Dictionary, words: Array, place := "space") -> String:
	if not host:
		return MissionRules.message(MissionRules.GUEST)
	if site.is_empty() or not stamped or world == null:
		return PAD_NOT_READY
	if building():
		return BUSY
	if plan.is_empty():
		return ""
	var d := RocketPlan.diff(plan, read_pad())
	if not (d.blocked as Array).is_empty():
		return RocketPlan.blocked_words((d.blocked as Array).size())
	if (d.place as Array).is_empty() and (d.clear as Array).is_empty():
		return ALREADY
	var corner := LaunchSite.corner(site)
	var steps: Array = []
	if not (d.clear as Array).is_empty():   # the stray parts first (top down): they would join the rocket
		var clear: Array = []
		for c: Array in d.clear:
			clear.append([corner + (c[0] as Vector3i), BlockIds.AIR])
		steps.append({"y": -1, "cells": clear})
	for c: Array in d.place:   # then the plan, bottom up (RocketPlan.diff keeps its layers' order)
		var y := (c[0] as Vector3i).y
		if steps.is_empty() or int(steps.back().y) != y:
			steps.append({"y": y, "cells": []})
		(steps.back().cells as Array).append([corner + (c[0] as Vector3i), c[1]])
	var height := 0
	for p: Vector3i in plan:
		height = maxi(height, p.y + 1)
	build_slowest_ms = 0.0
	_job = {"steps": steps, "chunk": [], "y": -1, "tops": RocketPlan.stage_tops(plan), "words": words.duplicate(),
		"said": 0, "wait": 0.0, "held": 0.0, "told": false, "place": place,
		"box": AABB(Vector3(corner), Vector3(RocketCheck.PAD, height + 1, RocketCheck.PAD))}
	say.call(STARTED % place)
	return ""


func _build_step(delta: float) -> void:
	if _job.is_empty() or bool(is_paused.call()):
		return
	var chunk: Array = _job.chunk
	if chunk.is_empty():
		_job.wait = float(_job.wait) - delta
		if float(_job.wait) > 0.0:
			return
		if (_job.steps as Array).is_empty():
			_finish_build("")
			return
	if _someone_on_pad():
		if not bool(_job.told):
			say.call(STEP_OFF)
			_job.told = true
		_held(delta)
		return
	_job.told = false
	if chunk.is_empty():
		var step: Dictionary = (_job.steps as Array).pop_front()
		_job.y = int(step.y)
		chunk = _fresh(step.cells)
		_job.chunk = chunk
		if chunk.is_empty():
			_layer_done()
			return
	var n := mini(BUILD_CELLS_PER_FRAME, chunk.size())
	var part := chunk.slice(0, n)
	if world.has_method("is_editable"):
		for c: Array in part:
			if not world.is_editable(c[0]):   # its chunk is not loaded yet: wait
				_held(delta)
				return
	_job.held = 0.0
	var why := ""
	var t0 := Time.get_ticks_usec()
	if write_cells.is_valid():
		why = str(write_cells.call(part))
	else:
		world.set_blocks(part)
	build_slowest_ms = maxf(build_slowest_ms, (Time.get_ticks_usec() - t0) / 1000.0)
	if why != "":
		_finish_build(why)
		return
	_job.chunk = chunk.slice(n)
	if (_job.chunk as Array).is_empty():
		_layer_done()


## Waiting (the pad not clear, a chunk not loaded): true while it still waits, false once it gave up.
func _held(delta: float) -> bool:
	_job.held = float(_job.held) + delta
	if float(_job.held) >= BUILD_WAIT_SECONDS:
		_finish_build(GAVE_UP)
		return false
	return true


## The cells of a layer still to write now: never one already right, never one a child filled meanwhile.
func _fresh(cells: Array) -> Array:
	var out: Array = []
	for c: Array in cells:
		var now := _block(c[0])
		var want := int(c[1])
		if now == want:
			continue
		if want == BlockIds.AIR and not RocketParts.is_part(now):
			continue   # a stray part someone took away already
		if want != BlockIds.AIR and not (now == BlockIds.AIR or now == BlockIds.WATER or RocketParts.is_part(now)):
			continue   # a child built here meanwhile: never broken
		out.append(c)
	return out


func _block(p: Vector3i) -> int:
	if world.has_method("get_block"):
		return int(world.get_block(p))
	return int((world.box_reader(p, Vector3i.ONE) as Callable).call(p))


func _someone_on_pad() -> bool:
	var box: AABB = _job.box
	for b: Variant in bodies.call():
		if b is AABB and (b as AABB).intersects(box):
			return true
	return false


## A layer stands: the next one after BUILD_LAYER_SECONDS, and the line of every stage it completed.
func _layer_done() -> void:
	var y := int(_job.y)
	_job.wait = BUILD_LAYER_SECONDS if y >= 0 else 0.0
	_say_stages(y)


func _say_stages(up_to: int) -> void:
	var tops: Array = _job.tops
	var words: Array = _job.words
	while int(_job.said) < tops.size() and int(tops[int(_job.said)]) <= up_to:
		if int(_job.said) < words.size():
			say.call(str(words[int(_job.said)]))
		_job.said = int(_job.said) + 1


func _finish_build(why: String) -> void:
	var place := str(_job.get("place", "space"))
	if why == "":
		_say_stages(1 << 20)
		say.call(DONE % place)
	else:
		say.call(why)
	_job = {}
	build_finished.emit(why)
	if why == "" and _inside and board != null:
		board.open_on_rocket(DONE % place)


# --- Owner #106: a crash comes back to the pad damaged ---------------------------------------------------------------

## The host's rocket on the pad crashed down by the Launch Site: CrashRules breaks a share of its parts (seeded by
## `seed`), gone from the pad (air: never back into a bag), a puff of dust at each. CrashRules.damage's result (broken
## cells relative to the pad's corner, "parts", "count", "gold") with "rocket" ({id: count} the rocket had before); {}
## on a friend's game, before the pad, or with no rocket on it.
func crash_damage(seed: int) -> Dictionary:
	if not host or site.is_empty() or world == null:
		return {}
	var rocket := RocketCheck.find_rocket(read_pad())
	if rocket.is_empty():
		return {}
	var d := CrashRules.damage(rocket, seed)
	var corner := LaunchSite.corner(site)
	var changes: Array = []
	for c: Vector3i in d.broken:
		changes.append([corner + c, BlockIds.AIR])
	world.set_blocks(changes)
	d["rocket"] = RocketParts.count(rocket)
	if is_inside_tree():
		var puffs := 0
		for c: Vector3i in d.broken:
			if puffs >= 8:
				break
			puffs += 1
			Fx.burst(get_tree().root, Vector3(corner + c) + Vector3(0.5, 0.5, 0.5), Color(0.6, 0.58, 0.55), 10, 3.0, 0.25,
				0.8, 1.2, 60.0)
	print("LAUNCH crash: %d of %d parts broke (seed %d)" % [int(d.count), rocket.size(), seed])
	return d


## The board's line for the crash: it opens on MY ROCKET with it NOTICE_SECONDS after the child is home at the board
## (or at the next walk-up), once.
func notice_crash(words: String) -> void:
	crash_notice = words
	if board != null and board.visible:
		board.open_on_rocket(words)
		crash_notice = ""
		return
	_inside = false
	_dismissed = false
	_wait = NOTICE_SECONDS


## The pad's cells for the check ({Vector3i relative to its corner, y up: id}), non-air only.
func read_pad() -> Dictionary:
	var out := {}
	if site.is_empty() or world == null:
		return out
	var size := Vector3i(RocketCheck.PAD, RocketCheck.MAX_HEIGHT, RocketCheck.PAD)
	var read: Callable = world.box_reader(LaunchSite.corner(site), size)
	var corner := LaunchSite.corner(site)
	for x in size.x:
		for z in size.z:
			for y in size.y:
				var id: int = read.call(corner + Vector3i(x, y, z))
				if id != BlockIds.AIR:
					out[Vector3i(x, y, z)] = id
	return out


func saved_site() -> Array:
	return LaunchSite.to_save(site, stamped)
