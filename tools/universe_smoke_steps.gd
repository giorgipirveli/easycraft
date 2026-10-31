extends Node
## The steps of tools/universe_smoke.gd (M3 Task 5), on real terrain through the real systems: a new
## Survivor world of Green Meadows has its stone circle; walking in opens the hub (one universe: the hint
## how to open the next); with universe 2 unlocked the hub lists both, GO! travels there carrying the bag
## (a cosmic sword and 40 planks), the new world is universe 2's (its slot, its ground), nothing stays
## behind; its own circle takes the child back to Green Meadows, bag and all; then the Golem's portal
## (opened as after a win) says where it leads, and walking into it travels to universe 2; there, two
## portal frames built with blocks link and swirl, walking into one comes out by the other, and it is saved.

const TIMEOUT := 180.0
const FAKE_PATH := "res://tests/fakes/fake_universe.gd"   # loaded at run time: tests/ is not exported

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scene: Node
var _left: Node   # the world travelled away from
var _a := Vector3i.ZERO   # two portal frames' doorways (M3 Task 5 portal blocks)
var _b := Vector3i.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.start_new_world = true
	Profile.data.universe_unlocked = 1
	UniverseRegistry.use(2, (load(FAKE_PATH) as GDScript).new())
	Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.NORMAL, 1)
	print("UNIVERSE_SMOKE begin")


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if sandbox != _scene:
		_scene = sandbox
		_wait = 1.0   # a new world: let it settle
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox)


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var hub: UniverseHub = sandbox.universe_hub
	match _step:
		0:
			_check(Game.universe == 1 and Game.slot() == "survivor_1", "universe 1 plays in M2's slot (%s)" % Game.slot())
			_check(hub != null and hub.circle != null, "a stone circle by the spawn")
			if hub == null or hub.circle == null:
				_finish()
				return
			var d := Vector2(hub.circle.position.x - p.global_position.x, hub.circle.position.z - p.global_position.z).length()
			_check(d < 14.0, "a few steps from the spawn (%.1f)" % d)
			_check(not hub.panel.visible, "the hub is closed")
			p.global_position = hub.circle.position + Vector3(0.3, 0.2, 0.2)
			_next(0.5)
		1:
			_check(hub.panel.visible, "walking into the circle opens the hub")
			_check(hub.panel.cards.size() == 1 and hub.panel.hint() == HubPanel.HINT_ONE,
				"one universe: how to open the next (%d cards, '%s')" % [hub.panel.cards.size(), hub.panel.hint()])
			p.global_position = hub.circle.position + Vector3(6, 0.5, 0)
			Profile.data.universe_unlocked = 2
			var bag := Session.inventory_of(p.peer_id)
			bag.add(ItemIds.SWORD_COSMIC, 1)
			bag.add(BlockIds.PLANKS, 40 - bag.count(BlockIds.PLANKS))
			_next(0.5)
		2:
			_check(not hub.panel.visible, "walking away closes it")
			p.global_position = hub.circle.position + Vector3(0.2, 0.2, -0.3)
			_next(0.5)
		3:
			_check(hub.panel.cards.size() == 2, "two universes listed (%d)" % hub.panel.cards.size())
			var card := hub.panel.card_for(2)
			_check(card != null and not card.disabled, "universe 2 can be picked")
			if card:
				card.pressed.emit()
			_left = sandbox
			_next(0.1)
		4:
			if sandbox == _left:
				return   # still saving and leaving
			_check(Game.universe == 2, "arrived in universe 2 (%d)" % Game.universe)
			_check(Game.slot() == "survivor_u2", "its own slot (%s)" % Game.slot())
			_check(p.world.universe == 2, "the world is universe 2's")
			var spawn := p.world.spawn_column()
			_check(p.world.surface_height(spawn.x, spawn.y) == int((load(FAKE_PATH) as GDScript).get_script_constant_map().HEIGHT), "its own ground")
			var bag := Session.inventory_of(p.peer_id)
			var kit := Inventory.starter_kit().count(BlockIds.PLANKS)   # a new world's kit comes on top (M2 §12.1)
			_check(bag.count(ItemIds.SWORD_COSMIC) == 1 and bag.count(BlockIds.PLANKS) == 40 + kit,
				"the bag came along, plus a new world's kit (sword %d, planks %d)" % [bag.count(ItemIds.SWORD_COSMIC),
				bag.count(BlockIds.PLANKS)])
			var left := Inventory.from_save(WorldSaves.load_meta("survivor_1").inventories.get(_key(), []))
			_check(left.count(ItemIds.SWORD_COSMIC) == 0 and left.count(BlockIds.PLANKS) == 0, "nothing stayed behind to use twice")
			_check(hub != null and hub.circle != null, "universe 2 has its circle too")
			if hub == null or hub.circle == null:
				_finish()
				return
			p.global_position = hub.circle.position + Vector3(0.1, 0.2, 0.1)
			_next(0.5)
		5:
			_check(hub.panel.visible and hub.panel.card_for(2).here, "the hub: 'You are here' on universe 2")
			hub.panel.card_for(1).pressed.emit()
			_left = sandbox
			_next(0.1)
		6:
			if sandbox == _left:
				return
			_check(Game.universe == 1, "back in Green Meadows (%d)" % Game.universe)
			var bag := Session.inventory_of(p.peer_id)
			_check(bag.count(ItemIds.SWORD_COSMIC) == 1, "the cosmic sword came back too")
			var left := Inventory.from_save(WorldSaves.load_meta("survivor_u2").inventories.get(_key(), []))
			_check(left.count(ItemIds.SWORD_COSMIC) == 0, "and nothing stayed in universe 2")
			var boss: BossDirector = sandbox.get_node("Boss")
			boss.restore(BossRules.new_help(), p.global_position + Vector3(5, 0, 0))   # the Golem's portal, as after a win
			_next(1.0)
		7:
			var boss: BossDirector = sandbox.get_node("Boss")
			var portals := boss.portals()
			_check(portals.size() == 1 and portals[0].target == 2, "the Golem's portal leads to universe 2")
			if portals.is_empty():
				_finish()
				return
			_check(portals[0].message() == "Walk in: %s!" % UniverseRegistry.display_name(2), "it says so (%s)" % portals[0].message())
			p.global_position = portals[0].global_position + Vector3(0, 0.1, 0.1)
			_left = sandbox
			_next(0.2)
		8:
			if sandbox == _left:
				if _step_t > 5.0:
					_check(false, "walking into the portal travelled")
					_finish()
				return
			_check(Game.universe == 2, "walking into the Golem's portal travelled to universe 2 (%d)" % Game.universe)
			var feet := Vector3i(p.global_position.floor())
			_a = feet + Vector3i(4, 0, 0)
			_b = feet + Vector3i(-6, 0, 8)
			_build_frame(p.world, _a)
			_build_frame(p.world, _b)
			_next(0.5)
		9:
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			_check(frames.swirls().size() == 2, "two portal frames built with blocks link and swirl (%d)" % frames.swirls().size())
			p.global_position = Vector3(_a) + Vector3(0.5, 0.05, 0.5)
			_next(0.5)
		10:
			var target := Vector3(_b) + Vector3(0.5, 0.0, 0.5)
			var d := Vector2(p._spawn_target.x - target.x, p._spawn_target.z - target.z).length()
			_check(d < 1.6, "walking in brings the player out by the other frame (%.1f away)" % d)
			var cell := Vector3i(p._spawn_target.floor())
			_check(not BlockIds.is_solid(p.world.get_block(cell)) and not BlockIds.is_solid(p.world.get_block(cell + Vector3i.UP)),
				"not into a wall")
			sandbox.call("save_world")
			var saved := WorldSaves.load_meta(Game.slot())
			_check(PortalLinks.from_save(saved.portals).works(_b + Vector3i.DOWN), "the link is saved")
			_next(1.5)   # the whoosh and its sparkles end before the run quits
		11:
			_finish()


## A 1 x 2 doorway along X whose lowest opening cell is `lo` (the host sets the blocks: the world's
## block_changed reaches the portals like any edit): frames round it, the core under it, the doorway open.
func _build_frame(world: WorldService, lo: Vector3i) -> void:
	for dy in range(-1, 3):
		for dx in range(-1, 2):
			var c := lo + Vector3i(dx, dy, 0)
			var inside := dx == 0 and dy >= 0 and dy <= 1
			world.set_block(c, BlockIds.AIR if inside else BlockIds.PORTAL_FRAME)
	for dz in [-1, 1]:   # room in front and behind
		world.set_block(lo + Vector3i(0, 0, dz), BlockIds.AIR)
		world.set_block(lo + Vector3i(0, 1, dz), BlockIds.AIR)
	world.set_block(lo + Vector3i.DOWN, BlockIds.PORTAL_CORE)


func _key() -> String:
	var n := str(Profile.data.username)
	return n if n != "" else "player"


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("UNIVERSE_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("UNIVERSE_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	Music.reset()   # a loop still playing at quit reads as a leak: stop it, then quit a moment later
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
