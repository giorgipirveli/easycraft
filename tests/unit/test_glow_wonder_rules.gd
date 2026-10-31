extends GutTest
## Universe 6, the Glow Caves (owner #122, docs/design/learning-is-play.md §3): the Cave Wonders as pure rules. Each
## real fact is the move that wins a small play in the world, and a fact line comes only after the try:
## - Glow-worm Grotto (bioluminescence): the glow-worms brighten while a child in the grotto is dark and still (crouched
##   or standing, no spore lamp in hand) and dim when the child is noisy or bright; held bright, they show the way.
## - Drip Stone (how stalactites grow): a drop falls every few seconds; a tap as it lands catches its calcite; every few
##   caught drops grow a flowstone step; the steps reach a ledge. The years the drops stand for are counted.
## - Echo Fork (echolocation): a click's echo comes back from each tunnel after twice its length over the speed of
##   sound (slowed down so a child hears it); the latest echo is the long, open tunnel.
## - Rain Carver (how caves form): rainwater is a weak acid: poured on limestone (cave stone) it dissolves it; granite
##   it never does.
## - Blind Fish Lake (why cave fish are blind): a lamp means nothing to them; ripples in the water bring them.
## Words are short, kind, English; every fact has a hook before it (the problem first) and fits one line.

const W := preload("res://core/rules/glow_wonder_rules.gd")


func test_the_wonders_and_their_words() -> void:
	assert_eq(W.KINDS, [W.GROTTO, W.DRIP, W.ECHO, W.RAIN, W.LAKE] as Array[StringName], "the five plays in the world")
	for kind: StringName in W.BOOK:
		assert_ne(W.name_of(kind), "", String(kind))
		assert_ne(str(W.FACTS.get(kind, "")), "", "%s has its see-why line" % kind)
		assert_lte(str(W.FACTS[kind]).length(), 150, "%s: one or two lines" % kind)
		assert_ne(str(W.BOOK_LINES.get(kind, "")), "", "%s: the book's line" % kind)
		assert_lte(str(W.BOOK_LINES[kind]).length(), 52, "%s: fits a book slot" % kind)
		for bad in ["die", "kill", "dead", "scary", "hurry", "last chance"]:
			assert_false(str(W.FACTS[kind]).to_lower().contains(bad), "%s: calm words" % kind)
	for kind: StringName in W.KINDS:
		assert_ne(str(W.HOOKS.get(kind, "")), "", "%s opens with a problem in the world, not a fact" % kind)
		assert_false(str(W.HOOKS[kind]).contains(str(W.FACTS[kind]).left(20)), "the hook never tells the answer")
		assert_ne(str(W.WINS.get(kind, "")), "", "%s: the world cheers the move first" % kind)
		assert_lte(str(W.WINS[kind]).length(), 48, "%s: a short cheer" % kind)
		assert_true(W.win_words(kind).begins_with(str(W.WINS[kind])), "the cheer, then ...")
		assert_true(W.win_words(kind).ends_with(str(W.FACTS[kind])), "... the see-why fact")


## Glow-worms: dark and still makes them shine; noise or a lamp in hand dims them; outside the grotto they rest.
func test_glow_worms_shine_for_a_dark_quiet_child() -> void:
	assert_eq(W.worm_target(true, 0.0, false), 1.0, "standing still in the dark")
	assert_eq(W.worm_target(true, StealthRules.NOISE_CROUCH, false), 1.0, "crouch-walking is quiet enough")
	assert_lt(W.worm_target(true, StealthRules.NOISE_WALK, false), 0.5, "walking about: they dim")
	assert_lt(W.worm_target(true, 0.0, true), 0.5, "a spore lamp in hand: they dim")
	assert_almost_eq(W.worm_target(false, 0.0, false), W.WORM_REST, 0.001, "nobody in the grotto: a soft resting glow")
	var b := W.WORM_REST
	var t := 0.0
	while b < W.WORM_SHOW and t < 20.0:
		b = W.worm_step(b, 1.0, 0.1)
		t += 0.1
	assert_between(t, 1.5, 6.0, "they brighten over a few seconds: %.1f" % t)
	assert_lt(W.worm_step(1.0, 0.2, 0.5), 1.0, "and dim faster")
	assert_false(W.worms_solved(W.WORM_SHOW, W.WORM_HOLD - 0.1))
	assert_true(W.worms_solved(W.WORM_SHOW, W.WORM_HOLD + 0.1), "held bright for a moment: the way shows")


