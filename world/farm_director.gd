class_name FarmDirector
extends Node
## The Gold Farm in a Survivor world (M3 Task 10; spec §5.6, §14.8, §17.6). The sandbox adds one on every
## peer, always named "Farm", so its RPCs line up across the network. The farm is the world's owner's (the
## host's player): guests see it, walk in it and see its panel, but it pays and grows for the owner only.
## Host:
## - Places it (Session.farm_place_requested): Survivor, the owner, none yet in this world, a FARM item in
##   their bag (taken), within reach, loaded ground that FarmSite says takes it, nobody standing in the barn.
## - Upgrades it (Session.farm_upgrade_requested): FarmRules' fixed prices through Session.gold_spend.
## - Every world save asks for_save(): the owner inside the farm leaves an away record (the device clock,
##   and when signed in the server's clock too: farm_collect "start", at most every SERVER_EVERY_MS); outside,
##   none. A record found when the world starts waits for the welcome-back and is never overwritten first.
## - The welcome-back (the world starts, or the app comes back after RESUME_MIN_AWAY): the server's
##   farm_collect when the record says the server was started and this phone is signed in, else the device
##   clock (FarmRules.welcome: nothing for a clock that went backwards). It pays once (the record goes and the
##   world is saved at once), through Session.gold_add, or farm_pay_collected for gold the server paid.
## - The opt-in "Your farm is full!" note (FarmNotifyRules, FarmNotifier) is asked for when the owner leaves
##   inside and taken back when they return.
## Every peer: the building from the host's state (_rpc_state), and its workers move while this game's
## player is near (NEAR, looked at CHECK_EVERY).

## Host (the owner's game): the welcome-back paid `gold` (0 = nothing to show); `capped`: the barn was full.
signal welcomed(gold: int, capped: bool)
## Every peer: the host's farm ({} = none), without the away record.
signal state_received(farm: Dictionary)
## Host: a farm was placed or upgraded (the sandbox puts it in the world save).
signal changed(farm: Dictionary)

const CHECK_EVERY := 0.25
const NEAR := 48.0
const HOST_REACH := 10.0          # the owner's eye to the tapped cell (a stamp's reach, with lag)
const UPGRADE_REACH := 16.0       # the owner's eye to the farm's centre for an upgrade
const SERVER_EVERY_MS := 30_000
const RESUME_MIN_AWAY := 300      # seconds in the background before the app's return is a welcome-back
const CONNECT_WAIT := 8.0         # seconds a welcome-back waits for a sign-in in progress
const BUILT_TEXT := "Your Gold Farm is ready! Stand on it when you stop playing, and it makes gold while you are away."
const NO_FARM_ITEM := "You have no Gold Farm to place. Tilly sells one!"
const TOO_FAR := "Come closer to place your farm!"
const IN_THE_WAY := "Step off that spot first!"
const RATE_TEXT := "Faster farm! %s gold an hour."
const CAP_TEXT := "Bigger barn! It holds %d hours of gold."
const MOVED_TEXT := "Your farm is back in your bag. Pick a new spot for it!"
const ONE_MOMENT := "One moment!"
const SPARKLE := Color("ffd23f")

# Host, injected by the sandbox (tests use stubs).
var farm: Dictionary = {}
var universe := 1
var slot := ""                                  # the world's save slot: the server's key for its farm clock
var mode: StringName = ModeRules.SURVIVOR
var block_reader: Callable = _world_reader     # (origin: Vector3i, size: Vector3i) -> Callable(Vector3i) -> int
var area_ready: Callable = _world_ready        # (cell: Vector3i) -> bool
var eye_of: Callable = _eye_of                  # (peer) -> Vector3, INF when no body
var bodies: Callable = _bodies                  # () -> Array[Vector3]: feet of every player and bot friend
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())
var msec: Callable = Time.get_ticks_msec
var online: Callable = Session.online_service_or_null   # () -> OnlineService or null
var pay: Callable = _pay                        # (gold) -> void: the owner's gold, the host's way
var pay_collected: Callable = Session.farm_pay_collected   # (gold) -> void: gold the server already paid
var tell: Callable = _tell                      # (peer, text) -> void
var save_now: Callable = Callable()             # () -> void: save the world at once (the welcome-back)
var save_meta: Callable = Callable()            # () -> void: save the world's meta (a server start answered)
var notifier: FarmNotifier = FarmNotifier.for_platform()
var profile: ProfileData                        # default Profile.data (the note's switch and time)
var tz_bias: int = int(Time.get_time_zone_from_system().get("bias", 0))
## Every peer: () -> Vector3, this game's player's feet (INF when not spawned); its workers wake near it.
var local_feet: Callable = Callable()

