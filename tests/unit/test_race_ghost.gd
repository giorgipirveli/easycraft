extends GutTest
## M4 ghost races: a best run as a shareable ghost (RaceGhost). A course's recorded run (M3 Task 7, 10 samples
## a second) is sampled 5 times a second, kept in decimetres from the START's top, sent in the server's format
## (server/modules/src/rules/ghost_rules.ts: int16 little-endian triplets in base64), checked the way the
## server checks it (START and FINISH where it says, from START to FINISH, never faster than the game's fastest
## move, jumps only onto a START, CHECKPOINT or TELEPORT_PAD) and played back smoothly, turned like a stamp.

const GHOST_TS := "res://server/modules/src/rules/ghost_rules.ts"


func _ts_int(ts: String, name: String) -> int:
	var m := RegEx.create_from_string("export const %s = (\\d+);" % name).search(ts)
	assert_not_null(m, name)
	return int(m.get_string(1)) if m else -1


func test_the_limits_are_the_servers() -> void:
	var ts := FileAccess.get_file_as_string(GHOST_TS)
	for pair: Array in [["TELEPORT_PAD", BlockIds.TELEPORT_PAD], ["START", BlockIds.START], ["CHECKPOINT", BlockIds.CHECKPOINT],
			["FINISH", BlockIds.FINISH], ["SAMPLE_MS", RaceGhost.SAMPLE_MS], ["MIN_MS", RaceGhost.MIN_MS],
			["MAX_MS", RaceGhost.MAX_MS], ["MAX_LOOK", RaceGhost.MAX_LOOK], ["MAX_SPEED", int(RaceGhost.MAX_SPEED)],
			["STEP_SLACK_DM", RaceGhost.STEP_SLACK_DM], ["FIRST_REACH_DM", RaceGhost.FIRST_REACH_DM],
			["LAST_REACH_DM", RaceGhost.LAST_REACH_DM], ["LAND_REACH_DM", RaceGhost.LAND_REACH_DM],
			["MAX_JUMPS", RaceGhost.MAX_JUMPS], ["MARGIN", RaceGhost.MARGIN], ["UP_MARGIN", RaceGhost.UP_MARGIN],
			["DOWN_MARGIN", RaceGhost.DOWN_MARGIN], ["PER_SHOWCASE", GhostRaceRules.PER_SHOWCASE],
			["SHARES_PER_HOUR", GhostRaceRules.SHARES_PER_HOUR]]:
		assert_eq(_ts_int(ts, pair[0]), pair[1], pair[0])
	assert_eq(RaceGhost.MAX_SAMPLES, RaceGhost.MAX_MS / RaceGhost.SAMPLE_MS + 1)
	assert_eq(RaceGhost.MIN_MS, CourseRules.MIN_GOAL_MS)
	assert_eq(RaceGhost.MAX_MS, roundi(RecordedRun.MAX_SAMPLES * RecordedRun.DT * 1000.0))
	assert_eq(RaceGhost.MAX_LOOK, AvatarLook.MAX_CODE_LENGTH)


## "Speed <= the game's max": the server's limit is above every way the game moves a child.
func test_the_speed_limit_is_above_every_way_to_move() -> void:
	var fall := sqrt(2.0 * Player.GRAVITY * (CourseRules.FALL_DEPTH + 2.0))   # a fall is caught 12 blocks down
	var fastest: Array[float] = [PadRules.LAUNCH_PAD_SPEED, PadRules.BOUNCE_SPEED, PadRules.LAUNCH_SPEED, PadRules.BOOST_SPEED,
		GadgetRules.HOOK_SPEED, GadgetRules.ZIP_MAX_SPEED, PetRules.GLIDE_SPEED, LabRules.ZERO_G_MAX_SPEED, fall,
		Player.FLY_SPEED * SizeMagic.walk_speed_factor(SizeMagic.Mode.GIANT),
		Player.WALK_SPEED * SizeMagic.walk_speed_factor(SizeMagic.Mode.GIANT) * PotionRules.SPEED]
	for s in fastest:
		assert_lt(s + Player.WALK_SPEED * 0.5, RaceGhost.MAX_SPEED, "a move of %.1f m/s (and a step on top) passes" % s)


