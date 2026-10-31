extends GutTest
## Owner #117 (docs/design/life-skills.md §13, "Devices: buttons, dials, displays and an order of steps"): the device model
## at run time. Its controls are used in the right order; what it shows changes; its safety steps come first (a drill's
## goggles before its trigger), kindly. It runs on Life L1's device data as written (words) and on structured data.

const DRILL := {
	"controls": [{"id": "battery", "words": "the battery"}, {"id": "chuck", "words": "the chuck"},
		{"id": "speed", "words": "the speed switch"}, {"id": "trigger", "words": "the trigger"}],
	"shows": [{"id": "speed", "words": "the speed: 1 slow, 2 fast", "start": "-"}, {"id": "light", "words": "the light",
		"start": "off"}],
	"order": [{"do": "chuck", "words": "the bit tight in the chuck"},
		{"do": "battery", "words": "the battery in", "shows": {"light": "on"}},
		{"do": "goggles", "words": "goggles on"},
		{"do": "speed", "value": "1", "words": "speed 1 (slow) to start", "shows": {"speed": "1"}},
		{"do": "trigger", "words": "squeeze gently, pressing straight"}],
	"safety": [{"id": "goggles", "words": "goggles on", "before": ["trigger"]},
		{"id": "battery_out", "words": "the battery out to change the bit"}],
}


func _drill() -> ToolDevice:
	return ToolDevice.from(DRILL, "drill")


func test_a_device_used_in_the_right_order_finishes() -> void:
	var d := _drill()
	for step: Array in [["chuck", ""], ["battery", ""], ["goggles", ""], ["speed", "1"], ["trigger", ""]]:
		var r := d.use(str(step[0]), str(step[1]))
		assert_true(bool(r.ok), str(step))
	assert_true(d.finished)


func test_what_it_shows_changes_as_it_is_used() -> void:
	var d := _drill()
	assert_eq(d.display("light"), "off")
	assert_eq(d.display("speed"), "-")
	d.use("chuck")
	d.use("battery")
	assert_eq(d.display("light"), "on")
	d.use("goggles")
	d.use("speed", "1")
	assert_eq(d.display("speed"), "1")


func test_safety_first_the_trigger_waits_for_the_goggles() -> void:
	var d := _drill()
	d.use("chuck")
	d.use("battery")
	var r := d.use("trigger")
	assert_false(bool(r.ok), "never before the goggles")
	assert_eq(str(r.safety), "goggles")
	assert_string_contains(str(r.said), "goggles on")
	assert_false(d.finished)


func test_out_of_order_is_kind_words_never_a_jump() -> void:
	var d := _drill()
	var r := d.use("battery")
	assert_false(bool(r.ok))
	assert_eq(str(r.said), ToolDevice.FIRST % "the bit tight in the chuck")
	assert_eq(d.index, 0, "nothing skipped")


func test_a_dial_set_to_the_wrong_value_waits() -> void:
	var d := _drill()
	d.use("chuck")
	d.use("battery")
	d.use("goggles")
	var r := d.use("speed", "2")
	assert_false(bool(r.ok))
	assert_string_contains(str(r.said), "speed 1")


func test_the_next_thing_to_use_is_known_for_the_glow() -> void:
	var d := _drill()
	assert_eq(d.next_do(), "chuck")
	d.use("chuck")
	assert_eq(d.next_do(), "battery")
	assert_eq(d.fraction(), 1.0 / 5.0)


func test_something_that_is_not_part_of_it_does_nothing() -> void:
	var d := _drill()
	var r := d.use("kettle")
	assert_false(bool(r.ok))
	assert_eq(str(r.said), "")


func test_life_l1s_extinguisher_runs_as_written() -> void:
	var data: Dictionary = LifeExperience.devices("fire_escape", "ge").extinguisher
	var d := ToolDevice.from(data, "extinguisher")
	assert_eq(d.order.size(), 4)
	assert_eq(d.next_do(), ToolDevice.slug("pull the pin"))
	var r := d.use(ToolDevice.slug("squeeze the handle"))
	assert_false(bool(r.ok))
	assert_eq(str(r.said), ToolDevice.FIRST % "pull the pin", "Pull, Aim, Squeeze, Sweep: in that order")
	for words: String in ["pull the pin", "aim at the bottom of the fire", "squeeze the handle", "sweep from side to side"]:
		assert_true(bool(d.use(ToolDevice.slug(words)).ok), words)
	assert_true(d.finished)
	assert_eq(d.safety_words(), ["a small fire only", "the way out behind you", "a grown-up uses it",
		"if in doubt, get out"] as Array[String])


func test_life_l1s_phone_has_the_regions_number() -> void:
	var d := ToolDevice.from(LifeExperience.devices("little_lifesaver", "uk").phone, "phone")
	assert_eq(d.order[1].words, "press 999")
	assert_eq(d.controls.size(), 2)


func test_every_life_device_reads_without_problems() -> void:
	for id in LifeExperience.IDS:
		var devs := LifeExperience.devices(id, "ge")
		for dev: String in devs:
			assert_eq(ToolDevice.problems(devs[dev]), [] as Array[String], "%s %s" % [id, dev])


func test_a_broken_device_is_found() -> void:
	assert_ne(ToolDevice.problems({}), [] as Array[String])
	var bad := DRILL.duplicate(true)
	(bad.safety as Array).append({"id": "x", "words": "a rule", "before": ["laser"]})
	assert_has(ToolDevice.problems(bad), "safety x guards laser, which is not a control")
	var unreachable := DRILL.duplicate(true)
	(unreachable.safety as Array).append({"id": "dry", "words": "dry hands", "before": ["trigger"]})
	assert_has(ToolDevice.problems(unreachable), "safety dry guards trigger but is never in the order",
		"a guard nobody can do would block the device for ever")
	var odd := DRILL.duplicate(true)
	(odd.order as Array).append({"do": "", "words": "?"})
	assert_ne(ToolDevice.problems(odd), [] as Array[String])


func test_a_slug_is_the_words_as_an_id() -> void:
	assert_eq(ToolDevice.slug("Pull the pin!"), "pull_the_pin")
	assert_eq(ToolDevice.slug("  press 112 "), "press_112")
