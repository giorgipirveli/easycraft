extends Node
## The steps of tools/knockout_smoke.gd (M2 Task 2): in a new Survivor world, the player is knocked
## out (hearts, fade, message, tip, a bag with the starter blocks, tools kept, no more damage), gets
## up at the world spawn with full hearts and protection, the bag is saved in world.json, a tap on it
## gives every block back, and a Sandbox knock-out pops up on the spot keeping everything.

const TIMEOUT := 90.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _fails: Array[String] = []
var _before: Array = []
var _fell_at := Vector3.ZERO
var _bag: PickupBag


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Session.magic_feedback.connect(func(text: String) -> void: print("KO_SMOKE feedback: %s" % text))
	Game.start_survivor(true)


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
	var hud: Hud = sandbox.hud
	var ko: KnockoutDirector = sandbox.get_node("Knockout")
	var inv := Session.inventory_of(p.peer_id)
	match _step:
		0:
			_check(hud.hearts.visible and hud.hearts.hp == Health.MAX_HP, "the hearts row shows 10 full hearts")
			_check(inv.count(BlockIds.PLANKS) == 16 and inv.count(BlockIds.DIRT) == 8, "the starter kit")
			_before = inv.to_save()
			_fell_at = p.global_position
			Session.hurt_player(p.peer_id, Health.MAX_HP, _fell_at + Vector3(3, 1, 0))
			_check(p.knocked_out and hud.hearts.hp == 0, "knocked out at 0 hearts")
			_check(hud.knockout_overlay.is_down() and hud.knockout_overlay.message() == KnockoutDirector.SURVIVOR_MESSAGE, "the fade and 'You were knocked out!'")
			_check(hud.knockout_overlay.tip_text() == KnockoutRules.TIPS[0].text, "the bed tip (no bed yet)")
			_check(ko.bags().size() == 1, "one bag")
			if ko.bags().is_empty():
				_finish()
				return
			_bag = ko.bags()[0]
			_check(_bag.items == [[BlockIds.PLANKS, 16], [BlockIds.DIRT, 8]], "the bag holds the blocks: %s" % [_bag.items])
			# The tools stay (and since owner #39 the universe's crystal too); only the blocks go into the bag
			_check(inv.has(ItemIds.SWORD) and inv.has(ItemIds.PICKAXE) and not inv.has(BlockIds.PLANKS) \
				and not inv.has(BlockIds.DIRT), "sword and pickaxe kept, the blocks in the bag: %s" % [inv.to_save()])
			_check(_bag.global_position.distance_to(_fell_at) < 2.5, "the bag lies where they fell")
			Session.hurt_player(p.peer_id, 5, _fell_at)
			_check(p.health.hp == 0 and ko.bags().size() == 1, "no more damage while down")
			_next(KnockoutRules.KO_TIME + 0.5)
		1:
			var c := p.world.spawn_column()
			_check(Vector2(p.global_position.x - c.x - 0.5, p.global_position.z - c.y - 0.5).length() < 1.0, "up again at the world spawn")
			_check(p.health.hp == Health.MAX_HP and hud.hearts.hp == Health.MAX_HP and not p.knocked_out, "full hearts, standing")
			_check(p.health.is_protected(), "protected after arriving")
			_check(not hud.knockout_overlay.is_down(), "the fade clears")
			sandbox.save_world()
			var meta := WorldSaves.load_meta(Game.slot())
			_check(meta.bags.size() == 1 and meta.bags[0].items == _bag.items, "the bag is in world.json")
			var stand := _view_spot(p.world, _bag.center())
			_check(stand.is_finite(), "a spot with a clear view of the bag")
			if not stand.is_finite():
				stand = _bag.global_position + Vector3(0, 0, 2.5)
			p.global_position = stand
			var d := _bag.center() - p.eye_position()
			p.rig.yaw = atan2(-d.x, -d.z)   # face the bag (forward is -Z turned by yaw)
			p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)
			if not p.rig.first_person:
				p.toggle_camera()   # the camera at the eye: nothing between it and the bag
			p.rig.snap_to_target()
			_next(0.6)
		2:
			var cam := p.camera()
			var interactor: BlockInteractor = p.get_node("BlockInteractor")
			var tapped := not cam.is_position_behind(_bag.center()) and interactor.place_at_screen(cam.unproject_position(_bag.center()))
			_check(tapped, "a tap on the bag")
			if not tapped:
				Session.request_take_bag(_bag.name)
			_check(inv.count(BlockIds.PLANKS) == 16 and inv.count(BlockIds.DIRT) == 8 and inv.has(ItemIds.SWORD) \
				and inv.has(ItemIds.PICKAXE), "every block back: %s" % [inv.to_save()])
			_check(ko.bags().is_empty(), "the bag is gone")
			_next(Health.PROTECTION)   # the protection after getting up runs out first
		3:
			Game.mode = ModeRules.SANDBOX   # the same world played by Sandbox rules
			_fell_at = p.global_position
			_before = inv.to_save()
			Session.hurt_player(p.peer_id, Health.MAX_HP, _fell_at)
			_check(p.knocked_out and hud.knockout_overlay.message() == KnockoutDirector.SANDBOX_MESSAGE, "Sandbox: 'Oops! Back on your feet!'")
			_check(ko.bags().is_empty() and inv.to_save() == _before, "Sandbox: no bag, nothing lost")
			_next(KnockoutRules.KO_TIME + 0.5)
		4:
			var moved := Vector2(p.global_position.x - _fell_at.x, p.global_position.z - _fell_at.z).length()
			_check(moved < 1.5 and p.health.hp == Health.MAX_HP and not p.knocked_out, "Sandbox: up on the spot (moved %.2f)" % moved)
			Game.mode = ModeRules.SURVIVOR
			_finish()


## Feet 2-3 blocks beside the bag, on the ground, with a clear line from the eye to `bag_center`
## (a bag on a slope can hide behind the hill from one side), or INF.
func _view_spot(world: WorldService, bag_center: Vector3) -> Vector3:
	var solid := func(cell: Vector3i) -> bool: return BlockIds.is_solid(world.get_block(cell))
	var base := Vector3i(bag_center.floor())
	for r: int in [2, 3]:
		for side: Vector3i in [Vector3i.BACK, Vector3i.FORWARD, Vector3i.LEFT, Vector3i.RIGHT]:
			var c := base + side * r
			var feet := Vector3(c.x + 0.5, SpawnRules.spawn_y(world.find_standing_y(c.x, c.z)), c.z + 0.5)
			var eye := feet + Vector3(0, CameraRig.HEAD_HEIGHT, 0)
			if absf(eye.y - bag_center.y) > 4.0:
				continue
			var hit := GridRay.cast(eye, bag_center - eye, eye.distance_to(bag_center), solid)
			if hit == null or hit.position == base:
				return feet
	return Vector3.INF


func _next(wait: float) -> void:
	_step += 1
	_wait = wait


func _check(ok: bool, what: String) -> void:
	print("KO_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("KO_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().quit(1 if not _fails.is_empty() else 0)
