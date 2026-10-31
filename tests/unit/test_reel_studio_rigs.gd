extends GutTest
## Owner #94 and #96 (spec §5.12b, the Reel Studio, round 2: learning reels): the stage's rigs a teaching reel needs,
## all pure functions of the time like the rest of the studio (a seek shows the frame playing reaches):
## - a model can ride on another (`on`): a crate on a lever's plank, Earth on its tilted axis, a pin on a turning Earth;
## - a model can be stretched along its own axes (`stretch`, and `grow` along one `axis`): a rope, a thin plate;
## - an avatar walks (`legs`: legs and arms swing, or pull a rope leaning back);
## - an invisible mark (`mark`) a camera can ride with or look at, and a camera that keeps a model in its middle (`aim`);
## - the light can change (light and sun keys: a sunset), and a night sky;
## - blocks from shapes (`fill`: box, disc, cone, ball, cylinder; AIR carves a cutaway);
## - rain, a lava fountain, and an effect's own gravity.


func _plank() -> Dictionary:
	return {"id": "plank", "model": "blocks", "cells": [[0, 0, 0, "PLANKS"]], "at": [0, 1, 0], "moves": [
		{"do": "turn", "at": 1.0, "dur": 2.0, "to": [0, 0, -20]}]}


func _crate() -> Dictionary:
	return {"id": "crate", "model": "blocks", "cells": [[0, 0, 0, "BARREL"]], "on": "plank", "at": [-2, 0.5, 0]}


func _stage(models: Array) -> Dictionary:
	return {"sky": "day", "light": "day", "models": models, "camera": [{"at": 0, "pos": [0, 3, 12], "look": [0, 1, 0]}]}


# --- Riding on another model -----------------------------------------------------------------------------------------

func test_a_rider_goes_where_its_model_goes_and_turns_with_it() -> void:
	var stage := _stage([_plank(), _crate()])
	var crate := StudioRules.model(stage, "crate")
	assert_almost_eq(StudioMotion.world(stage, crate, 0.5).origin.distance_to(Vector3(-2, 1.5, 0)), 0.0, 0.0001,
		"at rest it sits on the plank, in the plank's own space")
	var tilted := StudioMotion.world(stage, crate, 3.0)
	var expect := Transform3D(Basis.from_euler(Vector3(0, 0, deg_to_rad(-20))), Vector3(0, 1, 0)) * Vector3(-2, 0.5, 0)
	assert_almost_eq(tilted.origin.distance_to(expect), 0.0, 0.0001, "the plank turned: the crate rose on its arc")
	assert_gt(tilted.origin.y, 1.5, "the load end lifts")
	assert_almost_eq(tilted.basis.get_euler().z, deg_to_rad(-20), 0.0001, "and it tilts with the plank")


func test_a_rider_hides_while_its_model_is_hidden() -> void:
	var plank := _plank()
	plank.moves = [{"do": "pop", "at": 2.0}]
	var stage := _stage([plank, _crate()])
	var crate := StudioRules.model(stage, "crate")
	assert_false(StudioMotion.shown(stage, crate, 1.0), "the plank has not popped in yet")
	assert_true(StudioMotion.shown(stage, crate, 3.0))


func test_a_rider_of_a_rider_follows_both() -> void:
	var pin := {"id": "pin", "model": "mark", "on": "crate", "at": [0, 1, 0]}
	var stage := _stage([_plank(), _crate(), pin])
	var crate := StudioMotion.world(stage, StudioRules.model(stage, "crate"), 3.0)
	assert_almost_eq(StudioMotion.world(stage, pin, 3.0).origin.distance_to(crate * Vector3(0, 1, 0)), 0.0, 0.0001)


