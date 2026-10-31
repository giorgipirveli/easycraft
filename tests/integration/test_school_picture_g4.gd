extends GutTest
## Owner #68, grade 4 science (the grade 4 agent): the picture kinds its units need, drawn from data like the others
## (SchoolPicture's section "Grade 4 science kinds"): waves (crest, trough, amplitude, wavelength), pictures sent as 1s
## and 0s, maps of land, sea, mountains, volcanoes and earthquakes with their key, and light's path from a source to
## an object and into an eye.

const SAMPLES: Array[Dictionary] = [
	{"kind": "wave", "waves": [{"amp": 2, "count": 3}]},
	{"kind": "wave", "waves": [{"amp": 1, "count": 2}, {"amp": 3, "count": 4}], "names": true},
	{"kind": "wave", "waves": [{"amp": 1, "count": 2}, {"amp": 2, "count": 2}, {"amp": 4, "count": 5}], "names": true},
	{"kind": "wave", "waves": [{"amp": 2, "count": 2}], "labels": ["crest", "trough", "amplitude", "wavelength"]},
	{"kind": "pixels", "rows": ["01110", "10001", "11111"]},
	{"kind": "pixels", "rows": ["0110", "1001"], "digits": true},
	{"kind": "map", "rows": ["~~~..^^", "~~v..^.", "~=*...."], "key": true},
	{"kind": "map", "rows": ["~~x~~", "~.v.~"]},
	{"kind": "rays", "source": "sun", "object": 9},
	{"kind": "rays", "source": "lamp", "object": 272, "mirror": true},
	{"kind": "rays", "source": "none", "object": 9},
]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_science_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPicture.SCIENCE_KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)


func test_every_sample_draws_at_the_schools_sizes() -> void:
	for d in SAMPLES:
		for px: Vector2 in [Vector2(580, 250), Vector2(560, 380), Vector2(248, 126)]:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


func test_broken_pictures_are_problems() -> void:
	for d: Dictionary in [{"kind": "wave"}, {"kind": "wave", "waves": []}, {"kind": "wave", "waves": [{"amp": 0, "count": 2}]},
			{"kind": "wave", "waves": [{"amp": 2, "count": 9}]}, {"kind": "wave", "waves": [{"amp": 5, "count": 2}]},
			{"kind": "wave", "waves": [{"amp": 1, "count": 1}, {"amp": 1, "count": 1}, {"amp": 1, "count": 1},
				{"amp": 1, "count": 1}]},
			{"kind": "wave", "waves": [{"amp": 2, "count": 2}], "labels": ["height"]},
			{"kind": "wave", "waves": [{"amp": 2, "count": 2}, {"amp": 1, "count": 2}], "labels": ["crest"]},
			{"kind": "pixels"}, {"kind": "pixels", "rows": []}, {"kind": "pixels", "rows": ["012"]},
			{"kind": "pixels", "rows": ["01", "011"]}, {"kind": "pixels", "rows": ["0000000000001"]},
			{"kind": "pixels", "rows": ["0", "1", "0", "1", "0", "1", "0", "1", "0"]},
			{"kind": "map", "rows": []}, {"kind": "map", "rows": ["~~q"]}, {"kind": "map", "rows": ["~~", "~~~"]},
			{"kind": "map", "rows": ["...............~"]},
			{"kind": "rays", "source": "torch", "object": 9}, {"kind": "rays", "source": "sun"},
			{"kind": "rays", "source": "sun", "object": 99999}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


func test_a_wave_is_drawn_with_one_crest_per_wavelength() -> void:
	var r := Rect2(10, 20, 500, 100)
	for count in range(1, 9):
		var pts := SchoolPicture.wave_line(r, 30.0, count)
		assert_almost_eq(pts[0].x, r.position.x, 0.01, "it starts at the left")
		assert_almost_eq(pts[pts.size() - 1].x, r.end.x, 0.01, "and ends at the right")
		var crests := 0
		var troughs := 0
		for i in range(1, pts.size() - 1):
			if pts[i].y < pts[i - 1].y and pts[i].y <= pts[i + 1].y:
				crests += 1   # screen y grows downwards: a crest is a local top
			if pts[i].y > pts[i - 1].y and pts[i].y >= pts[i + 1].y:
				troughs += 1
		assert_eq(crests, count, "%d wavelengths, %d crests" % [count, count])
		assert_eq(troughs, count, "and %d troughs" % count)
		var top := INF
		for p in pts:
			top = minf(top, p.y)
		assert_almost_eq(r.get_center().y - top, 30.0, 0.5, "its crests stand the amplitude above the middle line")


func test_a_maps_key_names_what_the_map_shows_once_in_a_fixed_order() -> void:
	assert_eq(SchoolPicture.map_key(["~~v..^", "~x*..."]),
		["sea", "land", "mountain", "volcano", "earthquake"] as Array[String])
	assert_eq(SchoolPicture.map_key(["~=", "~~"]), ["sea", "deep trench"] as Array[String])
