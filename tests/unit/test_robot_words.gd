extends GutTest
## Owner #86 (spec §21f): what the robots and aliens say. Every space world has a helper robot with the planet's first
## fact, a sample fact and questions a child can answer from what the game told them; every alien is friendly and
## honest: an explorer says its home world is make-believe and always "No one has found life beyond Earth yet:
## scientists keep looking, and so do we!"; no mission's, company's or person's name (spec §21b.2); nothing scary.

const MISSION_NAMES: Array[String] = ["apollo", "artemis", "curiosity", "perseverance", "opportunity", "sojourner",
	"spirit", "viking", "insight", "pathfinder", "phoenix", "cassini", "huygens", "galileo", "juno", "voyager", "hubble",
	"webb", "messenger", "bepicolombo", "clipper", "dragonfly", "new horizons", "pioneer", "mariner", "kepler", "tess",
	"tianwen", "zhurong", "chang'e", "lunokhod", "yutu", "nasa", "esa", "spacex", "starship", "musk", "rover curiosity"]
const SCARY: Array[String] = ["hurt", "danger", "dangerous", "kill", "die", "dies", "dead", "scary", "attack", "burn",
	"burns", "invade", "invasion", "monster", "poison", "deadly"]


func _all_words() -> Array[String]:
	var out: Array[String] = [CreatureWords.HONEST]
	for u: int in CreatureWords.ROBOTS:
		var r: Dictionary = CreatureWords.ROBOTS[u]
		for k in ["hello", "fact", "sample"]:
			out.append(str(r[k]))
		for q: Dictionary in r.questions:
			out.append(str(q.q))
			out.append(str(q.hint))
			for c: Variant in q.choices:
				out.append(str(c))
	for id: StringName in CreatureWords.ALIENS:
		var a: Dictionary = CreatureWords.ALIENS[id]
		for k in ["pretend", "science", "asks", "hello"]:
			if a.has(k):
				out.append(str(a[k]))
	for id: String in CreatureWords.SOUVENIRS:
		out.append(str(CreatureWords.SOUVENIRS[id].name))
		out.append(str(CreatureWords.SOUVENIRS[id].story))
	return out


func test_every_space_world_has_a_helper_robot() -> void:
	for u: int in SpaceRules.WORLDS:
		if not UniverseRegistry.is_space(u):
			continue
		var r := CreatureWords.robot(u)
		assert_false(r.is_empty(), "world %d has a robot" % u)
		assert_string_contains(str(r.hello), str(r.name), "it says its name")
		assert_gt(str(r.fact).length(), 20, "a first fact")
		assert_string_contains(str(r.sample), "sample", "what the rover digs")
		assert_gte((r.questions as Array).size(), 3, "a quest's questions")
	assert_eq(UniverseRegistry.SPACE.size(), CreatureWords.ROBOTS.size(), "one robot per space world, no more")


func test_every_question_can_be_answered() -> void:
	var ids := {}
	for u: int in CreatureWords.ROBOTS:
		for q: Dictionary in CreatureWords.ROBOTS[u].questions:
			assert_false(ids.has(q.id), "one id per question: %s" % q.id)
			ids[q.id] = true
			assert_eq((q.choices as Array).size(), 3, "%s: three choices" % q.id)
			assert_between(int(q.answer), 0, 2, "%s: its answer is a choice" % q.id)
			assert_gt(str(q.hint).length(), 10, "%s: a hint for a second try" % q.id)
			assert_eq(CreatureWords.question(u, str(q.id)), q)
	assert_eq(CreatureWords.question_ids().size(), ids.size())


func test_the_right_answers_are_not_always_in_the_same_place() -> void:
	var at := {}
	for u: int in CreatureWords.ROBOTS:
		for q: Dictionary in CreatureWords.ROBOTS[u].questions:
			at[int(q.answer)] = int(at.get(int(q.answer), 0)) + 1
	assert_eq(at.size(), 3, "first, middle and last: %s" % at)


func test_every_camp_and_village_alien_is_known_and_explorers_are_honest() -> void:
	for u: int in CreatureWords.CAMPS:
		var c := CreatureWords.camp(u)
		var e := CreatureWords.alien(c.explorer)
		var t := CreatureWords.alien(c.trader)
		assert_eq(e.role, &"explorer")
		assert_eq(t.role, &"trader")
		assert_true(str(e.pretend).contains("story") or str(e.pretend).contains("pretend"),
			"%s's home world is clearly make-believe" % e.name)
		assert_gt(str(e.science).length(), 30, "%s tells how scientists look for life" % e.name)
		assert_true(CreatureWords.SOUVENIRS.has(str(e.gift)), "%s has a present" % e.name)
		for s: Variant in t.souvenirs:
			assert_gt(int(CreatureWords.souvenir(str(s)).get("price", 0)), 0, "%s sells %s" % [t.name, s])
	for u: int in CreatureWords.VILLAGES:
		var v := CreatureWords.village(u)
		var chief := CreatureWords.alien(v.chief)
		assert_eq(chief.role, &"chief")
		assert_string_contains(str(chief.pretend), "make-believe")
		for id: Variant in v.villagers:
			assert_eq(CreatureWords.alien(id).role, &"villager")
	assert_eq(CreatureWords.CAMPS.keys(), [16, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28], "the real bodies have camps")
	assert_eq(CreatureWords.VILLAGES.keys(), [17, 18], "the playful planets have villages")
	assert_string_contains(CreatureWords.HONEST, "No one has found life beyond Earth yet")


func test_no_mission_company_or_persons_name() -> void:
	for text in _all_words():
		# cosmos: the Cassini Division is a gap in Saturn's rings named for the astronomer who saw it in 1675, not the mission
		var lower := text.to_lower().replace("cassini division", "division")
		for name in MISSION_NAMES:
			assert_false(RegEx.create_from_string("(?<![a-z])" + name + "(?![a-z])").search(lower) != null,
				"\"%s\" names %s" % [text, name])


func test_nothing_they_say_is_scary() -> void:
	for text in _all_words():
		var lower := text.to_lower()
		for word in SCARY:
			assert_false(RegEx.create_from_string("(?<![a-z])" + word + "(?![a-z])").search(lower) != null,
				"\"%s\" says %s" % [text, word])


func test_souvenirs_are_make_believe_and_gifts_are_never_sold() -> void:
	for id: String in CreatureWords.SOUVENIRS:
		var s: Dictionary = CreatureWords.SOUVENIRS[id]
		assert_true(str(s.story).contains("story"), "%s is a story's treasure" % id)
		if bool(s.get("gift", false)):
			assert_eq(AlienRules.price(id), 0, "%s: a friend's present, never sold" % id)
		else:
			assert_between(AlienRules.price(id), 20, 200, "%s: a fair price" % id)


func test_directions_read_like_a_map() -> void:
	var o := Vector3.ZERO
	assert_eq(CreatureWords.direction(o, Vector3(0, 0, -10)), "north")
	assert_eq(CreatureWords.direction(o, Vector3(10, 0, 0)), "east")
	assert_eq(CreatureWords.direction(o, Vector3(0, 0, 10)), "south")
	assert_eq(CreatureWords.direction(o, Vector3(-10, 0, 0)), "west")
	assert_eq(CreatureWords.direction(o, Vector3(-10, 0, -10)), "north-west")
