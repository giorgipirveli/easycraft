extends GutTest
## M3 Task 7: a world keeps its smart blocks' state: the teleport pad pairs, the courses (goals, best
## times, the best run recorded for bots) and the power cells to look at again when it loads (buttons
## still pressed, plates stood on). Broken or missing data never stops a world loading.


func test_a_world_saves_and_loads_its_smart_state() -> void:
	var links := TeleportLinks.new()
	links.add(Vector3i(0, 10, 0))
	links.add(Vector3i(9, 10, 3))
	var book := CourseBook.new()
	var path := RecordedRun.new(Vector3(0.5, 11, 0.5))
	for i in 20:
		path.add(Vector3(i, 11, 0))
	book.finished(Vector3i(0, 10, 0), Vector3i(20, 10, 0), 12000, "Kid", path)
	var m := WorldMeta.new()
	m.smart = {"teleports": links.to_save(), "courses": book.to_save(), "power": [[4, 10, 4]]}
	var back := WorldMeta.from_json(m.to_json())
	var l := TeleportLinks.from_save(back.smart.get("teleports"))
	assert_eq(l.partner_of(Vector3i(0, 10, 0)), Vector3i(9, 10, 3))
	var b := CourseBook.from_save(back.smart.get("courses"))
	assert_eq(b.best(Vector3i(0, 10, 0)), 12000)
	assert_eq(b.ghost(Vector3i(0, 10, 0)).size(), 20)
	assert_eq(back.smart.get("power"), [Vector3i(4, 10, 4)])


func test_worlds_saved_before_have_none() -> void:
	var back := WorldMeta.from_json(JSON.stringify({"seed": 5}))
	assert_eq(TeleportLinks.from_save(back.smart.get("teleports")).pads().size(), 0)
	assert_eq(CourseBook.from_save(back.smart.get("courses")).starts().size(), 0)
	assert_eq(back.smart.get("power", []), [])


func test_broken_smart_state_is_cleaned() -> void:
	for bad: Variant in [5, "x", [1], {"teleports": "x", "courses": 3, "power": {"a": 1}},
			{"power": [["a", 1, 2], [1, 2], [1, 2, 3]]}]:
		var back := WorldMeta.from_json(JSON.stringify({"seed": 5, "smart": bad}))
		assert_true(back.smart is Dictionary, str(bad))
		for cell: Variant in back.smart.get("power", []):
			assert_true(cell is Vector3i)
	var many := []
	for i in 500:
		many.append([i, 10, 0])
	var back := WorldMeta.from_json(JSON.stringify({"seed": 5, "smart": {"power": many}}))
	assert_lte((back.smart.power as Array).size(), SmartState.MAX_POWER_CELLS)
