extends Node
## The steps of tools/farm_smoke.gd (M3 Task 10), in a new Survivor world on real terrain, through the real
## systems (Session requests, the host's FarmDirector, the HUD, the world save): Tilly sells one farm; the FARM
## item placed on flat ground near the player builds the barn, its field and a worker; the barn's floor holds a
## player inside; a tap on the barn opens its panel and FASTER buys a second worker; leaving inside the farm is
## saved; the world started again "3 hours later" (the away record moved back on disk) pays 3 h at 30 an hour
## with the banner and the coin shower, once; a clock that went backwards pays nothing. It ends with the cost
## of the workers' animation step.

const TIMEOUT := 240.0
const HOUR := 3600
const SEARCH_SECONDS := 40.0

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _gold := 0
var _farm_pos := Vector3i.ZERO
var _welcomes: Array = []
var _showers := 0
var _banner := ""
var _stand := Vector3.ZERO
var _next_try := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 1
	Game.start_new_world = true
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--smoke-seed="):
			Game.new_world_seed = int(arg.trim_prefix("--smoke-seed="))
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	_step_t += delta
	var scene := get_tree().current_scene
	if _step in [6, 9]:   # at the menu between two plays of the world
		_run_step(scene, null, delta)
		return
	if scene == null or scene.get("player") == null or not (scene.player as Player).is_spawned():
		return
	_run_step(scene, scene.player, delta)


