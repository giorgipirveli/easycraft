extends GutTest
## Owner feedback #39 (spec §14.2a, §12.9, §12.20, §6): the Dragon Realm's boss, the Sky Dragon, as pure rules. It
## flies: it circles over the arena, then picks a child, climbs and glows while a line shows on the ground where it
## will dive (every screen sees it), then swoops along that line: whoever stands on the line when it passes low is
## hit and pushed; a step off the line dodges it. After a dive it glides low and slow (the window to hit it); after
## every second dive it lands and rests (double damage, like the Golem's daze). Crystal towers rise round the arena at
## the start and once more at a third of its health, and heal it a little every second until the team breaks them.
## Health by team size and honest help like the Golem's (tired: less health, fewer towers, slower). It never leaves
## the arena circle and never pushes a child out of it.

const P := SkyDragonRules.Phase
const CENTER := Vector3(0, 32, 0)


# --- Health, words, scaling -----------------------------------------------------------------------------------

func test_health_scales_with_the_team_and_a_tired_dragon_has_less() -> void:
	assert_eq(SkyDragonRules.max_hp(1), SkyDragonRules.BASE_HP)
	assert_eq(SkyDragonRules.max_hp(3), roundi(SkyDragonRules.BASE_HP * 2.0), "each more player or bot friend adds half")
	assert_eq(SkyDragonRules.max_hp(1, true), roundi(SkyDragonRules.BASE_HP * BossRules.TIRED_SHARE), "honest help")
	assert_eq(SkyDragonRules.max_hp(0), SkyDragonRules.BASE_HP, "never less than one child's")
	assert_gt(SkyDragonRules.BASE_HP, CakeRules.BASE_HP, "the last universe's boss is the biggest")
	assert_eq(BossRules.max_hp_of(BossRules.SKY_DRAGON, 2), SkyDragonRules.max_hp(2), "the director asks BossRules")
	assert_eq(BossRules.max_hp_of(BossRules.SKY_DRAGON, 1, true), SkyDragonRules.max_hp(1, true))


func test_its_kind_and_words() -> void:
	assert_eq(BossRules.SKY_DRAGON, &"sky_dragon", "the lead's merge wires dragon.gd's boss_kind to this name")
	var w := BossRules.words(BossRules.SKY_DRAGON)
	assert_eq(w.name, "Sky Dragon")
	assert_eq(w.title, "SKY DRAGON")
	assert_eq(w.tired_title, "TIRED DRAGON")
	assert_string_contains(w.win, "Sky Dragon")
	assert_string_contains(w.tired, "tired")
	assert_string_contains(w.tired, "sun lanterns", "the tired line says what changed")   # owner #43
	assert_string_contains(w.summon, "%s")
	assert_eq(WaveRules.boss_word(w.name), "The Sky Dragon!")
	assert_string_contains(SkyDragonRules.TOWER_LINE, "sun lanterns")   # owner #43


func test_summon_skydragon_is_a_sandbox_command() -> void:
	assert_true(ChatCommands.BOSSES.has("skydragon"))
	assert_eq(ChatCommands.parse("/summon skydragon").get("boss"), BossRules.SKY_DRAGON)
	assert_eq(ChatCommands.parse("/summon SkyDragon").get("boss"), BossRules.SKY_DRAGON)
	assert_true(ChatCommands.suggestions("/summon sky").has("/summon skydragon"))
	assert_eq(ChatCommands.parse("/summon cake").get("boss"), BossRules.CAKE, "the other bosses keep their words")


# --- The schedule ---------------------------------------------------------------------------------------------

## A rhythm children can learn: arrive, circle, wind up (the line), dive, glide low; after every second dive it
## lands and rests, then takes off and circles again.
func test_the_schedule() -> void:
	assert_eq(SkyDragonRules.next_phase(P.RISE, 0), P.CIRCLE)
	assert_eq(SkyDragonRules.next_phase(P.CIRCLE, 0), P.DIVE_WARN)
	assert_eq(SkyDragonRules.next_phase(P.DIVE_WARN, 0), P.DIVE)
	assert_eq(SkyDragonRules.next_phase(P.DIVE, 1), P.GLIDE)
	assert_eq(SkyDragonRules.next_phase(P.GLIDE, 1), P.CLIMB, "one dive: back up")
	assert_eq(SkyDragonRules.next_phase(P.GLIDE, SkyDragonRules.DIVES_BEFORE_REST), P.LAND, "every second dive: it lands")
	assert_eq(SkyDragonRules.next_phase(P.CLIMB, 1), P.CIRCLE)
	assert_eq(SkyDragonRules.next_phase(P.LAND, 2), P.REST)
	assert_eq(SkyDragonRules.next_phase(P.REST, 0), P.TAKE_OFF)
	assert_eq(SkyDragonRules.next_phase(P.TAKE_OFF, 0), P.CIRCLE)
	assert_eq(SkyDragonRules.next_phase(P.DOWN, 0), P.DOWN)
	assert_eq(SkyDragonRules.DIVES_BEFORE_REST, 2)


