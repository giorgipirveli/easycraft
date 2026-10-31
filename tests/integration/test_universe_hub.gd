extends GutTest
## M3 Task 5 (spec §14.1): the portal hub in a Survivor world — a stone circle by the spawn (standing
## stones and a swirling floor, shared meshes and one shared material); walking into it opens the hub
## panel with every unlocked universe (this one "You are here"); GO! travels, a refusal is said on the
## panel; walking out closes it and it opens again next time. The Stone Golem's portal leads to the
## next universe when it exists: its words say so, and walking into it travels there.

const FAKE := preload("res://tests/fakes/fake_universe.gd")
const FLOOR := 10
const CENTER := Vector3(20.5, FLOOR, 8.5)

var _unlocked := 1
var _universe := 1
var _mode: StringName
var _feet := Vector3.INF
var _travels: Array[int] = []
var _toasts: Array[String] = []
var _refuse := ""


func before_each() -> void:
	_unlocked = Profile.data.universe_unlocked
	_universe = Game.universe
	_mode = Game.mode
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 1
	Profile.data.universe_unlocked = 2
	UniverseRegistry.use(2, FAKE.new())
	_feet = Vector3.INF
	_travels.clear()
	_toasts.clear()
	_refuse = ""


func after_each() -> void:
	Profile.data.universe_unlocked = _unlocked
	Game.universe = _universe
	Game.mode = _mode
	UniverseRegistry.reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _shape() -> MeadowsShape:
	return FAKE.FlatShape.new(1)


func _hub() -> UniverseHub:
	var hub := UniverseHub.new()
	hub.player_position = func() -> Vector3: return _feet
	hub.travel = func(u: int) -> String:
		_travels.append(u)
		return _refuse
	hub.toast = func(t: String) -> void: _toasts.append(t)
	add_child_autofree(hub)
	var ui := Control.new()
	add_child_autofree(ui)
	hub.setup_panel(ui)
	var spot := {"pos": Vector3(CENTER.x, FAKE.HEIGHT, CENTER.z), "yaw": 0.3}
	hub.setup_circle(spot, _shape(), self)
	hub.set_process(false)
	return hub


func _step(hub: UniverseHub) -> void:
	hub.tick(UniverseHub.CHECK_EVERY + 0.01)


func _center(hub: UniverseHub) -> Vector3:
	return hub.circle.position


# --- The stone circle ---

func test_the_circle_is_standing_stones_round_a_swirling_floor_all_shared() -> void:
	var a := _hub()
	var b := _hub()
	assert_eq(a.circle.stone_count(), HubRules.STONES)
	assert_same(a.circle.stone_mesh(), b.circle.stone_mesh(), "one stone mesh for every circle")
	assert_same(a.circle.floor_material(), PortalSwirl.material(), "the portals' one swirl material")
	assert_same(a.circle.floor_material(), b.circle.floor_material())
	assert_eq(_center(a).y, float(FAKE.HEIGHT), "on the ground")


func test_walking_in_opens_the_hub_with_every_unlocked_universe() -> void:
	var hub := _hub()
	_feet = _center(hub) + Vector3(0.5, 0, 0.3)
	_step(hub)
	assert_true(hub.panel.visible)
	assert_eq(hub.panel.cards.size(), 2)
	var here := hub.panel.card_for(1)
	assert_true(here.here, "this world")
	assert_true(here.disabled)
	assert_eq(here.state_label.text, "You are here")
	assert_false(hub.panel.card_for(2).disabled)


func test_go_travels_and_a_refusal_is_said_on_the_panel() -> void:
	var hub := _hub()
	_feet = _center(hub)
	_step(hub)
	hub.panel.card_for(2).pressed.emit()
	assert_eq(_travels, [2] as Array[int])
	_refuse = UniverseRules.travel_message("friends")
	hub.panel.card_for(2).pressed.emit()
	assert_eq(hub.panel.hint(), _refuse)
	assert_true(hub.panel.visible, "stays open to try again")