func _run_step(sandbox: Node, p: Player, _delta: float) -> void:
	match _step:
		0:
			var farm: FarmDirector = sandbox.get("_farm")
			_check(farm != null and farm.is_inside_tree() and farm.name == "Farm", "the world has its FarmDirector")
			_check(not farm.has_farm(), "no farm yet")
			_check((sandbox.meta as WorldMeta).has_trader(), "Tilly stands in the world")
			Profile.data.survivor_gold = 1000
			_next()
		1:   # buy a farm from Tilly (next to her stall)
			var meta: WorldMeta = sandbox.meta
			var world: WorldService = sandbox.world
			var t := meta.trader_pos + Vector3(0, 0, 2.5)
			p.global_position = Vector3(t.x, world.find_standing_y(floori(t.x), floori(t.z)), t.z)
			var said: Array = []
			var hear := func(ok: bool, text: String, _id: int, _count: int, gold: int) -> void: said.append([ok, text, gold])
			Session.trade_done.connect(hear)
			Session.request_trade(true, ItemIds.FARM, 1)
			Session.request_trade(true, ItemIds.FARM, 1)
			Session.trade_done.disconnect(hear)
			_check(said.size() == 2 and said[0][0] and said[0][1] == "You got a Gold Farm!", "Tilly sold a farm: %s" % [said])
			_check(said.size() == 2 and not said[1][0] and said[1][1] == ShopRules.message("have_it"), "one at a time")
			_check(Session.inventory_of(p.peer_id).count(ItemIds.FARM) == 1, "the FARM item is in the bag")
			_check(Profile.data.survivor_gold == 1000 - FarmRules.PRICE, "it cost %d gold (%d left)" % [FarmRules.PRICE, Profile.data.survivor_gold])
			_next()
		2:   # place it on flat ground near the player, like a stamp (the ground around streams in meanwhile)
			if _step_t < _next_try:
				return
			var world: WorldService = sandbox.world
			var last := _step_t > SEARCH_SECONDS
			var anchor := _flat_spot(world, Vector3i(p.global_position.floor()), last)
			if anchor == Vector3i(-99999, 0, 0) and not last:
				_next_try = _step_t + 1.0
				return
			_check(anchor != Vector3i(-99999, 0, 0), "found flat, open ground for a farm near %s (%.0f s)" % [Vector3i(p.global_position), _step_t])
			if anchor == Vector3i(-99999, 0, 0):
				_finish()
				return
			p.global_position = Vector3(anchor) + Vector3(0.5, 0, 3.5)
			p.rig.yaw = 0.0   # looking down -Z: the farm reaches that way, its door looks back
			var interactor: BlockInteractor = p.get_node("BlockInteractor")
			var said: Array[String] = []
			var hear := func(text: String) -> void: said.append(text)
			Session.magic_feedback.connect(hear)
			interactor._place_farm(BlockHit.new(anchor + Vector3i.DOWN, anchor, 3.0))
			Session.magic_feedback.disconnect(hear)
			var farm: FarmDirector = sandbox.get("_farm")
			_check(farm.has_farm(), "the farm stands at %s (%s)" % [anchor, said])
			if not farm.has_farm():
				_finish()
				return
			_farm_pos = farm.farm.pos
			_check(farm.building != null and farm.building.is_inside_tree(), "the barn and its field are there")
			_check(farm.building.workers.size() == 1, "one worker")
			_check(Session.inventory_of(p.peer_id).count(ItemIds.FARM) == 0, "the item is used up")
			_check(said.has(FarmDirector.BUILT_TEXT), "the child is told how it works")
			_next()
		3:   # into the barn: its floor holds the player
			if _step_t < 0.5:
				return
			var farm: FarmDirector = sandbox.get("_farm")
			_stand = farm.building.global_transform * Vector3(-2.0, 0.05, -1.0)
			p.global_position = _stand
			p.velocity = Vector3.ZERO
			_next()
		4:
			if _step_t < 1.9:   # the fall settles; the workers wake near the player (looked at 4 times a second)
				return
			var farm: FarmDirector = sandbox.get("_farm")
			_check(absf(p.global_position.y - _stand.y) < 0.6, "standing in the barn (y %.2f, floor %.2f)" % [p.global_position.y, _stand.y])
			_check(FarmSite.is_inside(farm.farm, p.global_position), "inside the farm")
			_check(farm.building.working, "the workers work while the player is near")
			# A tap on the barn from the yard opens its panel; FASTER buys a second worker.
			var eye := farm.building.global_transform * Vector3(-2.0, 1.6, FarmBuilding.BARN_HI.z + 3.0)
			var wall := farm.building.global_transform * Vector3(-2.0, 1.5, FarmBuilding.BARN_HI.z)
			_check(FarmBuilding.find(get_tree(), eye, (wall - eye).normalized(), eye) == farm.building, "a tap on the barn finds it")
			var hud: Hud = sandbox.hud
			var interactor: BlockInteractor = p.get_node("BlockInteractor")
			interactor.farm_tapped.emit(farm.building)
			_check(hud.farm_panel.visible, "its panel opens")
			_check(hud.farm_panel.rate_text() == "20 an hour" and hud.farm_panel.cap_text() == "Holds 12 hours",
				"it shows %s, %s" % [hud.farm_panel.rate_text(), hud.farm_panel.cap_text()])
			_gold = Profile.data.survivor_gold
			hud.farm_panel.faster_button.pressed.emit()
			_check(Profile.data.survivor_gold == _gold - 200, "FASTER cost 200 (%d left)" % Profile.data.survivor_gold)
			_check(farm.building.workers.size() == 2, "a second worker")
			_check(hud.farm_panel.rate_text() == "30 an hour", "the panel shows the new rate")
			hud.farm_panel.close()
			_next()
		5:   # leave inside the farm (in the field), saved; then back to the menu
			var farm: FarmDirector = sandbox.get("_farm")
			p.global_position = farm.building.global_transform * Vector3(2.5, 0.05, 0.0)
			sandbox.call(&"save_world")
			var meta := WorldSaves.load_meta(Game.slot())
			_check(meta.farm.get("pos") == _farm_pos and int(meta.farm.get("rate", -1)) == 1, "the farm is in world.json: %s" % [meta.farm])
			_check(meta.farm.has("away"), "leaving inside it is saved")
			_gold = Profile.data.survivor_gold
			sandbox.call(&"_save_and_quit")
			_next()
		6:   # at the menu: 3 hours pass (the record moves back), and the world starts again
			var scene := get_tree().current_scene
			if scene == null or scene.scene_file_path != Game.MENU_SCENE or _step_t < 1.0:
				return
			_move_away_record(-3 * HOUR)
			Game.start_world(ModeRules.SURVIVOR, false)
			_next()
		7:
			if _step_t < 0.2:
				return
			var farm: FarmDirector = sandbox.get("_farm")
			if not farm.welcomed.is_connected(_on_welcome):
				farm.welcomed.connect(_on_welcome)
			if _welcomes.is_empty():
				if _step_t > 15.0:
					_check(false, "the welcome-back came")
					_finish()
				return
			_banner = (sandbox.hud as Hud).banner.showing()
			_showers = get_tree().root.get_children().filter(func(n: Node) -> bool:
				return n is CPUParticles3D and (n as CPUParticles3D).mesh == Fx.coin_mesh()).size()
			_check(_welcomes == [[90, false]], "the welcome-back paid 3 h at 30 an hour: %s" % [_welcomes])
			_check(Profile.data.survivor_gold == _gold + 90, "the gold arrived (%d)" % Profile.data.survivor_gold)
			_check(_banner == "Your farm made 90 gold!", "the banner says it: '%s'" % _banner)
			_check(_showers == 1, "a coin shower (%d)" % _showers)
			_check(not WorldSaves.load_meta(Game.slot()).farm.has("away"), "saved at once: it pays once")
			_check(farm.building != null and farm.building.workers.size() == 2, "the farm came back with its two workers")
			_gold = Profile.data.survivor_gold
			_next()
		8:   # stand outside, then leave; a clock that went backwards pays nothing
			var farm: FarmDirector = sandbox.get("_farm")
			p.global_position = farm.building.global_transform * Vector3(2.5, 0.05, 0.0)
			sandbox.call(&"save_world")
			_welcomes.clear()
			sandbox.call(&"_save_and_quit")
			_next()
		9:
			var scene := get_tree().current_scene
			if scene == null or scene.scene_file_path != Game.MENU_SCENE or _step_t < 1.0:
				return
			_move_away_record(5 * HOUR)   # "left" 5 hours from now: the phone's clock went back
			Game.start_world(ModeRules.SURVIVOR, false)
			_next()
		10:
			if _step_t < 0.2:
				return
			var farm: FarmDirector = sandbox.get("_farm")
			if not farm.welcomed.is_connected(_on_welcome):
				farm.welcomed.connect(_on_welcome)
			if _welcomes.is_empty():
				if _step_t > 15.0:
					_check(false, "the welcome-back came (backwards clock)")
					_finish()
				return
			_check(_welcomes == [[0, false]], "a clock that went backwards paid nothing: %s" % [_welcomes])
			_check(Profile.data.survivor_gold == _gold, "and took nothing (%d)" % Profile.data.survivor_gold)
			_next()
		11:   # MOVE: the farm goes back in the bag with its levels
			var farm: FarmDirector = sandbox.get("_farm")
			p.global_position = farm.building.global_transform * Vector3(-2.0, 0.05, FarmBuilding.BARN_HI.z + 2.5)
			var hud: Hud = sandbox.hud
			(p.get_node("BlockInteractor") as BlockInteractor).farm_tapped.emit(farm.building)
			_check(hud.farm_panel.visible and hud.farm_panel.move_button.visible, "the owner's panel has MOVE")
			hud.farm_panel.move_button.pressed.emit()
			_check(not farm.has_farm() and farm.farm == {"packed": true, "rate": 1, "cap": 0}, "picked up: %s" % [farm.farm])
			_check(Session.inventory_of(p.peer_id).count(ItemIds.FARM) == 1, "the FARM item is back in the bag")
			_next()
		12:
			if _step_t < 0.3:
				return
			var farm: FarmDirector = sandbox.get("_farm")
			_check(not is_instance_valid(farm.building), "the barn is gone")
			var anchor := _flat_spot(sandbox.world, Vector3i(p.global_position.floor()), true)
			p.global_position = Vector3(anchor) + Vector3(0.5, 0, 3.5)
			p.rig.yaw = 0.0
			(p.get_node("BlockInteractor") as BlockInteractor)._place_farm(BlockHit.new(anchor + Vector3i.DOWN, anchor, 3.0))
			_check(farm.has_farm() and int(farm.farm.rate) == 1 and farm.building.workers.size() == 2,
				"placed again at %s with its level and two workers" % anchor)
			_cost(farm)
			_finish()


