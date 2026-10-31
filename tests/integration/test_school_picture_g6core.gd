extends GutTest
## Grade 6 maths, science and English, the research's last units: the picture kinds they add (SchoolPictureG6Core,
## drawn inside SchoolPicture): a skeleton, joints, a pair of arm muscles, food tests, enzymes cutting food, a key of
## yes-or-no questions, the five kingdoms, the levels of classification, a shadow's rays, a reflected ray, a periscope
## and a pinhole camera, energy changing form, an energy flow (Sankey) diagram, a function machine, handshakes, an
## argument's plan, a story's arc and an information page. Every kind draws from its data at the School's picture
## sizes; broken data is a problem the content test finds; the rules they draw by are checked here with this file's own
## arithmetic.

const SAMPLES: Array[Dictionary] = [
	{"kind": "skeleton"},
	{"kind": "skeleton", "labels": true},
	{"kind": "skeleton", "labels": true, "hide": "femur", "mark": "femur"},
	{"kind": "skeleton", "mark": "ribs"},
	{"kind": "joint", "type": "hinge"},
	{"kind": "joint", "type": "hinge", "labels": true, "move": false},
	{"kind": "joint", "type": "ball_socket"},
	{"kind": "joint", "type": "ball_socket", "labels": true, "name": false},
	{"kind": "joint", "type": "pivot"},
	{"kind": "joint", "type": "fixed", "name": false},
	{"kind": "muscle_pair", "move": "bend"},
	{"kind": "muscle_pair", "move": "straighten", "states": true},
	{"kind": "muscle_pair", "move": "bend", "labels": true, "hide": "tendon", "mark": "tendon"},
	{"kind": "muscle_pair", "move": "straighten", "labels": true, "mark": "triceps"},
	{"kind": "food_test", "tubes": [["starch", true, "bread"], ["sugar", false, "rice"], ["protein", true, "egg"],
		["fat", true, "butter"]]},
	{"kind": "food_test", "tubes": [["starch", false]], "names": false},
	{"kind": "food_test", "tubes": [["sugar", true, "A"], ["protein", false, "B"], ["fat", false, "C"]]},
	{"kind": "enzyme_cut", "food": "starch"},
	{"kind": "enzyme_cut", "food": "protein", "hide": "enzyme"},
	{"kind": "enzyme_cut", "food": "fat", "hide": "products"},
	{"kind": "enzyme_cut", "food": "starch", "names": false},
	{"kind": "key_tree", "questions": ["Does it have six legs?"], "ends": ["insect", "spider"]},
	{"kind": "key_tree", "questions": ["Does it have feathers?", "Does it have fur?", "Does it have fins?"],
		"ends": ["bird", "mammal", "fish", "frog"], "path": [false, true]},
	{"kind": "key_tree", "questions": ["Does it have a shell?", "Does it have legs?", "Are there 8 legs?",
		"Is its body in segments?"], "ends": ["snail", "?", "spider", "earthworm", "slug"], "hide": 1,
		"path": [false, false, false, false]},
	{"kind": "kingdoms", "show": ["animals", "plants", "fungi", "protists", "bacteria"]},
	{"kind": "kingdoms", "show": ["fungi", "plants"], "hide": 0, "mark": 1},
	{"kind": "kingdoms", "show": ["bacteria"], "names": false},
	{"kind": "taxon_levels"},
	{"kind": "taxon_levels", "example": ["animals", "chordates", "mammals", "carnivores", "dog family", "Canis",
		"Canis lupus"], "mark": 6},
	{"kind": "taxon_levels", "hide": 3, "names": true},
	{"kind": "shadow_rays", "near": 20, "far": 60, "size": 5},
	{"kind": "shadow_rays", "near": 10, "far": 50, "size": 4, "hide": "size"},
	{"kind": "shadow_rays", "near": 30, "far": 45, "size": 8, "hide": "near", "unit": "m"},
	{"kind": "shadow_rays", "near": 25, "far": 100, "size": 6, "hide": "far"},
	{"kind": "shadow_rays", "near": 15, "far": 30, "size": 3, "hide": "none", "numbers": false},
	{"kind": "reflection", "i": 40},
	{"kind": "reflection", "i": 30, "marks": ["i", "r"], "unknown": "r"},
	{"kind": "reflection", "i": 65, "marks": ["mi", "mr"], "unknown": "mr"},
	{"kind": "reflection", "i": 25, "marks": ["both"], "unknown": "both", "names": true},
	{"kind": "reflection", "i": 50, "marks": ["i", "mi"], "values": false, "names": true},
	{"kind": "light_device", "device": "periscope"},
	{"kind": "light_device", "device": "periscope", "names": true},
	{"kind": "light_device", "device": "pinhole"},
	{"kind": "light_device", "device": "pinhole", "names": true, "rays": false},
	{"kind": "energy_chain", "steps": ["chemical", "electrical", "light"], "things": ["battery", "wire", "bulb"],
		"wasted": ["heat"]},
	{"kind": "energy_chain", "steps": ["gravitational", "kinetic", "electrical", "light", "sound"], "hide": 2, "mark": 2},
	{"kind": "energy_chain", "steps": ["elastic", "kinetic"], "wasted": ["heat", "sound"]},
	{"kind": "energy_chain", "steps": ["heat", "chemical"]},
	{"kind": "sankey", "total": 100, "useful": [["light", 10]], "wasted": [["heat", 90]], "name": "a filament bulb"},
	{"kind": "sankey", "total": 500, "useful": [["kinetic", 300]], "wasted": [["heat", 150], ["sound", 50]], "hide": 3},
	{"kind": "sankey", "total": 1000, "useful": [["light", 400], ["sound", 100]], "wasted": [["heat", 500]], "hide": 0},
	{"kind": "op_chain", "start": "?", "ops": ["+ 5", "× 2"], "end": "30"},
	{"kind": "op_chain", "start": "7", "ops": ["× 3", "− 1", "÷ 4", "+ 10"], "end": "?", "back": false},
	{"kind": "op_chain", "start": "?", "ops": ["÷ 2", "+ 12"], "end": "30", "back": true},
	{"kind": "op_chain", "start": "4", "ops": ["× 2.5"], "end": "10"},
	{"kind": "handshakes", "n": 4},
	{"kind": "handshakes", "n": 6, "names": ["Tilly", "Zara", "Bram", "Mimi", "Oli", "Juno"]},
	{"kind": "handshakes", "n": 8, "count": true},
	{"kind": "handshakes", "n": 3, "lines": false},
	{"kind": "argument_map", "claim": "Our school should have a garden.", "reasons": ["It teaches science.",
		"It helps bees."], "evidence": ["Pupils grow and test plants.", "Bees need flowers."],
		"counter": "Gardens take time to look after.", "rebuttal": "A garden club can share the work."},
	{"kind": "argument_map", "claim": "Libraries matter.", "reasons": ["Free books", "Quiet rooms", "Help for all"],
		"titles": false, "mark": "reason"},
	{"kind": "argument_map", "claim": "Walk to school.", "reasons": ["It is exercise."], "counter": "It can rain.",
		"mark": "counterclaim"},
	{"kind": "story_arc"},
	{"kind": "story_arc", "names": false, "mark": "climax"},
	{"kind": "story_arc", "hide": "falling action", "events": ["Kit moves home", "The map is lost", "The storm",
		"The way back", "Home at last"]},
	{"kind": "story_arc", "dots": false, "hide": "exposition"},
	{"kind": "info_page", "title": "Volcanoes", "heading": "How they form", "caption": "Etna erupting",
		"glossary": ["magma", "lava", "crater"]},
	{"kind": "info_page", "title": "Honeybees", "heading": "Life in the hive", "caption": "A worker bee", "names": true},
	{"kind": "info_page", "title": "Owls", "heading": "Hunting at night", "caption": "A barn owl", "mark": "caption"},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126),
	Vector2(520, 250)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_and_its_options_have_a_sample() -> void:
	var seen := {}
	for d in SAMPLES:
		seen[str(d.kind)] = true
		for k: String in ["type", "move", "food", "device"]:
			if d.has(k):
				seen["%s:%s" % [k, d[k]]] = true
		for k: String in ["show", "steps", "marks"]:
			if d.get(k) is Array:
				for v: Variant in d[k]:
					seen["%s:%s" % [k, v]] = true
		for t: Variant in d.get("tubes", []):
			seen["tubes:%s:%s" % [t[0], t[1]]] = true
	for k: String in SchoolPictureG6Core.KINDS:
		assert_true(seen.has(k), "a sample of %s" % k)
	var lists := {"type": SchoolPictureG6Core.JOINTS, "move": SchoolPictureG6Core.MUSCLE_MOVES,
		"food": SchoolPictureG6Core.FOODS, "device": SchoolPictureG6Core.DEVICES, "show": SchoolPictureG6Core.KINGDOMS,
		"marks": SchoolPictureG6Core.MARKS}
	for k: String in lists:
		for v: Variant in lists[k]:
			assert_true(seen.has("%s:%s" % [k, v]), "a sample of %s %s" % [k, v])
	for t: String in ["starch", "sugar", "protein"]:
		for pos: bool in [true, false]:
			assert_true(seen.has("tubes:%s:%s" % [t, pos]), "a %s test %s" % [t, pos])


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


