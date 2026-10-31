extends GutTest
## Owner #112 (docs/design/life-skills.md §5 #4, #5, §6 "country-aware"; Life L2): the words an Experience fills from
## the region and the run's seed. Safe Streets: the kerb drill's order and sides (the region's traffic side: the
## grown-ups' Life page), the side the near cars come from, the speed limit on the practice street's sign in the
## region's unit. The Kitchen: a recipe from somewhere in the world on each track, varied by the seed (a repeat comes back
## a little different), with what is cut, poured and weighed, and amounts that read as fractions.


func test_the_kerb_drill_follows_the_traffic_side() -> void:
	assert_eq(LifeRegion.look_sides("ge"), ["left", "right", "left"] as Array[String], "cars on the right: left first")
	assert_eq(LifeRegion.look_sides("uk"), ["right", "left", "right"] as Array[String])
	var v := LifeExperience.vars("safe_streets", "little", 1, "au")
	assert_eq(v.look_order, "right, left, right")
	assert_eq(v.look_sides, ["right", "left", "right"] as Array[String])
	assert_eq(v.first_side, "right")
	assert_eq(v.drive, "left")


func test_the_practice_streets_sign_in_the_regions_unit() -> void:
	assert_eq(LifeRegion.speed_unit("uk"), "mph")
	assert_eq(LifeRegion.speed_unit("us"), "mph")
	assert_eq(LifeRegion.speed_unit("ge"), "km/h")
	assert_eq(LifeRegion.speed_limit("ge"), 30, "a school street's 30")
	assert_eq(LifeRegion.speed_limit("uk"), 20)
	var v := LifeExperience.vars("safe_streets", "big", 1, "us")
	assert_lt(int(v.speed_lo), int(v.speed_hi))
	assert_eq(int(v.speed_hi), 20)
	assert_gt(int(v.speed_top), int(v.speed_hi))


func test_the_kitchen_cooks_from_many_countries_by_the_seed() -> void:
	for track in LifeData.TRACKS:
		var seen := {}
		for seed in 12:
			var v := LifeKitchen.vars(track, seed)
			for key: String in ["recipe", "recipe_from", "cut_food", "pour_what", "pour_words", "weigh_what"]:
				assert_ne(str(v.get(key, "")), "", "%s %d: %s" % [track, seed, key])
			assert_between(float(v.pour_want), 0.2, 1.0, track)
			assert_between(int(v.weigh_g), 25, 450, track)
			seen[v.recipe] = true
		assert_gte(seen.size(), 3, "%s: three recipes or more" % track)


func test_the_cups_amount_reads_as_a_fraction() -> void:
	assert_eq(LifeKitchen.cup_words(0.25), "a quarter of a cup (1/4)")
	assert_eq(LifeKitchen.cup_words(0.5), "half a cup (1/2)")
	assert_eq(LifeKitchen.cup_words(0.75), "three quarters of a cup (3/4)")
	var v := LifeExperience.vars("kitchen", "middle", 3, "ge")
	assert_eq(v.pour_words, LifeKitchen.cup_words(float(v.pour_want)))
