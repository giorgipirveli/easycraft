class_name UniverseHub
extends Node
## The portal hub in a world (M3 Task 5, spec §14.1), on every game (per device, nothing sent): the
## stone circle by a Survivor world's spawn (HubCircle, placed from the seed by HubRules) and the hub
## panel (HubPanel). Ten times a second it looks where this game's player stands: walking into the
## circle opens the panel with every unlocked universe; walking away closes it. GO! and walking into a
## boss portal (BossDirector.portal_entered) ask `travel` (the sandbox's travel_to), which says why not.

const CHECK_EVERY := 0.1

## () -> Vector3: this game's player's feet (INF when there is none, or it isn't standing in the world).
var player_position: Callable = func() -> Vector3: return Vector3.INF
## (universe: int) -> String: travels there, or says why not ("" = on the way).
var travel: Callable = func(_u: int) -> String: return ""
## (text: String) -> void: a short message on this game's screen.
var toast: Callable = func(_t: String) -> void: pass

var circle: HubCircle
var panel: HubPanel

var _armed := true
var _check_t := 0.0


## The panel, in the world's UI layer.
func setup_panel(ui_parent: Node) -> void:
	panel = HubPanel.new()
	panel.name = "HubPanel"
	ui_parent.add_child(panel)
	panel.travel_requested.connect(_on_travel_requested)


## The stone circle at `spot` ({pos, yaw}, HubRules.circle_for_world), each stone on the ground of its
## own column (the terrain's rules, `shape`), under `world_parent`.
func setup_circle(spot: Dictionary, shape: MeadowsShape, world_parent: Node) -> void:
	var center: Vector3 = spot.pos
	var yaw := float(spot.get("yaw", 0.0))
	var turn := Basis(Vector3.UP, yaw)
	var heights: Array[float] = []
	for i in HubRules.STONES:
		var a := TAU * i / HubRules.STONES
		var at := center + turn * (Vector3(cos(a), 0.0, sin(a)) * HubRules.STONE_RING)
		heights.append(clampf(float(shape.height_at(floori(at.x), floori(at.z))) - center.y, -1.0, 1.0))
	circle = HubCircle.new()
	circle.setup(center, yaw, heights)
	world_parent.add_child(circle)


func _process(delta: float) -> void:
	tick(delta)


## CHECK_EVERY: into the circle opens the hub (once until the player walks away), away closes it.
func tick(delta: float) -> void:
	_check_t -= delta
	if _check_t > 0.0 or circle == null or panel == null:
		return
	_check_t = CHECK_EVERY
	var feet: Vector3 = player_position.call()
	if _armed and HubRules.inside(feet, circle.position):
		_armed = false
		open_hub()
	elif not _armed and HubRules.left(feet, circle.position):
		_armed = true
		panel.close()


## Every unlocked universe (this one "You are here").
func open_hub() -> void:
	panel.open(UniverseRegistry.hub_entries(Profile.data.universe_unlocked), Game.universe)


## A walk into a boss portal leading to `target`.
func portal_entered(target: int) -> void:
	if target == UniverseRules.HUB:   # M3 Task 4: the last universe's portal opens the hub
		open_hub()
		return
	var why: String = travel.call(target)
	if why != "":
		toast.call(why)


func _on_travel_requested(u: int) -> void:
	var why: String = travel.call(u)
	if why != "":
		panel.say(why)
