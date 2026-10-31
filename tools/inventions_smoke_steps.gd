extends Node
## The steps of tools/inventions_smoke.gd (owner #78, spec §21e), on real terrain through the real systems: the
## sandbox's Inventions node (the book, MAKE IT through the host's bag and wallet, TRY IT from the child's body), the
## Player's flying (InventionRules' gates, FlightCrafts' machines, the host's fuel), the Mission Board's gate.

const TIMEOUT := 300.0
const SEED := 12345

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _wait := 0.0
var _fails: Array[String] = []
var _scene: Node
var _said: Array[String] = []
var _y0 := 0.0
var _top := 0.0
var _fastest := 0.0
var _gold0 := 0
var _survivor_done := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot: String in ["sandbox_1", "survivor_1"]:
		WorldSaves.delete(slot)
	Profile.data.inventions = InventionData.new()
	Profile.data.survivor_gold = 1000
	Session.magic_feedback.connect(func(text: String) -> void: _said.append(text))
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.COZY, 1)
	print("INVENT_SMOKE begin")


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
		_wait = 1.5   # a new world: let it settle
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, sandbox.player)


## An air cell with solid ground under it and air above, `r` blocks from the feet.
func _free_cell(world: WorldService, feet: Vector3i, r: int) -> Vector3i:
	for d: Vector3i in [Vector3i(r, 0, 0), Vector3i(-r, 0, 0), Vector3i(0, 0, r), Vector3i(0, 0, -r)]:
		for dy in range(-2, 4):
			var c := feet + d + Vector3i(0, dy, 0)
			if world.get_block(c) == BlockIds.AIR and world.get_block(c + Vector3i.UP) == BlockIds.AIR \
					and BlockIds.is_solid(world.get_block(c + Vector3i.DOWN)):
				return c
	return feet + Vector3i(r, 0, 0)


func _stock(inv: Inventory, id: StringName) -> void:
	for n: Array in InventionLine.entry(id).needs:
		inv.add(int(InventionLine.MATERIALS[n[0]].ids[0]), int(n[1]))


