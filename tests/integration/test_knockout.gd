extends GutTest
## Knock-out, respawn and the pickup bag on a real Player (M2 Task 2, spec §12.3, §12.15). Solo play:
## this game is the host, and every request goes through Session like a LAN guest's would.

const BED := Vector3i(4, 30, -2)
const FELL_AT := Vector3(3.2, 17.9, -4.7)
const BAG_AT := Vector3(3.5, 10.0, -4.5)      # FELL_AT dropped onto the test floor

var world: WorldService
var player: Player
var director: KnockoutDirector
var _mode_before: StringName
var _gold_before := 0


## The test world's blocks: a floor (solid for y <= 9).
static func _floor(cell: Vector3i) -> int:
	return BlockIds.STONE if cell.y <= 9 else BlockIds.AIR


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 77
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)
	player.viewer.free()   # no streaming: nothing here needs loaded terrain
	player.global_position = FELL_AT
	director = KnockoutDirector.new()
	director.name = "Knockout"
	director.block_at = _floor
	director.name_of = func(peer_id: int) -> String: return "Mia" if peer_id == player.peer_id else "Leo"
	add_child_autofree(director)
	director.setup_local(player, null)
	Session.set_inventory(player.peer_id, _kit())


func after_each() -> void:
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Session.survivor_reset()


func _kit() -> Inventory:
	var inv := Inventory.new()
	inv.add(ItemIds.SWORD, 1)
	inv.add(BlockIds.PLANKS, 16)
	inv.add(ItemIds.PICKAXE, 1)
	inv.add(BlockIds.DIRT, 8)
	inv.add(ItemIds.BOW, 1)
	return inv


func _inv() -> Inventory:
	return Session.inventory_of(player.peer_id)


func _knock_out() -> void:
	Session.hurt_player(player.peer_id, Health.MAX_HP + 5, Vector3(9, 9, 9))


func test_a_survivor_knock_out_drops_the_blocks_into_a_bag_and_keeps_the_rest() -> void:
	_knock_out()
	assert_eq(player.health.hp, 0)
	assert_true(player.knocked_out, "lying down")
	assert_eq(director.bags().size(), 1)
	var bag: PickupBag = director.bags()[0]
	assert_eq(bag.items, [[BlockIds.PLANKS, 16], [BlockIds.DIRT, 8]], "every carried block")
	assert_eq(bag.owner_name, "Mia")
	assert_eq(bag.global_position, BAG_AT, "on the ground under where they fell")
	assert_eq(_inv().ids(), [ItemIds.SWORD, ItemIds.PICKAXE, ItemIds.BOW] as Array[int], "tools and weapons stay")
	assert_eq(Profile.data.survivor_gold, 77, "gold stays")


func test_a_knocked_out_player_takes_no_more_damage_until_revived() -> void:
	_knock_out()
	watch_signals(Session)
	Session.hurt_player(player.peer_id, 3, Vector3.ZERO)
	assert_eq(player.health.hp, 0)
	assert_signal_not_emitted(Session, "player_hurt", "no second knock-out, no hurt flash")
	assert_eq(director.bags().size(), 1, "no second bag")


func test_survivors_get_up_at_their_bed_with_full_hearts_and_protection() -> void:
	player.set_home(true, BED)
	_knock_out()
	director.advance(KnockoutRules.KO_TIME - 0.1)
	assert_eq(player.health.hp, 0, "down for a moment first")
	assert_true(player.knocked_out)
	director.advance(0.2)
	assert_eq(player.health.hp, Health.MAX_HP)
	assert_true(player.health.is_protected())
	assert_false(player.knocked_out, "standing again")
	assert_eq(player._spawn_target, BedRules.home_position(BED), "on the way to the bed")
	Session.hurt_player(player.peer_id, 5, Vector3.ZERO)
	assert_eq(player.health.hp, Health.MAX_HP, "protected")


