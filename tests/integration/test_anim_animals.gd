extends GutTest
## Owner #94 (the animations brief §2): animals' small idle life on top of the wagging tails and grazing heads: now and
## then a standing animal hops (rabbits, frogs, the bunnies...), shakes itself (dogs, sheep, horses...) or sniffs the
## ground, each at its own rhythm; never while it walks, sits, swims, carries a rider or is golden; its body is exactly
## at rest after; a cheer cuts a fidget short cleanly.


func _animal(species: StringName, id: String = "") -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": id if id != "" else "life_%s" % species, "pos": Vector3.ZERO, "yaw": 0.0,
		"owner": 0, "name": "", "sitting": false})
	a.set_physics_process(false)   # no world: only its looks run
	add_child_autofree(a)
	return a


func test_every_species_has_its_fidget() -> void:
	assert_eq(AnimLife.action(&"rabbit"), AnimLife.HOP)
	assert_eq(AnimLife.action(&"dog"), AnimLife.SHAKE)
	assert_eq(AnimLife.action(&"cat"), AnimLife.SNIFF)
	assert_eq(AnimLife.action(&"fish"), &"", "a fish sways its own way")
	for s: StringName in AnimalRules.SPECIES:
		assert_has([AnimLife.HOP, AnimLife.SHAKE, AnimLife.SNIFF, &""], AnimLife.action(s), str(s))


func test_each_animal_keeps_its_own_rhythm() -> void:
	for n in 5:
		assert_between(AnimLife.wait("cow_1", n), AnimLife.WAIT.x * 0.5, AnimLife.WAIT.y)
	assert_eq(AnimLife.wait("cow_1", 3), AnimLife.wait("cow_1", 3), "the same animal, the same rhythm")
	assert_ne(AnimLife.wait("cow_1", 1), AnimLife.wait("cow_2", 1), "two cows are not in step")


func test_a_standing_rabbit_hops_now_and_then_and_lands_at_rest() -> void:
	var a := _animal(&"rabbit")
	a._life_step(AnimLife.WAIT.y + 1.0)
	assert_true(a._anim != null and a._anim.is_running(), "it hops")
	var highest := 0.0
	while a._anim.is_running():   # every frame of it, however slow the PC's frames are
		highest = maxf(highest, a._body.position.y)
		await wait_process_frames(1)
	assert_gt(highest, 0.05, "off the ground")
	assert_eq(a._body.position.y, 0.0, "back on its feet")


func test_a_dog_shakes_and_a_cat_sniffs_then_stand_straight() -> void:
	var dog := _animal(&"dog")
	var cat := _animal(&"cat")
	dog._life_step(AnimLife.WAIT.y + 1.0)
	cat._life_step(AnimLife.WAIT.y + 1.0)
	var shook := 0.0
	var dipped := 0.0
	while dog._anim.is_running() or cat._anim.is_running():   # every frame, however slow the PC's frames are
		shook = maxf(shook, absf(dog._body.rotation.z))
		dipped = minf(dipped, cat._body.rotation.x)
		await wait_process_frames(1)
	assert_gt(shook, 0.05, "a shake")
	assert_lt(dipped, -0.05, "a sniff: the nose down")
	assert_eq(dog._body.rotation.z, 0.0)
	assert_eq(cat._body.rotation.x, 0.0)


func test_no_fidget_while_sitting_walking_or_golden() -> void:
	var a := _animal(&"rabbit")
	a.sitting = true
	a._life_step(60.0)
	assert_true(a._anim == null or not a._anim.is_running(), "sitting")
	a.sitting = false
	a._moving = true
	a._life_step(60.0)
	assert_true(a._anim == null or not a._anim.is_running(), "walking")
	a._moving = false
	a.golden = true
	a._life_step(60.0)
	assert_true(a._anim == null or not a._anim.is_running(), "a golden one runs, it never stops to fidget")


func test_a_cheer_cuts_a_fidget_short_cleanly() -> void:
	var dog := _animal(&"dog")
	dog._life_step(AnimLife.WAIT.y + 1.0)
	await wait_seconds(0.1)
	dog.cheer()
	assert_eq(dog._body.rotation.z, 0.0, "straight again at once")
	await wait_seconds(0.5)
	assert_eq(dog._body.position.y, 0.0)


func test_forty_animals_fidgeting_are_cheap() -> void:
	var herd: Array[Animal] = []
	for i in 40:
		herd.append(_animal(&"sheep", "herd_%d" % i))
	var t0 := Time.get_ticks_usec()
	for f in 60:
		for a in herd:
			a._life_step(1.0 / 60.0)
	var per := (Time.get_ticks_usec() - t0) / 60.0
	gut.p("MEASURE 40 animals' idle life %.1f us a frame" % per)
	assert_lt(per, 400.0, "a small share of a frame")