## Every dive is signalled for 1.2-1.5 s (the brief), tired or not; the dive itself lasts as long as its line.
func test_every_dive_is_signalled_first() -> void:
	for tired in [false, true]:
		var warn := SkyDragonRules.phase_time(P.DIVE_WARN, tired)
		assert_between(warn, 1.2, 1.5, "the line shows 1.2-1.5 s before the dive (tired %s)" % tired)
		assert_true(SkyDragonRules.is_warning(P.DIVE_WARN))
	for phase in [P.CIRCLE, P.DIVE, P.GLIDE, P.REST]:
		assert_false(SkyDragonRules.is_warning(phase))
	assert_almost_eq(SkyDragonRules.phase_time(P.DIVE, false, 26.0), 26.0 / SkyDragonRules.DIVE_SPEED, 0.001)
	assert_eq(SkyDragonRules.phase_time(P.DOWN, false), INF)
	assert_gte(SkyDragonRules.phase_time(P.REST, false), 3.0, "a real rest to hit it in")
	assert_gte(SkyDragonRules.phase_time(P.GLIDE, false), 2.0, "a real window after a dive")


func test_a_tired_dragon_is_slower_and_raises_fewer_towers() -> void:
	assert_lt(SkyDragonRules.dive_speed(true), SkyDragonRules.dive_speed(false), "slower dives")
	assert_gt(SkyDragonRules.phase_time(P.REST, true), SkyDragonRules.phase_time(P.REST, false), "longer rests")
	assert_gt(SkyDragonRules.phase_time(P.GLIDE, true), SkyDragonRules.phase_time(P.GLIDE, false), "longer low glides")
	assert_gte(SkyDragonRules.phase_time(P.CIRCLE, true), SkyDragonRules.phase_time(P.CIRCLE, false))
	assert_eq(SkyDragonRules.tower_count(false), 4)
	assert_eq(SkyDragonRules.tower_count(true), 3, "fewer towers")
	assert_almost_eq(SkyDragonRules.phase_time(P.DIVE, true, 26.0), 26.0 / SkyDragonRules.dive_speed(true), 0.001)


func test_when_it_can_be_hit_and_how_hard() -> void:
	for phase in [P.RISE, P.DOWN]:
		assert_false(SkyDragonRules.hittable(phase), "no hits while it arrives or is gone")
	for phase in [P.CIRCLE, P.DIVE_WARN, P.DIVE, P.GLIDE, P.CLIMB, P.LAND, P.REST, P.TAKE_OFF]:
		assert_true(SkyDragonRules.hittable(phase))
	assert_true(SkyDragonRules.is_resting(P.REST))
	assert_false(SkyDragonRules.is_resting(P.GLIDE))
	assert_eq(SkyDragonRules.hit_taken(5, true), 10, "resting: double, like the Golem's daze")
	assert_eq(SkyDragonRules.hit_taken(5, false), 5)
	assert_eq(SkyDragonRules.hit_taken(-3, true), 0)


# --- The dive -------------------------------------------------------------------------------------------------

## The line starts under the dragon, runs through the child and on past them; it is never shorter than DIVE_MIN.
func test_the_dive_line_runs_through_the_child_and_on() -> void:
	var start := Vector3(12, 41.5, 0)
	var child := Vector3(0, 32, 0.5)
	var line := SkyDragonRules.dive_line(start, child, CENTER)
	var from: Vector3 = line[0]
	var to: Vector3 = line[1]
	assert_almost_eq(from.x, start.x, 0.001, "it starts right under the dragon")
	assert_almost_eq(from.z, start.z, 0.001)
	assert_eq(from.y, child.y, "on the ground where the child stands")
	assert_eq(to.y, child.y)
	assert_lt(_off_line(child, from, to), 0.01, "the child is on the line")
	assert_almost_eq(Vector2(to.x - child.x, to.z - child.z).length(), SkyDragonRules.DIVE_OVERSHOOT, 0.01, "and it goes on past them")
	var near := SkyDragonRules.dive_line(Vector3(1, 41.5, 0), Vector3(3, 32, 0), CENTER)
	assert_gte(_flat(near[0], near[1]), SkyDragonRules.DIVE_MIN - 0.001, "never a stub")
	var below := SkyDragonRules.dive_line(Vector3(5, 41.5, 5), Vector3(5, 32, 5), CENTER)
	assert_gte(_flat(below[0], below[1]), SkyDragonRules.DIVE_MIN - 0.001, "a child right under it still gets a real line")


