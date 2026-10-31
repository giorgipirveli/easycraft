extends GutTest
## Owner feedback #29 ("monsters we cannt kill i think and this is bug"): monsters could be defeated
## with a sword, but ATTACK did nothing unless the selected hotbar slot held a weapon, and on a phone
## the ATTACK button was not even shown then. The Sandbox's hotbar starts with no weapon, and in
## Survivor the selected slot moves to blocks while building. Now ATTACK always attacks: the weapon
## in the hand; else the best melee weapon in the hotbar (its slot is selected, so the child sees it
## come to hand); else fists (a small, quick punch through the same host-checked attack path).
## Real Player, BlockInteractor, WeaponUser, Session and CombatDirector; solo, so this game is the host.

## Nothing but air: the aim ray never stops at a block.
class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


var director: CombatDirector
var p: Player
var interactor: BlockInteractor
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	director = CombatDirector.new()
	director.name = "Combat"
	add_child_autofree(director)
	director.block_at = func(_c: Vector3i) -> int: return BlockIds.AIR
	var w := AirWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, 80, 0.5)
	interactor = p.get_node("BlockInteractor")
	interactor.hotbar = WorldMeta._default_hotbar()   # the Sandbox's: blocks, the wand and a stamp
	interactor.select_slot(2)                          # planks in the hand
	Session._last_attack.erase(p.peer_id)
	await wait_process_frames(2)                       # the camera rig takes its place


func after_each() -> void:
	Game.mode = _mode_before
	Session._last_attack.erase(multiplayer.get_unique_id())
	Session.set_inventory(multiplayer.get_unique_id(), Inventory.new())


## A level-3 goblin just in front of the player (it takes several hits).
func _goblin() -> Monster:
	var m := Monster.new()
	m.setup({"kind": MonsterRules.GOBLIN, "level": 3, "id": "atk_goblin", "pos": Vector3(0.5, 80, -0.9), "yaw": 0.0,
		"wild": true, "universe": 1})
	m.block_at = director.block_at
	add_child_autofree(m)
	return m


func test_the_sandbox_hotbar_has_no_weapon() -> void:
	for id in WorldMeta._default_hotbar():
		assert_false(WeaponRules.is_weapon(id), "the default hotbar holds %s" % ItemIds.display_name(id))


func test_attack_holding_planks_swings_the_best_weapon_in_the_hotbar() -> void:
	interactor.hotbar[5] = ItemIds.SWORD
	interactor.hotbar[6] = ItemIds.SWORD_STONE
	interactor.hotbar[7] = ItemIds.PICKAXE_STONE
	var g := _goblin()
	watch_signals(Session)
	interactor.weapons.attack_pressed()
	interactor.weapons.attack_released()
	assert_eq(interactor.selected_slot, 6, "the stone sword comes to hand")
	assert_eq(p.held_item, ItemIds.SWORD_STONE, "and is held right away")
	var params: Variant = get_signal_parameters(Session, "attack_requested")
	assert_eq(params[1] if params is Array else 0, ItemIds.SWORD_STONE, "the host resolves the stone sword")
	assert_eq(g.hp, g.max_hp - int(WeaponRules.stats(ItemIds.SWORD_STONE).damage), "the goblin is hit")


func test_attack_with_no_weapon_at_all_punches() -> void:
	var g := _goblin()
	watch_signals(Session)
	interactor.weapons.attack_pressed()
	interactor.weapons.attack_released()
	assert_eq(interactor.selected_slot, 2, "the planks stay in the hand")
	assert_signal_emitted(Session, "attack_requested", "the punch goes to the host like any attack")
	var params: Variant = get_signal_parameters(Session, "attack_requested")
	assert_eq(params[1] if params is Array else 0, WeaponRules.FISTS)
	assert_eq(g.hp, g.max_hp - int(WeaponRules.stats(WeaponRules.FISTS).damage), "a punch hits")


func test_a_weapon_in_the_hand_is_used_as_before() -> void:
	interactor.hotbar[4] = ItemIds.HAMMER
	interactor.hotbar[5] = ItemIds.SWORD_COSMIC
	interactor.select_slot(4)
	var g := _goblin()
	interactor.weapons.attack_pressed()
	assert_eq(interactor.selected_slot, 4, "the hammer stays in the hand")
	assert_eq(g.hp, maxi(g.max_hp - int(WeaponRules.stats(ItemIds.HAMMER).damage), 0))


func test_a_bow_is_never_picked_for_a_quick_attack() -> void:
	interactor.hotbar[5] = ItemIds.BOW_COSMIC
	interactor.weapons.attack_pressed()
	interactor.weapons.attack_released()
	assert_eq(interactor.selected_slot, 2, "no melee weapon: a punch, the bow stays in the hotbar")


