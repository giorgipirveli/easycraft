extends GutTest
## M3 Task 21a (read-aloud, research O6): the lines waiting to be spoken. A speaker button speaks at once
## (cutting in); "Read to me" lines wait their turn, never twice in a row, never late (a toast long gone is not
## read), and never more than a few; other players' names are never read out (their words never are).

var q: SpeechQueue


func before_each() -> void:
	q = SpeechQueue.new()


func test_a_line_is_said_when_the_speaker_is_free() -> void:
	assert_true(q.push("Hello!", 0.0))
	assert_eq(q.next(0.1, false), "Hello!")
	assert_eq(q.next(0.2, false), "", "said once")


func test_lines_wait_while_the_speaker_talks() -> void:
	q.push("One", 0.0)
	q.push("Two", 0.1)
	assert_eq(q.next(0.2, true), "", "nothing while speaking")
	assert_eq(q.next(1.0, false), "One")
	assert_eq(q.next(1.1, true), "")
	assert_eq(q.next(2.0, false), "Two")


func test_a_speaker_button_cuts_in_and_clears_the_waiting_lines() -> void:
	q.push("One", 0.0)
	q.push("Two", 0.1)
	assert_true(q.push("Read the card", 0.2, true))
	assert_true(q.interrupting(), "the speaker stops what it says")
	assert_eq(q.next(0.3, true), "Read the card", "said even while the speaker was talking")
	assert_false(q.interrupting())
	assert_eq(q.next(5.0, false), "", "the waiting lines were dropped")


func test_the_same_line_is_not_read_twice_in_a_row() -> void:
	assert_true(q.push("Mirror ON", 0.0))
	assert_false(q.push("Mirror ON", 1.0), "still waiting")
	assert_eq(q.next(1.1, false), "Mirror ON")
	assert_false(q.push("Mirror ON", 2.0), "just said")
	assert_true(q.push("Mirror ON", 2.0 + SpeechQueue.REPEAT_GAP), "after a while it may be read again")
	assert_true(q.push("Mirror ON", 2.1, true), "a button always reads")


func test_only_a_few_lines_wait_and_the_oldest_goes() -> void:
	for i in SpeechQueue.MAX_WAITING + 2:
		q.push("Line %d" % i, float(i) * 0.1)
	assert_eq(q.waiting(), SpeechQueue.MAX_WAITING)
	assert_eq(q.next(1.0, false), "Line 2", "the two oldest went")


func test_a_line_that_waited_too_long_is_not_read_late() -> void:
	q.push("Old toast", 0.0)
	q.push("New toast", SpeechQueue.MAX_AGE)
	assert_eq(q.next(SpeechQueue.MAX_AGE + 0.5, false), "New toast")


func test_empty_lines_are_not_read() -> void:
	assert_false(q.push("", 0.0))
	assert_false(q.push("   \n ", 0.0))
	assert_eq(q.waiting(), 0)


func test_other_players_names_are_never_read_out() -> void:
	assert_eq(SpeechQueue.without_names("Anna was knocked out!", ["Anna"], "A friend"), "A friend was knocked out!")
	assert_eq(SpeechQueue.without_names("Welcome to Bo_2's showcase!", ["Bo_2"], "a friend"),
		"Welcome to a friend's showcase!")
	assert_eq(SpeechQueue.without_names("Annabel helped Anna up!", ["Anna"], "a friend"), "Annabel helped a friend up!",
		"whole names only")
	assert_eq(SpeechQueue.without_names("Wave 3 won!", [], "a friend"), "Wave 3 won!")
	assert_eq(SpeechQueue.without_names("Hi", ["", " "], "a friend"), "Hi", "empty names are no names")
