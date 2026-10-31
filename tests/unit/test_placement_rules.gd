extends GutTest

var body: Array[AABB]


func before_each() -> void:
	body = [PlacementRules.player_aabb(Vector3(5.5, 10.0, 5.5))]


func test_rejects_place_overlapping_player() -> void:
	assert_false(PlacementRules.can_place(Vector3i(5, 10, 5), body, BlockIds.STONE), "feet")
	assert_false(PlacementRules.can_place(Vector3i(5, 11, 5), body, BlockIds.STONE), "head")


func test_allows_place_next_to_player() -> void:
	assert_true(PlacementRules.can_place(Vector3i(6, 10, 5), body, BlockIds.STONE))


func test_allows_place_under_feet() -> void:
	assert_true(PlacementRules.can_place(Vector3i(5, 9, 5), body, BlockIds.STONE), "touching is not overlapping")


func test_rejects_water_inside_player() -> void:
	assert_false(PlacementRules.can_place(Vector3i(5, 10, 5), body, BlockIds.WATER))


func test_rejects_air_and_invalid_ids() -> void:
	assert_false(PlacementRules.can_place(Vector3i(9, 9, 9), body, BlockIds.AIR))
	assert_false(PlacementRules.can_place(Vector3i(9, 9, 9), body, 999))


func test_checks_every_player() -> void:
	var two: Array[AABB] = [PlacementRules.player_aabb(Vector3(0.5, 0, 0.5)), PlacementRules.player_aabb(Vector3(20.5, 0, 0.5))]
	assert_false(PlacementRules.can_place(Vector3i(20, 1, 0), two, BlockIds.STONE))


func test_reach() -> void:
	assert_true(PlacementRules.in_reach(Vector3(0.5, 0.5, 0.5), Vector3i(9, 0, 0)))
	assert_false(PlacementRules.in_reach(Vector3(0.5, 0.5, 0.5), Vector3i(15, 0, 0)))


func test_validate_edit_break_in_reach() -> void:
	assert_true(PlacementRules.validate_edit(Vector3i(3, 10, 5), BlockIds.AIR, BlockIds.STONE, Vector3(5.5, 11.5, 5.5), body))


func test_validate_edit_rejects_far_edits() -> void:
	assert_false(PlacementRules.validate_edit(Vector3i(40, 10, 5), BlockIds.STONE, BlockIds.AIR, Vector3(5.5, 11.5, 5.5), body))


func test_validate_edit_rejects_place_in_body() -> void:
	assert_false(PlacementRules.validate_edit(Vector3i(5, 10, 5), BlockIds.STONE, BlockIds.AIR, Vector3(5.5, 11.5, 5.5), body))


func test_validate_edit_accepts_custom_reach() -> void:
	assert_false(PlacementRules.validate_edit(Vector3i(25, 10, 5), BlockIds.STONE, BlockIds.AIR, Vector3(5.5, 11.5, 5.5), body))
	assert_true(PlacementRules.validate_edit(Vector3i(25, 10, 5), BlockIds.STONE, BlockIds.AIR, Vector3(5.5, 11.5, 5.5), body, PlacementRules.BATCH_REACH))


func test_bedrock_cells_can_never_be_edited() -> void:
	var eye := Vector3(5.5, 11.5, 5.5)
	var cell := Vector3i(3, 10, 5)
	assert_false(PlacementRules.validate_edit(cell, BlockIds.AIR, BlockIds.BEDROCK, eye, body, PlacementRules.REACH), "break")
	assert_false(PlacementRules.validate_edit(cell, BlockIds.STONE, BlockIds.BEDROCK, eye, body, PlacementRules.BATCH_REACH), "overwrite")
	assert_true(PlacementRules.validate_edit(cell, BlockIds.AIR, BlockIds.DEEPSTONE, eye, body, PlacementRules.REACH))


## Deferred M1 minor: a refused edit used to fail silently. The host now tells the player why.
func test_refusals_come_with_a_friendly_reason() -> void:
	var eye := Vector3(5.5, 11.5, 5.5)
	assert_eq(PlacementRules.refusal(Vector3i(3, 10, 5), BlockIds.STONE, BlockIds.AIR, eye, body), "")
	assert_eq(PlacementRules.refusal(Vector3i(3, 10, 5), BlockIds.AIR, BlockIds.BEDROCK, eye, body, PlacementRules.REACH),
		PlacementRules.BEDROCK_MESSAGE)
	assert_eq(PlacementRules.refusal(Vector3i(40, 10, 5), BlockIds.STONE, BlockIds.AIR, eye, body), PlacementRules.TOO_FAR_MESSAGE)
	assert_eq(PlacementRules.refusal(Vector3i(5, 10, 5), BlockIds.STONE, BlockIds.AIR, eye, body), PlacementRules.BODY_MESSAGE)
	for msg: String in [PlacementRules.BEDROCK_MESSAGE, PlacementRules.TOO_FAR_MESSAGE, PlacementRules.BODY_MESSAGE]:
		assert_true(msg.length() > 0 and msg.length() <= 40, "short, friendly")


## Review M1: a caller that forgets the cell's current block must not compile, instead of passing
## it as AIR and letting bedrock be edited (fail closed).
func test_the_current_block_is_a_required_argument() -> void:
	var found := 0
	for m: Dictionary in (load("res://core/building/placement_rules.gd") as Script).get_script_method_list():
		if m.name != "validate_edit" and m.name != "refusal":
			continue
		found += 1
		var names: Array = (m.args as Array).map(func(a: Dictionary) -> String: return a.name)
		var required := names.size() - (m.default_args as Array).size()
		assert_between(names.find("current_id"), 0, required - 1, "%s: current_id has no default" % m.name)
	assert_eq(found, 2)
