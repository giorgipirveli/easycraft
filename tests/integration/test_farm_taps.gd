extends GutTest
## M3 Task 10: the Gold Farm through the player's hands and the HUD. The FARM item in the hand places the farm
## like a stamp (the host decides: Session.farm_place_requested with the tapped cell and the door facing the
## child); a tap on the barn opens its panel whatever is in the hand, not from far away; the HUD's farm panel
## is an overlay under the palette that closes the others; the welcome-back shows the exact gold in a banner
## with a coin shower, and nothing for 0.

var _player: Player
var _interactor: BlockInteractor
var _farm: FarmBuilding
var _asked: Array = []


func before_each() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	_player.world = world
	add_child_autofree(_player)
	_player.viewer.free()
	_player.set_physics_process(false)
	_player.rig.process_mode = Node.PROCESS_MODE_DISABLED   # the test aims the camera
	_player._spawned = true
	_interactor = _player.get_node("BlockInteractor")
	_farm = FarmBuilding.new()
	add_child_autofree(_farm)
	_farm.setup(FarmRules.new_farm(Vector3i(0, 30, 0), 0))
	_asked.clear()
	Session.farm_place_requested.connect(_on_place)


func after_each() -> void:
	Session.farm_place_requested.disconnect(_on_place)


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_place(peer_id: int, anchor: Vector3i, facing: int) -> void:
	_asked.append([peer_id, anchor, facing])


## Aims the camera from `feet` at the barn's front wall.
func _look_at_barn_from(feet: Vector3) -> Vector2:
	_player.global_position = feet
	var wall := _farm.global_transform * Vector3(-2.0, 1.4, FarmBuilding.BARN_HI.z)
	_player.camera().look_at_from_position(_player.eye_position(), wall)
	return _interactor.get_viewport().get_visible_rect().size * 0.5


func test_a_tap_on_the_barn_opens_its_panel() -> void:
	var center := _look_at_barn_from(Vector3(-1.5, 30, 5.5))
	watch_signals(_interactor)
	assert_true(_interactor.place_at_screen(center))
	assert_signal_emitted_with_parameters(_interactor, "farm_tapped", [_farm])


func test_even_with_a_sword_in_hand() -> void:
	_interactor.hotbar[0] = ItemIds.SWORD
	_interactor.select_slot(0)
	var center := _look_at_barn_from(Vector3(-1.5, 30, 5.5))
	watch_signals(_interactor)
	_interactor.place_at_screen(center)
	assert_signal_emitted(_interactor, "farm_tapped", "a tap on the barn is its panel, not a swing")


func test_a_tap_from_far_away_does_not() -> void:
	var center := _look_at_barn_from(Vector3(-1.5, 30, 16))
	watch_signals(_interactor)
	_interactor.place_at_screen(center)
	assert_signal_not_emitted(_interactor, "farm_tapped")


func test_the_farm_item_asks_the_host_to_place_it_facing_the_child() -> void:
	_player.rig.yaw = 0.0   # looking down -Z
	assert_true(_interactor._place_farm(BlockHit.new(Vector3i(4, 29, -6), Vector3i(4, 30, -6), 3.0)))
	assert_eq(_asked, [[multiplayer.get_unique_id(), Vector3i(4, 30, -6), FarmSite.facing_for_forward(Vector3i(0, 0, -1))]])
	assert_eq(FarmSite.door_dir(int(_asked[0][2])), Vector2i(0, 1), "the door looks back at the child")


func test_the_hud_opens_the_farm_panel_over_the_others() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(_player, "Kid", false, false)
	var director := FarmDirector.new()
	add_child_autofree(director)
	hud.add_farm_controls(director)
	assert_lt(hud.farm_panel.get_index(), hud.palette.get_index(), "the block palette overlay stays on top")
	assert_true(hud.look_area.blockers.has(hud.farm_panel), "a tap on the panel never builds")
	hud.palette.open()
	_interactor.farm_tapped.emit(_farm)
	assert_true(hud.farm_panel.visible)
	assert_false(hud.palette.visible, "one overlay at a time")
	hud.farm_panel.close()


func test_the_welcome_back_shows_the_exact_gold_with_a_coin_shower() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(_player, "Kid", false, false)
	hud.add_secret_controls(null)   # the banner (the sandbox adds it)
	var before := get_tree().root.get_children().filter(func(n: Node) -> bool: return n is CPUParticles3D).size()
	hud.farm_welcome(0)
	assert_eq(hud.banner.showing(), "", "nothing made: nothing shown")
	hud.farm_welcome(240)
	assert_eq(hud.banner.showing(), "Your farm made 240 gold!")
	var showers := get_tree().root.get_children().filter(func(n: Node) -> bool:
		return n is CPUParticles3D and (n as CPUParticles3D).mesh == Fx.coin_mesh())
	assert_eq(showers.size(), 1, "one coin shower")
	assert_gt(get_tree().root.get_children().filter(func(n: Node) -> bool: return n is CPUParticles3D).size(), before)
	for s: Node in showers:
		s.free()


## Sandbox has no farm: its HUD makes no panel (Android Back, which looks at open panels, never stops at one).
func test_a_sandbox_hud_has_no_farm_panel() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(_player, "Kid", false, false)
	assert_null(hud.farm_panel)
	hud.open_farm(_farm, _farm.farm)   # nothing happens
	var loose := FarmPanel.new()
	assert_false(loose.visible, "hidden before it is in the tree")
	loose.free()

