extends GutTest
## Owner #72, #74 (spec §21b.2): the Space Book. The profile's books remember every body of the Star Map whose card the
## child opened (seen) and every world they landed on (landed, which includes seen); the backup's merge never loses
## one; SpaceBookRules counts them for the book.


func test_seeing_a_planet_is_kept_once() -> void:
	var w := WonderData.new()
	assert_true(w.see_body(&"mars"), "the first time")
	assert_false(w.see_body(&"mars"), "already in the book")
	assert_eq(w.bodies, {"mars": WonderData.SEEN})
	assert_false(w.see_body(&"nowhere"), "only the Star Map's bodies")
	assert_false(w.is_empty())


func test_landing_marks_seen_and_landed() -> void:
	var w := WonderData.new()
	assert_true(w.land_on_world(SpaceRules.MOON), "the first landing on the Moon")
	assert_eq(w.bodies, {"moon": WonderData.SEEN | WonderData.LANDED})
	assert_false(w.land_on_world(SpaceRules.MOON))
	assert_false(w.land_on_world(1), "Green Meadows is a universe: no landing mark")
	w.see_body(&"moon")
	assert_eq(int(w.bodies.moon), WonderData.SEEN | WonderData.LANDED, "seeing again keeps the landing")


func test_the_book_goes_to_the_profile_and_back() -> void:
	var w := WonderData.new()
	w.see_body(&"jupiter")
	w.land_on_world(SpaceRules.BOING)
	var back := WonderData.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	assert_eq(back.bodies, {"jupiter": WonderData.SEEN, "boing": WonderData.SEEN | WonderData.LANDED})
	var odd := WonderData.from_dict({"bodies": {"mars": 1, "atlantis": 1, "venus": 9, "io": "1", "sun": 2.5}})
	assert_eq(odd.bodies, {"mars": WonderData.SEEN}, "only known bodies and marks")


func test_the_backup_merge_keeps_every_mark() -> void:
	var a := WonderData.new()
	a.see_body(&"mars")
	a.land_on_world(SpaceRules.MOON)
	var b := WonderData.new()
	b.land_on_world(SpaceRules.MARS)
	b.see_body(&"pluto")
	a.merge_from(b)
	assert_eq(a.bodies, {"mars": WonderData.SEEN | WonderData.LANDED, "moon": WonderData.SEEN | WonderData.LANDED,
		"pluto": WonderData.SEEN})


func test_the_count_for_the_book() -> void:
	var w := WonderData.new()
	var all := StarMap.bodies().size()
	assert_eq(SpaceBookRules.count_words(w), "0 of %d seen" % all)
	w.see_body(&"mars")
	w.land_on_world(SpaceRules.MOON)
	assert_eq(SpaceBookRules.count_words(w), "2 of %d seen · landed on 1" % all)


func test_a_clue_for_a_body_not_seen_yet() -> void:
	assert_string_contains(SpaceBookRules.clue(&"neptune"), "Fly up to space")
