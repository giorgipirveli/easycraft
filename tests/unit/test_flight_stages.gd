extends GutTest
## Owner #79 (spec §25.3, §21d.4): the rocket a mission hands the flight — {"destination", "cells" {Vector3i: block id,
## relative to the pad's corner, y up}, "stages" [[Vector3i, …] bottom first, …], "seats"} — as pure rules
## (RocketStages): a clean copy of whatever came in, its stages, where the child sits, where the engines fire, what
## lands, and the developer's test rockets.


func _cells(list: Array) -> Dictionary:
	var out := {}
	for c: Array in list:
		out[Vector3i(c[0], c[1], c[2])] = int(c[3])
	return out


func test_a_rocket_is_cleaned_of_what_it_cannot_draw() -> void:
	var r := RocketStages.normalize({"destination": SpaceRules.MOON, "cells": {Vector3i(0, 0, 0): BlockIds.STONE,
		Vector3i(0, 1, 0): 0, Vector3i(0, 2, 0): -3, "junk": BlockIds.STONE, Vector3(0, 3, 0): BlockIds.STONE},
		"stages": [], "seats": 0})
	assert_eq(r.cells, {Vector3i(0, 0, 0): BlockIds.STONE}, "air, bad ids and bad keys go")
	assert_eq(r.seats, 1, "a rocket always has the pilot's seat")
	assert_eq(r.destination, SpaceRules.MOON)
	assert_eq(RocketStages.stage_count(r), 1, "no stages given: one stage of everything")


func test_nothing_at_all_is_still_a_rocket_of_nothing() -> void:
	var r := RocketStages.normalize({})
	assert_eq(r.cells, {})
	assert_eq(RocketStages.stage_count(r), 0)
	assert_eq(r.destination, SpaceRules.MOON, "the Moon when no one says where")
	assert_true(RocketStages.is_empty(r))


func test_stages_are_read_bottom_first_and_every_cell_belongs_to_one() -> void:
	var cells := _cells([[0, 0, 0, BlockIds.IRON], [0, 1, 0, BlockIds.STONE], [0, 2, 0, BlockIds.GLASS],
		[0, 3, 0, BlockIds.RED], [0, 4, 0, BlockIds.RED]])
	# Given top first, with a cell left out and one that does not exist.
	var r := RocketStages.normalize({"cells": cells, "stages": [[Vector3i(0, 2, 0), Vector3i(0, 3, 0),
		Vector3i(5, 5, 5)], [Vector3i(0, 0, 0), Vector3i(0, 1, 0)], []], "seats": 2, "destination": SpaceRules.MARS})
	assert_eq(RocketStages.stage_count(r), 2, "the empty stage goes")
	assert_eq(RocketStages.stage_cells(r, 0).keys().size(), 2, "the bottom stage first")
	assert_true(RocketStages.stage_cells(r, 0).has(Vector3i(0, 0, 0)))
	assert_true(RocketStages.stage_cells(r, 1).has(Vector3i(0, 4, 0)), "a cell in no stage joins the nearest one")
	assert_false(RocketStages.stage_cells(r, 1).has(Vector3i(5, 5, 5)), "a stage cell with no block goes")
	assert_eq(r.seats, 2)


func test_the_rocket_s_axis_is_the_middle_of_its_footprint_at_the_bottom() -> void:
	var cells := _cells([[0, 0, 0, 1], [2, 0, 0, 1], [1, 5, 1, 1], [0, 0, 2, 1]])
	assert_eq(RocketStages.bounds(cells), AABB(Vector3(0, 0, 0), Vector3(3, 6, 3)))
	assert_eq(RocketStages.pivot(cells), Vector3(1.5, 0.0, 1.5))
	assert_eq(RocketStages.bounds({}), AABB())


func test_the_child_sits_in_the_top_stage_one_below_its_nose() -> void:
	var r := RocketStages.test_rocket(SpaceRules.MOON)
	var top := RocketStages.stage_cells(r, RocketStages.stage_count(r) - 1)
	var b := RocketStages.bounds(top)
	var seat := RocketStages.seat(r)
	assert_almost_eq(seat.y, b.end.y - 1.5, 0.001, "in the capsule, under the nose")
	assert_almost_eq(seat.x, RocketStages.pivot(r.cells).x, 0.001, "on the rocket's axis")
	var one := RocketStages.normalize({"cells": {Vector3i(4, 7, 4): BlockIds.GLASS}})
	assert_eq(RocketStages.seat(one), Vector3(4.5, 7.5, 4.5), "a one-block rocket: inside that block")


func test_engines_fire_from_each_stage_s_bottom_layer() -> void:
	var r := RocketStages.test_rocket(SpaceRules.MOON)
	for i in RocketStages.stage_count(r):
		var cells := RocketStages.stage_cells(r, i)
		var low := int(RocketStages.bounds(cells).position.y)
		var nozzles := RocketStages.nozzles(r, i)
		assert_false(nozzles.is_empty(), "stage %d has somewhere to fire from" % i)
		for c: Vector3i in nozzles:
			assert_eq(c.y, low, "the stage's lowest layer")
			assert_true(cells.has(c))


func test_what_lands_is_the_top_stage() -> void:
	var r := RocketStages.test_rocket(SpaceRules.MARS, 3)
	assert_eq(RocketStages.stage_count(r), 3)
	assert_eq(RocketStages.lander(r), RocketStages.stage_cells(r, 2))
	assert_eq(RocketStages.flying_after(r, 1).size(), RocketStages.stage_cells(r, 1).size() + RocketStages.stage_cells(r, 2).size(),
		"after the first stage falls away, the rest flies on")


func test_the_test_rockets_are_real_rockets_of_blocks_that_exist() -> void:
	for stages in [1, 2, 3]:
		var r := RocketStages.test_rocket(SpaceRules.MOON, stages)
		assert_eq(RocketStages.stage_count(r), stages)
		assert_gt(r.cells.size(), 10 * stages, "a rocket, not a stick")
		for id: int in r.cells.values():
			assert_true(BlockIds.is_valid(id), "block %d exists" % id)
		var b := RocketStages.bounds(r.cells)
		assert_gt(b.size.y, b.size.x, "taller than wide")
		assert_eq(b.position, Vector3.ZERO, "from the pad's corner")
	var parts := RocketStages.test_rocket(SpaceRules.MOON, 2, true)
	for id: int in parts.cells.values():
		assert_between(id, RocketStages.PART_IDS_FIRST, RocketStages.PART_IDS_FIRST + 15,
			"the missions' part ids (page 32) as plain numbers")


func test_a_huge_rocket_is_cut_never_a_hang() -> void:
	var cells := {}
	for y in 80:
		for x in 8:
			for z in 8:
				cells[Vector3i(x, y, z)] = BlockIds.STONE
	var r := RocketStages.normalize({"cells": cells})
	assert_lte(r.cells.size(), RocketStages.MAX_CELLS)
	assert_eq(int(RocketStages.bounds(r.cells).position.y), 0, "the bottom stays: it is cut from the top")


## Owner #87: a landing on its own (the Star Map's LAND) flies a small lander.
func test_the_default_lander_is_one_small_stage() -> void:
	var r := RocketStages.default_lander(SpaceRules.MERCURY)
	assert_eq(RocketStages.stage_count(r), 1)
	assert_eq(r.destination, SpaceRules.MERCURY)
	assert_eq(RocketStages.bounds(r.cells).size, Vector3(5, 4, 5))
	assert_eq(RocketStages.lander(r), r.cells)
	for id: int in r.cells.values():
		assert_true(BlockIds.is_valid(id))