## The rules the pictures draw by, which the lessons teach, worked out again here: iodine turns blue-black with
## starch, Benedict's brick red with sugar, biuret purple with protein; a key names the first yes; a shadow grows as
## far ÷ near; the angle of reflection equals the angle of incidence; n people shake hands n(n − 1) ÷ 2 times; an energy
## flow's useful part over the total is its efficiency; a function machine undone gives its start.
func test_the_pictures_follow_the_rules_they_teach() -> void:
	assert_eq(SchoolPictureG6Core.colour_word("starch", true), "blue-black")
	assert_eq(SchoolPictureG6Core.colour_word("starch", false), "orange-brown")
	assert_eq(SchoolPictureG6Core.colour_word("sugar", true), "brick red")
	assert_eq(SchoolPictureG6Core.colour_word("sugar", false), "blue")
	assert_eq(SchoolPictureG6Core.colour_word("protein", true), "purple")
	assert_eq(SchoolPictureG6Core.colour_word("protein", false), "blue")
	assert_eq(SchoolPictureG6Core.colour_word("fat", true), "a see-through spot")
	assert_eq(SchoolPictureG6Core.ENZYMES, {"starch": "amylase", "protein": "protease", "fat": "lipase"})
	assert_eq(SchoolPictureG6Core.key_end([true]), 0)
	assert_eq(SchoolPictureG6Core.key_end([false, true]), 1)
	assert_eq(SchoolPictureG6Core.key_end([false, false, false]), 3)
	assert_almost_eq(SchoolPictureG6Core.shadow_height(20, 60, 5), 15.0, 0.0001)
	assert_almost_eq(SchoolPictureG6Core.shadow_height(10, 50, 4), 20.0, 0.0001)
	for i in range(10, 81):
		assert_eq(SchoolPictureG6Core.angle_of(i, "r"), SchoolPictureG6Core.angle_of(i, "i"), "r = i")
		assert_eq(SchoolPictureG6Core.angle_of(i, "mi") + i, 90, "the ray and the normal make a right angle with the mirror")
		assert_eq(SchoolPictureG6Core.angle_of(i, "both"), 2 * i)
	for n in range(2, 9):
		var lines := 0
		for a in n:
			for b in range(a + 1, n):
				lines += 1
		assert_eq(SchoolPictureG6Core.handshake_count(n), lines, "%d people" % n)
	assert_almost_eq(SchoolPictureG6Core.efficiency({"kind": "sankey", "total": 100, "useful": [["light", 10]],
		"wasted": [["heat", 90]]}), 10.0, 0.0001)
	assert_almost_eq(SchoolPictureG6Core.efficiency({"kind": "sankey", "total": 1000, "useful": [["light", 400],
		["sound", 100]], "wasted": [["heat", 500]]}), 50.0, 0.0001)
	assert_almost_eq(SchoolPictureG6Core.undo(30, ["+ 5", "× 2"]), 10.0, 0.0001)
	assert_almost_eq(SchoolPictureG6Core.run(10, ["+ 5", "× 2"]), 30.0, 0.0001)
	assert_almost_eq(SchoolPictureG6Core.run(7, ["× 3", "− 1", "÷ 4", "+ 10"]), 15.0, 0.0001)
	assert_almost_eq(SchoolPictureG6Core.undo(30, ["÷ 2", "+ 12"]), 36.0, 0.0001)
	assert_eq(SchoolPictureG6Core.inverse_op("× 3"), "÷ 3")
	assert_eq(SchoolPictureG6Core.inverse_op("− 1.5"), "+ 1.5")


