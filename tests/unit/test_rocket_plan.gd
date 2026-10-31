extends GutTest
## Owner #98 (spec §21d, §25): Mission Control's plan for every mission and every crew of 1 to 4 astronauts (RocketPlan,
## a stored table made by tools/make_rocket_plans.gd with the real RocketCheck). Every plan must pass the whole check
## for its mission and crew with its own parts bought, be one piece standing on the pad, fit the 9 × 9 square and 24
## layers, and beat the mission's speed by at least RocketPlan.MARGIN. It is shaped like a rocket a child knows: centred
## stages, engines at the bottom of each stage, a separator under the next stage, legs round the lander's engine,
## capsules and a nose cone on top. Prices: the Moon's plan a good day of learning, Mars under 900, the far worlds
## mostly under 2,000, Mercury the dearest (its speed).

const E := BlockIds.ROCKET_ENGINE
const V := BlockIds.SPACE_ENGINE
const T := BlockIds.FUEL_TANK
const N := BlockIds.NOSE_CONE
const C := BlockIds.CREW_CAPSULE
const S := BlockIds.SERVICE_MODULE
const L := BlockIds.LANDING_LEGS
const F := BlockIds.ROCKET_FINS
const X := BlockIds.STAGE_SEPARATOR
const P := BlockIds.SOLAR_ARRAY

## Mission × crew pairs with no plan yet (the board says so plainly). Aim: none. Mercury's 24.3 km/s with 3 or 4
## astronauts needs more than the 78 rocket engines the pad's first layer holds round its fins (the generator searched
## up to 8 stages).
const NO_PLAN: Array = [[&"mercury", 3], [&"mercury", 4]]


func _moon() -> Dictionary:
	return MissionRules.for_world(SpaceRules.MOON)


func test_every_mission_and_crew_has_a_plan_that_passes_the_whole_check() -> void:
	for m: Dictionary in MissionRules.MISSIONS:
		for crew in range(1, RocketPlan.MAX_CREW + 1):
			var what := "%s, crew %d" % [m.id, crew]
			var cells := RocketPlan.cells(m, crew)
			if NO_PLAN.has([m.id, crew]):
				assert_true(cells.is_empty(), "%s: listed as having no plan" % what)
				continue
			assert_false(cells.is_empty(), "%s has a plan" % what)
			if cells.is_empty():
				continue
			var r := RocketCheck.check(cells, m, crew, RocketParts.count(cells))
			for l: Dictionary in r.lines:
				assert_true(l.ok, "%s: %s" % [what, l.text])
			assert_true(r.ok, what)
			assert_gte(float(r.dv) - float(r.need), RocketPlan.MARGIN, "%s beats its speed by %.2f km/s" % [what,
				RocketPlan.MARGIN])
			assert_eq((r.cells as Dictionary).size(), cells.size(), "%s: one piece, every part counted" % what)
			var top := -1
			for p: Vector3i in cells:
				assert_true(RocketCheck.in_square(p), "%s: %s inside the 9 × 9 square" % [what, p])
				top = maxi(top, p.y)
			assert_lte(top + 1, RocketPlan.MAX_LAYERS, "%s: %d layers" % [what, top + 1])
			assert_eq(RocketPlan.gold(m, crew), RocketParts.cost(RocketParts.count(cells)), what)
			assert_eq(RocketPlan.size(m, crew), cells.size(), what)