func test_without_a_bed_survivors_get_up_at_the_world_spawn() -> void:
	_knock_out()
	director.advance(KnockoutRules.KO_TIME + 0.1)
	var c := world.spawn_column()
	assert_eq(Vector2(player._spawn_target.x, player._spawn_target.z), Vector2(c.x + 0.5, c.y + 0.5))
	assert_true(is_nan(player._spawn_target.y), "on the surface there")


func test_protection_holds_until_they_arrive_then_lasts_three_seconds() -> void:
	_knock_out()
	director.advance(KnockoutRules.KO_TIME + 0.1)
	player.health.tick(Health.PROTECTION - 0.1)
	director.advance(0.1)
	player.health.tick(Health.PROTECTION - 0.1)
	assert_true(player.health.is_protected(), "still on the way home (a far bed loads slowly)")
	player.spawned.emit()   # arrived at home
	player.health.tick(Health.PROTECTION - 0.1)
	director.advance(0.1)
	assert_true(player.health.is_protected(), "three seconds from the arrival")
	player.health.tick(0.2)
	assert_false(player.health.is_protected())
	director.advance(0.1)
	assert_false(player.health.is_protected(), "the host stopped holding it")


func test_a_player_who_never_says_they_arrived_is_not_protected_forever() -> void:
	_knock_out()
	director.advance(KnockoutRules.KO_TIME + 0.1)
	director.advance(KnockoutDirector.ARRIVAL_TIMEOUT + 0.1)
	player.health.tick(Health.PROTECTION + 0.1)
	director.advance(0.1)
	assert_false(player.health.is_protected())


func test_taking_the_bag_restores_exactly_and_only_once() -> void:
	var before := _kit().to_save()
	_knock_out()
	director.advance(KnockoutRules.KO_TIME + 0.1)
	var bag: PickupBag = director.bags()[0]
	player.global_position = BAG_AT + Vector3(0, 0, 3)
	Session.request_take_bag(bag.name)
	assert_eq(_inv().to_save(), [[ItemIds.SWORD, 1], [ItemIds.PICKAXE, 1], [ItemIds.BOW, 1],
		[BlockIds.PLANKS, 16], [BlockIds.DIRT, 8]])
	for e: Array in before:
		assert_eq(_inv().count(e[0]), e[1], "id %d" % e[0])
	assert_eq(director.bags().size(), 0, "the bag is gone")
	Session.request_take_bag(bag.name)
	assert_eq(_inv().count(BlockIds.PLANKS), 16, "never twice")
	assert_eq(_inv().count(BlockIds.DIRT), 8)


func test_a_bag_out_of_reach_stays_where_it_is() -> void:
	_knock_out()
	director.advance(KnockoutRules.KO_TIME + 0.1)
	var bag: PickupBag = director.bags()[0]
	player.global_position = BAG_AT + Vector3(0, 0, KnockoutRules.REACH + 2.0)
	Session.request_take_bag(bag.name)
	assert_eq(_inv().count(BlockIds.PLANKS), 0)
	assert_eq(director.bags().size(), 1)


func test_someone_elses_bag_waits_five_minutes() -> void:
	var bag := director.drop_bag("Leo", BAG_AT + Vector3(0, 3, 0), [[BlockIds.SAND, 5]])
	player.global_position = BAG_AT
	watch_signals(Session)
	Session.request_take_bag(bag.name)
	assert_eq(_inv().count(BlockIds.SAND), 0, "Leo's for now")
	assert_signal_emitted_with_parameters(Session, "magic_feedback", [KnockoutRules.refusal("Leo", "Mia", 0.0)])
	bag.set_age(KnockoutRules.OWNER_ONLY_TIME)
	Session.request_take_bag(bag.name)
	assert_eq(_inv().count(BlockIds.SAND), 5, "then anyone's")


func test_a_full_pocket_leaves_the_rest_in_the_bag() -> void:
	_knock_out()
	director.advance(KnockoutRules.KO_TIME + 0.1)
	_inv().add(BlockIds.PLANKS, Inventory.MAX_COUNT - 10)
	var bag: PickupBag = director.bags()[0]
	player.global_position = BAG_AT
	Session.request_take_bag(bag.name)
	assert_eq(_inv().count(BlockIds.PLANKS), Inventory.MAX_COUNT)
	assert_eq(_inv().count(BlockIds.DIRT), 8)
	assert_eq(director.bags().size(), 1, "the bag keeps what did not fit")
	assert_eq(bag.items, [[BlockIds.PLANKS, 6]])


