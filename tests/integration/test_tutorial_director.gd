extends GutTest
## M3 Task 15 (spec §14.9): the TutorialDirector (node "Tutorial", this game only). The first solo Survivor start
## offers PLAY WITH PIP / SKIP (the shop tip waits); SKIP is never asked again. Playing lays "Pip's playground" into
## the world (every changed cell recorded in the world's meta at once), brings a visiting Pip, and walks through the
## steps in order, each checked from the child's real actions; the end pays once (500 gold, Pip's Cap, Pip for keeps)
## and puts every cell back (the child's own blocks go back to their bag). The X stops it: everything goes, and it
## goes on from that step next time. A crash's leftovers are put back at the next start. SETTINGS replays it.

const SITE := {"origin": Vector3i(0, 40, 10), "dir": 0}
const DT := 0.1


## A voxel world: grass on dirt up to y 39, air above; every cell it changes it remembers.
class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		if cells.has(pos):
			return cells[pos]
		if pos.y >= 40:
			return BlockIds.AIR
		return BlockIds.GRASS if pos.y == 39 else BlockIds.DIRT

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 40


var world: EditWorld
var me: Player
var hud: Hud
var layer: Control
var d: TutorialDirector
var profile: ProfileData
var meta: WorldMeta
var bag: Inventory
var on_floor := [true]
var pips: Array = []
var pip: Node3D
var slimes: Array = []
var puffed: Array = []
var gold: Array = []
var tips: Array = []
var released: Array = []
var saves: Array = []
var points: Array = []
var tilly: Node3D
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	for list: Array in [pips, slimes, puffed, gold, tips, released, saves, points]:
		list.clear()
	pip = null
	on_floor[0] = true
	world = EditWorld.new()
	autofree(world)
	me = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.peer_id = multiplayer.get_unique_id()
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.viewer.free()
	me._spawned = true
	me.global_position = Vector3(0.5, 40, 0.5)   # at the spawn, off the playground (which starts at z 9)
	hud = Hud.new()
	add_child_autofree(hud)
	hud.setup(me, "Kid", true, false)
	layer = Control.new()
	add_child_autofree(layer)
	tilly = Node3D.new()
	add_child_autofree(tilly)
	tilly.global_position = Vector3(20.5, 40, 0.5)
	profile = ProfileData.new()
	meta = WorldMeta.new()
	bag = Inventory.starter_kit()
	d = _director(true)


func after_each() -> void:
	Game.mode = _mode_before


func _director(here: bool, the_meta: WorldMeta = null) -> TutorialDirector:
	var t := TutorialDirector.new()
	t.auto_tick = false
	t.threaded = false
	t.here = here
	t.profile = profile
	t.save_profile = func() -> void: saves.append(&"profile")
	t.meta = meta if the_meta == null else the_meta
	t.save_meta = func() -> void: saves.append(&"meta")
	t.world = world
	t.box_reader = func(_origin: Vector3i, _size: Vector3i) -> Callable: return world.get_block
	t.write_batch = 1 << 20   # every cell in one tick (the game writes a batch a tick: its own test)
	t.player = me
	t.hud = hud
	t.pick_site = func() -> Dictionary: return SITE
	t.on_floor = func() -> bool: return on_floor[0]
	t.bring_pip = func(record: Dictionary) -> void:
		pips.append(record)
		pip = Node3D.new()
		add_child_autofree(pip)
		pip.global_position = me.global_position + Vector3(1, 0, 0)
	t.pip_node = func() -> Node3D: return pip if is_instance_valid(pip) and not pip.is_queued_for_deletion() else null
	t.spawn_slime = func(pos: Vector3, _yaw: float) -> Node3D:
		var m := Monster.new()
		m.setup({"kind": MonsterRules.SLIME, "level": 1, "id": "tut_%d" % slimes.size(), "pos": pos, "wild": false, "practice": true})
		m.block_at = world.get_block
		add_child_autofree(m)
		m.set_physics_process(false)
		slimes.append(m)
		return m
	t.puff = func(m: Node3D) -> void:
		puffed.append(m)
		m.queue_free()
	t.gold_add = func(n: int) -> void: gold.append(n)
	t.bag = func() -> Inventory: return bag
	t.show_tip = func() -> bool:
		tips.append(true)
		return true
	t.release_tip = func() -> void: released.append(true)
	t.tilly = func() -> Node3D: return tilly
	t.point_at = func(what: String, pos: Vector3) -> void: points.append([what, pos])
	t.stop_arrow = func() -> void: points.append([])
	add_child_autofree(t)
	t.setup_local(layer)
	return t


