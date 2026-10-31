extends GutTest
## Owner #122 (G0, the brief's "lead's audit"), re-scoped by owner #133, #134 (docs/design/future-lessons.md §6):
## tools/play_audit.py counts the School's written units by play level (P0 the School's own, P1 a deep game) and the
## reading debt: the hand-written challenges a child can play without reading and those that need it, by the game's own
## rules (PlayReadless: the two counts must be equal). It lists any unit with a type no mechanic knows: there must be
## none (--check exits 0). Its count of written units is the School's own (Curriculum).


func _run(args: Array) -> Dictionary:
	var out: Array = []
	var code := OS.execute("python3", [ProjectSettings.globalize_path("res://tools/play_audit.py")] + args, out, true)
	return {"code": code, "text": "\n".join(out)}


func test_no_written_unit_has_a_type_no_mechanic_knows() -> void:
	var r := _run(["--check"])
	assert_eq(int(r.code), 0, str(r.text).right(600))
	assert_string_contains(str(r.text), "PLAY_AUDIT unplayable 0")


func test_the_audit_counts_the_school_s_written_units_by_play_level() -> void:
	var written := 0
	var p1 := 0   # owner #133, #134: the units a deep game plays (the leaf's B2: g5.science.plants_air_water)
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				if u.has("file"):
					written += 1
					if PlayMechanics.level(Curriculum.content(str(u.id))) == PlayMechanics.P1:
						p1 += 1
	Curriculum.clear_cache()
	var r := _run(["--check"])
	assert_string_contains(str(r.text), "PLAY_AUDIT written %d" % written)
	assert_string_contains(str(r.text), "PLAY_AUDIT P0 %d" % (written - p1), "the School's own")
	assert_string_contains(str(r.text), "PLAY_AUDIT P1 %d" % p1, "the deep games' (the registry's)")


func test_the_reading_debt_is_counted_as_the_game_plays() -> void:
	var playable := 0
	var reading := 0
	var why := {}
	Curriculum.clear_cache()
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				if not Curriculum.has_content(str(u.id)):
					continue
				var d := PlayReadless.debt(Curriculum.content(str(u.id)))
				playable += int(d.playable)
				reading += int(d.reading)
				for k: String in d.why:
					why[k] = int(why.get(k, 0)) + int(d.why[k])
	var r := _run([])
	assert_string_contains(str(r.text), "PLAY_AUDIT playable %d" % playable)
	assert_string_contains(str(r.text), "PLAY_AUDIT reading %d" % reading)
	for k in PlayReadless.REASONS:
		assert_string_contains(str(r.text), "PLAY_AUDIT reading_why %s: %d" % [k, int(why.get(k, 0))])
	assert_gt(playable, 0, "some of the School plays without reading")
	assert_gt(reading, playable, "the honest count: most of it still needs reading (future-lessons.md §1)")
