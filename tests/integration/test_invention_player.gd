extends GutTest
## Owner #78 (spec §21e) on a real Player with real physics: in Survivor, flying needs a flying machine the child
## invented (FLY is refused, with words, until then); the kite lifts you for a moment on a windy hill and lets you down
## gently, never flying; the balloon flies free and slowly; the plane and the jet burn fuel (FlyCost's gold, the jet
## twice); the glider invented gives the glide without one in the bag; the Sandbox keeps its classic free flying and
## tries any machine; nothing with wings or a bag of hot air flies without air (the Moon). The machine shows on the
## body (FlightLook) and is synced.
class FlatWorld:
	extends WorldService

	var top := 10

	func get_block(p: Vector3i) -> int:
		return BlockIds.STONE if p.y < top else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return top

	func is_area_ready(_center: Vector3) -> bool:
		return true


const LOW := 10
const HILL := MeadowsShape.SEA_LEVEL + 14

var world: FlatWorld
var player: Player
var _said: Array[String] = []
var _mode_before: StringName
var _universe_before := 1
var _gold_before := 0
var _inventions_before: InventionData


func before_each() -> void:
	_mode_before = Game.mode
	_universe_before = Game.universe
	_gold_before = Profile.data.survivor_gold
	_inventions_before = Profile.data.inventions
	Profile.data.inventions = InventionData.new()
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 1
	_said = []
	Session.magic_feedback.connect(_on_said)


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_said)
	Input.action_release(&"fly_up")
	Input.action_release(&"move_forward")
	Game.mode = _mode_before
	Game.universe = _universe_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.inventions = _inventions_before
	Session.fly_reset()
	Session.register_world(null)


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_said(text: String) -> void:
	_said.append(text)


func _invent(upto: StringName) -> void:
	for id in InventionLine.ORDER:
		Profile.data.inventions.add(id)
		if id == upto:
			return


func _setup(top: int = LOW) -> void:
	world = FlatWorld.new()
	world.top = top
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 10, 400)
	shape.shape = box
	shape.position = Vector3(0, top - 5, 0)
	ground.add_child(shape)
	world.add_child(ground)
	Session.register_world(world)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)
	player.spawn_at(Vector3(0.5, top, 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 2.0, "spawned")
	await wait_physics_frames(10)


func test_survivor_needs_an_invention_to_fly() -> void:
	Profile.data.survivor_gold = 1000
	await _setup()
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.physics_mode, PhysicsMode.Mode.NORMAL, "nothing invented yet: no flying")
	assert_has(_said, Lang.t(InventionRules.NEED_WORDS), "the words say how to invent it")
	assert_eq(player.flight_craft, FlightCrafts.Craft.NONE)


func test_the_balloon_rises_slowly_and_flies_free() -> void:
	_invent(InventionLine.BALLOON)
	Profile.data.survivor_gold = 0
	await _setup()
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.physics_mode, PhysicsMode.Mode.FLY, "no gold needed: the burner's gas is free")
	assert_eq(player.flight_craft, FlightCrafts.Craft.BALLOON)
	var y0 := player.global_position.y
	Input.action_press(&"fly_up")
	await wait_physics_frames(120)
	Input.action_release(&"fly_up")
	var rose := player.global_position.y - y0
	assert_between(rose, 1.5, FlightCrafts.BALLOON_RISE * 2.0 + 1.0, "up slowly (%.1f blocks in 2 s)" % rose)
	for i in 60 * 7:
		Session.fly_tick(1.0 / 60.0)
	assert_eq(player.physics_mode, PhysicsMode.Mode.FLY, "never landed for gold")
	assert_eq(Profile.data.survivor_gold, 0)
	player.set_physics_mode(PhysicsMode.Mode.NORMAL)
	assert_eq(player.flight_craft, FlightCrafts.Craft.NONE, "out of the balloon")


func test_the_plane_burns_fuel_and_the_jet_twice_as_much() -> void:
	_invent(InventionLine.PLANE)
	Profile.data.survivor_gold = 100
	await _setup()
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.flight_craft, FlightCrafts.Craft.PLANE, "the newest machine")
	Session.fly_tick(0.016)
	assert_eq(Profile.data.survivor_gold, 100 - FlyCost.GOLD_PER_CHARGE, "the plane's fuel")
	player.set_physics_mode(PhysicsMode.Mode.NORMAL)
	Session.fly_reset()
	_invent(InventionLine.JET)
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.flight_craft, FlightCrafts.Craft.JET)
	Session.fly_tick(0.016)
	assert_eq(Profile.data.survivor_gold, 100 - 3 * FlyCost.GOLD_PER_CHARGE, "the jet burns twice as much")
	player.set_physics_mode(PhysicsMode.Mode.NORMAL)
	Profile.data.survivor_gold = 1
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.physics_mode, PhysicsMode.Mode.NORMAL, "1 gold is not a jet's fuel")
	assert_has(_said, InventionRules.fuel_words(FlightCrafts.Craft.JET, 1))
	Profile.data.inventions.craft = InventionLine.BALLOON
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.flight_craft, FlightCrafts.Craft.BALLOON, "the machine picked in the book")


