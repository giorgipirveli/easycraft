extends GutTest
## M3 Task 10: the Gold Farm in a world (FarmDirector, host and every peer): the owner places it with the
## FARM item on flat ground (one per world), upgrades it with Survivor gold, leaving inside it records the
## time, and the welcome-back pays once, by the device clock offline and by the server's farm_collect when
## signed in (a fake server), never for a clock that went backwards. Every game shows the building; its
## workers move only near a player.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const FLOOR := 30
const HOUR := 3600

var DIR := "user://test_farm_director_%d/" % OS.get_process_id()
var now := 1_800_000_000
var eye := Vector3(0.5, FLOOR + 1.6, 4.5)
var in_the_way: Array[Vector3] = []
var saves: Array[int] = []
var told: Array[String] = []
var welcomes: Array = []
var collected: Array[int] = []
var service: OnlineService = null
var server: RefCounted
var _gold_before := 0
var _mode_before: StringName
var _online_before: OnlineService


func before_each() -> void:
	_gold_before = Profile.data.survivor_gold
	_mode_before = Game.mode
	_online_before = Session._online_service
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 500
	now = 1_800_000_000
	eye = Vector3(0.5, FLOOR + 1.6, 4.5)
	in_the_way.clear()
	saves.clear()
	told.clear()
	welcomes.clear()
	collected.clear()
	service = null
	server = FakeServer.new()
	DirAccess.make_dir_recursive_absolute(DIR)
	Session.set_inventory(_me(), Inventory.new())


func after_each() -> void:
	Profile.data.survivor_gold = _gold_before
	Game.mode = _mode_before
	Session._online_service = _online_before
	Session.survivor_reset()
	Session.farm_built = Callable()
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _me() -> int:
	return multiplayer.get_unique_id()


## A flat world: ground up to FLOOR - 1, air above.
func _flat(_origin: Vector3i, _size: Vector3i) -> Callable:
	return func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _bumpy(_origin: Vector3i, _size: Vector3i) -> Callable:
	return func(p: Vector3i) -> int: return BlockIds.STONE if p.y < FLOOR + (p.x + p.z) % 3 else BlockIds.AIR


func _director(saved: Dictionary = {}) -> FarmDirector:
	var d := FarmDirector.new()
	d.name = "Farm"
	d.slot = "survivor_1"
	d.block_reader = _flat
	d.area_ready = func(_c: Vector3i) -> bool: return true
	d.eye_of = func(_peer: int) -> Vector3: return eye
	d.bodies = func() -> Array[Vector3]: return in_the_way
	d.clock = func() -> int: return now
	d.online = func() -> OnlineService: return service
	d.pay_collected = func(gold: int) -> void: collected.append(gold)
	d.tell = func(_peer: int, text: String) -> void: told.append(text)
	d.save_now = func() -> void: saves.append(now)
	d.notifier = FarmNotifier.new()
	d.profile = ProfileData.new()
	d.tz_bias = 0
	d.welcomed.connect(func(gold: int, capped: bool) -> void: welcomes.append([gold, capped]))
	add_child_autofree(d)
	d.start(saved)
	return d


## A farm placed by the owner in front of `eye`: its front row's middle at (0, FLOOR, 3), door towards +Z.
func _placed() -> FarmDirector:
	var d := _director()
	Session.inventory_of(_me()).add(ItemIds.FARM, 1)
	assert_eq(d.host_place(_me(), Vector3i(0, FLOOR, 3), 0), "")
	return d


func _inside(d: FarmDirector) -> Vector3:
	var p: Vector3i = d.farm.pos
	return Vector3(p.x + 2.5, FLOOR, p.z + 0.5)   # in the field


func _outside(d: FarmDirector) -> Vector3:
	var p: Vector3i = d.farm.pos
	return Vector3(p.x + 0.5, FLOOR, p.z + 12.5)


