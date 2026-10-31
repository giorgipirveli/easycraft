extends GutTest
## M3 Task 21b (research C1): the Animal Book — a page for every animal kind in the species table
## (AnimalRules.SPECIES: read, never listed, so new animals get pages by themselves), a silhouette until
## met, then a picture, a name and a fun fact; fed and friend marks. Each mark comes once.


func test_every_kind_in_the_species_table_has_a_page() -> void:
	var kinds := AnimalBookRules.species()
	assert_eq(kinds.size(), AnimalRules.SPECIES.size(), "one page per kind, nothing listed by hand")
	for sp: StringName in AnimalRules.SPECIES:
		assert_has(kinds, sp)
		assert_ne(AnimalBookRules.name_of(sp), "", String(sp))
		assert_ne(AnimalBookRules.fact_of(sp), "", String(sp))
		assert_lte(AnimalBookRules.fact_of(sp).length(), 80, "a fun fact is short: %s" % sp)


func test_a_kind_nobody_wrote_a_fact_for_still_gets_a_page() -> void:
	assert_eq(AnimalBookRules.fact_of(&"axolotl"), AnimalBookRules.DEFAULT_FACT)
	assert_eq(AnimalBookRules.name_of(&"sea_turtle"), "Sea Turtle")


func test_a_mark_comes_once_and_feeding_or_a_friend_means_met() -> void:
	var w := WonderData.new()
	assert_false(AnimalBookRules.knows(w, &"cat"))
	assert_true(AnimalBookRules.record(w, &"cat", WonderData.FED), "new")
	assert_true(AnimalBookRules.knows(w, &"cat"), "fed means met")
	assert_false(AnimalBookRules.record(w, &"cat", WonderData.FED), "once")
	assert_false(AnimalBookRules.record(w, &"cat", WonderData.MET), "met already")
	assert_true(AnimalBookRules.record(w, &"cat", WonderData.FRIEND))
	assert_eq(AnimalBookRules.flags(w, &"cat"), WonderData.MET | WonderData.FED | WonderData.FRIEND)
	assert_false(AnimalBookRules.record(w, &"unicorn", WonderData.MET), "not an animal of the game")
	assert_false(AnimalBookRules.record(w, &"cow", 0))


func test_counted_events_fill_the_book() -> void:
	var w := WonderData.new()
	assert_eq(AnimalBookRules.from_event(w, &"pet_fed/parrot"), &"parrot")
	assert_eq(AnimalBookRules.flags(w, &"parrot"), WonderData.MET | WonderData.FED)
	assert_eq(AnimalBookRules.from_event(w, &"animal_tamed/dog"), &"dog")
	assert_eq(AnimalBookRules.flags(w, &"dog"), WonderData.MET | WonderData.FRIEND)
	assert_eq(AnimalBookRules.from_event(w, &"animal_tamed/dog"), &"", "nothing new")
	assert_eq(AnimalBookRules.from_event(w, &"monster_defeated/slime"), &"")
	assert_eq(AnimalBookRules.from_event(w, &"animal_tamed"), &"", "a family without the kind")


## A child who tamed and fed animals before the book existed finds them in it.
func test_the_book_catches_up_with_earlier_play() -> void:
	var w := WonderData.new()
	var d := ProgressData.new()
	d.record(&"animal_tamed/fox")
	d.record(&"pet_fed/cat", 2)
	var p := ProfileData.new()
	p.pip = {"name": "Pip"}
	assert_true(AnimalBookRules.catch_up(w, d, p))
	assert_eq(AnimalBookRules.flags(w, &"fox"), WonderData.MET | WonderData.FRIEND)
	assert_eq(AnimalBookRules.flags(w, &"cat"), WonderData.MET | WonderData.FED)
	assert_eq(AnimalBookRules.flags(w, &"pip"), WonderData.MET | WonderData.FRIEND, "Pip is the child's friend")
	assert_false(AnimalBookRules.catch_up(w, d, p), "nothing new the second time")


func test_animals_close_by_are_met() -> void:
	var w := WonderData.new()
	AnimalBookRules.record(w, &"sheep", WonderData.MET)
	var near: Array = [[&"cow", Vector3(3, 0, 4)], [&"sheep", Vector3(1, 0, 0)], [&"pig", Vector3(30, 0, 0)],
		[&"cow", Vector3(2, 0, 0)], [&"unicorn", Vector3.ZERO]]
	assert_eq(AnimalBookRules.newly_met(w, near, Vector3.ZERO), [&"cow"] as Array[StringName],
		"the cow once; the sheep was met; the pig is too far")


func test_counts_for_the_page() -> void:
	var w := WonderData.new()
	AnimalBookRules.record(w, &"dog", WonderData.MET)
	AnimalBookRules.record(w, &"fish", WonderData.MET)
	assert_eq(AnimalBookRules.met_count(w), 2)
	assert_eq(AnimalBookRules.count_words(w), "2 of %d animals" % AnimalRules.SPECIES.size())


func test_friend_marks_only_for_animals_that_can_be_friends() -> void:
	assert_true(AnimalBookRules.can_befriend(&"dog"))
	assert_true(AnimalBookRules.can_befriend(&"pip"), "Pip is given")
	assert_false(AnimalBookRules.can_befriend(&"cow"))