## The label exercises' parts are where the pictures draw them (part_at), and a part the picture has not is (-1, -1).
func test_parts_are_found() -> void:
	var box := Vector2(520, 250)
	var inside := Rect2(Vector2.ZERO, box)
	var sk := {"kind": "skeleton"}
	var skull := SchoolPictureG6Core.part_at(sk, "skull", box)
	var femur := SchoolPictureG6Core.part_at(sk, "femur", box)
	var tibia := SchoolPictureG6Core.part_at(sk, "tibia and fibula", box)
	assert_lt(skull.y, femur.y, "the skull above the femur")
	assert_lt(femur.y, tibia.y, "the femur above the shin")
	for b: String in SchoolPictureG6Core.BONES:
		assert_true(inside.has_point(SchoolPictureG6Core.part_at(sk, str(SchoolPictureG6Core.BONE_NAMES[b]), box)), b)
	assert_eq(SchoolPictureG6Core.part_at(sk, "kneecap", box), Vector2(-1, -1))
	var arm := {"kind": "muscle_pair", "move": "bend"}
	var bi := SchoolPictureG6Core.part_at(arm, "biceps", box)
	var tri := SchoolPictureG6Core.part_at(arm, "triceps", box)
	assert_lt(bi.y, tri.y, "the biceps on top, the triceps underneath")
	for part: String in ["biceps", "triceps", "tendon", "elbow joint", "humerus"]:
		assert_true(inside.has_point(SchoolPictureG6Core.part_at(arm, part, box)), part)
	var ray := {"kind": "reflection", "i": 40}
	assert_lt(SchoolPictureG6Core.part_at(ray, "incident ray", box).x, SchoolPictureG6Core.part_at(ray, "reflected ray",
		box).x)
	assert_gt(SchoolPictureG6Core.part_at(ray, "mirror", box).y, SchoolPictureG6Core.part_at(ray, "normal", box).y)
	var per := {"kind": "light_device", "device": "periscope"}
	assert_lt(SchoolPictureG6Core.part_at(per, "top mirror", box).y, SchoolPictureG6Core.part_at(per, "bottom mirror",
		box).y)
	assert_eq(SchoolPictureG6Core.part_at(per, "pinhole", box), Vector2(-1, -1))
	var pin := {"kind": "light_device", "device": "pinhole"}
	assert_lt(SchoolPictureG6Core.part_at(pin, "object", box).x, SchoolPictureG6Core.part_at(pin, "pinhole", box).x)
	assert_lt(SchoolPictureG6Core.part_at(pin, "pinhole", box).x, SchoolPictureG6Core.part_at(pin, "screen", box).x)
	var arg := {"kind": "argument_map", "claim": "Walk to school.", "reasons": ["Exercise", "Fresh air"],
		"evidence": ["Doctors say so", "Fewer cars"], "counter": "It can rain.", "rebuttal": "Wear a coat."}
	assert_lt(SchoolPictureG6Core.part_at(arg, "claim", box).y, SchoolPictureG6Core.part_at(arg, "reason", box).y)
	assert_lt(SchoolPictureG6Core.part_at(arg, "reason", box).y, SchoolPictureG6Core.part_at(arg, "evidence", box).y)
	assert_lt(SchoolPictureG6Core.part_at(arg, "counterclaim", box).x, SchoolPictureG6Core.part_at(arg, "rebuttal", box).x)
	assert_eq(SchoolPictureG6Core.part_at({"kind": "argument_map",
		"claim": "Libraries matter.", "reasons": ["Free books"]}, "evidence", box), Vector2(-1, -1), "no evidence boxes")
	var arc := {"kind": "story_arc"}
	var climax := SchoolPictureG6Core.part_at(arc, "climax", box)
	for s: String in SchoolPictureG6Core.STAGES:
		var at := SchoolPictureG6Core.part_at(arc, s, box)
		assert_true(inside.has_point(at), s)
		assert_true(at.y >= climax.y, "the climax is the highest point: %s" % s)
	var page := {"kind": "info_page", "title": "Owls", "heading": "Hunting", "caption": "A barn owl"}
	assert_lt(SchoolPictureG6Core.part_at(page, "title", box).y, SchoolPictureG6Core.part_at(page, "subheading", box).y)
	assert_lt(SchoolPictureG6Core.part_at(page, "diagram", box).y, SchoolPictureG6Core.part_at(page, "caption", box).y)
	assert_lt(SchoolPictureG6Core.part_at(page, "caption", box).y, SchoolPictureG6Core.part_at(page, "glossary", box).y)