func _signed_in() -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = "dev-farm"
	s.profile = ProfileData.new()
	s.profile.username = "Hopper"
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + "prefs.json"
	s.wallet_path = DIR + "wallet.json"
	s.clock = func() -> int: return now
	s.prefs.safe_card_seen = now
	add_child_autofree(s)
	server.make_account("dev-farm", "Hopper")
	assert_eq(await s.sign_in(), "")
	return s


# --- Placing ---

func test_the_owner_places_the_farm_with_a_farm_item() -> void:
	var changed: Array = []
	var d := _director()
	d.changed.connect(func(f: Dictionary) -> void: changed.append(f))
	Session.inventory_of(_me()).add(ItemIds.FARM, 1)
	assert_eq(d.host_place(_me(), Vector3i(0, FLOOR, 3), 0), "")
	assert_true(d.has_farm())
	assert_eq(d.farm.pos, Vector3i(0, FLOOR, 0), "the tapped cell is the middle of the front row")
	assert_eq(int(d.farm.facing), 0)
	assert_eq(Session.inventory_of(_me()).count(ItemIds.FARM), 0, "the item is used up")
	assert_eq(changed.size(), 1)
	assert_eq(told.back(), FarmDirector.BUILT_TEXT)
	assert_not_null(d.building, "the host's game shows it too")


func test_one_farm_per_world() -> void:
	var d := _placed()
	Session.inventory_of(_me()).add(ItemIds.FARM, 1)
	assert_eq(d.host_place(_me(), Vector3i(20, FLOOR, 3), 0), FarmRules.message("farm_one"))
	assert_eq(d.farm.pos, Vector3i(0, FLOOR, 0), "the first one stays")
	assert_eq(Session.farm_buy_refusal(_me(), ItemIds.FARM), "farm_one", "Tilly sells no second one")
	assert_eq(Session.farm_buy_refusal(_me(), BlockIds.LANTERN), "", "the rest of her shop is as before")


func test_only_the_owner_and_only_in_survivor() -> void:
	var d := _director()
	assert_eq(Session.farm_buy_refusal(4242, ItemIds.FARM), "farm_owner", "a guest can't buy one")
	Session.set_inventory(4242, Inventory.new())
	Session.inventory_of(4242).add(ItemIds.FARM, 1)
	assert_eq(d.host_place(4242, Vector3i(0, FLOOR, 3), 0), FarmRules.message("farm_owner"))
	d.mode = ModeRules.SANDBOX
	Session.inventory_of(_me()).add(ItemIds.FARM, 1)
	assert_eq(d.host_place(_me(), Vector3i(0, FLOOR, 3), 0), FarmRules.message("survivor_only"))
	assert_false(d.has_farm())


func test_placing_needs_the_item_reach_flat_ground_and_room() -> void:
	var d := _director()
	assert_eq(d.host_place(_me(), Vector3i(0, FLOOR, 3), 0), FarmDirector.NO_FARM_ITEM)
	Session.inventory_of(_me()).add(ItemIds.FARM, 1)
	eye = Vector3(0.5, FLOOR + 1.6, 30)
	assert_eq(d.host_place(_me(), Vector3i(0, FLOOR, 3), 0), FarmDirector.TOO_FAR)
	eye = Vector3(0.5, FLOOR + 1.6, 4.5)
	d.block_reader = _bumpy
	assert_ne(d.host_place(_me(), Vector3i(0, FLOOR, 3), 0), "", "bumpy ground")
	d.block_reader = _flat
	in_the_way.append(Vector3(-1.5, FLOOR, -0.5))   # a bot friend where the barn's walls go
	assert_eq(d.host_place(_me(), Vector3i(0, FLOOR, 3), 0), FarmDirector.IN_THE_WAY)
	assert_false(d.has_farm())
	assert_eq(Session.inventory_of(_me()).count(ItemIds.FARM), 1, "nothing used up")
	in_the_way.clear()
	assert_eq(d.host_place(_me(), Vector3i(0, FLOOR, 3), 0), "")


# --- Upgrades ---