## The line never leaves the arena circle: a child far out gets a line that stops at its edge.
func test_the_dive_line_stays_inside_the_arena() -> void:
	var start := Vector3(-12, 41.5, 0)
	var child := Vector3(SkyDragonRules.ARENA_LIMIT - 2.0, 32, 0)
	var line := SkyDragonRules.dive_line(start, child, CENTER)
	assert_lte(_flat(line[1], CENTER), SkyDragonRules.ARENA_LIMIT + 0.001, "the end is inside")
	assert_lte(_flat(line[0], CENTER), SkyDragonRules.ARENA_LIMIT + 0.001, "the start is inside")
	var outside := SkyDragonRules.dive_line(Vector3(0, 41.5, 12), Vector3(0, 32, 60), CENTER)
	assert_lte(_flat(outside[1], CENTER), SkyDragonRules.ARENA_LIMIT + 0.001, "a child outside: it stops at the edge")
	for p in [Vector3(50, 40, 0), Vector3(-3, 40, 4), Vector3(0, 40, -45)]:
		assert_lte(_flat(SkyDragonRules.keep_in(p, CENTER), CENTER), SkyDragonRules.ARENA_LIMIT + 0.001)
		assert_eq(SkyDragonRules.keep_in(p, CENTER).y, p.y, "keep_in only moves it sideways")
	assert_eq(SkyDragonRules.keep_in(Vector3(-3, 40, 4), CENTER), Vector3(-3, 40, 4), "inside stays put")


## It comes down steeply from where it hovered and is low (DIVE_LOW) before it reaches the child.
func test_the_dive_swoops_down_before_the_child() -> void:
	var high := SkyDragonRules.FLY_HEIGHT + SkyDragonRules.WARN_RISE
	assert_almost_eq(SkyDragonRules.dive_height(0.0, 12.0, high), high, 0.001, "it starts where it hovered")
	assert_almost_eq(SkyDragonRules.dive_height(12.0, 12.0, high), SkyDragonRules.DIVE_LOW, 0.001, "low at the child")
	assert_almost_eq(SkyDragonRules.dive_height(18.0, 12.0, high), SkyDragonRules.DIVE_LOW, 0.001, "and past them")
	var last := INF
	for i in 25:
		var h := SkyDragonRules.dive_height(i * 0.5, 12.0, high)
		assert_lte(h, last, "only down")
		assert_gte(h, SkyDragonRules.DIVE_LOW, "never into the ground")
		last = h


## Whoever stands on the line (feet within DIVE_REACH) when it passes low is hit; a step off dodges; while it is
## still high over the start of the line nobody is hit.
func test_who_the_dive_hits() -> void:
	var from := Vector3(0, 32.4, 0)
	var to := Vector3(0, 32.4, -1)
	var targets := [
		{"pos": Vector3(0, 32, -0.5)},                                  # on the line
		{"pos": Vector3(SkyDragonRules.DIVE_REACH + 0.4, 32, -0.5)},   # a step off it
		{"pos": Vector3(-0.8, 33.2, -0.5)},                             # jumping, still on it
		{"pos": Vector3(0, 32, -6)},                                    # further along: not yet
		{"pos": Vector3(0, 40, -0.5)},                                  # far above it
	]
	assert_eq(SkyDragonRules.dive_hits(from, to, targets), [0, 2] as Array[int])
	var high := [{"pos": Vector3(0, 32, -0.5)}]
	assert_eq(SkyDragonRules.dive_hits(Vector3(0, 38, 0), Vector3(0, 38, -1), high), [] as Array[int], "too high to hit")
	assert_lte(SkyDragonRules.DIVE_REACH, SkyDragonRules.LINE_HALF_WIDTH, "off the drawn line is always safe")
	assert_eq(SkyDragonRules.DIVE_DAMAGE, 4, "a fair hit, like the Golem's slam")