## Drips: one drop every DROP_EVERY; it lands DROP_FALL after it leaves the tip; a tap within CATCH of landing catches it.
func test_drips_are_caught_as_they_land() -> void:
	assert_gt(W.DROP_EVERY, W.DROP_FALL + W.CATCH, "one drop at a time")
	assert_true(W.caught(W.DROP_FALL))
	assert_true(W.caught(W.DROP_FALL + W.CATCH - 0.01))
	assert_true(W.caught(W.DROP_EVERY * 3 + W.DROP_FALL - W.CATCH + 0.01), "every drop, not just the first")
	assert_false(W.caught(W.DROP_FALL - W.CATCH - 0.05), "too early: the drop is still falling")
	assert_false(W.caught(W.DROP_FALL + W.CATCH + 0.05), "too late: it splashed")
	assert_eq(W.drop_number(W.DROP_EVERY * 2.5), 2)
	assert_eq(W.steps_for(0), 0)
	assert_eq(W.steps_for(W.DROPS_PER_STEP - 1), 0)
	assert_eq(W.steps_for(W.DROPS_PER_STEP * 3), 3, "a step for every few drops")
	assert_eq(W.years(10), 10 * W.YEARS_PER_DROP, "the years the drops stand for")
	assert_gte(W.YEARS_PER_DROP, 20, "slow: decades for a drop's ring")


## Echoes: twice the way there over the speed of sound, slowed down SLOWED times so a child hears the difference.
func test_echoes_come_back_later_from_longer_tunnels() -> void:
	assert_almost_eq(W.echo_delay(10.0), 2.0 * 10.0 / 343.0 * W.SLOWED, 0.0001)
	assert_lt(W.echo_delay(3.0), W.echo_delay(6.0))
	assert_gte(W.echo_delay(11.0) - W.echo_delay(6.0), 0.5, "far enough apart to hear")
	assert_eq(W.longest([3.0, 11.0, 6.0]), 1, "the latest echo: the long tunnel")
	assert_eq(W.ECHO_LENGTHS.size(), 3)
	var arrangements := {}
	for v in 12:
		var order := W.echo_order(v)
		assert_eq(order.size(), 3)
		arrangements[str(order)] = true
	assert_gte(arrangements.size(), 3, "the long tunnel is not always in the same place (never the same twice)")


## Rainwater dissolves limestone (the caves' rock), never granite.
func test_rainwater_dissolves_limestone_not_granite() -> void:
	assert_true(W.dissolves(BlockIds.CAVE_STONE), "the caves' limestone")
	assert_true(W.dissolves(BlockIds.LIMESTONE))
	assert_false(W.dissolves(BlockIds.GRANITE))
	assert_false(W.dissolves(BlockIds.STONE), "plain stone stays")
	assert_false(W.dissolves(BlockIds.AIR))
	assert_between(W.POURS_TO_OPEN, 2, 4, "a few pours: slow like real dissolving, quick enough to play")
	assert_eq(W.pours_left(0), W.POURS_TO_OPEN)
	assert_eq(W.pours_left(W.POURS_TO_OPEN - 1), 1)
	assert_eq(W.pours_left(W.POURS_TO_OPEN + 3), 0)


## The longest cave: a walk under the caves' roof long enough to feel the caves' size brings Mammoth Cave's length.
func test_a_long_walk_in_the_caves_brings_the_longest_cave() -> void:
	assert_between(W.LONGEST_WALK, 200.0, 1000.0, "a few minutes of exploring")
	assert_false(W.walked_far(W.LONGEST_WALK - 1.0))
	assert_true(W.walked_far(W.LONGEST_WALK))
	assert_lt(W.walk_step(Vector3.ZERO, Vector3(3, 0, 4)), 5.1, "sideways steps count")
	assert_eq(W.walk_step(Vector3.ZERO, Vector3(0, 9, 0)), 0.0, "falling or climbing is no walk")
	assert_eq(W.walk_step(Vector3.ZERO, Vector3(40, 0, 0)), 0.0, "a teleport or a respawn is no walk")


## Blind cave fish come to ripples, never to light.
func test_blind_fish_feel_ripples() -> void:
	assert_true(W.fish_come(W.RIPPLE))
	assert_false(W.fish_come(W.LIGHT))
	assert_eq(W.ripples_left(0), W.RIPPLES_NEEDED)
	assert_eq(W.ripples_left(W.RIPPLES_NEEDED + 2), 0)


func test_a_wonder_pays_once_fixed_gold_never_random() -> void:
	assert_eq(W.reward_gold(1), W.REWARD_GOLD)
	assert_eq(W.reward_gold(6), W.REWARD_GOLD * 32, "× 2^(u-1) like all Survivor gold")
	assert_eq(W.reward_gold(6), W.reward_gold(6))
