extends GutTest
## Universe 6, the Glow Caves' boss (spec §5.1; brief): the Spore Mother as pure rules. A giant, friendly-faced glowing
## mushroom in a domed cavern arena; health by team size; every attack clearly signalled; spore clouds that slow and
## hurt only a little; puffs that hide her; weak spots (her gills) that glow when they are open; the BossRules pattern
## (the BossDirector's fight, bar, honest help, gold and portal).
## - SPORES: her cap glows and swells (SPORE_WARN), rings show on the ground where the children stand; clouds land
##   there: 1 HP and a slow (half speed for a few seconds) to whoever is still in a ring; the clouds linger a while
##   (walking into one slows, never hurts).
## - RING: she spins with her rim glowing (RING_WARN), then a ring of spores rolls out along the ground: 2 HP to
##   whoever stands on the ground within it (a jump clears it).
## - PUFF: she squats (PUFF_WARN), then hides in a big glittering puff (HIDDEN: no hits), gliding to a new spot.
## After every attack her gills glow open (GILLS_OPEN): double damage.

const S := preload("res://core/rules/spore_mother_rules.gd")
const P := preload("res://core/rules/spore_mother_rules.gd").Phase


func test_health_by_team_size_and_tired() -> void:
	assert_eq(S.max_hp(1), S.BASE_HP)
	assert_eq(S.max_hp(3), roundi(S.BASE_HP * 2.0), "half again per extra player or bot friend")
	assert_eq(S.max_hp(1, true), roundi(S.BASE_HP * BossRules.TIRED_SHARE), "the honest help's tired boss")
	assert_eq(BossRules.max_hp_of(BossRules.SPORE_MOTHER, 2), S.max_hp(2), "the BossDirector asks BossRules")


func test_her_words() -> void:
	var w := BossRules.words(BossRules.SPORE_MOTHER)
	for key in ["name", "title", "tired_title", "win", "tired", "summon"]:
		assert_ne(str(w.get(key, "")), "", key)
	assert_eq(w.name, "Spore Mother")
	assert_string_contains(str(w.summon), "%s")
	for line: String in [w.win, w.tired, w.summon]:
		for scary in ["kill", "die", "dead", "blood", "hurry"]:
			assert_false(line.to_lower().contains(scary), "calm words: %s" % line)


## A fixed rhythm children can learn: spores, the ring, the puff, again; every attack after a sway, every attack's
## wind-up a second or more, every attack followed by her open gills.
func test_the_schedule() -> void:
	assert_eq(S.attack_at(0), S.SPORES)
	assert_eq(S.attack_at(1), S.RING)
	assert_eq(S.attack_at(2), S.PUFF)
	assert_eq(S.attack_at(3), S.SPORES)
	assert_eq(S.next_phase(P.RISE, 0), P.SWAY)
	assert_eq(S.next_phase(P.SWAY, 0), P.SPORE_WARN)
	assert_eq(S.next_phase(P.SWAY, 1), P.RING_WARN)
	assert_eq(S.next_phase(P.SWAY, 2), P.PUFF_WARN)
	assert_eq(S.next_phase(P.SPORE_WARN, 0), P.GILLS_OPEN, "the clouds land as the warning ends")
	assert_eq(S.next_phase(P.RING_WARN, 1), P.GILLS_OPEN, "the ring rolls as the warning ends")
	assert_eq(S.next_phase(P.PUFF_WARN, 2), P.HIDDEN)
	assert_eq(S.next_phase(P.HIDDEN, 2), P.GILLS_OPEN)
	assert_eq(S.next_phase(P.GILLS_OPEN, 3), P.SWAY)
	for w in [P.SPORE_WARN, P.RING_WARN, P.PUFF_WARN]:
		assert_true(S.is_warning(w))
		assert_gte(S.phase_time(w), 0.8, "a clear signal")
	assert_gte(S.phase_time(P.SPORE_WARN), 1.2)
	assert_gte(S.phase_time(P.GILLS_OPEN), 2.0, "time to land a few hits")


