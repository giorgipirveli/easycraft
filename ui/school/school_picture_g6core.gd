class_name SchoolPictureG6Core
extends RefCounted
## Grade 6 maths, science and English: the research's last units (owner #70, #73; research §6.6): the picture kinds they
## add, drawn from data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only,
## no new art; the font has no arrows, so they are drawn). Kinds and fields:
## - skeleton {labels? (true: every bone named with a line to it), mark? (BONES, orange), hide? (BONES: its name "?",
##   with labels)}: a person's skeleton from the front: skull, ribs, spine, pelvis, humerus, radius and ulna, femur,
##   tibia and fibula (part_at).
## - joint {type: JOINTS ("hinge", "ball_socket", "pivot", "fixed"), name? (true: the joint's name under it), move?
##   (true: arrows for the way it moves; a fixed joint has none), labels? (a hinge or a ball and socket: bone,
##   cartilage and ligament named)}.
## - muscle_pair {move: "bend" | "straighten", labels? (biceps, triceps, tendon, elbow joint and humerus named), states?
##   (the words "contracts" and "relaxes" by the muscles), mark? (MUSCLE_PARTS, orange), hide? (MUSCLE_PARTS: its name
##   "?", with labels)}: an upper arm from the side: the contracting muscle short and fat, the relaxing one long and thin
##   (contracting), its tendons pulling on the bones (part_at).
## - food_test {tubes: [[TESTS, positive (bool), tag? (1-10 letters)]] (1-4), names? (true: the test's reagent under
##   each)}: food tests: iodine orange-brown, blue-black with starch; Benedict's blue, brick red with sugar (heated);
##   biuret blue, purple with protein; paper rubbed with food: a see-through spot with fat (colour_word).
## - enzyme_cut {food: FOODS ("starch", "protein", "fat"), names? (true), hide? ("food" | "enzyme" | "products": that
##   name "?")}: an enzyme cutting a big food molecule into small ones: amylase starch into sugars, protease protein
##   into amino acids, lipase fat into fatty acids and glycerol (ENZYMES, PRODUCTS).
## - key_tree {questions: [text] (1-4, 30 letters), ends: [text] (one more than the questions, 14 letters), path?:
##   [bool] (the answers followed, drawn orange; it stops at the first yes), hide? (an end's index: "?")}: a key that
##   asks yes-or-no questions one after another: yes names a living thing, no goes on (key_end).
## - kingdoms {show: [KINGDOMS] (1-5, each once), names? (true), mark? (an index), hide? (an index: its name "?")}: the
##   five kingdoms drawn: animals, plants, fungi, protists, bacteria.
## - taxon_levels {example?: [text] (7, 16 letters: the names at each level), names? (true: the levels' words), mark?
##   (an index 0-6), hide? (an index: its word "?")}: kingdom, phylum, class, order, family, genus, species, narrowing.
## - shadow_rays {near (lamp to card, 1-500), far (lamp to screen: more than near, at most 6 × near), size (the card's
##   height, 1-100), hide? ("shadow" (the default) | "size" | "near" | "far" | "none": that number "?"), numbers? (true),
##   unit? (4 letters, "cm")}: a lamp, a card and a screen from the side; two straight rays past the card's edges make
##   the shadow (shadow_height: size × far ÷ near).
## - reflection {i (10-80 whole degrees: the angle of incidence), marks?: [MARKS] ("i", "r": from the normal; "mi", "mr":
##   from the mirror; "both": between the rays; the default ["i", "r"]), values? (true: the marked angles in degrees),
##   unknown? (a mark: "?"), names? (mirror, normal, incident ray and reflected ray named)}: a ray reflected by a flat
##   mirror (angle_of: r = i; to the mirror 90° − i; between the rays 2i) (part_at).
## - light_device {device: DEVICES ("periscope", "pinhole"), names? (the parts named), rays? (true)}: a periscope (two
##   mirrors at 45°) or a pinhole camera (the image upside down), with the light's straight path (part_at).
## - energy_chain {steps: [FORMS] (2-5), things?: [text] (one under each box, 12 letters), hide? (an index: "?"), mark?
##   (an index), wasted?: [FORMS] (1-2: thin grey arrows from the last box)}: energy changing from form to form.
## - sankey {total (1-100,000), useful: [[name (12 letters), amount]] (1-2), wasted: [[name, amount]] (1-2), hide? (a
##   value's index: 0 the total, then the useful ones, then the wasted: "?"), name? (the device, 20 letters), unit? ("J")}:
##   an energy flow whose bands are as wide as the energy; useful goes on, wasted bends down; the parts add up to the
##   total (efficiency).
## - op_chain {start (8 letters: a number or "?"), ops: [text] (1-4: "+ 5", "− 3", "× 2", "÷ 4"), end (a number or "?"),
##   back? (a second row: the steps undone, right to left)}: a function machine; with both ends numbers, running the
##   start through the steps gives the end (run, undo).
## - handshakes {n (2-8), lines? (true: every pair joined), names?: [text] (n, 6 letters), count? (the number of lines
##   written)}: people in a ring, a line for each handshake (handshake_count: n(n − 1) ÷ 2).
## - argument_map {claim (44 letters), reasons: [text] (1-3, 30), evidence?: [text] (one a reason, 30), counter? (44),
##   rebuttal? (44, with a counter), titles? (true: CLAIM, REASON, …), mark? (ARG_PARTS, orange)}: an argument's plan in
##   boxes (part_at).
## - story_arc {names? (true: the stages), mark? (STAGES), hide? (STAGES: "?"), events?: [text] (5, 18 letters: what
##   happens at each stage), dots? (true)}: a story's tension over time: exposition, rising action, climax, falling
##   action, resolution (part_at).
## - info_page {title (20 letters), heading (22), caption (26), glossary?: [text] (1-3, 12), names? (the features named
##   beside the page), mark? (PAGE_PARTS, orange)}: an information text's page: title, introduction, subheading,
##   diagram, caption and glossary (part_at).

