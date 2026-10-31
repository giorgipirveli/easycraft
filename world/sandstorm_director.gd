class_name SandstormDirector
extends Node
## Sandstorms in a Sandstorm Desert world (M3 Task 2, spec §14.1; rules in SandstormRules). The sandbox adds
## one on every peer, named "Sandstorm", when the world's universe has sandstorms (descriptor weather).
## Host: keeps the storm clock (calm spells and storms from the world seed; a warning first) and tells
## every game when a storm is coming, blows and ends (and a joining guest how things are).
## Every game: eases the storm's strength in and out; the view (Ambience.storm: sandy fog at half the
## distance, a sandy tint), the wind's loop and the toasts follow it; the host's StealthDirector asks
## visibility() for how visible someone outdoors is (× 0.5 in a full storm). Nothing here changes a block.

## Every game: a storm is coming (warning), blowing (on) or over.
signal storm_changed(on: bool, warning: bool)

const TICK := 0.5
const WIND_DB := -10.0            # the wind loop at full strength
const SILENT_DB := -40.0

var world_seed := 0
var host := false
## M3 Task 3: a Frostpeak snowstorm (its words and wind; set before it enters the tree).
var snow := false
## Every game: how strong the storm is now (0..1) and whether it blows (or is coming).
var strength := 0.0
var on := false
var warning := false
## This game's view: (strength) -> void (the sandbox sets Ambience.storm); toasts: (text) -> void.
var apply_view: Callable
var toast: Callable

var _n := 0                       # host: the storm number (SandstormRules.spell)
var _left := SandstormRules.FIRST_CALM   # host: seconds left of this calm spell or storm
var _t := 0.0
var _wind := AudioStreamPlayer.new()


func _ready() -> void:
	_wind.name = "Wind"
	_wind.stream = load(SandstormRules.style(snow).wind)
	_wind.volume_db = SILENT_DB
	add_child(_wind)


## Host and solo: the storm clock starts (calm first: a visit never begins in a storm).
func start_host(seed: int) -> void:
	host = true
	world_seed = seed
	_n = 0
	_left = maxf(SandstormRules.FIRST_CALM, SandstormRules.spell(seed, 0).x * 0.5)
	if not Session.client_ready.is_connected(_send_state_to):
		Session.client_ready.connect(_send_state_to)


func _process(delta: float) -> void:
	if host:
		_t += delta
		if _t >= TICK:
			tick(_t)
			_t = 0.0
	follow(delta)


## Host: the clock, TICK apart (tests call it with any step).
func tick(delta: float) -> void:
	_left -= delta
	if not on and not warning and _left <= SandstormRules.WARNING:
		_set_state.rpc(false, true)
	if _left > 0.0:
		return
	if on:
		_n += 1
		_left = SandstormRules.spell(world_seed, _n).x
		_set_state.rpc(false, false)
	else:
		_left = SandstormRules.spell(world_seed, _n).y
		_set_state.rpc(true, false)


## Every game: the strength eases towards the storm; the view and the wind follow it.
func follow(delta: float) -> void:
	var before := strength
	strength = SandstormRules.approach(strength, on, delta)
	if strength == before and not (on and not _wind.playing):
		return
	if apply_view.is_valid():
		apply_view.call(strength)
	if strength > 0.0 and not _wind.playing:
		_wind.play()
	_wind.volume_db = lerpf(SILENT_DB, WIND_DB, strength)
	if strength <= 0.0 and _wind.playing:
		_wind.stop()


## Host: how visible someone is (a factor on the light) at `underground` 0..1 (AmbienceRules).
func visibility(underground: float = 0.0) -> float:
	return SandstormRules.visibility(strength, underground)


## Host (tests, /time-like tools): a storm now, or calm now.
func force(storm: bool) -> void:
	_left = SandstormRules.STORM_MAX if storm else SandstormRules.CALM_MIN
	_set_state.rpc(storm, false)


func _send_state_to(peer_id: int) -> void:
	if multiplayer.get_peers().has(peer_id):
		_set_state.rpc_id(peer_id, on, warning)


@rpc("authority", "call_local", "reliable")
func _set_state(storm: bool, warn: bool) -> void:
	var was_on := on
	on = storm
	warning = warn and not storm
	if toast.is_valid():
		var words := SandstormRules.style(snow)
		if warning:
			toast.call(words.warn)
		elif storm and not was_on:
			toast.call(words.start)
		elif was_on and not storm:
			toast.call(words.end)
	storm_changed.emit(on, warning)


func _exit_tree() -> void:
	if apply_view.is_valid():
		apply_view.call(0.0)