func test_where_she_can_be_hit_and_the_open_gills() -> void:
	assert_false(S.hittable(P.RISE))
	assert_false(S.hittable(P.HIDDEN), "inside her puff")
	assert_false(S.hittable(P.DOWN))
	assert_true(S.hittable(P.SWAY))
	assert_true(S.hittable(P.SPORE_WARN))
	assert_true(S.hittable(P.GILLS_OPEN))
	assert_eq(S.hit_taken(5, P.GILLS_OPEN), 10, "her glowing gills are her weak spot")
	assert_eq(S.hit_taken(5, P.SWAY), 5)
	assert_eq(S.hit_taken(-3, P.SWAY), 0)
	assert_true(S.gills_open(P.GILLS_OPEN))
	assert_false(S.gills_open(P.SWAY))


## The spore clouds land on rings shown at each child's feet as the warning starts (no lead: a step out dodges them),
## and a few more round her; one that lands on a child: 1 HP and slowed.
func test_spore_clouds() -> void:
	var center := Vector3(0, 30, 0)
	var feet: Array[Vector3] = [Vector3(5, 30, 2), Vector3(-4, 30, -6)]
	var spots := S.cloud_spots(center, feet, 7)
	assert_eq(spots.size(), S.CLOUDS)
	assert_true(spots.has(feet[0]) and spots.has(feet[1]), "on the children's feet")
	for s: Vector3 in spots:
		assert_lte(Vector2(s.x, s.z).length(), S.ARENA_REACH + 0.01, "inside the arena")
	assert_eq(S.cloud_spots(center, feet, 7), spots, "the same for the same step (every screen draws them)")
	assert_true(S.cloud_hits(Vector3(5, 30, 2), Vector3(5.8, 30, 2.4)), "still in the ring")
	assert_false(S.cloud_hits(Vector3(5, 30, 2), Vector3(5 + S.CLOUD_R + 0.3, 30, 2)), "a step out of it")
	assert_false(S.cloud_hits(Vector3(5, 30, 2), Vector3(5, 33.5, 2)), "high above")
	assert_eq(S.damage(S.SPORES), 1, "a spore cloud hurts only a little")
	assert_lt(S.SLOW, 1.0)
	assert_gt(S.SLOW, 0.3, "slowed, never stuck")
	assert_between(S.SLOW_TIME, 2.0, 4.0)


## Lingering clouds slow whoever walks in (they never hurt) until they fade.
func test_lingering_clouds_slow() -> void:
	var clouds := [[Vector3(5, 30, 2), 3.0], [Vector3(-2, 30, 0), 0.0]]
	assert_true(S.in_cloud(Vector3(5.5, 30, 2), clouds))
	assert_false(S.in_cloud(Vector3(-2, 30, 0), clouds), "a faded cloud slows nobody")
	assert_false(S.in_cloud(Vector3(20, 30, 20), clouds))
	assert_gte(S.CLOUD_LINGER, 3.0)


## The spore ring rolls along the ground: whoever stands on the ground within it; a jump clears it.
func test_the_spore_ring() -> void:
	var c := Vector3(0, 30, 0)
	var targets := [{"pos": Vector3(4, 30, 0), "grounded": true}, {"pos": Vector3(4, 31.5, 0), "grounded": false},
		{"pos": Vector3(S.RING_RADIUS + 1.0, 30, 0), "grounded": true}]
	assert_eq(S.ring_hits(c, targets), [0] as Array[int])
	assert_eq(S.damage(S.RING), 2)


## Her puff carries her to a new spot SOME blocks away, never out of the arena.
func test_the_puff_moves_her_within_the_arena() -> void:
	var middle := Vector3(0, 30, 0)
	for step in 6:
		var to := S.puff_spot(Vector3(3, 30, 0), middle, step)
		assert_almost_eq(Vector2(to.x - 3, to.z).length(), S.PUFF_MOVE, 0.01, "step %d" % step)
		assert_lte(Vector2(to.x, to.z).length(), S.ARENA_REACH, "inside the arena")
	assert_ne(S.puff_spot(Vector3(3, 30, 0), middle, 0), S.puff_spot(Vector3(3, 30, 0), middle, 1), "somewhere new")