func test_fists_are_quick_short_and_weak() -> void:
	var fists := WeaponRules.stats(WeaponRules.FISTS)
	assert_eq(fists.kind, WeaponRules.MELEE)
	for id in [ItemIds.SWORD, ItemIds.SPEAR, ItemIds.MACE, ItemIds.AXE, ItemIds.PICKAXE, ItemIds.HAMMER]:
		var w := WeaponRules.stats(id)
		assert_lt(int(fists.damage), int(w.damage), "weaker than the %s" % ItemIds.display_name(id))
		assert_lt(float(fists.reach), float(w.reach), "shorter than the %s" % ItemIds.display_name(id))
	assert_lte(float(fists.cooldown), float(WeaponRules.stats(ItemIds.SWORD).cooldown), "as quick as a sword")
	assert_false(ItemIds.is_hotbar_valid(WeaponRules.FISTS), "never an item in a hotbar or a bag")
	assert_true(BlockyAvatar.ARM_SWINGS.has(HeldItem.swing_name(WeaponRules.FISTS, 0)), "the arm punches")


func test_survivor_punches_without_owning_anything_but_swings_only_owned_weapons() -> void:
	Game.mode = ModeRules.SURVIVOR
	var peer := 770031
	Session.set_inventory(peer, Inventory.new())
	assert_true(Session.accept_attack(peer, WeaponRules.FISTS, Vector3.FORWARD, 1.0, 10000), "fists need nothing")
	assert_false(Session.accept_attack(peer, ItemIds.SWORD, Vector3.FORWARD, 1.0, 20000), "a sword it doesn't own")
	Session._last_attack.erase(peer)
	Session.set_inventory(peer, Inventory.new())


func test_survivor_building_with_planks_still_attacks_with_the_owned_sword() -> void:
	Game.mode = ModeRules.SURVIVOR
	Session.set_inventory(p.peer_id, Inventory.starter_kit())
	interactor.hotbar[0] = ItemIds.SWORD
	var g := _goblin()
	interactor.weapons.attack_pressed()
	interactor.weapons.attack_released()
	assert_eq(interactor.selected_slot, 0, "the sword comes to hand")
	assert_eq(g.hp, g.max_hp - int(WeaponRules.stats(ItemIds.SWORD).damage))


func test_best_melee_slot_prefers_the_strongest_hitter_per_second() -> void:
	var bar: Array[int] = [BlockIds.STONE, ItemIds.HAMMER, ItemIds.SWORD, ItemIds.BOW_COSMIC, ItemIds.WAND]
	assert_eq(WeaponRules.best_melee_slot(bar), 2, "a sword beats the slow hammer; bows are not melee")
	bar[4] = ItemIds.MACE_COSMIC
	assert_eq(WeaponRules.best_melee_slot(bar), 4, "a cosmic mace beats a wooden sword")
	assert_eq(WeaponRules.best_melee_slot([BlockIds.STONE, ItemIds.BOW] as Array[int]), -1, "none: fists")


# --- The ATTACK button on a phone (real touches pushed into the HUD's own viewport) ---

func _phone_hud() -> Hud:
	var view := SubViewport.new()
	view.size = Vector2i(1280, 720)
	add_child_autofree(view)
	var hud := Hud.new()
	view.add_child(hud)
	hud.setup(p, "Kid", true, false)
	await wait_process_frames(2)
	return hud


func _touch(hud: Hud, pos: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = pos
	t.pressed = pressed
	hud.get_viewport().push_input(t, true)


func test_the_attack_button_shows_on_a_phone_whatever_is_in_the_hand() -> void:
	var hud := await _phone_hud()
	assert_true(hud.attack_button.visible, "planks in the hand: ATTACK is there")
	interactor.select_slot(7)
	await wait_process_frames(1)
	assert_true(hud.attack_button.visible, "the wand in the hand: ATTACK is there")


func test_a_tap_on_attack_with_blocks_in_the_hand_punches() -> void:
	var hud := await _phone_hud()
	var g := _goblin()
	var at := hud.attack_button.get_global_rect().get_center()
	_touch(hud, at, true)
	_touch(hud, at, false)
	assert_eq(g.hp, g.max_hp - int(WeaponRules.stats(WeaponRules.FISTS).damage), "a tap of ATTACK punches the goblin")


## The lead could not see a throw on the emulator: ATTACK held with a finger for longer than
## WeaponRules.SPEAR_THROW_HOLD and lifted throws the spear; a quick tap thrusts.
func test_holding_the_attack_button_and_lifting_the_finger_throws_the_spear() -> void:
	interactor.hotbar[0] = ItemIds.SPEAR
	interactor.select_slot(0)
	var hud := await _phone_hud()
	var at := hud.attack_button.get_global_rect().get_center()
	watch_signals(Session)
	_touch(hud, at, true)
	await wait_seconds(WeaponRules.SPEAR_THROW_HOLD + 0.15)
	_touch(hud, at, false)
	assert_signal_emitted(Session, "spear_throw_requested", "held and lifted: thrown")
	assert_not_null(director.spear_of(p.peer_id), "the spear flies")
	assert_signal_not_emitted(Session, "attack_requested")


func test_a_quick_tap_on_the_attack_button_thrusts_the_spear() -> void:
	interactor.hotbar[0] = ItemIds.SPEAR
	interactor.select_slot(0)
	var hud := await _phone_hud()
	var at := hud.attack_button.get_global_rect().get_center()
	watch_signals(Session)
	_touch(hud, at, true)
	await wait_process_frames(2)
	_touch(hud, at, false)
	assert_signal_emitted(Session, "attack_requested", "a tap thrusts")
	assert_signal_not_emitted(Session, "spear_throw_requested")
