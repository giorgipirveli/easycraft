extends GutTest
## Owner #70 and #73, grade 5 computing, art and music (research §6.5): the picture kinds they add (SchoolPictureG5Arts,
## drawn inside SchoolPicture): a pen that draws what a program with loops and procedures says, variables as named
## boxes, a simulation's frames, a message in packets, a page of search results with its adverts, a photo whose shadows
## give an edit away, a column chart whose axis may not start at 0, a spreadsheet that works out its formulas, a chat, a
## phone's helping features, one-point perspective, the Greek columns, a Greek vase, a mosaic, famous buildings and
## arches, a still life, abstract art, dyed cloth, comic panels, a piano keyboard, chords on the stave, a song's form,
## composers' lives on a timeline, a beat grid, a conductor's beat pattern, a music maker's tracks and a recording's
## waveform; and grade 4's stave gains quavers, dotted minims and words under its notes, its code DEFINE blocks. Every
## kind draws from its data at the School's picture sizes; broken data is a problem the content test finds; the
## pictures' facts are worked out (the pen's path, a formula's value, a message's packets).

const SAMPLES: Array[Dictionary] = [
	{"kind": "pen", "lines": ["REPEAT 4 TIMES", "  FORWARD 2", "  TURN LEFT"]},
	{"kind": "pen", "lines": ["REPEAT 3 TIMES", "  REPEAT 4 TIMES", "    FORWARD 1", "    TURN LEFT", "  PEN UP",
		"  FORWARD 2", "  PEN DOWN"], "cols": 9, "rows": 4, "code": true},
	{"kind": "pen", "lines": ["DEFINE step", "  FORWARD 1", "  TURN LEFT", "  FORWARD 1", "  TURN RIGHT",
		"REPEAT 4 TIMES", "  step"], "cols": 5, "rows": 5, "start": [0, 5], "facing": "E"},
	{"kind": "var_boxes", "boxes": [["score", "120"], ["lives", "3"], ["level", "2"]], "mark": 1},
	{"kind": "var_boxes", "boxes": [["name", "Pip"]]},
	{"kind": "sim_frames", "what": "ball", "values": [8, 5, 2, 0, 3, 5], "top": 10},
	{"kind": "sim_frames", "what": "plant", "values": [1, 3, 5, 7], "top": 8, "labels": ["day 1", "day 2", "day 3", "day 4"]},
	{"kind": "packets", "message": "MEET AT THE TREE", "size": 4, "to": "Zara", "from": "Tilly"},
	{"kind": "packets", "message": "HELLO GRAN", "size": 4, "order": [2, 0, 1]},
	{"kind": "search_page", "query": "how do bees make honey", "results": [{"title": "Buy honey now: half price!", "ad": true},
		{"title": "How bees make honey", "note": "a nature society's page"}, {"title": "Bees for children"}], "mark": 0},
	{"kind": "shadow_photo", "things": ["tree", "person", "tree"], "sun": "left", "odd": 1},
	{"kind": "shadow_photo", "things": ["post", "tree"], "sun": "right"},
	{"kind": "column_chart", "bars": [["Pip", 52], ["Moss", 55]], "from": 50, "to": 56, "step": 1, "title": "Gems found"},
	{"kind": "column_chart", "bars": [["Mon", 4], ["Tue", 7], ["Wed", 2], ["Thu", 9]], "to": 10, "step": 2, "mark": 3},
	{"kind": "sheet", "cells": [["Buddy", "Gems"], ["Pip", "12"], ["Moss", "8"], ["Fizz", "15"], ["Total", "=SUM(B2:B4)"]],
		"mark": "B5"},
	{"kind": "sheet", "cells": [["Item", "Cost", "How many", "Total"], ["rope", "3", "2", "=B2*C2"],
		["lamp", "5", "1", "=B3*C3"]], "show": "formulas"},
	{"kind": "chat", "name": "CoolGamer", "messages": [["them", "hi! what school do you go to?"],
		["me", "I don't share that"], ["them", "ok, what's your address then?"]], "mark": 2},
	{"kind": "access_feature", "what": "captions"},
	{"kind": "access_feature", "what": "read_aloud"},
	{"kind": "access_feature", "what": "big_text"},
	{"kind": "access_feature", "what": "high_contrast"},
	{"kind": "access_feature", "what": "voice"},
	{"kind": "access_feature", "what": "alt_text"},
	{"kind": "perspective", "scene": "road", "lines": true, "mark": "vanishing point"},
	{"kind": "perspective", "scene": "room", "labels": true},
	{"kind": "perspective", "scene": "rails", "mark": "horizon", "vp": 0.35},
	{"kind": "greek_column", "orders": ["doric", "ionic", "corinthian"], "labels": true},
	{"kind": "greek_column", "orders": ["ionic"], "mark": 0},
	{"kind": "greek_vase", "style": "black-figure"},
	{"kind": "greek_vase", "style": "red-figure"},
	{"kind": "mosaic", "rows": ["bbbbbbbb", "bbwwbbbb", "bwwwwwbb", "bbwwbwbb", "bbbbbbbb"], "key": {"b": "blue", "w": "white"}},
	{"kind": "mosaic", "rows": ["ry", "yr"], "key": {"r": "red", "y": "yellow"}, "grout": false},
	{"kind": "building", "what": "pyramid"},
	{"kind": "building", "what": "parthenon"},
	{"kind": "building", "what": "pantheon"},
	{"kind": "building", "what": "aqueduct"},
	{"kind": "building", "what": "cathedral"},
	{"kind": "building", "what": "taj_mahal"},
	{"kind": "building", "what": "pagoda"},
	{"kind": "building", "what": "skyscraper"},
	{"kind": "building", "what": "lintel"},
	{"kind": "building", "what": "round_arch"},
	{"kind": "building", "what": "pointed_arch"},
	{"kind": "still_life", "objects": ["jug", "apple", "pear"], "light": "left"},
	{"kind": "still_life", "objects": ["bowl", "lemon"], "light": "right", "labels": true},
	{"kind": "still_life", "objects": ["bottle", "cup"], "light": "left", "shade": false},
	{"kind": "abstract", "style": "grid"},
	{"kind": "abstract", "style": "shapes", "variant": 2},
	{"kind": "abstract", "style": "circles", "variant": 1},
	{"kind": "dye", "what": "rings", "colour": "blue"},
	{"kind": "dye", "what": "spiral", "colour": "purple"},
	{"kind": "dye", "what": "batik", "colour": "orange"},
	{"kind": "dye", "what": "tied", "colour": "white"},
	{"kind": "comic", "panels": [{"caption": "One sunny morning…", "shot": "wide"}, {"say": "Where is my buddy?"},
		{"think": "Maybe in the barn!", "shot": "close"}, {"sfx": "CRASH!"}], "mark": 2},
	{"kind": "comic", "panels": [{"say": "Hello!"}]},
	{"kind": "keyboard", "mark": ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"], "names": true, "steps": true,
		"scale": "major", "title": "C major scale"},
	{"kind": "keyboard", "from": "C4", "keys": 10, "mark": ["C4", "Eb4", "G4"]},
	{"kind": "keyboard", "mark": ["F#4"], "keys": 8},
	{"kind": "chord_stave", "chords": [["C4", "E4", "G4"], ["F4", "A4", "C5"], ["G4", "B4", "D5"], ["A4", "C5", "E5"]],
		"names": ["C", "F", "G", "Am"]},
	{"kind": "chord_stave", "chords": [["D4", "F4", "A4"]], "mark": 0},
	{"kind": "song_form", "sections": ["A", "B", "A"]},
	{"kind": "song_form", "sections": ["verse", "chorus", "verse", "chorus", "bridge", "chorus"], "mark": 4},
	{"kind": "lifespans", "people": [["J. S. Bach", 1685, 1750], ["Handel", 1685, 1759], ["Haydn", 1732, 1809],
		["Mozart", 1756, 1791]], "from": 1650, "to": 1850, "mark": 3, "year": 1756},
	{"kind": "beat_grid", "rows": [["djembe", "x--x--x-"], ["bell", "x-x-xx-x"]], "count": true},
	{"kind": "beat_grid", "rows": [["surdo", "----x-------x---"], ["caixa", "x-xxx-xxx-xxx-xx"], ["agogo", "x-x---x-x-x---x-"]], "mark": 0},
	{"kind": "beat_pattern", "beats": 4, "mark": 2},
	{"kind": "beat_pattern", "beats": 3},
	{"kind": "beat_pattern", "beats": 2},
	{"kind": "tracks", "tracks": [["drums", [[0, 4]]], ["bass", [[0, 2], [2, 2]]], ["voice", [[2, 2]]]], "bars": 4,
		"loop": [0, 2], "mark": 2},
	{"kind": "waveform", "levels": [0, 0, 1, 6, 9, 5, 7, 8, 4, 2, 1, 0, 0, 0], "keep": [2, 10]},
	{"kind": "waveform", "levels": [2, 5, 3, 8]},
	# grade 4's kinds, grown for grade 5
	{"kind": "stave", "notes": ["G4", "G4", "A4", "B4", "C5", "B4", "A4"], "values": ["quaver", "quaver", "crotchet",
		"crotchet", "dotted minim", "crotchet", "crotchet"], "time": "4/4", "bars": true},
	{"kind": "stave", "notes": ["E4", "G4", "G4", "A4"], "words": ["Sun", "is", "shin", "ing"]},
	{"kind": "code", "lines": ["DEFINE square", "  REPEAT 4 TIMES", "    FORWARD 2", "    TURN RIGHT", "square",
		"FORWARD 3", "square"], "mark": 4},
]
const BROKEN: Array[Dictionary] = [
	{"kind": "pen", "lines": ["FORWARD 20"]},                       # off the paper
	{"kind": "pen", "lines": ["JUMP 2"]},                           # not a command
	{"kind": "pen", "lines": ["TURN LEFT"]},                        # draws nothing
	{"kind": "pen", "lines": ["DEFINE a", "  a", "a"]},             # calls itself for ever
	{"kind": "var_boxes", "boxes": []},
	{"kind": "sim_frames", "what": "ball", "values": [12], "top": 10},
	{"kind": "packets", "message": "HELLO", "size": 2, "order": [0, 0, 1]},
	{"kind": "packets", "message": "A VERY LONG MESSAGE HERE", "size": 2},   # 12 packets
	{"kind": "search_page", "query": "bees", "results": []},
	{"kind": "shadow_photo", "things": ["tree"], "sun": "left"},
	{"kind": "column_chart", "bars": [["a", 3], ["b", 70]], "to": 10, "step": 1},
	{"kind": "sheet", "cells": [["=SUM(A1:A2)"], ["3"]]},              # refers to itself
	{"kind": "sheet", "cells": [["a", "b"], ["c"]]},
	{"kind": "chat", "messages": [["you", "hi"]]},
	{"kind": "access_feature", "what": "telepathy"},
	{"kind": "perspective", "scene": "sky"},
	{"kind": "greek_column", "orders": ["tuscan"]},
	{"kind": "building", "what": "moon base"},
	{"kind": "still_life", "objects": ["car"], "light": "left"},
	{"kind": "abstract", "style": "grid", "variant": 9},
	{"kind": "dye", "what": "rings", "colour": "tartan"},
	{"kind": "comic", "panels": [{}, {}, {}, {}, {}]},
	{"kind": "keyboard", "mark": ["C7"]},
	{"kind": "chord_stave", "chords": [["G4", "E4", "C4"]]},           # a chord goes up
	{"kind": "song_form", "sections": ["A"]},
	{"kind": "lifespans", "people": [["Bach", 1750, 1685]], "from": 1600, "to": 1800},
	{"kind": "beat_grid", "rows": [["drum", "x-x"], ["bell", "x-x-"]]},
	{"kind": "beat_pattern", "beats": 5},
	{"kind": "tracks", "tracks": [["drums", [[3, 4]]]], "bars": 4},
	{"kind": "waveform", "levels": [1, 20]},
	{"kind": "stave", "notes": ["C4", "D4"], "words": ["one"]},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_broken_data_is_a_problem() -> void:
	for d in BROKEN:
		assert_ne(SchoolPicture.problem(d), "", str(d))


func test_every_grade_5_arts_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG5Arts.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drew every sample")


## The pen goes where its program says: a square comes back to its start; loops inside loops draw every side.
func test_the_pen_draws_what_the_program_says() -> void:
	var square := SchoolPictureG5Arts.trace({"kind": "pen", "lines": ["REPEAT 4 TIMES", "  FORWARD 2", "  TURN LEFT"]})
	assert_eq(square.error, "")
	assert_eq(square.pos, Vector2i(0, 6), "a square ends where it started (the bottom left)")
	assert_eq(square.moves, 8, "four sides of 2")
	var three := SchoolPictureG5Arts.trace(SAMPLES[1])
	assert_eq(three.error, "")
	assert_eq(three.moves, 12, "three squares of 4 sides; the pen is up for the gaps")
	assert_eq((three.segments as Array).size(), 12)
	var stairs := SchoolPictureG5Arts.trace(SAMPLES[2])
	assert_eq(stairs.error, "")
	assert_eq(stairs.pos, Vector2i(4, 1), "four steps up and along")
	assert_eq(stairs.facing, "E")


## A spreadsheet works out its formulas: sums, products and cells that use other formulas.
func test_the_sheet_works_out_its_formulas() -> void:
	var sheet: Dictionary = SAMPLES[14]
	assert_eq(SchoolPictureG5Arts.value(sheet, "B5"), 35.0)
	assert_eq(SchoolPictureG5Arts.value(sheet, "B2"), 12.0)
	var costs: Dictionary = SAMPLES[15]
	assert_eq(SchoolPictureG5Arts.value(costs, "D2"), 6.0)
	assert_eq(SchoolPictureG5Arts.value(costs, "D3"), 5.0)
	var more := {"kind": "sheet", "cells": [["4", "=A1+6", "=MAX(A1:B1)", "=MIN(A1:C1)", "=C1-A1"]]}
	assert_eq(SchoolPictureG5Arts.value(more, "B1"), 10.0)
	assert_eq(SchoolPictureG5Arts.value(more, "C1"), 10.0)
	assert_eq(SchoolPictureG5Arts.value(more, "D1"), 4.0)
	assert_eq(SchoolPictureG5Arts.value(more, "E1"), 6.0)
	assert_true(is_nan(SchoolPictureG5Arts.value(more, "Z9")), "no such cell")


## A message is split into packets of `size` letters: "HELLO GRAN" in fours is HELL, O GR, AN.
func test_a_message_splits_into_packets() -> void:
	assert_eq(SchoolPictureG5Arts.packets_of("HELLO GRAN", 4), ["HELL", "O GR", "AN"] as Array[String])
	assert_eq(SchoolPictureG5Arts.packets_of("MEET AT THE TREE", 4).size(), 4)


## The stave's quavers are half a beat and its dotted minims three, so the bars fall in the right places.
func test_the_stave_counts_quavers_and_dotted_minims() -> void:
	assert_eq(SchoolPictureG4Arts.VALUE_HALVES["quaver"], 1)
	assert_eq(SchoolPictureG4Arts.VALUE_HALVES["dotted minim"], 6)
	assert_ne(SchoolPicture.problem({"kind": "stave", "notes": ["C4"], "values": ["hemidemisemiquaver"]}), "")
