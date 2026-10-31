extends GutTest
## Owner #68 (spec §22.1): lesson and exercise pictures are drawn from their data (UI draw calls and block icons, no new
## art): base-ten blocks, arrays, groups, fraction walls, number lines, farms, angles, lines, shapes, line plots, rock
## layers, towers, clocks, tables and single icons. Every kind draws; broken data is a problem the content test finds.

const SAMPLES: Array[Dictionary] = [
	{"kind": "blocks", "thousands": 1, "hundreds": 3, "tens": 4, "ones": 7},
	{"kind": "array", "rows": 3, "cols": 4},
	{"kind": "array", "rows": 2, "cols": 6, "block": 9},
	{"kind": "groups", "groups": 4, "each": 3, "left": 2},
	{"kind": "bar", "den": 8, "num": 3},
	{"kind": "bar", "bars": [{"den": 4, "num": 3}, {"den": 8, "num": 6}]},
	{"kind": "number_line", "from": "0", "to": "1", "step": "1/8", "dot": "3/8"},
	{"kind": "number_line", "from": "0", "to": "1", "step": "0.1", "marks": ["0.4", "0.7"], "labels": "all"},
	{"kind": "number_line", "from": "40000", "to": "50000", "step": "1000", "dot": "46732", "labels": "ends"},
	{"kind": "rect", "w": 6, "h": 4, "unit": "m", "grid": true},
	{"kind": "rect", "w": 8, "h": 3, "unknown": "w"},
	{"kind": "angle", "deg": 60, "show": true},
	{"kind": "angle", "deg": 90, "parts": [35, 55], "protractor": true},
	{"kind": "lines", "what": "perpendicular"},
	{"kind": "lines", "what": "ray"},
	{"kind": "shape", "what": "trapezium", "marks": true},
	{"kind": "shape", "what": "hexagon", "symmetry": true},
	{"kind": "line_plot", "den": 8, "from": 1, "to": 8, "counts": {"2": 1, "3": 3, "5": 2}, "unit": "m"},
	{"kind": "layers", "blocks": [18, 17, 3, 4, 2], "fossils": {"2": "shell", "3": "fish"}},
	{"kind": "towers", "heights": [2, 4, 6], "missing": true},
	{"kind": "clock", "h": 3, "m": 15},
	{"kind": "table", "rows": [["km", "m"], ["1", "1,000"], ["3", "?"]]},
	{"kind": "icon", "block": 28, "count": 3},
	{"kind": "icon", "animal": "owl"},
	{"kind": "icon", "picture": "chest"},
]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPicture.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)


func test_every_sample_draws() -> void:
	for d in SAMPLES:
		var p := SchoolPicture.new(d)
		p.size = Vector2(480, 280)
		add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


func test_broken_pictures_are_problems() -> void:
	for d: Dictionary in [{"kind": "painting"}, {"kind": "array", "rows": 0, "cols": 4}, {"kind": "array", "rows": 30, "cols": 4},
			{"kind": "bar", "den": 4, "num": 5}, {"kind": "number_line", "from": "1", "to": "0", "step": "1"},
			{"kind": "number_line", "from": "0", "to": "1", "step": "1/1000"}, {"kind": "angle", "deg": 400},
			{"kind": "shape", "what": "blob"}, {"kind": "layers", "blocks": []}, {"kind": "icon"},
			{"kind": "icon", "animal": "unicorn"}, {"kind": "clock", "h": 13, "m": 0}, {"kind": "table", "rows": []}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))
