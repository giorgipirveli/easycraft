extends GutTest
## MAKE MY SHORT: the child's own Shorts in the profile (ProfileData.my_shorts), as small recipes: at most 20, newest
## first, ids never reused (a heart can't jump to a new Short), each recipe cleaned when read back.


func _recipe(title: String = "How I built my castle") -> Dictionary:
	return {"template": "built", "title": title, "photos": ["p_1.jpg", "p_2.jpg"], "captions": ["I started with the floor."],
		"ending": "What will you build next?", "backdrop": "grass", "music": "", "voice": true}


func test_a_short_is_added_with_a_new_id() -> void:
	var d := MyShortsData.new()
	assert_true(d.is_empty())
	var id := d.add(_recipe(), 1000)
	assert_eq(id, "mine:1")
	assert_eq(d.count(), 1)
	var r := d.recipe(id)
	assert_eq(r.title, "How I built my castle")
	assert_eq(r.id, "mine:1")
	assert_eq(r.made, 1000)
	assert_eq(d.add(_recipe("My dream home"), 1001), "mine:2")


func test_newest_first() -> void:
	var d := MyShortsData.new()
	d.add(_recipe("My dream home"), 100)
	d.add(_recipe("My secret base"), 300)
	d.add(_recipe("Look what I made!"), 200)
	var titles: Array[String] = []
	for r in d.newest_first():
		titles.append(str(r.title))
	assert_eq(titles, ["Look what I made!", "My secret base", "My dream home"] as Array[String],
		"the newest made last is first (ids go up)")


func test_at_most_twenty() -> void:
	var d := MyShortsData.new()
	for i in MyShortRules.MAX_SHORTS:
		assert_ne(d.add(_recipe(), 100 + i), "")
	assert_true(d.is_full())
	assert_eq(d.add(_recipe(), 999), "", "full: the maker asks for one to be deleted first")
	assert_eq(d.count(), MyShortRules.MAX_SHORTS)


func test_a_deleted_id_is_never_used_again() -> void:
	var d := MyShortsData.new()
	var a := d.add(_recipe(), 1)
	var b := d.add(_recipe(), 2)
	assert_true(d.remove(b))
	assert_false(d.remove(b))
	assert_eq(d.add(_recipe(), 3), "mine:3")
	assert_true(d.remove(a))
	assert_eq(d.count(), 1)


func test_a_short_can_be_changed() -> void:
	var d := MyShortsData.new()
	var id := d.add(_recipe(), 10)
	var changed := _recipe("My secret base")
	assert_true(d.replace(id, changed, 20))
	assert_eq(d.recipe(id).title, "My secret base")
	assert_eq(d.recipe(id).made, 10, "still made when it was first made")
	assert_false(d.replace("mine:99", changed, 30))
	assert_false(d.replace(id, {"template": "nope"}, 30))


func test_a_bad_recipe_is_refused() -> void:
	var d := MyShortsData.new()
	assert_eq(d.add({"template": "built", "photos": []}, 1), "")
	assert_eq(d.add({}, 1), "")
	assert_true(d.is_empty())


func test_files_in_use() -> void:
	var d := MyShortsData.new()
	d.add(_recipe(), 1)
	d.add({"template": "steps", "build": {"kind": "stamp", "file": "b_7.txt", "layers": 4}}, 2)
	d.add({"template": "steps", "build": {"kind": "blueprint", "id": "house"}}, 3)
	assert_eq(d.files(), ["p_1.jpg", "p_2.jpg", "b_7.txt"] as Array[String])


func test_it_round_trips_and_cleans_junk() -> void:
	var d := MyShortsData.new()
	d.add(_recipe(), 1)
	d.add({"template": "facts", "subject": {"kind": "planet", "id": "mars"}, "facts": [2, 0, 1]}, 2)
	var back := MyShortsData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	assert_eq(back.to_dict(), d.to_dict())
	assert_eq(back.add(_recipe(), 3), "mine:3", "the next id travels too")
	var junk := MyShortsData.from_dict({"next": "x", "shorts": ["text", {"template": "video"}, {"id": "mine:5", "template": "built",
		"photos": ["p_1.jpg", "p_2.jpg"]}, {"id": "mine:5", "template": "built", "photos": ["p_3.jpg", "p_4.jpg"]},
		{"template": "built", "photos": ["p_1.jpg", "p_2.jpg"]}]})
	assert_eq(junk.count(), 1, "broken ones, a twin id and one without an id are left out")
	assert_eq(junk.next_id, 6, "past every id kept")
	assert_true(MyShortsData.from_dict(null).is_empty())


func test_a_full_profile_s_part_is_small() -> void:
	var d := MyShortsData.new()
	for i in MyShortRules.MAX_SHORTS:
		var r := _recipe()
		r.photos = ["p_1727771234_%d.jpg" % i, "p_1727771235_%d.jpg" % i, "p_1727771236_%d.jpg" % i, "p_1727771237_%d.jpg" % i]
		r.captions = ["x".repeat(80), "y".repeat(80), "z".repeat(80), "w".repeat(80)]
		d.add(r, 1727771234 + i)
	assert_lt(JSON.stringify(d.to_dict()).length(), 24 * 1024, "twenty full Shorts are a few KB of the profile")
