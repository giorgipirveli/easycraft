extends GutTest
## Buddy playdates in a world (M4 Wave 3, agent I; research T4): the host's PlaydateDirector (at most 10
## decisions a second) walks two friends' buddies to each other and tells every game when they wave and
## dance (one reliable RPC each, never a stream); a buddy in a playdate walks to its spot instead of its
## owner; a buddy waiting in a showcase never follows anyone. Solo: this game is the host.


func _buddy(root: Node, buddy_name: String, owner: int, pos: Vector3) -> Buddy:
	var b := Buddy.new()
	b.setup({"flat": Buddy.pack({Vector3i.ZERO: BlockIds.RED, Vector3i(0, 1, 0): BlockIds.BLUE}), "name": buddy_name,
		"owner": owner, "pos": pos, "yaw": 0.0, "id": buddy_name})
	root.add_child(b)
	b.set_physics_process(false)   # stepped by hand where it matters
	return b


func _setup() -> Array:   # [director, root, a, b]
	var root := Node3D.new()
	add_child_autofree(root)
	var director := PlaydateDirector.new()
	director.buddies_root = root
	director.set_physics_process(false)
	add_child_autofree(director)
	var a := _buddy(root, "Blocky", 1, Vector3(0, 10, 0))
	var b := _buddy(root, "Sparkle", 2, Vector3(10, 10, 0))
	return [director, root, a, b]


func test_two_friends_buddies_wave_then_walk_to_each_other_and_dance() -> void:
	var s := _setup()
	var director: PlaydateDirector = s[0]
	var a: Buddy = s[2]
	var b: Buddy = s[3]
	director.step()
	assert_eq(director.shown, [["wave", "Blocky", "Sparkle"]], "every game waves (the RPC plays here too)")
	assert_eq(a.playdate_target, a.global_position, "they stand while they wave")
	director.clock = PlaydateRules.WAVE_TIME
	director.step()
	assert_eq(a.playdate_target, Vector3(5, 10, 0), "then walk to the middle")
	assert_eq(b.playdate_target, Vector3(5, 10, 0))
	a.global_position = Vector3(4.2, 10, 0)
	b.global_position = Vector3(5.8, 10, 0)
	director.clock += PlaydateRules.TICK
	director.step()
	assert_eq(director.shown.back(), ["dance", "Blocky", "Sparkle"], "together: the dance")
	director.clock += PlaydateRules.DANCE_TIME
	director.step()
	assert_eq(a.playdate_target, b.global_position, "then one follows the other a little")
	assert_false(b.playdate_target.is_finite(), "the other leads back to its owner")
	director.clock += PlaydateRules.FOLLOW_TIME
	director.step()
	assert_false(a.playdate_target.is_finite(), "back to its owner")
	assert_false(b.playdate_target.is_finite())


func test_a_buddy_on_a_playdate_walks_to_its_spot_not_its_owner() -> void:
	var s := _setup()
	var a: Buddy = s[2]
	var owner_at := Vector3(-7, 10, 2)
	assert_eq(a._goal(owner_at), owner_at, "no playdate: its owner")
	assert_eq(a._follow_distance(), Buddy.FOLLOW_DISTANCE)
	a.playdate_target = Vector3(3, 10, 3)
	assert_eq(a._goal(owner_at), Vector3(3, 10, 3))
	assert_lt(a._follow_distance(), Buddy.FOLLOW_DISTANCE, "it walks right up to the spot")


func test_only_different_owners_and_waiting_buddies_never_play() -> void:
	var s := _setup()
	var director: PlaydateDirector = s[0]
	var root: Node3D = s[1]
	(s[3] as Buddy).owner_peer = 1   # both mine
	director.step()
	assert_eq(director.shown, [])
	var visitor := _buddy(root, "Visitor", 3, Vector3(2, 10, 0))
	visitor.visiting = true
	director.step()
	assert_eq(director.shown, [], "a buddy waiting in a showcase is left alone")


func test_a_visiting_buddy_stands_and_waves_whoever_comes() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, 9.5, 0)
	root.add_child(floor_body)
	var b := _buddy(root, "Waiter", -1, Vector3(0, 10.05, 0))
	b.visiting = true
	b.set_physics_process(true)
	await wait_seconds(0.6)
	assert_lt(Vector2(b.global_position.x, b.global_position.z).length(), 0.2, "it stays")
	assert_almost_eq(b.global_position.y, 10.0, 0.2, "standing on the ground")