func test_a_rider_does_not_take_its_model_s_stretch_or_size() -> void:
	var rope := {"id": "rope", "model": "blocks", "cells": [[0, -1, 0, "PLANKS"]], "at": [0, 4, 0], "size": 3,
		"stretch": [0.1, 1, 0.1]}
	var hook := {"id": "hook", "model": "mark", "on": "rope", "at": [1, 0, 0]}
	var stage := _stage([rope, hook])
	assert_almost_eq(StudioMotion.world(stage, hook, 0.0).origin.distance_to(Vector3(1, 4, 0)), 0.0, 0.0001)


func test_a_model_that_leaves_and_comes_back_is_its_full_size_again() -> void:
	# The review found the Moon's orbit line missing when it came back: its out had left its size at 0 under the pop
	# (the Reel Studio's orrery lines too).
	var m := {"id": "line", "model": "orbit_line", "radius": 10, "at": [0, 0, 0], "moves": [
		{"do": "out", "at": 20.0, "dur": 0.3}, {"do": "pop", "at": 40.0}]}
	assert_almost_eq(float(StudioMotion.state(m, 10.0).scale), 1.0, 0.0001)
	assert_almost_eq(float(StudioMotion.state(m, 30.0).scale), 0.0, 0.0001, "gone")
	assert_true(StudioMotion.state(m, 41.0).visible)
	assert_almost_eq(float(StudioMotion.state(m, 41.0).scale), 1.0, 0.0001, "back at its full size")


# --- Stretching --------------------------------------------------------------------------------------------------------

func test_a_stretch_scales_along_the_model_s_own_axes() -> void:
	var m := {"id": "rope", "model": "blocks", "cells": [[0, 0, 0, "PLANKS"]], "at": [0, 0, 0], "turn": [0, 0, 90],
		"stretch": [1, 4, 1]}
	var xf := StudioMotion.transform(m, 0.0)
	assert_almost_eq((xf.basis * Vector3.UP).length(), 4.0, 0.0001, "its own up is four times as long")
	assert_almost_eq((xf.basis * Vector3.UP).normalized().dot(Vector3.LEFT), 1.0, 0.0001, "and turned with it")
	assert_almost_eq((xf.basis * Vector3.RIGHT).length(), 1.0, 0.0001)


func test_a_grow_along_an_axis_stretches_one_way() -> void:
	var m := {"id": "rope", "model": "blocks", "cells": [[0, -1, 0, "PLANKS"]], "at": [0, 5, 0], "moves": [
		{"do": "grow", "at": 1.0, "dur": 2.0, "to": 0.25, "axis": "y", "ease": "smooth"}]}
	assert_eq(StudioMotion.state(m, 0.5).stretch, Vector3.ONE)
	var end: Vector3 = StudioMotion.state(m, 3.5).stretch
	assert_almost_eq(end.y, 0.25, 0.0001, "a rope wound up to a quarter")
	assert_almost_eq(end.x, 1.0, 0.0001)
	assert_almost_eq(float(StudioMotion.state(m, 3.5).scale), 1.0, 0.0001, "its size is untouched")


# --- Walking ---------------------------------------------------------------------------------------------------------

func _walker() -> Dictionary:
	return {"id": "me", "model": "avatar", "at": [0, 0, 0], "moves": [
		{"do": "move", "at": 1.0, "dur": 4.0, "to": [0, 0, -6]}, {"do": "legs", "at": 1.0, "dur": 4.0}]}


func test_an_avatar_s_legs_swing_while_it_walks() -> void:
	var w := _walker()
	assert_true((StudioMotion.state(w, 0.5).walk as Dictionary).is_empty(), "standing before")
	assert_true((StudioMotion.state(w, 5.5).walk as Dictionary).is_empty(), "and after")
	var swings := []
	for t: float in [1.1, 1.3, 1.5, 1.7]:
		var pose := StudioMotion.walk_pose(StudioMotion.state(w, t).walk)
		swings.append(float(pose.l_leg))
		assert_almost_eq(float(pose.l_leg), -float(pose.r_leg), 0.0001, "the legs go opposite ways")
	assert_gt(swings.max() - swings.min(), 0.5, "they swing")
	assert_eq(StudioMotion.walk_pose(StudioMotion.state(w, 2.3).walk),
		StudioMotion.walk_pose(StudioMotion.state(w, 2.3).walk), "the same at the same moment")


