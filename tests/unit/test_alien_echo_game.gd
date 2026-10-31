extends GutTest
## Owner #86 (spec §21f): the alien villages' drum game, Echo. The chief plays a little song on four drums; the child
## hops on them in the same order; each round is one note longer; a wrong drum is never a loss ("Not yet! Listen
## again."): the same round plays again. No timer.


func _game(s: int = 7) -> EchoGame:
	var g := EchoGame.new()
	g.start(s)
	return g


func test_the_song_uses_the_four_drums_and_never_one_twice_in_a_row() -> void:
	for s in 50:
		var g := _game(s)
		assert_eq(g.song.size(), EchoGame.LAST_LENGTH)
		for i in g.song.size():
			assert_between(g.song[i], 0, EchoGame.PADS - 1)
			if i > 0:
				assert_ne(g.song[i], g.song[i - 1], "seed %d: never the same drum twice in a row" % s)
	assert_eq(_game(3).song, _game(3).song, "the same seed, the same song")


func test_rounds_grow_one_note_at_a_time_until_the_whole_song() -> void:
	var g := _game()
	assert_eq(g.round_song().size(), EchoGame.FIRST_LENGTH)
	assert_eq(g.hop(g.song[0]), EchoGame.IDLE, "not the child's turn while the chief plays")
	var rounds := 0
	while not g.won:
		g.your_turn()
		var notes := g.round_song()
		for i in notes.size():
			var r := g.hop(notes[i])
			if i < notes.size() - 1:
				assert_eq(r, EchoGame.RIGHT)
			else:
				assert_eq(r, EchoGame.WON if notes.size() == EchoGame.LAST_LENGTH else EchoGame.ROUND_DONE)
		rounds += 1
	assert_eq(rounds, EchoGame.rounds())
	assert_eq(g.misses, 0)
	assert_eq(g.hop(0), EchoGame.IDLE, "won: nothing more to hop")


func test_a_wrong_drum_plays_the_round_again_never_a_loss() -> void:
	var g := _game()
	g.your_turn()
	var wrong := (g.song[0] + 1) % EchoGame.PADS
	assert_eq(g.hop(wrong), EchoGame.NOT_YET)
	assert_eq(g.round_number(), 1, "the same round")
	assert_false(g.listening, "the chief plays it again first")
	assert_eq(g.hop(g.song[0]), EchoGame.IDLE)
	g.your_turn()
	assert_eq(g.hop(g.song[0]), EchoGame.RIGHT, "and the child tries again from its start")
	assert_eq(g.misses, 1)


func test_each_drum_has_its_own_note() -> void:
	var seen := {}
	for p in EchoGame.PADS:
		seen[BuildNotes.pitch(EchoGame.degree(p))] = true
	assert_eq(seen.size(), EchoGame.PADS)


func test_a_bounce_on_the_same_drum_counts_once() -> void:
	var g := _game()
	g.your_turn()
	assert_eq(g.hop(g.song[0]), EchoGame.RIGHT)
	assert_eq(g.hop(g.song[0]), EchoGame.IDLE, "Planet Boing's moss bounced the child on the same drum")
	assert_eq(g.misses, 0)
	assert_eq(g.hop(g.song[1]), EchoGame.ROUND_DONE, "the next drum goes on")
