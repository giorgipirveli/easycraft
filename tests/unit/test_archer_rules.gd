extends GutTest
## M3 Task 14b (spec §13.7, build-fight practice): the goblin archer as pure rules. It shoots from 10 to 20
## blocks, backs off from a child who comes close, likes high ground, hides where a block stands between it
## and the child and steps out to shoot (signalled a second before); its arrows are slow, lobbed a little,
## and never go through a wall. It comes at night from level 2 and in waves from wave 4 (goblins only).

const A := MonsterRules.ARCHER
const FLOOR := 10

var _cells := {}


func before_each() -> void:
	_cells = {}


func _solid(c: Vector3i) -> bool:
	return c.y < FLOOR or BlockIds.is_solid(int(_cells.get(c, BlockIds.AIR)))


func _wall(x0: int, x1: int, z: int, height: int = 3) -> void:
	for x in range(x0, x1 + 1):
		for y in range(FLOOR, FLOOR + height):
			_cells[Vector3i(x, y, z)] = BlockIds.STONE


func test_the_archer_is_a_goblin_kind_with_a_one_second_signal() -> void:
	assert_true(MonsterRules.KINDS.has(A))
	assert_eq(String(A), "archer", "/summon archer")
	assert_eq(MonsterRules.behaviour(A), MonsterRules.SHOOTER)
	assert_eq(MonsterRules.windup(A), 1.0, "signalled 1 s before")
	assert_eq(MonsterRules.MEADOWS_KINDS, [MonsterRules.SLIME, MonsterRules.GOBLIN] as Array[StringName], "night pairs unchanged")
	for l in range(1, 6):
		assert_lt(MonsterRules.hp(A, l), MonsterRules.hp(MonsterRules.GOBLIN, l), "weaker than a goblin up close")
		assert_lte(MonsterRules.hit(A, l), MonsterRules.hit(MonsterRules.GOBLIN, l), "its arrows sting less than a club")
		assert_gt(MonsterRules.gold(A, l), 0)
	assert_lt(MonsterRules.speed(A, 1), 6.0, "slower than a walking child")


func test_it_shoots_from_10_to_20_blocks() -> void:
	var me := Vector3(0.5, FLOOR, 0.5)
	assert_false(ArcherRules.in_range(me, me + Vector3(0, 0, 8)))
	assert_true(ArcherRules.in_range(me, me + Vector3(0, 0, 10)))
	assert_true(ArcherRules.in_range(me, me + Vector3(12, 2, 9)))
	assert_true(ArcherRules.in_range(me, me + Vector3(0, 0, 20)))
	assert_false(ArcherRules.in_range(me, me + Vector3(0, 0, 21)))
	assert_true(ArcherRules.too_close(me, me + Vector3(3, 0, 0)), "a child this close: it backs off")
	assert_false(ArcherRules.too_close(me, me + Vector3(9, 0, 0)))


func test_its_arrows_are_slow_and_clearly_visible() -> void:
	assert_lte(ArcherRules.ARROW_SPEED, WeaponRules.ARROW_SPEED * 0.5, "much slower than a child's arrow")
	var flight := 16.0 / ArcherRules.ARROW_SPEED
	assert_gte(flight, 1.0, "a second or more to step aside at 16 blocks")


func test_an_arrow_reaches_a_child_in_the_open() -> void:
	var from := Vector3(0.5, FLOOR + 1.2, 0.5)
	var chest := Vector3(0.5, FLOOR + 1.0, -14.5)
	var v := ArcherRules.aim(from, chest)
	assert_almost_eq(v.length(), ArcherRules.ARROW_SPEED, 0.01)
	assert_true(ArcherRules.shot_reaches(from, v, chest, _solid), "lobbed onto the child")


func test_an_arrow_never_goes_through_a_wall() -> void:
	_wall(-3, 3, -7)
	var from := Vector3(0.5, FLOOR + 1.2, 0.5)
	var chest := Vector3(0.5, FLOOR + 1.0, -14.5)
	assert_false(ArcherRules.shot_reaches(from, ArcherRules.aim(from, chest), chest, _solid), "the wall stops it")
	_cells.clear()
	_wall(-3, 3, -7, 1)
	assert_true(ArcherRules.shot_reaches(from, ArcherRules.aim(from, chest), chest, _solid), "a low wall: it flies over")


func test_a_standing_spot_is_found_in_a_column() -> void:
	assert_eq(ArcherRules.stand_y(4, 4, FLOOR, _solid), FLOOR)
	_cells[Vector3i(4, FLOOR, 4)] = BlockIds.STONE
	_cells[Vector3i(4, FLOOR + 1, 4)] = BlockIds.STONE
	assert_eq(ArcherRules.stand_y(4, 4, FLOOR, _solid), FLOOR + 2, "on top of a 2-high pillar: high ground")
	for y in range(FLOOR, FLOOR + 8):
		_cells[Vector3i(6, y, 6)] = BlockIds.STONE
	assert_eq(ArcherRules.stand_y(6, 6, FLOOR, _solid), ArcherRules.NO_SPOT, "too tall to climb")