func test_a_plan_is_shaped_like_a_rocket() -> void:
	for m: Dictionary in MissionRules.MISSIONS:
		for crew in range(1, RocketPlan.MAX_CREW + 1):
			var cells := RocketPlan.cells(m, crew)
			if cells.is_empty():
				continue
			var what := "%s, crew %d" % [m.id, crew]
			var stages := RocketCheck.stages_of(cells)
			assert_eq(stages.size(), RocketPlan.stages_for(m, crew).size(), what)
			var top := -1
			for p: Vector3i in cells:
				top = maxi(top, p.y)
			assert_eq(cells.get(Vector3i(4, top, 4)), N, "%s: a nose cone on top, in the middle" % what)
			assert_eq(cells.get(Vector3i(4, top - 1, 4)), C, "%s: the capsules under it" % what)
			for i in stages.size():
				var bottom := 999
				for p: Vector3i in stages[i]:
					bottom = mini(bottom, p.y)
				assert_true(cells.has(Vector3i(4, bottom, 4)), "%s: stage %d stands on the middle" % [what, i + 1])
				assert_true(RocketParts.is_engine(int(cells.get(Vector3i(4, bottom, 4), 0))),
					"%s: stage %d's engines at its bottom" % [what, i + 1])
				for p: Vector3i in stages[i]:
					if RocketParts.is_engine(int(cells[p])):
						assert_eq(p.y, bottom, "%s: every engine of stage %d at its bottom" % [what, i + 1])
				if i < stages.size() - 1:
					var sep := 0
					for p: Vector3i in stages[i]:
						if int(cells[p]) == X:
							sep += 1
					assert_eq(sep, 1, "%s: one separator ends stage %d" % [what, i + 1])
			var lander: Array = stages[stages.size() - 1]
			var low := 999
			for p: Vector3i in lander:
				low = mini(low, p.y)
			var legs := 0
			for p: Vector3i in lander:
				if int(cells[p]) == L:
					legs += 1
					assert_eq(p.y, low, "%s: the legs stand round the lander's engine" % what)
			assert_eq(legs, RocketCheck.LEGS_NEEDED, what)
			var fins := 0
			for p: Vector3i in stages[0]:
				if int(cells[p]) == F:
					fins += 1
					assert_eq(p.y, 0, "%s: the fins round the first engines, on the pad" % what)
			assert_eq(fins, RocketCheck.FINS_NEEDED, what)


func test_the_lander_carries_a_capsule_and_a_service_module_for_each_astronaut() -> void:
	for crew in range(1, 5):
		var n := RocketParts.count(RocketPlan.cells(_moon(), crew))
		assert_eq(int(n.get(C, 0)), crew, "a seat each")
		assert_eq(int(n.get(S, 0)), crew, "a service module each: it keeps one astronaut for the whole trip")
		assert_eq(int(n.get(L, 0)), 3)
		assert_eq(int(n.get(P, 0)), 1)
		assert_eq(int(n.get(N, 0)), 1)
	var mars := RocketParts.count(RocketPlan.cells(MissionRules.for_world(SpaceRules.MARS), 1))
	assert_eq(int(mars.get(BlockIds.HEAT_SHIELD, 0)), 1, "Mars has air: a heat shield")
	assert_eq(int(mars.get(BlockIds.PARACHUTE_PACK, 0)), 1, "and a parachute")
	var triton := RocketParts.count(RocketPlan.cells(MissionRules.for_world(27), 1))
	assert_eq(int(triton.get(BlockIds.HEAT_SHIELD, 0)), 1, "Triton's thin air is skimmed behind a heat shield")
	assert_eq(int(triton.get(BlockIds.PARACHUTE_PACK, 0)), 0, "far too thin to land with")


func test_the_prices_of_the_plans_are_days_of_learning_not_weeks() -> void:
	var moon := RocketPlan.gold(_moon(), 1)
	assert_between(moon, 400, 550, "the Moon: one good day of learning (150 for answers, 100 a unit mastered)")
	assert_lte(RocketPlan.gold(MissionRules.for_world(SpaceRules.MARS), 1), 900, "Mars")
	var dearest := ""
	var top := 0
	var far_under := 0
	var far := 0
	for m: Dictionary in MissionRules.MISSIONS:
		var g := RocketPlan.gold(m, 1)
		if g > top:
			top = g
			dearest = str(m.id)
		if not m.id in [&"moon", &"mars"]:
			far += 1
			far_under += 1 if g <= 2000 else 0
	assert_eq(dearest, "mercury", "Mercury is the hardest: 24.3 km/s")
	assert_gte(far_under * 2, far, "most far worlds' plans cost 2,000 gold or less for one astronaut")
	assert_gt(RocketPlan.gold(_moon(), 2), moon, "a second astronaut costs more")
	assert_eq(int(SpendRules.GUIDE.moon_rocket), moon, "the shop's guide says the plan's price")
	assert_eq(int(SpendRules.GUIDE.mars_rocket), RocketPlan.gold(MissionRules.for_world(SpaceRules.MARS), 1))
	var dearest_part := 0
	for id in RocketParts.ORDER:
		dearest_part = maxi(dearest_part, RocketParts.price(id))
	assert_eq(int(SpendRules.GUIDE.first_part), dearest_part)