## A 10 Hz recording of a straight 2 s walk from START's top (1.5, 11, 1.5) to FINISH's top (9.5, 11, 9.5).
func _walk(from: Vector3, to: Vector3, seconds: float) -> RecordedRun:
	var r := RecordedRun.new(from)
	var n := roundi(seconds / RecordedRun.DT) + 1
	for i in n:
		r.add(from.lerp(to, i / float(n - 1)))
	return r


func test_a_recorded_run_becomes_five_samples_a_second_from_starts_top() -> void:
	var run := _walk(Vector3(1.5, 11, 1.5), Vector3(9.5, 11, 9.5), 2.0)
	var g := RaceGhost.from_run(run, 2000, Vector3i(1, 10, 1), Vector3i(9, 10, 9), "{\"hat\":\"cap\"}")
	assert_not_null(g)
	assert_eq(g.points.size(), RaceGhost.sample_count(2000))
	assert_eq(g.points.size(), 11)
	assert_eq(g.points[0], Vector3.ZERO, "starts on START's top")
	assert_eq(g.points[g.points.size() - 1], Vector3(8, 0, 8), "ends on FINISH's top")
	assert_almost_eq(g.points[5].x, 4.0, 0.051, "evenly spread over the run")
	for p in g.points:
		assert_almost_eq(p.x * 10.0, roundf(p.x * 10.0), 0.0001, "decimetres, as the server keeps them")
	assert_eq([g.start, g.finish, g.ms, g.look], [Vector3i(1, 10, 1), Vector3i(9, 10, 9), 2000, "{\"hat\":\"cap\"}"])
	assert_null(RaceGhost.from_run(RecordedRun.new(), 2000, Vector3i.ZERO, Vector3i.ONE, ""), "no samples: no ghost")


## A fall brings the runner back to the checkpoint in one step: the sampled path never has a point in the air
## between the fall and the checkpoint (the server allows only jumps that land on one).
func test_a_fall_back_stays_one_sharp_jump_when_sampled() -> void:
	var top := Vector3(1.5, 11, 1.5)
	var run := RecordedRun.new(top)
	for i in 11:                                   # 1 s walking +z, then falling 13 blocks in 0.5 s
		run.add(top + Vector3(0, 0, i * 0.7))
	for i in 5:
		run.add(top + Vector3(0, -2.6 * (i + 1), 7.0))
	for i in 12:                                   # back on the checkpoint at (5, 10, 5), walking on
		run.add(Vector3(5.5, 11, 5.5) + Vector3(i * 0.3, 0, i * 0.3))
	var ms := roundi(run.duration() * 1000.0)
	var g := RaceGhost.from_run(run, ms, Vector3i(1, 10, 1), Vector3i(9, 10, 9), "")
	assert_eq(g.points.size(), 15, "2.7 s: a sample falls inside the 10 Hz step of the jump (1.5-1.6 s)")
	var limit := RaceGhost.MAX_SPEED * (ms / 1000.0) / (g.points.size() - 1) + RaceGhost.STEP_SLACK_DM / 10.0
	var jumps := 0
	for i in range(1, g.points.size()):
		if g.points[i].distance_to(g.points[i - 1]) > limit:
			jumps += 1
			assert_lt(g.points[i].distance_to(Vector3(4, 0, 4)), 3.0, "a jump lands on the checkpoint's top")
	assert_eq(jumps, 1)