var building: FarmBuilding
var _welcoming := false
var _waiting := false          # a record found at start waits for the welcome-back
var _server_ms := -1           # when the server's clock was last started (msec), -1 never this stay
var _check := 0.0
var _holder := Node3D.new()


func _ready() -> void:
	if profile == null:
		profile = Profile.data
	_holder.name = "Buildings"
	_holder.top_level = true
	add_child(_holder)


func _exit_tree() -> void:
	if Session.farm_built.is_valid() and Session.farm_built.get_object() == self:
		Session.farm_built = Callable()


# --- Host: the farm ------------------------------------------------------------------------------------

## Host: the world's saved farm (WorldMeta.farm). A record of the owner leaving inside waits for welcome_back.
func start(saved: Dictionary) -> void:
	farm = saved.duplicate(true)
	_waiting = farm.has("away")
	Session.farm_built = owns_farm
	_broadcast()


## A farm stands in the world.
func has_farm() -> bool:
	return FarmRules.standing(farm)


## The world has its farm, standing or picked up to move (Tilly sells no second one).
func owns_farm() -> bool:
	return not farm.is_empty()


## Host: places the owner's farm. "" when it was built, else the words the player was told.
func host_place(peer_id: int, anchor: Vector3i, facing: int) -> String:
	var why := _place_refusal(peer_id, anchor, facing)
	if why != "":
		tell.call(peer_id, why)
		return why
	Session.inventory_of(peer_id).take(ItemIds.FARM, 1)
	var center := FarmSite.center_for(anchor, facing)
	farm = FarmRules.placed_again(farm, center, facing)   # a moved farm keeps its levels
	_server_ms = -1
	changed.emit(farm)
	_broadcast()
	_rpc_cheer.rpc(Vector3(center) + Vector3(0.5, 2.0, 0.5))
	tell.call(peer_id, BUILT_TEXT)
	return ""


func _place_refusal(peer_id: int, anchor: Vector3i, facing: int) -> String:
	if not FarmRules.wants_farm(mode):
		return FarmRules.message("survivor_only")
	var buy := FarmRules.buy_refusal(peer_id == multiplayer.get_unique_id(), has_farm())
	if buy != "":
		return FarmRules.message(buy)
	if Session.inventory_of(peer_id).count(ItemIds.FARM) <= 0:
		return NO_FARM_ITEM
	var eye: Vector3 = eye_of.call(peer_id)
	if not eye.is_finite() or eye.distance_to(Vector3(anchor) + Vector3(0.5, 0.5, 0.5)) > HOST_REACH:
		return TOO_FAR
	var center := FarmSite.center_for(anchor, facing)
	if not bool(area_ready.call(center)):
		return FarmSite.message("farm_ground")
	var box: Array = FarmSite.box(center)
	var why := FarmSite.refusal(center, facing, block_reader.call(box[0], box[1]))
	if why != "":
		return FarmSite.message(why)
	var probe := FarmRules.new_farm(center, facing)
	for feet: Vector3 in bodies.call():
		if FarmSite.in_barn(probe, feet):
			return IN_THE_WAY
	return ""


## Host: one level up in `kind` for the owner, paid with Survivor gold. "" when done, else the words told.
func host_upgrade(peer_id: int, kind: StringName) -> String:
	var owner := peer_id == multiplayer.get_unique_id()
	var why := FarmRules.upgrade_refusal(farm, kind, Session.gold_of(peer_id), universe, owner)
	if why == "" and not FarmRules.wants_farm(mode):
		why = "survivor_only"
	var eye: Vector3 = eye_of.call(peer_id)
	if why == "" and (not eye.is_finite() or eye.distance_to(_center()) > UPGRADE_REACH):
		why = "farm_far"
	if why == "" and not Session.gold_spend(peer_id, FarmRules.upgrade_price(farm, kind, universe)):
		why = "gold"
	if why != "":
		var text := FarmRules.message(why) if why != "farm_far" else TOO_FAR
		tell.call(peer_id, text)
		return text
	farm = FarmRules.upgraded(farm, kind)
	changed.emit(farm)
	_broadcast()
	_rpc_cheer.rpc(_center() + Vector3(0, 2.0, 0))
	var text := tr(RATE_TEXT) % CodeRules.thousands(FarmRules.rate_per_hour(int(farm.rate), universe)) if kind == FarmRules.RATE \
		else tr(CAP_TEXT) % FarmRules.cap_hours(int(farm.cap))
	tell.call(peer_id, text)
	return ""


