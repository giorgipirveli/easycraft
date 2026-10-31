extends GutTest
## Owner #70, #73 and #111, grade 7 health and PE, design and technology, and projects (research §6.7): the School draws
## their pictures from data (SchoolPictureG7Life, inside SchoolPicture): heart-rate zones with a session's pulse, the
## flight of a net game's shots, a night's sleep on a 24-hour dial, a portrait before and after editing, an advert's
## tricks, what influences a choice, a referee's signals; circuit diagrams with UK symbols, a resistor's colour bands, a
## classroom microcontroller board, a torch's exploded view, a laser cutter and a 3D printer, technical fabrics, and a
## home that saves energy and water. Every sample draws at the School's picture sizes; broken data is a problem the
## content test finds; the rules the pictures draw by (zones, hours, ohms, a complete loop, the LEDs, the parts' places)
## are checked here.

const SAMPLES: Array[Dictionary] = [
	{"kind": "hr_zones", "max": 208},
	{"kind": "hr_zones", "max": 200, "trace": [["rest", 70], ["warm", 115], ["run", 150], ["sprint", 182], ["cool", 100]],
		"point": 2, "mark": "aerobic"},
	{"kind": "hr_zones", "max": 160, "names": false, "trace": [["0", 80], ["10", 130]], "hide": "anaerobic"},
	{"kind": "shot_paths", "sport": "badminton", "shots": ["clear", "drop", "smash", "net"]},
	{"kind": "shot_paths", "sport": "badminton", "shots": ["drive"], "mark": "drive"},
	{"kind": "shot_paths", "sport": "tennis", "shots": ["lob", "drop", "smash", "drive"], "tags": true},
	{"kind": "sleep_dial", "sleep": "22:00", "wake": "07:00", "screens": "21:00"},
	{"kind": "sleep_dial", "sleep": "23:30", "wake": "07:00", "hide": true},
	{"kind": "sleep_dial", "sleep": "01:15", "wake": "10:45", "hours": false},
	{"kind": "photo_edit", "edits": ["light", "filter", "smooth", "eyes", "teeth", "background"], "tags": true,
		"names": true},
	{"kind": "photo_edit", "edits": ["smooth"], "before": false},
	{"kind": "photo_edit", "edits": ["background", "teeth"]},
	{"kind": "advert", "product": "drink", "tricks": ["star", "bandwagon", "free_gift", "health_claim", "small_print",
		"ad_label"]},
	{"kind": "advert", "product": "trainers", "tricks": ["star", "ad_label"], "labels": true, "mark": "star"},
	{"kind": "advert", "product": "cereal", "tricks": ["health_claim", "free_gift", "small_print"], "labels": true,
		"hide": "free_gift", "words": false},
	{"kind": "influence_map", "centre": "my choice", "influences": ["family", "friends", "adverts", "social media",
		"school", "culture"]},
	{"kind": "influence_map", "centre": "lunch", "influences": ["price", "taste"], "mark": 1, "hide": 0},
	{"kind": "ref_signal", "signal": "advantage", "name": true},
	{"kind": "ref_signal", "signal": "direct"},
	{"kind": "ref_signal", "signal": "indirect", "name": true},
	{"kind": "ref_signal", "signal": "penalty"},
	{"kind": "ref_signal", "signal": "card", "card": "red", "name": true},
	{"kind": "schematic", "parts": ["switch", "resistor", "led", "battery"], "names": true},
	{"kind": "schematic", "parts": ["closed", "resistor", "led", "battery"], "lit": true,
		"values": ["", "330 ohms", "", "9 V"]},
	{"kind": "schematic", "parts": ["pad", "buzzer", "cell"], "active": true, "lit": true, "names": true,
		"values": ["", "", "3 V"]},
	{"kind": "schematic", "parts": ["push", "led_back", "resistor", "battery"], "active": true, "lit": true, "mark": 1},
	{"kind": "schematic", "parts": ["reed", "tilt", "lamp", "motor", "ldr", "cell"], "hide": 4},
	{"kind": "resistor", "bands": ["brown", "black", "red", "gold"], "names": true, "value": true},
	{"kind": "resistor", "bands": ["orange", "orange", "brown"], "hide": 2},
	{"kind": "resistor", "bands": ["yellow", "violet", "black", "silver"]},
	{"kind": "micro_board", "leds": ["01010", "11111", "11111", "01110", "00100"], "pressed": "A", "sound": true},
	{"kind": "micro_board", "grid": true, "leds": ["10000", "00000", "00100", "00000", "00001"]},
	{"kind": "micro_board", "labels": true, "mark": "speaker", "hide": "pins"},
	{"kind": "exploded", "product": "torch"},
	{"kind": "exploded", "product": "torch", "labels": true, "mark": "reflector", "hide": "spring"},
	{"kind": "cam_process", "machine": "laser"},
	{"kind": "cam_process", "machine": "laser", "labels": true, "mark": "beam"},
	{"kind": "cam_process", "machine": "printer", "layers": 12, "labels": true, "hide": "nozzle"},
	{"kind": "cam_process", "machine": "printer", "layers": 2},
	{"kind": "fabric_section", "type": "breathable", "labels": true},
	{"kind": "fabric_section", "type": "breathable", "mark": "membrane"},
	{"kind": "fabric_section", "type": "reflective", "labels": true, "hide": "glass beads"},
	{"kind": "fabric_section", "type": "smart", "labels": true},
	{"kind": "fabric_section", "type": "smart"},
	{"kind": "eco_home"},
	{"kind": "eco_home", "labels": true, "mark": "heat pump", "hide": "insulation"},
	{"kind": "eco_home", "features": ["solar panels", "rain butt"], "labels": true},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126),
	ExerciseCheck.LABEL_BOX]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_and_variant_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG7Life.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	var has := func(kind: String, key: String, value: String) -> bool:
		return SAMPLES.any(func(d: Dictionary) -> bool: return d.kind == kind and str(d.get(key, "")) == value)
	for s: String in SchoolPictureG7Life.SIGNALS:
		assert_true(has.call("ref_signal", "signal", s), "a %s signal" % s)
	for m: String in SchoolPictureG7Life.MACHINES:
		assert_true(has.call("cam_process", "machine", m), "a %s" % m)
	for t: String in SchoolPictureG7Life.FABRICS:
		assert_true(has.call("fabric_section", "type", t), "a %s fabric" % t)
	for p: String in SchoolPictureG7Life.PRODUCTS:
		assert_true(has.call("advert", "product", p), "an advert for %s" % p)
	for s: String in SchoolPictureG7Life.SPORTS:
		assert_true(has.call("shot_paths", "sport", s), "%s's shots" % s)
	var syms := {}
	for d in SAMPLES:
		if d.kind == "schematic":
			for s: Variant in d.parts:
				syms[str(s)] = true
	for s: String in SchoolPictureG7Life.SYMS:
		assert_true(syms.has(s), "the %s symbol drawn" % s)


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