const KINDS: Array[String] = ["skeleton", "joint", "muscle_pair", "food_test", "enzyme_cut", "key_tree", "kingdoms",
	"taxon_levels", "shadow_rays", "reflection", "light_device", "energy_chain", "sankey", "op_chain", "handshakes",
	"argument_map", "story_arc", "info_page"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const GREEN := Color("3fa34d")
const GREY := Color("9aa1ad")
const BONE := Color("f3ead3")
const BONE_EDGE := Color("9c8a63")
const MUSCLE := Color("c9473d")
const MUSCLE_SOFT := Color("e59c90")
const TENDON := Color("d8c9a3")
const CARTILAGE := Color("9fd0e6")
const LIGAMENT := Color("c49a2e")
const YELLOW := Color("f2c230")

const BONES: Array[String] = ["skull", "ribs", "spine", "pelvis", "humerus", "radius_ulna", "femur", "tibia_fibula"]
const BONE_NAMES := {"skull": "skull", "ribs": "ribs", "spine": "spine", "pelvis": "pelvis", "humerus": "humerus",
	"radius_ulna": "radius and ulna", "femur": "femur", "tibia_fibula": "tibia and fibula"}
## Where each bone's label line ends, in the skeleton's units (x from the middle, y down from the top of 100), and
## which side its label is on.
const BONE_AT := {"skull": [-5.0, 6.0, -1], "humerus": [-15.2, 29.0, -1], "radius_ulna": [-18.6, 48.0, -1],
	"femur": [-6.0, 71.0, -1], "ribs": [9.6, 27.0, 1], "spine": [0.9, 45.0, 1], "pelvis": [9.0, 57.0, 1],
	"tibia_fibula": [7.0, 89.0, 1]}
const JOINTS: Array[String] = ["hinge", "ball_socket", "pivot", "fixed"]
const JOINT_NAMES := {"hinge": "hinge joint", "ball_socket": "ball and socket joint", "pivot": "pivot joint",
	"fixed": "fixed joint"}
const MUSCLE_MOVES: Array[String] = ["bend", "straighten"]
const MUSCLE_PARTS: Array[String] = ["biceps", "triceps", "tendon", "joint", "bone"]
const MUSCLE_NAMES := {"biceps": "biceps", "triceps": "triceps", "tendon": "tendon", "joint": "elbow joint",
	"bone": "humerus"}
const TESTS: Array[String] = ["starch", "sugar", "protein", "fat"]
const REAGENTS := {"starch": "iodine", "sugar": "Benedict's", "protein": "biuret", "fat": "paper"}
const TEST_COLOURS := {"starch": [Color("c47a2c"), Color("1c2140")], "sugar": [Color("3f7fd9"), Color("b0442a")],
	"protein": [Color("5a8ee0"), Color("7c45a8")]}
const MAX_TAG := 10
const FOODS: Array[String] = ["starch", "protein", "fat"]
const ENZYMES := {"starch": "amylase", "protein": "protease", "fat": "lipase"}
const PRODUCTS := {"starch": "sugars", "protein": "amino acids", "fat": "fatty acids and glycerol"}
const ENZYME_HIDES: Array[String] = ["food", "enzyme", "products"]
const MAX_QUESTION := 30
const MAX_END := 14
const KINGDOMS: Array[String] = ["animals", "plants", "fungi", "protists", "bacteria"]
const LEVELS: Array[String] = ["kingdom", "phylum", "class", "order", "family", "genus", "species"]
const MAX_EXAMPLE := 16
const SHADOW_HIDES: Array[String] = ["shadow", "size", "near", "far", "none"]
const MARKS: Array[String] = ["i", "r", "mi", "mr", "both"]
const RAY_PARTS: Array[String] = ["mirror", "normal", "incident ray", "reflected ray"]
const DEVICES: Array[String] = ["periscope", "pinhole"]
const DEVICE_PARTS := {"periscope": ["top mirror", "bottom mirror", "eye", "object"],
	"pinhole": ["pinhole", "screen", "object", "image"]}
const FORMS: Array[String] = ["chemical", "electrical", "kinetic", "light", "sound", "heat", "gravitational", "elastic"]
const FORM_COLOURS := {"chemical": Color("8fcf7a"), "electrical": Color("f5d547"), "kinetic": Color("7fb3f0"),
	"light": Color("fff0a0"), "sound": Color("c9b3f2"), "heat": Color("f5a36b"), "gravitational": Color("b8c4d6"),
	"elastic": Color("f2a6c8")}
const MAX_THING := 12
const MAX_FLOW_NAME := 12
const OP_SIGNS := ["+", "−", "×", "÷"]
const MAX_OP_VALUE := 8
const MAX_NAME := 6
const ARG_PARTS: Array[String] = ["claim", "reason", "evidence", "counterclaim", "rebuttal"]
const MAX_CLAIM := 44
const MAX_REASON := 30
const STAGES: Array[String] = ["exposition", "rising action", "climax", "falling action", "resolution"]
## The stages' places on the arc: [x, tension], each 0-1.
const STAGE_AT := [[0.08, 0.12], [0.29, 0.5], [0.5, 0.94], [0.71, 0.54], [0.92, 0.24]]
const MAX_EVENT := 18
const PAGE_PARTS: Array[String] = ["title", "introduction", "subheading", "diagram", "caption", "glossary"]

# --- The rules the pictures draw by (the lessons teach them; tests check them) --------------------------------------

## A food test's colour: iodine blue-black with starch (orange-brown without), Benedict's brick red with sugar (blue
## without), biuret purple with protein (blue without), paper a see-through spot with fat.
static func colour_word(test: String, positive: bool) -> String:
	match test:
		"starch":
			return "blue-black" if positive else "orange-brown"
		"sugar":
			return "brick red" if positive else "blue"
		"protein":
			return "purple" if positive else "blue"
		"fat":
			return "a see-through spot" if positive else "no spot"
	return ""


## Where a key sends you: the first question answered yes names that end; all no, the last end.
static func key_end(answers: Array) -> int:
	for i in answers.size():
		if bool(answers[i]):
			return i
	return answers.size()


## A shadow's height on the screen: the rays spread in straight lines from the lamp, so the shadow is as many times
## taller than the card as the screen is farther from the lamp than the card.
static func shadow_height(near: float, far: float, size: float) -> float:
	return size * far / near


## A mark's angle for a ray whose angle of incidence is `i`: "i" and "r" (the angle of reflection equals it), "mi" and
## "mr" (to the mirror: 90° − i), "both" (between the two rays: 2i).
static func angle_of(i: int, mark: String) -> int:
	match mark:
		"i", "r":
			return i
		"mi", "mr":
			return 90 - i
	return 2 * i


## How many handshakes when each of `n` people shakes hands with each other person once.
static func handshake_count(n: int) -> int:
	return n * (n - 1) / 2


## A sankey's useful energy as a percentage of the total.
static func efficiency(p: Dictionary) -> float:
	var useful := 0.0
	for u: Variant in p.get("useful", []):
		useful += float(u[1])
	return useful * 100.0 / float(p.get("total", 1))


## A function machine's step ("+ 5") as [sign, value]; [] when it is not one.
static func op_parts(op: String) -> Array:
	var t := op.strip_edges()
	if t.length() < 3 or not OP_SIGNS.has(t.substr(0, 1)) or t.substr(1, 1) != " ":
		return []
	var v := t.substr(2)
	if not v.is_valid_float() or v.length() > MAX_OP_VALUE or float(v) < 0:
		return []
	if t.substr(0, 1) == "÷" and float(v) == 0.0:
		return []
	return [t.substr(0, 1), float(v)]


## A step undone: + with −, × with ÷ ("+ 5" -> "− 5").
static func inverse_op(op: String) -> String:
	var parts := op_parts(op)
	if parts.is_empty():
		return ""
	var back := {"+": "−", "−": "+", "×": "÷", "÷": "×"}
	return "%s %s" % [back[parts[0]], op.strip_edges().substr(2)]


## `x` run through the steps, first to last.
static func run(x: float, ops: Array) -> float:
	for o: Variant in ops:
		var parts := op_parts(str(o))
		var n: float = parts[1]
		match str(parts[0]):
			"+":
				x += n
			"−":
				x -= n
			"×":
				x *= n
			"÷":
				x /= n
	return x


## The start that gives `end`: the steps undone, last first.
static func undo(end: float, ops: Array) -> float:
	var back: Array = []
	for i in range(ops.size() - 1, -1, -1):
		back.append(inverse_op(str(ops[i])))
	return run(end, back)


## Where a label's part is drawn on a picture of `size` (for label exercises): a skeleton's bones by name, a muscle
## pair's parts, a reflection's mirror, normal and rays, a periscope's or a pinhole camera's parts, an argument map's
## boxes (the middle of the box's outer side), a story arc's stages and an information page's features (the middle of
## their outer side); (-1, -1) when the picture has no such part.
static func part_at(p: Dictionary, label: String, size: Vector2) -> Vector2:
	var r := _rect(size)
	var none := Vector2(-1, -1)
	match str(p.get("kind", "")):
		"skeleton":
			var g := _skeleton_geo(r, bool(p.get("labels", false)))
			for b: String in BONES:
				if label == str(BONE_NAMES[b]) or label == b:
					var at: Array = BONE_AT[b]
					return _sk(g, float(at[0]), float(at[1]))
		"muscle_pair":
			var g := _muscle_geo(r, str(p.get("move", "bend")), bool(p.get("labels", false)))
			for part: String in MUSCLE_PARTS:
				if label == part or label == str(MUSCLE_NAMES[part]):
					return g[part]
		"reflection":
			var g := _reflection_geo(r, int(p.get("i", 40)), bool(p.get("names", false)))
			match label:
				"mirror":
					return (g.p as Vector2) + Vector2(g.len * 0.75, 0)
				"normal":
					return (g.p as Vector2) + Vector2(0, -g.len * 0.8)
				"incident ray":
					return (g.p as Vector2).lerp(g.a, 0.55)
				"reflected ray":
					return (g.p as Vector2).lerp(g.b, 0.55)
		"light_device":
			var device := str(p.get("device", ""))
			if DEVICE_PARTS.has(device) and (DEVICE_PARTS[device] as Array).has(label):
				var g := _device_geo(r, device)
				return g[label]
		"argument_map":   # the middle of a box's outer side, so a label's line never crosses its words
			var boxes := _argument_boxes(p, r)
			if boxes.has(label):
				var box: Rect2 = boxes[label]
				return Vector2(box.end.x if label == "rebuttal" else box.position.x, box.get_center().y)
		"story_arc":
			var i := STAGES.find(label)
			if i >= 0:
				return _arc_points(r)[i]
		"info_page":   # the middle of a feature's outer side (the diagram and caption on the right), clear of its words
			var boxes := _page_boxes(r, bool(p.get("names", false)))
			if PAGE_PARTS.has(label):
				var box: Rect2 = boxes[label]
				return Vector2(box.end.x if label in ["diagram", "caption"] else box.position.x, box.get_center().y)
	return none


# --- Checks ------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"skeleton":
			for k: String in ["mark", "hide"]:
				if p.has(k) and not BONES.has(str(p[k])):
					return "%s is one of %s" % [k, BONES]
			if p.has("hide") and not bool(p.get("labels", false)):
				return "hide needs labels"
			return _bool_problem(p, ["labels"])
		"joint":
			if not JOINTS.has(str(p.get("type", ""))):
				return "a joint's type is one of %s" % [JOINTS]
			if bool(p.get("labels", false)) and not ["hinge", "ball_socket"].has(str(p.type)):
				return "labels: a hinge or a ball and socket joint"
			return _bool_problem(p, ["name", "move", "labels"])
		"muscle_pair":
			if not MUSCLE_MOVES.has(str(p.get("move", ""))):
				return "move is bend or straighten"
			for k: String in ["mark", "hide"]:
				if p.has(k) and not MUSCLE_PARTS.has(str(p[k])):
					return "%s is one of %s" % [k, MUSCLE_PARTS]
			if p.has("hide") and not bool(p.get("labels", false)):
				return "hide needs labels"
			return _bool_problem(p, ["labels", "states"])
		"food_test":
			var tubes: Variant = p.get("tubes")
			if not tubes is Array or (tubes as Array).is_empty() or (tubes as Array).size() > 4:
				return "1-4 tubes"
			for t: Variant in tubes:
				if not t is Array or not (t as Array).size() in [2, 3] or not TESTS.has(str(t[0])) or not t[1] is bool:
					return "a tube is [test (%s), positive (true or false), tag?]" % [TESTS]
				if (t as Array).size() == 3 and (str(t[2]).length() < 1 or str(t[2]).length() > MAX_TAG):
					return "a tag is 1-%d letters" % MAX_TAG
			return _bool_problem(p, ["names"])
		"enzyme_cut":
			if not FOODS.has(str(p.get("food", ""))):
				return "food is one of %s" % [FOODS]
			if p.has("hide") and not ENZYME_HIDES.has(str(p.hide)):
				return "hide is one of %s" % [ENZYME_HIDES]
			return _bool_problem(p, ["names"])
		"key_tree":
			var qs: Variant = p.get("questions")
			var ends: Variant = p.get("ends")
			if not qs is Array or (qs as Array).is_empty() or (qs as Array).size() > 4:
				return "1-4 questions"
			if not ends is Array or (ends as Array).size() != (qs as Array).size() + 1:
				return "one more end than questions"
			for q: Variant in qs:
				if str(q).length() < 1 or str(q).length() > MAX_QUESTION:
					return "a question is 1-%d letters" % MAX_QUESTION
			for e: Variant in ends:
				if str(e).length() < 1 or str(e).length() > MAX_END:
					return "an end is 1-%d letters" % MAX_END
			if p.has("path"):
				var path: Variant = p.path
				if not path is Array or (path as Array).is_empty() or (path as Array).size() > (qs as Array).size():
					return "a path is 1-%d answers" % (qs as Array).size()
				for a: Variant in path:
					if not a is bool:
						return "a path's answers are true or false"
			if p.has("hide") and (not _whole(p.hide) or int(p.hide) < 0 or int(p.hide) >= (ends as Array).size()):
				return "hide is an end's index"
			return ""
		"kingdoms":
			return _list_problem(p, "show", KINGDOMS, 5, ["names"])
		"taxon_levels":
			if p.has("example"):
				var ex: Variant = p.example
				if not ex is Array or (ex as Array).size() != LEVELS.size():
					return "an example names all %d levels" % LEVELS.size()
				for e: Variant in ex:
					if str(e).length() < 1 or str(e).length() > MAX_EXAMPLE:
						return "an example's name is 1-%d letters" % MAX_EXAMPLE
			return _index_problem(p, LEVELS.size(), ["names"])
		"shadow_rays":
			for k: String in ["near", "far", "size"]:
				if not _number(p.get(k)) or float(p[k]) <= 0:
					return "%s is a length above 0" % k
			if float(p.near) > 500 or float(p.size) > 100:
				return "near at most 500, size at most 100"
			if float(p.far) <= float(p.near) or float(p.far) > 6 * float(p.near):
				return "the screen is farther than the card, at most 6 times as far"
			if p.has("hide") and not SHADOW_HIDES.has(str(p.hide)):
				return "hide is one of %s" % [SHADOW_HIDES]
			if p.has("unit") and (str(p.unit).length() < 1 or str(p.unit).length() > 4):
				return "a unit is 1-4 letters"
			return _bool_problem(p, ["numbers"])
		"reflection":
			if not _whole(p.get("i")) or int(p.i) < 10 or int(p.i) > 80:
				return "i is 10-80 whole degrees"
			if p.has("marks"):
				if not p.marks is Array or (p.marks as Array).is_empty():
					return "marks is a list of %s" % [MARKS]
				for m: Variant in p.marks:
					if not MARKS.has(str(m)):
						return "a mark is one of %s" % [MARKS]
			if p.has("unknown"):
				var marks: Array = p.get("marks", ["i", "r"])
				if not marks.has(str(p.unknown)):
					return "the unknown is one of the marks"
			return _bool_problem(p, ["values", "names"])
		"light_device":
			if not DEVICES.has(str(p.get("device", ""))):
				return "a device is one of %s" % [DEVICES]
			return _bool_problem(p, ["names", "rays"])
		"energy_chain":
			var steps: Variant = p.get("steps")
			if not steps is Array or (steps as Array).size() < 2 or (steps as Array).size() > 5:
				return "2-5 steps"
			for s: Variant in steps:
				if not FORMS.has(str(s)):
					return "a step is one of %s" % [FORMS]
			if p.has("things"):
				var things: Variant = p.things
				if not things is Array or (things as Array).size() != (steps as Array).size():
					return "a thing under each step"
				for t: Variant in things:
					if str(t).length() > MAX_THING:
						return "a thing is at most %d letters" % MAX_THING
			if p.has("wasted"):
				var wasted: Variant = p.wasted
				if not wasted is Array or (wasted as Array).is_empty() or (wasted as Array).size() > 2:
					return "1-2 wasted forms"
				for w: Variant in wasted:
					if not FORMS.has(str(w)):
						return "a wasted form is one of %s" % [FORMS]
			return _index_problem(p, (steps as Array).size(), [])
		"sankey":
			if not _number(p.get("total")) or float(p.total) <= 0 or float(p.total) > 100000:
				return "a total of 1-100,000"
			var sum := 0.0
			var n := 1
			for key: String in ["useful", "wasted"]:
				var flows: Variant = p.get(key)
				var most := 2
				if not flows is Array or (flows as Array).is_empty() or (flows as Array).size() > most:
					return "%s: 1-%d flows" % [key, most]
				for f: Variant in flows:
					if not f is Array or (f as Array).size() != 2 or not _number(f[1]) or float(f[1]) <= 0:
						return "a flow is [name, amount above 0]"
					if str(f[0]).length() < 1 or str(f[0]).length() > MAX_FLOW_NAME:
						return "a flow's name is 1-%d letters" % MAX_FLOW_NAME
					sum += float(f[1])
					n += 1
			if absf(sum - float(p.total)) > 0.0001:
				return "the useful and wasted energy add up to the total (energy is never made or destroyed)"
			if p.has("name") and (str(p.name).length() < 1 or str(p.name).length() > 20):
				return "a name is 1-20 letters"
			if p.has("unit") and (str(p.unit).length() < 1 or str(p.unit).length() > 3):
				return "a unit is 1-3 letters"
			if p.has("hide") and (not _whole(p.hide) or int(p.hide) < 0 or int(p.hide) >= n):
				return "hide is a value's index 0-%d" % (n - 1)
			return ""
		"op_chain":
			var ops: Variant = p.get("ops")
			if not ops is Array or (ops as Array).is_empty() or (ops as Array).size() > 4:
				return "1-4 steps"
			for o: Variant in ops:
				if op_parts(str(o)).is_empty():
					return "a step is a sign and a number: + 5, − 3, × 2, ÷ 4"
			for k: String in ["start", "end"]:
				var v := str(p.get(k, ""))
				if v != "?" and not v.is_valid_float():
					return "%s is a number or ?" % k
				if v.length() > 8:
					return "%s is at most 8 letters" % k
			if str(p.start) != "?" and str(p.end) != "?" \
					and absf(run(float(str(p.start)), ops) - float(str(p.end))) > 0.000001:
				return "the steps take the start to the end"
			return _bool_problem(p, ["back"])
		"handshakes":
			if not _whole(p.get("n")) or int(p.n) < 2 or int(p.n) > 8:
				return "n is 2-8 people"
			if p.has("names"):
				var names: Variant = p.names
				if not names is Array or (names as Array).size() != int(p.n):
					return "a name for each person"
				for nm: Variant in names:
					if str(nm).length() < 1 or str(nm).length() > MAX_NAME:
						return "a name is 1-%d letters" % MAX_NAME
			return _bool_problem(p, ["lines", "count"])
		"argument_map":
			if str(p.get("claim", "")).length() < 1 or str(p.get("claim", "")).length() > MAX_CLAIM:
				return "a claim is 1-%d letters" % MAX_CLAIM
			var reasons: Variant = p.get("reasons")
			if not reasons is Array or (reasons as Array).is_empty() or (reasons as Array).size() > 3:
				return "1-3 reasons"
			for t: Variant in reasons:
				if str(t).length() < 1 or str(t).length() > MAX_REASON:
					return "a reason is 1-%d letters" % MAX_REASON
			if p.has("evidence"):
				var ev: Variant = p.evidence
				if not ev is Array or (ev as Array).size() != (reasons as Array).size():
					return "evidence for each reason"
				for t: Variant in ev:
					if str(t).length() < 1 or str(t).length() > MAX_REASON:
						return "evidence is 1-%d letters" % MAX_REASON
			for k: String in ["counter", "rebuttal"]:
				if p.has(k) and (str(p[k]).length() < 1 or str(p[k]).length() > MAX_CLAIM):
					return "a %s is 1-%d letters" % [k, MAX_CLAIM]
			if p.has("rebuttal") and not p.has("counter"):
				return "a rebuttal answers a counterclaim"
			if p.has("mark") and not ARG_PARTS.has(str(p.mark)):
				return "mark is one of %s" % [ARG_PARTS]
			return _bool_problem(p, ["titles"])
		"story_arc":
			for k: String in ["mark", "hide"]:
				if p.has(k) and not STAGES.has(str(p[k])):
					return "%s is one of %s" % [k, STAGES]
			if p.has("events"):
				var ev: Variant = p.events
				if not ev is Array or (ev as Array).size() != STAGES.size():
					return "an event for each of the %d stages" % STAGES.size()
				for t: Variant in ev:
					if str(t).length() > MAX_EVENT:
						return "an event is at most %d letters" % MAX_EVENT
			return _bool_problem(p, ["names", "dots"])
		"info_page":
			for k: Array in [["title", 20], ["heading", 22], ["caption", 26]]:
				var n := str(p.get(k[0], "")).length()
				if n < 1 or n > int(k[1]):
					return "a %s is 1-%d letters" % [k[0], k[1]]
			if p.has("glossary"):
				var words: Variant = p.glossary
				if not words is Array or (words as Array).is_empty() or (words as Array).size() > 3:
					return "a glossary of 1-3 words"
				for w: Variant in words:
					if str(w).length() < 1 or str(w).length() > 12:
						return "a glossary word is 1-12 letters"
			if p.has("mark") and not PAGE_PARTS.has(str(p.mark)):
				return "mark is one of %s" % [PAGE_PARTS]
			return _bool_problem(p, ["names"])
	return ""


static func _list_problem(p: Dictionary, key: String, known: Array[String], most: int, bools: Array) -> String:
	var items: Variant = p.get(key)
	if not items is Array or (items as Array).is_empty() or (items as Array).size() > most:
		return "%s: 1-%d of %s" % [key, most, known]
	var seen := {}
	for it: Variant in items:
		if not known.has(str(it)) or seen.has(str(it)):
			return "%s: each one of %s, once" % [key, known]
		seen[str(it)] = true
	return _index_problem(p, (items as Array).size(), bools)


static func _index_problem(p: Dictionary, n: int, bools: Array) -> String:
	for k: String in ["mark", "hide"]:
		if p.has(k) and (not _whole(p[k]) or int(p[k]) < 0 or int(p[k]) >= n):
			return "%s is an index 0-%d" % [k, n - 1]
	return _bool_problem(p, bools)


static func _bool_problem(p: Dictionary, keys: Array) -> String:
	for k: String in keys:
		if p.has(k) and not p[k] is bool:
			return "%s is true or false" % k
	return ""


static func _number(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


static func _whole(v: Variant) -> bool:
	return _number(v) and float(v) == floorf(float(v))


# --- Drawing -------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"skeleton":
			_draw_skeleton(pic, font, r, d)
		"joint":
			_draw_joint(pic, font, r, d)
		"muscle_pair":
			_draw_muscles(pic, font, r, d)
		"food_test":
			_draw_food_test(pic, font, r, d)
		"enzyme_cut":
			_draw_enzyme(pic, font, r, d)
		"key_tree":
			_draw_key(pic, font, r, d)
		"kingdoms":
			_draw_kingdoms(pic, font, r, d)
		"taxon_levels":
			_draw_levels(pic, font, r, d)
		"shadow_rays":
			_draw_shadow(pic, font, r, d)
		"reflection":
			_draw_reflection(pic, font, r, d)
		"light_device":
			_draw_device(pic, font, r, d)
		"energy_chain":
			_draw_chain(pic, font, r, d)
		"sankey":
			_draw_sankey(pic, font, r, d)
		"op_chain":
			_draw_ops(pic, font, r, d)
		"handshakes":
			_draw_handshakes(pic, font, r, d)
		"argument_map":
			_draw_argument(pic, font, r, d)
		"story_arc":
			_draw_arc(pic, font, r, d)
		"info_page":
			_draw_page(pic, font, r, d)


## The drawing area of a SchoolPicture of `size` (its MARGIN all round).
static func _rect(size: Vector2) -> Rect2:
	return Rect2(Vector2(SchoolPicture.MARGIN, SchoolPicture.MARGIN), size - Vector2(2, 2) * SchoolPicture.MARGIN)


static func _fs(r: Rect2, k: float = 0.085, lo: int = 10, hi: int = 22) -> int:
	return clampi(int(r.size.y * k), lo, hi)


# --- skeleton ------------------------------------------------------------------------------------------------------

## The skeleton's scale in `r`: {cx, top, u (a hundredth of its height), fs}.
static func _skeleton_geo(r: Rect2, labels: bool) -> Dictionary:
	var u := minf(r.size.y / 102.0, r.size.x / (80.0 if labels else 46.0))
	return {"cx": r.get_center().x, "top": r.position.y + (r.size.y - 100.0 * u) * 0.5, "u": u, "fs": _fs(r, 0.07, 9, 18)}


static func _sk(g: Dictionary, x: float, y: float) -> Vector2:
	return Vector2(float(g.cx) + x * float(g.u), float(g.top) + y * float(g.u))


static func _bone_line(ci: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	ci.draw_line(a, b, BONE_EDGE, w + 2.0, true)
	ci.draw_circle(a, w * 0.7 + 1.0, BONE_EDGE)
	ci.draw_circle(b, w * 0.7 + 1.0, BONE_EDGE)
	ci.draw_line(a, b, col, w, true)
	ci.draw_circle(a, w * 0.7, col)
	ci.draw_circle(b, w * 0.7, col)


static func _draw_skeleton(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var labels := bool(d.get("labels", false))
	var g := _skeleton_geo(r, labels)
	var u: float = g.u
	var mark := str(d.get("mark", ""))
	var col := func(b: String) -> Color: return ORANGE if b == mark else BONE
	# spine
	var y := 16.0
	while y < 60.0:
		var v := Rect2(_sk(g, -1.4, y), Vector2(2.8, 1.9) * u)
		ci.draw_rect(v, col.call("spine"))
		ci.draw_rect(v, BONE_EDGE, false, 1.0)
		y += 2.5
	# skull and jaw
	var sc := _sk(g, 0, 8)
	ci.draw_colored_polygon(_ellipse(sc, 6.6 * u, 7.6 * u), BONE_EDGE)
	ci.draw_colored_polygon(_ellipse(sc, 6.6 * u - 1.5, 7.6 * u - 1.5), col.call("skull"))
	for sx: float in [-2.5, 2.5]:
		ci.draw_circle(_sk(g, sx, 7.5), 1.6 * u, INK)
	ci.draw_colored_polygon(PackedVector2Array([_sk(g, 0, 9.5), _sk(g, -0.9, 11.5), _sk(g, 0.9, 11.5)]), INK)
	var jaw := Rect2(_sk(g, -3.6, 13.2), Vector2(7.2, 2.6) * u)
	ci.draw_rect(jaw, col.call("skull"))
	ci.draw_rect(jaw, BONE_EDGE, false, 1.0)
	# collarbones and breastbone
	for s: float in [-1.0, 1.0]:
		_bone_line(ci, _sk(g, 0.8 * s, 19.2), _sk(g, 13.5 * s, 18.6), 1.3 * u, BONE)
	ci.draw_rect(Rect2(_sk(g, -1.1, 20), Vector2(2.2, 13.5) * u), BONE)
	# ribs
	for k in 6:
		var y0 := 21.0 + 3.1 * k
		var w := 10.5 - maxf(0.0, k - 3.0) * 1.3 - (1.2 if k == 0 else 0.0)
		for s: float in [-1.0, 1.0]:
			var pts := PackedVector2Array([_sk(g, 1.2 * s, y0), _sk(g, w * 0.75 * s, y0 - 0.4), _sk(g, w * s, y0 + 1.5),
				_sk(g, w * 0.8 * s, y0 + 3.3), _sk(g, 1.6 * s, y0 + 2.4)])
			ci.draw_polyline(pts, BONE_EDGE, 1.1 * u + 2.0, true)
			ci.draw_polyline(pts, col.call("ribs"), 1.1 * u, true)
	# pelvis
	for s: float in [-1.0, 1.0]:
		var lobe := PackedVector2Array()
		for q: Array in [[0.8, 55.0], [8.5, 53.2], [10.6, 56.5], [8.0, 61.5], [3.6, 63.6], [0.8, 62.2]]:
			lobe.append(_sk(g, float(q[0]) * s, float(q[1])))
		ci.draw_colored_polygon(lobe, col.call("pelvis"))
		lobe.append(lobe[0])
		ci.draw_polyline(lobe, BONE_EDGE, 1.5, true)
		ci.draw_circle(_sk(g, 4.2 * s, 58.6), 1.4 * u, PAPER)
	# arms and legs
	for s: float in [-1.0, 1.0]:
		_bone_line(ci, _sk(g, 14.2 * s, 20.0), _sk(g, 16.6 * s, 39.0), 2.3 * u, col.call("humerus"))
		_bone_line(ci, _sk(g, 16.0 * s, 40.6), _sk(g, 18.0 * s, 56.0), 1.1 * u, col.call("radius_ulna"))
		_bone_line(ci, _sk(g, 17.6 * s, 40.6), _sk(g, 20.0 * s, 55.6), 1.1 * u, col.call("radius_ulna"))
		ci.draw_colored_polygon(_ellipse(_sk(g, 19.4 * s, 58.8), 2.1 * u, 2.6 * u), BONE_EDGE)
		ci.draw_colored_polygon(_ellipse(_sk(g, 19.4 * s, 58.8), 2.1 * u - 1.0, 2.6 * u - 1.0), BONE)
		_bone_line(ci, _sk(g, 5.4 * s, 62.6), _sk(g, 6.6 * s, 79.4), 2.7 * u, col.call("femur"))
		ci.draw_circle(_sk(g, 6.7 * s, 81.0), 1.3 * u, BONE_EDGE)
		ci.draw_circle(_sk(g, 6.7 * s, 81.0), 1.3 * u - 1.0, BONE)
		_bone_line(ci, _sk(g, 6.2 * s, 82.6), _sk(g, 6.4 * s, 95.6), 1.8 * u, col.call("tibia_fibula"))
		_bone_line(ci, _sk(g, 8.4 * s, 83.0), _sk(g, 8.4 * s, 95.0), 0.9 * u, col.call("tibia_fibula"))
		ci.draw_colored_polygon(_ellipse(_sk(g, 7.6 * s, 97.8), 3.6 * u, 1.5 * u), BONE_EDGE)
		ci.draw_colored_polygon(_ellipse(_sk(g, 7.6 * s, 97.8), 3.6 * u - 1.0, 1.5 * u - 1.0), BONE)
	if not labels:
		return
	var fs: int = g.fs
	var hide := str(d.get("hide", ""))
	var left_x := float(g.cx) - 26.0 * u
	var right_x := float(g.cx) + 26.0 * u
	for b: String in BONES:
		var at: Array = BONE_AT[b]
		var part := _sk(g, float(at[0]), float(at[1]))
		var side := int(at[2])
		var t := "?" if b == hide else str(BONE_NAMES[b])
		var tcol := ORANGE if b == hide or b == mark else INK
		var room := (left_x - r.position.x) if side < 0 else (r.end.x - right_x)
		var size := _fit(font, t, room - 4.0, fs)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var end_x := left_x if side < 0 else right_x
		ci.draw_line(Vector2(end_x, part.y), part, Color(INK, 0.6), 1.5, true)
		var tx := end_x - tw - 3.0 if side < 0 else end_x + 3.0
		ci.draw_string(font, Vector2(tx, part.y + size * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tcol)


# --- joint ---------------------------------------------------------------------------------------------------------

static func _draw_joint(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var type := str(d.type)
	var fs := _fs(r, 0.08, 10, 20)
	var named := bool(d.get("name", true))
	var area := Rect2(r.position, r.size - Vector2(0, fs * 1.6 if named else 0.0))
	var s := minf(area.size.y * 0.86, area.size.x * 0.5)
	var c := area.get_center()
	var labels := bool(d.get("labels", false))
	var moves := bool(d.get("move", true))
	var w := s * 0.16
	var lfs := maxi(9, fs - 2)
	match type:
		"hinge":
			# the upper bone comes down to a rounded end; the lower bone turns on it like a door on its hinge
			var knob := c + Vector2(-s * 0.18, -s * 0.05)
			var down := Vector2(sin(0.6), cos(0.6))
			_bone_line(ci, knob + Vector2(0, -s * 0.42), knob, w, BONE)
			_bone_line(ci, knob + down * w * 1.1, knob + down * s * 0.5, w * 0.9, BONE)
			ci.draw_arc(knob, w * 0.95, 0, TAU, 28, CARTILAGE, 4.0, true)
			for sx: float in [-1.0, 1.0]:
				ci.draw_line(knob + Vector2(sx * w * 1.05, -w * 1.1), knob + Vector2(sx * w * 1.05, w * 0.9), LIGAMENT, 5.0, true)
			if moves:
				var rad := s * 0.36
				var a0 := PI * 0.5 - 0.6 - 0.45
				var a1 := PI * 0.5 - 0.6 + 0.45
				ci.draw_arc(knob, rad, a0, a1, 20, RED, 3.0, true)
				_head(ci, knob + Vector2(cos(a0), sin(a0)) * rad, Vector2(sin(a0), -cos(a0)), 11.0, RED)
				_head(ci, knob + Vector2(cos(a1), sin(a1)) * rad, Vector2(-sin(a1), cos(a1)), 11.0, RED)
			if labels:
				_joint_label(ci, font, lfs, knob + Vector2(0, -s * 0.3), knob + Vector2(-s * 0.55, -s * 0.3), "bone")
				_joint_label(ci, font, lfs, knob + Vector2(w * 0.7, -w * 0.7), knob + Vector2(s * 0.62, -s * 0.28), "cartilage")
				_joint_label(ci, font, lfs, knob + Vector2(w * 1.05, w * 0.4), knob + Vector2(s * 0.62, s * 0.02), "ligament")
		"ball_socket":
			var ball := c + Vector2(-s * 0.3, 0)
			ci.draw_rect(Rect2(ball + Vector2(-s * 0.46, -s * 0.42), Vector2(s * 0.26, s * 0.84)), BONE)
			ci.draw_rect(Rect2(ball + Vector2(-s * 0.46, -s * 0.42), Vector2(s * 0.26, s * 0.84)), BONE_EDGE, false, 1.5)
			ci.draw_arc(ball, w * 1.6, PI * 0.45, PI * 1.55, 24, BONE_EDGE, w * 0.6 + 2.0, true)
			ci.draw_arc(ball, w * 1.6, PI * 0.45, PI * 1.55, 24, BONE, w * 0.6, true)
			_bone_line(ci, ball, ball + Vector2(s * 0.72, s * 0.1), w * 0.85, BONE)
			ci.draw_circle(ball, w * 1.2 + 1.5, BONE_EDGE)
			ci.draw_circle(ball, w * 1.2, BONE)
			ci.draw_arc(ball, w * 1.28, PI * 0.5, PI * 1.5, 24, CARTILAGE, 4.0, true)
			if moves:   # it turns every way: a ring of arrow round the bone
				var rc := ball + Vector2(s * 0.42, s * 0.06)
				var ring := PackedVector2Array()
				for k in 25:
					var a := 0.4 + (TAU - 0.9) * k / 24.0
					ring.append(rc + Vector2(cos(a) * s * 0.07, sin(a) * s * 0.22))
				ci.draw_polyline(ring, RED, 3.0, true)
				var last := ring[ring.size() - 1]
				_head(ci, last, (last - ring[ring.size() - 2]).normalized(), 11.0, RED)
			if labels:
				_joint_label(ci, font, lfs, ball + Vector2(-s * 0.33, -s * 0.3), ball + Vector2(-s * 0.33, -s * 0.46), "bone")
				_joint_label(ci, font, lfs, ball + Vector2(-w * 0.5, -w * 1.2), ball + Vector2(s * 0.2, -s * 0.44), "cartilage")
				ci.draw_line(ball + Vector2(w * 0.5, -w * 1.7), ball + Vector2(w * 1.8, -w * 0.45), LIGAMENT, 5.0, true)
				_joint_label(ci, font, lfs, ball + Vector2(w * 1.2, -w * 1.1), ball + Vector2(s * 0.62, -s * 0.3), "ligament")
		"pivot":
			var ring_c := c + Vector2(0, s * 0.02)
			_bone_line(ci, c + Vector2(0, s * 0.42), ring_c, w * 0.8, BONE)
			ci.draw_colored_polygon(_ellipse(ring_c, s * 0.3, s * 0.1), BONE_EDGE)
			ci.draw_colored_polygon(_ellipse(ring_c, s * 0.3 - 2.0, s * 0.1 - 2.0), BONE)
			ci.draw_colored_polygon(_ellipse(ring_c, s * 0.1, s * 0.035), CARTILAGE)
			_bone_line(ci, ring_c, ring_c + Vector2(0, -s * 0.3), w * 0.55, BONE)
			if moves:   # the ring turns round the peg
				var arc := PackedVector2Array()
				for k in 21:
					var a := PI * 1.1 + PI * 0.8 * k / 20.0
					arc.append(ring_c + Vector2(cos(a) * s * 0.4, sin(a) * s * 0.16) + Vector2(0, -s * 0.04))
				ci.draw_polyline(arc, RED, 3.0, true)
				var last := arc[arc.size() - 1]
				_head(ci, last, (last - arc[arc.size() - 2]).normalized(), 11.0, RED)
		"fixed":
			var plate := Rect2(c - Vector2(s * 0.62, s * 0.34), Vector2(s * 1.24, s * 0.68))
			ci.draw_rect(plate, BONE)
			ci.draw_rect(plate, BONE_EDGE, false, 2.0)
			var seam := PackedVector2Array()
			var n := 9
			for i in n + 1:
				seam.append(Vector2(c.x + (s * 0.06 if i % 2 == 0 else -s * 0.06), plate.position.y + plate.size.y * i / n))
			ci.draw_polyline(seam, BONE_EDGE, 3.0, true)
	if named:
		_text(ci, font, Vector2(r.get_center().x, r.end.y - fs * 0.3), str(JOINT_NAMES[type]), fs)


static func _joint_label(ci: CanvasItem, font: Font, fs: int, part: Vector2, at: Vector2, text: String) -> void:
	ci.draw_line(part, at, Color(INK, 0.6), 1.5, true)
	_text(ci, font, at + Vector2(0, -3), text, fs)


# --- muscle_pair ---------------------------------------------------------------------------------------------------

## Where an arm's parts are in `r`: {shoulder, elbow, hand, dir (the forearm's way), biceps, triceps (the muscles'
## middles), tendon (the biceps's lower tendon), joint, bone, fs, len, thick, and the muscles' ends}.
static func _muscle_geo(r: Rect2, move: String, labels: bool) -> Dictionary:
	var fs := _fs(r, 0.075, 10, 18)
	var area := r.grow_individual(-r.size.x * (0.18 if labels else 0.04), -fs * 1.2, -r.size.x * (0.18 if labels else 0.04),
		-fs * 1.2)
	var bend := move == "bend"
	var arm := minf(area.size.x * 0.52, area.size.y * 1.3)
	var y := area.position.y + area.size.y * (0.72 if bend else 0.45)
	var shoulder := Vector2(area.position.x + area.size.x * 0.08, y)
	var elbow := shoulder + Vector2(arm, 0)
	var a := deg_to_rad(-72.0 if bend else 8.0)
	var dir := Vector2(cos(a), sin(a))
	var fore := minf(arm * 0.95, (area.end.x - elbow.x) / maxf(dir.x, 0.25))
	if bend:
		fore = minf(fore, (elbow.y - area.position.y) / -dir.y)
	var hand := elbow + dir * fore
	var thick := arm * 0.11
	var up := Vector2(0, -1)
	var b_short := bend
	var b0 := shoulder + Vector2(arm * (0.28 if b_short else 0.12), 0) + up * thick * 0.9
	var b1 := shoulder + Vector2(arm * (0.72 if b_short else 0.86), 0) + up * thick * 0.9
	var t0 := shoulder + Vector2(arm * (0.12 if b_short else 0.26), 0) - up * thick * 0.9
	var t1 := shoulder + Vector2(arm * (0.9 if b_short else 0.74), 0) - up * thick * 0.9
	var b_attach := elbow + dir * fore * 0.16 + Vector2(dir.y, -dir.x) * thick * 0.35
	var t_attach := elbow - dir * thick * 0.9
	return {"shoulder": shoulder, "elbow": elbow, "hand": hand, "dir": dir, "fs": fs, "len": arm, "thick": thick,
		"b0": b0, "b1": b1, "t0": t0, "t1": t1, "b_attach": b_attach, "t_attach": t_attach,
		"biceps": b0.lerp(b1, 0.5), "triceps": t0.lerp(t1, 0.5), "tendon": b1.lerp(b_attach, 0.5), "joint": elbow,
		"bone": shoulder.lerp(elbow, 0.2)}


static func _draw_muscles(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var move := str(d.move)
	var labels := bool(d.get("labels", false))
	var g := _muscle_geo(r, move, labels)
	var thick: float = g.thick
	var bend := move == "bend"
	var mark := str(d.get("mark", ""))
	var shoulder: Vector2 = g.shoulder
	var elbow: Vector2 = g.elbow
	# the shoulder blade, the humerus and the forearm
	ci.draw_colored_polygon(_ellipse(shoulder + Vector2(-thick * 0.6, 0), thick * 1.1, thick * 2.0), BONE_EDGE)
	ci.draw_colored_polygon(_ellipse(shoulder + Vector2(-thick * 0.6, 0), thick * 1.1 - 1.5, thick * 2.0 - 1.5), BONE)
	_bone_line(ci, shoulder, elbow, thick * 0.7, ORANGE if mark == "bone" else BONE)
	_bone_line(ci, g.t_attach, g.hand, thick * 0.55, BONE)
	ci.draw_colored_polygon(_ellipse(g.hand, thick * 0.9, thick * 0.9), Color("f1c9a5"))
	ci.draw_circle(elbow, thick * 0.55, ORANGE if mark == "joint" else CARTILAGE)
	# the muscles: the contracting one short and fat, the relaxing one long and thin
	var b_col := MUSCLE if bend else MUSCLE_SOFT
	var t_col := MUSCLE_SOFT if bend else MUSCLE
	if mark == "biceps":
		b_col = ORANGE
	if mark == "triceps":
		t_col = ORANGE
	ci.draw_colored_polygon(_spindle(g.b0, g.b1, thick * (2.4 if bend else 1.1)), b_col)
	ci.draw_colored_polygon(_spindle(g.t0, g.t1, thick * (1.1 if bend else 2.4)), t_col)
	# tendons: the biceps to the shoulder and to the forearm, the triceps to the shoulder and the elbow's point
	var tendon_col := ORANGE if mark == "tendon" else TENDON
	ci.draw_line(g.b1, g.b_attach, tendon_col, maxf(3.0, thick * 0.3), true)
	ci.draw_line(g.b0, shoulder + Vector2(0, -thick * 0.5), TENDON, maxf(3.0, thick * 0.3), true)
	ci.draw_line(g.t1, g.t_attach, TENDON, maxf(3.0, thick * 0.3), true)
	ci.draw_line(g.t0, shoulder + Vector2(0, thick * 0.5), TENDON, maxf(3.0, thick * 0.3), true)
	var fs: int = g.fs
	if bool(d.get("states", false)):
		_text_col(ci, font, (g.biceps as Vector2) + Vector2(0, -thick * (1.5 if bend else 0.9)),
			"contracts" if bend else "relaxes", fs, MUSCLE if bend else INK)
		_text_col(ci, font, (g.triceps as Vector2) + Vector2(0, thick * (1.2 if bend else 1.8) + fs * 0.8),
			"relaxes" if bend else "contracts", fs, INK if bend else MUSCLE)
	if not labels:
		return
	var hide := str(d.get("hide", ""))
	var spots := {"biceps": [r.position.x + 4.0, r.position.y + fs * 1.2], "triceps": [r.position.x + 4.0, r.end.y - 4.0],
		"bone": [r.position.x + 4.0, r.get_center().y], "tendon": [r.end.x - 4.0, r.position.y + fs * 1.2],
		"joint": [r.end.x - 4.0, r.end.y - 4.0]}
	for part: String in MUSCLE_PARTS:
		var at: Vector2 = g[part]
		var sp: Array = spots[part]
		var t := "?" if part == hide else str(MUSCLE_NAMES[part])
		var size := _fit(font, t, r.size.x * 0.17, fs)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var left := float(sp[0]) < r.get_center().x
		var base := Vector2(float(sp[0]) if left else float(sp[0]) - tw, float(sp[1]))
		var line_from := Vector2(base.x + tw + 2.0 if left else base.x - 2.0, base.y - size * 0.35)
		ci.draw_line(line_from, at, Color(INK, 0.6), 1.5, true)
		ci.draw_string(font, base, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ORANGE if part == hide or part == mark else INK)


# --- food_test -----------------------------------------------------------------------------------------------------

static func _draw_food_test(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var tubes: Array = d.tubes
	var names := bool(d.get("names", true))
	var fs := _fs(r, 0.08, 10, 20)
	var n := tubes.size()
	var cell := r.size.x / n
	var top := r.position.y + fs * 1.4
	var bottom := r.end.y - (fs * 1.5 if names else 4.0)
	for i in n:
		var t: Array = tubes[i]
		var test := str(t[0])
		var positive := bool(t[1])
		var cx := r.position.x + cell * (i + 0.5)
		if t.size() > 2:
			_text(ci, font, Vector2(cx, r.position.y + fs), str(t[2]), fs)
		if test == "fat":
			var side := minf(cell * 0.7, bottom - top)
			var paper := Rect2(Vector2(cx - side * 0.5, (top + bottom - side) * 0.5), Vector2(side, side))
			ci.draw_rect(paper, Color("fffdf6"))
			ci.draw_rect(paper, GREY, false, 2.0)
			if positive:
				ci.draw_colored_polygon(_ellipse(paper.get_center(), side * 0.28, side * 0.22), Color(0.98, 0.93, 0.7, 0.55))
				ci.draw_colored_polygon(_ellipse(paper.get_center() + Vector2(side * 0.04, 0), side * 0.2, side * 0.15),
					Color(1, 1, 1, 0.8))
				ci.draw_arc(paper.get_center(), side * 0.25, 0, TAU, 28, Color(0.8, 0.7, 0.4, 0.8), 1.5, true)
		else:
			var tw := minf(cell * 0.28, (bottom - top) * 0.3)
			var tube := Rect2(Vector2(cx - tw * 0.5, top), Vector2(tw, bottom - top - tw * 0.5))
			var cols: Array = TEST_COLOURS[test]
			var liquid: Color = cols[1] if positive else cols[0]
			var level := tube.position.y + tube.size.y * 0.42
			ci.draw_rect(Rect2(Vector2(tube.position.x, level), Vector2(tw, tube.end.y - level)), liquid)
			ci.draw_circle(Vector2(cx, tube.end.y), tw * 0.5, liquid)
			ci.draw_line(tube.position, Vector2(tube.position.x, tube.end.y), INK, 2.0, true)
			ci.draw_line(Vector2(tube.end.x, tube.position.y), tube.end, INK, 2.0, true)
			ci.draw_arc(Vector2(cx, tube.end.y), tw * 0.5, 0, PI, 16, INK, 2.0, true)
			ci.draw_line(tube.position + Vector2(-3, 0), Vector2(tube.end.x + 3, tube.position.y), INK, 2.0, true)
			ci.draw_line(Vector2(tube.position.x + tw * 0.25, level + 4.0), Vector2(tube.position.x + tw * 0.25,
				tube.end.y - 4.0), Color(1, 1, 1, 0.35), 2.0)
		if names:
			var word := str(REAGENTS[test])
			_text(ci, font, Vector2(cx, r.end.y - fs * 0.3), word, _fit(font, word, cell * 0.95, fs))


# --- enzyme_cut ----------------------------------------------------------------------------------------------------

static func _draw_enzyme(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var food := str(d.food)
	var names := bool(d.get("names", true))
	var hide := str(d.get("hide", ""))
	var fs := _fs(r, 0.075, 10, 18)
	var mid_y := r.position.y + (r.size.y - (fs * 1.5 if names else 0.0)) * 0.5
	var left := Rect2(r.position, Vector2(r.size.x * 0.38, mid_y * 2.0 - r.position.y * 2.0))
	var right := Rect2(Vector2(r.position.x + r.size.x * 0.62, r.position.y), left.size)
	var bead := minf(left.size.x / 7.5, left.size.y * 0.16)
	var cols: Array[Color] = [Color("e8746a"), Color("7fb3f0"), Color("8fcf7a"), Color("f5d547"), Color("c9b3f2"),
		Color("f5a36b")]
	match food:
		"starch", "protein":
			# a chain of beads, then the same beads apart
			var start := Vector2(left.get_center().x - bead * 2.6, mid_y)
			for k in 6:
				var c := start + Vector2(bead * 1.05 * k, (bead * 0.35 if k % 2 == 0 else -bead * 0.35))
				if k > 0:
					var prev := start + Vector2(bead * 1.05 * (k - 1), (bead * 0.35 if (k - 1) % 2 == 0 else -bead * 0.35))
					ci.draw_line(prev, c, INK, 2.0, true)
				_bead(ci, c, bead * 0.5, food, cols[k % cols.size()])
			for k in 6:
				var c := Vector2(right.position.x + right.size.x * (0.2 + 0.3 * (k % 3)), mid_y + (floorf(k / 3.0) - 0.5) * bead * 1.8)
				_bead(ci, c, bead * 0.5, food, cols[k % cols.size()])
		"fat":
			var gx := left.get_center().x - bead * 2.0
			_glycerol(ci, gx, mid_y, bead)
			for k in 3:
				_tail(ci, Vector2(gx + bead * 0.3, mid_y + (k - 1) * bead * 1.2), bead)
			var rx := right.position.x + right.size.x * 0.12
			_glycerol(ci, rx, mid_y, bead)
			for k in 3:
				_tail(ci, Vector2(rx + bead * 1.4, mid_y + (k - 1) * bead * 1.2), bead)
	# the enzyme on the arrow: a round shape with a notch, cutting
	var a := Vector2(r.position.x + r.size.x * 0.4, mid_y)
	var b := Vector2(r.position.x + r.size.x * 0.6, mid_y)
	_arrow(ci, a, b, INK, 3.0)
	var ec := a.lerp(b, 0.45) + Vector2(0, -bead * 1.3)
	var er := bead * 0.8
	var pts := PackedVector2Array([ec])
	for k in 25:
		var ang := 0.55 + (TAU - 1.1) * k / 24.0
		pts.append(ec + Vector2(cos(ang), sin(ang)) * er)
	ci.draw_colored_polygon(pts, BLUE)
	if names:
		var y := r.end.y - fs * 0.3
		var enz := "?" if hide == "enzyme" else str(ENZYMES[food])
		_text_col(ci, font, ec + Vector2(0, -er - 4.0), enz, _fit(font, enz, r.size.x * 0.24, fs),
			ORANGE if hide == "enzyme" else BLUE)
		var ft := "?" if hide == "food" else food
		var pt := "?" if hide == "products" else str(PRODUCTS[food])
		_text_col(ci, font, Vector2(left.get_center().x, y), ft, _fit(font, ft, left.size.x, fs),
			ORANGE if hide == "food" else INK)
		_text_col(ci, font, Vector2(right.get_center().x, y), pt, _fit(font, pt, right.size.x, fs),
			ORANGE if hide == "products" else INK)


static func _bead(ci: CanvasItem, c: Vector2, rad: float, food: String, col: Color) -> void:
	if food == "starch":   # every unit the same sugar: a hexagon
		var hex := PackedVector2Array()
		for k in 6:
			hex.append(c + Vector2(cos(TAU * k / 6.0), sin(TAU * k / 6.0)) * rad)
		ci.draw_colored_polygon(hex, Color("f5d547"))
		hex.append(hex[0])
		ci.draw_polyline(hex, INK, 1.5, true)
	else:   # amino acids of many kinds: coloured beads
		ci.draw_circle(c, rad, col)
		ci.draw_arc(c, rad, 0, TAU, 20, INK, 1.5, true)


static func _glycerol(ci: CanvasItem, x: float, y: float, bead: float) -> void:
	var box := Rect2(Vector2(x - bead * 0.3, y - bead * 1.8), Vector2(bead * 0.6, bead * 3.6))
	ci.draw_rect(box, Color("c9b3f2"))
	ci.draw_rect(box, INK, false, 1.5)


static func _tail(ci: CanvasItem, from: Vector2, bead: float) -> void:
	var pts := PackedVector2Array([from])
	for k in 6:
		pts.append(from + Vector2(bead * 0.5 * (k + 1), (-bead * 0.25 if k % 2 == 0 else bead * 0.25)))
	ci.draw_polyline(pts, Color("d98c2b"), 3.0, true)


# --- key_tree ------------------------------------------------------------------------------------------------------

static func _draw_key(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var qs: Array = d.questions
	var ends: Array = d.ends
	var n := qs.size()
	var rows := n + 1
	var row_h := r.size.y / rows
	var fs := clampi(int(row_h * 0.36), 9, 20)
	var qw := r.size.x * 0.56
	var ew := r.size.x * 0.28
	var bh := minf(row_h * 0.72, fs * 2.0)
	var path: Array = d.get("path", [])
	var stop := key_end(path) if not path.is_empty() else -1
	var hide := int(d.get("hide", -1))
	for i in rows:
		var cy := r.position.y + row_h * (i + 0.5)
		if i < n:
			var qbox := Rect2(Vector2(r.position.x, cy - bh * 0.5), Vector2(qw, bh))
			var on_path := not path.is_empty() and i <= mini(stop, path.size() - 1)
			ci.draw_rect(qbox, Color("e8f0ff"))
			ci.draw_rect(qbox, ORANGE if on_path else INK, false, 3.0 if on_path else 2.0)
			var qt := "%d  %s" % [i + 1, qs[i]]
			_text(ci, font, Vector2(qbox.get_center().x, cy + fs * 0.35), qt, _fit(font, qt, qw - 8.0, fs))
			# yes: across to an end
			var ebox := Rect2(Vector2(r.end.x - ew, cy - bh * 0.5), Vector2(ew, bh))
			var yes_on := on_path and i < path.size() and bool(path[i])
			_arrow(ci, Vector2(qbox.end.x + 2, cy), Vector2(ebox.position.x - 2, cy), ORANGE if yes_on else INK, 2.5)
			_text(ci, font, Vector2((qbox.end.x + ebox.position.x) * 0.5, cy - 5.0), "yes", maxi(9, fs - 3))
			_end_box(ci, font, ebox, "?" if hide == i else str(ends[i]), fs, yes_on)
			# no: down to the next question (or the last end)
			var no_on := on_path and i < path.size() and not bool(path[i])
			var down_x := r.position.x + qw * 0.5
			_arrow(ci, Vector2(down_x, qbox.end.y + 1), Vector2(down_x, cy + row_h - bh * 0.5 - 1), ORANGE if no_on else INK, 2.5)
			_text(ci, font, Vector2(down_x + fs * 1.2, cy + row_h * 0.5 + fs * 0.3), "no", maxi(9, fs - 3))
		else:
			var last := Rect2(Vector2(r.position.x + qw * 0.5 - ew * 0.5, cy - bh * 0.5), Vector2(ew, bh))
			_end_box(ci, font, last, "?" if hide == n else str(ends[n]), fs, stop == n and path.size() == n)


static func _end_box(ci: CanvasItem, font: Font, box: Rect2, text: String, fs: int, lit: bool) -> void:
	ci.draw_rect(box, Color("e9f7e6"))
	ci.draw_rect(box, ORANGE if lit or text == "?" else GREEN, false, 3.0 if lit else 2.0)
	_text_col(ci, font, Vector2(box.get_center().x, box.get_center().y + fs * 0.35), text, _fit(font, text, box.size.x - 6.0,
		fs), ORANGE if text == "?" else INK)


# --- kingdoms ------------------------------------------------------------------------------------------------------

static func _draw_kingdoms(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var show: Array = d.show
	var names := bool(d.get("names", true))
	var n := show.size()
	var fs := _fs(r, 0.08, 10, 20)
	var w := r.size.x / n
	var h := r.size.y - (fs * 1.6 if names else 0.0)
	for i in n:
		var tile := Rect2(Vector2(r.position.x + w * i + w * 0.06, r.position.y + 2), Vector2(w * 0.88, h - 4))
		var sq := minf(tile.size.x, tile.size.y)
		var box := Rect2(tile.get_center() - Vector2(sq, sq) * 0.5, Vector2(sq, sq))
		ci.draw_rect(tile, Color("f4f7ee"))
		if d.has("mark") and int(d.mark) == i:
			ci.draw_rect(tile.grow(2), ORANGE, false, 4.0)
		_kingdom_icon(ci, box.grow(sq * 0.04), str(show[i]))
		if names:
			var t := "?" if d.has("hide") and int(d.hide) == i else str(show[i])
			_text_col(ci, font, Vector2(tile.get_center().x, r.end.y - fs * 0.35), t, _fit(font, t, w * 0.96, fs),
				ORANGE if t == "?" else INK)


static func _kingdom_icon(ci: CanvasItem, b: Rect2, kingdom: String) -> void:
	var c := b.get_center()
	var s := b.size.x * (0.8 if kingdom == "animals" else 1.0)
	match kingdom:
		"animals":   # a fox from the side
			var fur := Color("e07b39")
			ci.draw_colored_polygon(_ellipse(c + Vector2(-s * 0.02, s * 0.06), s * 0.28, s * 0.14), fur)
			ci.draw_colored_polygon(_ellipse(c + Vector2(s * 0.28, -s * 0.06), s * 0.12, s * 0.1), fur)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.24, -s * 0.12), c + Vector2(s * 0.27, -s * 0.26),
				c + Vector2(s * 0.32, -s * 0.13)]), fur)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.36, -s * 0.08), c + Vector2(s * 0.48, -s * 0.03),
				c + Vector2(s * 0.37, 0.0)]), fur)
			ci.draw_circle(c + Vector2(s * 0.31, -s * 0.08), s * 0.018, INK)
			for lx: float in [-0.2, -0.1, 0.1, 0.18]:
				ci.draw_line(c + Vector2(s * lx, s * 0.14), c + Vector2(s * lx, s * 0.32), Color("8a4a22"), maxf(2.0, s * 0.035))
			ci.draw_colored_polygon(_ellipse(c + Vector2(-s * 0.36, -s * 0.02), s * 0.14, s * 0.07), fur)
			ci.draw_circle(c + Vector2(-s * 0.48, -s * 0.05), s * 0.05, Color.WHITE)
		"plants":
			ci.draw_line(c + Vector2(0, s * 0.42), c + Vector2(0, -s * 0.2), GREEN, maxf(2.0, s * 0.04))
			for side: float in [-1.0, 1.0]:
				ci.draw_colored_polygon(_ellipse(c + Vector2(side * s * 0.13, s * 0.12 - side * s * 0.08), s * 0.13, s * 0.06),
					Color("5cb85c"))
			for k in 6:
				var ang := TAU * k / 6.0
				ci.draw_circle(c + Vector2(0, -s * 0.28) + Vector2(cos(ang), sin(ang)) * s * 0.09, s * 0.07, Color("e8746a"))
			ci.draw_circle(c + Vector2(0, -s * 0.28), s * 0.06, YELLOW)
		"fungi":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.08, -s * 0.05), Vector2(s * 0.16, s * 0.42)), Color("f3ead3"))
			var cap := PackedVector2Array()
			for k in 17:
				var ang := PI + PI * k / 16.0
				cap.append(c + Vector2(cos(ang) * s * 0.38, sin(ang) * s * 0.3 - s * 0.02))
			ci.draw_colored_polygon(cap, Color("c0392b"))
			for sp: Vector2 in [Vector2(-0.18, -0.16), Vector2(0.05, -0.24), Vector2(0.2, -0.12)]:
				ci.draw_circle(c + sp * s, s * 0.04, Color.WHITE)
			ci.draw_line(c + Vector2(-s * 0.38, -s * 0.02), c + Vector2(s * 0.38, -s * 0.02), Color("8a2a20"), 2.0)
		"protists":   # an amoeba: a blob with a nucleus
			var blob := PackedVector2Array()
			for k in 40:
				var ang := TAU * k / 40.0
				var rad := s * (0.3 + 0.07 * sin(ang * 3.0) + 0.04 * cos(ang * 5.0))
				blob.append(c + Vector2(cos(ang), sin(ang)) * rad)
			ci.draw_colored_polygon(blob, Color("b9e0d4"))
			blob.append(blob[0])
			ci.draw_polyline(blob, Color("3f8f7a"), 2.0, true)
			ci.draw_circle(c + Vector2(s * 0.04, -s * 0.02), s * 0.08, Color("3f8f7a"))
			ci.draw_circle(c + Vector2(-s * 0.12, s * 0.1), s * 0.03, Color("7fbfae"))
		"bacteria":   # rod-shaped cells with a tail, no nucleus
			for k in 3:
				var at := c + Vector2(-s * 0.1 + (k % 2) * s * 0.12, (k - 1) * s * 0.26)
				var rod := Rect2(at - Vector2(s * 0.2, s * 0.08), Vector2(s * 0.4, s * 0.16))
				ci.draw_rect(rod.grow_individual(-s * 0.08, 0, -s * 0.08, 0), Color("a3c86b"))
				ci.draw_circle(Vector2(rod.position.x + s * 0.08, at.y), s * 0.08, Color("a3c86b"))
				ci.draw_circle(Vector2(rod.end.x - s * 0.08, at.y), s * 0.08, Color("a3c86b"))
				ci.draw_circle(at + Vector2(-s * 0.04, 0), s * 0.025, Color("6b8f3a"))
				var tail := PackedVector2Array()
				for q in 7:
					tail.append(Vector2(rod.end.x + q * s * 0.035, at.y + (s * 0.03 if q % 2 == 0 else -s * 0.03)))
				ci.draw_polyline(tail, Color("6b8f3a"), 2.0, true)


