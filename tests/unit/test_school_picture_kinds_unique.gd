extends GutTest
## Two agents once named a picture kind "circuit" each (grade 4 life's and grade 4 core's), and the first hook took both
## (the lead's merge, 2026-09-29): every picture kind is drawn by exactly one place. Every `ui/school/school_picture*.gd`
## is found by itself, so a new agent's picture file is checked without anyone listing it here.

const DIR := "res://ui/school/"


func _kind_lists() -> Dictionary:
	var lists := {}
	for f in DirAccess.get_files_at(DIR):
		if not (f.begins_with("school_picture") and f.ends_with(".gd")):
			continue
		var consts := (load(DIR + f) as Script).get_script_constant_map()
		var kinds: Array = []
		for key: String in ["KINDS", "SCIENCE_KINDS"]:
			if consts.has(key):
				kinds.append_array(consts[key])
		lists[f] = kinds
	return lists


func test_every_picture_file_is_found() -> void:
	var lists := _kind_lists()
	for f: String in ["school_picture.gd", "school_picture_g4core.gd", "school_picture_g5life.gd", "school_picture_g5core.gd",
			"school_picture_g5arts.gd"]:
		assert_true(lists.has(f), f)
		assert_false((lists.get(f, []) as Array).is_empty(), "%s has kinds" % f)


func test_every_picture_kind_has_one_home() -> void:
	var lists := _kind_lists()
	var home := {}
	for owner: String in lists:
		for k: Variant in lists[owner]:
			assert_false(home.has(k), "%s is drawn by %s and %s" % [k, home.get(k, ""), owner])
			home[k] = owner
	assert_gt(home.size(), 100, "every file's kinds (%d)" % home.size())
