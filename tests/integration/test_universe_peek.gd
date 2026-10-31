extends GutTest
## Universe 6, the Glow Caves (brief: "worth paying for", owner #72; the fair-fun rules): a free peek at a locked
## universe that has one (its descriptor's `peek` lines). The hub's locked card keeps saying how it opens and stays
## unpressable for travel, but has a PEEK button; the Star Map's card of a locked universe too. The peek: the universe's
## own picture, its name, what is inside (a few short lines) and how it opens (beat the boss before it). No price, no
## timer shown, no "buy", nothing that hurries; it closes on its button or by itself after PEEK_SECONDS.

const BAD := ["buy", "price", "$", "€", "hurry", "only", "last chance", "now!", "left"]

var _unlocked := 1


func before_each() -> void:
	_unlocked = Profile.data.universe_unlocked


func after_each() -> void:
	Profile.data.universe_unlocked = _unlocked
	UniverseRegistry.reset()


func _peeks() -> Array:
	return get_tree().root.find_children("*", "UniversePeek", true, false).filter(
		func(n: Node) -> bool: return not n.is_queued_for_deletion())


func after_all() -> void:
	for p: Node in _peeks():
		p.queue_free()


func test_the_glow_caves_have_peek_lines() -> void:
	var lines := UniverseRegistry.peek(6)
	assert_between(lines.size(), 2, 3, "a few lines of what is inside")
	for l: String in lines:
		assert_lte(l.length(), 60, l)
		for bad: String in BAD:
			assert_false(l.to_lower().contains(bad), "calm words: %s" % l)
	assert_eq(UniverseRegistry.peek(1), [] as Array[String], "the first universe is always open: nothing to peek")


func test_a_locked_card_peeks_and_never_travels() -> void:
	var locked := UniverseCard.new(6, false)
	add_child_autofree(locked)
	assert_true(locked.disabled, "a locked universe is still no trip")
	assert_not_null(locked.peek_button, "a PEEK button")
	assert_true(locked.peek_button.visible)
	var open := UniverseCard.new(5, true)
	add_child_autofree(open)
	assert_null(open.peek_button, "an open card has GO!")
	var later := UniverseCard.new(7, false)
	add_child_autofree(later)
	assert_null(later.peek_button, "a universe not built yet has nothing to peek at")
	locked.peek_button.pressed.emit()
	await wait_process_frames(2)
	var shown := _peeks()
	assert_eq(shown.size(), 1, "the peek opens")
	var peek: UniversePeek = shown[0]
	assert_eq(peek.universe, 6)
	var words := peek.words()
	assert_true(words.contains("Glow Caves"))
	for l: String in UniverseRegistry.peek(6):
		assert_true(words.contains(l))
	assert_true(words.contains(StarMap.action_words(StarMap.LOCKED)), "how it opens")
	for bad: String in BAD:
		assert_false(words.to_lower().contains(bad), "no pressure: %s" % bad)
	peek.close_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(_peeks().size(), 0, "closed on its button")


func test_a_peek_closes_by_itself() -> void:
	var peek := UniversePeek.show_for(6, self)
	assert_not_null(peek)
	await wait_process_frames(1)
	peek.tick(UniversePeek.PEEK_SECONDS - 0.5)
	assert_false(peek.is_queued_for_deletion(), "a few seconds' look")
	peek.tick(1.0)
	assert_true(peek.is_queued_for_deletion(), "then it closes by itself")
	assert_null(UniversePeek.show_for(1, self), "no peek for a universe without one")


func test_the_star_maps_locked_card_peeks() -> void:
	var p := SpacePanel.new()
	p.size = Vector2(1280, 720)
	add_child_autofree(p)
	p.open(1, 1, [] as Array[int], 5)
	await wait_process_frames(2)
	p.select(&"universe_6")
	assert_true(p.peek_button.visible, "the Glow Caves' card: PEEK")
	assert_false(p.action_button.visible, "no trip while it is locked")
	p.peek_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(_peeks().size(), 1)
	(_peeks()[0] as UniversePeek).close_button.pressed.emit()
	await wait_process_frames(2)
	p.select(&"frostpeak")
	assert_false(p.peek_button.visible, "an open universe has its portal words, no peek")