func test_walking_out_closes_it_and_it_opens_again_next_time() -> void:
	var hub := _hub()
	_feet = _center(hub)
	_step(hub)
	hub.panel.close()
	_step(hub)
	assert_false(hub.panel.visible, "not again while still standing in it")
	_feet = _center(hub) + Vector3(HubRules.LEAVE + 1.0, 0, 0)
	_step(hub)
	_feet = _center(hub)
	_step(hub)
	assert_true(hub.panel.visible, "walked out and in again")
	_feet = _center(hub) + Vector3(HubRules.LEAVE + 1.0, 0, 0)
	_step(hub)
	assert_false(hub.panel.visible, "walking away closes it")


func test_flying_over_does_not_open_it() -> void:
	var hub := _hub()
	_feet = _center(hub) + Vector3(0, 6, 0)
	_step(hub)
	assert_false(hub.panel.visible)


func test_one_universe_says_how_to_open_the_next() -> void:
	Profile.data.universe_unlocked = 1
	var hub := _hub()
	_feet = _center(hub)
	_step(hub)
	assert_eq(hub.panel.cards.size(), 1)
	assert_eq(hub.panel.hint(), HubPanel.HINT_ONE)


func test_only_survivor_worlds_have_the_circle() -> void:
	assert_true(UniverseRules.wants_hub(ModeRules.SURVIVOR))
	assert_false(UniverseRules.wants_hub(ModeRules.SANDBOX))


# --- The Stone Golem's portal ---

func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _portal(target: int) -> DesertPortal:
	var p := DesertPortal.new()
	p.setup({"id": "portal", "pos": Vector3(0.5, FLOOR, 0.5), "yaw": 0.0, "target": target})
	add_child_autofree(p)
	return p


func test_the_golems_portal_names_the_next_universe() -> void:
	assert_eq(_portal(2).message(), "Walk in: Test Land!")
	UniverseRegistry.use(2, null)
	assert_eq(_portal(2).message(), "Sandstorm Desert opens in the next update!", "M2's words until it exists")
	Game.mode = ModeRules.SANDBOX
	UniverseRegistry.use(2, FAKE.new())
	assert_eq(_portal(2).message(), "Test Land waits in Survivor!")


func test_walking_into_the_portal_asks_to_travel_there_once() -> void:
	var portal := _portal(2)
	var entered: Array[int] = []
	portal.entered.connect(func(u: int) -> void: entered.append(u))
	var me := _player(Vector3(0.5, FLOOR, 4.0))
	await get_tree().physics_frame
	portal.tick(1.0)
	assert_eq(entered, [] as Array[int], "near, not in")
	me.global_position = Vector3(0.7, FLOOR, 0.6)
	await get_tree().physics_frame
	portal.tick(1.0)
	portal.tick(0.016)
	assert_eq(entered, [2] as Array[int], "once")
	me.global_position = Vector3(0.5, FLOOR, 5.0)
	await get_tree().physics_frame
	portal.tick(1.0)
	me.global_position = Vector3(0.5, FLOOR, 0.5)
	await get_tree().physics_frame
	portal.tick(1.0)
	assert_eq(entered, [2, 2] as Array[int], "again after stepping out")


func test_a_portal_to_a_universe_that_is_coming_does_not_ask() -> void:
	UniverseRegistry.use(2, null)
	var portal := _portal(2)
	var entered: Array[int] = []
	portal.entered.connect(func(u: int) -> void: entered.append(u))
	_player(Vector3(0.5, FLOOR, 0.5))
	await get_tree().physics_frame
	portal.tick(1.0)
	assert_eq(entered, [] as Array[int])


func test_the_boss_director_passes_a_walk_in_on_and_its_portal_leads_on_from_this_universe() -> void:
	Game.universe = 1
	var d := BossDirector.new()
	d.name = "Boss"
	d.block_at = func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR
	add_child_autofree(d)
	var got: Array[int] = []
	d.portal_entered.connect(func(u: int) -> void: got.append(u))
	d.restore(BossRules.new_help(), Vector3(3.5, FLOOR, 0.5))
	assert_eq(d.portals().size(), 1)
	var portal := d.portals()[0]
	assert_eq(portal.target, 2, "Green Meadows' portal leads to universe 2")
	portal.entered.emit(2)
	assert_eq(got, [2] as Array[int])
