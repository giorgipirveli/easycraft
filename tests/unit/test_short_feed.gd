extends GutTest
## Owner #94 (spec §5.12b): the feed's order teaches (never an endless algorithm): a topic's Shorts stay together in
## their written order, topics with Shorts not seen yet come first, each seen Short is marked; filters: the hand-made
## Shorts, Lessons in a minute (a grade's, subject by subject), and the child's LIKED list.


func after_each() -> void:
	Curriculum.clear_cache()
	ShortLibrary.clear_cache()


func _e(id: String, topic: String) -> Dictionary:
	return {"id": id, "title": id.capitalize(), "topic": topic, "kind": ShortFeed.HAND}


func _ids(feed: Array) -> Array[String]:
	var out: Array[String] = []
	for e: Dictionary in feed:
		out.append(str(e.id))
	return out


func test_a_topics_shorts_stay_together_and_new_topics_come_first() -> void:
	var entries := [_e("a1", "rockets"), _e("a2", "rockets"), _e("b1", "space"), _e("c1", "maths"), _e("b2", "space")]
	var data := ShortsData.new()
	assert_eq(_ids(ShortFeed.arrange(entries, data)), ["a1", "a2", "b1", "b2", "c1"] as Array[String],
		"a topic together, in the written order")
	data.mark_seen("a1")
	data.mark_seen("a2")
	var feed := ShortFeed.arrange(entries, data)
	assert_eq(_ids(feed), ["b1", "b2", "c1", "a1", "a2"] as Array[String], "the rockets were all seen: they go last")
	assert_true(feed[3].seen and feed[4].seen, "seen ones are marked")
	assert_false(feed[0].seen)
	data.mark_seen("b1")
	assert_eq(_ids(ShortFeed.arrange(entries, data)), ["b1", "b2", "c1", "a1", "a2"] as Array[String],
		"a topic partly seen keeps its order (the lesson goes on where it was)")


func test_the_feed_starts_at_the_first_short_not_seen() -> void:
	var data := ShortsData.new()
	var feed := ShortFeed.arrange([_e("a1", "rockets"), _e("a2", "rockets"), _e("b1", "space")], data)
	assert_eq(ShortFeed.start_index(feed), 0)
	data.mark_seen("a1")
	feed = ShortFeed.arrange([_e("a1", "rockets"), _e("a2", "rockets"), _e("b1", "space")], data)
	assert_eq(feed[ShortFeed.start_index(feed)].id, "a2")
	for id: String in ["a2", "b1"]:
		data.mark_seen(id)
	feed = ShortFeed.arrange([_e("a1", "rockets"), _e("a2", "rockets"), _e("b1", "space")], data)
	assert_eq(ShortFeed.start_index(feed), 0, "all seen: from the top")


func test_the_hand_made_feed_is_every_hand_made_short_by_topic() -> void:
	var feed := ShortFeed.build(ShortFeed.HAND, 4, ShortsData.new())
	assert_eq(feed.size(), ShortLibrary.hand_ids().size())
	var topics: Array[String] = []
	for e: Dictionary in feed:
		if topics.is_empty() or topics.back() != e.topic:
			assert_false(topics.has(e.topic), "%s's Shorts are together" % e.topic)
			topics.append(e.topic)
		assert_eq(e.kind, ShortFeed.HAND)
	assert_eq(topics[0], "rockets", "how to build a rocket first")


func test_lessons_are_a_grades_written_units_subject_by_subject() -> void:
	var feed := ShortFeed.build(ShortFeed.LESSONS, 4, ShortsData.new())
	var expected: Array[String] = []
	for s in Curriculum.subjects(4):
		for u in Curriculum.units(4, str(s.id)):
			if u.has("file") and not bool(u.get("bonus", false)):
				expected.append("lesson:" + str(u.id))
	assert_gt(expected.size(), 100, "grade 4 has over a hundred written units")
	assert_eq(_ids(feed), expected, "in the School's order: maths first, unit by unit")
	assert_eq(feed[0].topic, "maths")
	assert_eq(feed[0].grade, 4)
	assert_false(_ids(feed).has("lesson:g4.science.rockets_explorer"), "an Explorer lesson (sold for gold) is not given away")


func test_liked_lists_both_kinds_newest_first() -> void:
	var data := ShortsData.new()
	var hand: String = ShortLibrary.hand_ids()[0]
	data.like(hand, 100)
	data.like("lesson:g3.maths.numbers_to_10000", 200)
	data.like("lesson:g3.maths.no_such_unit", 300)   # gone from the School: left out
	var feed := ShortFeed.build(ShortFeed.LIKED, 3, data)
	assert_eq(_ids(feed), ["lesson:g3.maths.numbers_to_10000", hand] as Array[String])
	assert_eq(feed[0].kind, ShortFeed.LESSON)


func test_an_entry_knows_its_colour_title_and_where_learn_it_goes() -> void:
	var e := ShortFeed.entry_for("lesson:g4.science.circuits")
	assert_eq(e.title, Curriculum.unit("g4.science.circuits").title)
	assert_eq(e.topic, "science")
	assert_eq(e.link, {"unit": "g4.science.circuits"})
	assert_true(ShortFeed.entry_for("no_such_short").is_empty())