func _ticks(n: int = 1) -> void:
	for i in n:
		d.tick(DT)


func _feet(a: int, s: int = 0, dy: float = 0.0) -> Vector3:
	return TutorialCourse.spot(SITE, a, s) + Vector3(0, dy, 0)


func _play() -> void:
	d.start_session()
	d.offer.play_button.pressed.emit()
	_ticks()


func _cell(a: int, s: int, dy: int) -> Vector3i:
	return TutorialCourse.cell(SITE, a, s, dy)


# --- The offer ---

func test_the_first_survivor_start_offers_it_and_the_shop_tip_waits() -> void:
	assert_true(d.holds_tip(), "set up before the spawn: the tip waits")
	d.start_session()
	assert_true(d.offer.is_open(), "PLAY WITH PIP / SKIP")
	assert_false(d.is_running())
	assert_true(world.cells.is_empty(), "nothing in the world before the child says yes")


func test_skip_is_never_asked_again_and_gives_nothing() -> void:
	d.start_session()
	d.offer.skip_button.pressed.emit()
	assert_eq(profile.tutorial.state, TutorialData.SKIPPED)
	assert_false(d.holds_tip())
	assert_eq(released.size(), 1, "the shop tip comes now")
	assert_true(gold.is_empty() and profile.pip.is_empty() and profile.cosmetics.is_empty(), "no reward")
	assert_true(saves.has(&"profile"))
	var again := _director(true)
	again.start_session()
	assert_false(again.offer.is_open(), "never asked again")


func test_it_is_never_offered_where_it_does_not_play() -> void:
	var off := _director(false)
	assert_false(off.holds_tip())
	off.start_session()
	assert_false(off.offer.is_open())


func test_where_it_plays_now() -> void:
	var saved := [Game.mode, Game.net_mode, Game.survivor_game, Game.universe]
	Game.mode = ModeRules.SURVIVOR
	Game.net_mode = &"solo"
	Game.survivor_game = SurvivorGames.CLASSIC
	Game.universe = 1
	assert_true(TutorialDirector.plays_now(), "a solo Survivor world")
	Game.net_mode = &"host"
	assert_false(TutorialDirector.plays_now(), "never in LAN or online games")
	Game.net_mode = &"solo"
	Game.mode = ModeRules.SANDBOX
	assert_false(TutorialDirector.plays_now(), "never in Sandbox")
	Game.mode = ModeRules.WAVE
	assert_false(TutorialDirector.plays_now(), "never in Monster Wave")
	Game.mode = saved[0]
	Game.net_mode = saved[1]
	Game.survivor_game = saved[2]
	Game.universe = saved[3]


func test_a_tap_outside_the_offer_asks_again_next_time() -> void:
	d.start_session()
	d.offer.close()
	assert_eq(profile.tutorial.state, TutorialData.NEW)
	assert_eq(released.size(), 1)
	var again := _director(true)
	again.start_session()
	assert_true(again.offer.is_open())


# --- The playground ---

func test_play_lays_out_the_playground_records_it_and_brings_pip() -> void:
	_play()
	assert_true(d.is_running())
	assert_eq(d.step, 0)
	assert_eq(pips.size(), 1, "a visiting Pip rolls up")
	assert_true(d.card.visible)
	assert_false(world.cells.is_empty(), "the playground is in the world")
	assert_eq(world.get_block(TutorialCourse.bench(SITE)), BlockIds.CRAFTING_TABLE)
	assert_eq(meta.tutorial_props, d.record, "recorded in the world's meta")
	assert_true(saves.has(&"meta"), "saved the moment it went in (a crash never keeps it)")
	assert_eq(points[0][0], TutorialRules.PLAYGROUND, "the arrow points at Pip's playground")


func test_the_playground_goes_in_and_out_a_batch_a_tick() -> void:
	d.write_batch = 32
	d.start_session()
	d.offer.play_button.pressed.emit()
	_ticks()
	assert_between(world.cells.size(), 1, 32, "the first batch (the frame cost stays small)")
	assert_eq(meta.tutorial_props.size(), d.record.size(), "the whole record saved before the first cell")
	_ticks(20)
	assert_eq(world.get_block(TutorialCourse.bench(SITE)), BlockIds.CRAFTING_TABLE, "all in")
	d.card.stop_button.pressed.emit()
	assert_false(meta.tutorial_props.is_empty(), "the record stays until every cell is back")
	_ticks(20)
	assert_true(meta.tutorial_props.is_empty())
	assert_eq(world.get_block(TutorialCourse.bench(SITE)), BlockIds.AIR)
	for p: Vector3i in world.cells:
		assert_true(world.cells[p] == BlockIds.AIR if p.y >= 40 else world.cells[p] in [BlockIds.GRASS, BlockIds.DIRT], "back: %s" % p)


