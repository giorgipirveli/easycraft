extends GutTest
## M3 Task 14a through the host (Session section "M3 Task 14a") and the GadgetDirector: quick builds (from
## the stamps' blueprints, into empty cells only, one undo step, Survivor pays planks then stone and says
## "Need 12 Planks!"), the Boing Orb (pushes monsters, bounces players, hurts nobody), the Dance Orb
## (monsters dance 5 s and never attack meanwhile; a boss 2 s, at most once in 20 s), thrown orbs (they fly
## in every game from a small pool and burst where they land; Survivor uses one up), guests' requests checked,
## and ATTACK with a gadget in the hand (owner feedback #29: the hook or an orb is used; with a build in the
## hand ATTACK still attacks).

const ME_AT := Vector3(0.5, 10.0, 0.5)


## Stands in for the terrain: grass below y = 10, air above, plus `cells`.
class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 9


var world: EditWorld
var me: Player
var interactor: BlockInteractor
var gadgets: GadgetDirector
var _said: Array = []
var _pushes: Array = []
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	Session.gadget_reset()
	world = EditWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	me = _player(multiplayer.get_unique_id(), ME_AT)
	interactor = me.get_node("BlockInteractor")
	gadgets = GadgetDirector.new()
	add_child_autofree(gadgets)
	gadgets.block_at = world.get_block
	_said.clear()
	_pushes.clear()
	Session.magic_feedback.connect(_on_said)
	Session.knocked_back.connect(_on_pushed)


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_said)
	Session.knocked_back.disconnect(_on_pushed)
	Game.mode = _mode_before
	Session.register_world(null)
	Session.survivor_reset()
	Session.gadget_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_said(text: String) -> void:
	_said.append(text)


func _on_pushed(impulse: Vector3) -> void:
	_pushes.append(impulse)


func _player(peer: int, feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.global_position = feet
	p._spawned = true
	return p


func _monster(kind: StringName, pos: Vector3, id: String) -> Monster:
	var m := Monster.new()
	m.setup({"kind": kind, "level": 1, "id": id, "pos": pos, "yaw": 0.0})
	m.block_at = world.get_block
	add_child_autofree(m)
	m.set_physics_process(false)
	return m


## A physics floor with its top at y = 10 (monsters stepped by hand stand on it).
func _floor() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 10, 200)
	shape.shape = box
	shape.position = Vector3(0, 5, 0)
	ground.add_child(shape)
	world.add_child(ground)


