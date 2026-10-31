class_name SleepDirector
extends Node
## Beds and sleeping in the sandbox (M1b Task 10).
## Every peer: finds a bed next to the local player for the HUD's SLEEP button, and shows who
## sleeps (lying avatars with "Zzz"; the local screen fades).
## Host: accepts or refuses sleep requests (BedRules), makes the bed the sleeper's home, and once
## every player in the game sleeps it skips the clock (SkyCycle) to the next sunrise at night or
## sunset by day and wakes everyone. A player who leaves never blocks the skip. Breaking a bed
## clears it as a home and wakes whoever sleeps in it.

const SCAN_INTERVAL := 0.25
const SKIP_DELAY := 2.5           # everyone sleeps this long before the time skips (lie down, Zzz, fade)
const WAKE_KEY := KEY_B           # desktop: B sleeps and wakes, like the button
const WAKE_TOAST_WINDOW := 0.002  # of a day (about 2 s): "Good morning!" right after a skip

var world: WorldService
var sky: SkyCycle
var player: Player                # the local player (may be null on a dedicated host)
var hud: Hud

var nearby_bed := BedRules.NO_BED
## Host: (peer_id) -> String, why this player may not sleep now ("" = they may; Build to Survive's beds need
## a shelter, SurvivorGameDirector.sleep_refusal).
var may_sleep: Callable

var _scan_t := 0.0
var _sleepers := {}               # host: {peer_id: bed}
var _homes := {}                  # host: {peer_id: bed}
var _skip_t := -1.0               # host: countdown to the skip while everyone sleeps


func _ready() -> void:
	Session.sleep_state_received.connect(_on_sleep_state)
	Session.home_received.connect(_on_home)
	Session.go_home_received.connect(_on_go_home)
	if hud:
		hud.add_sleep_controls()
		hud.sleep_button.pressed.connect(press_sleep)
	if Session.is_host():
		Session.bed_sleep_requested.connect(_on_bed_sleep_requested)
		Session.bed_wake_requested.connect(_on_bed_wake_requested)
		Session.client_ready.connect(_on_client_ready)
		Session.peer_left.connect(_on_peer_left)
		world.block_changed.connect(_on_block_changed)


## The SLEEP / WAKE UP button (and B on a keyboard).
func press_sleep() -> void:
	if player == null:
		return
	if player.sleeping:
		Session.request_bed_wake()
	elif nearby_bed != BedRules.NO_BED:
		Session.request_bed_sleep(nearby_bed)


## Host: the local player's saved home (from WorldMeta).
func restore_home(bed: Vector3i) -> void:
	if player:
		_homes[player.peer_id] = bed
		player.set_home(true, bed)


## Host: a player's home bed, or BedRules.NO_BED.
func home_of(peer_id: int) -> Vector3i:
	return _homes.get(peer_id, BedRules.NO_BED)


## Host: sends a player home (the chat's /home).
func send_player_home(peer_id: int) -> void:
	Session.send_go_home(peer_id)


func _process(delta: float) -> void:
	if Session.is_host():
		_process_skip(delta)
	if not is_instance_valid(player):   # none on a dedicated host; freed when a LAN host quits
		return
	if player.sleeping:
		if Input.is_action_just_pressed(&"jump"):
			Session.request_bed_wake()
		return
	_scan_t -= delta
	if _scan_t > 0.0:
		return
	_scan_t = SCAN_INTERVAL
	var bed := BedRules.NO_BED
	if player.is_spawned() and player.is_on_floor() and player.physics_mode == PhysicsMode.Mode.NORMAL \
			and not player.is_riding():   # M3 Task 20a: no bed from a buddy's saddle
		var box: Array = BedRules.scan_box(player.global_position)
		bed = BedRules.find_bed(player.global_position, world.box_reader(box[0], box[1]))
	if bed != nearby_bed:
		nearby_bed = bed
		if hud:
			hud.show_sleep_button(bed != BedRules.NO_BED)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == WAKE_KEY:
		press_sleep()


# --- Every peer -------------------------------------------------------------------------------

func _on_sleep_state(peer_id: int, asleep: bool, bed: Vector3i) -> void:
	var p := Session._player_for_peer(peer_id)
	if p == null:
		return
	p.set_sleeping(asleep, bed)
	if p != player:
		if asleep and hud and player and not player.sleeping:
			hud.toast("A friend is sleeping. Sleep in a bed too to skip ahead!")
		return
	nearby_bed = BedRules.NO_BED
	_scan_t = 0.0
	if hud == null:
		return
	hud.set_sleeping(asleep)
	hud.show_sleep_button(asleep, "WAKE UP")
	if not asleep and sky:   # the clock was just set; allow a frame or two before the wake arrives
		if absf(sky.time - DayCycle.SUNRISE) < WAKE_TOAST_WINDOW:
			hud.toast("Good morning!")
		elif absf(sky.time - DayCycle.SUNSET) < WAKE_TOAST_WINDOW:
			hud.toast("Good evening!")


