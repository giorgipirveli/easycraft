class_name SpaceDirector
extends Node
## Space on this game (owner feedback #55, spec §21.1), per device, nothing sent: ten times a second it looks how high
## this game's player is (its position only: however it flies — the fly switch, a double tap, a buddy, a glider). On
## the way up the sky turns to space (sky_climb, SpaceRules.climb) and "Keep flying up!" is said once per climb;
## crossing the space line opens "Where shall we land?" (SpacePanel), once until the child comes back under
## SpaceRules.REARM_Y. The picker's choices go to the sandbox: travel (land on a space world), go_home (from a space
## world), stay (back under the line). Only where flying is (SpaceRules.may_launch: never Monster Wave).

const CHECK_EVERY := 0.1

## The world landed on by the last trip (the sandbox sets it just before the new world loads; take_landing reads it
## once there: the landing words and the puff of dust).
static var landing := 0

## () -> Vector3: this game's player's feet (INF when there is none).
var player_position: Callable = func() -> Vector3: return Vector3.INF
## () -> StringName: the game mode (Game.mode).
var mode: Callable = func() -> StringName: return Game.mode
## This world's number, and its home (WorldMeta.space_home: a space world's way home).
var here := 1
var home := 1
## (id: StringName) -> void: a body's card was opened on the Star Map (the Space Book, spec §21b.2).
var seen: Callable = func(_id: StringName) -> void: pass
## () -> int: the highest universe opened (Profile.data.universe_unlocked): the Star Map's universes say PORTAL or LOCKED.
var unlocked: Callable = func() -> int: return UniverseRules.FIRST
## () -> Array[int]: the worlds to land on whose files exist (UniverseRegistry.trip_available: space's and, owner #78, Earth's).
var available: Callable = func() -> Array[int]: return UniverseRegistry.trip_available()
## () -> Variant: spec §21d.5: the worlds this child has reached (MissionRules.route), or null for no missions.
var route: Callable = func() -> Variant: return null
## (universe: int) -> String: lands there, or says why not ("" = on the way).
var travel: Callable = func(_u: int) -> String: return ""
## () -> String: from a space world, home (or why not).
var go_home: Callable = func() -> String: return ""
## () -> void: STAY HERE (the sandbox puts the flyer back under the line).
var stay: Callable = func() -> void: pass
## (text: String) -> void: a short line on this game's screen.
var toast: Callable = func(_t: String) -> void: pass
## (climb: float) -> void: the sky's climb toward space changed.
var sky_climb: Callable = func(_c: float) -> void: pass
## () -> bool: hold the game still while the picker shows (played alone).
var may_hold: Callable = func() -> bool: return false
## () -> void: M7 (the browser's freezes): the space worlds' files start loading in the background, once, when the climb
## begins (UniverseRegistry.warm_space), so the picker never loads them in its frame.
var warm: Callable = func() -> void: UniverseRegistry.warm_space()

var panel: SpacePanel

var _check_t := 0.0
var _armed := true
var _hinted := false
var _climb := 0.0
var _warmed := false


## The picker, in the world's UI layer.
func setup_panel(ui_parent: Node) -> void:
	panel = SpacePanel.new()
	panel.name = "SpacePanel"
	ui_parent.add_child(panel)
	panel.travel_requested.connect(_on_travel)
	panel.home_requested.connect(_on_home)
	panel.stay_requested.connect(func() -> void: stay.call())
	panel.body_seen.connect(func(id: StringName) -> void: seen.call(id))


## True once when the last trip landed on world u (and forgets it either way).
static func take_landing(u: int) -> bool:
	var was := landing
	landing = 0
	return was != 0 and was == u


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = CHECK_EVERY
	var feet: Vector3 = player_position.call()
	var y := feet.y if feet.is_finite() else NAN
	if not SpaceRules.may_launch(mode.call()):
		y = NAN
	_follow_climb(SpaceRules.climb(y))
	if not is_finite(y):
		return
	if not _warmed and y >= SpaceRules.CLIMB_FROM:
		_warmed = true
		warm.call()
	if y < SpaceRules.CLIMB_FROM:
		_hinted = false
	elif y >= SpaceRules.HINT_Y and not _hinted and y < SpaceRules.SPACE_Y:
		_hinted = true
		toast.call(Lang.t(SpaceRules.HINT_WORDS))
	if SpaceRules.rearms(y):
		_armed = true
	if SpaceRules.crossed(y, _armed):
		_armed = false
		open_picker()


## The Star Map ("Where shall we land?") now.
func open_picker() -> void:
	if panel == null:
		return
	panel.hold = bool(may_hold.call())
	panel.open(here, home, available.call(), int(unlocked.call()), route.call())


func close_picker() -> bool:
	if panel == null or not panel.visible:
		return false
	panel.close()
	return true


func _follow_climb(c: float) -> void:
	var edge := (c == 0.0 or c == 1.0) and c != _climb
	if not edge and absf(c - _climb) < SkyCycle.CLIMB_STEP:
		return
	_climb = c
	sky_climb.call(c)


func _on_travel(u: int) -> void:
	var why: String = travel.call(u)
	if why != "":
		panel.say(why)
	else:
		panel.close()


func _on_home() -> void:
	var why: String = go_home.call()
	if why != "":
		panel.say(why)
	else:
		panel.close()
