class_name LifeTownDirector
extends Node
## Owner #112 (docs/design/life-skills.md §7, Life Town; Life L2): a home world's Life Town (node "LifeTown" of the
## sandbox), following the Launch Site's way (LaunchDirector): setup() finds its site (the saved one, else a new one,
## LifeTown.pick_for on a worker, away from the Theater and the Launch Site, found from the save or the seed), and on the
## host checks once that its ground is still the world's own (LifeTown.natural: a child's build there moves it
## elsewhere), clears the trees and plants in and round its places (LifeTown.clear_changes: ordinary world edits, a
## batch a frame), stands the buildings (LifeTownBuildings: models, every device) and asks the save to keep the site
## (site_placed). A LAN guest finds it from the seed and stands it at once.
##
## Walking up to a place opens Life on its Experience on this device (LifeTownPanel); walking away, or BACK, closes it
## (after BACK it stays closed until the child walks away and back). While a practice room from it shows, the child's
## avatar is held still and kept safe (take_over, keep_safe: the sandbox's), and walking-away never closes the room.
## Nothing here goes over the network.
## Owner #115 (S3): once the town stands, its Market Square stands beside it (MarketPlazaPlacer, node "MarketSquare":
## found by Life Town's own search near the town, checked and cleared on the host like the town, saved with the town:
## site.market); walking up to its bakery or its stalls opens My Business's shop or the Market Square.

signal site_placed(saved: Array)
signal site_ready
## S3's follow-up (the lead): the Market Square's site is known (a saved one at once, a searched one when it stands):
## MY MAP marks it.
signal market_ready

const CHECK_SECONDS := 0.1
const WRITE_BATCH := 48
const SAFE_EVERY := 1.0

## The world (WorldService or a test's stand-in): is_editable, set_blocks, box_reader.
var world: Node
var host := true
var search_later := true
var site := {}
var stood := false
var buildings: LifeTownBuildings
var panel: LifeTownPanel
var player_position := Callable()   # () -> Vector3: the local player's feet; INF while not spawned
var overlay_open := Callable()      # () -> bool: another menu covers the screen
var keep_safe := Callable()         # () -> void: the avatar safe a moment (the sandbox: health.protect)
var take_over := Callable()         # (on: bool) -> void: hold the avatar still while a practice room shows
## (x, z) -> the first empty y (the generator's): where each place and its spot stand.
var ground := Callable()
var profile: ProfileData = null     # tests give theirs; the game's own otherwise
var save_profile := Callable()
var market_square: MarketPlazaPlacer   # owner #115 (S3)

var _shape: MeadowsShape
var _theater_saved: Array = []
var _launch_saved: Array = []
var _rejected: Array = []
var _task := -1
var _found: Array = [{}]
var _check_task := -1
var _checked: Array = [{}]
var _queue: Array = []
var _inside := ""
var _dismissed := false
var _wait := 0.0
var _safe_wait := 0.0
var _taken := false
var _market_saved := {}   # owner #115 (S3): the Market Square the save kept


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Finds the site (saved: WorldMeta.life_town) and adds the panel under `ui_parent`; `theater` and `launch` are the
## world's saved Theater and Launch Site ([] for the seed's). Returns what the save should keep now.
func setup(shape: MeadowsShape, saved: Array, theater: Array, launch: Array, ui_parent: Node) -> Array:
	_shape = shape
	_theater_saved = theater
	_launch_saved = launch
	if not ground.is_valid() and shape != null:
		ground = shape.height_at
	panel = LifeTownPanel.new()
	panel.closed.connect(_on_panel_closed)
	if ui_parent:
		ui_parent.add_child(panel)
	var known := LifeTown.from_save(saved)
	_market_saved = known.get("market", {})   # owner #115 (S3)
	if not known.is_empty():
		site = known
		stood = true
		_stand()
		return LifeTown.to_save(site)
	_search()
	return []


func _search() -> void:
	if _shape == null:
		return   # no generator (a test's stand-in world): nothing to search
	var shape := _shape
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
		return LifeTown.pick_for(shape, theater, launch, rejected)
	if not search_later:
		_on_found(job.call())
		return
	var found := _found
	_task = WorkerThreadPool.add_task(func() -> void: found[0] = job.call(), true, "Life Town")


func _on_found(s: Dictionary) -> void:
	if s.is_empty():
		push_warning("Life Town: no place for it near the spawn")
		return
	site = s
	stood = false
	if not host:
		_stand()   # a guest: the host checks and clears; the buildings stand here from the seed


func _stand() -> void:
	if buildings:
		buildings.queue_free()
	buildings = LifeTownBuildings.new()
	add_child(buildings)
	buildings.setup(site, ground)
	stood = true
	site_ready.emit()
	_stand_market()   # owner #115 (S3)