func test_the_wire_is_the_servers_format_both_ways() -> void:
	var g := RaceGhost.new()
	g.start = Vector3i(1, 0, 1)
	g.finish = Vector3i(8, 0, 8)
	g.ms = 1000
	g.points = PackedVector3Array([Vector3.ZERO, Vector3(-0.1, 0.2, -0.3)])
	assert_eq(g.path_text(), "AAAAAAAA//8CAP3/", "int16 little-endian decimetres in base64")
	g.points = PackedVector3Array([Vector3.ZERO, Vector3(1.4, 0, 1.4), Vector3(2.8, 0, 2.8), Vector3(4.2, 0, 4.2),
		Vector3(5.6, 0, 5.6), Vector3(7, 0, 7)])
	g.look = "{\"hat\":\"cap\"}"
	var wire := g.to_wire()
	assert_eq(wire, {"start": [1, 0, 1], "finish": [8, 0, 8], "ms": 1000, "path": g.path_text(), "look": g.look})
	var back := RaceGhost.from_wire(JSON.parse_string(JSON.stringify(wire)))   # numbers come back as floats
	assert_not_null(back)
	assert_eq([back.start, back.finish, back.ms, back.points, back.look], [g.start, g.finish, g.ms, g.points, g.look])
	var listed := RaceGhost.from_wire({"ghost_id": "h1_abc", "start": [1, 0, 1], "finish": [8, 0, 8], "ms": 1000,
		"path": g.path_text(), "look": "", "updated_ms": 5})
	assert_eq(listed.id, "h1_abc", "a showcase ghost keeps the server's id")


func test_a_broken_ghost_from_the_wire_is_refused() -> void:
	var g := {"start": [1, 0, 1], "finish": [8, 0, 8], "ms": 1000, "path": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "look": ""}
	assert_not_null(RaceGhost.from_wire(g), "six samples of 0: a fine shape")
	for bad: Variant in [null, 5, "x", [], {}]:
		assert_null(RaceGhost.from_wire(bad), str(bad))
	for change: Array in [["start", [1, 0]], ["start", [1, 0, 1.5]], ["start", [-1, 0, 1]], ["finish", "8,0,8"], ["ms", "1000"],
			["ms", 999], ["ms", 180001], ["ms", 1000.5], ["path", 7], ["path", "!!!!"], ["path", "AAAA"], ["look", 7],
			["look", "not json"], ["look", "[1]"], ["look", "x".repeat(2049)], ["ms", 4000], ["ghost_id", 5]]:
		var d := g.duplicate()
		d[change[0]] = change[1]
		assert_null(RaceGhost.from_wire(d), "%s %s" % [change[0], str(change[1]).left(20)])


# --- The server's checks, on this side (the game offers only what the server will take) ---

## A 12 x 4 x 12 course: START (1, 0, 1), FINISH (9, 0, 9), a CHECKPOINT (5, 0, 5), a TELEPORT_PAD (1, 0, 9).
func _course(c: Vector3i) -> int:
	if c.x < 0 or c.y < 0 or c.z < 0 or c.x >= 12 or c.y >= 4 or c.z >= 12 or c.y != 0:
		return BlockIds.AIR
	match [c.x, c.z]:
		[1, 1]:
			return BlockIds.START
		[9, 9]:
			return BlockIds.FINISH
		[5, 5]:
			return BlockIds.CHECKPOINT
		[1, 9]:
			return BlockIds.TELEPORT_PAD
	return BlockIds.STONE


func _ghost(points: Array, ms: int = -1) -> RaceGhost:
	var g := RaceGhost.new()
	g.start = Vector3i(1, 0, 1)
	g.finish = Vector3i(9, 0, 9)
	g.points = PackedVector3Array(points)
	g.ms = ms if ms > 0 else (points.size() - 1) * RaceGhost.SAMPLE_MS
	return g


## `steps` points after `from` up to `to`.
func _line(from: Vector3, to: Vector3, steps: int) -> Array:
	var out := []
	for k in range(1, steps + 1):
		out.append(from.lerp(to, k / float(steps)))
	return out


const SIZE := Vector3i(12, 4, 12)
const TO_FINISH := Vector3(8, 0, 8)