func test_an_avatar_can_pull_a_rope_leaning_back() -> void:
	var m := {"id": "me", "model": "avatar", "at": [0, 0, 0], "moves": [
		{"do": "legs", "at": 0.0, "dur": 6.0, "arms": "pull", "lean": 15, "steps": 0}]}
	var pose := StudioMotion.walk_pose(StudioMotion.state(m, 3.0).walk)
	assert_gt((pose.l_arm as Vector2).x, 0.6, "arms reach forward to the rope")
	assert_almost_eq((pose.l_arm as Vector2).x, (pose.r_arm as Vector2).x, 0.0001)
	assert_almost_eq(float(pose.lean), deg_to_rad(15), 0.0001, "leaning back")
	assert_almost_eq(float(pose.l_leg), 0.0, 0.0001, "standing still (no steps)")


# --- The camera aims ------------------------------------------------------------------------------------------------

func test_a_camera_can_keep_a_model_in_its_middle() -> void:
	var moon := {"id": "moon", "model": "planet", "body": "moon", "at": [20, 0, 0], "moves": [
		{"do": "orbit", "at": 0.0, "around": [0, 0, 0], "period": 8.0}]}
	var stage := _stage([moon])
	var where := func(id: String, t: float) -> Vector3: return StudioMotion.world(stage, StudioRules.model(stage, id), t).origin
	var keys := [{"at": 0.0, "pos": [0, 1, 0], "look": [0, 0, 0], "aim": "moon"},
		{"at": 8.0, "pos": [0, 1, 0], "look": [0, 0, 0], "aim": "moon"}]
	for t: float in [0.0, 1.0, 2.7, 5.5]:
		var p := StudioCamera.pose(keys, t, where)
		assert_almost_eq((p.look as Vector3).distance_to(where.call("moon", t)), 0.0, 0.0001, "on the Moon at %.1f s" % t)


func test_a_follow_rides_with_a_rider() -> void:
	var stage := _stage([_plank(), _crate()])
	var where := func(id: String, t: float) -> Vector3: return StudioMotion.world(stage, StudioRules.model(stage, id), t).origin
	var keys := [{"at": 0.0, "follow": "crate", "pos": [0, 0, 5], "look": [0, 0, 0]}]
	var p := StudioCamera.pose(keys, 3.0, where)
	assert_almost_eq((p.look as Vector3).distance_to(where.call("crate", 3.0)), 0.0, 0.0001)


# --- Ropes --------------------------------------------------------------------------------------------------------

func test_a_rope_runs_from_one_model_to_another_as_they_move() -> void:
	var hook := {"id": "hook", "model": "mark", "at": [0, 8, 0]}
	var load_mark := {"id": "load", "model": "mark", "at": [0, 1, 0], "moves": [{"do": "move", "at": 1, "dur": 2, "to": [0, 5, 0]}]}
	var rope := {"id": "rope", "model": "rope", "from": "hook", "to": "load", "at": [0, 0, 0]}
	var stage := _stage([hook, load_mark, rope])
	var a := StudioMotion.rope(stage, rope, 0.0)
	assert_almost_eq((a.origin as Vector3).distance_to(Vector3(0, 8, 0)), 0.0, 0.0001, "it starts at its from")
	assert_almost_eq(float(a.length), 7.0, 0.0001)
	var b := StudioMotion.rope(stage, rope, 3.0)
	assert_almost_eq(float(b.length), 3.0, 0.0001, "shorter as the load rises")
	assert_almost_eq((b.dir as Vector3).dot(Vector3.DOWN), 1.0, 0.0001, "down from the hook to the load")