func test_the_playground_waits_while_the_child_stands_where_it_goes() -> void:
	me.global_position = _feet(5)
	d.start_session()
	d.offer.play_button.pressed.emit()
	_ticks(3)
	assert_true(world.cells.is_empty(), "never under the child's feet")
	assert_eq(hud._toast_label.text, TutorialRules.line(&"tutorial_step_back"))
	me.global_position = Vector3(0.5, 40, 0.5)
	_ticks(6)
	assert_false(world.cells.is_empty())


func test_a_childs_build_on_the_site_means_another_site() -> void:
	world.cells[_cell(12, 1, 0)] = BlockIds.BRICK   # a house where the playground would go
	var picks := []
	d.pick_site = func() -> Dictionary:
		picks.append(true)
		return SITE if picks.size() == 1 else {"origin": Vector3i(40, 40, 10), "dir": 0}
	_play()
	_ticks(2)
	assert_eq(picks.size(), 2, "asked for another site")
	assert_eq(world.get_block(_cell(12, 1, 0)), BlockIds.BRICK, "the child's build is never touched")
	assert_eq(d.site.origin, Vector3i(40, 40, 10))


# --- The steps, from what the child really does ---

## Walks to the playground's start in small steps, turning the camera on the way.
func _walk_and_look() -> void:
	var from := me.global_position
	var to := _feet(-1)
	for i in range(1, 9):
		me.global_position = from.lerp(to, i / 8.0)
		me.rig.yaw = i * 0.3
		_ticks()


func _jump() -> void:
	me.global_position = _feet(1)
	on_floor[0] = true
	_ticks()
	on_floor[0] = false
	me.global_position = _feet(4, 0, 2.0)
	_ticks()
	me.global_position = _feet(9)
	on_floor[0] = true
	_ticks()


func _bridge() -> void:
	for a in range(TutorialCourse.BRIDGE_FROM, TutorialCourse.BRIDGE_TO + 1):
		world.set_block(_cell(a, 0, -1), BlockIds.PLANKS)
		bag.take(BlockIds.PLANKS, 1)
	_ticks()


func _wall() -> void:
	world.set_block(_cell(TutorialCourse.WALL_A, -1, 0), BlockIds.AIR)
	world.set_block(_cell(TutorialCourse.WALL_A, -1, 1), BlockIds.AIR)
	_ticks()


func _hide() -> void:
	me.global_position = _feet(TutorialCourse.BUSHES[0].x, TutorialCourse.BUSHES[0].y)
	me.crouching = true
	me.stealth_in_bush = true
	_ticks(int(TutorialChecks.HIDE_HOLD / DT) + 2)
	me.crouching = false
	me.stealth_in_bush = false


func _craft() -> void:
	Session.craft_done.emit(true, "", ItemIds.STICK, 4)
	_ticks()


func _visit_tilly() -> void:
	me.global_position = tilly.global_position + Vector3(0, 0, 2.5)
	_ticks()


func test_the_steps_in_order_each_from_real_actions() -> void:
	_play()
	_ticks(3)
	assert_eq(d.step, 0, "standing still: not yet")
	_walk_and_look()
	assert_eq(d.step, 1, "walked to the arrow and looked around")
	me.global_position = _feet(1)
	_ticks()
	me.global_position = _feet(4, 3)   # walked round the side of the hole ...
	_ticks()
	me.global_position = _feet(12)     # ... and back on past it: no jump
	_ticks()
	assert_eq(d.step, 1, "the hole must be jumped")
	_jump()
	assert_eq(d.step, 2, "jumped the hole")
	_ticks(3)
	assert_eq(d.step, 2, "the bridge waits for its blocks")
	_bridge()
	assert_eq(d.step, 3, "the bridge")
	_wall()
	assert_eq(d.step, 4, "the wall")
	assert_eq(slimes.size(), 1, "the practice slime comes")
	assert_true((slimes[0] as Monster).practice)
	_hide()
	assert_eq(d.step, 5, "hid in the bush")
	assert_has(puffed, slimes[0], "the slime puffs away")
	Session.craft_done.emit(true, "", BlockIds.CRAFTING_TABLE, 1)
	_ticks()
	assert_eq(d.step, 5, "only sticks")
	_craft()
	assert_eq(d.step, 6, "made sticks")
	assert_eq(tips.size(), 1, "owner #37's shop tip and its arrow")
	_visit_tilly()
	assert_false(d.is_running(), "every step done")