func test_the_plan_s_words_say_its_size_and_price() -> void:
	var size := RocketPlan.size(_moon(), 1)
	var gold := RocketPlan.gold(_moon(), 1)
	assert_eq(RocketPlan.card_words(_moon(), 1), "Mission Control's plan: %d parts, %d gold." % [size, gold])
	assert_eq(RocketPlan.no_plan_words(_moon(), 1), "", "the Moon has a plan")
	var words := RocketPlan.stage_words(RocketPlan.cells(_moon(), 1))
	assert_eq(words.size(), RocketPlan.stages_for(_moon(), 1).size(), "a line for each stage")
	assert_string_starts_with(words[0], "Stage 1: ")
	assert_string_contains(words[0], "rocket engines")
	assert_string_contains(words[0], "lift everything.")
	assert_string_contains(words[words.size() - 1], "the lander")


## A plan on a pad: cells that already hold the right part stay, empty cells (and water) get their part, other rocket
## parts in the build box go (they would join the rocket), and a child's other blocks are never broken: they block.
func test_the_diff_with_what_stands_on_the_pad() -> void:
	var plan := RocketPlan.cells(_moon(), 1)
	var d := RocketPlan.diff(plan, {})
	assert_eq((d.place as Array).size(), plan.size(), "an empty pad: every part placed")
	assert_eq(int(d.keep), 0)
	var pad := {}
	var some: Vector3i = plan.keys()[0]
	pad[some] = plan[some]                           # already right
	var other: Vector3i = plan.keys()[1]
	pad[other] = T if int(plan[other]) != T else E   # a different part: replaced
	pad[Vector3i(0, 30, 0)] = T                      # a stray part high in the box: it goes
	pad[Vector3i(8, 0, 8)] = BlockIds.STONE          # a child's block off the plan: it stays
	var wet: Vector3i = plan.keys()[2]
	pad[wet] = BlockIds.WATER                        # water is empty
	d = RocketPlan.diff(plan, pad)
	assert_eq(int(d.keep), 1)
	assert_eq((d.place as Array).size(), plan.size() - 1)
	assert_has(d.clear, [other, pad[other]])
	assert_has(d.clear, [Vector3i(0, 30, 0), T])
	assert_eq((d.clear as Array).size(), 2)
	assert_eq(d.blocked, [])
	var where: Vector3i = plan.keys()[3]
	pad[where] = BlockIds.PLANKS                     # a child's block where the rocket goes
	d = RocketPlan.diff(plan, pad)
	assert_eq(d.blocked, [where], "never broken: it must be moved first")
	assert_string_contains(RocketPlan.blocked_words(1), "1 block")
	assert_string_contains(RocketPlan.blocked_words(3), "3 blocks")


## Survivor: what the bag still lacks to build the plan (the parts cleared off the pad go back into it first).
func test_what_the_bag_still_needs() -> void:
	var plan := RocketPlan.cells(_moon(), 1)
	var bag := {}
	var need := RocketPlan.bag_short(plan, {}, func(id: int) -> int: return int(bag.get(id, 0)))
	assert_eq(need, RocketParts.count(plan), "an empty bag needs every part")
	bag = RocketParts.count(plan)
	assert_eq(RocketPlan.bag_short(plan, {}, func(id: int) -> int: return int(bag.get(id, 0))), {})
	bag = {}
	var half := {}
	for p: Vector3i in plan:
		if int(plan[p]) == T:
			half[p] = T
	var left := RocketPlan.bag_short(plan, half, func(id: int) -> int: return int(bag.get(id, 0)))
	assert_false(left.has(T), "the tanks already stand on the pad")


func test_layers_go_bottom_up_middle_first() -> void:
	var plan := RocketPlan.cells(_moon(), 1)
	var layers := RocketPlan.layers(plan)
	var n := 0
	for i in layers.size():
		for c: Array in layers[i]:
			assert_eq((c[0] as Vector3i).y, i)
			assert_eq(plan[c[0]], c[1])
			n += 1
		if not (layers[i] as Array).is_empty():
			assert_eq((layers[i][0][0] as Vector3i), Vector3i(4, i, 4), "the middle first")
	assert_eq(n, plan.size())