# --- taxon_levels --------------------------------------------------------------------------------------------------

static func _draw_levels(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var n := LEVELS.size()
	var h := r.size.y / n
	var fs := clampi(int(h * 0.62), 8, 20)
	var names := bool(d.get("names", true))
	var ex: Array = d.get("example", [])
	for i in n:
		var w := r.size.x * (1.0 - 0.07 * i)
		var row := Rect2(Vector2(r.get_center().x - w * 0.5, r.position.y + h * i + 1), Vector2(w, h - 2))
		var shade := Color("3a7be8").lerp(Color("dce9ff"), float(i) / (n - 1))
		ci.draw_rect(row, shade)
		if d.has("mark") and int(d.mark) == i:
			ci.draw_rect(row.grow(1), ORANGE, false, 3.0)
		var tcol := Color.WHITE if i < 3 else INK
		var y := row.get_center().y + fs * 0.35
		if names:
			var t := "?" if d.has("hide") and int(d.hide) == i else LEVELS[i]
			var tx := row.position.x + 6.0 if not ex.is_empty() else row.get_center().x - font.get_string_size(t,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 0.5
			ci.draw_string(font, Vector2(tx, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ORANGE if t == "?" else tcol)
		if not ex.is_empty():
			var e := str(ex[i])
			var size := _fit(font, e, row.size.x * 0.55, fs)
			var ew := font.get_string_size(e, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			ci.draw_string(font, Vector2(row.end.x - ew - 6.0, y), e, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tcol)


# --- shadow_rays ---------------------------------------------------------------------------------------------------

static func _draw_shadow(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var near := float(d.near)
	var far := float(d.far)
	var size := float(d.size)
	var shadow := shadow_height(near, far, size)
	var hide := str(d.get("hide", "shadow"))
	var numbers := bool(d.get("numbers", true))
	var unit := str(d.get("unit", "cm"))
	var fs := _fs(r, 0.08, 10, 18)
	var area := r.grow_individual(-fs * 0.5, -4, -fs * 4.5, -fs * (2.6 if numbers else 0.8))
	var ax := area.position.y + area.size.y * 0.5
	var lamp := Vector2(area.position.x + fs * 1.2, ax)
	var scale_x := (area.end.x - lamp.x) / far
	var scale_y := area.size.y * 0.96 / shadow
	var card_x := lamp.x + near * scale_x
	var screen_x := lamp.x + far * scale_x
	var half := size * scale_y * 0.5
	var shalf := shadow * scale_y * 0.5
	# the screen and the shadow on it
	ci.draw_rect(Rect2(Vector2(screen_x, area.position.y - 2), Vector2(fs * 0.8, area.size.y + 4)), Color("eef1f6"))
	ci.draw_rect(Rect2(Vector2(screen_x, ax - shalf), Vector2(fs * 0.8, shalf * 2.0)), Color("4a5160"))
	ci.draw_rect(Rect2(Vector2(screen_x, area.position.y - 2), Vector2(fs * 0.8, area.size.y + 4)), INK, false, 1.5)
	# the rays past the card's edges
	for s: float in [-1.0, 1.0]:
		ci.draw_line(lamp, Vector2(screen_x, ax + s * shalf), YELLOW.darkened(0.1), 2.0, true)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(card_x, ax - half), Vector2(screen_x, ax - shalf),
		Vector2(screen_x, ax + shalf), Vector2(card_x, ax + half)]), Color(0.3, 0.33, 0.4, 0.18))
	# the card and the lamp
	ci.draw_line(Vector2(card_x, ax - half), Vector2(card_x, ax + half), INK, maxf(4.0, fs * 0.35), true)
	ci.draw_circle(lamp, fs * 0.55, YELLOW)
	ci.draw_arc(lamp, fs * 0.55, 0, TAU, 20, INK, 1.5, true)
	ci.draw_rect(Rect2(lamp + Vector2(-fs * 1.1, -fs * 0.35), Vector2(fs * 0.6, fs * 0.7)), GREY)
	if not numbers:
		return
	var word := func(key: String, v: float) -> String:
		return "?" if hide == key else "%s %s" % [_num(v), unit]
	var dist_y := r.end.y - fs * 1.6
	var fs2 := fs - 1
	_dimension(ci, font, Vector2(lamp.x, dist_y), Vector2(card_x, dist_y), word.call("near", near), fs2, hide == "near")
	_dimension(ci, font, Vector2(lamp.x, dist_y + fs * 1.2), Vector2(screen_x, dist_y + fs * 1.2), word.call("far", far),
		fs2, hide == "far")
	var st: String = word.call("size", size)
	var sw := font.get_string_size(st, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
	ci.draw_string(font, Vector2(card_x - sw - 5.0, ax - half - 3.0), st, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2,
		ORANGE if hide == "size" else INK)
	var sh: String = word.call("shadow", shadow)
	ci.draw_string(font, Vector2(screen_x + fs, ax + fs2 * 0.35), sh, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2,
		ORANGE if hide == "shadow" else INK)


static func _dimension(ci: CanvasItem, font: Font, a: Vector2, b: Vector2, text: String, fs: int, hidden: bool) -> void:
	ci.draw_line(a, b, Color(INK, 0.55), 1.5)
	ci.draw_line(a + Vector2(0, -4), a + Vector2(0, 4), Color(INK, 0.55), 1.5)
	ci.draw_line(b + Vector2(0, -4), b + Vector2(0, 4), Color(INK, 0.55), 1.5)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var mid := a.lerp(b, 0.5)
	ci.draw_rect(Rect2(Vector2(mid.x - w * 0.5 - 3, mid.y - fs * 0.6), Vector2(w + 6, fs * 1.1)), PAPER)
	ci.draw_string(font, Vector2(mid.x - w * 0.5, mid.y + fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		ORANGE if hidden else INK)


## A number as the lessons write it: 2,000; 12.5.
static func _num(v: float) -> String:
	return NumberPad.group(str(int(v))) if v == floorf(v) else str(snappedf(v, 0.01))


# --- reflection ----------------------------------------------------------------------------------------------------

## A reflection's points in `r`: {p (where the ray meets the mirror), a (the incident ray's start), b (the reflected
## ray's end), len, fs, mirror_y}.
static func _reflection_geo(r: Rect2, i: int, names: bool) -> Dictionary:
	var fs := _fs(r, 0.08, 10, 18)
	var mirror_y := r.end.y - fs * 1.2
	var p := Vector2(r.get_center().x, mirror_y)
	var ln := minf(mirror_y - r.position.y - fs * (1.6 if names else 0.4), r.size.x * 0.42)
	var ang := deg_to_rad(float(i))
	var a := p + Vector2(-sin(ang), -cos(ang)) * ln
	var b := p + Vector2(sin(ang), -cos(ang)) * ln
	return {"p": p, "a": a, "b": b, "len": ln, "fs": fs, "mirror_y": mirror_y}


static func _draw_reflection(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var i := int(d.i)
	var names := bool(d.get("names", false))
	var g := _reflection_geo(r, i, names)
	var p: Vector2 = g.p
	var ln: float = g.len
	var fs: int = g.fs
	var mirror_y: float = g.mirror_y
	var half_w := minf(r.size.x * 0.46, ln * 1.3)
	# the mirror: a silver line, hatched behind
	ci.draw_line(Vector2(p.x - half_w, mirror_y), Vector2(p.x + half_w, mirror_y), Color("8fa3b8"), 5.0)
	var x := p.x - half_w
	while x < p.x + half_w:
		ci.draw_line(Vector2(x, mirror_y + 3), Vector2(x - 7, mirror_y + 10), GREY, 1.5)
		x += 10.0
	# the normal, dashed
	var ny := p.y - ln * 1.02
	var y := p.y
	while y > ny:
		ci.draw_line(Vector2(p.x, y), Vector2(p.x, maxf(ny, y - 7.0)), Color(INK, 0.6), 2.0)
		y -= 12.0
	# the rays
	var ray_col := Color("e0a800")
	ci.draw_line(g.a, p, ray_col, 3.5, true)
	_head(ci, (g.a as Vector2).lerp(p, 0.55), (p - (g.a as Vector2)).normalized(), 13.0, ray_col)
	ci.draw_line(p, g.b, ray_col, 3.5, true)
	_head(ci, p.lerp(g.b, 0.6), ((g.b as Vector2) - p).normalized(), 13.0, ray_col)
	# the marked angles
	var marks: Array = d.get("marks", ["i", "r"])
	var values := bool(d.get("values", true))
	var unknown := str(d.get("unknown", ""))
	var ang := deg_to_rad(float(i))
	var up := -PI * 0.5
	var arcs := {"i": [up - ang, up], "r": [up, up + ang], "mi": [PI, PI + (PI * 0.5 - ang)], "mr": [-(PI * 0.5 - ang), 0.0],
		"both": [up - ang, up + ang]}
	var rad := {"i": ln * 0.28, "r": ln * 0.28, "mi": ln * 0.22, "mr": ln * 0.22, "both": ln * 0.4}
	for m: Variant in marks:
		var key := str(m)
		var span: Array = arcs[key]
		var rr: float = rad[key]
		var col := ORANGE if key == unknown else BLUE
		ci.draw_arc(p, rr, float(span[0]), float(span[1]), 18, col, 2.5, true)
		if not values and key != unknown:
			continue
		var t := "?" if key == unknown else "%d°" % angle_of(i, key)
		var mid := (float(span[0]) + float(span[1])) * 0.5
		var at := p + Vector2(cos(mid), sin(mid)) * (rr + fs * (1.0 if key != "both" else 0.8))
		if key == "mi" or key == "mr":
			at = p + Vector2(cos(mid), sin(mid)) * (rr + fs * 1.6)
		_text_col(ci, font, at + Vector2(0, fs * 0.35), t, fs, col)
	if names:
		var nfs := maxi(9, fs - 2)
		_text(ci, font, Vector2(p.x, ny - 3.0), "normal", nfs)
		_text(ci, font, Vector2(p.x + half_w * 0.75, mirror_y + nfs * 1.25), "mirror", nfs)
		_text(ci, font, (g.a as Vector2) + Vector2(0, -6.0), "incident ray", nfs)
		_text(ci, font, (g.b as Vector2) + Vector2(0, -6.0), "reflected ray", nfs)


# --- light_device --------------------------------------------------------------------------------------------------

## A device's parts in `r`: periscope {top mirror, bottom mirror, eye, object, tube: Rect2, m (the mirrors' half size)};
## pinhole {pinhole, screen, object, image, box: Rect2, obj_top, obj_bottom, img_top, img_bottom}; and where each part's
## name goes (names: {part: its centre}).
static func _device_geo(r: Rect2, device: String) -> Dictionary:
	var fs := _fs(r, 0.075, 10, 18)
	if device == "periscope":
		var h := r.size.y - fs * 0.4
		var w := minf(h * 0.3, r.size.x * 0.16)
		var tube := Rect2(Vector2(r.get_center().x - w * 0.5, r.position.y + fs * 0.2), Vector2(w, h))
		var top_m := Vector2(tube.get_center().x, tube.position.y + w * 0.7)
		var bot_m := Vector2(tube.get_center().x, tube.end.y - w * 0.7)
		var obj := Vector2(r.position.x + r.size.x * 0.14, top_m.y)
		var eye := Vector2(tube.end.x + r.size.x * 0.16, bot_m.y)
		return {"tube": tube, "m": w * 0.42, "top mirror": top_m, "bottom mirror": bot_m, "fs": fs, "eye": eye,
			"object": obj, "names": {"top mirror": Vector2(tube.end.x + r.size.x * 0.13, top_m.y),
				"bottom mirror": Vector2(tube.position.x - r.size.x * 0.13, bot_m.y),
				"object": Vector2(obj.x, obj.y + fs * 3.2), "eye": Vector2(eye.x, eye.y + fs * 1.9)}}
	var box := Rect2(Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.12),
		Vector2(r.size.x * 0.36, r.size.y * 0.66))
	var hole := Vector2(box.position.x, box.get_center().y)
	var obj_x := r.position.x + r.size.x * 0.1
	var obj_h := box.size.y * 0.72
	var screen_x := box.end.x - 4.0
	var k := (screen_x - hole.x) / (hole.x - obj_x)
	var img_h := obj_h * k
	return {"box": box, "pinhole": hole, "screen": Vector2(screen_x, box.position.y + box.size.y * 0.1), "fs": fs,
		"object": Vector2(obj_x, hole.y), "image": Vector2(screen_x - 3.0, hole.y),
		"obj_top": Vector2(obj_x, hole.y - obj_h * 0.5), "obj_bottom": Vector2(obj_x, hole.y + obj_h * 0.5),
		"img_top": Vector2(screen_x - 3.0, hole.y + img_h * 0.5), "img_bottom": Vector2(screen_x - 3.0, hole.y - img_h * 0.5),
		"names": {"object": Vector2(obj_x, r.end.y - fs * 0.7), "pinhole": Vector2(hole.x, box.position.y - fs * 0.7),
			"screen": Vector2(box.end.x + r.size.x * 0.07, box.position.y + fs * 0.6), "image": Vector2(screen_x - 3.0,
			r.end.y - fs * 0.7)}}


static func _draw_device(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var device := str(d.device)
	var names := bool(d.get("names", false))
	var rays := bool(d.get("rays", true))
	var g := _device_geo(r, device)
	var fs: int = g.fs
	var ray_col := Color("e0a800")
	if device == "periscope":
		var tube: Rect2 = g.tube
		var m: float = g.m
		var top_m: Vector2 = g["top mirror"]
		var bot_m: Vector2 = g["bottom mirror"]
		var gap := tube.size.x * 0.5
		ci.draw_rect(tube, Color("dfe6ef"))
		# the openings: top left and bottom right
		ci.draw_line(tube.position, Vector2(tube.position.x, top_m.y - gap), INK, 3.0)
		ci.draw_line(Vector2(tube.position.x, top_m.y + gap), Vector2(tube.position.x, tube.end.y), INK, 3.0)
		ci.draw_line(Vector2(tube.end.x, tube.position.y), Vector2(tube.end.x, bot_m.y - gap), INK, 3.0)
		ci.draw_line(Vector2(tube.end.x, bot_m.y + gap), tube.end, INK, 3.0)
		ci.draw_line(tube.position, Vector2(tube.end.x, tube.position.y), INK, 3.0)
		ci.draw_line(Vector2(tube.position.x, tube.end.y), tube.end, INK, 3.0)
		# the mirrors at 45°
		for mc: Vector2 in [top_m, bot_m]:
			ci.draw_line(mc + Vector2(-m, -m), mc + Vector2(m, m), Color("8fa3b8"), 6.0, true)
		# a tree to look at, and an eye
		var obj: Vector2 = g.object
		ci.draw_rect(Rect2(obj + Vector2(-fs * 0.2, fs * 0.3), Vector2(fs * 0.4, fs * 1.8)), Color("8a5a2b"))
		ci.draw_circle(obj, fs * 0.9, GREEN)
		_eye(ci, g.eye, fs, true)
		if rays:
			var eye: Vector2 = g.eye
			_arrow(ci, obj + Vector2(fs, 0), top_m, ray_col, 3.0)
			_arrow(ci, top_m, bot_m, ray_col, 3.0)
			_arrow(ci, bot_m, eye + Vector2(-fs * 0.9, 0), ray_col, 3.0)
	else:
		var box: Rect2 = g.box
		var hole: Vector2 = g.pinhole
		var screen: Vector2 = g.screen
		ci.draw_rect(box, Color("cfd5df"))
		ci.draw_rect(Rect2(Vector2(screen.x - 2.0, box.position.y + 3.0), Vector2(6.0, box.size.y - 6.0)), Color("fbf7ea"))
		ci.draw_rect(box, INK, false, 3.0)
		ci.draw_rect(Rect2(hole - Vector2(2, 3), Vector2(4, 6)), Color("cfd5df"))
		ci.draw_circle(hole, 2.5, INK)
		var ot: Vector2 = g.obj_top
		var ob: Vector2 = g.obj_bottom
		var it: Vector2 = g.img_top
		var ib: Vector2 = g.img_bottom
		_candle(ci, ob, ot, fs)
		_candle(ci, ib, it, fs * 0.8)   # upside down: the flame's light lands low on the screen
		if rays:
			ci.draw_line(ot + Vector2(0, fs * 0.3), it, ray_col, 2.5, true)
			ci.draw_line(ob, ib, Color("c9a74a"), 2.5, true)
	if names:
		var nfs := maxi(9, fs - 1)
		var at_of: Dictionary = g.names
		for part: Variant in DEVICE_PARTS[device]:
			var at: Vector2 = at_of[str(part)]
			var t := str(part)
			var size := _fit(font, t, r.size.x * 0.24, nfs)
			_text(ci, font, Vector2(at.x, at.y + size * 0.35), t, size)
			if device == "periscope" and t.ends_with("mirror"):
				var target: Vector2 = g[t]
				var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
				var from := Vector2(at.x + (-tw * 0.5 - 3.0 if at.x > target.x else tw * 0.5 + 3.0), at.y)
				ci.draw_line(from, target, Color(INK, 0.5), 1.5, true)


static func _eye(ci: CanvasItem, c: Vector2, fs: float, left: bool) -> void:
	ci.draw_colored_polygon(_ellipse(c, fs * 0.8, fs * 0.45), Color.WHITE)
	ci.draw_arc(c, fs * 0.8, 0, TAU, 20, INK, 1.5, true)
	ci.draw_circle(c + Vector2(-fs * 0.3 if left else fs * 0.3, 0), fs * 0.25, INK)


## A candle standing from `base` to `tip` (upside down when the tip is below the base).
static func _candle(ci: CanvasItem, base: Vector2, tip: Vector2, fs: float) -> void:
	var w := maxf(6.0, fs * 0.55)
	var dir := (tip - base).normalized()
	var wick := base.lerp(tip, 0.7)
	ci.draw_line(base, wick, Color("f6efdc"), w, true)
	ci.draw_line(base + Vector2(w * 0.5, 0), wick + Vector2(w * 0.5, 0), BONE_EDGE, 1.0)
	ci.draw_line(base - Vector2(w * 0.5, 0), wick - Vector2(w * 0.5, 0), BONE_EDGE, 1.0)
	var flame := wick.lerp(tip, 0.55)
	ci.draw_colored_polygon(_ellipse(flame, w * 0.5, absf((tip - wick).y) * 0.5 + 1.0), ORANGE)
	ci.draw_circle(flame - dir * 2.0, w * 0.22, YELLOW)


# --- energy_chain --------------------------------------------------------------------------------------------------

static func _draw_chain(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var steps: Array = d.steps
	var n := steps.size()
	var things: Array = d.get("things", [])
	var wasted: Array = d.get("wasted", [])
	var fs := _fs(r, 0.075, 9, 18)
	var gap := r.size.x * 0.06
	var bw := (r.size.x - gap * (n - 1)) / n
	var bottom_room := (fs * 1.4 if not things.is_empty() else 0.0) + (fs * 2.4 if not wasted.is_empty() else 0.0)
	var bh := minf(r.size.y - bottom_room, bw * 1.05)
	var y0 := r.position.y + (r.size.y - bottom_room - bh) * 0.5
	for i in n:
		var box := Rect2(Vector2(r.position.x + (bw + gap) * i, y0), Vector2(bw, bh))
		var form := str(steps[i])
		var hidden := d.has("hide") and int(d.hide) == i
		ci.draw_rect(box, Color("eeeeee") if hidden else FORM_COLOURS[form])
		ci.draw_rect(box, ORANGE if d.has("mark") and int(d.mark) == i else INK, false, 3.0 if d.has("mark") and int(d.mark) == i else 2.0)
		var word := "?" if hidden else form
		var wfs := _fit(font, word, bw - 6.0, fs)
		if not hidden:
			var icon := Rect2(box.position + Vector2(bw * 0.2, bh * 0.08), Vector2(bw * 0.6, bh * 0.6))
			var side := minf(icon.size.x, icon.size.y)
			_form_icon(ci, Rect2(icon.get_center() - Vector2(side, side) * 0.5, Vector2(side, side)), form)
		_text_col(ci, font, Vector2(box.get_center().x, box.end.y - bh * 0.1 if not hidden else box.get_center().y + wfs * 0.4),
			word, wfs if not hidden else fs * 2, ORANGE if hidden else INK)
		if i < n - 1:
			_arrow(ci, Vector2(box.end.x + 2, box.get_center().y), Vector2(box.end.x + gap - 2, box.get_center().y), INK, 3.0)
		if not things.is_empty():
			var t := str(things[i])
			_text(ci, font, Vector2(box.get_center().x, box.end.y + fs * 1.15), t, _fit(font, t, bw + gap * 0.8, fs))
	if not wasted.is_empty():
		var last := Rect2(Vector2(r.position.x + (bw + gap) * (n - 1), y0), Vector2(bw, bh))
		for k in wasted.size():
			var from := Vector2(last.position.x + bw * (0.3 + 0.4 * k), last.end.y + (fs * 1.4 if not things.is_empty() else 2.0))
			var to := from + Vector2(-bw * 0.2, fs * 1.1)
			_arrow(ci, from, to, GREY, 2.0)
			_text_col(ci, font, to + Vector2(-fs * 0.2, fs * 0.9), str(wasted[k]), maxi(8, fs - 3), Color(INK, 0.7))


static func _form_icon(ci: CanvasItem, b: Rect2, form: String) -> void:
	var c := b.get_center()
	var s := b.size.x
	match form:
		"chemical":   # a battery
			var body := Rect2(c - Vector2(s * 0.3, s * 0.16), Vector2(s * 0.6, s * 0.32))
			ci.draw_rect(body, Color("3d4454"))
			ci.draw_rect(Rect2(Vector2(body.end.x, c.y - s * 0.07), Vector2(s * 0.07, s * 0.14)), Color("3d4454"))
			ci.draw_rect(Rect2(body.position, Vector2(s * 0.2, body.size.y)), Color("d98c2b"))
		"electrical":   # a lightning bolt
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.08, -s * 0.4), c + Vector2(-s * 0.2, s * 0.05),
				c + Vector2(-s * 0.02, s * 0.05), c + Vector2(-s * 0.1, s * 0.4), c + Vector2(s * 0.22, -s * 0.08),
				c + Vector2(s * 0.03, -s * 0.08)]), Color("e0a800"))
		"kinetic":   # a rolling ball and its speed lines
			ci.draw_circle(c + Vector2(s * 0.12, 0), s * 0.22, BLUE)
			for k in 3:
				ci.draw_line(c + Vector2(-s * 0.42, (k - 1) * s * 0.13), c + Vector2(-s * 0.16, (k - 1) * s * 0.13), INK, 2.0)
		"light":   # a sun
			ci.draw_circle(c, s * 0.18, Color("f2b632"))
			for k in 8:
				var ang := TAU * k / 8.0
				ci.draw_line(c + Vector2(cos(ang), sin(ang)) * s * 0.25, c + Vector2(cos(ang), sin(ang)) * s * 0.4,
					Color("f2b632"), 2.5)
		"sound":   # a loudspeaker and waves
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.35, -s * 0.1), c + Vector2(-s * 0.2, -s * 0.1),
				c + Vector2(-s * 0.02, -s * 0.28), c + Vector2(-s * 0.02, s * 0.28), c + Vector2(-s * 0.2, s * 0.1),
				c + Vector2(-s * 0.35, s * 0.1)]), INK)
			for k in 2:
				ci.draw_arc(c + Vector2(-s * 0.02, 0), s * (0.16 + 0.14 * k), -0.8, 0.8, 12, INK, 2.0, true)
		"heat":   # a flame
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.4), c + Vector2(s * 0.24, s * 0.05),
				c + Vector2(s * 0.18, s * 0.3), c + Vector2(-s * 0.18, s * 0.3), c + Vector2(-s * 0.24, s * 0.05)]),
				Color("e8551f"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.1), c + Vector2(s * 0.12, s * 0.12),
				c + Vector2(s * 0.08, s * 0.28), c + Vector2(-s * 0.08, s * 0.28), c + Vector2(-s * 0.12, s * 0.12)]),
				YELLOW)
		"gravitational":   # a ball up high over the ground, an arrow down
			ci.draw_line(c + Vector2(-s * 0.4, s * 0.38), c + Vector2(s * 0.4, s * 0.38), INK, 2.5)
			ci.draw_circle(c + Vector2(0, -s * 0.26), s * 0.13, Color("7b8494"))
			_arrow(ci, c + Vector2(0, -s * 0.08), c + Vector2(0, s * 0.3), INK, 2.0)
		"elastic":   # a spring
			var pts := PackedVector2Array()
			for k in 11:
				pts.append(c + Vector2((-0.4 + 0.08 * k) * s, (s * 0.18 if k % 2 == 0 else -s * 0.18) if k > 0 and k < 10 else 0.0))
			ci.draw_polyline(pts, Color("b0306a"), 2.5, true)


