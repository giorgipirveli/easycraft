extends GutTest
## Owner #96 (spec §5.12b, the Reel Studio): a 3D stage's models, camera and particles are pure functions of the time,
## so a Short's frame at any moment is the same whether it was played to or sought (the feed's snap, the frame sheets,
## the Movie Maker's frames).


func _rocket() -> Dictionary:
	return {"id": "rocket", "model": "rocket", "rocket": "moon", "at": [0, 0, 0], "moves": [
		{"do": "move", "at": 2.0, "dur": 10.0, "to": [0, 300, 0], "ease": "in"},
		{"do": "stage", "at": 8.0, "stage": 0}]}


# --- Models ----------------------------------------------------------------------------------------------------------

func test_a_model_stands_where_it_is_until_it_moves() -> void:
	var s := StudioMotion.state(_rocket(), 1.0)
	assert_true(s.visible)
	assert_eq(s.pos, Vector3.ZERO)
	assert_eq(StudioMotion.state(_rocket(), 2.0).pos, Vector3.ZERO, "a move starts where it stands")


func test_a_launch_speeds_up() -> void:
	var early: float = StudioMotion.state(_rocket(), 4.0).pos.y - StudioMotion.state(_rocket(), 3.0).pos.y
	var late: float = StudioMotion.state(_rocket(), 11.0).pos.y - StudioMotion.state(_rocket(), 10.0).pos.y
	assert_gt(late, early * 4.0, "ease in: the rocket climbs faster and faster")
	assert_almost_eq(StudioMotion.state(_rocket(), 12.0).pos.y, 300.0, 0.001)
	assert_almost_eq(StudioMotion.state(_rocket(), 30.0).pos.y, 300.0, 0.001, "a finished move holds its end")


func test_entrances_hide_a_model_until_they_start() -> void:
	var m := {"id": "tank", "model": "blocks", "at": [0, 5, 0], "moves": [{"do": "drop", "at": 3.0, "height": 8.0}]}
	assert_false(StudioMotion.state(m, 2.9).visible, "hidden before it drops in")
	var falling := StudioMotion.state(m, 3.05)
	assert_true(falling.visible)
	assert_gt(falling.pos.y, 10.0, "it falls from above")
	assert_almost_eq(StudioMotion.state(m, 5.0).pos.y, 5.0, 0.001, "and lands where it stands")


func test_a_model_may_leave_and_come_back() -> void:
	var m := {"id": "line", "model": "orbit_line", "radius": 10, "at": [0, 0, 0], "moves": [
		{"do": "out", "at": 20.0, "dur": 0.3}, {"do": "pop", "at": 40.0}]}
	assert_true(StudioMotion.state(m, 5.0).visible, "there from the start (it leaves before it enters)")
	assert_false(StudioMotion.state(m, 30.0).visible, "gone for the close-ups")
	assert_true(StudioMotion.state(m, 41.0).visible, "and back")


func test_a_pop_overshoots_then_settles() -> void:
	var m := {"id": "p", "model": "planet", "body": "mars", "at": [0, 0, 0], "moves": [{"do": "pop", "at": 1.0}]}
	var biggest := 0.0
	for i in 20:
		biggest = maxf(biggest, float(StudioMotion.state(m, 1.0 + i * 0.025).scale))
	assert_gt(biggest, 1.02, "a little overshoot")
	assert_almost_eq(float(StudioMotion.state(m, 2.0).scale), 1.0, 0.0001)


func test_an_orbit_comes_round_in_its_period() -> void:
	var m := {"id": "earth", "model": "planet", "body": "earth", "at": [40, 0, 0], "moves": [
		{"do": "orbit", "at": 0.0, "around": [0, 0, 0], "period": 10.0, "dir": -1}]}
	assert_almost_eq(StudioMotion.state(m, 10.0).pos.distance_to(Vector3(40, 0, 0)), 0.0, 0.001)
	var quarter: Vector3 = StudioMotion.state(m, 2.5).pos
	assert_almost_eq(quarter.length(), 40.0, 0.001, "on its circle")
	assert_almost_eq(absf(quarter.z), 40.0, 0.001, "a quarter of the way round")
	var other := m.duplicate(true)
	other.moves[0].dir = 1
	assert_almost_eq(StudioMotion.state(other, 2.5).pos.z, -quarter.z, 0.001, "dir turns it the other way")


func test_a_spin_at_a_rate_goes_on() -> void:
	var m := {"id": "s", "model": "planet", "body": "saturn", "at": [0, 0, 0], "moves": [
		{"do": "spin", "at": 0.0, "rate": 0.25}]}
	assert_almost_eq(float(StudioMotion.state(m, 2.0).rot.y), PI, 0.0001, "half a turn in 2 s")
	assert_almost_eq(float(StudioMotion.state(m, 30.0).rot.y), TAU * 7.5, 0.0001)


