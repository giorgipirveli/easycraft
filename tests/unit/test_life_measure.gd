extends GutTest
## Owner #113 (docs/design/life-skills.md §10 "Measured"): each Experience step's first-time success measured on the
## device (how often it is done without the hint, how long it takes), in its own file, never in the profile and never
## sent: a step most children miss gets redesigned.

var path := ""


func before_each() -> void:
	path = "user://life_measure_test_%d.json" % OS.get_process_id()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func after_each() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _log() -> Array[Dictionary]:
	return [{"id": "low", "kind": "action", "seconds": 4.0, "hinted": false},
		{"id": "check", "kind": "hold", "seconds": 12.0, "hinted": true}]


func test_a_run_is_counted_per_step() -> void:
	var m := LifeMeasure.new(path)
	m.note("fire_escape.middle", _log())
	var low := m.step("fire_escape.middle", "low")
	assert_eq(int(low.n), 1)
	assert_eq(int(low.u), 1, "done without the hint")
	assert_almost_eq(float(low.s), 4.0, 0.01)
	assert_eq(int(low.f), 1, "the first time: unaided")
	var check := m.step("fire_escape.middle", "check")
	assert_eq(int(check.u), 0)
	assert_eq(int(check.f), 0, "the first time needed the coach")


func test_the_first_time_stays_the_first_time() -> void:
	var m := LifeMeasure.new(path)
	m.note("fire_escape.middle", _log())
	var later: Array[Dictionary] = [{"id": "check", "kind": "hold", "seconds": 3.0, "hinted": false}]
	m.note("fire_escape.middle", later)
	var check := m.step("fire_escape.middle", "check")
	assert_eq(int(check.n), 2)
	assert_eq(int(check.u), 1)
	assert_eq(int(check.f), 0)
	assert_almost_eq(float(check.ft), 12.0, 0.01)


func test_it_is_kept_in_its_own_file_on_the_device() -> void:
	var m := LifeMeasure.new(path)
	m.note("money_stall.little", _log())
	assert_true(m.save())
	var again := LifeMeasure.new(path)
	assert_eq(int(again.step("money_stall.little", "low").n), 1)
	assert_ne(LifeMeasure.PATH, "user://profile.json")


func test_a_broken_file_is_a_fresh_start() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	var m := LifeMeasure.new(path)
	assert_true(m.steps.is_empty())


func test_the_share_done_without_a_hint() -> void:
	var m := LifeMeasure.new(path)
	m.note("fire_escape.middle", _log())
	m.note("fire_escape.middle", _log())
	assert_almost_eq(m.unaided_share("fire_escape.middle", "check"), 0.0, 0.01)
	assert_almost_eq(m.unaided_share("fire_escape.middle", "low"), 1.0, 0.01)