func test_finishing_pays_once_keeps_pip_and_puts_the_world_back() -> void:
	_play()
	var before_gold := gold.size()
	_walk_and_look()
	_jump()
	_bridge()
	_wall()
	_hide()
	_craft()
	_visit_tilly()
	assert_eq(gold, [TutorialRules.REWARD_GOLD], "500 Survivor gold")
	assert_eq(before_gold, 0)
	assert_has(profile.cosmetics, "hat.pip_cap", "the free hat")
	assert_false(profile.pip.is_empty(), "Pip is the first pet")
	assert_eq(profile.tutorial.state, TutorialData.DONE)
	assert_true(profile.tutorial.rewarded)
	assert_true(d.offer.is_open(), "the reward card")
	assert_has(d.offer.texts(), TutorialRules.line(&"tutorial_reward_pip"))
	assert_true(meta.tutorial_props.is_empty(), "nothing is kept")
	for p: Vector3i in world.cells:
		assert_eq(world.cells[p], world.get_block(p))
	assert_eq(world.get_block(TutorialCourse.bench(SITE)), BlockIds.AIR, "the Workbench went")
	assert_eq(world.get_block(_cell(TutorialCourse.BRIDGE_FROM, 0, -1)), BlockIds.GRASS, "the ground is back")
	assert_eq(bag.count(BlockIds.PLANKS), 16, "the bridge's planks came back")
	assert_false(d.card.visible)
	# SETTINGS: again, no second reward
	TutorialRules.ask_replay(profile.tutorial)
	d.tick(1.0)
	assert_true(d.is_running(), "a replay asked from SETTINGS starts without the card")
	assert_eq(d.step, 0)
	_walk_and_look()
	_jump()
	_bridge()
	_wall()
	_hide()
	_craft()
	_visit_tilly()
	assert_eq(gold, [TutorialRules.REWARD_GOLD], "no second reward")
	assert_has(d.offer.texts(), TutorialRules.line(&"tutorial_again_done"))


func test_the_x_stops_it_nothing_lost_and_it_goes_on_from_there() -> void:
	_play()
	_walk_and_look()
	_jump()
	_bridge()
	assert_eq(d.step, 3)
	d.card.stop_button.pressed.emit()
	assert_false(d.is_running())
	assert_false(d.card.visible)
	assert_true(meta.tutorial_props.is_empty(), "the playground goes")
	assert_eq(world.get_block(TutorialCourse.bench(SITE)), BlockIds.AIR)
	assert_eq(bag.count(BlockIds.PLANKS), 16, "the bridge's blocks came back")
	assert_null(d.pip_node.call(), "the visiting Pip went home")
	assert_eq(profile.tutorial.state, TutorialData.STARTED)
	assert_eq(profile.tutorial.step, 3)
	assert_true(released.size() >= 1, "the shop tip may come now")
	assert_true(gold.is_empty(), "no reward for part of it")
	var again := _director(true)
	d = again
	again.start_session()
	assert_true(again.offer.is_open())
	assert_has(again.offer.texts(), TutorialRules.line(&"tutorial_resume"))
	again.offer.play_button.pressed.emit()
	_ticks()
	assert_eq(again.step, 3, "on at the wall")
	assert_eq(world.get_block(_cell(TutorialCourse.WALL_A, 0, 0)), BlockIds.DIRT, "the playground is back for it")


func test_a_crashs_leftovers_are_put_back_at_the_next_start() -> void:
	_play()
	_walk_and_look()
	_jump()
	_bridge()
	var record := meta.tutorial_props.duplicate(true)
	assert_false(record.is_empty())
	# the game closed here: the next start finds the record in the world's meta
	var next_meta := WorldMeta.from_json(meta.to_json())
	var next := _director(false, next_meta)   # even where the tutorial never plays (a LAN host of this world)
	next.start_session()
	next.tick(DT)
	assert_true(next_meta.tutorial_props.is_empty())
	assert_eq(world.get_block(TutorialCourse.bench(SITE)), BlockIds.AIR, "put back")
	assert_eq(bag.count(BlockIds.PLANKS), 16, "and the bridge's planks are the child's again")