# --- sankey --------------------------------------------------------------------------------------------------------

static func _draw_sankey(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var total := float(d.total)
	var useful: Array = d.useful
	var wasted: Array = d.wasted
	var unit := str(d.get("unit", "J"))
	var hide := int(d.get("hide", -1))
	var fs := _fs(r, 0.075, 9, 18)
	var top := r.position.y + (fs * 1.5 if d.has("name") else 2.0)
	var band := minf(r.size.y * 0.4, (r.end.y - top) * 0.45)
	var k := band / total
	var x0 := r.position.x + r.size.x * 0.2
	var split := r.position.x + r.size.x * 0.42
	var end_x := r.end.x - r.size.x * 0.27
	var yellow := Color("f5d547")
	var green := Color("5cb85c")
	var grey := Color("aab1bd")
	var value := func(v: float, idx: int) -> String: return "?" if idx == hide else "%s %s" % [_num(v), unit]
	if d.has("name"):
		_text(ci, font, Vector2(r.get_center().x, r.position.y + fs), str(d.name), fs)
	# what goes in
	ci.draw_rect(Rect2(Vector2(x0, top), Vector2(split - x0, band)), yellow)
	var in_t: String = value.call(total, 0)
	var in_fs := _fit(font, in_t, x0 - r.position.x - 6.0, fs)
	var in_w := font.get_string_size(in_t, HORIZONTAL_ALIGNMENT_LEFT, -1, in_fs).x
	ci.draw_string(font, Vector2(x0 - in_w - 4.0, top + band * 0.5 + in_fs * 0.35), in_t, HORIZONTAL_ALIGNMENT_LEFT, -1,
		in_fs, ORANGE if hide == 0 else INK)
	# the useful energy goes straight on
	var y := top
	var idx := 1
	for u: Variant in useful:
		var h := float(u[1]) * k
		var shade := green if idx % 2 == 1 else green.darkened(0.25)
		ci.draw_rect(Rect2(Vector2(split, y), Vector2(end_x - split, h)), shade)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(end_x, y), Vector2(end_x + maxf(h * 0.5, 6.0), y + h * 0.5),
			Vector2(end_x, y + h)]), shade)
		var t := "%s: %s" % [u[0], value.call(float(u[1]), idx)]
		var tx := end_x + maxf(h * 0.5, 6.0) + 5.0
		var tfs := _fit(font, t, r.end.x - tx, fs)
		ci.draw_string(font, Vector2(tx, y + h * 0.5 + tfs * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs,
			ORANGE if idx == hide else INK)
		y += h
		idx += 1
	# the wasted energy bends down, the bends round one centre (the lowest band innermost)
	var turn := Vector2(split + r.size.x * 0.1, top + band + fs * 0.8)
	var bottom := r.end.y - fs * 0.9
	var inner := fs * 0.8
	var bands: Array = []
	for w: Variant in wasted:
		bands.append([str(w[0]), float(w[1]), idx, y])
		y += float(w[1]) * k
		idx += 1
	bands.reverse()
	for bd: Array in bands:
		var h: float = float(bd[1]) * k
		var ya: float = bd[3]
		var shape := PackedVector2Array([Vector2(split, ya)])
		for s in 11:
			var a := -PI * 0.5 + PI * 0.5 * s / 10.0
			shape.append(turn + Vector2(cos(a), sin(a)) * (inner + h))
		shape.append(Vector2(turn.x + inner + h, bottom - fs * 0.6))
		shape.append(Vector2(turn.x + inner + h * 0.5 + fs * 0.4, bottom - fs * 0.6))
		shape.append(Vector2(turn.x + inner + h * 0.5, bottom))
		shape.append(Vector2(turn.x + inner + h * 0.5 - fs * 0.4, bottom - fs * 0.6))
		shape.append(Vector2(turn.x + inner, bottom - fs * 0.6))
		for s in 11:
			var a := -PI * 0.5 * s / 10.0
			shape.append(turn + Vector2(cos(a), sin(a)) * inner)
		shape.append(Vector2(split, ya + h))
		ci.draw_colored_polygon(shape, grey if int(bd[2]) % 2 == 0 else grey.darkened(0.2))
		var t := "%s: %s" % [bd[0], value.call(float(bd[1]), int(bd[2]))]
		var first: bool = bd == bands[0]
		var mid_y := (turn.y + bottom) * 0.5 + (fs * 0.6 if first else -fs * 0.6)
		var room := (turn.x + inner - r.position.x - 8.0) if first else (r.end.x - turn.x - inner - h - 8.0)
		var tfs := _fit(font, t, room, fs)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x
		var tx := turn.x + inner - tw - 6.0 if first else turn.x + inner + h + 6.0
		ci.draw_string(font, Vector2(tx, mid_y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, ORANGE if int(bd[2]) == hide else INK)
		inner += h


# --- op_chain ------------------------------------------------------------------------------------------------------

static func _draw_ops(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var ops: Array = d.ops
	var back := bool(d.get("back", false))
	var n := ops.size() + 2
	var fs := _fs(r, 0.1, 10, 22)
	var gap := r.size.x * 0.045
	var bw := (r.size.x - gap * (n - 1)) / n
	var bh := minf(r.size.y * (0.36 if back else 0.5), fs * 2.4)
	var y1 := r.position.y + (r.size.y * (0.3 if back else 0.5)) - bh * 0.5
	var texts: Array = [str(d.start)]
	for o: Variant in ops:
		texts.append(str(o))
	texts.append(str(d.end))
	for i in n:
		var box := Rect2(Vector2(r.position.x + (bw + gap) * i, y1), Vector2(bw, bh))
		var t := str(texts[i])
		var is_end := i == 0 or i == n - 1
		if is_end:
			ci.draw_colored_polygon(_ellipse(box.get_center(), bw * 0.5, bh * 0.5), Color("e9f7e6") if t != "?" else Color("fff1dc"))
			_outline_ellipse(ci, box.get_center(), bw * 0.5, bh * 0.5, ORANGE if t == "?" else GREEN)
		else:
			ci.draw_rect(box, Color("e8f0ff"))
			ci.draw_rect(box, BLUE, false, 2.0)
		_text_col(ci, font, Vector2(box.get_center().x, box.get_center().y + fs * 0.35), t, _fit(font, t, bw - 6.0, fs),
			ORANGE if t == "?" else INK)
		if i < n - 1:
			_arrow(ci, Vector2(box.end.x + 1, box.get_center().y), Vector2(box.end.x + gap - 1, box.get_center().y), INK, 2.5)
	if not back:
		return
	var y2 := r.position.y + r.size.y * 0.74 - bh * 0.5
	for i in range(1, n - 1):
		var box := Rect2(Vector2(r.position.x + (bw + gap) * i, y2), Vector2(bw, bh))
		var t := inverse_op(str(ops[i - 1]))
		ci.draw_rect(box, Color("fff1dc"))
		ci.draw_rect(box, ORANGE, false, 2.0)
		_text(ci, font, Vector2(box.get_center().x, box.get_center().y + fs * 0.35), t, _fit(font, t, bw - 6.0, fs))
	for i in range(1, n):
		var right_box := Rect2(Vector2(r.position.x + (bw + gap) * i, y2), Vector2(bw, bh))
		if i == n - 1:
			right_box = Rect2(Vector2(r.position.x + (bw + gap) * i, y1), Vector2(bw, bh))
			_arrow(ci, Vector2(right_box.get_center().x, right_box.end.y + 2), Vector2(right_box.get_center().x - bw * 0.3,
				y2 + bh * 0.5), ORANGE, 2.5)
			_arrow(ci, Vector2(right_box.get_center().x - bw * 0.3, y2 + bh * 0.5), Vector2(right_box.position.x - 1,
				y2 + bh * 0.5), ORANGE, 2.5)
		else:
			_arrow(ci, Vector2(right_box.position.x - 1, y2 + bh * 0.5), Vector2(right_box.position.x - gap + 1, y2 + bh * 0.5),
				ORANGE, 2.5)
	_text_col(ci, font, Vector2(r.position.x + bw * 0.5, y2 + bh * 0.5 + fs * 0.35), "back", fs, ORANGE)


static func _outline_ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := _ellipse(c, rx, ry)
	pts.append(pts[0])
	ci.draw_polyline(pts, col, 2.5, true)


# --- handshakes ----------------------------------------------------------------------------------------------------

static func _draw_handshakes(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var n := int(d.n)
	var fs := _fs(r, 0.08, 10, 20)
	var c := r.get_center()
	var rad := minf(r.size.y * 0.5 - fs * 1.4, r.size.x * 0.3)
	var pts: Array[Vector2] = []
	for i in n:
		var a := -PI * 0.5 + TAU * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	if bool(d.get("lines", true)):
		for i in n:
			for j in range(i + 1, n):
				ci.draw_line(pts[i], pts[j], Color(BLUE, 0.75), 2.0, true)
	var names: Array = d.get("names", [])
	var person := maxf(8.0, fs * 0.8)
	var skins: Array[Color] = [Color("f1c9a5"), Color("c68a5b"), Color("8d5a3b"), Color("f3d6b8"), Color("a86b43")]
	for i in n:
		ci.draw_circle(pts[i], person, skins[i % skins.size()])
		ci.draw_arc(pts[i], person, 0, TAU, 20, INK, 2.0, true)
		ci.draw_circle(pts[i] + Vector2(-person * 0.35, -person * 0.15), person * 0.12, INK)
		ci.draw_circle(pts[i] + Vector2(person * 0.35, -person * 0.15), person * 0.12, INK)
		ci.draw_arc(pts[i] + Vector2(0, person * 0.1), person * 0.4, 0.3, PI - 0.3, 8, INK, 1.5, true)
		if not names.is_empty():
			var out := (pts[i] - c).normalized()
			var tw := font.get_string_size(str(names[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var at := pts[i] + out * (person + 5.0 + absf(out.x) * tw * 0.5 + absf(out.y) * fs * 0.45)
			_text(ci, font, at + Vector2(0, fs * 0.35), str(names[i]), fs)
	if bool(d.get("count", false)):
		var t := str(handshake_count(n))
		ci.draw_circle(c, fs * 1.1, PAPER)
		_text_col(ci, font, c + Vector2(0, fs * 0.4), t, fs + 2, ORANGE)


# --- argument_map --------------------------------------------------------------------------------------------------

## An argument map's boxes in `r`, by part: {claim, reason (the first), reasons: [Rect2], evidence (the first),
## evidences: [Rect2], counterclaim, rebuttal}; untitled maps leave room at both sides for label pins.
static func _argument_boxes(p: Dictionary, r: Rect2) -> Dictionary:
	if not bool(p.get("titles", true)):   # untitled, for labelling: room at both sides for the pins
		r = r.grow_individual(-r.size.x * 0.12, 0, -r.size.x * 0.12, 0)
	var reasons: Array = p.get("reasons", [])
	var ev := p.has("evidence")
	var ct := p.has("counter")
	var rows := 2 + (1 if ev else 0) + (1 if ct else 0)
	var gap := r.size.y * 0.06
	var h := (r.size.y - gap * (rows - 1)) / rows
	var out := {}
	out.claim = Rect2(Vector2(r.position.x + r.size.x * 0.15, r.position.y), Vector2(r.size.x * 0.7, h))
	var n := maxi(1, reasons.size())
	var w := (r.size.x - gap * (n - 1)) / n
	var rs: Array[Rect2] = []
	var es: Array[Rect2] = []
	for i in n:
		rs.append(Rect2(Vector2(r.position.x + (w + gap) * i, r.position.y + h + gap), Vector2(w, h)))
		if ev:
			es.append(Rect2(Vector2(r.position.x + (w + gap) * i, r.position.y + (h + gap) * 2), Vector2(w, h)))
	out.reasons = rs
	out.reason = rs[0]
	if ev:
		out.evidences = es
		out.evidence = es[0]
	if ct:
		var y := r.position.y + (h + gap) * (rows - 1)
		var half := (r.size.x - gap) * 0.5
		out.counterclaim = Rect2(Vector2(r.position.x, y), Vector2(half if p.has("rebuttal") else r.size.x, h))
		if p.has("rebuttal"):
			out.rebuttal = Rect2(Vector2(r.position.x + half + gap, y), Vector2(half, h))
	return out


static func _draw_argument(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var boxes := _argument_boxes(d, r)
	var titles := bool(d.get("titles", true))
	var mark := str(d.get("mark", ""))
	var claim: Rect2 = boxes.claim
	var fs := clampi(int(claim.size.y * 0.34), 9, 18)
	var reasons: Array = d.reasons
	var rs: Array = boxes.reasons
	for i in rs.size():
		var rb: Rect2 = rs[i]
		ci.draw_line(Vector2(claim.get_center().x, claim.end.y), Vector2(rb.get_center().x, rb.position.y), Color(INK, 0.5), 2.0)
		if boxes.has("evidences"):
			var eb: Rect2 = (boxes.evidences as Array)[i]
			ci.draw_line(Vector2(rb.get_center().x, rb.end.y), Vector2(eb.get_center().x, eb.position.y), Color(INK, 0.5), 2.0)
	_arg_box(ci, font, claim, "CLAIM" if titles else "", str(d.claim), Color("dce9ff"), fs, mark == "claim")
	for i in rs.size():
		_arg_box(ci, font, rs[i], "REASON" if titles else "", str(reasons[i]), Color("e9f7e6"), fs, mark == "reason")
		if boxes.has("evidences"):
			_arg_box(ci, font, (boxes.evidences as Array)[i], "EVIDENCE" if titles else "", str(d.evidence[i]),
				Color("fff6d6"), fs, mark == "evidence")
	if boxes.has("counterclaim"):
		_arg_box(ci, font, boxes.counterclaim, "COUNTERCLAIM" if titles else "", str(d.counter), Color("fde4e1"), fs,
			mark == "counterclaim")
	if boxes.has("rebuttal"):
		var cb: Rect2 = boxes.counterclaim
		var rb2: Rect2 = boxes.rebuttal
		_arg_box(ci, font, rb2, "REBUTTAL" if titles else "", str(d.rebuttal), Color("efe3fb"), fs, mark == "rebuttal")
		_arrow(ci, Vector2(cb.end.x + 1, cb.get_center().y), Vector2(rb2.position.x - 1, rb2.get_center().y), INK, 2.0)


static func _arg_box(ci: CanvasItem, font: Font, box: Rect2, title: String, text: String, col: Color, fs: int,
		marked: bool) -> void:
	ci.draw_rect(box, col)
	ci.draw_rect(box, ORANGE if marked else INK, false, 3.0 if marked else 1.5)
	var inner := box.grow(-4)
	if title != "":
		var tfs := maxi(9, int(fs * 0.72))
		ci.draw_string(font, inner.position + Vector2(0, tfs), title, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, Color(INK, 0.6))
		inner = inner.grow_individual(0, -tfs * 1.05, 0, 0)
	_box_text(ci, font, inner, text, fs, INK)


# --- story_arc -----------------------------------------------------------------------------------------------------

## The arc's plot area in `r` and its five stages' points (their names go under the time line).
static func _arc_points(r: Rect2) -> Array[Vector2]:
	var fs := _fs(r, 0.075, 9, 18)
	var plot := r.grow_individual(-fs * 1.4, -fs * 1.3, -fs * 0.5, -fs * 3.4)
	var out: Array[Vector2] = []
	for s: Array in STAGE_AT:
		out.append(Vector2(plot.position.x + plot.size.x * float(s[0]), plot.end.y - plot.size.y * float(s[1])))
	return out


static func _draw_arc(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 0.075, 9, 18)
	var pts := _arc_points(r)
	var base_y := r.end.y - fs * 3.4 + 6.0
	var ax := r.position.x + fs * 0.7
	_arrow(ci, Vector2(ax, base_y), Vector2(ax, r.position.y + 2), INK, 2.0)
	_arrow(ci, Vector2(ax, base_y), Vector2(r.end.x - 2, base_y), INK, 2.0)
	var sfs := maxi(8, fs - 3)
	ci.draw_string(font, Vector2(ax + 6.0, r.position.y + sfs), "tension", HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, Color(INK, 0.6))
	var tw := font.get_string_size("time", HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x
	ci.draw_string(font, Vector2(r.end.x - tw - 4.0, base_y - 5.0), "time", HORIZONTAL_ALIGNMENT_LEFT, -1, sfs,
		Color(INK, 0.6))
	var line := PackedVector2Array([Vector2(ax + 2.0, base_y - 3.0)])
	for i in pts.size() - 1:
		for k in 8:
			var t := k / 8.0
			line.append(pts[i].lerp(pts[i + 1], t) + Vector2(0, -sin(t * PI) * 4.0))
	line.append(pts[-1])
	line.append(Vector2(r.end.x - fs * 1.4, pts[-1].y + 1.0))
	var names := bool(d.get("names", true))
	var hide := str(d.get("hide", ""))
	var mark := str(d.get("mark", ""))
	var events: Array = d.get("events", [])
	var room := (pts[1].x - pts[0].x) * 0.94
	var name_fs := fs
	for stage: String in STAGES:
		name_fs = mini(name_fs, _fit(font, stage, room, fs))
	for i in STAGES.size():   # dashed drops from each stage to the time line, under the arc
		var y := pts[i].y + fs * 0.5
		while y < base_y - 2.0:
			ci.draw_line(Vector2(pts[i].x, y), Vector2(pts[i].x, minf(y + 4.0, base_y - 2.0)), Color(INK, 0.35), 1.5)
			y += 8.0
	ci.draw_polyline(line, RED, 3.0, true)
	for i in STAGES.size():
		var stage := STAGES[i]
		var col := ORANGE if stage == mark or stage == hide else INK
		if bool(d.get("dots", true)) or stage == mark:
			ci.draw_circle(pts[i], fs * 0.4, col)
		if names:
			var t := "?" if stage == hide else stage
			var size := name_fs
			_text_col(ci, font, Vector2(_clamp_x(font, t, size, pts[i].x, r), base_y + fs * 1.35), t, size, col)
		if not events.is_empty() and str(events[i]) != "":
			var e := str(events[i])
			var size := _fit(font, e, room, sfs)
			_text_col(ci, font, Vector2(_clamp_x(font, e, size, pts[i].x, r), base_y + fs * 1.35 + sfs * 1.25), e, size,
				Color(INK, 0.75))


## `x` moved in so that `text` centred on it stays inside `r`.
static func _clamp_x(font: Font, text: String, fs: int, x: float, r: Rect2) -> float:
	var half := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 0.5
	return clampf(x, r.position.x + half, r.end.x - half)


# --- info_page -----------------------------------------------------------------------------------------------------

## The page's features in `r` (the page itself narrower when the features are named beside it, or labelled with
## pins): {page, title, introduction, subheading, diagram, caption, glossary}.
static func _page_boxes(r: Rect2, names: bool) -> Dictionary:
	var w := r.size.x * (0.5 if names else 0.56)
	var page := Rect2(Vector2(r.get_center().x - w * 0.5, r.position.y), Vector2(w, r.size.y))
	var in_ := page.grow(-page.size.x * 0.05)
	var h := in_.size.y
	var out := {"page": page}
	out.title = Rect2(in_.position, Vector2(in_.size.x, h * 0.14))
	out.introduction = Rect2(in_.position + Vector2(0, h * 0.17), Vector2(in_.size.x, h * 0.14))
	out.subheading = Rect2(in_.position + Vector2(0, h * 0.35), Vector2(in_.size.x * 0.52, h * 0.1))
	out.diagram = Rect2(in_.position + Vector2(in_.size.x * 0.56, h * 0.34), Vector2(in_.size.x * 0.44, h * 0.3))
	out.caption = Rect2(in_.position + Vector2(in_.size.x * 0.56, h * 0.65), Vector2(in_.size.x * 0.44, h * 0.08))
	out.glossary = Rect2(in_.position + Vector2(0, h * 0.77), Vector2(in_.size.x, h * 0.23))
	return out


static func _draw_page(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var names := bool(d.get("names", false))
	var b := _page_boxes(r, names)
	var page: Rect2 = b.page
	var mark := str(d.get("mark", ""))
	ci.draw_rect(page, Color.WHITE)
	ci.draw_rect(page, GREY, false, 2.0)
	var title: Rect2 = b.title
	var tfs := _fit(font, str(d.title), title.size.x, clampi(int(title.size.y * 0.8), 9, 24))
	_text(ci, font, Vector2(title.get_center().x, title.end.y - title.size.y * 0.15), str(d.title), tfs)
	var intro: Rect2 = b.introduction
	for k in 3:
		var ly := intro.position.y + intro.size.y * (0.2 + 0.32 * k)
		ci.draw_line(Vector2(intro.position.x, ly), Vector2(intro.position.x + intro.size.x * (0.96 if k < 2 else 0.6), ly),
			Color(GREY, 0.8), 3.0)
	var sub: Rect2 = b.subheading
	var hfs := _fit(font, str(d.heading), sub.size.x, clampi(int(sub.size.y * 0.85), 8, 18))
	ci.draw_string(font, Vector2(sub.position.x, sub.end.y - sub.size.y * 0.15), str(d.heading), HORIZONTAL_ALIGNMENT_LEFT,
		-1, hfs, BLUE)
	for k in 4:
		var ly := sub.end.y + sub.size.y * (0.6 + 0.62 * k)
		ci.draw_line(Vector2(sub.position.x, ly), Vector2(sub.position.x + sub.size.x * (0.98 if k < 3 else 0.7), ly),
			Color(GREY, 0.8), 3.0)
	var dg: Rect2 = b.diagram
	ci.draw_rect(dg, Color("eef6ff"))
	ci.draw_rect(dg, INK, false, 1.5)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(dg.position.x + dg.size.x * 0.1, dg.end.y - 3),
		Vector2(dg.get_center().x, dg.position.y + dg.size.y * 0.25), Vector2(dg.end.x - dg.size.x * 0.1, dg.end.y - 3)]),
		Color("9c7a5b"))
	ci.draw_circle(Vector2(dg.get_center().x, dg.position.y + dg.size.y * 0.2), dg.size.y * 0.1, ORANGE)
	var cap: Rect2 = b.caption
	var cfs := _fit(font, str(d.caption), cap.size.x, clampi(int(cap.size.y * 0.9), 7, 14))
	_text_col(ci, font, Vector2(cap.get_center().x, cap.end.y - cap.size.y * 0.15), str(d.caption), cfs, Color(INK, 0.75))
	var gl: Rect2 = b.glossary
	ci.draw_rect(gl, Color("fff6d6"))
	ci.draw_rect(gl, Color("c9a74a"), false, 1.5)
	var gfs := clampi(int(gl.size.y * 0.3), 7, 14)
	ci.draw_string(font, gl.position + Vector2(4, gfs + 2), "Glossary", HORIZONTAL_ALIGNMENT_LEFT, -1, gfs, INK)
	var words: Array = d.get("glossary", [])
	var line := ", ".join(PackedStringArray(words.map(func(w: Variant) -> String: return str(w))))
	if line != "":
		ci.draw_string(font, gl.position + Vector2(4, gfs * 2.3 + 2), line, HORIZONTAL_ALIGNMENT_LEFT, gl.size.x - 8, _fit(font,
			line, gl.size.x - 8, gfs), Color(INK, 0.8))
	if PAGE_PARTS.has(mark):
		ci.draw_rect((b[mark] as Rect2).grow(3), ORANGE, false, 3.0)
	if names:
		var fs := _fs(r, 0.07, 9, 16)
		for part: String in PAGE_PARTS:
			var box: Rect2 = b[part]
			var left := part in ["title", "introduction", "subheading"]
			var at := Vector2(box.position.x - 2.0 if left else box.end.x + 2.0, box.get_center().y)
			if part == "glossary":
				left = true
				at = Vector2(box.position.x - 2.0, box.get_center().y)
			var edge := page.position.x - 6.0 if left else page.end.x + 6.0
			var tw := font.get_string_size(part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			ci.draw_line(Vector2(edge, at.y), at, Color(INK, 0.5), 1.5)
			ci.draw_string(font, Vector2(edge - tw - 3.0 if left else edge + 3.0, at.y + fs * 0.35), part,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


# --- helpers -------------------------------------------------------------------------------------------------------

static func _ellipse(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## A muscle's shape from `a` to `b`: thick in the middle, thin at the ends.
static func _spindle(a: Vector2, b: Vector2, thick: float) -> PackedVector2Array:
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array()
	var n := 16
	for k in n + 1:
		var t := float(k) / n
		pts.append(a.lerp(b, t) + side * thick * 0.5 * sin(t * PI))
	for k in range(n, -1, -1):
		var t := float(k) / n
		pts.append(a.lerp(b, t) - side * thick * 0.5 * sin(t * PI))
	return pts


## The font size (at most `fs`) at which `text` fits `width`.
static func _fit(font: Font, text: String, width: float, fs: int) -> int:
	var size := fs
	while size > 7 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		size -= 1
	return size


## `text` broken into lines no wider than `width` at `fs`.
static func _wrap(font: Font, text: String, width: float, fs: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for word in text.split(" ", false):
		var trial := word if line == "" else line + " " + word
		if line != "" and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width:
			lines.append(line)
			line = word
		else:
			line = trial
	if line != "":
		lines.append(line)
	return lines


## `text` wrapped into `box`, as big as fits (at most `fs`), centred.
static func _box_text(ci: CanvasItem, font: Font, box: Rect2, text: String, fs: int, col: Color) -> void:
	var size := fs
	var lines := _wrap(font, text, box.size.x, size)
	while size > 7:
		lines = _wrap(font, text, box.size.x, size)
		var widest := 0.0
		for l in lines:
			widest = maxf(widest, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
		if lines.size() * size * 1.1 <= box.size.y and widest <= box.size.x:
			break
		size -= 1
	var y := box.get_center().y - lines.size() * size * 1.1 * 0.5 + size * 0.85
	for l in lines:
		_text_col(ci, font, Vector2(box.get_center().x, y), l, size, col)
		y += size * 1.1


## A straight arrow from `a` to `b`, its head at `b`.
static func _arrow(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var dir := (b - a).normalized()
	if dir == Vector2.ZERO:
		return
	var head := w * 3.2
	ci.draw_line(a, b - dir * head * 0.8, col, w, true)
	_head(ci, b, dir, head, col)


static func _head(ci: CanvasItem, tip: Vector2, dir: Vector2, size: float, col: Color) -> void:
	var side := Vector2(-dir.y, dir.x) * size * 0.55
	ci.draw_colored_polygon(PackedVector2Array([tip, tip - dir * size + side, tip - dir * size - side]), col)


static func _text(ci: CanvasItem, font: Font, center_base: Vector2, text: String, fs: int) -> void:
	_text_col(ci, font, center_base, text, fs, INK)


static func _text_col(ci: CanvasItem, font: Font, center_base: Vector2, text: String, fs: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(font, Vector2(center_base.x - w * 0.5, center_base.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
