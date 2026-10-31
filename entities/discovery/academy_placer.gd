class_name AcademyPlacer
extends Node
## Owner #132 (W1), stage 3: a home world's Discovery Academy (node "Academy" under the sandbox's Discovery), placed the
## way the Market Square is (MarketPlazaPlacer): a saved site stands at once; otherwise AcademyPlaza.pick_for finds it on
## a worker (after Life Town's and the Market Square's sites: the saved ones, else the seed's), and on the host it checks
## once that the ground is still the world's own (a child's build there moves it elsewhere: `rejected`), clears the
## trees and plants in and right round its tower and gates (ordinary world edits, a batch a frame), stands the buildings
## (AcademyBuildings) and says `placed` (the sandbox saves it: WorldMeta.academy). No room on the ground: the island over
## the spawn, which needs no clearing. A LAN guest finds it from the seed and stands it at once. Nothing here goes over
## the network.

signal placed(site: Dictionary)
signal stands

const WRITE_BATCH := 48

var world: Node
var host := true
var search_later := true
var site := {}
var stood := false
var buildings: AcademyBuildings
var ground := Callable()
var rejected: Array = []

var _shape: MeadowsShape
var _theater_saved: Array = []
var _launch_saved: Array = []
var _town_saved: Array = []
var _task := -1
var _found: Array = [{}]
var _check_task := -1
var _checked: Array = [{}]
var _queue: Array = []
var _doors := {}   # door -> its walk-up spot in the world (worked out once it stands)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## `saved`: the site the world's save kept ({} for none yet); theater, launch and town: the world's saved sites ([] for
## the seed's; the town's with its Market Square: LifeTown.to_save).
func setup(shape: MeadowsShape, saved: Dictionary, ground_at: Callable, theater: Array = [], launch: Array = [],
		town: Array = []) -> void:
	name = "Academy"
	_shape = shape
	ground = ground_at
	_theater_saved = theater
	_launch_saved = launch
	_town_saved = town
	if not saved.is_empty():
		site = saved
		_stand()
		return
	_search()


## A site found (the search's, or a test's): the host checks and clears it before it stands; a guest and the island
## stand at once.
func place(s: Dictionary) -> void:
	if s.is_empty():
		push_warning("The Discovery Academy: no site")
		return
	site = s
	stood = false
	_queue.clear()
	if not host:
		_stand()
	elif bool(s.get("island", false)):
		_placed()


func _search() -> void:
	if _shape == null:
		return   # a test's stand-in world (no generator): nothing to search
	var shape := _shape
	var theater_saved := _theater_saved
	var launch_saved := _launch_saved
	var town_saved := _town_saved
	var avoid := rejected.duplicate()
	var job := func() -> Dictionary:
		var theater := TheaterSite.from_save(theater_saved)
		if theater.is_empty():
			theater = TheaterSite.pick_for(shape)
		var launch := LaunchSite.from_save(launch_saved)
		if launch.is_empty():
			launch = LaunchSite.pick_for(shape, theater)
		var town := LifeTown.from_save(town_saved)
		if town.is_empty():
			town = LifeTown.pick_for(shape, theater, launch)
		var market: Dictionary = town.get("market", {})
		if market.is_empty() and not town.is_empty():
			market = MarketPlaza.pick_for(shape, town, theater, launch)
		return AcademyPlaza.pick_for(shape, theater, launch, town, market, avoid)
	if not search_later:
		place(job.call())
		return
	var found := _found
	_task = WorkerThreadPool.add_task(func() -> void: found[0] = job.call(), true, "The Discovery Academy")


func _stand() -> void:
	if buildings:
		buildings.queue_free()
	buildings = AcademyBuildings.new()
	add_child(buildings)
	buildings.setup(site, ground)
	_doors.clear()
	for door: String in AcademyPlaza.DOORS:
		_doors[door] = AcademyPlaza.door_position(site, door, ground)
	stood = true
	stands.emit()


func _exit_tree() -> void:
	for t: int in [_task, _check_task]:
		if t != -1:
			WorkerThreadPool.wait_for_task_completion(t)
	_task = -1
	_check_task = -1


func _process(_delta: float) -> void:
	if _task != -1 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		place(_found[0])
	if host:
		_place_step()


func _place_step() -> void:
	if site.is_empty() or stood or world == null:
		return
	if not _queue.is_empty():
		var n := mini(WRITE_BATCH, _queue.size())
		world.set_blocks(_queue.slice(0, n))
		_queue = _queue.slice(n)
		if _queue.is_empty():
			_placed()
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
	var box := AcademyPlaza.natural_box(site)
	var read: Callable = world.box_reader(box[0], box[1])
	var s := site.duplicate()
	var job := func() -> Dictionary:
		if not AcademyPlaza.natural(s, read):
			return {"site": s, "natural": false}
		return {"site": s, "natural": true, "changes": AcademyPlaza.clear_changes(s, read)}
	if not search_later:
		_take_check(job.call())
		return
	var out := _checked
	_check_task = WorkerThreadPool.add_task(func() -> void: out[0] = job.call(), true, "The Discovery Academy's ground")


func _take_check(res: Variant) -> void:
	if not res is Dictionary or (res as Dictionary).get("site") != site:
		return
	if not bool(res.natural):
		var p: Vector3i = site.pos
		rejected.append(Vector2i(p.x, p.z))   # a child built here: another place
		print("ACADEMY site at %s holds a build: another place" % [p])
		site = {}
		_search()
		return
	_queue = res.changes
	if _queue.is_empty():
		_placed()


func _placed() -> void:
	_stand()
	print("ACADEMY stands at %s%s" % [site.pos, " (the island over the spawn)" if site.get("island", false) else ""])
	placed.emit(site)


## The plaza's corners and middle are loaded (editable).
func _loaded() -> bool:
	if not world.has_method("is_editable"):
		return true
	var p: Vector3i = site.pos
	for c: Vector2i in [AcademyPlaza.PLAZA_MIN, AcademyPlaza.PLAZA_MAX, Vector2i(AcademyPlaza.PLAZA_MIN.x,
			AcademyPlaza.PLAZA_MAX.y), Vector2i(AcademyPlaza.PLAZA_MAX.x, AcademyPlaza.PLAZA_MIN.y), Vector2i.ZERO]:
		var w := AcademyPlaza.to_world(site, c)
		for y in [p.y - LifeTown.PLINTH_DEPTH, p.y + LifeTown.CLEAR_UP]:
			if not world.is_editable(Vector3i(w.x, y, w.y)):
				return false
	return true


## The door whose walk-up spot feet at `feet` stand at ("" for none, before it stands, or on the island): the nearest
## within LifeTown.REACH across the ground and LifeTown.HEIGHT up or down (AcademyPlaza.near's rule, on the doors' spots
## worked out once when it stood: asked every frame, the ground is never read again).
func near(feet: Vector3) -> String:
	if not stood or bool(site.get("island", false)) or not feet.is_finite():
		return ""
	var best := ""
	var best_d := LifeTown.REACH
	for door: String in _doors:
		var d: Vector3 = _doors[door]
		var flat := Vector2(feet.x - d.x, feet.z - d.z).length()
		if flat <= best_d and absf(feet.y - d.y) <= LifeTown.HEIGHT:
			best = door
			best_d = flat
	return best


func door_position(door: String) -> Vector3:
	return _doors.get(door, Vector3.INF) if stood else Vector3.INF
