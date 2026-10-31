extends GutTest
## Universe 6, the Glow Caves (spec §5.1, §5.2's sneaker; brief: stealth-heavy darkness): its two monsters as pure
## rules, gentle and fair like every monster (§6, §12.4), and each one teaching a sense the caves are about.
## - Spore puff: a round, cartoon puffball mushroom that hides in the dark (the candy sneaker's behaviour: only a
##   shimmer near a child) and shows where there is light: a spore lamp, or the glow of moss and glowshrooms round it.
##   It SEES only by light: a child in the glow is seen far, one in the dark only close (the visibility meter). It
##   swells up (the signal) and bumps with a puff of spores: a small nip.
## - Cave crawler: a blind cave beetle with glowing feelers (real cave animals are often blind). It never sees; it
##   HEARS: footsteps, landings, breaking blocks find it (the noise meter), and it feels a child who touches it. A
##   child who crouch-walks past is never found. It raises its feelers and clicks (the signal) before a little nip.
## - Both: levels 1-5 by shape and colour, × 2^(u-1) in universe u, slower than a walking child.

const P := MonsterRules.SPORE_PUFF
const C := MonsterRules.CRAWLER


func test_the_glow_kinds_exist_beside_the_others() -> void:
	for k in [P, C]:
		assert_true(MonsterRules.KINDS.has(k), String(k))
		assert_false(MonsterRules.splits(k, 5))
		assert_lt(MonsterRules.speed(k, 5), 6.0, "%s is slower than a walking child" % k)
		assert_gt(MonsterRules.windup(k), 0.6, "%s signals every attack" % k)
	assert_eq(MonsterRules.GLOW_KINDS, [P, C] as Array[StringName])
	assert_eq(MonsterRules.behaviour(P), MonsterRules.SNEAKS, "the puff hides in the dark")
	assert_eq(MonsterRules.behaviour(C), MonsterRules.CHASER, "the crawler scuttles after a sound")
	assert_eq(MonsterRules.pick_kind(0.1, MonsterRules.GLOW_KINDS), P)
	assert_eq(MonsterRules.pick_kind(0.9, MonsterRules.GLOW_KINDS), C)


## A small nip each (1 + l/2), never the hard hit of a goblin; × 2^(u-1) in universe 6.
func test_their_stats() -> void:
	for l in range(1, 6):
		assert_eq(MonsterRules.hit(P, l), 1 + l / 2, "puff nip %d" % l)
		assert_eq(MonsterRules.hit(C, l), 1 + l / 2, "crawler nip %d" % l)
		assert_gt(MonsterRules.hp(P, l), 0)
		assert_gt(MonsterRules.gold(C, l), 0)
	assert_eq(MonsterRules.hp(P, 1, 6), MonsterRules.hp(P, 1) * 32, "universe 6 multiplies by 32")
	assert_eq(MonsterRules.hit(C, 1, 6), 32)
	assert_gt(MonsterRules.size_of(P, 5).y, MonsterRules.size_of(P, 1).y, "bigger at higher levels")


## The puff hides in the dark like the candy sneaker: in the light (a spore lamp near it) it shows; in the dark the
## child's own lantern shows it close by (PUFF_LIT), a shimmer a little further (and always while it winds up), nothing
## further away.
func test_the_puff_hides_in_the_dark_and_shows_in_the_light() -> void:
	assert_true(MonsterRules.hides_in_dark(P))
	assert_true(MonsterRules.hides_in_dark(MonsterRules.SNEAKER))
	assert_false(MonsterRules.hides_in_dark(C))
	assert_eq(MonsterRules.dark_look(P, false, false, 20.0), MonsterRules.SEEN, "in the light it shows")
	assert_eq(MonsterRules.dark_look(P, true, false, MonsterRules.PUFF_LIT - 0.5), MonsterRules.SEEN, "the lantern lights it")
	assert_eq(MonsterRules.dark_look(P, true, false, MonsterRules.PUFF_LIT + 1.0), MonsterRules.SHIMMER)
	assert_eq(MonsterRules.dark_look(P, true, true, 15.0), MonsterRules.SHIMMER, "its swelling always shows")
	assert_eq(MonsterRules.dark_look(P, true, false, 15.0), MonsterRules.HIDDEN)
	assert_eq(MonsterRules.dark_look(MonsterRules.SNEAKER, true, false, 3.0), MonsterRules.sneaker_look(true, false, 3.0),
		"the candy sneaker keeps its own rule")


## The crawler is blind: whatever the light, it sees nobody; it hears a moving child within the noise's radius and
## feels one who touches it; a crouch-walking child is heard only within the crouch's tiny radius.
func test_the_crawler_hears_and_never_sees() -> void:
	assert_true(MonsterRules.blind(C))
	assert_false(MonsterRules.blind(P))
	assert_false(MonsterRules.blind(MonsterRules.GOBLIN))
	assert_true(MonsterRules.heard_as_found(C, 5.0, StealthRules.NOISE_WALK), "a walking child 5 blocks off is found")
	assert_false(MonsterRules.heard_as_found(C, 8.0, StealthRules.NOISE_WALK), "beyond the walk's noise: not")
	assert_false(MonsterRules.heard_as_found(C, 3.0, StealthRules.NOISE_CROUCH), "a crouch-walk passes it")
	assert_true(MonsterRules.heard_as_found(C, MonsterRules.FEEL - 0.1, 0.0), "a child who touches it is felt")
	assert_true(MonsterRules.heard_as_found(C, 10.0, StealthRules.NOISE_SPRINT), "running is loud")
	assert_false(MonsterRules.heard_as_found(P, 2.0, StealthRules.NOISE_SPRINT), "the puff does not hunt by sound")


## In the caves a placed spore lamp is a light (no night monster comes near it; it lights a child up).
func test_the_spore_lamp_is_a_light() -> void:
	assert_true(MonsterRules.LIGHT_BLOCKS.has(BlockIds.SPORE_LAMP))
	assert_true(StealthRules.LIGHT_BLOCKS.has(BlockIds.SPORE_LAMP))
