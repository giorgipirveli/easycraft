extends GutTest
## M2 Task 1: the host decides every change of Survivor gold, inventories and health (solo play: this
## game is the host). Gold changes stay in memory; the world's save writes the profile.

var _gold_before := 0
var _mode_before: StringName
var _events: Array = []


func before_each() -> void:
	_gold_before = Profile.data.survivor_gold
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 30
	_events.clear()
	Session.gold_changed.connect(_on_gold)


func after_each() -> void:
	Session.difficulty = DifficultyRules.NORMAL
	Session.gold_changed.disconnect(_on_gold)
	Profile.data.survivor_gold = _gold_before
	Game.mode = _mode_before
	Session.survivor_reset()


func _on_gold(balance: int) -> void:
	_events.append(balance)


func test_the_host_adds_and_spends_the_local_players_gold() -> void:
	var me := multiplayer.get_unique_id()
	Session.gold_add(me, 12, "slime")
	assert_eq(Profile.data.survivor_gold, 42)
	assert_true(Session.gold_spend(me, 40))
	assert_eq(Profile.data.survivor_gold, 2)
	assert_false(Session.gold_spend(me, 3), "not enough: refused")
	assert_eq(Profile.data.survivor_gold, 2)
	assert_eq(_events, [42, 2], "the HUD hears each change")


func test_sandbox_gold_is_infinite_and_never_changes() -> void:
	Game.mode = ModeRules.SANDBOX
	var me := multiplayer.get_unique_id()
	Session.gold_add(me, 12, "slime")
	assert_true(Session.gold_spend(me, 999999), "Sandbox pays for anything")
	assert_eq(Profile.data.survivor_gold, 30, "and never touches Survivor gold")
	assert_eq(_events, [])


func test_bad_amounts_are_ignored() -> void:
	var me := multiplayer.get_unique_id()
	Session.gold_add(me, -50, "bug")
	assert_false(Session.gold_spend(me, -5), "spending a negative amount would mint gold")
	assert_eq(Profile.data.survivor_gold, 30)


func test_each_player_has_an_inventory_on_the_host() -> void:
	var me := multiplayer.get_unique_id()
	var inv := Inventory.starter_kit()
	Session.set_inventory(me, inv)
	assert_same(Session.inventory_of(me), inv)
	assert_eq(Session.inventory_of(424242).ids(), [] as Array[int], "a player without one gets an empty one")


func test_the_host_hurts_a_player_and_everyone_hears_it() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p.viewer.free()
	watch_signals(Session)
	Session.hurt_player(p.peer_id, 5, Vector3(1, 0, 0))
	assert_eq(p.health.hp, Health.MAX_HP - 5)
	assert_signal_emitted_with_parameters(Session, "player_hurt", [p.peer_id, Health.MAX_HP - 5, Vector3(1, 0, 0)])
	Session.hurt_player(p.peer_id, 0, Vector3.ZERO)
	Session.hurt_player(p.peer_id, -3, Vector3.ZERO)
	assert_eq(p.health.hp, Health.MAX_HP - 5, "no damage, no heal")


func test_the_host_regenerates_hearts_and_tells_everyone() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p.viewer.free()
	Session.hurt_player(p.peer_id, 4, Vector3.ZERO)
	watch_signals(Session)
	p.tick_health(Health.REGEN_DELAY + Health.REGEN_EVERY)
	assert_eq(p.health.hp, Health.MAX_HP - 3)
	assert_signal_emitted(Session, "player_hurt", "the HUD and other players hear the heal")


## M2 Task 17: the world's difficulty scales what monsters do (Cozy half, Brave half again).
func test_the_worlds_difficulty_scales_a_hit() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p.viewer.free()
	Session.difficulty = DifficultyRules.COZY
	Session.hurt_player(p.peer_id, 4, Vector3.INF)
	assert_eq(p.health.hp, Health.MAX_HP - 2, "Cozy: half")
	p.health = Health.new()   # full hearts, no protection
	Session.difficulty = DifficultyRules.BRAVE
	Session.hurt_player(p.peer_id, 4, Vector3.INF)
	assert_eq(p.health.hp, Health.MAX_HP - 6, "Brave: half again")