func test_a_rope_can_hold_on_at_a_point_of_its_models() -> void:
	var axle := {"id": "axle", "model": "mark", "at": [0, 6, 0], "turn": [90, 0, 0]}
	var crate := {"id": "crate", "model": "blocks", "cells": [[0, 0, 0, "BARREL"]], "at": [-0.6, 0, 0], "moves": [
		{"do": "move", "at": 1, "dur": 2, "to": [-0.6, 2, 0]}]}
	var rope := {"id": "rope", "model": "rope", "from": "axle", "from_at": [-0.6, 0, 0], "to": "crate", "to_at": [0, 1, 0],
		"at": [0, 0, 0]}
	var stage := _stage([axle, crate, rope])
	var r := StudioMotion.rope(stage, rope, 3.0)
	assert_almost_eq((r.origin as Vector3).distance_to(Vector3(-0.6, 6, 0)), 0.0, 0.0001, "the wheel's rim, in its frame")
	assert_almost_eq(float(r.length), 3.0, 0.0001, "down to the crate's top (6 - 3)")


func test_a_rope_is_checked() -> void:
	var good := _stage([{"id": "a", "model": "mark", "at": [0, 0, 0]}, {"id": "b", "model": "mark", "at": [0, 3, 0]},
		{"id": "rope", "model": "rope", "from": "a", "to": "b", "at": [0, 0, 0], "width": 0.08, "block": "PLANKS"}])
	assert_eq(Scene3DKind.stage_problem(good), "")
	for what: String in ["from", "to"]:
		var s := good.duplicate(true)
		s.models[2][what] = "ufo"
		assert_ne(Scene3DKind.stage_problem(s), "", "a rope's %s is a model" % what)
	var s := good.duplicate(true)
	s.models[2].block = "UNOBTAINIUM"
	assert_ne(Scene3DKind.stage_problem(s), "")


# --- Light and sky --------------------------------------------------------------------------------------------------

func test_the_light_can_fade_into_a_sunset() -> void:
	var stage := {"light": [{"at": 0, "light": "day"}, {"at": 10, "dur": 4, "light": "dusk"}],
		"sun": [{"at": 0, "sun": [0.2, 1, 0]}, {"at": 10, "dur": 4, "sun": [1, 0.1, 0]}]}
	var day := StudioRules.light_at(stage, 5.0)
	var dusk := StudioRules.light_at(stage, 20.0)
	assert_almost_eq(float(day.key_energy), float(StudioRules.light("day").key_energy), 0.0001)
	assert_almost_eq(float(dusk.key_energy), float(StudioRules.light("dusk").key_energy), 0.0001)
	var half := StudioRules.light_at(stage, 12.0)
	assert_between(float(half.key_energy), float(StudioRules.light("dusk").key_energy), float(StudioRules.light("day").key_energy))
	assert_almost_eq((dusk.sun as Vector3).distance_to(Vector3(1, 0.1, 0).normalized()), 0.0, 0.0001, "the sun went low")
	assert_almost_eq((day.sun as Vector3).length(), 1.0, 0.0001)
	assert_eq(StudioRules.light_at({"light": "moon"}, 3.0).key_energy, StudioRules.light("moon").key_energy,
		"one preset holds all along")
	assert_almost_eq((StudioRules.light_at({"light": "day", "sun": [0, 0, 1]}, 3.0).sun as Vector3).z, 1.0, 0.0001)


func test_a_night_sky_lets_the_stars_through() -> void:
	var night := StudioRules.sky_colours("night")
	assert_lt(float(night.opacity), 0.5, "stars show through a night sky")
	assert_lt((night.top as Color).get_luminance(), 0.1, "and it is dark")
	var light := StudioRules.light("night")
	assert_lt(float(light.key_energy), float(StudioRules.light("dusk").key_energy) * 0.5, "a night's light is dim")
	assert_gt((light.key as Color).b, (light.key as Color).r, "and bluish, like moonlight")


# --- Blocks from shapes --------------------------------------------------------------------------------------------