func test_upgrades_cost_fixed_gold_and_bring_workers() -> void:
	var d := _placed()
	assert_eq(d.building.workers.size(), 1)
	Profile.data.survivor_gold = 250
	assert_eq(d.host_upgrade(_me(), FarmRules.RATE), "")
	assert_eq(Profile.data.survivor_gold, 50)
	assert_eq(int(d.farm.rate), 1)
	assert_eq(d.building.workers.size(), 2, "every game sees one more worker")
	assert_eq(told.back(), FarmDirector.RATE_TEXT % "30")
	assert_eq(d.host_upgrade(_me(), FarmRules.RATE), FarmRules.message("gold"), "400 for the next")
	assert_eq(Profile.data.survivor_gold, 50, "nothing taken")
	assert_eq(int(d.farm.rate), 1)
	Profile.data.survivor_gold = 150
	assert_eq(d.host_upgrade(_me(), FarmRules.CAP), "")
	assert_eq(FarmRules.cap_hours(int(d.farm.cap)), 16)
	assert_eq(Profile.data.survivor_gold, 0)
	assert_eq(d.host_upgrade(4242, FarmRules.CAP), FarmRules.message("farm_owner"))


func test_upgrade_prices_follow_the_universe() -> void:
	var d := _placed()
	d.universe = 3
	Profile.data.survivor_gold = 799
	assert_eq(d.host_upgrade(_me(), FarmRules.RATE), FarmRules.message("gold"), "200 × 4 in universe 3")
	Profile.data.survivor_gold = 800
	assert_eq(d.host_upgrade(_me(), FarmRules.RATE), "")
	assert_eq(Profile.data.survivor_gold, 0)
	assert_eq(told.back(), FarmDirector.RATE_TEXT % "120", "30 an hour × 4")


# --- Leaving and coming back (device clock) ---

func test_leaving_inside_records_the_time_and_outside_none() -> void:
	var d := _placed()
	var saved := d.for_save(_inside(d))
	assert_eq(saved.away, {"at": now, "server": false})
	now += 60
	saved = d.for_save(_outside(d))
	assert_false(saved.has("away"), "walked out: nothing owed")
	saved = d.for_save(Vector3.INF)
	assert_false(saved.has("away"), "not standing in the world: the last record is kept")


func test_the_welcome_back_pays_once_by_the_device_clock() -> void:
	var d := _placed()
	var saved := d.for_save(_inside(d))
	var back := _director(saved)   # the world starts again the next day
	now += 3 * HOUR
	assert_eq(await back.welcome_back(), 60)
	assert_eq(Profile.data.survivor_gold, 560, "through the host's gold path")
	assert_eq(welcomes, [[60, false]])
	assert_eq(saves.size(), 1, "the world is saved at once")
	assert_false(back.farm.has("away"), "the record is gone")
	assert_eq(await back.welcome_back(), 0, "paid once")
	assert_eq(Profile.data.survivor_gold, 560)
	assert_false(back.for_save(_outside(back)).has("away"))


func test_the_barn_holds_12_hours() -> void:
	var d := _placed()
	var back := _director(d.for_save(_inside(d)))
	now += 30 * HOUR
	assert_eq(await back.welcome_back(), 240)
	assert_eq(welcomes, [[240, true]])


func test_gold_is_scaled_by_the_universe() -> void:
	var d := _placed()
	var back := _director(d.for_save(_inside(d)))
	back.universe = 2
	now += HOUR
	assert_eq(await back.welcome_back(), 40)


func test_a_clock_that_went_backwards_pays_nothing_and_takes_nothing() -> void:
	var d := _placed()
	var back := _director(d.for_save(_inside(d)))
	now -= 5 * HOUR
	assert_eq(await back.welcome_back(), 0)
	assert_eq(Profile.data.survivor_gold, 500)
	assert_eq(welcomes, [[0, false]])
	assert_false(back.farm.has("away"), "the odd record is gone too")


func test_leaving_outside_the_farm_pays_nothing() -> void:
	var d := _placed()
	var back := _director(d.for_save(_outside(d)))
	now += 5 * HOUR
	assert_eq(await back.welcome_back(), 0)
	assert_eq(Profile.data.survivor_gold, 500)


