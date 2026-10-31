extends GutTest
## M3 Task 21b (research X5): idea cards — picture cards with build ideas to flip through for inspiration.
## No rewards (research §1.8, overjustification), no timers, short words a child can read or guess from the
## pictures.

const REWARD_KEYS: Array[String] = ["gold", "xp", "reward", "sticker", "prize", "time", "timer", "seconds"]
const PRESSURE: Array[String] = ["hurry", "quick", "fast as you can", "before", "only", "must", "streak"]


func test_there_are_plenty_of_cards_each_with_pictures_and_words() -> void:
	assert_gte(IdeaCards.count(), 20)
	var ids: Array[StringName] = []
	for c: Dictionary in IdeaCards.CARDS:
		assert_false(ids.has(c.id), "unique: %s" % c.id)
		ids.append(c.id)
		var words: String = c.words
		assert_ne(words, "")
		assert_lte(words.split(" ").size(), 8, "short: %s" % words)
		var pics: Array = c.pictures
		assert_between(pics.size(), 1, 3, String(c.id))
		for p: Variant in pics:
			assert_true(IdeaCards.picture_ok(p), "%s: %s" % [c.id, p])


func test_no_card_has_a_reward_or_a_timer() -> void:
	for c: Dictionary in IdeaCards.CARDS:
		for key: String in c:
			assert_false(REWARD_KEYS.has(key), "%s has '%s'" % [c.id, key])
		for bad in PRESSURE:
			assert_false(str(c.words).to_lower().contains(bad), "%s: '%s'" % [c.id, bad])


func test_flipping_wraps_round() -> void:
	assert_eq(IdeaCards.flip(0, 1), 1)
	assert_eq(IdeaCards.flip(IdeaCards.count() - 1, 1), 0)
	assert_eq(IdeaCards.flip(0, -1), IdeaCards.count() - 1)
	assert_eq(IdeaCards.card(IdeaCards.count() + 3), IdeaCards.CARDS[3], "any number is a card")