func test_a_second_knock_out_at_the_same_spot_fills_the_same_bag() -> void:
	_knock_out()
	director.advance(KnockoutRules.KO_TIME + 0.1)
	player.spawned.emit()
	player.health.tick(Health.PROTECTION + 0.1)
	_inv().add(BlockIds.DIRT, 4)
	_inv().add(BlockIds.STONE, 2)
	player.global_position = FELL_AT + Vector3(0.5, 0, 0.5)
	_knock_out()
	assert_eq(director.bags().size(), 1)
	assert_eq(director.bags()[0].items, [[BlockIds.PLANKS, 16], [BlockIds.DIRT, 12], [BlockIds.STONE, 2]])


func test_bags_are_saved_and_restored() -> void:
	_knock_out()
	director.drop_bag("Leo", Vector3(20.5, 30.0, 20.5), [[BlockIds.CRYSTAL, 3]]).set_age(120.0)
	var meta := WorldMeta.new_random()
	meta.bags = director.to_save()
	var back := WorldMeta.from_json(meta.to_json())
	var other := KnockoutDirector.new()
	other.name = "Knockout2"
	add_child_autofree(other)
	other.restore(back.bags)
	assert_eq(other.bags().size(), 2)
	var mine: PickupBag = other.bags()[0]
	assert_eq(mine.owner_name, "Mia")
	assert_eq(mine.global_position, BAG_AT)
	assert_eq(mine.items, [[BlockIds.PLANKS, 16], [BlockIds.DIRT, 8]])
	var leos: PickupBag = other.bags()[1]
	assert_eq(leos.owner_name, "Leo")
	assert_almost_eq(leos.age(), 120.0, 1.0, "the five minutes keep counting")


func test_sandbox_pops_back_up_on_the_spot_keeping_everything() -> void:
	Game.mode = ModeRules.SANDBOX
	player._spawned = true
	player.global_position = Vector3(40.5, 12.0, 40.5)
	_knock_out()
	assert_true(player.knocked_out)
	assert_eq(director.bags().size(), 0, "no bag in Sandbox")
	assert_eq(_inv().to_save(), _kit().to_save(), "nothing lost")
	director.advance(KnockoutRules.KO_TIME + 0.1)
	assert_eq(player.health.hp, Health.MAX_HP)
	assert_true(player.health.is_protected())
	assert_false(player.knocked_out)
	assert_true(player.is_spawned(), "no trip home")
	assert_almost_eq(player.global_position.x, 40.5, 0.01)
	assert_almost_eq(player.global_position.z, 40.5, 0.01)


func test_only_the_hosts_own_hearts_decide_a_knock_out() -> void:
	Session.player_hurt.emit(player.peer_id, 0, Vector3.ZERO)   # a stale or forged "0 HP"
	assert_false(player.knocked_out)
	assert_eq(director.bags().size(), 0)
	assert_eq(_inv().count(BlockIds.PLANKS), 16)


func test_a_sleeper_who_is_knocked_out_wakes_up_first() -> void:
	player.set_sleeping(true, BED)
	watch_signals(Session)
	_knock_out()
	assert_signal_emitted_with_parameters(Session, "bed_wake_requested", [player.peer_id])


## The lead's Cozy / Normal / Brave: a Cozy Survivor world drops no bag; getting up is the same.
func test_cozy_worlds_drop_no_bag_but_still_get_up_at_home() -> void:
	director.difficulty = KnockoutRules.COZY
	player.set_home(true, BED)
	_knock_out()
	assert_eq(director.bags().size(), 0)
	assert_eq(_inv().to_save(), _kit().to_save(), "nothing dropped")
	director.advance(KnockoutRules.KO_TIME + 0.1)
	assert_eq(player.health.hp, Health.MAX_HP)
	assert_eq(player._spawn_target, BedRules.home_position(BED))