func _cells_of(id: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for c: Vector3i in world.cells:
		if world.cells[c] == id:
			out.append(c)
	return out

# --- Quick builds -----------------------------------------------------------------------------------------

func test_a_quick_wall_goes_up_in_front_as_one_undo_step() -> void:
	watch_signals(Session)
	assert_true(Session.request_instant_build(ItemIds.BUILD_WALL, 0.0))   # looking along -Z
	var planks := _cells_of(BlockIds.PLANKS)
	assert_eq(planks.size(), 12)
	for c in planks:
		assert_eq(c.z, -2, "two blocks in front")
	assert_signal_emitted(Session, "gadget_built")
	assert_eq(interactor.undo_size(), 1, "one undo step")
	assert_true(interactor.undo())
	assert_eq(_cells_of(BlockIds.PLANKS).size(), 0, "undo takes the whole wall away")


func test_a_build_never_replaces_a_block_and_says_when_there_is_no_room() -> void:
	world.cells[Vector3i(0, 10, -2)] = BlockIds.BRICK
	Session.request_instant_build(ItemIds.BUILD_WALL, 0.0)
	assert_eq(world.get_block(Vector3i(0, 10, -2)), BlockIds.BRICK, "the brick stays")
	assert_eq(_cells_of(BlockIds.PLANKS).size(), 11)
	Session.gadget_reset()
	assert_false(Session.request_instant_build(ItemIds.BUILD_FLOOR, 0.0), "flat ground: no hole to fill")
	assert_has(_said, GadgetRules.NOTHING_TO_BUILD)


func test_a_quick_fort_leaves_a_door_and_a_ramp_climbs() -> void:
	assert_true(Session.request_instant_build(ItemIds.BUILD_FORT, 0.0))
	assert_eq(world.get_block(Vector3i(0, 10, -1)), BlockIds.AIR, "the door, facing the player")
	assert_eq(world.get_block(Vector3i(1, 10, -1)), BlockIds.PLANKS)
	assert_eq(world.get_block(Vector3i(0, 10, -5)), BlockIds.PLANKS, "the back wall")
	me.global_position = Vector3(10.5, 10.0, 10.5)
	Session.gadget_reset()
	assert_true(Session.request_instant_build(ItemIds.BUILD_RAMP, PI))   # looking along +Z
	assert_eq(world.get_block(Vector3i(10, 10, 11)), BlockIds.PLANKS)
	assert_eq(world.get_block(Vector3i(10, 13, 14)), BlockIds.PLANKS, "four steps up")


func test_survivor_pays_planks_then_stone_and_says_what_is_missing() -> void:
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	Session.set_inventory(me.peer_id, inv)
	inv.add(ItemIds.BUILD_WALL, 1)
	inv.add(BlockIds.PLANKS, 5)
	assert_false(Session.request_instant_build(ItemIds.BUILD_WALL, 0.0))
	assert_has(_said, "Need 12 Planks!")
	assert_eq(_cells_of(BlockIds.PLANKS).size(), 0, "nothing is built")
	assert_eq(inv.count(BlockIds.PLANKS), 5, "nothing is taken")
	inv.add(BlockIds.STONE, 20)
	Session.gadget_reset()
	assert_true(Session.request_instant_build(ItemIds.BUILD_WALL, 0.0))
	assert_eq(_cells_of(BlockIds.STONE).size(), 12, "a stone wall")
	assert_eq(inv.count(BlockIds.STONE), 8)
	assert_eq(inv.count(BlockIds.PLANKS), 5)
	inv.add(BlockIds.PLANKS, 20)
	me.global_position = Vector3(10.5, 10.0, 10.5)
	Session.gadget_reset()
	assert_true(Session.request_instant_build(ItemIds.BUILD_WALL, 0.0))
	assert_eq(inv.count(BlockIds.PLANKS), 13, "planks first when there are enough")


func test_survivor_needs_the_build_in_the_bag_and_builds_wait_a_moment() -> void:
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	inv.add(BlockIds.PLANKS, 100)
	Session.set_inventory(me.peer_id, inv)
	assert_false(Session.request_instant_build(ItemIds.BUILD_WALL, 0.0), "no Quick Wall bought")
	inv.add(ItemIds.BUILD_WALL, 1)
	var now := [0]
	Session.gadget_now_ms = func() -> int: return now[0]
	assert_true(Session.request_instant_build(ItemIds.BUILD_WALL, 0.0))
	me.global_position = Vector3(10.5, 10.0, 10.5)
	now[0] = 100
	assert_false(Session.request_instant_build(ItemIds.BUILD_WALL, 0.0), "a moment later")
	now[0] = 700
	assert_true(Session.request_instant_build(ItemIds.BUILD_WALL, 0.0))
	assert_eq(inv.count(ItemIds.BUILD_WALL), 1, "a build item is kept")


func test_a_guests_build_goes_where_the_host_sees_the_guest() -> void:
	var guest := _player(5, Vector3(20.5, 10.0, 0.5))
	assert_true(Session.host_instant_build(5, ItemIds.BUILD_WALL, 0.0))
	assert_eq(world.get_block(Vector3i(20, 10, -2)), BlockIds.PLANKS)
	assert_false(Session.host_instant_build(5, ItemIds.SWORD, 0.0), "not a build")
	assert_false(Session.host_instant_build(5, ItemIds.BUILD_WALL, NAN), "a broken yaw")
	assert_true(is_instance_valid(guest))
	for e in get_errors():   # the guest's undo step goes by RPC, and in a test there is no network peer 5
		e.handled = true

# --- Orbs -------------------------------------------------------------------------------------------------

func test_the_boing_orb_pushes_monsters_and_bounces_players_and_hurts_nobody() -> void:
	var m := _monster(MonsterRules.GOBLIN, Vector3(2.5, 10.0, 0.5), "boing_goblin")
	var hp := m.hp
	var hearts := me.health.hp
	await wait_physics_frames(1)         # players are looked up once per physics frame
	var caught := gadgets.burst(ItemIds.IMPULSE_ORB, Vector3(0.5, 10.2, 0.5))
	assert_true(caught.has(m))
	assert_gt(m.velocity.x, 3.0, "pushed away from the burst")
	assert_eq(m.hp, hp, "never hurt")
	assert_true(caught.has(me))
	assert_eq(_pushes.size(), 1)
	assert_gt((_pushes[0] as Vector3).y, 10.0, "the player bounces up")
	assert_eq(me.health.hp, hearts)
	var far := _monster(MonsterRules.SLIME, Vector3(12.5, 10.0, 0.5), "far_slime")
	gadgets.burst(ItemIds.IMPULSE_ORB, Vector3(0.5, 10.2, 0.5))
	assert_eq(far.velocity, Vector3.ZERO, "outside the burst")


func test_monsters_dance_for_5_s_and_never_attack_meanwhile() -> void:
	_floor()
	var m := _monster(MonsterRules.GOBLIN, Vector3(1.5, 10.0, 0.5), "dancer")
	await wait_physics_frames(1)
	m.winding = true
	gadgets.burst(ItemIds.DANCE_ORB, Vector3(1.5, 10.2, 1.5))
	assert_true(m.is_dancing())
	assert_almost_eq(m.dance_left, GadgetRules.DANCE_TIME, 0.001)
	assert_false(m.winding, "the club comes down")
	assert_eq(gadgets.dancers(), 1, "every game shows the dance")
	var hearts := me.health.hp
	var yaw := m.rotation.y
	var turned := false
	for i in 240:                        # 4 s, the player right beside it
		m._physics_process(1.0 / 60.0)
		turned = turned or absf(m.rotation.y - yaw) > 0.3
	assert_true(turned, "it dances")
	assert_eq(me.health.hp, hearts, "it never attacked")
	for i in 90:
		m._physics_process(1.0 / 60.0)
	assert_false(m.is_dancing(), "5 s and it is over")


func test_a_boss_dances_2_s_and_only_once_in_20_s() -> void:
	var g := StoneGolem.new()
	g.setup({"id": "dance_golem", "pos": Vector3(2.5, 10.0, 0.5), "yaw": 0.0, "max_hp": 60, "tired": false})
	g.block_at = world.get_block
	add_child_autofree(g)
	g.set_physics_process(false)
	var now := [100.0]
	gadgets.now_s = func() -> float: return now[0]
	gadgets.burst(ItemIds.DANCE_ORB, Vector3(2.5, 11.0, 1.5))
	assert_almost_eq(g.dance_left, GadgetRules.BOSS_DANCE_TIME, 0.001)
	var phase_t := g._phase_t
	for i in 60:
		g._physics_process(1.0 / 60.0)
	assert_eq(g._phase_t, phase_t, "its attacks wait while it dances")
	for i in 70:
		g._physics_process(1.0 / 60.0)
	assert_false(g.is_dancing())
	now[0] = 110.0
	gadgets.burst(ItemIds.DANCE_ORB, Vector3(2.5, 11.0, 1.5))
	assert_false(g.is_dancing(), "not again within 20 s")
	now[0] = 121.0
	gadgets.burst(ItemIds.DANCE_ORB, Vector3(2.5, 11.0, 1.5))
	assert_true(g.is_dancing())


func test_a_thrown_orb_flies_and_bursts_where_it_lands() -> void:
	var m := _monster(MonsterRules.SLIME, Vector3(0.5, 10.0, -6.5), "target_slime")
	watch_signals(gadgets)
	assert_true(Session.request_orb(ItemIds.DANCE_ORB, Vector3(0, -0.3, -1)))
	assert_eq(gadgets.pending(), 1)
	assert_eq(gadgets.orbs_flying(), 1, "every game flies it")
	await wait_until(func() -> bool: return gadgets.pending() == 0, 3.0, "it lands")
	assert_signal_emitted(gadgets, "burst_done")
	assert_true(m.is_dancing(), "it landed by the slime")


func test_orbs_come_from_a_small_pool_never_a_node_per_throw() -> void:
	for i in 30:
		gadgets._rpc_orb(ItemIds.IMPULSE_ORB, Vector3(0, 12, 0), Vector3(0, 5, -10), 1.0)
	assert_lte(gadgets.orb_nodes(), GadgetDirector.POOL_SIZE)
	assert_lte(gadgets.orbs_flying(), GadgetDirector.POOL_SIZE)


func test_survivor_uses_up_an_orb_and_needs_one_to_throw() -> void:
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	inv.add(ItemIds.IMPULSE_ORB, 1)
	Session.set_inventory(me.peer_id, inv)
	var now := [0]
	Session.gadget_now_ms = func() -> int: return now[0]
	assert_true(Session.request_orb(ItemIds.IMPULSE_ORB, Vector3.FORWARD))
	assert_eq(inv.count(ItemIds.IMPULSE_ORB), 0, "used up")
	now[0] = 5000
	assert_false(Session.request_orb(ItemIds.IMPULSE_ORB, Vector3.FORWARD))
	assert_has(_said, "You have no Boing Orb left!")


func test_a_guests_orb_is_checked() -> void:
	_player(5, Vector3(4.5, 10.0, 0.5))
	var now := [0]
	Session.gadget_now_ms = func() -> int: return now[0]
	assert_false(Session.host_orb(5, ItemIds.SWORD, Vector3.FORWARD), "not an orb")
	assert_false(Session.host_orb(5, ItemIds.DANCE_ORB, Vector3(NAN, 0, 0)), "a broken aim")
	assert_false(Session.host_orb(9, ItemIds.DANCE_ORB, Vector3.FORWARD), "nobody there")
	assert_true(Session.host_orb(5, ItemIds.DANCE_ORB, Vector3.FORWARD))
	now[0] = 400
	assert_false(Session.host_orb(5, ItemIds.DANCE_ORB, Vector3.FORWARD), "once a second")
	now[0] = 1000
	assert_true(Session.host_orb(5, ItemIds.DANCE_ORB, Vector3.FORWARD))

# --- ATTACK and the hand (owner feedback #29) ---------------------------------------------------------------

func test_attack_with_the_hook_or_an_orb_in_the_hand_uses_it_and_never_punches() -> void:
	for item in [ItemIds.GRAPPLE, ItemIds.DANCE_ORB]:
		interactor.set_slot_block(0, item)
		watch_signals(Session)
		interactor.weapons.attack_pressed()
		assert_signal_not_emitted(Session, "attack_requested", ItemIds.display_name(item))
		assert_eq(interactor.selected_block(), item, "it stays in the hand")


func test_attack_with_a_quick_build_or_the_glider_in_the_hand_still_attacks() -> void:
	for item in [ItemIds.BUILD_WALL, ItemIds.GLIDER]:
		interactor.set_slot_block(0, item)
		watch_signals(Session)
		interactor.weapons._ready_ms = 0
		interactor.weapons.attack_pressed()
		assert_signal_emitted(Session, "attack_requested", ItemIds.display_name(item))


func test_a_gadget_shows_in_the_hand() -> void:
	interactor.set_slot_block(0, ItemIds.GRAPPLE)
	interactor.weapons._process(0.0)
	assert_eq(me.held_item, ItemIds.GRAPPLE, "synced: everyone sees the hook in the hand")
	me._update_held_item()
	assert_same(me._held._mesh.mesh, GadgetModels.held(ItemIds.GRAPPLE))