func test_the_same_checks_as_the_server() -> void:
	assert_eq(_ghost([Vector3.ZERO] + _line(Vector3.ZERO, TO_FINISH, 10)).check(SIZE, _course), "", "a walk")
	var not_start := _ghost([Vector3.ZERO] + _line(Vector3.ZERO, TO_FINISH, 10))
	not_start.start = Vector3i(2, 0, 1)
	assert_eq(not_start.check(SIZE, _course), RaceGhost.NOT_ON_COURSE)
	var off := _ghost([Vector3(3.5, 0, 0)] + _line(Vector3(3.5, 0, 0), TO_FINISH, 10))
	assert_eq(off.check(SIZE, _course), RaceGhost.IMPOSSIBLE, "3.5 blocks off START")
	var short := _ghost([Vector3.ZERO] + _line(Vector3.ZERO, Vector3(8, 0, 6), 10))
	assert_eq(short.check(SIZE, _course), RaceGhost.IMPOSSIBLE, "2 blocks short of FINISH")
	var hop := _ghost([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, TO_FINISH])
	assert_eq(hop.check(SIZE, _course), RaceGhost.IMPOSSIBLE, "a teleport onto FINISH")
	var fall := [Vector3.ZERO] + _line(Vector3.ZERO, Vector3(0, 0, 7), 10) + _line(Vector3(0, 0, 7), Vector3(0, -13, 7), 5)
	assert_eq(_ghost(fall + [Vector3(4, 0, 4)] + _line(Vector3(4, 0, 4), TO_FINISH, 14)).check(SIZE, _course), "",
		"back on the checkpoint")
	assert_eq(_ghost(fall + [Vector3(9, 0, 1)] + _line(Vector3(9, 0, 1), TO_FINISH, 14)).check(SIZE, _course),
		RaceGhost.IMPOSSIBLE, "a jump to nowhere")
	var pad := [Vector3.ZERO] + _line(Vector3.ZERO, Vector3(8, 0, 0), 10) + [Vector3(0, 0, 8)] + _line(Vector3(0, 0, 8), TO_FINISH, 10)
	assert_eq(_ghost(pad).check(SIZE, _course), "", "a teleport pad's trip")
	var far := [Vector3.ZERO] + _line(Vector3.ZERO, Vector3(-8, 0, 0), 20) + _line(Vector3(-8, 0, 0), TO_FINISH, 30)
	assert_eq(_ghost(far).check(SIZE, _course), RaceGhost.IMPOSSIBLE, "8 blocks out of the box")
	var slow := _ghost([Vector3.ZERO] + _line(Vector3.ZERO, TO_FINISH, 10), 4000)
	assert_eq(slow.check(SIZE, _course), RaceGhost.BAD, "the samples must match the time")


# --- Playback ---

func test_playback_runs_the_path_over_the_runs_time_and_blinks_across_a_jump() -> void:
	var g := _ghost([Vector3.ZERO] + _line(Vector3.ZERO, Vector3(8, 0, 0), 10) + [Vector3(0, 0, 8)] + _line(Vector3(0, 0, 8), TO_FINISH, 10))
	assert_eq(g.duration(), 4.2)
	assert_eq(g.sample_at(0.0), Vector3.ZERO)
	assert_eq(g.sample_at(-1.0), Vector3.ZERO)
	assert_eq(g.sample_at(4.2), TO_FINISH)
	assert_eq(g.sample_at(99.0), TO_FINISH)
	assert_almost_eq(g.sample_at(0.1).x, 0.4, 0.0001, "between two samples")
	assert_eq(g.sample_at(2.03), Vector3(8, 0, 0), "a jump: still where it was")
	assert_eq(g.sample_at(2.17), Vector3(0, 0, 8), "then on the pad: never in the air between")
	assert_true(g.jumps_between(1.9, 2.3))
	assert_false(g.jumps_between(0.0, 1.9))
	assert_eq(g.facing_at(1.0), Vector3(1, 0, 0), "facing the way it goes")
	assert_eq(g.facing_at(3.0), Vector3(1, 0, 0))


func test_turned_like_a_stamp() -> void:
	# A stamp placed facing `forward` maps its x to the right, its z away from the child (Blueprints.to_world).
	for forward: Vector3i in [Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, 0)]:
		var cell := Vector3i(3, 2, 5)
		var anchor := Vector3i(10, 20, 30)
		var world_cell := Blueprints.to_world(cell, anchor, forward)
		var origin := Blueprints.to_world(Vector3i.ZERO, anchor, forward)
		var turned := RaceGhost.turned(Vector3(cell), forward)
		assert_eq(Vector3(origin) + turned, Vector3(world_cell), "the cells land where the stamp puts them: %s" % forward)
	assert_eq(RaceGhost.turned(Vector3(1, 2, 3), Vector3i.ZERO), Vector3(1, 2, 3), "a showcase is never turned")