func test_the_plane_flies_fast() -> void:
	_invent(InventionLine.PLANE)
	Profile.data.survivor_gold = 100
	await _setup()
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	Input.action_press(&"move_forward")
	await wait_physics_frames(150)
	var flat := Vector2(player.velocity.x, player.velocity.z).length()
	assert_almost_eq(flat, FlightCrafts.PLANE_TOP, 1.0, "faster than the classic flying (%.1f m/s)" % flat)


func test_the_kite_needs_a_windy_hill() -> void:
	_invent(InventionLine.KITE)
	await _setup(LOW)
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.physics_mode, PhysicsMode.Mode.NORMAL)
	assert_has(_said, Lang.t(InventionRules.KITE_HILL_WORDS))
	assert_eq(player.flight_craft, FlightCrafts.Craft.NONE)


func test_the_kite_lifts_you_on_a_hill_and_lets_you_down_gently() -> void:
	_invent(InventionLine.KITE)
	await _setup(HILL)
	var y0 := player.global_position.y
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.physics_mode, PhysicsMode.Mode.NORMAL, "a kite never flies you")
	assert_eq(player.flight_craft, FlightCrafts.Craft.KITE, "the kite is up")
	var top := y0
	var fastest_down := 0.0
	for i in 150:
		await wait_physics_frames(1)
		if i % 10 == 5:
			player.set_physics_mode(PhysicsMode.Mode.FLY)   # FLY again and again: one lift until the feet land
		top = maxf(top, player.global_position.y)
		fastest_down = minf(fastest_down, player.velocity.y)
	assert_between(top - y0, 3.0, 9.0, "a short lift (%.1f blocks)" % (top - y0))
	assert_gte(fastest_down, -FlightCrafts.KITE_FALL - 0.01, "down gently")
	await wait_until(func() -> bool: return player.is_on_floor(), 5.0, "back on the hill")
	await wait_physics_frames(2)
	assert_eq(player.flight_craft, FlightCrafts.Craft.NONE, "the kite comes down with you")


func test_the_glider_invented_is_never_lost() -> void:
	await _setup()
	assert_false(player.has_glider(), "Survivor: no glider in the bag")
	_invent(InventionLine.GLIDER)
	assert_true(player.has_glider(), "invented: the glide, in every world")


func test_the_sandbox_keeps_free_flying_and_tries_any_machine() -> void:
	Game.mode = ModeRules.SANDBOX
	Profile.data.survivor_gold = 0
	await _setup()
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.physics_mode, PhysicsMode.Mode.FLY, "free flying, nothing invented")
	assert_eq(player.flight_craft, FlightCrafts.Craft.NONE, "the classic flying")
	player.set_physics_mode(PhysicsMode.Mode.NORMAL)
	player.chosen_craft = FlightCrafts.Craft.JET
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.flight_craft, FlightCrafts.Craft.JET, "trying the jet")


func test_no_air_no_wings() -> void:
	_invent(InventionLine.JET)
	Profile.data.survivor_gold = 100
	Game.universe = SpaceRules.MOON
	await _setup()
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(player.physics_mode, PhysicsMode.Mode.NORMAL)
	assert_has(_said, Lang.t(InventionRules.NO_AIR_WORDS))


func test_the_machine_shows_and_is_synced() -> void:
	_invent(InventionLine.BALLOON)
	await _setup()
	var cfg := (player.get_node("Sync") as MultiplayerSynchronizer).replication_config
	assert_true(cfg.has_property(NodePath(".:flight_craft")), "every game sees the machine")
	player.set_physics_mode(PhysicsMode.Mode.FLY)
	await wait_frames(2)
	var look := player.get_node_or_null("FlightLook") as FlightLook
	assert_not_null(look)
	assert_eq(look.shown(), FlightCrafts.Craft.BALLOON)
	player.flight_craft = 42
	await wait_frames(2)
	assert_eq(player.flight_craft, FlightCrafts.Craft.NONE, "a tampered number is none")
