extends GutTest
## Owner #110, VR round 4 idea 6 (VR-HANDS; the research §5.3 "The Giant's Table", R6): ModelViewRules. The Sandbox only;
## the child a giant 25 times their size; the little figure of them dropped on the model lands on the first block's top
## under it, and may go there when a child could stand there (room for the body, never a hiding spot, never where a
## game says no, within the model's loaded view); a two-hand twist turns the world in 45° steps, never smoothly.


## Grass under y 10; a pillar at (4, 10..12, 0); a barrel (a hiding spot) at (6, 10, 0); a roof at (8, 12, 0).
func _block_at(c: Vector3i) -> int:
	if c.y < 10:
		return BlockIds.GRASS
	if c.x == 4 and c.z == 0 and c.y <= 12:
		return BlockIds.STONE
	if c == Vector3i(6, 10, 0):
		return BlockIds.BARREL
	if c == Vector3i(8, 12, 0) or c == Vector3i(8, 11, 0):
		return BlockIds.STONE
	return BlockIds.AIR


func test_the_sandbox_only() -> void:
	assert_true(ModelViewRules.allowed(ModeRules.SANDBOX))
	assert_false(ModelViewRules.allowed(ModeRules.SURVIVOR), "R6: monsters do not wait for a giant")


func test_a_dropped_figure_lands_on_the_first_top_under_it() -> void:
	assert_eq(ModelViewRules.landing(Vector3(1.5, 30.0, 0.5), _block_at), Vector3(1.5, 10.0, 0.5), "on the grass")
	assert_eq(ModelViewRules.landing(Vector3(4.5, 30.0, 0.5), _block_at), Vector3(4.5, 13.0, 0.5), "on the pillar")
	assert_false(ModelViewRules.landing(Vector3(1.5, 5.0, 0.5), _block_at).is_finite(), "under the ground: nowhere")


func test_where_the_figure_may_go() -> void:
	var feet := Vector3(0.5, 10.0, 0.5)
	var no := Callable()
	var ok := ModelViewRules.check(feet, Vector3(1.5, 10.0, 0.5), 0.3, 2, _block_at, no)
	assert_eq(ok, "", "on the grass beside the child")
	assert_eq(ModelViewRules.check(feet, Vector3(4.5, 13.0, 0.5), 0.3, 2, _block_at, no), "", "on top of the pillar: fine")
	assert_eq(ModelViewRules.check(feet, Vector3.INF, 0.3, 2, _block_at, no), TeleportRules.NOWHERE)
	assert_eq(ModelViewRules.check(feet, Vector3(6.5, 11.0, 0.5), 0.3, 2, _block_at, no), TeleportRules.SPOT,
		"never onto a hiding spot")
	assert_eq(ModelViewRules.check(feet, Vector3(8.5, 10.0, 0.5), 0.3, 2, _block_at, no), TeleportRules.ROOM,
		"under a roof too low for the body")
	assert_eq(ModelViewRules.check(feet, Vector3(200.5, 10.0, 0.5), 0.3, 2, _block_at, no), TeleportRules.FAR,
		"past the model's loaded land")
	var race := func(_at: Vector3) -> bool: return true
	assert_eq(ModelViewRules.check(feet, Vector3(1.5, 10.0, 0.5), 0.3, 2, _block_at, race), TeleportRules.AREA,
		"a game says no")


func test_the_model_is_the_land_within_range_cut_by_the_far_plane() -> void:
	var far := ModelViewRules.far_plane(40.0)
	assert_almost_eq(sqrt(far * far - 40.0 * 40.0), ModelViewRules.RANGE, 0.001, "the ground cut RANGE blocks away")
	assert_gt(ModelViewRules.far_plane(0.0), 1.0)


func test_a_two_hand_twist_turns_in_45_degree_steps() -> void:
	assert_eq(ModelViewRules.twist_steps(deg_to_rad(20.0)), 0)
	assert_eq(ModelViewRules.twist_steps(deg_to_rad(50.0)), 1)
	assert_eq(ModelViewRules.twist_steps(deg_to_rad(-100.0)), -2)
	assert_eq(ModelViewRules.SCALE, 25.0, "a giant 25 times their size: 64 blocks round are a model 2.5 m across")