func _on_home(has_home: bool, bed: Vector3i) -> void:
	if player == null:
		return
	player.set_home(has_home, bed)
	if hud:
		hud.toast("This bed is your home now." if has_home else "Your bed is gone! Home is the world spawn again.")


func _on_go_home() -> void:
	if player == null:
		return
	if player.sleeping:
		Session.request_bed_wake()
	player.go_home()


# --- Host -------------------------------------------------------------------------------------

func _on_bed_sleep_requested(peer_id: int, bed: Vector3i) -> void:
	var p := Session._player_for_peer(peer_id)
	if p == null or not p.is_spawned() or _sleepers.has(peer_id):
		return
	var why: String = may_sleep.call(peer_id) if may_sleep.is_valid() else ""   # Survivor games (spec §12.18)
	if why != "":
		_tell(peer_id, why)
		return
	var feet := p.global_position
	var in_water := world.get_block(Vector3i((feet + Vector3(0, 0.6, 0)).floor())) == BlockIds.WATER
	var on_floor := p.is_on_floor() if p.is_local else true   # remote bodies are simulated by their owners
	var error := BedRules.check(world.get_block(bed), bed, feet, on_floor, in_water, world.get_block(bed + Vector3i.UP),
		p.physics_mode, _sleepers.values().has(bed), BedRules.REACH + BedRules.REACH_TOLERANCE)
	if error != "":
		_tell(peer_id, BedRules.message(error))
		return
	_sleepers[peer_id] = bed
	if _homes.get(peer_id) != bed:
		_homes[peer_id] = bed
		Session.send_home(peer_id, true, bed)
	Session.broadcast_sleep_state(peer_id, true, bed)
	_check_all_asleep()


func _on_bed_wake_requested(peer_id: int) -> void:
	if _sleepers.has(peer_id):
		_wake(peer_id)
		_check_all_asleep()


func _on_peer_left(peer_id: int) -> void:
	_sleepers.erase(peer_id)
	_homes.erase(peer_id)
	_check_all_asleep(peer_id)


## A player who joins sees who is already sleeping. They are awake, so a running skip stops and
## the sleepers hear the new count. The sandbox adds the joiner's body after this runs, so the
## joiner is counted by id (review M6).
func _on_client_ready(peer_id: int) -> void:
	for id: int in _sleepers:
		Session.send_sleep_state(peer_id, id, true, _sleepers[id])
	_check_all_asleep(0, peer_id)


func _on_block_changed(pos: Vector3i, old_id: int, new_id: int) -> void:
	if old_id != BlockIds.BED or new_id == BlockIds.BED:
		return
	for id: Variant in BedRules.lost_homes(_homes, pos, new_id):
		_homes.erase(id)
		Session.send_home(id, false, pos)
	var woke := false
	for id: int in _sleepers.keys():
		if _sleepers[id] == pos:
			_wake(id)
			woke = true
	if woke:
		_check_all_asleep()


## Starts the countdown to the skip when everyone sleeps; otherwise tells the sleepers how many
## are still awake. leaving: a player on the way out (their node may still be in the tree);
## joining: a player whose body is not in the tree yet.
func _check_all_asleep(leaving: int = 0, joining: int = 0) -> void:
	var ids := _player_ids(leaving)
	if joining != 0 and not ids.has(joining):
		ids.append(joining)
	if BedRules.all_asleep(ids, _sleepers):
		if _skip_t < 0.0:
			_skip_t = SKIP_DELAY
		return
	_skip_t = -1.0
	var asleep := BedRules.asleep_count(ids, _sleepers)
	for id: int in _sleepers:
		_tell(id, tr("Zzz... %d of %d asleep. Everybody sleeps in a bed to skip ahead!") % [asleep, ids.size()])


func _process_skip(delta: float) -> void:
	if _skip_t < 0.0:
		return
	_skip_t -= delta
	if _skip_t > 0.0:
		return
	_skip_t = -1.0
	if not BedRules.all_asleep(_player_ids(), _sleepers):
		_check_all_asleep()   # never give up silently: the sleepers hear the count
		return
	if sky:
		sky.set_time(DayCycle.wake_time(sky.time))
	for id: int in _sleepers.keys():
		_wake(id)


func _wake(peer_id: int) -> void:
	var bed: Vector3i = _sleepers[peer_id]
	_sleepers.erase(peer_id)
	Session.broadcast_sleep_state(peer_id, false, bed)


func _player_ids(leaving: int = 0) -> Array:
	var ids := []
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		if p.peer_id != leaving and not p.is_queued_for_deletion():
			ids.append(p.peer_id)
	return ids


## A message for one player, if they are still here.
func _tell(peer_id: int, text: String) -> void:
	if peer_id == multiplayer.get_unique_id() or multiplayer.get_peers().has(peer_id):
		Session.send_feedback(peer_id, text)


## Host: every player's home bed (M2 Task 4: night monsters never appear within 8 blocks of one).
func home_beds() -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	out.assign(_homes.values())
	return out