func test_a_record_from_before_waits_for_the_welcome_back() -> void:
	var d := _placed()
	var saved := d.for_save(_inside(d))
	var back := _director(saved)
	now += 2 * HOUR
	assert_eq(back.for_save(_inside(back)).away.at, saved.away.at, "a save before the welcome keeps the old time")
	assert_eq(back.for_save(_outside(back)).away.at, saved.away.at, "... even walking out meanwhile")
	assert_eq(await back.welcome_back(), 40)
	assert_eq(back.for_save(_inside(back)).away.at, now, "then a new stay begins")


func test_coming_back_from_the_background() -> void:
	var d := _placed()
	d.welcome_back()   # the start's welcome (nothing was owed)
	d.for_save(_inside(d))   # the app went to the background inside the farm
	now += 60
	assert_eq(await d.welcome_back(true), 0, "a minute away: not a welcome-back yet")
	assert_true(d.farm.has("away"), "still owed later")
	now += 2 * HOUR
	assert_eq(await d.welcome_back(true), 40)


# --- Signed in: the server's clock ---

func test_signed_in_the_server_clock_pays() -> void:
	service = await _signed_in()
	var uid := service.backend.user_id()
	var d := _placed()
	d.for_save(_inside(d))
	await wait_process_frames(3)
	assert_true(server.farms[uid].has("survivor_1"), "farm_collect start: the server noted its own time")
	assert_true(d.farm.away.server, "the record knows the server was told")
	var back := _director(d.for_save(_inside(d)))
	server.clock_ms += 2 * HOUR * 1000
	now += 9 * HOUR   # the phone's clock says more: the server's clock wins
	var wallet_before := int(server.wallets.get(uid, 0))
	assert_eq(await back.welcome_back(), 40)
	assert_eq(collected, [40], "paid as gold the server already has")
	assert_eq(int(server.wallets[uid]), wallet_before + 40)
	assert_false(server.farms[uid].has("survivor_1"), "collected: the server's record is gone")
	assert_eq(Profile.data.survivor_gold, 500, "the stub took it (Session.farm_pay_collected is tested below)")


func test_the_server_not_knowing_the_stay_falls_back_to_the_device_clock() -> void:
	service = await _signed_in()
	var d := _placed()
	var saved := FarmRules.left_inside(d.farm, now, true)   # the record says the server was told, it wasn't
	var back := _director(saved)
	now += HOUR
	assert_eq(await back.welcome_back(), 20)
	assert_eq(collected, [] as Array[int])
	assert_eq(Profile.data.survivor_gold, 520)


func test_offline_the_device_clock_pays_even_if_the_server_was_started() -> void:
	var d := _placed()
	var back := _director(FarmRules.left_inside(d.farm, now, true))
	now += HOUR
	assert_eq(await back.welcome_back(), 20)
	assert_eq(Profile.data.survivor_gold, 520)


func test_gold_the_server_paid_reaches_the_phone_once() -> void:
	service = await _signed_in()
	Session._online_service = service
	var uid := service.backend.user_id()
	var marker := WalletSync.marker_of(service.wallet_path, uid)
	assert_gte(marker, 0, "signing in made the marker")
	Session.farm_pay_collected(40)
	assert_eq(Profile.data.survivor_gold, 540)
	assert_eq(WalletSync.marker_of(service.wallet_path, uid), marker + 40,
		"the wallet sync won't send it again (the server has it already)")
	assert_eq(service.pending_reports(), 0, "nothing reported")
	Game.mode = ModeRules.SANDBOX
	Session.farm_pay_collected(40)
	assert_eq(Profile.data.survivor_gold, 540, "Sandbox gold is ∞: nothing moves")


# --- The note ---