func test_shapes_fill_blocks_in_order_and_air_carves() -> void:
	var data := {"fill": [{"box": [0, 0, 0, 3, 1, 2], "block": "STONE"}, {"box": [1, 1, 1, 2, 1, 1], "block": "AIR"}]}
	var cells := StudioShapes.cells(data)
	assert_eq(cells.size(), 4 * 2 * 3 - 2, "a 4 × 2 × 3 box, two carved out of its top")
	assert_eq(int(cells[Vector3i(0, 0, 0)]), BlockIds.STONE)
	assert_false(cells.has(Vector3i(1, 1, 1)))
	data.cells = [[1, 1, 1, "GOLD_QUARTZ"]]
	assert_eq(int(StudioShapes.cells(data)[Vector3i(1, 1, 1)]), BlockIds.GOLD_QUARTZ, "cells go in last")


func test_a_disc_a_cylinder_a_cone_and_a_ball_are_round() -> void:
	var disc := StudioShapes.cells({"fill": [{"disc": [0, 0, 0, 3], "block": "GRASS"}]})
	assert_true(disc.has(Vector3i(3, 0, 0)) and disc.has(Vector3i(0, 0, -3)))
	assert_false(disc.has(Vector3i(3, 0, 3)), "a corner is outside the circle")
	assert_between(disc.size(), 25, 37, "about π × 3²")
	var cyl := StudioShapes.cells({"fill": [{"cylinder": [0, 0, 0, 3, 4], "block": "LOG"}]})
	assert_eq(cyl.size(), disc.size() * 4, "four discs high")
	var cone := StudioShapes.cells({"fill": [{"cone": [0, 0, 0, 6, 6], "block": "STONE"}]})
	var lowest := 0
	var highest := 0
	for c: Vector3i in cone:
		if c.y == 0:
			lowest += 1
		elif c.y == 5:
			highest += 1
	assert_gt(lowest, highest * 10, "wide at the bottom, narrow at the top")
	assert_gt(highest, 0, "it has a top")
	var ball := StudioShapes.cells({"fill": [{"ball": [0, 0, 0, 3], "block": "HOT_LAVA"}]})
	assert_true(ball.has(Vector3i(0, 3, 0)) and ball.has(Vector3i(0, -3, 0)))
	assert_false(ball.has(Vector3i(2, 2, 2)))


func _buffer_cells(data: Dictionary) -> Dictionary:
	var made := StudioShapes.buffer(data)
	var out := {}
	if made.is_empty():
		return out
	var buf: VoxelBuffer = made.buffer
	var lo: Vector3i = made.lo
	var size := buf.get_size()
	for x in range(1, size.x - 1):
		for y in range(1, size.y - 1):
			for z in range(1, size.z - 1):
				var v := buf.get_voxel(x, y, z, VoxelBuffer.CHANNEL_TYPE)
				if v != 0:
					out[lo + Vector3i(x - 1, y - 1, z - 1)] = v
	return out


func test_a_voxel_buffer_of_the_shapes_holds_exactly_their_cells() -> void:
	# The stage meshes a blocks model from a VoxelBuffer filled row by row in C++ (a phone builds a reel in a frame of
	# its own: the volcano's 14,000 cells took 120 ms one by one); it must hold exactly StudioShapes.cells.
	var models: Array = [{"fill": [{"box": [0, 0, 0, 3, 1, 2], "block": "STONE"}, {"box": [1, 1, 1, 2, 1, 1], "block": "AIR"}],
		"cells": [[1, 1, 1, "GOLD_QUARTZ"], [9, 9, 9, "AIR"]]},
		{"fill": [{"disc": [0.5, 0, -0.3, 3.7], "block": "GRASS"}, {"ball": [2, 3, 1, 2.3], "block": "HOT_LAVA"},
			{"cone": [-1, 0, 0, 6.2, 7], "block": "BASALT"}, {"cylinder": [4, -2, 4, 1.4, 3], "block": "LOG"},
			{"box": [-30, -30, 1, 30, 30, 30], "block": "AIR"}]}]
	for id: String in ["volcano_erupts", "water_cycle_3d", "pyramid_build", "gold_prospecting", "plates_mountains",
			"float_or_sink", "lever_pulley", "plants_food", "volume_blocks", "day_and_night"]:
		for m: Dictionary in ShortLibrary.get_short(id).stage.models:
			if str(m.model) == "blocks" and not m.has("build"):
				models.append(m)
	for m: Dictionary in models:
		var want := StudioShapes.cells(m)
		var got := _buffer_cells(m)
		assert_eq(got.size(), want.size(), "as many cells: %s" % m.get("id", "a test model"))
		var same := true
		for c: Vector3i in want:
			if not got.has(c) or int(got[c]) != int(want[c]):
				same = false
				break
		assert_true(same, "the same cells and blocks: %s" % m.get("id", "a test model"))
	assert_true(StudioShapes.buffer({"fill": [{"box": [0, 0, 0, 1, 1, 1], "block": "AIR"}]}).is_empty(), "nothing: no buffer")


