extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5's rules table, rulings 7 and 29, §4.6): the altars a room
## offers, new every visit (seeded). Every generated altar holds for its hidden weight, can be freed within its budget,
## keeps a pan countable in phase B (at most 16 things: four rows of five; the model's top Great Altar, three crystals of
## 4 and 4 gems, makes 16; the twin forms are phase C's, their ranges set then), and takes its numbers from the School's generator's forms and ranges
## (G6AlgebraGen.solve_one_step: the crystal 1-15, a coefficient 2-12); the crystal stands on the right as often as the
## form says.

const HALL: Array[String] = ["bowls", "gem_bag"]
const SKY: Array[String] = ["bowls", "gem_bag", "pump"]
const TWIN: Array[String] = ["bowls", "gem_bag", "pump"]


func _forms_and_tools() -> Dictionary:
	return {"add_L": HALL, "add_R": HALL, "mul_L": HALL, "mul_R": HALL, "two_L": HALL, "two_R": HALL, "sub_L": SKY,
		"sub_R": SKY, "subtwo_L": SKY, "twin_L": TWIN, "twin_R": TWIN}


func test_every_altar_holds_and_can_be_freed_within_its_budget() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var forms := _forms_and_tools()
	for form: String in forms:
		for i in 60:
			var s := AltarGen.make(form, rng)
			assert_true(s.holds(), "%s %s holds" % [form, s])
			assert_false(s.freed(), "%s starts frozen" % form)
			assert_true(AltarSolver.solvable(s, forms[form]), "%s %s can be freed" % [form, s])
			assert_lte(AltarSolver.min_ops(s, forms[form]), 3, form)
			if form.begins_with("twin"):
				continue
			for pan in 2:
				assert_lte(absi(s.gems(pan)) + absi(s.crystals(pan)), 16, "%s %s: a pan stays countable" % [form, s])


func test_the_forms_are_what_their_names_say() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var add := AltarGen.make("add_L", rng)
	assert_true(add.lc == 1 and add.lk > 0 and add.rc == 0, "x + a = b: %s" % add)
	var right := AltarGen.make("add_R", rng)
	assert_true(right.rc == 1 and right.rk > 0 and right.lc == 0, "b = x + a: %s" % right)
	var mul := AltarGen.make("mul_L", rng)
	assert_true(mul.lc >= 2 and mul.lk == 0 and mul.rc == 0, "c x = b: %s" % mul)
	var two := AltarGen.make("two_L", rng)
	assert_true(two.lc >= 2 and two.lk > 0, "c x + a = b: %s" % two)
	var sub := AltarGen.make("sub_L", rng)
	assert_true(sub.lc == 1 and sub.lk < 0 and sub.rk > 0, "x - a = b (balloons beside the crystal): %s" % sub)
	var subtwo := AltarGen.make("subtwo_L", rng)
	assert_true(subtwo.lc >= 2 and subtwo.lk < 0, "c x - a = b: %s" % subtwo)
	var twin := AltarGen.make("twin_L", rng)
	assert_true(twin.lc > twin.rc and twin.rc >= 1, "a x + b = c x + d (crystals on both pans): %s" % twin)


func test_the_numbers_sit_in_the_school_s_generator_ranges() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for form: String in ["add_L", "add_R", "mul_L", "mul_R", "sub_L", "sub_R"]:
		for i in 200:
			var s := AltarGen.make(form, rng)
			assert_between(s.x, 1, 15, "%s: the crystal weighs what G6AlgebraGen's x can (1-15)" % form)
			var c := maxi(s.lc, s.rc)
			if c >= 2:
				assert_between(c, 2, 12, "%s: a coefficient G6AlgebraGen can make (2-12)" % form)
	for i in 200:
		assert_between(AltarGen.make("add_L", rng).x, 1, 8, "the hall's crystal weighs 1-8 (ruling 7)")


func test_the_same_seed_gives_the_same_altars() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 99
	b.seed = 99
	for form: String in ["add_L", "mul_R", "two_L", "sub_R", "subtwo_L"]:
		assert_true(AltarGen.make(form, a).same(AltarGen.make(form, b)), form)


func test_a_taught_altar_has_fixed_numbers() -> void:
	var s := AltarGen.fixed([1, 2, 0, 5], 3)
	assert_true(s.same(AltarState.make(1, 2, 0, 5, 3)))
	assert_true(s.holds())
	assert_true(AltarGen.forms().has("subtwo_L"))
	assert_true(AltarGen.forms().has("add_R"))