func test_turns_are_in_degrees() -> void:
	var m := {"id": "r", "model": "rocket", "rocket": "moon", "at": [0, 0, 0], "turn": [0, 90, 0], "moves": [
		{"do": "turn", "at": 1.0, "dur": 1.0, "to": [20, 90, 0]}]}
	assert_almost_eq(float(StudioMotion.state(m, 0.0).rot.y), PI * 0.5, 0.0001)
	assert_almost_eq(float(StudioMotion.state(m, 3.0).rot.x), deg_to_rad(20.0), 0.0001)


func test_stages_fall_away_behind_the_rocket() -> void:
	var r := _rocket()
	assert_eq(StudioMotion.stages_dropped(r, 7.9), 0)
	assert_eq(StudioMotion.stages_dropped(r, 8.0), 1)
	var at_drop := StudioMotion.transform(r, 8.0)
	var fell := StudioMotion.dropped(r, 0, 8.0)
	assert_almost_eq(fell.origin.distance_to(at_drop.origin), 0.0, 0.001, "it lets go where the rocket is")
	var later := 3.0
	var gap: float = StudioMotion.transform(r, 8.0 + later).origin.y - StudioMotion.dropped(r, 0, 8.0 + later).origin.y
	assert_gt(gap, 20.0, "the rocket speeds away; the empty stage falls behind")
	assert_ne(StudioMotion.dropped(r, 0, 10.0).basis, at_drop.basis, "it tumbles")
	assert_eq(StudioMotion.dropped(r, 0, 10.0), StudioMotion.dropped(r, 0, 10.0), "the same moment, the same place")


func test_an_emote_plays_from_its_start() -> void:
	var m := {"id": "me", "model": "avatar", "look": "astronaut", "at": [0, 0, 0], "moves": [
		{"do": "emote", "at": 2.0, "emote": "wave"}]}
	assert_true(StudioMotion.state(m, 1.0).emote.is_empty())
	var e: Dictionary = StudioMotion.state(m, 2.5).emote
	assert_eq(e.name, &"wave")
	assert_almost_eq(float(e.t), 0.5, 0.0001)


# --- The camera ------------------------------------------------------------------------------------------------------

func test_the_camera_holds_before_its_first_key_and_after_its_last() -> void:
	var keys := [{"at": 1.0, "pos": [0, 2, 10], "look": [0, 1, 0], "fov": 40},
		{"at": 3.0, "pos": [0, 2, 20], "look": [0, 1, 0], "fov": 60}]
	assert_eq(StudioCamera.pose(keys, 0.0).pos, Vector3(0, 2, 10))
	assert_eq(StudioCamera.pose(keys, 9.0).pos, Vector3(0, 2, 20))
	assert_almost_eq(float(StudioCamera.pose(keys, 9.0).fov), 60.0, 0.0001)


func test_a_dolly_eases_between_keys() -> void:
	var keys := [{"at": 0.0, "pos": [0, 2, 10], "look": [0, 1, 0]}, {"at": 4.0, "pos": [0, 2, 30], "look": [0, 1, 0]}]
	var mid: Vector3 = StudioCamera.pose(keys, 2.0).pos
	assert_almost_eq(mid.z, 20.0, 0.001, "smooth: half-way at half the time")
	var start: Vector3 = StudioCamera.pose(keys, 0.4).pos
	assert_lt(start.z - 10.0, 10.0 * 0.4 / 4.0 * 2.0 * 0.5, "it starts gently (no jerk)")


func test_a_cut_jumps() -> void:
	var keys := [{"at": 0.0, "pos": [0, 2, 10], "look": [0, 0, 0]}, {"at": 5.0, "cut": true, "pos": [50, 2, 0], "look": [0, 0, 0]}]
	assert_eq(StudioCamera.pose(keys, 4.99).pos, Vector3(0, 2, 10), "holds until the cut")
	assert_eq(StudioCamera.pose(keys, 5.0).pos, Vector3(50, 2, 0))


func test_an_orbit_keeps_its_distance() -> void:
	var keys := [{"at": 0.0, "pos": [20, 5, 0], "look": [0, 0, 0]},
		{"at": 4.0, "pos": [0, 5, 20], "look": [0, 0, 0], "path": "orbit", "ease": "linear"}]
	for t: float in [0.5, 1.3, 2.0, 3.1]:
		var p: Vector3 = StudioCamera.pose(keys, t).pos
		assert_almost_eq(Vector2(p.x, p.z).length(), 20.0, 0.001, "round the look point at %.1f s" % t)
		assert_almost_eq(p.y, 5.0, 0.001)
	var turned := keys.duplicate(true)
	turned[1].turns = 1
	var half: Vector3 = StudioCamera.pose(turned, 2.0).pos
	assert_almost_eq(Vector2(half.x, half.z).length(), 20.0, 0.001)
	assert_lt(half.x, -10.0, "an extra turn goes the long way round")


