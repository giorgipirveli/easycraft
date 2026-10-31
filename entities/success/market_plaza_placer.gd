class_name MarketPlazaPlacer
extends Node
## Owner #115 (S3): the Market Square beside a home world's Life Town (node "MarketSquare" under LifeTownDirector, which
## makes it once its town stands). It follows the town's own way (LifeTownDirector): the saved site stands at once;
## otherwise MarketPlaza.pick_for finds it on a worker (Life Town's search, near the town), and on the host it checks once
## that the ground is the world's own (a child's build there moves it elsewhere), clears the trees and plants in and right
## round its two places (ordinary world edits, a batch a frame), stands the buildings (MarketPlazaBuildings) and says
## `placed` (the director saves it with the town). A LAN guest finds it from the seed and stands it at once. Walking up
## is the director's (near). Nothing here goes over the network.

signal placed(site: Dictionary)

const WRITE_BATCH := 48

var world: Node
var host := true
var search_later := true
var site := {}
var stood := false
var buildings: MarketPlazaBuildings
var ground := Callable()

var _shape: MeadowsShape
var _town := {}
var _theater_saved: Array = []
var _launch_saved: Array = []
var _rejected: Array = []
var _task := -1
var _found: Array = [{}]
var _check_task := -1
var _checked: Array = [{}]
var _queue: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## `saved`: the site the world's save kept ({} for none yet); `town`: the town's site; theater and launch: the world's
## saved sites ([] for the seed's).
func setup(shape: MeadowsShape, town: Dictionary, saved: Dictionary, theater: Array, launch: Array, ground_at: Callable) -> void:
	name = "MarketSquare"
	_shape = shape
	_town = town
	_theater_saved = theater
	_launch_saved = launch
	ground = ground_at
	if not saved.is_empty():
		site = saved
		_stand()
		return
	_search()


func _search() -> void:
	if _shape == null or _town.is_empty():
		return   # a test's stand-in world (no generator): nothing to search
	var shape := _shape
	var town := _town.duplicate()
	var theater_saved := _theater_saved
	var launch_saved := _launch_saved
	var rejected := _rejected.duplicate()
	var job := func() -> Dictionary:
		var theater := TheaterSite.from_save(theater_saved)
		if theater.is_empty():
			theater = TheaterSite.pick_for(shape)
		var launch := LaunchSite.from_save(launch_saved)
		if launch.is_empty():
			launch = LaunchSite.pick_for(shape, theater)
		return MarketPlaza.pick_for(shape, town, theater, launch, rejected)
	if not search_later:
		_on_found(job.call())
		return
	var found := _found
	_task = WorkerThreadPool.add_task(func() -> void: found[0] = job.call(), true, "The Market Square")


func _on_found(s: Dictionary) -> void:
	if s.is_empty():
		push_warning("The Market Square: no place for it beside Life Town (the LIFE tab still opens both)")
		return
	site = s
	stood = false
	if not host:
		_stand()


func _stand() -> void:
	if buildings:
		buildings.queue_free()
	buildings = MarketPlazaBuildings.new()
	add_child(buildings)
	buildings.setup(site, ground)
	stood = true


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
		_on_found(_found[0])
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
	var box := MarketPlaza.natural_box(site)
	var read: Callable = world.box_reader(box[0], box[1])
	var s := site.duplicate()
	var job := func() -> Dictionary:
		if not MarketPlaza.natural(s, read):
			return {"site": s, "natural": false}
		return {"site": s, "natural": true, "changes": MarketPlaza.clear_changes(s, read)}
	if not search_later:
		_take_check(job.call())
		return
	var out := _checked
	_check_task = WorkerThreadPool.add_task(func() -> void: out[0] = job.call(), true, "The Market Square's ground")


func _take_check(res: Variant) -> void:
	if not res is Dictionary or (res as Dictionary).get("site") != site:
		return
	if not bool(res.natural):
		var p: Vector3i = site.pos
		_rejected.append(Vector2i(p.x, p.z))
		print("MARKET_SQUARE site at %s holds a build: another place" % [p])
		site = {}
		_search()
		return
	_queue = res.changes
	if _queue.is_empty():
		_placed()


func _placed() -> void:
	_stand()
	print("MARKET_SQUARE stands at %s" % [site.pos])
	placed.emit(site)


func _loaded() -> bool:
	if not world.has_method("is_editable"):
		return true
	var p: Vector3i = site.pos
	for c: Vector2i in [MarketPlaza.PLAZA_MIN, MarketPlaza.PLAZA_MAX, Vector2i(MarketPlaza.PLAZA_MIN.x, MarketPlaza.PLAZA_MAX.y),
			Vector2i(MarketPlaza.PLAZA_MAX.x, MarketPlaza.PLAZA_MIN.y), Vector2i.ZERO]:
		var w := MarketPlaza.to_world(site, c)
		for y in [p.y - LifeTown.PLINTH_DEPTH, p.y + LifeTown.CLEAR_UP]:
			if not world.is_editable(Vector3i(w.x, y, w.y)):
				return false
	return true


## The place whose door feet at `feet` stand at ("" for none, or before it stands).
func near(feet: Vector3) -> String:
	return MarketPlaza.near(site, feet, ground) if stood else ""