func _run_step(sandbox: Node, p: Player) -> void:
	if _survivor_done:
		_sandbox_step(sandbox, p)
		return
	var world: WorldService = sandbox.get("world")
	var hud: Hud = sandbox.get("hud")
	var inv := Session.inventory_of(p.peer_id)
	var inventions: InventionsDirector = sandbox.get("inventions")
	var book: InventionsPanel = inventions.panel if inventions else null
	match _step:
		0:
			_check(inventions != null and sandbox.get_node_or_null("Inventions") == inventions, "the Inventions node")
			if inventions == null:
				_finish()
				return
			var names: Array[String] = []
			for b in hud.more.buttons():
				names.append(b.text)
			_check(names.has("INVENT"), "INVENT in MORE: %s" % [names])
			_check(InputMap.has_action("inventions") and KeysRules.key_text("inventions") == "I", "I opens it on a PC")
			_check(inventions.survivor and inventions.host, "Survivor, the host's own world")
			_check(str(sandbox.call(&"mission_gate")) == Lang.t(InventionRules.MISSIONS_WORDS),
				"the Launch Site's missions wait for the rocket")
			_said.clear()
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			_check(p.physics_mode == PhysicsMode.Mode.NORMAL, "nothing invented: no flying")
			_check(_said.has(Lang.t(InventionRules.NEED_WORDS)), "the words say how: %s" % [_said])
			_next()
		1:   # the book: the kite first; MAKE IT needs a Workbench
			(sandbox.get("invent_button") as TouchButton).pressed.emit()
			_check(book.is_open() and book.shown == InventionLine.KITE, "INVENT opens the book on the kite")
			_check(book.make_button.visible, "MAKE IT")
			for id: int in [ItemIds.STICK, BlockIds.SAIL, BlockIds.RED, BlockIds.PLANKS]:
				inv.take(id, inv.count(id))
			_stock(inv, InventionLine.KITE)
			book.refresh()
			_check(book.need_lines() == (["Sticks 4/4", "Cloth 3/3"] as Array[String]), "have / need: %s" % [book.need_lines()])
			book.make_button.pressed.emit()
			_check(book.message() == "Stand next to a Workbench to make it!", "a Workbench first: %s" % book.message())
			inv.add(BlockIds.CRAFTING_TABLE, 1)
			var table := _free_cell(world, Vector3i(p.global_position.floor()), 2)
			Session.request_set_block(table, BlockIds.CRAFTING_TABLE)
			_check(world.get_block(table) == BlockIds.CRAFTING_TABLE, "a Workbench placed at %s" % table)
			_gold0 = Profile.data.survivor_gold
			book.make_button.pressed.emit()
			_check(Profile.data.inventions.has(InventionLine.KITE), "the kite invented: %s" % book.message())
			_check(inv.count(ItemIds.STICK) == 0 and inv.count(BlockIds.SAIL) == 0, "its sticks and cloth were used")
			_check(Profile.data.survivor_gold == _gold0 - 10, "10 gold (%d -> %d)" % [_gold0, Profile.data.survivor_gold])
			_check(book.status(InventionLine.KITE) == &"invented" and book.try_button.visible, "Invented! TRY IT")
			book.close()
			_next()
		2:   # the kite lifts the child on high ground
			p.global_position += Vector3(0, 30, 0)
			p.velocity = Vector3.ZERO
			_y0 = p.global_position.y
			_top = _y0
			_fastest = 0.0
			_said.clear()
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			_check(p.physics_mode == PhysicsMode.Mode.NORMAL and p.flight_craft == FlightCrafts.Craft.KITE and p.kite_floating(),
				"the kite pulls the child up (never flying): %s" % [_said])
			_next()
		3:
			_top = maxf(_top, p.global_position.y)
			_fastest = minf(_fastest, p.velocity.y)
			if p.is_on_floor() or _step_t > 25.0:
				_check(_fastest >= -FlightCrafts.KITE_FALL - 0.05, "down gently (at most %.1f m/s)" % -_fastest)
				_check(_top - _y0 > 3.0, "a short lift: %.1f blocks up" % (_top - _y0))
				_check(p.is_on_floor(), "back on the ground")
				_next()
		4:   # the balloon: made, flies free, its TRY IT pays once
			if _step_t < 0.3:
				return   # a physics step after the landing
			_check(p.flight_craft == FlightCrafts.Craft.NONE, "the kite came down with the child")
			_stock(inv, InventionLine.BALLOON)
			var table := _near_table(world, p)
			_check(table, "still by the Workbench")
			var why := inventions.make(InventionLine.BALLOON)
			_check(why == "" and Profile.data.inventions.has(InventionLine.BALLOON), "the balloon invented (%s)" % why)
			_gold0 = Profile.data.survivor_gold
			inventions.open(InventionLine.BALLOON)
			book.try_button.pressed.emit()
			_check(p.physics_mode == PhysicsMode.Mode.FLY and p.flight_craft == FlightCrafts.Craft.BALLOON, "TRY IT: up in the balloon")
			_check(inventions.banner.visible and inventions.trial.active(), "the try's banner")
			_check(not book.is_open(), "the book steps aside")
			_y0 = p.global_position.y
			Input.action_press(&"fly_up")
			_next()
		5:
			if inventions.trial.active() and _step_t < 20.0:
				return
			Input.action_release(&"fly_up")
			_check(Profile.data.inventions.was_tried(InventionLine.BALLOON), "15 blocks up: done")
			_check(Profile.data.survivor_gold == _gold0 + EarnRules.INVENT_TRY_GOLD, "+%d gold once, no fuel (%d -> %d)" % [
				EarnRules.INVENT_TRY_GOLD, _gold0, Profile.data.survivor_gold])
			var sky := p.global_position.y - _y0
			_check(sky >= InventionTry.BALLOON_BLOCKS - 0.5, "it rose %.1f blocks" % sky)
			_next()
		6:   # the glider and the plane; the plane burns fuel
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			_ensure_table(world, p, inv)
			_stock(inv, InventionLine.GLIDER)
			_check(inventions.make(InventionLine.GLIDER) == "", "the glider invented")
			_check(p.has_glider(), "its glide, with no glider in the bag")
			_stock(inv, InventionLine.PLANE)
			_check(inventions.make(InventionLine.PLANE) == "", "the plane invented")
			_gold0 = Profile.data.survivor_gold
			_check(inventions.fly_with(InventionLine.PLANE) != "", "FLY WITH IT: the plane")
			_check(Profile.data.inventions.craft == InventionLine.PLANE, "the pick is saved")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			_check(p.flight_craft == FlightCrafts.Craft.PLANE, "FLY: in the plane")
			Input.action_press(&"move_forward")
			_next()
		7:
			if _step_t < 3.0:
				return
			Input.action_release(&"move_forward")
			var speed := Vector2(p.velocity.x, p.velocity.z).length()
			_check(speed > Player.FLY_SPEED, "fast (%.1f m/s)" % speed)
			_check(Profile.data.survivor_gold < _gold0, "the engine burns fuel (%d -> %d)" % [_gold0, Profile.data.survivor_gold])
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			_next()
		8:   # the jet and the rocket need kerosene; the rocket opens the missions
			if _step_t < 2.0 and not p.is_on_floor():
				return
			_stock(inv, InventionLine.JET)
			_ensure_table(world, p, inv)   # the plane flew the child away from the Workbench
			var jet := inventions.make(InventionLine.JET)
			_check(jet == "", "the jet invented (%s)" % jet)
			_stock(inv, InventionLine.ROCKET)
			_check(inventions.make(InventionLine.ROCKET) == "", "the rocket invented")
			_check(str(sandbox.call(&"mission_gate")) == "", "the Launch Site's missions are open")
			var site: LaunchDirector = sandbox.get("launch_site")
			if site != null and site.board != null:
				site.board.open()
				_check(site.board.message() == "", "the Mission Board no longer asks for the rocket")
				site.board.close()
			sandbox.call(&"save_world")
			Profile.save()
			var saved := ProfileData.from_json(FileAccess.get_file_as_string(Profile.PATH))
			_check(saved.inventions.has(InventionLine.ROCKET) and saved.inventions.was_tried(InventionLine.BALLOON),
				"profile.json keeps them: %s" % [saved.inventions.to_dict()])
			_survivor_done = true
			_step = 0
			_step_t = 0.0
			Game.new_world_seed = SEED
			Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)