func test_shapes_are_checked() -> void:
	var good := {"id": "v", "model": "blocks", "at": [0, 0, 0], "fill": [{"cone": [0, 0, 0, 6, 6], "block": "STONE"}]}
	var stage := _stage([good])
	assert_eq(Scene3DKind.stage_problem(stage), "")
	var cases := {
		"shape": func(m: Dictionary) -> void: m.fill = [{"pyramid": [0, 0, 0, 3], "block": "STONE"}],
		"block": func(m: Dictionary) -> void: m.fill[0].block = "UNOBTAINIUM",
		"numbers": func(m: Dictionary) -> void: m.fill[0].cone = [0, 0, 0, 6],
		"too many": func(m: Dictionary) -> void: m.fill = [{"box": [0, 0, 0, 99, 99, 99], "block": "STONE"}],
		"nothing": func(m: Dictionary) -> void: m.fill = [],
	}
	for what: String in cases:
		var s := _stage([good.duplicate(true)])
		(cases[what] as Callable).call(s.models[0])
		assert_ne(Scene3DKind.stage_problem(s), "", "%s is checked" % what)


# --- Effects -------------------------------------------------------------------------------------------------------

func _cloud(_t: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0, 20, 0))


func test_rain_falls_fast_in_long_upright_drops() -> void:
	var e := {"kind": "rain", "at": [0, 20, 0], "from": 0.0, "to": 10.0}
	var list := StudioParticles.alive(e, 5.0, _cloud)
	assert_gt(list.size(), 50)
	var below := 0
	for p: Array in list:
		if (p[0] as Vector3).y < 19.0:
			below += 1
	assert_gt(below, list.size() / 2, "the drops fall from the cloud")
	var buf := PackedFloat32Array()
	buf.resize(StudioParticles.amount(e) * StudioParticles.STRIDE)
	StudioParticles.fill(e, 5.0, _cloud, buf, {})
	var up := Vector3(buf[1], buf[5], buf[9])
	var side := Vector3(buf[0], buf[4], buf[8])
	assert_gt(up.length(), side.length() * 3.0, "a drop is a streak, longer than it is wide")
	assert_almost_eq(up.normalized().dot(Vector3.UP), 1.0, 0.0001, "and it stands upright")


func test_an_effect_can_rise_from_a_wide_flat_patch() -> void:
	var sea := func(_t: float) -> Transform3D: return Transform3D(Basis.IDENTITY, Vector3(0, -1, 0))
	var e := {"kind": "steam", "at": [0, -1, 0], "from": 0.0, "to": 20.0, "size": 0.15, "area": [8, 6], "amount": 120}
	var xs := []
	var zs := []
	for p: Array in StudioParticles.alive(e, 10.0, sea):
		xs.append((p[0] as Vector3).x)
		zs.append((p[0] as Vector3).z)
	assert_gt(xs.max() - xs.min(), 6.0, "spread across the patch's 8 m")
	assert_lt(xs.max() - xs.min(), 9.0)
	assert_gt(zs.max() - zs.min(), 4.5, "and its 6 m")
	assert_ne(Scene3DKind._effect_problem({"kind": "steam", "from": 0, "to": 1, "area": [8, 0]}, {}, -1.0), "",
		"an area is [x, z] metres, each above 0")