func test_broken_pictures_are_problems() -> void:
	for d: Dictionary in [
			{"kind": "hr_zones"}, {"kind": "hr_zones", "max": 140}, {"kind": "hr_zones", "max": 200.5},
			{"kind": "hr_zones", "max": 200, "trace": [["a", 100]]},
			{"kind": "hr_zones", "max": 200, "trace": [["a", 100], ["b", 300]]},
			{"kind": "hr_zones", "max": 200, "trace": [["a label far too long", 100], ["b", 120]]},
			{"kind": "hr_zones", "max": 200, "point": 0}, {"kind": "hr_zones", "max": 200, "trace": [["a", 100],
				["b", 120]], "point": 2}, {"kind": "hr_zones", "max": 200, "mark": "rest"},
			{"kind": "shot_paths", "sport": "golf", "shots": ["clear"]},
			{"kind": "shot_paths", "sport": "tennis", "shots": ["clear"]},
			{"kind": "shot_paths", "sport": "badminton", "shots": []},
			{"kind": "shot_paths", "sport": "badminton", "shots": ["clear", "clear"]},
			{"kind": "shot_paths", "sport": "badminton", "shots": ["clear", "drop", "smash", "drive", "net"]},
			{"kind": "shot_paths", "sport": "badminton", "shots": ["clear"], "mark": "drop"},
			{"kind": "sleep_dial", "sleep": "22:00"}, {"kind": "sleep_dial", "sleep": "22:10", "wake": "07:00"},
			{"kind": "sleep_dial", "sleep": "25:00", "wake": "07:00"}, {"kind": "sleep_dial", "sleep": "22:00",
				"wake": "23:00"}, {"kind": "sleep_dial", "sleep": "06:00", "wake": "22:00"},
			{"kind": "sleep_dial", "sleep": "22:00", "wake": "07:00", "screens": "9pm"},
			{"kind": "photo_edit", "edits": []}, {"kind": "photo_edit", "edits": ["blur"]},
			{"kind": "photo_edit", "edits": ["light", "light"]}, {"kind": "photo_edit", "edits": ["light"], "tags": 1},
			{"kind": "advert", "product": "car", "tricks": ["star"]}, {"kind": "advert", "product": "drink", "tricks": []},
			{"kind": "advert", "product": "drink", "tricks": ["star"], "mark": "bandwagon"},
			{"kind": "influence_map", "centre": "", "influences": ["a", "b"]},
			{"kind": "influence_map", "centre": "me", "influences": ["a"]},
			{"kind": "influence_map", "centre": "me", "influences": ["a", "b"], "mark": 2},
			{"kind": "influence_map", "centre": "me", "influences": ["a name much too long", "b"]},
			{"kind": "ref_signal", "signal": "offside"}, {"kind": "ref_signal", "signal": "direct", "card": "red"},
			{"kind": "ref_signal", "signal": "card", "card": "green"},
			{"kind": "schematic", "parts": ["led"]}, {"kind": "schematic", "parts": ["led", "resistor"]},
			{"kind": "schematic", "parts": ["led", "battery", "cell"]},
			{"kind": "schematic", "parts": ["led", "battery", "transistor"]},
			{"kind": "schematic", "parts": ["led", "battery"], "values": ["2 V"]},
			{"kind": "schematic", "parts": ["led", "battery"], "values": ["a long value", ""]},
			{"kind": "schematic", "parts": ["led", "battery"], "mark": 2},
			{"kind": "schematic", "parts": ["led", "lamp", "buzzer", "motor", "resistor", "ldr", "battery"]},
			{"kind": "resistor", "bands": ["brown", "black"]}, {"kind": "resistor", "bands": ["black", "red", "red"]},
			{"kind": "resistor", "bands": ["brown", "black", "gold"]},
			{"kind": "resistor", "bands": ["brown", "black", "red", "red"]},
			{"kind": "resistor", "bands": ["brown", "black", "red"], "hide": 3},
			{"kind": "micro_board", "leds": ["00000"]}, {"kind": "micro_board", "leds": ["0000", "00000", "00000",
				"00000", "00000"]}, {"kind": "micro_board", "leds": ["0000x", "00000", "00000", "00000", "00000"]},
			{"kind": "micro_board", "pressed": "C"}, {"kind": "micro_board", "mark": "battery"},
			{"kind": "exploded", "product": "phone"}, {"kind": "exploded", "product": "torch", "hide": "bulb"},
			{"kind": "cam_process", "machine": "lathe"}, {"kind": "cam_process", "machine": "laser", "layers": 4},
			{"kind": "cam_process", "machine": "printer", "layers": 20},
			{"kind": "cam_process", "machine": "printer", "mark": "beam"},
			{"kind": "fabric_section", "type": "wool"}, {"kind": "fabric_section", "type": "smart", "mark": "rain"},
			{"kind": "eco_home", "features": []}, {"kind": "eco_home", "features": ["wind turbine"]},
			{"kind": "eco_home", "features": ["rain butt"], "mark": "heat pump"},
			{"kind": "eco_home", "labels": "yes"}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


## Heart-rate zones as shares of the maximum: warm-up 50-60%, aerobic 60-80%, anaerobic 80-90%, maximum 90-100%.
func test_the_zones() -> void:
	assert_eq(SchoolPictureG7Life.zone_of(200, 90), "rest")
	assert_eq(SchoolPictureG7Life.zone_of(200, 100), "warm-up")
	assert_eq(SchoolPictureG7Life.zone_of(200, 120), "aerobic")
	assert_eq(SchoolPictureG7Life.zone_of(200, 159), "aerobic")
	assert_eq(SchoolPictureG7Life.zone_of(200, 160), "anaerobic")
	assert_eq(SchoolPictureG7Life.zone_of(200, 185), "maximum")
	assert_eq(SchoolPictureG7Life.zone_of(200, 210), "maximum")
	assert_eq(SchoolPictureG7Life.zone_bpm(208, 0.6), 125)
	assert_eq(SchoolPictureG7Life.zone_bpm(208, 0.8), 166)


## Hours of sleep across midnight, and the way the dial writes them.
func test_the_hours_of_sleep() -> void:
	assert_almost_eq(SchoolPictureG7Life.sleep_hours("22:00", "07:00"), 9.0, 0.001)
	assert_almost_eq(SchoolPictureG7Life.sleep_hours("23:30", "07:00"), 7.5, 0.001)
	assert_almost_eq(SchoolPictureG7Life.sleep_hours("01:15", "10:45"), 9.5, 0.001)
	assert_almost_eq(SchoolPictureG7Life.sleep_hours("21:45", "07:00"), 9.25, 0.001)
	assert_eq(SchoolPictureG7Life.hours_text(9.0), "9 hours")
	assert_eq(SchoolPictureG7Life.hours_text(8.5), "8.5 hours")
	assert_eq(SchoolPictureG7Life.minutes_of("7:30"), 450)
	assert_eq(SchoolPictureG7Life.minutes_of("07:20"), -1)


## A resistor's bands: two digits, then that many zeros.
func test_the_colour_code() -> void:
	assert_eq(SchoolPictureG7Life.resistor_ohms(["brown", "black", "red", "gold"]), 1000)
	assert_eq(SchoolPictureG7Life.resistor_ohms(["orange", "orange", "brown"]), 330)
	assert_eq(SchoolPictureG7Life.resistor_ohms(["yellow", "violet", "black"]), 47)
	assert_eq(SchoolPictureG7Life.resistor_ohms(["red", "red", "orange"]), 22000)


## A loop conducts with no open switch and no LED the wrong way round; push switches, pads, reed and tilt switches only
## when active.
func test_a_loop_conducts() -> void:
	assert_true(SchoolPictureG7Life.conducts(["closed", "resistor", "led", "battery"], false))
	assert_false(SchoolPictureG7Life.conducts(["switch", "resistor", "led", "battery"], true))
	assert_false(SchoolPictureG7Life.conducts(["pad", "buzzer", "cell"], false))
	assert_true(SchoolPictureG7Life.conducts(["pad", "buzzer", "cell"], true))
	assert_false(SchoolPictureG7Life.conducts(["closed", "led_back", "resistor", "battery"], true))


## The board's LEDs by column and row from the top left.
func test_the_leds() -> void:
	var leds := ["10000", "00000", "00100", "00000", "00001"]
	assert_true(SchoolPictureG7Life.led_at(leds, 0, 0))
	assert_true(SchoolPictureG7Life.led_at(leds, 2, 2))
	assert_true(SchoolPictureG7Life.led_at(leds, 4, 4))
	assert_false(SchoolPictureG7Life.led_at(leds, 4, 0))
	assert_false(SchoolPictureG7Life.led_at(leds, 5, 0))


## Every part a label can point at has a place inside the picture, and none of a kind's parts share one.
func test_every_part_has_its_place() -> void:
	var box := ExerciseCheck.LABEL_BOX
	var pictures: Array[Dictionary] = [{"kind": "advert", "product": "drink", "tricks": SchoolPictureG7Life.TRICKS},
		{"kind": "micro_board"}, {"kind": "exploded", "product": "torch"}, {"kind": "eco_home"}]
	for m: String in SchoolPictureG7Life.MACHINES:
		pictures.append({"kind": "cam_process", "machine": m})
	for t: String in SchoolPictureG7Life.FABRICS:
		pictures.append({"kind": "fabric_section", "type": t})
	var checked := 0
	for p in pictures:
		var names: Array = []
		match str(p.kind):
			"advert":
				for t: String in SchoolPictureG7Life.TRICKS:
					names.append(SchoolPictureG7Life.TRICK_NAMES[t])
			"micro_board":
				names = SchoolPictureG7Life.BOARD_PARTS
			"exploded":
				names = SchoolPictureG7Life.TORCH_PARTS
			"eco_home":
				names = SchoolPictureG7Life.ECO_PARTS
			"cam_process":
				names = SchoolPictureG7Life.CAM_PARTS[str(p.machine)]
			"fabric_section":
				names = SchoolPictureG7Life.FABRIC_PARTS[str(p.type)]
		var seen: Array[Vector2] = []
		for n: Variant in names:
			var at := SchoolPictureG7Life.part_at(p, str(n), box)
			assert_true(Rect2(Vector2.ZERO, box).has_point(at), "%s: %s is inside (%s)" % [p.kind, n, at])
			for other in seen:
				assert_gt(at.distance_to(other), 8.0, "%s: %s has its own place" % [p.kind, n])
			seen.append(at)
			checked += 1
	assert_eq(SchoolPictureG7Life.part_at({"kind": "eco_home", "features": ["rain butt"]}, "heat pump", box),
		Vector2(-1, -1), "a part not drawn has no place")
	assert_eq(SchoolPictureG7Life.part_at({"kind": "hr_zones", "max": 200}, "aerobic", box), Vector2(-1, -1))
	assert_gt(checked, 35, "the parts were checked")
