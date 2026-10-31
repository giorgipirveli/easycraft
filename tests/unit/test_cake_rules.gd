extends GutTest
## M3 Task 4 (spec §14.1 "Cake Monster (layers fall off as it is hurt; each layer changes its attack)", §5.3
## "clearly signalled attacks, health scales with team size", research G3 "honest help"): the Candy Kingdom's
## boss as pure rules. Three tiers: while all three stand it sends a frosting wave (jump it); at two thirds of
## its health the top tier falls off and it throws cherries (three, spread: keep moving); at a third the middle
## one falls and it spins at you like a top (jump aside). Every attack is signalled by a wind-up, and after it
## the cake is dizzy (double damage). A falling layer is a pause: no hits, no attacks.

const P := CakeRules.Phase


func test_health_scales_with_the_team_and_a_tired_cake_has_less() -> void:
	assert_eq(CakeRules.max_hp(1), CakeRules.BASE_HP)
	assert_eq(CakeRules.max_hp(3), roundi(CakeRules.BASE_HP * 2.0), "each more player or bot friend adds half")
	assert_eq(CakeRules.max_hp(1, true), roundi(CakeRules.BASE_HP * BossRules.TIRED_SHARE), "honest help")
	assert_gt(CakeRules.BASE_HP, SerpentRules.BASE_HP, "the last universe's boss is the biggest")
	assert_eq(BossRules.max_hp_of(BossRules.CAKE, 2), CakeRules.max_hp(2), "the director asks BossRules")


func test_layers_fall_off_at_two_thirds_and_one_third() -> void:
	var m := 300
	assert_eq(CakeRules.layers_left(300, m), 3)
	assert_eq(CakeRules.layers_left(201, m), 3)
	assert_eq(CakeRules.layers_left(200, m), 2, "at two thirds the top tier falls")
	assert_eq(CakeRules.layers_left(101, m), 2)
	assert_eq(CakeRules.layers_left(100, m), 1, "at a third the middle one falls")
	assert_eq(CakeRules.layers_left(1, m), 1)
	assert_eq(CakeRules.layers_left(0, m), 0, "defeated")
	assert_eq(CakeRules.layers_left(150, 0), 3, "a broken max counts as whole")


func test_each_layer_has_its_own_attack() -> void:
	assert_eq(CakeRules.attack_for(3), CakeRules.WAVE)
	assert_eq(CakeRules.attack_for(2), CakeRules.CHERRIES)
	assert_eq(CakeRules.attack_for(1), CakeRules.SPIN)
	assert_eq(CakeRules.next_phase(P.WALK, 3), P.WAVE_WARN)
	assert_eq(CakeRules.next_phase(P.WALK, 2), P.CHERRY_WARN)
	assert_eq(CakeRules.next_phase(P.WALK, 1), P.SPIN_WARN)
	assert_ne(CakeRules.LAYER_LINES[2], CakeRules.LAYER_LINES[1], "a line says what comes next")


## A fixed rhythm children can learn: rise, walk, wind-up, the attack, dizzy, walk again.
func test_the_schedule() -> void:
	assert_eq(CakeRules.next_phase(P.RISE, 3), P.WALK)
	assert_eq(CakeRules.next_phase(P.WAVE_WARN, 3), P.DIZZY, "the wave lands as its wind-up ends")
	assert_eq(CakeRules.next_phase(P.CHERRY_WARN, 2), P.DIZZY, "the cherries fly as their wind-up ends")
	assert_eq(CakeRules.next_phase(P.SPIN_WARN, 1), P.SPIN)
	assert_eq(CakeRules.next_phase(P.SPIN, 1), P.DIZZY)
	assert_eq(CakeRules.next_phase(P.DIZZY, 2), P.WALK)
	assert_eq(CakeRules.next_phase(P.LAYER_DROP, 2), P.WALK)
	for phase in [P.WAVE_WARN, P.CHERRY_WARN, P.SPIN_WARN]:
		assert_gte(CakeRules.phase_time(phase), 1.0, "every attack is signalled for a second or more")
		assert_true(CakeRules.is_warning(phase))
	assert_almost_eq(CakeRules.phase_time(P.SPIN), CakeRules.SPIN_DISTANCE / CakeRules.SPIN_SPEED, 0.001)
	assert_eq(CakeRules.phase_time(P.DOWN), INF)


func test_when_it_can_be_hit_and_how_hard() -> void:
	for phase in [P.RISE, P.LAYER_DROP, P.DOWN]:
		assert_false(CakeRules.hittable(phase), "no hits while it rises, drops a layer or is down")
	for phase in [P.WALK, P.WAVE_WARN, P.CHERRY_WARN, P.SPIN_WARN, P.SPIN, P.DIZZY]:
		assert_true(CakeRules.hittable(phase))
	assert_eq(CakeRules.hit_taken(5, true), 10, "dizzy: double")
	assert_eq(CakeRules.hit_taken(5, false), 5)
	assert_eq(CakeRules.hit_taken(-3, true), 0)


## A layer falls when a hit takes the cake below a third: the hit ends there, so one big hit never skips the
## middle tier's cherries (each attack gets its turn).
func test_a_hit_never_skips_a_layer() -> void:
	var m := 300
	assert_eq(CakeRules.after_hit(210, 30, m), 200, "stops at the top tier's line")
	assert_eq(CakeRules.after_hit(200, 150, m), 100, "then at the middle one's")
	assert_eq(CakeRules.after_hit(100, 150, m), 0, "the last layer can be beaten")
	assert_eq(CakeRules.after_hit(250, 10, m), 240, "an ordinary hit")


func test_the_frosting_wave_hits_everyone_on_the_ground_nearby() -> void:
	var c := Vector3(0, 10, 0)
	var targets := [{"pos": Vector3(3, 10, 0), "grounded": true}, {"pos": Vector3(3, 11.5, 0), "grounded": false},
		{"pos": Vector3(CakeRules.WAVE_RADIUS + 1, 10, 0), "grounded": true}, {"pos": Vector3(0, 10, -2), "grounded": true}]
	assert_eq(CakeRules.wave_hits(c, targets), [0, 3] as Array[int], "a jump clears it; far away is safe")


## Three cherries: one where the child stands, one each side, CHERRY_SPREAD apart across the throw.
func test_cherries_land_at_the_child_and_to_each_side() -> void:
	var from := Vector3(0, 12, 0)
	var at := Vector3(0, 10, -8)
	var spots := CakeRules.cherry_spots(from, at)
	assert_eq(spots.size(), 3)
	assert_eq(spots[0], at, "the first at the child")
	for s: Vector3 in spots.slice(1):
		assert_almost_eq(absf(s.x - at.x), CakeRules.CHERRY_SPREAD, 0.001, "to the side across the throw")
		assert_almost_eq(s.z, at.z, 0.001)
		assert_eq(s.y, at.y)
	assert_eq(CakeRules.cherry_spots(from, from + Vector3(0, -2, 0)).size(), 3, "straight down still gives three")
	assert_eq(CakeRules.damage(CakeRules.CHERRIES), 3)
	assert_eq(CakeRules.damage(CakeRules.WAVE), 4)
	assert_eq(CakeRules.damage(CakeRules.SPIN), 5)


func test_its_words() -> void:
	var w := BossRules.words(BossRules.CAKE)
	assert_eq(w.name, "Cake Monster")
	assert_eq(w.title, "CAKE MONSTER")
	assert_string_contains(w.win, "Cake Monster")
	assert_string_contains(w.summon, "%s")
	assert_eq(WaveRules.boss_word(w.name), "The Cake Monster!")