## Owner #115 (S3): the Market Square beside the town, once (its saved site, else the search near the town).
func _stand_market() -> void:
	if market_square != null or site.is_empty():
		return
	market_square = MarketPlazaPlacer.new()
	market_square.world = world
	market_square.host = host
	market_square.search_later = search_later
	market_square.placed.connect(func(m: Dictionary) -> void:
		site.market = m
		if host:
			site_placed.emit(LifeTown.to_save(site))
		market_ready.emit())
	add_child(market_square)
	var town := {"pos": site.pos, "facing": site.facing}
	market_square.setup(_shape, town, _market_saved, _theater_saved, _launch_saved, ground)
	if not _market_saved.is_empty():
		site.market = _market_saved
		market_ready.emit()


## The Experience of a place walked up to: the town's, or the Market Square's ("market/<id>").
static func _experience_of(spot: String) -> String:
	if spot.begins_with("market/"):
		return str(MarketPlaza.SPOTS[spot.trim_prefix("market/")].experience)
	return str(LifeTown.SPOTS[spot].experience)


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
		_place_step()
	_wait -= delta
	if _wait <= 0.0:
		_wait = CHECK_SECONDS
		_follow_player()
	_hold_while_practising(delta)


## The host: once its ground is loaded, check it is the world's own (on a worker), clear its trees and plants a batch a
## frame, then stand the buildings and ask the save to keep the site.
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
	var box := LifeTown.natural_box(site)
	var read: Callable = world.box_reader(box[0], box[1])
	var s := site.duplicate()
	var job := func() -> Dictionary:
		if not LifeTown.natural(s, read):
			return {"site": s, "natural": false}
		return {"site": s, "natural": true, "changes": LifeTown.clear_changes(s, read)}
	if not search_later:
		_take_check(job.call())
		return
	var out := _checked
	_check_task = WorkerThreadPool.add_task(func() -> void: out[0] = job.call(), true, "Life Town's ground")


func _take_check(res: Variant) -> void:
	if not res is Dictionary or (res as Dictionary).get("site") != site:
		return
	if not bool(res.natural):
		var p: Vector3i = site.pos
		_rejected.append(Vector2i(p.x, p.z))   # a child built here: another place
		print("LIFE_TOWN site at %s holds a build: another place" % [p])
		site = {}
		_search()
		return
	_queue = res.changes
	if _queue.is_empty():
		_placed()


func _placed() -> void:
	_stand()
	print("LIFE_TOWN stands at %s" % [site.pos])
	site_placed.emit(LifeTown.to_save(site))


## The plaza's corners and middle are loaded (editable).
func _loaded() -> bool:
	if not world.has_method("is_editable"):
		return true
	var p: Vector3i = site.pos
	for c: Vector2i in [LifeTown.PLAZA_MIN, LifeTown.PLAZA_MAX, Vector2i(LifeTown.PLAZA_MIN.x, LifeTown.PLAZA_MAX.y),
			Vector2i(LifeTown.PLAZA_MAX.x, LifeTown.PLAZA_MIN.y), Vector2i.ZERO]:
		var w := LifeTown.to_world(site, c)
		for y in [p.y - LifeTown.PLINTH_DEPTH, p.y + LifeTown.CLEAR_UP]:
			if not world.is_editable(Vector3i(w.x, y, w.y)):
				return false
	return true


## Walking up to a place opens Life on it; walking away closes it (never a practice room that shows).
func _follow_player() -> void:
	if panel == null or not stood or not player_position.is_valid():
		return
	if panel.room_open():
		return
	var feet: Vector3 = player_position.call()
	var paused := is_inside_tree() and get_tree().paused
	var spot := "" if paused else LifeTown.near(site, feet, ground)
	if spot == "" and not paused and market_square != null:   # owner #115 (S3): the Market Square's two places
		var m := market_square.near(feet)
		spot = "market/" + m if m != "" else ""
	if spot != _inside:
		_dismissed = false   # a BACK holds for the place it was pressed at, never the next one
		if spot != "" and not (overlay_open.is_valid() and bool(overlay_open.call())):
			panel.open_experience(_experience_of(spot), profile, save_profile)
		elif spot == "" and panel.visible:
			panel.close()
			_dismissed = false
	_inside = spot


func _on_panel_closed() -> void:
	_dismissed = _inside != ""


## While a practice room from Life Town shows: the avatar held still and kept safe (monsters, the night).
func _hold_while_practising(delta: float) -> void:
	var practising := panel != null and panel.room_open()
	if practising != _taken:
		_taken = practising
		if take_over.is_valid():
			take_over.call(practising)
	if not practising:
		return
	_safe_wait -= delta
	if _safe_wait <= 0.0:
		_safe_wait = SAFE_EVERY
		if keep_safe.is_valid():
			keep_safe.call()


## Android Back: true when Life Town took it (its panel closed, or a practice room's own card takes it).
func close_if_open() -> bool:
	return panel != null and panel.close_if_open()


func saved_site() -> Array:
	return LifeTown.to_save(site) if stood else []