func test_a_spot_behind_a_block_is_cover_with_a_peek_beside_it() -> void:
	var target := Vector3(0.5, FLOOR, -14.5)
	var open := ArcherRules.score_spot(Vector3(4.5, FLOOR, 0.5), target, Vector3(4.5, FLOOR, 0.5), _solid)
	assert_false(open.is_empty())
	assert_false(open.cover, "nothing between")
	assert_eq(open.peek, Vector3(4.5, FLOOR, 0.5), "it shoots from where it stands")
	_wall(0, 0, -1, 2)                  # one block, two high, right in front of (0, -0)
	var behind := ArcherRules.score_spot(Vector3(0.5, FLOOR, 0.5), target, Vector3(0.5, FLOOR, 0.5), _solid)
	assert_false(behind.is_empty())
	assert_true(behind.cover, "a block between it and the child")
	var peek: Vector3 = behind.peek
	assert_eq(peek.y, float(FLOOR))
	assert_eq(absf(peek.x - 0.5), 1.0, "one step to the side")
	assert_true(MonsterRules.clear_line(peek + Vector3(0, ArcherRules.EYE, 0), target + Vector3(0, 1.0, 0), _solid), "a clear shot from there")
	assert_gt(behind.score, open.score, "cover scores better")


func test_a_spot_out_of_range_or_without_a_way_to_shoot_is_no_good() -> void:
	var target := Vector3(0.5, FLOOR, -14.5)
	assert_true(ArcherRules.score_spot(Vector3(0.5, FLOOR, -9.5), target, Vector3.ZERO, _solid).is_empty(), "5 blocks: too close")
	_wall(-3, 3, -1, 3)                 # a long wall: no side step clears it
	assert_true(ArcherRules.score_spot(Vector3(0.5, FLOOR, 0.5), target, Vector3(0.5, FLOOR, 0.5), _solid).is_empty())


func test_high_ground_scores_better() -> void:
	var target := Vector3(0.5, FLOOR, -14.5)
	var low := ArcherRules.score_spot(Vector3(4.5, FLOOR, 0.5), target, Vector3(4.5, FLOOR, 0.5), _solid)
	var high := ArcherRules.score_spot(Vector3(4.5, FLOOR + 2, 0.5), target, Vector3(4.5, FLOOR, 0.5), _solid)
	assert_gt(high.score, low.score)


func test_the_search_looks_at_rings_around_it() -> void:
	var seen := {}
	for i in ArcherRules.CANDIDATES:
		var c := ArcherRules.candidate(i)
		seen[c] = true
		var r := Vector2(c).length()
		assert_between(r, 1.5, 6.5, "%s" % c)
	assert_eq(seen.size(), ArcherRules.CANDIDATES, "all different")


func test_archers_come_at_night_from_level_2_and_only_instead_of_goblins() -> void:
	assert_eq(ArcherRules.night_kind(MonsterRules.GOBLIN, 1, 0.0), MonsterRules.GOBLIN, "level 1: a goblin")
	assert_eq(ArcherRules.night_kind(MonsterRules.GOBLIN, 2, 0.0), A)
	assert_eq(ArcherRules.night_kind(MonsterRules.GOBLIN, 3, 0.99), MonsterRules.GOBLIN, "some goblins stay goblins")
	assert_eq(ArcherRules.night_kind(MonsterRules.SLIME, 4, 0.0), MonsterRules.SLIME)
	assert_eq(ArcherRules.night_kind(MonsterRules.MUMMY, 4, 0.0), MonsterRules.MUMMY)


func test_archers_join_waves_from_wave_4() -> void:
	for n in [1, 2, 3]:
		var r := ArcherRules.wave_roster(WaveRules.roster(n, false), n)
		assert_eq(r, WaveRules.roster(n, false), "wave %d unchanged" % n)
	var r4 := ArcherRules.wave_roster(WaveRules.roster(4, false), 4)
	var archers := r4.filter(func(e: Dictionary) -> bool: return e.kind == A).size()
	var goblins := r4.filter(func(e: Dictionary) -> bool: return e.kind == MonsterRules.GOBLIN).size()
	assert_gt(archers, 0)
	assert_gt(goblins, 0, "goblins still come")
	assert_eq(r4.size(), WaveRules.roster(4, false).size(), "as many monsters")
	var desert := ArcherRules.wave_roster(WaveRules.roster(6, false, 1, MonsterRules.DESERT_KINDS), 6)
	assert_eq(desert, WaveRules.roster(6, false, 1, MonsterRules.DESERT_KINDS), "no goblins in the desert: no archers")