## The push goes sideways off the line on the child's side, and never out of the arena: near its edge, inwards.
func test_the_push_never_throws_a_child_out_of_the_arena() -> void:
	var dir := Vector3(0, 0, -1)
	var right := SkyDragonRules.dive_push(dir, Vector3(0.6, 32, -3), Vector3(0, 32.4, -3), CENTER)
	assert_gt(right.x, 0.0, "off the line on their side")
	assert_gt(right.y, 0.0, "a hop up")
	var left := SkyDragonRules.dive_push(dir, Vector3(-0.6, 32, -3), Vector3(0, 32.4, -3), CENTER)
	assert_lt(left.x, 0.0)
	var edge := Vector3(SkyDragonRules.PUSH_INWARD_BEYOND + 2.0, 32, -3)
	var inward := SkyDragonRules.dive_push(dir, edge, Vector3(edge.x - 0.6, 32.4, -3), CENTER)
	assert_lt(inward.x, 0.0, "a child near the edge is pushed back in, not out")
	assert_lte(Vector2(right.x, right.z).length(), SkyDragonRules.DIVE_PUSH + 0.001, "a fair push")


# --- Flying above the ground ----------------------------------------------------------------------------------

## The ground from the one it knew nearby: two cells on flat ground, up over cover, down a slope, never into water,
## and over the void the height it knew.
func test_the_ground_under_it() -> void:
	var reads := [0]
	var flat := func(c: Vector3i) -> int:
		reads[0] += 1
		return BlockIds.STONE if c.y < 32 else BlockIds.AIR
	assert_eq(SkyDragonRules.column_floor(3.5, 2.5, 32.0, flat), 32.0, "the arena's flat ground")
	assert_lte(reads[0], 2, "two cells on flat ground")
	assert_eq(SkyDragonRules.column_floor(3.5, 2.5, 40.0, flat), 32.0, "down to it")
	assert_eq(SkyDragonRules.column_floor(3.5, 2.5, 25.0, flat), 32.0, "up to it")
	var pillar := func(c: Vector3i) -> int:
		if c.y < 32 or (c.x == 3 and c.z == 2 and c.y < 34):
			return BlockIds.STONE
		return BlockIds.AIR
	assert_eq(SkyDragonRules.column_floor(3.5, 2.5, 32.0, pillar), 34.0, "on top of a pillar of cover")
	var water := func(c: Vector3i) -> int: return BlockIds.STONE if c.y < 28 else (BlockIds.WATER if c.y < 31 else BlockIds.AIR)
	assert_eq(SkyDragonRules.column_floor(0.5, 0.5, 36.0, water), 31.0, "never down into water")
	var void_ := func(_c: Vector3i) -> int: return BlockIds.AIR
	assert_eq(SkyDragonRules.column_floor(0.5, 0.5, 30.0, void_), 30.0, "over the void: the height it knew")


## Its body is wider than its feet: the ground under it is the highest under its footprint.
func test_the_ground_under_its_body() -> void:
	var pillar := func(c: Vector3i) -> int:
		if c.y < 32 or (c.x == 4 and c.z == 2 and c.y < 34):
			return BlockIds.STONE
		return BlockIds.AIR
	assert_eq(SkyDragonRules.column_floor(3.5, 2.5, 32.0, pillar), 32.0, "beside the pillar ...")
	assert_eq(SkyDragonRules.floor_under_body(3.5, 2.5, 32.0, pillar), 34.0, "... but its body is over it")
	assert_eq(SkyDragonRules.floor_under_body(3.5, 3.5, 32.0, pillar), 34.0, "diagonally too")
	assert_eq(SkyDragonRules.floor_under_body(1.5, 2.5, 32.0, pillar), 32.0, "clear of it")
	assert_eq(SkyDragonRules.floor_under_body(3.5, 2.5, 32.0, pillar, 0.0), 32.0, "reach 0: its feet only")


## Along a dive's line cover raises the swoop a little before and after it (a flat top, then 1 m down per metre).
func test_the_ground_along_a_dive() -> void:
	var raw := PackedFloat32Array()
	for i in 21:
		raw.append(34.0 if i == 10 else 32.0)
	var sp := SkyDragonRules.DIVE_SAMPLE
	var s := SkyDragonRules.smooth_floors(raw, sp)
	assert_eq(s.size(), raw.size())
	var top := ceili(SkyDragonRules.PLATEAU / sp)
	for i in range(10 - top, 10 + top + 1):
		assert_eq(s[i], 34.0, "a flat top round the cover (%d)" % i)
	assert_almost_eq(s[10 - top - 1], 34.0 - sp, 0.001, "then it slopes down 1 m per metre")
	assert_almost_eq(s[10 + top + 1], 34.0 - sp, 0.001)
	assert_eq(s[0], 32.0, "far away: the ground")
	for i in raw.size():
		assert_gte(s[i], raw[i], "never below the ground")


