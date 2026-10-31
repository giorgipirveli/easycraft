extends GutTest
## The classical pieces (owner feedback #31): at least 8, by Beethoven, Mozart, Bach, Grieg, Tchaikovsky,
## Vivaldi and Satie, each with its composer, its title and the moods it fits; enough pieces in every mood
## that none plays twice in a row.

const COMPOSERS := ["Beethoven", "Mozart", "Bach", "Grieg", "Tchaikovsky", "Vivaldi", "Satie"]


func test_at_least_eight_pieces_by_the_great_composers() -> void:
	assert_gte(MusicPieces.ids().size(), 8)
	var composers := {}
	for id: StringName in MusicPieces.ids():
		composers[MusicPieces.composer(id)] = true
	for c: String in COMPOSERS:
		assert_true(composers.has(c), c)


func test_every_piece_has_a_title_a_file_a_length_and_moods() -> void:
	for id: StringName in MusicPieces.ids():
		assert_ne(MusicPieces.title(id), "", String(id))
		assert_true(MusicPieces.path(id).begins_with("res://assets/music/classical/"), String(id))
		assert_between(MusicPieces.length(id), 60.0, 190.0, String(id))
		assert_false(MusicPieces.moods(id).is_empty(), String(id))
		for mood: StringName in MusicPieces.moods(id):
			assert_true(MusicPlan.MOODS.has(mood), "%s: %s" % [id, mood])


func test_every_mood_has_pieces_and_all_but_the_morning_have_two() -> void:
	for mood: StringName in MusicPlan.MOODS:
		var n := MusicPieces.for_mood(mood).size()
		assert_gte(n, 2 if mood != MusicPlan.MORNING else 1, "%s: %d pieces" % [mood, n])


func test_the_labels_name_the_composer_first() -> void:
	assert_eq(MusicPieces.label(&"nachtmusik"), "Mozart — Eine kleine Nachtmusik")
	assert_eq(MusicPieces.label(&"no_such_piece"), "")


func test_the_boss_pieces_are_the_dramatic_ones() -> void:
	assert_true(MusicPieces.fits(&"mountain_king", MusicPlan.BOSS))
	assert_false(MusicPieces.fits(&"gymnopedie", MusicPlan.BOSS))
	assert_true(MusicPieces.fits(&"morning_mood", MusicPlan.MORNING))
	assert_false(MusicPieces.fits(&"no_such_piece", MusicPlan.DAY))
