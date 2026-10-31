extends GutTest
## Owner #70 and #73, grade 6 computing, art and music (research §6.6): the picture kinds they add (SchoolPictureG6Arts,
## drawn inside SchoolPicture): binary cards, colours of light, logic gates, the inside of a computer, a trick email, a
## game's privacy settings, a computer's training examples, the principles of design, an illuminated letter, an Islamic
## star, a Chinese landscape scroll, tessellations, rotating patterns, two-point perspective, feelings in art, a layered
## print, capitals built from strokes, handwriting's guide lines, land art, three famous paintings to analyse, key
## signatures, the 12-bar blues, finger numbers on a keyboard, instruments of the world and a decibel scale. Every kind
## draws from its data at the School's picture sizes; broken data is a problem the content test finds; the pictures'
## facts are worked out (binary values, gates, key signatures, the blues' chords, where the parts are).

const SAMPLES: Array[Dictionary] = [
	{"kind": "bit_cards", "bits": "10110", "total": true},
	{"kind": "bit_cards", "bits": "11111111", "values": true},
	{"kind": "bit_cards", "bits": "0101", "values": false},
	{"kind": "rgb_mix", "r": 255, "g": 200, "b": 0},
	{"kind": "rgb_mix", "r": 255, "g": 255, "b": 255, "view": "lights"},
	{"kind": "rgb_mix", "r": 255, "g": 0, "b": 255, "view": "lights"},
	{"kind": "logic_gate", "gate": "AND", "inputs": [1, 0]},
	{"kind": "logic_gate", "gate": "OR", "inputs": [0, 1], "out": false, "names": ["key", "gem"]},
	{"kind": "logic_gate", "gate": "NOT", "inputs": [1]},
	{"kind": "logic_gate", "gate": "AND", "inputs": [1, 1], "then": "NOT"},
	{"kind": "computer_parts", "labels": true},
	{"kind": "computer_parts", "mark": "processor", "hide": "memory"},
	{"kind": "phish_mail", "from": "prize-team@gold-winners.biz", "subject": "YOU WON 1,000,000 GOLD!!!",
		"lines": ["Dear player,", "Click in the next 10 minutes or lose it!"], "link": "claim-your-prize.biz/login",
		"button": "LOG IN NOW", "mark": "link"},
	{"kind": "phish_mail", "from": "Zara", "subject": "Our castle", "lines": ["See you at the castle after school!"]},
	{"kind": "privacy_panel", "title": "Who can see me?", "rows": [["See my profile", "friends"],
		["Send me messages", "only me"], ["Show where I am", "off"], ["Join my world", "everyone"]], "mark": 3},
	{"kind": "ai_examples", "examples": [["circle", "red", "apple"], ["circle", "green", "apple"], ["star", "yellow", "not apple"],
		["square", "blue", "not apple"], ["circle", "orange", "apple"]], "new": ["circle", "purple"]},
	{"kind": "ai_examples", "examples": [["triangle", "red", "yes"], ["square", "blue", "no"]]},
	{"kind": "art_principle", "show": "symmetry"},
	{"kind": "art_principle", "show": "asymmetry"},
	{"kind": "art_principle", "show": "radial"},
	{"kind": "art_principle", "show": "contrast"},
	{"kind": "art_principle", "show": "emphasis"},
	{"kind": "art_principle", "show": "rhythm"},
	{"kind": "art_principle", "show": "unity"},
	{"kind": "art_principle", "show": "variety"},
	{"kind": "art_principle", "show": "movement"},
	{"kind": "art_principle", "show": "pattern"},
	{"kind": "illuminated", "letter": "B"},
	{"kind": "illuminated", "letter": "Q", "text": false},
	{"kind": "star_pattern", "points": 8, "stage": 1},
	{"kind": "star_pattern", "points": 8, "stage": 2},
	{"kind": "star_pattern", "points": 8},
	{"kind": "star_pattern", "points": 6, "tiled": true},
	{"kind": "star_pattern", "points": 10, "stage": 2},
	{"kind": "star_pattern", "points": 12},
	{"kind": "ink_landscape"},
	{"kind": "ink_landscape", "labels": true, "mark": "mist"},
	{"kind": "tessellation", "shape": "triangle"},
	{"kind": "tessellation", "shape": "square", "colours": ["red", "white"]},
	{"kind": "tessellation", "shape": "hexagon", "colours": ["yellow", "orange", "green"]},
	{"kind": "tessellation", "shape": "brick"},
	{"kind": "tessellation", "shape": "rhombus"},
	{"kind": "tessellation", "shape": "octagon", "colours": ["blue", "white"]},
	{"kind": "tessellation", "shape": "pentagon"},
	{"kind": "tessellation", "shape": "circle"},
	{"kind": "rotation_motif", "order": 6, "motif": "petal"},
	{"kind": "rotation_motif", "order": 4, "motif": "hook", "mark": true},
	{"kind": "rotation_motif", "order": 3, "motif": "flag"},
	{"kind": "rotation_motif", "order": 8, "motif": "leaf"},
	{"kind": "rotation_motif", "order": 5, "motif": "drop"},
	{"kind": "two_point", "eye": "above", "lines": true, "labels": true},
	{"kind": "two_point", "eye": "level", "lines": true, "mark": "near edge"},
	{"kind": "two_point", "eye": "below", "mark": "horizon", "labels": true},
	{"kind": "feeling_art", "feeling": "joy"},
	{"kind": "feeling_art", "feeling": "sadness", "body": true, "colour": true},
	{"kind": "feeling_art", "feeling": "anger", "body": true},
	{"kind": "feeling_art", "feeling": "fear", "colour": true},
	{"kind": "feeling_art", "feeling": "surprise", "body": true},
	{"kind": "feeling_art", "feeling": "calm", "body": true, "colour": true},
	{"kind": "print_layers", "layers": ["yellow", "orange", "red", "black"]},
	{"kind": "print_layers", "layers": ["blue", "green"], "view": "final"},
	{"kind": "stroke_letters", "text": "HIT", "serif": true, "guides": true},
	{"kind": "stroke_letters", "text": "NAME", "contrast": true},
	{"kind": "stroke_letters", "text": "ZT", "monogram": true},
	{"kind": "stroke_letters", "text": "FLY"},
	{"kind": "letter_guides", "word": "gold", "labels": true},
	{"kind": "letter_guides", "word": "happy", "mark": "x-height"},
	{"kind": "land_art", "design": "spiral", "material": "leaves"},
	{"kind": "land_art", "design": "circle", "material": "stones"},
	{"kind": "land_art", "design": "rings", "material": "petals"},
	{"kind": "land_art", "design": "line", "material": "sticks"},
	{"kind": "land_art", "design": "mandala", "material": "stones"},
	{"kind": "land_art", "design": "seeds", "material": "petals"},
	{"kind": "masterwork", "what": "great_wave"},
	{"kind": "masterwork", "what": "starry_night"},
	{"kind": "masterwork", "what": "hunters_snow"},
	{"kind": "key_signature", "key": "G", "notes": ["G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5"], "names": true},
	{"kind": "key_signature", "key": "F", "title": true},
	{"kind": "key_signature", "key": "D", "notes": ["D4", "F4", "A4"]},
	{"kind": "key_signature", "key": "Bb", "title": true, "notes": ["B4", "E5"], "names": true},
	{"kind": "key_signature", "key": "A"},
	{"kind": "key_signature", "key": "C", "notes": ["C4", "E4", "G4"]},
	{"kind": "twelve_bar", "key": "C", "numerals": true},
	{"kind": "twelve_bar", "key": "G", "mark": 4, "hide": [8, 9]},
	{"kind": "hand_keys", "hand": "right", "fingers": [["C4", 1], ["D4", 2], ["E4", 3], ["F4", 4], ["G4", 5]]},
	{"kind": "hand_keys", "hand": "left", "from": "C3", "keys": 10, "fingers": [["C3", 5], ["E3", 3], ["G3", 1]], "mark": "E3"},
	{"kind": "world_instrument", "what": "sitar", "labels": true},
	{"kind": "world_instrument", "what": "koto", "labels": true},
	{"kind": "world_instrument", "what": "djembe", "labels": true},
	{"kind": "world_instrument", "what": "bagpipes", "labels": true, "mark": "drones"},
	{"kind": "world_instrument", "what": "steelpan", "labels": true},
	{"kind": "world_instrument", "what": "didgeridoo"},
	{"kind": "world_instrument", "what": "kora", "labels": true},
	{"kind": "world_instrument", "what": "erhu", "labels": true},
	{"kind": "decibel_scale", "safe": true},
	{"kind": "decibel_scale", "items": [["whisper", 30], ["talking", 60], ["concert", 110]], "mark": 2},
]
const BROKEN: Array[Dictionary] = [
	{"kind": "bit_cards", "bits": "10201"},
	{"kind": "bit_cards", "bits": "101010101"},
	{"kind": "rgb_mix", "r": 300, "g": 0, "b": 0},
	{"kind": "rgb_mix", "r": 0, "g": 0, "b": 0, "view": "prism"},
	{"kind": "logic_gate", "gate": "XOR", "inputs": [1, 0]},
	{"kind": "logic_gate", "gate": "NOT", "inputs": [1, 0]},
	{"kind": "logic_gate", "gate": "AND", "inputs": [1, 2]},
	{"kind": "computer_parts", "mark": "flux capacitor"},
	{"kind": "phish_mail", "from": "a", "subject": "b", "lines": []},
	{"kind": "phish_mail", "from": "a", "subject": "b", "lines": ["hi"], "mark": "link"},
	{"kind": "privacy_panel", "rows": [["See my profile", "the whole moon"]]},
	{"kind": "ai_examples", "examples": [["circle", "red", "a"], ["circle", "red", "b"], ["circle", "red", "c"]]},
	{"kind": "ai_examples", "examples": [["hexagon", "red", "a"], ["circle", "red", "b"]]},
	{"kind": "art_principle", "show": "chaos"},
	{"kind": "illuminated", "letter": "ab"},
	{"kind": "star_pattern", "points": 7},
	{"kind": "ink_landscape", "mark": "dragon"},
	{"kind": "tessellation", "shape": "heptagon"},
	{"kind": "tessellation", "shape": "square", "colours": ["red"]},
	{"kind": "rotation_motif", "order": 1, "motif": "petal"},
	{"kind": "two_point", "eye": "sideways"},
	{"kind": "feeling_art", "feeling": "hungry"},
	{"kind": "print_layers", "layers": []},
	{"kind": "print_layers", "layers": ["tartan"]},
	{"kind": "stroke_letters", "text": "BOB"},
	{"kind": "stroke_letters", "text": "HIT", "monogram": true},
	{"kind": "letter_guides", "word": "Gold"},
	{"kind": "land_art", "design": "spiral", "material": "plastic"},
	{"kind": "masterwork", "what": "a selfie"},
	{"kind": "key_signature", "key": "H"},
	{"kind": "key_signature", "key": "G", "notes": ["C7"]},
	{"kind": "twelve_bar", "key": "F"},
	{"kind": "twelve_bar", "key": "C", "mark": 12},
	{"kind": "hand_keys", "hand": "right", "fingers": [["C4", 6]]},
	{"kind": "hand_keys", "hand": "right", "fingers": [["C6", 1]]},
	{"kind": "world_instrument", "what": "kazoo"},
	{"kind": "world_instrument", "what": "sitar", "mark": "bag"},
	{"kind": "decibel_scale", "items": [["space", 400], ["a", 1]]},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(248, 126), Vector2(520, 250)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_broken_data_is_a_problem() -> void:
	for d in BROKEN:
		assert_ne(SchoolPicture.problem(d), "", str(d))


func test_every_grade_6_arts_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG6Arts.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drew every sample")


## Binary: each card is worth twice the one on its right (1, 2, 4, 8, 16 …), and a face-up card counts.
func test_the_bit_cards_add_up() -> void:
	assert_eq(SchoolPictureG6Arts.bits_value("10110"), 22, "16 + 4 + 2")
	assert_eq(SchoolPictureG6Arts.bits_value("11111111"), 255, "a byte's biggest number")
	assert_eq(SchoolPictureG6Arts.bits_value("0"), 0)
	assert_eq(SchoolPictureG6Arts.bits_value("1000"), 8)


func test_the_gates_follow_their_rules() -> void:
	for a in 2:
		for b in 2:
			assert_eq(SchoolPictureG6Arts.gate_out("AND", [a, b]), 1 if a == 1 and b == 1 else 0, "AND %d %d" % [a, b])
			assert_eq(SchoolPictureG6Arts.gate_out("OR", [a, b]), 1 if a == 1 or b == 1 else 0, "OR %d %d" % [a, b])
		assert_eq(SchoolPictureG6Arts.gate_out("NOT", [a]), 1 - a, "NOT %d" % a)


## A major key's signature holds the notes its scale sharpens or flattens: G major's scale (G A B C D E F# G) needs F
## sharp, F major's (F G A Bb C D E F) B flat.
func test_the_key_signatures_are_the_scales_sharps_and_flats() -> void:
	var semis := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	var letters := "CDEFGAB"
	var steps: Array[int] = [2, 2, 1, 2, 2, 2, 1]
	for key: String in SchoolPictureG6Arts.KEYS:
		var at := posmod(int(semis[key.left(1)]) - (1 if key.ends_with("b") else 0), 12)
		var li := letters.find(key.left(1))
		var changed: Array = []
		for i in 7:
			var letter := letters[(li + i) % 7]
			var diff := posmod(at - int(semis[letter]) + 6, 12) - 6
			if diff == 1:
				changed.append(letter + "#")
			elif diff == -1:
				changed.append(letter + "b")
			else:
				assert_eq(diff, 0, "%s major: %s" % [key, letter])
			at = posmod(at + steps[i], 12)
		var want := SchoolPictureG6Arts.key_accidentals(key)
		changed.sort()
		want.sort()
		assert_eq(changed, want, "%s major's key signature" % key)


## Grade 6's spreadsheet models: grade 5's sheet picture works out =AVERAGE(…) and a share (=B2/C2) too.
func test_the_sheet_works_out_averages_and_shares() -> void:
	var d := {"kind": "sheet", "cells": [["Game", "Points"], ["1", "7"], ["2", "18"], ["3", "2"],
		["Average", "=AVERAGE(B2:B4)"], ["Each of 3", "=B5/3"], ["Zero", "=B2/0"]]}
	assert_eq(SchoolPictureG5Arts.value(d, "B5"), 9.0, "(7 + 18 + 2) ÷ 3")
	assert_eq(SchoolPictureG5Arts.value(d, "B6"), 3.0, "9 ÷ 3")
	assert_true(is_nan(SchoolPictureG5Arts.value(d, "B7")), "nothing divides by 0")
	assert_ne(SchoolPicture.problem(d), "", "a formula that divides by 0 can't be worked out")
	d.cells.pop_back()
	assert_eq(SchoolPicture.problem(d), "")


func test_the_twelve_bar_blues_goes_one_four_five() -> void:
	assert_eq(SchoolPictureG6Arts.twelve_bar_chords("C"), ["C", "C", "C", "C", "F", "F", "C", "C", "G", "F", "C", "C"] as Array[String])
	assert_eq(SchoolPictureG6Arts.twelve_bar_chords("G"), ["G", "G", "G", "G", "C", "C", "G", "G", "D", "C", "G", "G"] as Array[String])
	assert_eq(SchoolPictureG6Arts.twelve_bar_chords("E"), ["E", "E", "E", "E", "A", "A", "E", "E", "B", "A", "E", "E"] as Array[String])


## Every part a label can point at is inside the picture, and the parts of one picture are far enough apart for a
## finger to tell their pins apart.
func test_the_parts_are_on_the_picture() -> void:
	var box := ExerciseCheck.LABEL_BOX
	var pictures: Array[Dictionary] = [{"kind": "computer_parts"}, {"kind": "ink_landscape"}]
	var parts: Array = [SchoolPictureG6Arts.PARTS.keys(), SchoolPictureG6Arts.INK_PARTS.keys()]
	for what: String in SchoolPictureG6Arts.INSTRUMENTS:
		pictures.append({"kind": "world_instrument", "what": what})
		parts.append((SchoolPictureG6Arts.INSTRUMENT_PARTS[what] as Dictionary).keys())
	for eye: String in SchoolPictureG6Arts.EYES:
		pictures.append({"kind": "two_point", "eye": eye})
		parts.append(SchoolPictureG6Arts.TWO_POINT_PARTS)
	pictures.append({"kind": "letter_guides", "word": "gold"})
	parts.append(SchoolPictureG6Arts.GUIDES)
	for i in pictures.size():
		for part: String in parts[i]:
			var p := SchoolPictureG6Arts.part_at(pictures[i], part, box)
			assert_true(Rect2(Vector2.ZERO, box).has_point(p), "%s: %s at %s" % [pictures[i], part, p])
	assert_eq(SchoolPictureG6Arts.part_at({"kind": "computer_parts"}, "a sandwich", box), Vector2(-1, -1))
	var g := SchoolPictureG6Arts.part_at({"kind": "letter_guides", "word": "a"}, "baseline", box)
	var x := SchoolPictureG6Arts.part_at({"kind": "letter_guides", "word": "a"}, "x-height", box)
	assert_lt(x.y, g.y, "the x-height is above the baseline")
