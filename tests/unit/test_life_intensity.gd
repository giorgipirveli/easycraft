extends GutTest
## Owner #118 (docs/design/life-skills.md §14: "a calm intensity setting on the grown-ups' page (gentle by default; a
## grown-up may allow 'more real' on the Big track)"; Life L3a): the setting is the profile's (LifeData.intensity), kept in
## the backup, merged as the grown-up's latest choice, and only ever "more real" on the Big track. The device's
## measurement counts how often each step's wrong way is tried (LifeMeasure's "m").


func test_gentle_by_default() -> void:
	var life := LifeData.new()
	assert_eq(life.intensity, LifeData.GENTLE)
	assert_true(life.is_empty(), "the default keeps an untouched Life empty")
	for track in LifeData.TRACKS:
		assert_eq(life.intensity_for(track), LifeData.GENTLE, track)


func test_more_real_only_on_the_big_track() -> void:
	var life := LifeData.new()
	life.intensity = LifeData.REAL
	assert_false(life.is_empty())
	assert_eq(life.intensity_for("big"), LifeData.REAL)
	assert_eq(life.intensity_for("middle"), LifeData.GENTLE, "never for a younger track")
	assert_eq(life.intensity_for("little"), LifeData.GENTLE)


func test_it_travels_in_the_backup_and_a_bad_value_is_gentle() -> void:
	var life := LifeData.new()
	life.intensity = LifeData.REAL
	assert_eq(LifeData.from_dict(life.to_dict()).intensity, LifeData.REAL)
	var bad := life.to_dict()
	bad["intensity"] = "scary"
	assert_eq(LifeData.from_dict(bad).intensity, LifeData.GENTLE)
	bad.erase("intensity")
	assert_eq(LifeData.from_dict(bad).intensity, LifeData.GENTLE, "an older save")


func test_the_merge_keeps_the_grown_ups_latest_choice() -> void:
	var newer := LifeData.new()
	var older := LifeData.new()
	older.intensity = LifeData.REAL
	newer.merge_from(older)
	assert_eq(newer.intensity, LifeData.GENTLE, "the newer copy's (like the careful switches)")


func test_the_measurement_counts_the_wrong_way_tried() -> void:
	var path := "user://life_measure_intensity_%d.json" % OS.get_process_id()
	var m := LifeMeasure.new(path)
	m.note("water_safety.middle", [{"id": "rip", "seconds": 4.0, "hinted": false, "mistakes": 1}] as Array[Dictionary])
	m.note("water_safety.middle", [{"id": "rip", "seconds": 3.0, "hinted": false, "mistakes": 0}] as Array[Dictionary])
	assert_eq(int(m.step("water_safety.middle", "rip").m), 1, "one run tried the wrong way")
	assert_eq(int(m.step("water_safety.middle", "rip").fm), 1, "and the very first time did")
	assert_true(m.save())
	var back := LifeMeasure.new(path)
	assert_eq(int(back.step("water_safety.middle", "rip").m), 1)
	DirAccess.remove_absolute(path)
