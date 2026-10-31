extends GutTest
## Spec §23.2: the Lab Book is kept in the profile (ProfileData.lab, LabData): each experiment's last prediction, whether
## it matched what happened, how many times it was done (a star from the first) and when the plants' seeds went in. It
## is parsed field by field (a bad entry falls back on its own), saved with the profile, and the server backup's merge
## never loses a star, a guess or a planting.


func test_a_new_lab_book_is_empty() -> void:
	var d := LabData.new()
	assert_true(d.is_empty())
	assert_eq(d.runs("magnets"), 0)
	assert_false(d.has_star("magnets"))
	assert_null(d.guess("magnets"))
	assert_eq(d.planted_at("plants"), 0)
	assert_eq(d.stars(), 0)


func test_guesses_runs_and_stars() -> void:
	var d := LabData.new()
	d.set_guess("magnets", [0, 1, 1, 0], false)
	assert_eq(d.guess("magnets"), [0, 1, 1, 0])
	assert_false(d.matched("magnets"))
	assert_false(d.has_star("magnets"), "a guess alone is no star")
	assert_true(d.finish("magnets"), "the first time: the star")
	assert_true(d.has_star("magnets"))
	assert_false(d.finish("magnets"), "again: no new star, one more run")
	assert_eq(d.runs("magnets"), 2)
	d.set_guess("melting", 0, true)
	assert_true(d.matched("melting"))
	assert_eq(d.stars(), 1)
	d.set_planted("plants", 123456)
	assert_eq(d.planted_at("plants"), 123456)
	d.set_planted("plants", 0)
	assert_eq(d.planted_at("plants"), 0, "picked: the pots are empty again")
	assert_false(d.is_empty())


func test_it_round_trips_and_drops_bad_fields_one_by_one() -> void:
	var d := LabData.new()
	d.set_guess("float_sink", [0, 1, 0, 1, 0, 1, 0, 1], true)
	d.finish("float_sink")
	d.set_guess("melting", 2, false)
	d.set_planted("plants", 99)
	var back := LabData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	assert_eq(back.to_dict(), d.to_dict())
	assert_eq(back.guess("float_sink"), [0, 1, 0, 1, 0, 1, 0, 1])
	assert_eq(back.guess("melting"), 2)
	var bad := LabData.from_dict({"magnets": {"g": "lots", "n": 3, "m": true}, "BAD ID!": {"n": 1},
		"melting": {"n": -4, "g": 1.5}, "colours": "x", "plants": {"p": 1e20, "n": 1}})
	assert_null(bad.guess("magnets"), "a guess must be a choice's index or a sort")
	assert_eq(bad.runs("magnets"), 3, "the rest of the entry stays")
	assert_false(bad.entries.has("BAD ID!"))
	assert_eq(bad.runs("melting"), 0)
	assert_null(bad.guess("melting"))
	assert_false(bad.entries.has("colours"))
	assert_eq(bad.planted_at("plants"), 0)
	assert_eq(bad.runs("plants"), 1)
	assert_true(LabData.from_dict("rubbish").is_empty())


func test_merging_keeps_every_star_guess_and_planting() -> void:
	var a := LabData.new()
	a.finish("magnets")
	a.set_guess("magnets", [0, 1], true)
	a.set_planted("plants", 500)
	var b := LabData.new()
	b.finish("magnets")
	b.finish("magnets")
	b.finish("circuit")
	b.set_guess("circuit", 1, false)
	b.set_guess("magnets", [1, 1], false)
	b.set_planted("plants", 300)
	a.merge_from(b)
	assert_eq(a.runs("magnets"), 2, "the most runs")
	assert_eq(a.guess("magnets"), [0, 1], "this copy's own guess stays")
	assert_true(a.matched("magnets"))
	assert_true(a.has_star("circuit"), "a star from the other copy")
	assert_eq(a.guess("circuit"), 1)
	assert_eq(a.planted_at("plants"), 300, "the earlier planting: its seeds have grown longer")


func test_the_profile_keeps_the_lab_book_and_the_backup_merges_it() -> void:
	var p := ProfileData.new()
	assert_true(p.lab.is_empty())
	p.lab.finish("colours")
	p.lab.set_guess("colours", 1, true)
	var back := ProfileData.from_json(p.to_json())
	assert_true(back.lab.has_star("colours"))
	assert_eq(back.lab.guess("colours"), 1)
	assert_false(ProfileBackup.is_new(back), "a Lab Book star is progress")
	var local := ProfileData.new()
	local.username = "Juno"
	local.updated_at = 100
	local.lab.finish("magnets")
	var remote := ProfileData.new()
	remote.username = "Juno"
	remote.updated_at = 200
	remote.lab.finish("plants")
	var merged: ProfileData = ProfileBackup.merge(local, remote.to_json()).profile
	assert_true(merged.lab.has_star("magnets"), "the older copy's star is kept")
	assert_true(merged.lab.has_star("plants"))