func test_the_note_is_asked_only_when_turned_on_and_taken_back_on_return() -> void:
	var d := _placed()
	d.for_save(_inside(d))
	assert_eq(d.notifier.scheduled_at, 0, "off by default")
	d.profile.settings.farm_note = true
	now = 1_800_057_600 + 9 * HOUR   # 09:00 UTC
	d.for_save(_inside(d))
	assert_eq(d.notifier.scheduled_at, 1_800_057_600 + 86400 + 8 * HOUR, "full at 21:00: it waits for 08:00")
	assert_eq(d.profile.farm_note_at, d.notifier.scheduled_at)
	var back := _director(d.for_save(_inside(d)))
	back.notifier = d.notifier
	back.profile = d.profile
	now += HOUR
	await back.welcome_back()
	assert_eq(back.notifier.scheduled_at, 0, "back before it rang: taken back")
	assert_eq(back.profile.farm_note_at, 0)


# --- Every peer ---

func test_every_game_shows_the_building_from_the_hosts_state() -> void:
	var d := _placed()
	var got: Array = []
	d.state_received.connect(func(f: Dictionary) -> void: got.append(f))
	d.for_save(_inside(d))
	d.send_to(_me())   # not a guest: nothing is sent
	d._rpc_state(FarmRules.to_save(FarmRules.upgraded(d.farm, FarmRules.RATE)))
	assert_eq(d.building.workers.size(), 2)
	assert_false(got.back().has("away"), "guests never hear when the owner left")
	d._rpc_state({})
	await wait_process_frames(1)
	assert_false(is_instance_valid(d.building), "no farm, no building")


func test_workers_move_only_near_a_player() -> void:
	var d := _placed()
	var feet: Array[Vector3] = [Vector3(500, FLOOR, 500)]
	d.local_feet = func() -> Vector3: return feet[0]
	await wait_process_frames(2)
	await wait_seconds(FarmDirector.CHECK_EVERY + 0.1)
	assert_false(d.building.working, "far away: they rest")
	assert_false(d.building.workers[0].is_processing())
	feet[0] = _inside(d)
	await wait_seconds(FarmDirector.CHECK_EVERY + 0.1)
	assert_true(d.building.working)
	assert_true(d.building.workers[0].is_processing())
	var w: FarmWorker = d.building.workers[0]
	var start := [w.position, w._arm_pivot.rotation.x]
	await wait_seconds(0.4)
	assert_ne([w.position, w._arm_pivot.rotation.x], start, "a worker walks or hoes (its place or its arm moves)")


# --- Moving the farm ---

func test_the_owner_picks_the_farm_up_and_places_it_again_with_its_levels() -> void:
	var d := _placed()
	Profile.data.survivor_gold = 500
	d.host_upgrade(_me(), FarmRules.RATE)
	var feet := _inside(d)
	d.for_save(feet)   # the owner stands in it
	assert_eq(d.host_move(_me()), "")
	assert_false(d.has_farm(), "no farm stands")
	assert_eq(Session.inventory_of(_me()).count(ItemIds.FARM), 1, "the FARM item is back in the bag")
	assert_eq(told.back(), FarmDirector.MOVED_TEXT)
	await wait_process_frames(1)
	assert_false(is_instance_valid(d.building), "the barn is gone on every game")
	assert_eq(Session.farm_buy_refusal(_me(), ItemIds.FARM), "farm_one", "Tilly sells no second one meanwhile")
	var saved := d.for_save(feet)
	assert_eq(saved, {"packed": true, "rate": 1, "cap": 0}, "saved packed; no away record")
	assert_eq(await d.welcome_back(), 0)
	assert_eq(d.host_place(_me(), Vector3i(0, FLOOR, 3), 1), "")
	assert_eq(int(d.farm.rate), 1, "its level kept")
	assert_eq(int(d.farm.facing), 1)
	assert_eq(d.building.workers.size(), 2)


func test_only_the_owner_moves_it_and_from_near() -> void:
	var d := _placed()
	Session.set_inventory(4242, Inventory.new())
	assert_eq(d.host_move(4242), FarmRules.message("farm_owner"))
	eye = Vector3(0.5, FLOOR + 1.6, 60)
	assert_eq(d.host_move(_me()), FarmDirector.TOO_FAR)
	assert_true(d.has_farm())
	assert_eq(Session.inventory_of(_me()).count(ItemIds.FARM), 0)