func test_brave_worlds_drop_the_bag_like_normal() -> void:
	director.difficulty = KnockoutRules.BRAVE
	_knock_out()
	assert_eq(director.bags().size(), 1)


func test_the_knocked_out_player_sees_the_message_and_one_picture_tip() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	director.setup_local(player, hud)
	_knock_out()
	assert_true(hud.knockout_overlay.is_down())
	assert_eq(hud.knockout_overlay.message(), KnockoutDirector.SURVIVOR_MESSAGE)
	assert_eq(hud.knockout_overlay.tip_text(), KnockoutRules.TIPS[0].text, "no bed yet: the bed tip")
	director.advance(KnockoutRules.KO_TIME + 0.1)
	assert_true(hud.knockout_overlay.is_down(), "dark until they are home")
	player.spawned.emit()
	assert_false(hud.knockout_overlay.is_down(), "fades once home")
	player.set_home(true, BED)
	player.health.tick(Health.PROTECTION + 0.1)
	_knock_out()
	assert_eq(hud.knockout_overlay.tip_text(), KnockoutRules.tip(1, true, true).text, "the next tip")


## A bag floating in front of the camera, high in the sky (no terrain in the way), ready for rays.
func _bag_in_view(items: Array) -> PickupBag:
	player.get_node("CollisionViewer").free()
	player.global_position = Vector3(0.5, 150.0, 0.5)
	player.rig.snap_to_target()
	var cam := player.camera()
	var spot := player.eye_position() + (-cam.global_basis.z * Vector3(1, 0, 1)).normalized() * 4.0 - Vector3(0, 0.3, 0)
	return director.spawn_bag("Mia", spot, items, 0.0)


func test_a_tap_on_a_bag_takes_it() -> void:
	var bag := _bag_in_view([[BlockIds.GLASS, 3]])
	await wait_physics_frames(3)
	var interactor: BlockInteractor = player.get_node("BlockInteractor")
	interactor.set_slot_block(0, ItemIds.SWORD)   # even with a weapon in the hand
	watch_signals(Session)
	var at := player.camera().unproject_position(bag.center())
	assert_true(interactor.place_at_screen(at), "the tap was used")
	assert_signal_emitted_with_parameters(Session, "bag_take_requested", [player.peer_id, bag.name])
	assert_eq(_inv().count(BlockIds.GLASS), 3, "and the host handed it over")


func test_holding_on_a_bag_takes_it_too() -> void:
	var bag := _bag_in_view([[BlockIds.BRICK, 2]])
	await wait_physics_frames(3)
	var interactor: BlockInteractor = player.get_node("BlockInteractor")
	assert_true(interactor.break_at_screen(player.camera().unproject_position(bag.center())))
	assert_eq(_inv().count(BlockIds.BRICK), 2)


func test_a_tap_beside_a_bag_is_an_ordinary_tap() -> void:
	var bag := _bag_in_view([[BlockIds.BRICK, 2]])
	await wait_physics_frames(3)
	var interactor: BlockInteractor = player.get_node("BlockInteractor")
	watch_signals(Session)
	interactor.place_at_screen(player.camera().unproject_position(bag.center()) + Vector2(200, 0))
	assert_signal_not_emitted(Session, "bag_take_requested")


## Found by the LAN run: a knocked-out guest standing on its bag took it back during the fade.
func test_a_knocked_out_player_cannot_take_a_bag_until_up_again() -> void:
	_knock_out()
	var bag: PickupBag = director.bags()[0]
	Session.request_take_bag(bag.name)
	assert_eq(_inv().count(BlockIds.PLANKS), 0, "not while down")
	assert_eq(director.bags().size(), 1)
	director.advance(KnockoutRules.KO_TIME + 0.1)
	player.global_position = BAG_AT
	Session.request_take_bag(bag.name)
	assert_eq(_inv().count(BlockIds.PLANKS), 16, "once up again")