func _on_welcome(gold: int, capped: bool) -> void:
	_welcomes.append([gold, capped])


## Moves the saved away record by `seconds` from now (a stand-in for time passing while the game was closed).
func _move_away_record(seconds: int) -> void:
	var meta := WorldSaves.load_meta(Game.slot())
	_check(not meta.farm.is_empty(), "world.json has the farm")
	meta.farm = FarmRules.left_inside(meta.farm, int(Time.get_unix_time_from_system()) + seconds, false)
	WorldSaves.save_meta(Game.slot(), meta)


## A flat, open spot near `feet` whose farm (door facing +Z) FarmSite accepts, the anchor cell; or x -99999.
func _flat_spot(world: WorldService, feet: Vector3i, report: bool) -> Vector3i:
	var why := {}
	for r in range(4, 48, 2):
		for i in 24:
			var a := TAU * i / 24.0
			var x := feet.x + roundi(cos(a) * r)
			var z := feet.z + roundi(sin(a) * r)
			var y := world.find_standing_y(x, z)
			var anchor := Vector3i(x, y, z)
			var center := FarmSite.center_for(anchor, 0)
			if not world.is_area_ready(Vector3(center)):
				why["not loaded"] = int(why.get("not loaded", 0)) + 1
				continue
			var box: Array = FarmSite.box(center)
			var no := FarmSite.refusal(center, 0, world.box_reader(box[0], box[1]))
			if no == "":
				return anchor
			why[no] = int(why.get(no, 0)) + 1
	if report:
		print("FARM_SMOKE no spot: %s (seed %d)" % [why, WorldSaves.load_meta(Game.slot()).seed])
	return Vector3i(-99999, 0, 0)


## The workers' animation step, three workers working: microseconds a frame (this thread).
func _cost(farm: FarmDirector) -> void:
	var b := farm.building
	b.show_levels(FarmRules.new_farm(b.farm.pos, int(b.farm.facing), 3, 0))
	var t0 := Time.get_ticks_usec()
	for i in 600:
		for w in b.workers:
			w.step(1.0 / 60.0)
	var per_frame := float(Time.get_ticks_usec() - t0) / 600.0
	print("FARM_SMOKE cost workers=%d step_us_per_frame=%.1f load=%s" % [b.workers.size(), per_frame, _load()])


func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"


func _next() -> void:
	_step += 1
	_step_t = 0.0
	_next_try = 0.0


func _check(ok: bool, what: String) -> void:
	print("FARM_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("FARM_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