func _center() -> Vector3:
	if not has_farm():
		return Vector3.INF
	var p: Vector3i = farm.pos
	return Vector3(p.x + 0.5, p.y, p.z + 0.5)


## Host: the owner picks the farm up to put it somewhere else: the FARM item goes back in their bag and the
## farm keeps its levels. "" when done, else the words told.
func host_move(peer_id: int) -> String:
	var why := ""
	var eye: Vector3 = eye_of.call(peer_id)
	if peer_id != multiplayer.get_unique_id():
		why = FarmRules.message("farm_owner")
	elif not has_farm():
		why = FarmRules.message("farm_none")
	elif _waiting or _welcoming:
		why = ONE_MOMENT   # the welcome-back pays first
	elif not eye.is_finite() or eye.distance_to(_center()) > UPGRADE_REACH:
		why = TOO_FAR
	if why != "":
		tell.call(peer_id, why)
		return why
	_rpc_cheer.rpc(_center() + Vector3(0, 2.0, 0))
	farm = FarmRules.packed(farm)
	_server_ms = -1
	_take_back_note(clock.call())
	Session.inventory_of(peer_id).add(ItemIds.FARM, 1)
	changed.emit(farm)
	_broadcast()
	tell.call(peer_id, MOVED_TEXT)
	return ""


# --- Host: leaving and coming back -----------------------------------------------------------------------

## Host, every world save: the farm to save (WorldMeta.farm's form). `owner_feet`: the owner's player (INF
## when not standing in the world, which keeps the last record). Inside the farm: an away record now (and the
## server's clock started, when signed in); outside: none. A record from before this session waits for the
## welcome-back; a farm picked up to move is saved as it is.
func for_save(owner_feet: Vector3) -> Dictionary:
	if not has_farm() or _waiting or _welcoming or not owner_feet.is_finite():
		return farm.duplicate(true)
	var now: int = clock.call()
	if FarmSite.is_inside(farm, owner_feet):
		var same_stay: bool = farm.has("away")
		farm = FarmRules.left_inside(farm, now, same_stay and bool(farm.away.get("server", false)))
		if not same_stay:
			_server_ms = -1
		_start_server_clock()
		_ask_note(now)
	else:
		farm = FarmRules.left_outside(farm)
		_server_ms = -1
		_take_back_note(now)
	return farm.duplicate(true)


## Signed in: the server notes its own time for this stay (at most every SERVER_EVERY_MS); its answer marks
## the record, and the world's meta is saved again so the next start knows.
func _start_server_clock() -> void:
	var s: OnlineService = online.call()
	if s == null or s.status != OnlineService.ONLINE or slot == "":
		return
	var now_ms: int = msec.call()
	if _server_ms >= 0 and now_ms - _server_ms < SERVER_EVERY_MS:
		return
	_server_ms = now_ms
	var p := FarmRules.server_start(farm, universe)
	var r: Dictionary = await s.farm_start(slot, int(p.rate_per_hour), int(p.universe), int(p.cap_hours))
	if r.get("ok", false) and farm.has("away") and not _welcoming and not _waiting:
		farm.away = {"at": int(farm.away.at), "server": true}
		if save_meta.is_valid():
			save_meta.call()
	elif not r.get("ok", false):
		_server_ms = -1


## Host (the owner's game): what the farm made while they were away, paid once. `resumed`: the app came back
## from the background (only after RESUME_MIN_AWAY by the device clock). Returns the gold paid.
func welcome_back(resumed := false) -> int:
	if not Session.is_host():
		return 0
	if _welcoming:
		return 0   # one welcome at a time (a return from the background during the start's)
	if not farm.has("away") or not FarmRules.wants_farm(mode):
		_waiting = false
		return 0
	var now: int = clock.call()
	if resumed and now - int(farm.away.at) < RESUME_MIN_AWAY:
		return 0
	_welcoming = true
	var gold := -1
	var capped := false
	var from_server := false
	if bool(farm.away.get("server", false)):
		var s: OnlineService = online.call()
		var waited := 0.0
		while s != null and s.status == OnlineService.CONNECTING and waited < CONNECT_WAIT and is_inside_tree():
			await get_tree().create_timer(0.25).timeout
			waited += 0.25
		if s != null and s.status == OnlineService.ONLINE and slot != "":
			var r: Dictionary = await s.farm_collect(slot)
			if r.get("ok", false):
				gold = maxi(int(r.get("earned", 0)), 0)
				capped = bool(r.get("capped", false))
				from_server = true
	if gold < 0:
		var w := FarmRules.welcome(farm, clock.call(), universe)
		gold = w.gold
		capped = w.capped
	farm = FarmRules.paid(farm)
	_waiting = false
	_server_ms = -1
	_take_back_note(clock.call())
	if gold > 0:
		if from_server:
			pay_collected.call(gold)
		else:
			pay.call(gold)
	if save_now.is_valid():
		save_now.call()
	_welcoming = false
	welcomed.emit(gold, capped)
	return gold