func test_a_lava_fountain_rises_and_falls_back() -> void:
	var vent := func(_t: float) -> Transform3D: return Transform3D.IDENTITY
	var e := {"kind": "lava", "at": [0, 0, 0], "from": 0.0, "to": 10.0}
	var highest := 0.0
	var fallen := 0
	for p: Array in StudioParticles.alive(e, 6.0, vent):
		var at: Vector3 = p[0]
		highest = maxf(highest, at.y)
		if at.y < 1.0:
			fallen += 1
	assert_gt(highest, 2.0, "it shoots up")
	assert_gt(fallen, 0, "and gravity brings some back down")
	var floaty := e.duplicate()
	floaty.gravity = -1.0
	var top := 0.0
	for p: Array in StudioParticles.alive(floaty, 6.0, vent):
		top = maxf(top, (p[0] as Vector3).y)
	assert_gt(top, highest, "an effect's own gravity: a weak pull throws it higher (Io)")


# --- The checks ----------------------------------------------------------------------------------------------------

func test_the_rigs_are_checked() -> void:
	var good := _stage([_plank(), _crate(), {"id": "eye", "model": "mark", "at": [0, 2, 6]},
		{"id": "me", "model": "avatar", "at": [3, 0, 0], "stretch": [1, 1, 1], "moves": [
			{"do": "legs", "at": 0.5, "dur": 2.0, "arms": "pull", "lean": 10, "steps": 1.5},
			{"do": "grow", "at": 3.0, "dur": 1.0, "to": 1.2, "axis": "y"}]}])
	good.camera.append({"at": 2.0, "follow": "eye", "pos": [0, 0, 0], "look": [0, 0, 0], "aim": "crate"})
	good.light = [{"at": 0, "light": "day"}, {"at": 2, "dur": 1, "light": "dusk"}]
	good.sun = [{"at": 0, "sun": [0, 1, 0]}, {"at": 2, "dur": 1, "sun": [1, 0.2, 0]}]
	good.sky = "night"
	good.effects = [{"kind": "rain", "at": [0, 9, 0], "from": 0, "to": 3}, {"kind": "lava", "on": "eye", "from": 0, "to": 3,
		"gravity": -3}]
	assert_eq(Scene3DKind.stage_problem(good), "")
	var cases := {
		"on nothing": func(s: Dictionary) -> void: s.models[1].on = "ufo",
		"on itself": func(s: Dictionary) -> void: s.models[1].on = "crate",
		"a ring of riders": func(s: Dictionary) -> void: s.models[0].on = "crate",
		"a stretch": func(s: Dictionary) -> void: s.models[3].stretch = [1, 0, 1],
		"a grow's axis": func(s: Dictionary) -> void: s.models[3].moves[1].axis = "w",
		"legs on a plank": func(s: Dictionary) -> void: s.models[0].moves.append({"do": "legs", "at": 1, "dur": 1}),
		"the arms": func(s: Dictionary) -> void: s.models[3].moves[0].arms = "flap",
		"aim": func(s: Dictionary) -> void: s.camera[1].aim = "ufo",
		"light keys": func(s: Dictionary) -> void: s.light[1].light = "disco",
		"sun keys": func(s: Dictionary) -> void: s.sun[1].sun = [0, 0, 0],
		"gravity": func(s: Dictionary) -> void: s.effects[1].gravity = "down",
	}
	for what: String in cases:
		var s := good.duplicate(true)
		(cases[what] as Callable).call(s)
		assert_ne(Scene3DKind.stage_problem(s), "", "%s is checked" % what)
