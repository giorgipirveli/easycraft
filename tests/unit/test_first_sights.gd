extends GutTest
## The frame spikes (2026-09-30, docs/devlog/parts/frame-spikes.md): tools/first_sights.gd tells, in a probe run, which
## draws the camera sees for the first time and whether a quick child's warm-up had them ready (before the fix: the
## first world's part only; now: the world's own landing part, ShaderWarmup.world_part).

const FirstSights := preload("res://tools/first_sights.gd")


func _box_at(root: Node3D, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	mi.mesh = box
	mi.position = pos
	root.add_child(mi)
	return mi


func test_on_screen_is_in_the_frustum_within_the_far_plane_and_the_visibility_range() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var cam := Camera3D.new()
	cam.far = 200.0
	root.add_child(cam)
	var ahead := _box_at(root, Vector3(0, 0, -10))
	var behind := _box_at(root, Vector3(0, 0, 10))
	var too_far := _box_at(root, Vector3(0, 0, -400))
	var out_of_range := _box_at(root, Vector3(0, 0, -50))
	out_of_range.visibility_range_end = 30.0
	var planes := cam.get_frustum()
	assert_true(FirstSights.on_screen(ahead, cam, planes))
	assert_false(FirstSights.on_screen(behind, cam, planes), "behind the camera")
	assert_false(FirstSights.on_screen(too_far, cam, planes), "past the far plane")
	assert_false(FirstSights.on_screen(out_of_range, cam, planes), "past its visibility range")


func test_a_lamp_lights_what_its_range_reaches() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var near := _box_at(root, Vector3(0, 0, -3))
	var far := _box_at(root, Vector3(0, 0, -30))
	var lamp := OmniLight3D.new()
	lamp.omni_range = 5.0
	root.add_child(lamp)
	var lamps: Array[OmniLight3D] = [lamp]
	assert_true(FirstSights.lit_by(near, lamps))
	assert_false(FirstSights.lit_by(far, lamps))


func test_a_quick_child_s_warm_up_had_the_world_s_own_landing_ready_only_since_the_fix() -> void:
	var moon := {"phases": ["moon"], "shown": ["moon"], "at": "Secrets/Things/chest (treasure_chest.gd)"}
	assert_eq(FirstSights.warm_by_now(moon, false, SpaceRules.MOON, "blocky"), [false, true] as Array[bool],
		"the Moon's own draw: compiled in play before, behind its card now")
	var first_world := {"phases": ["new"], "shown": ["new"]}
	assert_eq(FirstSights.warm_by_now(first_world, false, 1, "blocky"), [true, true] as Array[bool])
	var play := {"phases": ["play"], "shown": ["play"]}
	assert_eq(FirstSights.warm_by_now(play, false, 1, "blocky"), [false, false] as Array[bool], "the rest waits")
	assert_eq(FirstSights.warm_by_now(moon, true, SpaceRules.MOON, "blocky"), [false, false] as Array[bool],
		"by a lamp: the rest's lanterns")
	assert_eq(FirstSights.warm_by_now(null, false, 1, "blocky"), [false, false] as Array[bool], "not in the census")
	var avatar := {"material": ShaderWarmup.describe(AvatarParts.material(Color.RED)), "instanced": false, "shadow": true,
		"phases": ["new"], "shown": ["new"]}
	assert_eq(FirstSights.warm_by_now(avatar, true, EarthRules.WONDERS, "blocky"), [false, true] as Array[bool],
		"the avatar by the player's own lantern: in every world's part now")
