extends GutTest
## M3 Task 4 (spec §14.1, §5.3, §5.9): the Candy Kingdom's boss through the BossDirector. With the world's boss
## set to the Cake Monster, the Totem's fight brings a CakeMonster with its team-sized health; the HUD bar names
## it and shows its face; a win says "You beat the Cake Monster!", pays and resets the help like the Golem's.
## Since owner 39 the Dragon Realm (universe 5) follows it on the ladder: its boss opens the portal there, and the
## realm's own boss opens the rainbow portal to the portal hub with the grand celebration; beating it in Survivor
## earns every player the cosmic outfit (AvatarCatalog.EARN_CAKE_MONSTER), never in Sandbox (/summon cake).

const FLOOR := 10
const TOTEM := Vector3(20.5, FLOOR, 3.5)
const COSMIC := "outfit.cosmic"

var _mode_before: StringName
var _universe_before := 1
var _gold_before := 0
var _unlocked_before := 1
var _cosmetics_before: Array[String] = []
var _toasts: Array = []


func before_each() -> void:
	_mode_before = Game.mode
	_universe_before = Game.universe
	_gold_before = Profile.data.survivor_gold
	_unlocked_before = Profile.data.universe_unlocked
	_cosmetics_before = Profile.data.cosmetics.duplicate()
	Profile.data.cosmetics.erase(COSMIC)
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 4
	Profile.data.universe_unlocked = 4
	_toasts.clear()
	Session.magic_feedback.connect(_on_toast)


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_toast)
	Game.mode = _mode_before
	Game.universe = _universe_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.universe_unlocked = _unlocked_before
	Profile.data.cosmetics = _cosmetics_before
	Session.survivor_reset()
	Music.reset()
	UniverseRegistry.reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_toast(text: String) -> void:
	_toasts.append(text)


func _flat(p: Vector3i) -> int:
	return BlockIds.FROSTING if p.y < FLOOR else BlockIds.AIR


func _director(kind: StringName = BossRules.CAKE) -> BossDirector:
	var d := BossDirector.new()
	d.name = "Boss"
	d.block_at = _flat
	d.boss_kind = kind
	d.pay_gold = func(_peer: int, _amount: int) -> void: pass
	d.celebrate = func() -> void: pass
	var bar := BossBar.new()
	add_child_autofree(bar)
	d.bar = bar
	add_child_autofree(d)
	return d


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _win(d: BossDirector) -> void:
	var g := d.golem()
	g.start_phase(CakeRules.Phase.WALK)
	for i in 4:
		if is_instance_valid(g) and not g.is_down():
			g.start_phase(CakeRules.Phase.WALK)
			g.take_hit(100000, TOTEM, Vector3.ZERO)
	await get_tree().process_frame
	d.tick(0.016)


func test_the_candy_totem_brings_the_cake_monster() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	assert_eq(d.start(TOTEM), "")
	var g := d.golem()
	assert_true(g is CakeMonster, "the world's boss")
	assert_eq(g.max_hp, CakeRules.max_hp(1))
	d.tick(0.016)
	assert_eq(d.bar.title(), CakeRules.TITLE)
	assert_eq(d.bar.face(), BossRules.CAKE, "the bar shows the cake's face")
	assert_eq(d.start(TOTEM), "The Cake Monster is already here!", "one at a time, by its name")


## Owner 39: the Candy Kingdom is no longer the last universe: its boss opens the portal to the Dragon Realm (universe 5),
## whose own boss portal leads to the hub with the grand celebration.
func test_a_win_names_it_and_opens_the_portal_to_the_dragon_realm() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	await _win(d)
	assert_eq(d.bar.title(), CakeRules.WIN_MESSAGE)
	assert_eq(d.help.losses, 0, "the help resets after a win")
	assert_eq(d.portals().size(), 1, "a portal opens by the Totem")
	var portal := d.portals()[0]
	assert_eq(portal.target, 5, "universe 4 leads to universe 5, the Dragon Realm")
	assert_eq(portal.message(), "Walk in: Dragon Realm!")
	assert_true(portal.leads_somewhere(), "walking in travels there")
	assert_false(_toasts.has(CakeRules.GRAND_WIN), "the grand celebration waits for the last universe: %s" % [_toasts])
	assert_eq(Profile.data.universe_unlocked, 5, "the Dragon Realm is open")
	assert_eq(UniverseRegistry.hub_entries(Profile.data.universe_unlocked).size(), 5,
		"the hub lists every universe opened (the Glow Caves, 6, come after the Sky Dragon)")


## The portal a saved last-universe world (now the Glow Caves') restores leads to the hub; the kingdom's to the realm,
## the realm's to the caves.
func test_a_restored_portal_in_the_last_universe_leads_to_the_hub() -> void:
	var d := _director()
	d.restore(BossRules.new_help(), TOTEM + BossRules.PORTAL_OFFSET)
	assert_eq(d.portals()[0].target, 5, "the Candy Kingdom's leads to the Dragon Realm")
	Game.universe = 5
	var d5 := _director(BossRules.GOLEM)
	d5.restore(BossRules.new_help(), TOTEM + BossRules.PORTAL_OFFSET)
	assert_eq(d5.portals()[0].target, 6, "the Dragon Realm's leads to the Glow Caves")
	Game.universe = 6
	var d6 := _director(BossRules.GOLEM)
	d6.restore(BossRules.new_help(), TOTEM + BossRules.PORTAL_OFFSET)
	assert_eq(d6.portals()[0].target, UniverseRules.HUB, "the last universe's leads to the hub")
	Game.universe = 1
	var d1 := _director(BossRules.GOLEM)
	d1.restore(BossRules.new_help(), TOTEM + BossRules.PORTAL_OFFSET)
	assert_eq(d1.portals()[0].target, 2, "Green Meadows' still leads to universe 2")


func test_walking_into_the_hub_portal_opens_the_hub_panel() -> void:
	var hub := UniverseHub.new()
	add_child_autofree(hub)
	var ui := Control.new()
	add_child_autofree(ui)
	hub.setup_panel(ui)
	var travels: Array = []
	hub.travel = func(u: int) -> String:
		travels.append(u)
		return ""
	hub.portal_entered(UniverseRules.HUB)
	assert_true(hub.panel.visible, "the hub opens with every unlocked universe")
	assert_eq(travels, [], "nothing travels by itself: the child picks where")


func test_beating_it_in_survivor_earns_the_cosmic_outfit() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	assert_false(AvatarUnlocks.is_owned(COSMIC, Profile.data.cosmetics))
	await _win(d)
	assert_true(AvatarUnlocks.is_owned(COSMIC, Profile.data.cosmetics), "the cosmic outfit (legendary, earned)")
	assert_true(_toasts.any(func(t: String) -> bool: return t.contains("Cosmic")), "it says so: %s" % [_toasts])


func test_a_sandbox_cake_earns_nothing() -> void:
	Game.mode = ModeRules.SANDBOX
	Game.universe = 1
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director(BossRules.GOLEM)
	d.start(TOTEM, BossRules.CAKE)
	assert_true(d.golem() is CakeMonster, "/summon cake")
	await _win(d)
	assert_false(AvatarUnlocks.is_owned(COSMIC, Profile.data.cosmetics), "Sandbox does not unlock avatar items (§5.9)")


func test_summon_cake_is_a_sandbox_command() -> void:
	assert_eq(ChatCommands.parse("/summon cake").get("boss"), &"cake")
	assert_true(ChatCommands.suggestions("/summon ca").has("/summon cake"))
