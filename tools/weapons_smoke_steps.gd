extends Node
## The steps of tools/weapons_smoke.gd (M1b Task 11): holds a sword, places a dummy, swings at it,
## shoots it with the bow, throws the boomerang, fells a tree with the axe, smashes with the hammer,
## digs with the pickaxe and saves the targets.

const TIMEOUT := 60.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _fails: Array[String] = []
var _dummy: PracticeTarget
var _log_cell := Vector3i.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _wait > 0.0:
		_wait -= delta
		return
	_run_step(sandbox)


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var interactor: BlockInteractor = p.get_node("BlockInteractor")
	var combat: CombatDirector = sandbox.get_node("Combat")
	var world: WorldService = p.world
	match _step:
		0:
			interactor.set_slot_block(0, ItemIds.SWORD)
			_next(0.2)
		1:
			_check(p.held_item == ItemIds.SWORD, "player holds the sword")
			var hand := p.avatar.hand()
			var held := hand.get_child(0) as HeldItem if hand.get_child_count() > 0 else null
			_check(held != null and held.visible and held.item_id == ItemIds.SWORD, "sword model in the hand")
			var cell := _target_spot(world, p)
			_check(cell.y > -1000, "found a flat spot for a dummy")
			Session.request_place_target(ItemIds.DUMMY, cell, p.rig.yaw + PI)
			_next(0.2)
		2:
			_check(combat.targets().size() == 1, "dummy placed")
			if combat.targets().is_empty():
				_finish()
				return
			_dummy = combat.targets()[0]
			_check(interactor.weapons.attack_towards(ItemIds.SWORD, _dummy.center(), 1.0), "sword swing accepted")
			_next(0.5)
		3:
			_check(_dummy.hits_taken == 1 and _dummy.last_damage == 4, "sword hit the dummy for 4 (hits %d)" % _dummy.hits_taken)
			interactor.set_slot_block(0, ItemIds.BOW)
			_next(0.6)
		4:
			_check(interactor.weapons.attack_towards(ItemIds.BOW, _dummy.center(), 1.0), "bow shot accepted")
			_next(1.0)
		5:
			_check(_dummy.hits_taken == 2, "arrow hit the dummy (hits %d)" % _dummy.hits_taken)
			interactor.set_slot_block(0, ItemIds.BOOMERANG)
			_next(0.7)
		6:
			_check(interactor.weapons.attack_towards(ItemIds.BOOMERANG, _dummy.center(), 1.0), "boomerang thrown")
			_next(0.1)
		7:
			_check(combat.boomerang_of(p.peer_id) != null, "boomerang in the air")
			_next(3.0)
		8:
			_check(combat.boomerang_of(p.peer_id) == null, "boomerang came back")
			_check(_dummy.hits_taken == 3, "boomerang hit the dummy once (hits %d)" % _dummy.hits_taken)
			_log_cell = _find_log(world, p)
			_check(_log_cell.y > -1000, "found a tree")
			if _log_cell.y > -1000:
				var edits := ToolPowers.for_tool(ItemIds.AXE, _log_cell, Vector3i.UP, 0, world.get_block)
				_check(edits.size() > 5, "the axe fells %d blocks" % edits.size())
				p.global_position = Vector3(_log_cell) + Vector3(2.5, 0.0, 0.5)
				_check(interactor.apply_edits(edits, false), "tree edits accepted by the host")
			_next(0.3)
		9:
			if _log_cell.y > -1000:
				_check(world.get_block(_log_cell) == BlockIds.AIR, "tree felled")
			var ground := Vector3i(p.global_position.floor()) + Vector3i(0, -1, -2)
			var smash := ToolPowers.for_tool(ItemIds.HAMMER, ground, Vector3i.UP, 0, world.get_block)
			_check(interactor.apply_edits(smash), "smash edits accepted (%d)" % smash.size())
			var dig := ToolPowers.for_tool(ItemIds.PICKAXE, ground + Vector3i(0, -1, 0), Vector3i.UP, 0, world.get_block)
			_check(interactor.apply_edits(dig), "pickaxe edits accepted (%d)" % dig.size())
			_next(0.3)
		10:
			sandbox.save_world()
			_check(sandbox.meta.targets.size() == 1, "the dummy is saved with the world")
			_finish()


func _next(wait: float) -> void:
	_step += 1
	_wait = wait


func _check(ok: bool, what: String) -> void:
	print("WEAPONS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("WEAPONS_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().quit(1 if not _fails.is_empty() else 0)


## A spot 2-4 blocks from the player where a target can stand.
func _target_spot(world: WorldService, p: Player) -> Vector3i:
	var feet := Vector3i(p.global_position.floor())
	for r in range(2, 5):
		for dx in range(-r, r + 1):
			for dy in range(-2, 3):
				var cell := feet + Vector3i(dx, dy, -r)
				if WeaponRules.target_spot_ok(cell, world.get_block):
					return cell
	return Vector3i(0, -9999, 0)


## A natural tree's log near the player.
func _find_log(world: WorldService, p: Player) -> Vector3i:
	var feet := Vector3i(p.global_position.floor())
	for r in range(1, 40):
		for dx in range(-r, r + 1):
			for dz in [-r, r]:
				for pos: Vector3i in [Vector3i(dx, 0, dz), Vector3i(dz, 0, dx)]:
					for dy in range(-6, 10):
						var c := feet + pos + Vector3i(0, dy, 0)
						if world.get_block(c) == BlockIds.LOG and not ToolPowers.fell_tree(c, world.get_block).is_empty():
							return c
	return Vector3i(0, -9999, 0)
