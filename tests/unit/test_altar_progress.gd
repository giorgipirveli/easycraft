extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §3.6's fade, §3.10's keeper's journal, §3.12, rulings 11, 19,
## 20, 30): the temple's state, on this device only in phase B (`user://balance_altar.json`, like PlayQuests): the rooms
## lit (the board opens the next), each room's Glimmers freed (kept when the child stops for now: never lost), the
## keeper's journal (each idea shown with or without help, where, the misconceptions seen) and the fade's stage (the
## grade sets the start; three altars freed first time in a row move it on, two helped in a row move it back).
## Nothing changes by itself: no clocks, no timers, no decay.

var _path := ""


func before_each() -> void:
	_path = "user://test_altar_progress_%d.json" % randi()


func after_each() -> void:
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))


func test_a_new_temple_is_dark_and_starts_at_the_grade_s_stage() -> void:
	var p := AltarProgress.open_at(_path)
	assert_eq(p.done, [] as Array[String])
	assert_eq(p.open_rooms(), ["entrance"] as Array[String])
	assert_eq(p.begin_stage(6), AltarRunes.PICTURES)
	assert_eq(p.begin_stage(8), AltarRunes.PICTURES, "set once: the child's play moves it after that")
	var q := AltarProgress.open_at(_path + ".b")
	assert_eq(q.begin_stage(7), AltarRunes.LETTERS)


func test_the_fade_moves_with_play() -> void:
	var p := AltarProgress.open_at(_path)
	p.begin_stage(6)
	assert_eq(p.note_altar(SkillShown.SOLVED), AltarRunes.PICTURES)
	assert_eq(p.note_altar(SkillShown.NEW_SETTING), AltarRunes.PICTURES)
	assert_eq(p.note_altar(SkillShown.SOLVED), AltarRunes.NUMBERS, "three in a row unhelped: the next stage")
	assert_eq(p.note_altar(SkillShown.HELPED), AltarRunes.NUMBERS)
	assert_eq(p.note_altar(SkillShown.SHOWN), AltarRunes.PICTURES, "two helped in a row: back one")
	assert_eq(p.note_altar(SkillShown.HELPED), AltarRunes.PICTURES)
	assert_eq(p.note_altar(SkillShown.HELPED), AltarRunes.PICTURES, "never below pictures")
	for i in 12:
		p.note_altar(SkillShown.SOLVED)
	assert_eq(p.stage, AltarRunes.RUNES, "never past the runes")


func test_glimmers_freed_are_kept_even_when_the_child_stops() -> void:
	var p := AltarProgress.open_at(_path)
	p.free_glimmer("entrance", 1)
	p.free_glimmer("entrance", 3)
	p.free_glimmer("entrance", 3)
	p.save()
	var again := AltarProgress.open_at(_path)
	assert_eq(again.glimmers_freed("entrance"), [1, 3] as Array[int])
	assert_false(again.lit("entrance"), "stopped for now: freed Glimmers stay, the hall isn't lit")


func test_a_finished_room_is_lit_and_its_altars_go_in_the_journal() -> void:
	var p := AltarProgress.open_at(_path)
	p.finish("entrance", [
		{"n": 3, "form": "add_L", "kind": SkillShown.SOLVED, "note": ""},
		{"n": 6, "form": "mul_L", "kind": SkillShown.HELPED, "note": "one pan, ghost step"},
		{"n": 11, "form": "two_L", "kind": SkillShown.NEW_SETTING, "note": "the Great Altar"},
	])
	assert_true(p.lit("entrance"))
	assert_eq(p.open_rooms(), ["entrance", "sky"] as Array[String], "the great door opens onto the Sky Room")
	assert_eq(p.shown(AltarProgress.TAKE), 2, "x + a = b and the Great Altar")
	assert_eq(p.shown(AltarProgress.SHARE), 1, "the Great Altar")
	assert_eq(p.helped(AltarProgress.SHARE), 1, "c x = b with help")
	assert_eq(p.shown(AltarProgress.ORDER), 1)
	assert_eq(p.shown(AltarProgress.TWIN), 2)
	assert_eq(int(p.misses(AltarProgress.TWIN).get("one pan", 0)), 1, "the misconception seen")
	assert_eq(p.rooms(AltarProgress.TAKE), ["entrance"])
	p.finish("sky", [{"n": 1, "form": "sub_L", "kind": SkillShown.NEW_SETTING, "note": "the Sky Room"}])
	assert_eq(p.shown(AltarProgress.BALLOONS), 1)
	assert_eq(p.rooms(AltarProgress.BALLOONS), ["sky"])


func test_saved_and_opened_again_and_a_broken_file_is_a_new_temple() -> void:
	var p := AltarProgress.open_at(_path)
	p.begin_stage(6)
	p.finish("entrance", [{"n": 3, "form": "add_L", "kind": SkillShown.SOLVED, "note": ""}])
	p.free_glimmer("entrance", 11)
	p.save()
	var again := AltarProgress.open_at(_path)
	assert_true(again.lit("entrance"))
	assert_eq(again.shown(AltarProgress.TAKE), 1)
	assert_eq(again.stage, AltarRunes.PICTURES)
	assert_eq(again.glimmers_freed("entrance"), [11] as Array[int])
	var f := FileAccess.open(_path, FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	assert_eq(AltarProgress.open_at(_path).done, [] as Array[String])


func test_nothing_in_the_file_is_a_clock() -> void:
	var p := AltarProgress.open_at(_path)
	p.finish("entrance", [])
	var keys := p.to_dict().keys()
	for k: Variant in keys:
		assert_false(str(k).contains("time") or str(k).contains("date") or str(k).contains("day"), str(k))
