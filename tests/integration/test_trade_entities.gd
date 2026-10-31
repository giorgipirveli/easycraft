extends GutTest
## Owner #37 (spec §14.23): a helper's stand and Nico's market cart are traders (the host's reach check, taps through
## Trader.find), cheap (shared meshes, one static body on the world layer) and say what they sell.


func _stand(u: int, at: Vector3) -> TraderStand:
	var s := TraderStand.new()
	s.setup({"pos": at, "yaw": 0.0, "universe": u})
	add_child_autofree(s)
	return s


func _cart(at: Vector3) -> MarketCart:
	var c := MarketCart.new()
	c.setup({"pos": at, "yaw": 0.0})
	add_child_autofree(c)
	return c


func _bodies(n: Node) -> Array:
	return n.find_children("*", "StaticBody3D", true, false)


func test_a_stand_is_a_trader_with_the_universes_things() -> void:
	var s := _stand(2, Vector3(5, 20, 5))
	assert_true(s.is_in_group(&"traders"))
	assert_true(s.is_in_group(&"stands"))
	assert_false(s.is_in_group(&"market_traders"), "a stand sells at Tilly's prices")
	assert_eq(s.shop_stock, StandRules.stock(2))
	assert_eq(s.shop_title, "Zara's stand")
	var labels := s.find_children("*", "Label3D", true, false).map(func(l: Node) -> String: return (l as Label3D).text)
	assert_has(labels, "Zara's stand")
	assert_false(s.hint_visible(), "no SHOP arrow over a stand")


func test_stands_share_one_mesh_per_universe_and_have_one_small_body() -> void:
	var a := _stand(3, Vector3(0, 20, 0))
	var b := _stand(3, Vector3(10, 20, 0))
	var c := _stand(4, Vector3(20, 20, 0))
	var mesh_of := func(n: Node) -> Mesh: return (n.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	assert_same(mesh_of.call(a), mesh_of.call(b))
	assert_ne(mesh_of.call(a), mesh_of.call(c), "each universe its colours")
	assert_eq(_bodies(a).size(), 1)
	assert_eq((_bodies(a)[0] as StaticBody3D).collision_layer, Player.WORLD_COLLISION_MASK)


func test_a_tap_finds_a_stand_like_tilly() -> void:
	var s := _stand(2, Vector3(0, 20, -4))
	var eye := Vector3(0, 21.6, 0)
	var chest := s.global_position + Vector3(0, TraderRules.CHEST_HEIGHT, 0)
	assert_eq(Trader.find(get_tree(), eye, (chest - eye).normalized(), eye), s)


func test_nicos_cart_is_a_market_trader_that_waves() -> void:
	var c := _cart(Vector3(0, 20, 0))
	assert_true(c.is_in_group(&"traders"))
	assert_true(c.is_in_group(&"market_traders"))
	assert_true(c.market)
	assert_eq(c.shop_stock, MarketRules.stock())
	assert_eq(c.shop_title, MarketRules.SHOP_TITLE)
	assert_eq(_bodies(c).size(), 1)
	var c2 := _cart(Vector3(10, 20, 0))
	var meshes := func(n: Node) -> Array: return n.find_children("*", "MeshInstance3D", true, false).map(
		func(m: Node) -> Mesh: return (m as MeshInstance3D).mesh)
	assert_eq(meshes.call(c), meshes.call(c2), "shared meshes")
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.viewer.free()
	p.set_physics_process(false)
	p.global_position = c.global_position + Vector3(0, 0, -4)
	p.visible = true   # a player waits hidden until it has spawned
	c._look_for_players()
	assert_true(c._greeting, "Nico waves at a child near the cart")
