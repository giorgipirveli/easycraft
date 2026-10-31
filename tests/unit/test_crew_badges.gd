extends GutTest
## Crew flights (spec §21d.6 phase 2, the brief's item 4): every crew member's own profile keeps a crew badge ("Crew of
## the Moon mission with Anna and Sam"), in MissionData (backed up with the profile; the merge never loses one). The
## same crew to the same world is one badge; nothing pays twice.


func test_a_new_crew_is_a_new_badge() -> void:
	var b := CrewBadges.new()
	assert_true(b.is_empty())
	assert_true(b.add(SpaceRules.MOON, ["Sam", "Anna"]))
	assert_false(b.is_empty())
	assert_eq(b.words(), ["Crew of the Moon mission with Anna and Sam"] as Array[String], "names in order")


func test_the_same_crew_to_the_same_world_is_one_badge() -> void:
	var b := CrewBadges.new()
	b.add(SpaceRules.MOON, ["Anna", "Sam"])
	assert_false(b.add(SpaceRules.MOON, ["Sam", "Anna"]))
	assert_true(b.add(SpaceRules.MARS, ["Anna", "Sam"]), "another world")
	assert_true(b.add(SpaceRules.MOON, ["Mia"]), "another crew")
	assert_eq(b.list.size(), 3)
	assert_eq(b.for_world(SpaceRules.MOON).size(), 2)


func test_a_badge_needs_a_world_with_a_mission_and_at_least_one_friend() -> void:
	var b := CrewBadges.new()
	assert_false(b.add(SpaceRules.BOING, ["Anna"]), "no mission to Planet Boing")
	assert_false(b.add(SpaceRules.MOON, []), "a crew is more than one")
	assert_false(b.add(SpaceRules.MOON, ["", "  "]), "no names at all")
	assert_true(b.is_empty())


func test_names_are_kept_short_and_the_list_bounded() -> void:
	var b := CrewBadges.new()
	b.add(SpaceRules.MOON, ["A".repeat(80)])
	assert_eq((b.list[0].with[0] as String).length(), CrewBadges.MAX_NAME)
	for i in CrewBadges.MAX + 10:
		b.add(SpaceRules.MARS, ["Friend%d" % i])
	assert_eq(b.list.size(), CrewBadges.MAX, "the oldest go first")


func test_it_saves_and_loads() -> void:
	var b := CrewBadges.new()
	b.add(SpaceRules.MOON, ["Anna", "Sam"])
	var again := CrewBadges.from_array(JSON.parse_string(JSON.stringify(b.to_array())))
	assert_eq(again.words(), b.words())
	assert_true(CrewBadges.from_array("nonsense").is_empty())
	assert_true(CrewBadges.from_array([{"world": "x"}, 5, {"world": 16, "with": "Sam"}]).is_empty(), "bad rows are skipped")


func test_the_merge_keeps_every_badge() -> void:
	var a := CrewBadges.new()
	a.add(SpaceRules.MOON, ["Anna"])
	var b := CrewBadges.new()
	b.add(SpaceRules.MOON, ["Anna"])
	b.add(SpaceRules.MARS, ["Sam"])
	a.merge_from(b)
	assert_eq(a.list.size(), 2)


func test_mission_data_keeps_the_badges() -> void:
	var m := MissionData.new()
	assert_true(m.crews.add(SpaceRules.MOON, ["Anna"]))
	assert_false(m.is_empty(), "a badge is progress")
	var again := MissionData.from_dict(JSON.parse_string(JSON.stringify(m.to_dict())))
	assert_eq(again.crews.words(), ["Crew of the Moon mission with Anna"] as Array[String])
	var other := MissionData.new()
	other.merge_from(m)
	assert_eq(other.crews.list.size(), 1, "the backup's merge never loses a badge")
