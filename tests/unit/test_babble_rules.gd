extends GutTest
## M3 Task 21a (babble voices, research F7): buddies, bot friends, Tilly and the story friends, and pets "talk" in
## cute nonsense syllables (never real words). Every speaker has its own pitch: tiny ones squeak, giants rumble;
## a line is a few syllables by how long its words are. One budget per device, like the animal chorus (owner
## #50): one line at a time, a speaker rests after talking, far ones are never heard; an answer to the child's own
## tap is never held back.

var rules: BabbleRules


func before_each() -> void:
	rules = BabbleRules.new()


func test_small_speakers_squeak_and_big_ones_rumble() -> void:
	var tiny := BabbleRules.pitch(&"buddy", 1.0, 0.0)
	var normal := BabbleRules.pitch(&"buddy", 3.0, 0.0)
	var big := BabbleRules.pitch(&"buddy", 8.0, 0.0)
	var giant := BabbleRules.pitch(&"buddy", 30.0, 0.0)
	assert_gt(tiny, normal)
	assert_gt(normal, big)
	assert_gt(big, giant)
	assert_almost_eq(BabbleRules.pitch(&"buddy", BabbleRules.NORMAL_SIZE, 0.0), 1.0, 0.001, "a normal-sized buddy: its voice as made")
	assert_between(giant, BabbleRules.MIN_PITCH, BabbleRules.MAX_PITCH, "never so low it stops being cute")
	assert_between(BabbleRules.pitch(&"pet", 0.1, 1.0), BabbleRules.MIN_PITCH, BabbleRules.MAX_PITCH)


func test_each_speaker_has_its_own_voice() -> void:
	var a := BabbleRules.personality("Bolt")
	var b := BabbleRules.personality("Zuzu")
	assert_eq(BabbleRules.personality("Bolt"), a, "the same every time")
	assert_ne(a, b)
	assert_between(a, -1.0, 1.0)
	var pa := BabbleRules.pitch(&"bot", BabbleRules.NORMAL_SIZE, a)
	var pb := BabbleRules.pitch(&"bot", BabbleRules.NORMAL_SIZE, b)
	assert_ne(pa, pb)
	var base := BabbleRules.pitch(&"bot", BabbleRules.NORMAL_SIZE, 0.0)
	assert_between(pa / base, 1.0 - BabbleRules.SPREAD - 0.001, 1.0 + BabbleRules.SPREAD + 0.001)


func test_kinds_of_speakers_sound_different() -> void:
	var n := BabbleRules.NORMAL_SIZE
	assert_gt(BabbleRules.pitch(&"pet", n, 0.0), BabbleRules.pitch(&"bot", n, 0.0), "a parrot chirps higher than a bot")
	assert_gt(BabbleRules.pitch(&"tilly", n, 0.0), BabbleRules.pitch(&"giver", n, 0.0) - 0.2)
	assert_eq(BabbleRules.pitch(&"nobody", n, 0.0), BabbleRules.pitch(&"buddy", n, 0.0), "unknown kinds babble like a buddy")


func test_longer_words_make_a_longer_babble() -> void:
	assert_eq(BabbleRules.syllables(""), BabbleRules.MIN_SYLLABLES)
	assert_eq(BabbleRules.syllables("Hi!"), BabbleRules.MIN_SYLLABLES)
	var short := BabbleRules.syllables("I love your builds!")
	var long := BabbleRules.syllables("Look! A little friend over here! Pet it three times!")
	assert_gt(long, short)
	assert_eq(BabbleRules.syllables("x".repeat(500)), BabbleRules.MAX_SYLLABLES, "never a long speech")


func test_a_line_is_syllables_one_after_another() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var at := BabbleRules.schedule(5, rng)
	assert_eq(at.size(), 5)
	assert_eq(at[0], 0.0)
	for i in range(1, at.size()):
		assert_between(at[i] - at[i - 1], BabbleRules.GAP_MIN, BabbleRules.GAP_MAX)
	assert_almost_eq(BabbleRules.line_seconds(at), at.back() + BabbleRules.TAIL, 0.001)


func test_one_line_at_a_time_on_a_device() -> void:
	assert_true(rules.may_talk("pip", 0.0, 3.0, false))
	rules.talked("pip", 0.0, 1.0)
	assert_false(rules.may_talk("bolt", 0.5, 3.0, false), "another speaker waits while one talks")
	assert_false(rules.may_talk("bolt", 1.0 + BabbleRules.LINE_GAP - 0.1, 3.0, false))
	assert_true(rules.may_talk("bolt", 1.0 + BabbleRules.LINE_GAP, 3.0, false))


func test_a_speaker_rests_after_talking() -> void:
	rules.talked("pip", 0.0, 1.0)
	assert_false(rules.may_talk("pip", 1.0 + BabbleRules.LINE_GAP, 3.0, false))
	assert_true(rules.may_talk("pip", 1.0 + BabbleRules.SPEAKER_REST, 3.0, false))


func test_an_answer_to_the_child_is_never_held_back() -> void:
	rules.talked("pip", 0.0, 1.0)
	assert_true(rules.may_talk("pip", 0.2, 3.0, true), "the child tapped: it answers now")
	assert_false(rules.may_talk("pip", 0.2, BabbleRules.RADIUS + 1.0, true), "but never from far away")


func test_far_speakers_are_not_heard_and_near_ones_are_louder() -> void:
	assert_false(rules.may_talk("pip", 0.0, BabbleRules.RADIUS + 0.5, false))
	assert_true(rules.may_talk("pip", 0.0, BabbleRules.RADIUS - 0.5, false))
	assert_gt(BabbleRules.volume_db(2.0), BabbleRules.volume_db(15.0))
	assert_eq(BabbleRules.volume_db(0.0), BabbleRules.volume_db(BabbleRules.NEAR))