## A Workbench within reach (another one placed by the feet when the child flew away from the last).
func _ensure_table(world: WorldService, p: Player, inv: Inventory) -> void:
	if _near_table(world, p):
		return
	inv.add(BlockIds.CRAFTING_TABLE, 1)
	var c := _free_cell(world, Vector3i(p.global_position.floor()), 2)
	Session.request_set_block(c, BlockIds.CRAFTING_TABLE)
	_check(_near_table(world, p), "another Workbench by the child at %s" % c)


func _near_table(_world: WorldService, p: Player) -> bool:
	return bool(Session.craft_stations_near(p.eye_position(), CraftRules.REACH).get(Recipes.TABLE, false))


func _sandbox_step(sandbox: Node, p: Player) -> void:
	var inventions: InventionsDirector = sandbox.get("inventions")
	var book: InventionsPanel = inventions.panel
	match _step:
		0:   # the classic free flying stays
			_check(not inventions.survivor, "the Sandbox")
			_check(str(sandbox.call(&"mission_gate")) == "", "the Sandbox's missions are open")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			_check(p.physics_mode == PhysicsMode.Mode.FLY and p.flight_craft == FlightCrafts.Craft.NONE, "free flying, as always")
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			inventions.open(InventionLine.JET)
			_check(not book.make_button.visible and book.try_button.visible and book.fly_button.visible,
				"to read and try: TRY IT, FLY WITH IT")
			book.try_button.pressed.emit()
			_check(p.physics_mode == PhysicsMode.Mode.FLY and p.flight_craft == FlightCrafts.Craft.JET, "TRY IT: in the jet")
			Input.action_press(&"move_forward")
			Input.action_press(&"fly_up")   # up over the hills
			_next()
		1:
			if _step_t < 3.0:
				return
			Input.action_release(&"move_forward")
			Input.action_release(&"fly_up")
			var speed := Vector2(p.velocity.x, p.velocity.z).length()
			_check(speed > FlightCrafts.PLANE_TOP, "the fastest (%.1f m/s)" % speed)
			_check(p.get_node_or_null("FlightLook") != null and (p.get_node("FlightLook") as FlightLook).shown() == FlightCrafts.Craft.JET,
				"the jet shows round the child")
			inventions.open(InventionLine.JET)
			book.free_button.pressed.emit()
			_check(p.flight_craft == FlightCrafts.Craft.NONE and p.physics_mode == PhysicsMode.Mode.FLY, "FREE FLYING: back to the classic")
			book.show_invention(InventionLine.ROCKET)
			book.try_button.pressed.emit()
			_check(book.bottle_open(), "the rocket's TRY IT: a bottle rocket")
			_gold0 = Profile.data.survivor_gold
			for i in 6:
				book.bottle.pump()
			var h := book.bottle.fire()
			_check(h >= InventionTry.BOTTLE_GOAL, "it flew %.0f m" % h)
			_check(Profile.data.inventions.was_tried(InventionLine.ROCKET), "done")
			_check(Profile.data.survivor_gold == _gold0 + EarnRules.INVENT_TRY_GOLD, "+%d gold into the profile" % EarnRules.INVENT_TRY_GOLD)
			sandbox.call(&"go_back")
			_check(book.is_open() and not book.bottle_open(), "Back: from the bottle rocket to the page")
			sandbox.call(&"go_back")
			_check(not book.is_open(), "Back again closes the book")
			_finish()


func _next(wait: float = 0.0) -> void:
	_step += 1
	_step_t = 0.0
	_wait = wait


func _check(ok: bool, what: String) -> void:
	print("INVENT_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("INVENT_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Input.action_release(&"fly_up")
	Input.action_release(&"move_forward")
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