func test_a_fall_into_the_hole_says_try_again() -> void:
	_play()
	_walk_and_look()
	me.global_position = _feet(1)
	_ticks()
	me.global_position = _feet(4, 0, -2.0)
	_ticks()
	assert_eq(d.step, 1)
	assert_eq(hud._toast_label.text, TutorialRules.line(&"tutorial_jump_again"))


func test_blocks_for_the_bridge_when_the_bag_has_none() -> void:
	bag = Inventory.new()
	bag.add(ItemIds.SWORD, 1)
	_play()
	_walk_and_look()
	_jump()
	assert_eq(d.step, 2)
	assert_eq(bag.count(BlockIds.DIRT), 3, "Pip hands over 3 blocks")


func test_the_craft_step_opens_the_bag_on_crafting() -> void:
	_play()
	_walk_and_look()
	_jump()
	_bridge()
	_wall()
	_hide()
	assert_eq(d.step, 5)
	hud.palette.counted = true
	hud.palette.open()
	assert_eq(hud.palette.tab_bar.current_tab, BlockPalette.CRAFT_PAGE)


func test_the_card_steps_aside_for_the_shop_tip() -> void:
	_play()
	hud.picture_hint.show_hint(CoinIcon.texture(), CoinIcon.GOLD, "tip", 5.0)
	_ticks()
	assert_false(d.card.visible)
	hud.picture_hint.hide()
	_ticks()
	assert_true(d.card.visible)


func test_photo_mode_hides_the_card_and_the_glow_with_the_hud() -> void:
	_play()
	hud.visible = false   # photo mode (it pauses the game too: no tick runs)
	assert_false(d.card.visible)
	assert_false(d.outline.visible)
	hud.visible = true
	assert_true(d.card.visible)
	assert_true(d.outline.visible)


func test_the_step_words_are_read_aloud_and_have_ids() -> void:
	var said := []
	d.say = func(text: String) -> void: said.append(text)
	_play()
	assert_eq(said[0], TutorialRules.words(0))
	_walk_and_look()
	assert_has(said, TutorialRules.words(1))


## Found in the live relay test (2026-09-25 22:08): a guest's director ticks before its player comes from the host,
## so before the sandbox gives it the profile; the SETTINGS replay look read `profile.tutorial` on null.
func test_a_director_not_set_up_yet_ticks_quietly() -> void:
	var t := TutorialDirector.new()
	t.auto_tick = false
	add_child_autofree(t)
	t.tick(TutorialDirector.REPLAY_LOOK + 0.1)
	t.tick(TutorialDirector.REPLAY_LOOK + 0.1)
	assert_eq(get_errors().size(), 0, "nothing to do until the sandbox sets it up")


## M5 Task 6 (the whole-game review): the X gave the child's own blocks back to their bag at once while the cells went
## back a batch a tick (about a second), and the world's meta kept the whole record until the last cell. A game saved
## and closed in that second (SAVE & QUIT right after the X or the end) found the child's blocks still in the world at
## the next start and gave them back a second time: blocks built into the playground doubled.
func test_blocks_given_back_are_never_given_twice_after_a_close_mid_clearing() -> void:
	_play()
	_walk_and_look()
	_jump()
	_bridge()
	assert_eq(bag.count(BlockIds.PLANKS), 13, "three planks in the bridge")
	d.write_batch = 1   # the game writes a batch a tick: the clearing takes a while
	d.card.stop_button.pressed.emit()
	assert_eq(bag.count(BlockIds.PLANKS), 16, "the bridge's planks came back")
	assert_false(meta.tutorial_props.is_empty(), "the game closes before every cell is back")
	var next_meta := WorldMeta.from_json(meta.to_json())
	var next := _director(false, next_meta)
	next.start_session()
	for i in 400:
		next.tick(DT)
	assert_true(next_meta.tutorial_props.is_empty(), "the rest put back at the next start")
	assert_eq(bag.count(BlockIds.PLANKS), 16, "and never given twice")
	for a in range(TutorialCourse.BRIDGE_FROM, TutorialCourse.BRIDGE_TO + 1):
		assert_ne(world.get_block(_cell(a, 0, -1)), BlockIds.PLANKS, "the bridge went with its planks")