func test_broken_pictures_are_problems() -> void:
	for d: Dictionary in [
			{"kind": "skeleton", "mark": "kneecap"}, {"kind": "skeleton", "hide": "skull"},
			{"kind": "skeleton", "labels": "yes"},
			{"kind": "joint"}, {"kind": "joint", "type": "saddle"}, {"kind": "joint", "type": "pivot", "labels": true},
			{"kind": "muscle_pair"}, {"kind": "muscle_pair", "move": "wave"},
			{"kind": "muscle_pair", "move": "bend", "hide": "biceps"},
			{"kind": "muscle_pair", "move": "bend", "mark": "heart"},
			{"kind": "food_test"}, {"kind": "food_test", "tubes": []},
			{"kind": "food_test", "tubes": [["vitamin", true]]}, {"kind": "food_test", "tubes": [["starch", "yes"]]},
			{"kind": "food_test", "tubes": [["starch", true, "a very long tag"]]},
			{"kind": "food_test", "tubes": [["starch", true], ["starch", true], ["fat", true], ["fat", false],
				["sugar", true]]},
			{"kind": "enzyme_cut"}, {"kind": "enzyme_cut", "food": "fibre"},
			{"kind": "enzyme_cut", "food": "fat", "hide": "all"},
			{"kind": "key_tree"}, {"kind": "key_tree", "questions": ["Legs?"], "ends": ["a"]},
			{"kind": "key_tree", "questions": ["a", "b", "c", "d", "e"], "ends": ["1", "2", "3", "4", "5", "6"]},
			{"kind": "key_tree", "questions": ["Does it have a very long and winding tail?"], "ends": ["a", "b"]},
			{"kind": "key_tree", "questions": ["Legs?"], "ends": ["a", "b"], "path": [true, false]},
			{"kind": "key_tree", "questions": ["Legs?"], "ends": ["a", "b"], "hide": 2},
			{"kind": "kingdoms"}, {"kind": "kingdoms", "show": ["viruses"]},
			{"kind": "kingdoms", "show": ["fungi", "fungi"]}, {"kind": "kingdoms", "show": ["fungi"], "mark": 1},
			{"kind": "taxon_levels", "example": ["a", "b"]}, {"kind": "taxon_levels", "mark": 7},
			{"kind": "shadow_rays"}, {"kind": "shadow_rays", "near": 20, "far": 10, "size": 5},
			{"kind": "shadow_rays", "near": 10, "far": 70, "size": 5},
			{"kind": "shadow_rays", "near": 10, "far": 20, "size": 0},
			{"kind": "shadow_rays", "near": 10, "far": 20, "size": 5, "hide": "lamp"},
			{"kind": "reflection"}, {"kind": "reflection", "i": 5}, {"kind": "reflection", "i": 85},
			{"kind": "reflection", "i": 40.5}, {"kind": "reflection", "i": 40, "marks": ["x"]},
			{"kind": "reflection", "i": 40, "unknown": "mi"},
			{"kind": "light_device"}, {"kind": "light_device", "device": "telescope"},
			{"kind": "energy_chain"}, {"kind": "energy_chain", "steps": ["heat"]},
			{"kind": "energy_chain", "steps": ["heat", "magic"]},
			{"kind": "energy_chain", "steps": ["heat", "light"], "things": ["a"]},
			{"kind": "energy_chain", "steps": ["heat", "light"], "hide": 2},
			{"kind": "energy_chain", "steps": ["heat", "light"], "wasted": ["heat", "sound", "light"]},
			{"kind": "sankey"}, {"kind": "sankey", "total": 100, "useful": [["light", 10]], "wasted": [["heat", 80]]},
			{"kind": "sankey", "total": 100, "useful": [], "wasted": [["heat", 100]]},
			{"kind": "sankey", "total": 100, "useful": [["light", 10]], "wasted": [["heat", 90]], "hide": 3},
			{"kind": "sankey", "total": 100, "useful": [["light", 10]], "wasted": [["heat", 45], ["sound", 40],
				["kinetic", 5]]},
			{"kind": "op_chain"}, {"kind": "op_chain", "start": "?", "ops": [], "end": "3"},
			{"kind": "op_chain", "start": "?", "ops": ["plus 5"], "end": "3"},
			{"kind": "op_chain", "start": "?", "ops": ["÷ 0"], "end": "3"},
			{"kind": "op_chain", "start": "2", "ops": ["+ 5"], "end": "8"},
			{"kind": "op_chain", "start": "two", "ops": ["+ 5"], "end": "?"},
			{"kind": "handshakes"}, {"kind": "handshakes", "n": 1}, {"kind": "handshakes", "n": 9},
			{"kind": "handshakes", "n": 3, "names": ["a", "b"]},
			{"kind": "argument_map"}, {"kind": "argument_map", "claim": "x", "reasons": []},
			{"kind": "argument_map", "claim": "x", "reasons": ["a"], "evidence": ["1", "2"]},
			{"kind": "argument_map", "claim": "x", "reasons": ["a"], "rebuttal": "y"},
			{"kind": "argument_map", "claim": "x", "reasons": ["a"], "mark": "title"},
			{"kind": "story_arc", "mark": "prologue"}, {"kind": "story_arc", "events": ["a", "b"]},
			{"kind": "info_page"}, {"kind": "info_page", "title": "A", "heading": "B", "caption": ""},
			{"kind": "info_page", "title": "A", "heading": "B", "caption": "C", "mark": "index"},
			{"kind": "info_page", "title": "A", "heading": "B", "caption": "C", "glossary": []}]:
		assert_ne(SchoolPicture.problem(d), "", "broken: %s" % d)
