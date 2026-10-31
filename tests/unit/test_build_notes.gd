extends GutTest
## M3 Task 21c: building sounds and melody (spec §16 "building sounds"). Every block kind has a soft note of its
## own; blocks placed one after another in a row climb a little melody on the major pentatonic scale (no two of its
## notes clash, so it always sounds nice); a budget keeps the notes from flooding the mix.


func test_the_scale_is_the_major_pentatonic() -> void:
	assert_eq(BuildNotes.SCALE, [0, 2, 4, 7, 9] as Array[int])
	assert_almost_eq(BuildNotes.pitch(0), 1.0, 0.0001, "degree 0 is the sample's own note")
	assert_almost_eq(BuildNotes.pitch(2), pow(2.0, 4.0 / 12.0), 0.0001, "E")
	assert_almost_eq(BuildNotes.pitch(3), pow(2.0, 7.0 / 12.0), 0.0001, "G")
	assert_almost_eq(BuildNotes.pitch(5), 2.0, 0.0001, "an octave up")
	assert_almost_eq(BuildNotes.pitch(7), pow(2.0, 16.0 / 12.0), 0.0001, "E an octave up")


## Every pitch the melody can reach is a note of the scale: a whole number of semitones from the sample's C that
## the scale holds (no out-of-tune wobble), never above the top.
func test_every_reachable_note_is_in_tune() -> void:
	for d in range(0, BuildNotes.TOP + 1):
		var semis := 12.0 * log(BuildNotes.pitch(d)) / log(2.0)
		assert_almost_eq(semis, roundf(semis), 0.001, "degree %d" % d)
		assert_true(BuildNotes.SCALE.has(posmod(roundi(semis), 12)), "degree %d is pentatonic" % d)
	assert_lte(BuildNotes.pitch(BuildNotes.TOP), 4.8, "never shrill")


func test_each_block_kind_has_its_own_note_and_voice() -> void:
	var notes := {}
	for id: int in BlockIds.PLACEABLE:
		var d := BuildNotes.base_degree(id)
		assert_between(d, 0, BuildNotes.START_TOP, BlockIds.display_name(id))
		assert_eq(BuildNotes.base_degree(id), d, "always the same note")
		notes[d] = true
	assert_gte(notes.size(), 5, "blocks sing different notes")
	assert_ne(BuildNotes.base_degree(BlockIds.STONE), BuildNotes.base_degree(BlockIds.GLASS), "stone low, glass high")
	assert_lt(BuildNotes.base_degree(BlockIds.STONE), BuildNotes.base_degree(BlockIds.GLASS))
	assert_eq(BuildNotes.voice(BlockIds.GLASS), BuildNotes.BELL, "glass rings like a bell")
	assert_eq(BuildNotes.voice(BlockIds.CRYSTAL), BuildNotes.BELL)
	assert_eq(BuildNotes.voice(BlockIds.PLANKS), BuildNotes.WOOD, "wood knocks like a marimba")
	assert_eq(BuildNotes.voice(BlockIds.STONE), BuildNotes.WOOD)
	assert_eq(BuildNotes.voice(ItemIds.STAMP_HOUSE), BuildNotes.WOOD, "anything else has a voice too")


## Blocks placed next to the last one, soon after it, climb the scale step by step; a phrase of PHRASE notes
## starts again from the row's first note.
func test_blocks_in_a_row_climb_a_rising_melody() -> void:
	var m := BuildNotes.Melody.new()
	var start := BuildNotes.base_degree(BlockIds.PLANKS)
	var got: Array[int] = []
	for i in BuildNotes.PHRASE + 2:
		got.append(m.next(BlockIds.PLANKS, Vector3i(i, 5, 0), 1000 + i * 400))
	for i in BuildNotes.PHRASE:
		assert_eq(got[i], start + i, "note %d rises" % i)
	assert_eq(got[BuildNotes.PHRASE], start, "a new phrase starts from the row's first note")
	assert_eq(got[BuildNotes.PHRASE + 1], start + 1)


## The row's first block sets the tune: another kind of block in the same row goes on up the melody.
func test_a_mixed_row_keeps_climbing() -> void:
	var m := BuildNotes.Melody.new()
	var a := m.next(BlockIds.STONE, Vector3i(0, 0, 0), 0)
	var b := m.next(BlockIds.GLASS, Vector3i(1, 0, 0), 300)
	var c := m.next(BlockIds.RED, Vector3i(1, 1, 0), 600)
	assert_eq(a, BuildNotes.base_degree(BlockIds.STONE))
	assert_eq(b, a + 1)
	assert_eq(c, a + 2, "stacking up counts as a row too")


## A pause, or a block far from the last one, starts a new tune with that block's own note.
func test_a_pause_or_a_far_block_starts_again() -> void:
	var m := BuildNotes.Melody.new()
	m.next(BlockIds.PLANKS, Vector3i(0, 0, 0), 0)
	m.next(BlockIds.PLANKS, Vector3i(1, 0, 0), 200)
	assert_eq(m.next(BlockIds.GLASS, Vector3i(2, 0, 0), 200 + BuildNotes.ROW_GAP_MS + 1), BuildNotes.base_degree(BlockIds.GLASS),
		"a pause")
	m.next(BlockIds.PLANKS, Vector3i(3, 0, 0), 5000)
	assert_eq(m.next(BlockIds.STONE, Vector3i(3 + BuildNotes.ROW_REACH + 1, 0, 0), 5100), BuildNotes.base_degree(BlockIds.STONE),
		"far away")


func test_no_note_is_ever_above_the_top() -> void:
	var m := BuildNotes.Melody.new()
	for i in 60:
		var d := m.next(BlockIds.CRYSTAL if i % 3 == 0 else BlockIds.GLASS, Vector3i(i % 2, i / 2, 0), i * 100)
		assert_between(d, 0, BuildNotes.TOP, "note %d" % i)


## The budget: at most one note every MIN_GAP_MS and PER_SECOND in any second, however fast blocks come.
func test_the_budget_never_floods_the_mix() -> void:
	var m := BuildNotes.Melody.new()
	var played := 0
	for ms in range(0, 1000, 5):   # 200 placements in one second
		if m.may_play(ms):
			played += 1
	assert_between(played, 1, BuildNotes.PER_SECOND)
	var n := BuildNotes.Melody.new()
	assert_true(n.may_play(0))
	assert_false(n.may_play(BuildNotes.MIN_GAP_MS - 1), "too soon")
	assert_true(n.may_play(BuildNotes.MIN_GAP_MS + 1))
	var slow := BuildNotes.Melody.new()
	var all := 0
	for i in 20:   # a child tapping three times a second is always heard
		if slow.may_play(i * 333):
			all += 1
	assert_eq(all, 20)