## The opt-in note: when the barn will be full (FarmNotifyRules: never at night, once a day).
func _ask_note(now: int) -> void:
	if profile == null or not FarmNotifyRules.wanted(profile.settings):
		_take_back_note(now)
		return
	var full := now + FarmRules.cap_hours(int(farm.cap)) * FarmRules.HOUR
	var at := FarmNotifyRules.fire_at(full, tz_bias, FarmNotifyRules.last_rang_day(profile.farm_note_at, now, tz_bias))
	if at != notifier.scheduled_at:
		notifier.schedule(at, FarmNotifyRules.TITLE, FarmNotifyRules.TEXT)
	profile.farm_note_at = at


func _take_back_note(now: int) -> void:
	if profile != null and profile.farm_note_at > now:
		profile.farm_note_at = 0
	if notifier.scheduled_at > 0:
		notifier.cancel()


# --- Every peer: the building ----------------------------------------------------------------------------

## Host: sends the farm (without the away record) to everyone, or to one guest who joined.
func send_to(peer_id: int) -> void:
	if Session.is_host() and multiplayer.get_peers().has(peer_id):
		_rpc_state.rpc_id(peer_id, _public())


func _broadcast() -> void:
	if Session.is_host():
		_rpc_state.rpc(_public())


func _public() -> Dictionary:
	return FarmRules.to_save(FarmRules.left_outside(farm)) if has_farm() else {}


@rpc("authority", "call_local", "reliable")
func _rpc_state(data: Dictionary) -> void:
	var f := FarmRules.left_outside(FarmRules.clean(data))
	if f.is_empty():
		if building:
			building.queue_free()
			building = null
	elif building and building.farm.pos == f.pos and int(building.farm.facing) == int(f.facing):
		building.show_levels(f)
	else:
		if building:
			building.free()
		building = FarmBuilding.new()
		_holder.add_child(building)
		building.setup(f)
		print("FARM at %s" % building.position)
	state_received.emit(f)


## This game's copy of the farm (the panel reads it): {} = none.
func shown() -> Dictionary:
	return building.farm if is_instance_valid(building) else {}


@rpc("authority", "call_local", "reliable")
func _rpc_cheer(at: Vector3) -> void:
	if not at.is_finite() or not is_inside_tree():
		return
	Audio.play(&"coin", at)
	Fx.burst(get_tree().root, at, SPARKLE, 24, 5.0, 0.14, 0.9, 6.0)


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0 or not is_instance_valid(building):
		return
	_check = CHECK_EVERY
	var feet: Vector3 = local_feet.call() if local_feet.is_valid() else Vector3.INF
	var near := feet.is_finite() and feet.distance_to(building.global_position) <= NEAR
	if near != building.working:
		building.set_working(near)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN] and is_inside_tree() \
			and Session.is_host() and has_farm() and farm.has("away") and not _waiting:
		welcome_back(true)


# --- Defaults ---

func _world_reader(origin: Vector3i, size: Vector3i) -> Callable:
	return Session.world.box_reader(origin, size) if Session.world else func(_p: Vector3i) -> int: return BlockIds.AIR


func _world_ready(cell: Vector3i) -> bool:
	return Session.world != null and Session.world.is_area_ready(Vector3(cell))


func _eye_of(peer_id: int) -> Vector3:
	var p := Session._player_for_peer(peer_id)
	return p.eye_position() if p and p.is_spawned() else Vector3.INF


func _bodies() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for group: StringName in [&"players", &"bots"]:
		for n in get_tree().get_nodes_in_group(group):
			if n is Node3D and is_instance_valid(n):
				out.append((n as Node3D).global_position)
	return out


func _pay(gold: int) -> void:
	Session.gold_add(multiplayer.get_unique_id(), gold, "farm")


func _tell(peer_id: int, text: String) -> void:
	if peer_id == multiplayer.get_unique_id() or multiplayer.get_peers().has(peer_id):
		Session.send_feedback(peer_id, text)