func test_a_follow_key_rides_with_its_model() -> void:
	var stage := {"models": [_rocket()]}
	var where := func(id: String, t: float) -> Vector3: return StudioMotion.state(StudioRules.model(stage, id), t).pos
	var keys := [{"at": 0.0, "follow": "rocket", "pos": [0, 5, 30], "look": [0, 10, 0]}]
	var p := StudioCamera.pose(keys, 11.0, where)
	var rocket_y: float = StudioMotion.state(_rocket(), 11.0).pos.y
	assert_almost_eq(float(p.pos.y), rocket_y + 5.0, 0.001)
	assert_almost_eq(float(p.look.y), rocket_y + 10.0, 0.001)


func test_a_roll_turns_the_picture_round_the_view() -> void:
	var keys := [{"at": 0.0, "pos": [0, 30, 50], "look": [0, 0, 0], "roll": 90}]
	var flat := StudioCamera.transform(StudioCamera.pose([{"at": 0.0, "pos": [0, 30, 50], "look": [0, 0, 0]}], 0.0))
	var rolled := StudioCamera.transform(StudioCamera.pose(keys, 0.0))
	assert_almost_eq(rolled.basis.z.dot(flat.basis.z), 1.0, 0.0001, "it still looks the same way")
	assert_almost_eq(absf(rolled.basis.y.dot(flat.basis.x)), 1.0, 0.0001, "a quarter turn: its up is the old right")


func test_a_shake_is_the_same_at_the_same_moment() -> void:
	var keys := [{"at": 0.0, "pos": [0, 2, 10], "look": [0, 1, 0], "shake": 0.3}]
	var a := StudioCamera.pose(keys, 2.37)
	var b := StudioCamera.pose(keys, 2.37)
	assert_eq(a.pos, b.pos)
	assert_ne(a.pos, Vector3(0, 2, 10), "it shakes")
	assert_lt((a.pos as Vector3).distance_to(Vector3(0, 2, 10)), 0.6)


# --- Particles -------------------------------------------------------------------------------------------------------

func _origin(t: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0, t * 10.0, 0))


func test_no_particle_before_an_effect_starts_or_long_after_it_ends() -> void:
	var e := {"kind": "smoke", "from": 2.0, "to": 5.0}
	assert_eq(StudioParticles.alive(e, 1.9, _origin).size(), 0)
	assert_gt(StudioParticles.alive(e, 3.0, _origin).size(), 5)
	assert_eq(StudioParticles.alive(e, 5.0 + StudioParticles.life(e) + 0.01, _origin).size(), 0)


func test_particles_are_the_same_at_the_same_moment() -> void:
	var e := {"kind": "flame", "from": 0.0, "to": 20.0}
	assert_eq(StudioParticles.alive(e, 7.31, _origin), StudioParticles.alive(e, 7.31, _origin))
	assert_ne(StudioParticles.alive(e, 7.31, _origin), StudioParticles.alive(e, 7.35, _origin), "and they move")


func test_a_flame_pours_down_from_its_engine() -> void:
	var e := {"kind": "flame", "from": 0.0, "to": 20.0}
	var below := 0
	var list := StudioParticles.alive(e, 5.0, _origin)
	for p: Array in list:
		if (p[0] as Vector3).y < 0.0:
			below += 1
	assert_gt(below, list.size() * 0.9, "a flame is local to its engine and pours down")
	assert_lte(list.size(), StudioParticles.amount(e))


func test_smoke_stays_where_it_was_made() -> void:
	var e := {"kind": "smoke", "from": 0.0, "to": 20.0}
	var low := 0
	for p: Array in StudioParticles.alive(e, 10.0, _origin):
		if (p[0] as Vector3).y < 80.0:
			low += 1
	assert_gt(low, 3, "smoke left behind as the rocket climbs (the world's frame)")


func test_a_ring_of_dust_spreads_low_along_the_ground() -> void:
	# The review found a landing's dust rising at 45 degrees: a ring's small lift had been made a whole unit up.
	var e := {"kind": "billow", "at": [0, 0.2, 0], "from": 0.0, "to": 5.0, "size": 0.45, "speed": 1.5}
	var ground := func(_t: float) -> Transform3D: return Transform3D(Basis.IDENTITY, Vector3(0, 0.2, 0))
	var wide := 0.0
	for p: Array in StudioParticles.alive(e, 4.0, ground):
		var at: Vector3 = p[0]
		assert_lt(at.y, 2.0, "low: %s" % at)
		wide = maxf(wide, Vector2(at.x, at.z).length())
	assert_gt(wide, 3.0, "and wide")
