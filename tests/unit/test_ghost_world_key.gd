extends GutTest
## M4 ghost races key a child's ghosts by this world on this device (its save slot and seed). A LAN guest has no
## WorldMeta (the host keeps the world), so its game has no key; found by owner #37's LAN trade run, where the guest
## stopped with "Invalid access to property or key 'seed' on a base object of type 'Nil'" in gh_world_key.


func _sandbox() -> Node:
	return load("res://scenes/sandbox.gd").new()


func test_a_guest_without_the_worlds_meta_has_no_world_key() -> void:
	var s := _sandbox()
	s.meta = null
	assert_eq(s.gh_world_key(), "")
	s.free()


func test_the_host_keys_ghosts_by_slot_and_seed() -> void:
	var s := _sandbox()
	var m := WorldMeta.new()
	m.seed = 42
	s.meta = m
	s._slot = "sandbox"
	assert_eq(s.gh_world_key(), "sandbox:42")
	s.free()