func test_the_circle() -> void:
	var p := SkyDragonRules.circle_point(CENTER, 0.0, 40.0)
	assert_almost_eq(_flat(p, CENTER), SkyDragonRules.CIRCLE_RADIUS, 0.001)
	assert_eq(p.y, 40.0)
	assert_lt(SkyDragonRules.CIRCLE_RADIUS, SkyDragonRules.ARENA_LIMIT)
	assert_lt(SkyDragonRules.ARENA_LIMIT, BossRules.ARENA, "the director's 'near' reaches wherever it flies")
	assert_gt(SkyDragonRules.FLY_HEIGHT, 5.0, "high over a jumping child and 2-block cover")


# --- Crystal towers -------------------------------------------------------------------------------------------

func test_crystal_towers_stand_round_the_arena() -> void:
	var first := SkyDragonRules.tower_spots(CENTER, 0, 4)
	assert_eq(first.size(), 4)
	for s: Vector3 in first:
		assert_almost_eq(_flat(s, CENTER), SkyDragonRules.TOWER_RING, 0.001)
		assert_eq(s.y, CENTER.y)
	for i in 4:
		for j in range(i + 1, 4):
			assert_gt(_flat(first[i], first[j]), 10.0, "spread out round the arena")
	var second := SkyDragonRules.tower_spots(CENTER, 1, 4)
	for s: Vector3 in second:
		for f: Vector3 in first:
			assert_gt(_flat(s, f), 3.0, "the second rise stands in new places")
	assert_eq(SkyDragonRules.tower_spots(CENTER, 0, 3).size(), 3)


## Each standing tower heals it a little every second (a share of its health, at least 1), never above its max.
func test_towers_heal_a_little_every_second() -> void:
	var m := SkyDragonRules.max_hp(1)
	var one := SkyDragonRules.heal_per_second(m, 1)
	assert_gte(one, 1)
	assert_lte(one, ceili(m * 0.01), "a little: at most 1% a second per tower")
	assert_eq(SkyDragonRules.heal_per_second(m, 4), 4 * one, "every standing tower heals")
	assert_eq(SkyDragonRules.heal_per_second(m, 0), 0, "broken towers heal nothing")
	assert_gt(SkyDragonRules.heal_per_second(SkyDragonRules.max_hp(3), 1), one, "a bigger team's dragon heals more")
	assert_eq(SkyDragonRules.healed(100, m, 2), 100 + 2 * one)
	assert_eq(SkyDragonRules.healed(m - 1, m, 4), m, "never above its health")
	assert_eq(SkyDragonRules.healed(0, m, 4), 0, "a beaten dragon stays beaten")


func test_towers_break_after_a_few_hits() -> void:
	assert_eq(SkyDragonRules.TOWER_HITS, 4)
	assert_true(SkyDragonRules.tower_standing(0))
	assert_true(SkyDragonRules.tower_standing(SkyDragonRules.TOWER_HITS - 1))
	assert_false(SkyDragonRules.tower_standing(SkyDragonRules.TOWER_HITS))
	var hits := PackedByteArray([0, 4, 2, 4])
	assert_eq(SkyDragonRules.standing(hits), 2)


## Towers rise at the start (after it arrives) and once more at a third of its health; not at two thirds, never a
## third time.
func test_phases_at_thirds() -> void:
	var m := 300
	assert_eq(SkyDragonRules.stage(300, m), 3)
	assert_eq(SkyDragonRules.stage(201, m), 3)
	assert_eq(SkyDragonRules.stage(200, m), 2, "two thirds")
	assert_eq(SkyDragonRules.stage(101, m), 2)
	assert_eq(SkyDragonRules.stage(100, m), 1, "a third")
	assert_eq(SkyDragonRules.stage(0, m), 0)
	assert_eq(SkyDragonRules.stage(10, 0), 3, "a broken max counts as whole")
	assert_false(SkyDragonRules.towers_due(0, 300, m), "the first rise comes when it has arrived, not by health")
	assert_false(SkyDragonRules.towers_due(1, 200, m), "nothing new at two thirds")
	assert_false(SkyDragonRules.towers_due(1, 101, m))
	assert_true(SkyDragonRules.towers_due(1, 100, m), "at a third: the towers rise again")
	assert_true(SkyDragonRules.towers_due(1, 40, m))
	assert_false(SkyDragonRules.towers_due(2, 40, m), "only once more")
	assert_false(SkyDragonRules.towers_due(1, 0, m), "not for a beaten dragon")
	assert_ne(SkyDragonRules.TOWER_LINE, SkyDragonRules.TOWER_LINE_AGAIN, "the second rise says it is new")


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _off_line(p: Vector3, a: Vector3, b: Vector3) -> float:
	var q := Vector2(p.x, p.z)
	return q.distance_to(Geometry2D.get_closest_point_to_segment(q, Vector2(a.x, a.z), Vector2(b.x, b.z)))
