extends GutTest
## Crafting through the host (spec §12.19): a request names a recipe; the host checks a Survivor world, the
## recipe, the stations near the requester's body as the host sees it (one bulk copy of the blocks around
## it), the ingredients and the fuel, then takes and gives and answers that player. A guest's craft is
## checked the same way against the guest's own body and inventory.

const GUEST := 7


class BoxWorld:
	extends WorldService

	var blocks := {}
	var copies := 0

	func get_block(pos: Vector3i) -> int:
		return blocks.get(pos, BlockIds.AIR)

	func copy_box(origin: Vector3i, size: Vector3i) -> VoxelBuffer:
		copies += 1
		var buf := VoxelBuffer.new()
		buf.create(size.x, size.y, size.z)
		for p: Vector3i in blocks:
			var l: Vector3i = p - origin
			if l.x >= 0 and l.y >= 0 and l.z >= 0 and l.x < size.x and l.y < size.y and l.z < size.z:
				buf.set_voxel(blocks[p], l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE)
		return buf


var _world: BoxWorld
var _world_before: WorldService
var _mode_before: StringName
var _me: Player
var _guest: Player
var _done: Array = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_world_before = Session.world
	_world = BoxWorld.new()
	autofree(_world)
	Session.world = _world
	_done.clear()
	Session.craft_done.connect(_on_done)
	_me = _body(multiplayer.get_unique_id(), Vector3(0.5, 20, 0.5))
	_guest = _body(GUEST, Vector3(40.5, 20, 0.5))
	Session.set_inventory(_me.peer_id, Inventory.new())
	Session.set_inventory(GUEST, Inventory.new())


func after_each() -> void:
	Session.craft_done.disconnect(_on_done)
	Session.world = _world_before
	Game.mode = _mode_before
	Session.survivor_reset()


func _body(peer: int, at: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = _world
	add_child_autofree(p)
	p.viewer.free()
	p.set_physics_process(false)
	p.global_position = at
	return p


func _on_done(ok: bool, text: String, id: int, count: int) -> void:
	_done.append([ok, text, id, count])


func _mine() -> Inventory:
	return Session.inventory_of(_me.peer_id)


func test_planks_by_hand_anywhere() -> void:
	_mine().add(BlockIds.LOG, 2)
	Session.request_craft(&"planks")
	assert_eq(_mine().count(BlockIds.LOG), 1)
	assert_eq(_mine().count(BlockIds.PLANKS), 4)
	assert_eq(_done, [[true, "You made 4 Planks!", BlockIds.PLANKS, 4]])


## Owner #45a: what the host made counts for the crafter ("Craft 10 things", "Melt sand into glass", quests).
func test_a_craft_counts_for_the_crafters_progress() -> void:
	var data := ProgressData.new()
	Progress.begin(data)
	_mine().add(BlockIds.LOG, 2)
	Session.request_craft(&"planks")
	Session.request_craft(&"sword")   # no table near: refused
	Progress.end()
	assert_eq(data.count(&"item_crafted/planks"), 1)
	assert_eq(data.count(&"item_crafted"), 1, "a refused craft counts nothing")


func test_a_sword_needs_a_crafting_table_near_the_player() -> void:
	_mine().add(BlockIds.PLANKS, 2)
	_mine().add(ItemIds.STICK, 1)
	Session.request_craft(&"sword")
	assert_eq(_done.back(), [false, "Stand next to a Workbench!", ItemIds.SWORD, 0])
	assert_eq(_mine().count(BlockIds.PLANKS), 2, "nothing taken")
	_world.blocks[Vector3i(9, 20, 0)] = BlockIds.CRAFTING_TABLE   # too far
	Session.request_craft(&"sword")
	assert_false(_done.back()[0])
	_world.blocks[Vector3i(3, 20, 0)] = BlockIds.CRAFTING_TABLE
	Session.request_craft(&"sword")
	assert_eq(_done.back(), [true, "You made a Sword!", ItemIds.SWORD, 1])
	assert_eq(_mine().count(ItemIds.SWORD), 1)
	assert_eq(_mine().count(BlockIds.PLANKS), 0)
	assert_eq(_mine().count(ItemIds.STICK), 0)


func test_glass_at_a_furnace_burns_coal() -> void:
	_world.blocks[Vector3i(-2, 21, 1)] = BlockIds.FURNACE
	_mine().add(BlockIds.SAND, 4)
	_mine().add(BlockIds.COAL, 1)
	Session.request_craft(&"glass")
	assert_true(_done.back()[0], str(_done))
	assert_eq(_mine().count(BlockIds.GLASS), 4)
	assert_eq(_mine().count(BlockIds.COAL), 0)
	assert_eq(_mine().count(BlockIds.SAND), 0)


func test_the_host_looks_around_with_one_bulk_copy() -> void:
	_mine().add(BlockIds.LOG, 1)
	_world.copies = 0
	Session.request_craft(&"planks")
	assert_lte(_world.copies, 1)


## A guest's request uses the guest's body on the host and the guest's own inventory.
func test_a_guests_craft_is_checked_by_the_host() -> void:
	var theirs := Session.inventory_of(GUEST)
	theirs.add(BlockIds.STONE, 8)
	_world.blocks[Vector3i(2, 20, 0)] = BlockIds.CRAFTING_TABLE   # next to the host's player, far from the guest
	var r := Session.host_craft(GUEST, &"furnace")
	assert_false(r.ok, "the guest stands 40 blocks away from the table")
	assert_eq(r.error, "table")
	assert_eq(theirs.count(BlockIds.STONE), 8)
	_guest.global_position = Vector3(3.5, 20, 2.5)
	r = Session.host_craft(GUEST, &"furnace")
	assert_true(r.ok)
	assert_eq(theirs.count(BlockIds.FURNACE), 1)
	assert_eq(theirs.count(BlockIds.STONE), 0)
	assert_eq(_mine().count(BlockIds.FURNACE), 0, "the host's own bag is not touched")


func test_a_request_from_nobody_or_for_no_recipe_changes_nothing() -> void:
	assert_false(Session.host_craft(99, &"planks").ok, "no such player")
	_mine().add(BlockIds.LOG, 1)
	Session.request_craft(&"gold_from_nothing")
	assert_eq(_done.back()[0], false)
	assert_eq(_mine().count(BlockIds.LOG), 1)


func test_the_sandbox_has_everything_already() -> void:
	Game.mode = ModeRules.SANDBOX
	_mine().add(BlockIds.LOG, 1)
	Session.request_craft(&"planks")
	assert_eq(_done.back(), [false, "Crafting is for Survivor worlds.", BlockIds.PLANKS, 0])
	assert_eq(_mine().count(BlockIds.LOG), 1)


## The local game's own view of the stations, for the recipe book (the same rules, the stricter reach).
func test_the_local_player_sees_the_stations_near_them() -> void:
	_world.blocks[Vector3i(3, 20, 0)] = BlockIds.CRAFTING_TABLE
	var st := Session.craft_stations_near(_me.eye_position(), CraftRules.REACH)
	assert_eq(st, {Recipes.HAND: true, Recipes.TABLE: true, Recipes.FURNACE: false, Recipes.REFINERY: false,
		Recipes.MELTER: false, Recipes.OXYGEN_MAKER: false, Recipes.SOLAR_OVEN: false})   # spec §26.5: the machines
