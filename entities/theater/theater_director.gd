class_name TheaterDirector
extends Node
## The Shorts Theater in a world (spec §5.12, §14.12; M3 Task 17). setup() stands the building on
## its site (the saved one, else a new one about 30 blocks from the spawn, TheaterSite) and adds
## the video panel to the UI. Walking into the room opens the panel on this device; walking out,
## or EXIT, closes it (after EXIT it stays closed until the player walks out and in again). While a
## menu covers the middle of the screen, the Android player steps aside.
##
## The Theater is per device: nothing about it goes over the network. A LAN guest finds it from the
## seed like the host. The channel list's kill-switch leaves it out (a saved site is kept for when
## it comes back). Owner #89: when this device is online (`online`), the server's list is read and kept
## (TheaterFeed); the panel plays it from its next opening. The player is the browser page's block on the web,
## the Android plugin elsewhere (null: stills or "Coming soon").

const CHECK_SECONDS := 0.1
const PICTURE_SIZE := Vector2i(480, 270)
## M7: the site the worker found (search_later): what the world save should keep now.
signal site_placed(saved: Array)

var list: Dictionary = {}
var site: Dictionary = {}
var building: TheaterBuilding
var panel: TheaterPanel
var player_position := Callable()   # () -> Vector3, the local player's feet; INF while not spawned
var overlay_open := Callable()      # () -> bool: a menu covers the middle of the screen
var online := Callable()            # () -> OnlineService or null (the sandbox's); the server's list when online
var feed_cache := TheaterFeed.CACHE_PATH

## M7 (the browser's freezes): a new world's site search (up to ~110 ms on the desktop, several times that on a phone)
## ran in the world switch's frame. With search_later (the sandbox's) it runs on a worker (like Pip's
## playground search, M5 Task 3: high priority) and the Theater stands a moment later (site_placed).
var search_later := false

var _saved: Array = []
var _inside := false
var _wait := 0.0
var _picture: SubViewport
var _task := -1
var _found: Array = [{}]   # the worker's answer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps the Android player hidden under the pause menu


## Places the Theater and adds the panel under `ui_parent`. `saved` is the world's TheaterSite
## save ([] = never placed). Returns what the world save should keep.
func setup(shape: MeadowsShape, saved: Array, ui_parent: Node, channels: Dictionary, avoid: Array = []) -> Array:
	list = channels
	_saved = saved
	_read_server_list.call_deferred()   # owner #89: also when the kept list is the kill-switch (it may come back)
	if list.get("enabled") != true:
		return _saved
	site = TheaterSite.from_save(saved)
	if TheaterSite.stands_on_colony(shape, site):
		site = {}   # spec §21c: a space world saved before its colony: the Theater moves off the colony's ground
	if site.is_empty() and search_later:
		var found := _found
		_task = WorkerThreadPool.add_task(func() -> void: found[0] = TheaterSite.pick_for(shape, avoid), true,
			"Theater site")   # _process stands it when it is done
		_add_panel(ui_parent)
		return _saved
	if site.is_empty():
		site = TheaterSite.pick_for(shape, avoid)
	if site.is_empty():
		push_warning("Theater: no flat, dry ground near the spawn")
		return _saved
	_saved = TheaterSite.to_save(site)
	_stand()
	_add_panel(ui_parent)
	return _saved


func _stand() -> void:
	building = TheaterBuilding.new()
	building.name = "TheaterBuilding"
	add_child(building)
	building.setup(site)


func _add_panel(ui_parent: Node) -> void:
	panel = TheaterPanel.new()
	panel.name = "TheaterPanel"
	panel.list = list
	panel.backend = player_backend()
	panel.picture_provider = world_picture
	ui_parent.add_child(panel)


## This build's video player: the page's block in a browser (owner #89), the Android plugin in a Gradle APK, null
## elsewhere.
static func player_backend() -> Object:
	if OS.has_feature("web"):
		return TheaterWebPlayer.create()
	return TheaterWebView.create()


## Owner #89: the server's list, when this device is online now or signs in during the world. A new list plays
## from the panel's next opening; the kill-switch closes it then.
func _read_server_list() -> void:
	var service: Object = online.call() if online.is_valid() else null
	if service == null or not is_inside_tree():
		return
	if service.get("status") != OnlineService.ONLINE:
		if service.has_signal("status_changed") and not service.is_connected("status_changed", _on_online_status):
			service.connect("status_changed", _on_online_status)
		return
	var fresh: Dictionary = await TheaterFeed.fetch(service, feed_cache)
	if fresh.is_empty() or not is_inside_tree():
		return
	list = fresh
	if panel:
		panel.list = fresh


func _on_online_status(status: StringName) -> void:
	if status == OnlineService.ONLINE:
		_read_server_list()


## The worker's search ended: the Theater stands there (nothing when there is no site).
func _on_found() -> void:
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	site = _found[0]
	if site.is_empty():
		push_warning("Theater: no flat, dry ground near the spawn")
		return
	_saved = TheaterSite.to_save(site)
	_stand()
	site_placed.emit(_saved)


func _exit_tree() -> void:
	if _task != -1:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func saved_site() -> Array:
	return _saved


func _process(delta: float) -> void:
	if _task != -1 and WorkerThreadPool.is_task_completed(_task):
		_on_found()
	if panel == null or not player_position.is_valid():
		return
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = CHECK_SECONDS
	if not get_tree().paused:
		var inside := TheaterSite.is_inside(site, player_position.call())
		if inside and not _inside:
			panel.open()
		elif not inside and _inside:
			panel.close()
		_inside = inside
	var covered := get_tree().paused or (overlay_open.is_valid() and bool(overlay_open.call()))
	panel.set_covered(covered)


## A picture of the world for the end card: seen from above the Theater's door, looking towards
## the spawn. One small render, shared with the world (no second copy of anything).
func world_picture() -> Texture2D:
	if site.is_empty() or not is_inside_tree():
		return null
	if _picture == null:
		_picture = SubViewport.new()
		_picture.name = "WorldPicture"
		_picture.size = PICTURE_SIZE
		_picture.world_3d = get_viewport().world_3d
		var cam := Camera3D.new()
		cam.fov = 70.0
		_picture.add_child(cam)
		add_child(_picture)
		var c: Vector3i = site.pos
		var door := TheaterSite.door_dir(site.facing)
		var from := Vector3(c.x + 0.5, c.y, c.z + 0.5) + Vector3(door.x, 0, door.y) * (TheaterSite.HALF + 3) + Vector3(0, 9, 0)
		cam.position = from
		cam.look_at(from + Vector3(door.x, -0.45, door.y), Vector3.UP)
		cam.current = true
	_picture.render_target_update_mode = SubViewport.UPDATE_ONCE
	return _picture.get_texture()
