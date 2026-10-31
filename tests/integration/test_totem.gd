extends GutTest
## M2 Task 9: the Monster Totem. Cheap (shared meshes, one shared glowing material, nothing made per
## Totem or per wave), solid like Tilly's stall, glowing while a wave runs, with a short line over it
## ("Wave 3", "5", "4 left", "Try again?"), and a tap within reach asks for the Totem's panel.


func _totem(pos: Vector3 = Vector3(0.5, 30, 0.5), yaw: float = 0.0) -> Totem:
	var t := Totem.new()
	t.setup({"pos": pos, "yaw": yaw})
	add_child_autofree(t)
	return t


func _state(phase: int, next: int = 1, wave: int = 0, left: int = 0, count: int = 0, lost: int = 0, boss: bool = false) -> Dictionary:
	return {"phase": phase, "next": next, "wave": wave, "left": left, "total": left, "count": count,
		"time_left": 0.0, "lost": lost, "boss": boss, "gentle": false}


func test_the_totem_stands_where_the_host_put_it() -> void:
	var t := _totem(Vector3(20.5, 31, -4.5), 1.2)
	assert_eq(t.name, "Totem")
	assert_eq(t.global_position, Vector3(20.5, 31, -4.5))
	assert_almost_eq(t.rotation.y, 1.2, 0.0001)
	assert_true(t.is_in_group(&"totems"))


func test_the_totem_is_cheap_and_shares_everything() -> void:
	var a := _totem()
	var b := _totem(Vector3(40.5, 30, 0.5))
	var meshes_a := a.find_children("*", "MeshInstance3D", true, false)
	var meshes_b := b.find_children("*", "MeshInstance3D", true, false)
	assert_lte(meshes_a.size(), 4, "a handful of draw calls")
	for i in meshes_a.size():
		assert_same((meshes_a[i] as MeshInstance3D).mesh, (meshes_b[i] as MeshInstance3D).mesh, "built once and shared")
	var mats := {}
	for mi: MeshInstance3D in meshes_a:
		for s in mi.mesh.get_surface_count():
			mats[mi.mesh.surface_get_material(s)] = true
	assert_true(mats.has(WeaponModels.material()), "the carved pole shares the weapons' material")
	assert_true(mats.has(Totem.glow_material()), "eyes and runes share one glowing material")
	assert_eq(mats.size(), 2)


func test_it_glows_while_a_wave_runs_without_making_anything_new() -> void:
	var t := _totem()
	var before := t.find_children("*", "", true, false).size()
	assert_false(t.glowing())
	t.show_state(_state(WaveDirector.Phase.RUNNING, 3, 3, 5))
	assert_true(t.glowing())
	assert_eq(t.find_children("*", "", true, false).size(), before, "no node made for the glow")
	t.show_state(_state(WaveDirector.Phase.IDLE, 4))
	assert_false(t.glowing())
	t.show_state(_state(WaveDirector.Phase.COUNTDOWN, 4, 4, 11, 5))
	assert_true(t.glowing(), "from the countdown on")
	t.show_state(_state(WaveDirector.Phase.BOSS, 6))
	assert_true(t.glowing(), "and while the boss fights")


func test_the_line_over_the_totem_says_what_is_going_on() -> void:
	var t := _totem()
	t.show_state(_state(WaveDirector.Phase.IDLE, 3))
	assert_eq(t.label_text(), "Wave 3")
	t.show_state(_state(WaveDirector.Phase.COUNTDOWN, 3, 3, 9, 4))
	assert_eq(t.label_text(), "4")
	t.show_state(_state(WaveDirector.Phase.RUNNING, 3, 3, 7))
	assert_eq(t.label_text(), "7 left")
	t.show_state(_state(WaveDirector.Phase.IDLE, 3, 0, 0, 0, 3))
	assert_eq(t.label_text(), "Try again?")
	t.show_state(_state(WaveDirector.Phase.IDLE, 6, 0, 0, 0, 0, true))
	assert_eq(t.label_text(), "Wave 6 or the Golem!")


func test_players_bump_into_it() -> void:
	var t := _totem()
	var bodies := t.find_children("*", "StaticBody3D", true, false)
	assert_eq(bodies.size(), 1)
	var body := bodies[0] as StaticBody3D
	assert_eq(body.collision_layer, Player.WORLD_COLLISION_MASK, "on the world layer")
	assert_eq(body.collision_mask, 0)


func test_it_is_about_as_tall_as_its_tap_box() -> void:
	var t := _totem()
	var box := AABB()
	for mi: MeshInstance3D in t.find_children("*", "MeshInstance3D", true, false):
		box = box.merge(t.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb())
	assert_between(box.size.y, WaveRules.HEIGHT - 0.6, WaveRules.HEIGHT + 0.8)
	assert_between(box.size.x, 1.6, 3.2, "fits its 3 x 3 flat spot")


func test_find_needs_reach_a_clear_view_and_a_quiet_totem() -> void:
	var t := _totem(Vector3(0.5, 30, 0.5))
	var eye := Vector3(0.5, 31.6, -3.0)
	var dir := Vector3(0, 0, 1)
	assert_same(Totem.find(get_tree(), eye, dir, eye), t)
	var wall := func(_from: Vector3, _dir: Vector3, _d: float) -> bool: return true
	assert_null(Totem.find(get_tree(), eye, dir, eye, wall), "not through blocks")
	var far := Vector3(0.5, 31.6, -10.0)
	assert_null(Totem.find(get_tree(), far, dir, far), "not from far away")
	t.show_state(_state(WaveDirector.Phase.RUNNING, 1, 1, 5))
	assert_null(Totem.find(get_tree(), eye, dir, eye), "during a wave a tap is a swing, not the panel")


# --- A tap through the player's camera ---

func _tap_setup() -> Array:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p.viewer.free()
	p.set_physics_process(false)
	p.rig.process_mode = Node.PROCESS_MODE_DISABLED
	p._spawned = true
	return [p, p.get_node("BlockInteractor")]


func _look_from(p: Player, feet: Vector3, at: Vector3) -> Vector2:
	p.global_position = feet
	p.camera().look_at_from_position(p.eye_position(), at)
	return p.get_viewport().get_visible_rect().size * 0.5


func test_a_tap_on_the_totem_asks_for_its_panel_whatever_is_in_the_hand() -> void:
	var t := _totem(Vector3(0.5, 30, 0.5))
	var pi := _tap_setup()
	var p: Player = pi[0]
	var interactor: BlockInteractor = pi[1]
	interactor.hotbar[0] = ItemIds.SWORD
	interactor.select_slot(0)
	var center := _look_from(p, Vector3(0.5, 30, -3.0), t.global_position + Vector3(0, 1.5, 0))
	watch_signals(interactor)
	assert_true(interactor.place_at_screen(center))
	assert_signal_emitted_with_parameters(interactor, "totem_tapped", [t])


func test_a_tap_from_far_away_does_not() -> void:
	var t := _totem(Vector3(0.5, 30, 0.5))
	var pi := _tap_setup()
	var p: Player = pi[0]
	var interactor: BlockInteractor = pi[1]
	var center := _look_from(p, Vector3(0.5, 30, -12.0), t.global_position + Vector3(0, 1.5, 0))
	watch_signals(interactor)
	interactor.place_at_screen(center)
	assert_signal_not_emitted(interactor, "totem_tapped")
