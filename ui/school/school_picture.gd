class_name SchoolPicture
extends Control
## Owner #68 (spec §22.1): a lesson's or an exercise's picture, drawn from its data on a paper card (UI draw calls, the
## game's block icons, its animals and its board pictures; no new art). `problem(d)` checks the data (the content test).
## Kinds and their fields:
## - blocks {thousands, hundreds, tens, ones}: base-ten blocks, each 0-9.
## - array {rows, cols, block?}: rows × cols blocks (1-12 each).
## - groups {groups, each, left?}: equal groups of blocks in boxes, and some left over.
## - bar {den, num} or {bars: [{den, num}, …]}: fraction walls (den 1-16, or 100 as a 10 × 10 square).
## - number_line {from, to, step, dot?, marks?, labels? ("ends", "all", "none")}: numbers as text ("3/8", "0.4", "46732").
## - rect {w, h, unit?, grid?, unknown? ("w", "h"), label_w?, label_h?}: a fenced farm w × h (labels: other words for a
##   side, for farms bigger than the picture's grid).
## - angle {deg, parts?, hide?, show?, protractor?, unknown?}: an angle (parts: two angles side by side that make it;
##   hide: the part whose size is "?").
## - lines {what: ShapeFacts-free kinds in LINES}; shape {what: ShapeFacts.SHAPES, symmetry?, marks?}.
## - line_plot {den, from, to, counts: {numerator: count}, unit?}: X marks over fractions of a unit.
## - layers {blocks: [block ids, bottom first], fossils?: {layer: kind}, labels?}: rock layers in a cliff.
## - wave, pixels, map, rays: grade 4 science (their fields in the section "Grade 4 science kinds").
## - towers {heights, missing?}: a growing pattern of block towers (the next one "?").
## - clock {h, m}; table {rows: [[text, …], …]} (1-7 rows of 1-6 cells; the first row is the header).
## - icon {block | animal | picture, count?}: one picture, or `count` of it.
## Grade 5 maths kinds (grid, cubes, family, places, area_model, fraction_area, column) are drawn by SchoolPictureG5
## (ui/school/school_picture_g5.gd, its header lists their fields).
## Grade 3 maths kinds (pictogram, bar_graph, jug, dial_scale, ruler, cut_shape, unit_squares, side_lengths,
## fraction_plot, bar_model, digital_clock, times_grid, fraction_wall) are drawn by SchoolPictureG3
## (ui/school/school_picture_g3.gd, its header lists their fields).
## Grade 3 computing, art and music kinds (swatches, notation, melody, robot, marks) are drawn by SchoolPictureArts
## (ui/school/school_picture_arts.gd, its header lists their fields).
## Grade 3 health, D&T and projects kinds (net, plate, lever, frame, weave, stitch, pose) are drawn by SchoolPictureLife
## (ui/school/school_picture_life.gd, its header lists their fields).
## Grade 4 and 5 history and geography kinds (numerals: Egyptian, Babylonian and Maya numbers; latlong: the world's grid
## of latitude and longitude) are drawn by SchoolPictureHistory (ui/school/school_picture_history.gd, its header lists
## their fields).
## Grade 4 computing, art and music kinds (stave, code, flowchart, network, colour_wheel, shading, face, landscape,
## pixel_art, relief, print, orchestra, glyphs) are drawn by SchoolPictureG4Arts (ui/school/school_picture_g4arts.gd).
## Grade 4 health, D&T and projects kinds (circuit, beach_flags, food_label, pitch, site_plan, chassis, hand) are drawn by
## SchoolPictureG4Life (ui/school/school_picture_g4life.gd, its header lists their fields).
## Grade 4 maths, science and English kinds (line_graph, pie_chart, lab_circuit, thermometer, states, teeth, digestion) are
## drawn by SchoolPictureG4Core (ui/school/school_picture_g4core.gd, its header lists their fields).
## Grade 5 health, D&T and projects kinds (net_court, gears, pulleys, cam, bridge, views, compass, food_web, lying) are
## drawn by SchoolPictureG5Life (ui/school/school_picture_g5life.gd, its header lists their fields).
## Grade 5 computing, art and music kinds (pen, var_boxes, sim_frames, packets, search_page, shadow_photo, column_chart,
## sheet, chat, access_feature, perspective, greek_column, greek_vase, mosaic, building, still_life, abstract, dye, comic,
## keyboard, chord_stave, song_form, lifespans, beat_grid, beat_pattern, tracks, waveform) are drawn by
## SchoolPictureG5Arts (ui/school/school_picture_g5arts.gd, its header lists their fields).
## Grade 5 maths, science and English kinds (hundred_square, angle_facts, circuit_symbols, force_arrows, life_cycle,
## flower_parts, lungs, blood_loop) are drawn by SchoolPictureG5Core (ui/school/school_picture_g5core.gd, its header lists
## their fields).
## Grade 6 history, geography and citizenship kinds (event_timeline, quipu, feudal_pyramid, castle_type, dot_density,
## city_zones, os_map, climograph, river_course, layer_map, savings_growth) are drawn by SchoolPictureG6Hum
## (ui/school/school_picture_g6hum.gd, its header lists their fields).
## Grade 6 computing, art and music kinds (bit_cards, rgb_mix, logic_gate, computer_parts, phish_mail, privacy_panel,
## ai_examples, art_principle, illuminated, star_pattern, ink_landscape, tessellation, rotation_motif, two_point,
## feeling_art, print_layers, stroke_letters, letter_guides, land_art, masterwork, key_signature, twelve_bar, hand_keys,
## world_instrument, decibel_scale) are drawn by SchoolPictureG6Arts (ui/school/school_picture_g6arts.gd, its header
## lists their fields).
## Grade 6 health, D&T and projects kinds (lever_class, linkage, truss, struct_force, biomimicry, material_swatch,
## design_style, sensor_system, threshold_graph, breath_box, control_rings, food_thermo, microbe_split, weather_kit,
## access_fm, talk_test, fast_signs, track_field) are drawn by SchoolPictureG6Health (ui/school/school_picture_g6health.gd,
## its header lists their fields).
## Grade 6 maths, science and English kinds (skeleton, joint, muscle_pair, food_test, enzyme_cut, key_tree, kingdoms,
## taxon_levels, shadow_rays, reflection, light_device, energy_chain, sankey, op_chain, handshakes, argument_map,
## story_arc, info_page) are drawn by SchoolPictureG6Core (ui/school/school_picture_g6core.gd, its header lists their
## fields).
## Grade 7 computing, art and music kinds (text_code, list_boxes, func_machine, search_steps, sort_bars, internet_trip,
## cipher_wheel, data_sheet, phone_feed, licence_tags, old_master, colour_scheme, figure_study, world_art_piece,
## poster_layout, house_drawing, thirds_frame, carved_block, gallery_wall, chord_chart, ornament_signs, symphony_plan,
## drum_kit, piano_roll, film_strip, mixer, clef_stave) are drawn by SchoolPictureG7Arts (ui/school/school_picture_g7arts.gd,
## its header lists their fields).
## Grade 7 history, geography and citizenship kinds (hand_press, voyage_map, pole_star, columbian_exchange, dome_profile,
## charbagh, sky_model, family_tree, plate_section, rock_cycle, soil_profile, glacial_valley, coast_view, nutrient_cycle,
## step_chain, break_even, cut_axis_bars) are drawn by SchoolPictureG7Hum (ui/school/school_picture_g7hum.gd, its header
## lists their fields).
## Grade 7 health, D&T and projects kinds (hr_zones, shot_paths, sleep_dial, photo_edit, advert, influence_map,
## ref_signal, schematic, resistor, micro_board, exploded, cam_process, fabric_section, eco_home) are drawn by
## SchoolPictureG7Life (ui/school/school_picture_g7life.gd, its header lists their fields).
## Grade 8 history, geography and citizenship kinds (steam_engine, greenhouse, scatter_plot, pop_pyramid, tourism_cycle,
## ocean_zones, projection, parliament_seats, receipt, balance_scale) are drawn by SchoolPictureG8Hum
## (ui/school/school_picture_g8hum.gd, its header lists their fields).
## Grade 8 computing, art and music kinds (structure_chart, step_growth, state_machine, abstract_map, cpu_cycle,
## sampled_wave, gate_circuit, db_table, scatter_learn, threat_card, app_screen, light_series, brushwork, movement_piece,
## camera_obscura, raster_vector, symbol_portrait, grid_enlarge, object_design, flip_frames, mobile_balance, gallery_plan,
## wall_label, jazz_band, instrument_ranges, opera_house, swing_beats) are drawn by SchoolPictureG8Arts
## (ui/school/school_picture_g8arts.gd, its header lists their fields).
## Grade 8 health, D&T and projects kinds (fitness_profile, feeling_curve, chance_wheel, cpr_aed, making_plan,
## smart_material, gear_train, block_tackle, tall_structure, circular_loop) are drawn by SchoolPictureG8Life
## (ui/school/school_picture_g8life.gd, its header lists their fields).
## Grade 7 maths, science and English kinds (factor_tree, prime_venn, distance_time, speed_triangle, chart_kinds,
## odd_scale, big_icons, periodic_grid, ph_scale, separation, chromatogram, light_rays, seen_colour, carbon_cycle, air_mix,
## marked_text, venn, pov_view) are drawn by SchoolPictureG7Core (ui/school/school_picture_g7core.gd, its header lists
## their fields).
## Grade 8 maths, science and English kinds (parabola, trig_triangle, fluid_pressure, energy_meter, energy_profile,
## meter_circuit, plant_transport, heart_chambers, air_sac, gene_transfer, slide_design, story_order) are drawn by
## SchoolPictureG8Core (ui/school/school_picture_g8core.gd, its header lists their fields).
## Owner #94: moving pictures. `time` and `playing` (below) animate the kinds that teach motion; SchoolPictureMotion
## (ui/school/school_picture_motion.gd) says which kinds move and how, and draws the kinds made for motion (water_cycle,
## moon_phases, orbit, pendulum, rocket_stages; its header lists their fields). Any picture may say "animate": false (never
## moves) or, in an exercise, "animate": true (moves there too; should_play).
## The lesson-quality kinds (owner #94: inequality_line, word_blocks, sentence_parts, coordinate_plane) are drawn by
## SchoolPictureQuality (ui/school/school_picture_quality.gd, its header lists their fields).

const KINDS: Array[String] = ["blocks", "array", "groups", "bar", "number_line", "rect", "angle", "lines", "shape",
	"line_plot", "layers", "towers", "clock", "table", "icon"]
const LINES: Array[String] = ["point", "line", "ray", "segment", "parallel", "perpendicular", "intersecting"]
const FOSSILS: Array[String] = ["shell", "fish", "leaf", "bone", "footprint"]
## Grade 4 science's kinds (owner #68, the grade 4 agent), checked and drawn in their own section below.
const SCIENCE_KINDS: Array[String] = ["wave", "pixels", "map", "rays"]
const MAX_GRID := 12
const MAX_TICKS := 20
const MARGIN := 14.0
const FONT := 22
## Owner #94: a table cell's words shrink to fit their cell, down to this size (they were drawn over the next cell).
const TABLE_LEAST_FONT := 13
const SHADE := Color("f08a1c")
const SOFT := Color("fce2b8")
const LINE_W := 3.0
## Owner #94: a playing picture redraws at most this often (a phone draws the School's cards 3-5x slower).
const FPS := 30

var data: Dictionary:
	set(v):
		data = v
		_moving = -1
		queue_redraw()
## Owner #94: the seconds a moving kind draws (SchoolPictureMotion.moves: gears turn, a pendulum swings, the Moon goes
## round). A still kind ignores it and draws once, as it always did; time 0 is every moving kind's still picture.
## Setting it redraws a moving picture once (a Short can drive its own clock).
var time: float:
	get:
		return _time
	set(v):
		_time = v
		if _moves():
			queue_redraw()
## Owner #94: true advances `time` by itself, redrawing at FPS while the picture shows (only a moving kind ticks).
## should_play is the School's rule for it.
var playing := false:
	set(v):
		playing = v
		if is_node_ready():
			set_process(playing and _moves())

static var _paper: StyleBoxFlat

var _time := 0.0
var _moving := -1   # 1: the data moves (SchoolPicture.animates), 0: still, -1: not asked yet
var _redraw_in := 0.0


func _init(d: Dictionary = {}, px: Vector2 = Vector2(480, 280)) -> void:
	data = d
	custom_minimum_size = px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if str(d.get("kind", "")) == "icon" and d.has("animal"):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in clampi(int(d.get("count", 1)), 1, 10):
			row.add_child(AnimalPortrait.new(StringName(str(d.animal)), minf(px.y - 2 * MARGIN, 200.0)))
		add_child(row)


func _ready() -> void:
	set_process(playing and _moves())
	if _moves():
		clip_contents = true   # owner #94: what moves (a falling rocket stage) never leaves the card


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_redraw_in -= delta
	if _redraw_in <= 0.0:
		_redraw_in = 1.0 / FPS
		queue_redraw()


func _moves() -> bool:
	if _moving < 0:
		_moving = 1 if animates(data) else 0
	return _moving == 1


# --- Owner #94: moving pictures ------------------------------------------------------------------------------------

## True when `d` is a good picture of a kind that moves (SchoolPictureMotion.moves) and its data does not say
## "animate": false.
static func animates(d: Variant) -> bool:
	if not d is Dictionary or problem(d) != "":
		return false
	return (d as Dictionary).get("animate", true) != false and SchoolPictureMotion.moves(d)


## The School's rule: a lesson card's picture plays (it teaches the motion); an exercise's picture (`question`) is the
## question and stays still unless its data says "animate": true (motion can show the answer: the gears' turning is
## the answer to "which way does C turn?"); with Reduce motion every picture stays still.
static func should_play(d: Variant, question: bool) -> bool:
	if Profile.data != null and bool(Profile.data.settings.get("reduce_motion", false)):
		return false
	if question and not (d is Dictionary and (d as Dictionary).get("animate", false) == true):
		return false
	return animates(d)


## The time a kind's drawing reads from the card it draws on (0 for a still picture or anything else).
static func time_of(ci: CanvasItem) -> float:
	var pic := ci as SchoolPicture
	return pic._time if pic != null and pic._moves() else 0.0


## "" when `d` can be drawn; otherwise what is wrong.
static func problem(d: Variant) -> String:
	if not d is Dictionary:
		return "a picture is a dictionary"
	var p: Dictionary = d
	var kind := str(p.get("kind", ""))
	if p.has("animate") and not p.animate is bool:
		return "animate is true or false"
	if SchoolPictureMotion.KINDS.has(kind):   # owner #94: kinds made for motion (school_picture_motion.gd)
		return SchoolPictureMotion.problem(p)
	if SCIENCE_KINDS.has(kind):
		return _science_problem(p)
	if SchoolPictureG5.KINDS.has(kind):   # grade 5 maths kinds (school_picture_g5.gd)
		return SchoolPictureG5.problem(p)
	if SchoolPictureG3.KINDS.has(kind):   # grade 3 maths kinds (school_picture_g3.gd)
		return SchoolPictureG3.problem(p)
	if SchoolPictureArts.KINDS.has(kind):   # grade 3 computing, art and music kinds (school_picture_arts.gd)
		return SchoolPictureArts.problem(p)
	if SchoolPictureLife.KINDS.has(kind):   # grade 3 health, D&T and projects kinds (school_picture_life.gd)
		return SchoolPictureLife.problem(p)
	if SchoolPictureHistory.KINDS.has(kind):   # grade 4 history's numerals (school_picture_history.gd)
		return SchoolPictureHistory.problem(p)
	if SchoolPictureG4Arts.KINDS.has(kind):   # grade 4 computing, art and music kinds (school_picture_g4arts.gd)
		return SchoolPictureG4Arts.problem(p)
	if SchoolPictureG4Life.KINDS.has(kind):   # grade 4 health, D&T and projects kinds (school_picture_g4life.gd)
		return SchoolPictureG4Life.problem(p)
	if SchoolPictureG4Core.KINDS.has(kind):   # grade 4 maths, science and English kinds (school_picture_g4core.gd)
		return SchoolPictureG4Core.problem(p)
	if SchoolPictureG5Life.KINDS.has(kind):   # grade 5 health, D&T and projects kinds (school_picture_g5life.gd)
		return SchoolPictureG5Life.problem(p)
	if SchoolPictureG5Arts.KINDS.has(kind):   # grade 5 computing, art and music kinds (school_picture_g5arts.gd)
		return SchoolPictureG5Arts.problem(p)
	if SchoolPictureG5Core.KINDS.has(kind):   # grade 5 maths, science and English kinds (school_picture_g5core.gd)
		return SchoolPictureG5Core.problem(p)
	if SchoolPictureG6Hum.KINDS.has(kind):   # grade 6 history, geography and citizenship kinds (school_picture_g6hum.gd)
		return SchoolPictureG6Hum.problem(p)
	if SchoolPictureG6Arts.KINDS.has(kind):   # grade 6 computing, art and music kinds (school_picture_g6arts.gd)
		return SchoolPictureG6Arts.problem(p)
	if SchoolPictureG6Health.KINDS.has(kind):   # grade 6 health, D&T and projects kinds (school_picture_g6health.gd)
		return SchoolPictureG6Health.problem(p)
	if SchoolPictureG6Core.KINDS.has(kind):   # grade 6 maths, science and English kinds (school_picture_g6core.gd)
		return SchoolPictureG6Core.problem(p)
	if SchoolPictureG7Arts.KINDS.has(kind):   # grade 7 computing, art and music kinds (school_picture_g7arts.gd)
		return SchoolPictureG7Arts.problem(p)
	if SchoolPictureG7Hum.KINDS.has(kind):   # grade 7 history, geography and citizenship kinds (school_picture_g7hum.gd)
		return SchoolPictureG7Hum.problem(p)
	if SchoolPictureG7Life.KINDS.has(kind):   # grade 7 health, D&T and projects kinds (school_picture_g7life.gd)
		return SchoolPictureG7Life.problem(p)
	if SchoolPictureG8Hum.KINDS.has(kind):   # grade 8 history, geography and citizenship kinds (school_picture_g8hum.gd)
		return SchoolPictureG8Hum.problem(p)
	if SchoolPictureG8Arts.KINDS.has(kind):   # grade 8 computing, art and music kinds (school_picture_g8arts.gd)
		return SchoolPictureG8Arts.problem(p)
	if SchoolPictureG8Life.KINDS.has(kind):   # grade 8 health, D&T and projects kinds (school_picture_g8life.gd)
		return SchoolPictureG8Life.problem(p)
	if SchoolPictureG7Core.KINDS.has(kind):   # grade 7 maths, science and English kinds (school_picture_g7core.gd)
		return SchoolPictureG7Core.problem(p)
	if SchoolPictureG8Core.KINDS.has(kind):   # grade 8 maths, science and English kinds (school_picture_g8core.gd)
		return SchoolPictureG8Core.problem(p)
	if SchoolPictureQuality.KINDS.has(kind):   # owner #94's lesson-quality kinds (school_picture_quality.gd)
		return SchoolPictureQuality.problem(p)
	if not KINDS.has(kind):
		return "unknown picture kind '%s'" % kind
	match kind:
		"blocks":
			var total := 0
			for k: String in ["thousands", "hundreds", "tens", "ones"]:
				var n := _int(p, k, 0)
				if n < 0 or n > 9:
					return "%s must be 0-9" % k
				total += n
			if total == 0:
				return "no blocks"
		"array":
			if not _in(_int(p, "rows", 0), 1, MAX_GRID) or not _in(_int(p, "cols", 0), 1, MAX_GRID):
				return "rows and cols 1-%d" % MAX_GRID
		"groups":
			if not _in(_int(p, "groups", 0), 1, 10) or not _in(_int(p, "each", -1), 0, 12) or not _in(_int(p, "left", 0), 0, 9):
				return "groups 1-10, each 0-12, left 0-9"
		"bar":
			var bars := _bars(p)
			if bars.is_empty() or bars.size() > 4:
				return "1-4 bars"
			for b: Dictionary in bars:
				var den := _int(b, "den", 0)
				if not (_in(den, 1, 16) or den == 100) or not _in(_int(b, "num", -1), 0, den):
					return "a bar needs den 1-16 or 100 and num 0-den"
		"number_line":
			var from := NumberAnswer.value(str(p.get("from", "")))
			var to := NumberAnswer.value(str(p.get("to", "")))
			var step := NumberAnswer.value(str(p.get("step", "")))
			if is_nan(from) or is_nan(to) or is_nan(step) or step <= 0.0 or to <= from:
				return "from < to and a step above 0"
			var ticks := (to - from) / step
			if ticks > MAX_TICKS + 0.001 or absf(ticks - roundf(ticks)) > 0.001:
				return "the step must fit the line in at most %d steps" % MAX_TICKS
			for v: Variant in [p.get("dot")] + Array(p.get("marks", [])):
				if v != null and (is_nan(NumberAnswer.value(str(v))) or NumberAnswer.value(str(v)) < from - 0.0001
						or NumberAnswer.value(str(v)) > to + 0.0001):
					return "a dot or mark off the line: %s" % v
		"rect":
			if not _in(_int(p, "w", 0), 1, MAX_GRID) or not _in(_int(p, "h", 0), 1, MAX_GRID):
				return "w and h 1-%d" % MAX_GRID
		"angle":
			var deg := _int(p, "deg", 0)
			if not _in(deg, 1, 360):
				return "deg 1-360"
			if p.has("parts"):
				var parts: Variant = p.parts
				if not parts is Array or (parts as Array).size() != 2 or int(parts[0]) + int(parts[1]) != deg \
						or int(parts[0]) <= 0 or int(parts[1]) <= 0:
					return "two parts that add up to deg"
		"lines":
			if not LINES.has(str(p.get("what", ""))):
				return "lines: one of %s" % [LINES]
		"shape":
			if not ShapeFacts.knows(str(p.get("what", ""))):
				return "unknown shape %s" % p.get("what", "")
		"line_plot":
			var den := _int(p, "den", 0)
			if not [2, 3, 4, 5, 6, 8, 10, 12].has(den) or _int(p, "from", -1) < 0 or _int(p, "to", 0) <= _int(p, "from", 0) \
					or _int(p, "to", 0) - _int(p, "from", 0) > MAX_TICKS or not p.get("counts") is Dictionary:
				return "a line plot needs den, from < to (at most %d steps) and counts" % MAX_TICKS
			for k: Variant in p.counts:
				if not str(k).is_valid_int() or int(str(k)) < _int(p, "from", 0) or int(str(k)) > _int(p, "to", 0) \
						or int(p.counts[k]) < 0 or int(p.counts[k]) > 8:
					return "counts off the plot: %s" % k
		"layers":
			var blocks: Variant = p.get("blocks")
			if not blocks is Array or (blocks as Array).is_empty() or (blocks as Array).size() > 8:
				return "1-8 layers"
			var fossils: Variant = p.get("fossils", {})
			if not fossils is Dictionary:
				return "fossils: {layer: kind}"
			for k: Variant in fossils:
				if not str(k).is_valid_int() or not _in(int(str(k)), 0, (blocks as Array).size() - 1) \
						or not FOSSILS.has(str(fossils[k])):
					return "a fossil in no layer, or of no kind: %s" % k
		"towers":
			var h: Variant = p.get("heights")
			if not h is Array or (h as Array).is_empty() or (h as Array).size() > 6:
				return "1-6 towers"
			for v: Variant in h:
				if not _in(int(v), 0, 12):
					return "towers 0-12 blocks tall"
		"clock":
			if not _in(_int(p, "h", 0), 1, 12) or not _in(_int(p, "m", -1), 0, 59):
				return "h 1-12, m 0-59"
		"table":
			var rows: Variant = p.get("rows")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > 7:
				return "1-7 rows"
			for r: Variant in rows:
				if not r is Array or (r as Array).is_empty() or (r as Array).size() > 6:
					return "each row 1-6 cells"
		"icon":
			var count := _int(p, "count", 1)
			if not _in(count, 1, 10):
				return "count 1-10"
			if p.has("animal"):
				if not AnimalRules.SPECIES.has(StringName(str(p.animal))):
					return "unknown animal %s" % p.animal
			elif p.has("picture"):
				if not ProgressPictures.knows(StringName(str(p.picture))):
					return "unknown picture %s" % p.picture
			elif not p.has("block") or BlockIcons.icon(int(p.block)) == null:
				return "an icon needs a block, an animal or a picture"
	return ""


func _draw() -> void:
	if _paper == null:
		_paper = StyleBoxFlat.new()
		_paper.bg_color = SchoolUi.PAPER
		_paper.set_corner_radius_all(16)
	draw_style_box(_paper, Rect2(Vector2.ZERO, size))
	if _moving != 1 and problem(data) != "":   # a moving picture's data was checked when it started
		return
	var r := Rect2(Vector2(MARGIN, MARGIN), size - Vector2(2 * MARGIN, 2 * MARGIN))
	if SchoolPictureMotion.KINDS.has(str(data.kind)):   # owner #94: kinds made for motion (school_picture_motion.gd)
		SchoolPictureMotion.draw(self, data, r)
		return
	if SCIENCE_KINDS.has(str(data.kind)):
		_draw_science(r)
		return
	if SchoolPictureG5.KINDS.has(str(data.kind)):   # grade 5 maths kinds (school_picture_g5.gd)
		SchoolPictureG5.draw(self, data, r)
		return
	if SchoolPictureG3.KINDS.has(str(data.kind)):   # grade 3 maths kinds (school_picture_g3.gd)
		SchoolPictureG3.draw(self, data, r)
		return
	if SchoolPictureArts.KINDS.has(str(data.kind)):   # grade 3 computing, art and music kinds (school_picture_arts.gd)
		SchoolPictureArts.draw(self, data, r)
		return
	if SchoolPictureLife.KINDS.has(str(data.kind)):   # grade 3 health, D&T and projects kinds (school_picture_life.gd)
		SchoolPictureLife.draw(self, data, r)
		return
	if SchoolPictureHistory.KINDS.has(str(data.kind)):   # grade 4 history's numerals (school_picture_history.gd)
		SchoolPictureHistory.draw(self, data, r)
		return
	if SchoolPictureG4Arts.KINDS.has(str(data.kind)):   # grade 4 computing, art and music kinds (school_picture_g4arts.gd)
		SchoolPictureG4Arts.draw(self, data, r)
		return
	if SchoolPictureG4Life.KINDS.has(str(data.kind)):   # grade 4 health, D&T and projects kinds (school_picture_g4life.gd)
		SchoolPictureG4Life.draw(self, data, r)
		return
	if SchoolPictureG4Core.KINDS.has(str(data.kind)):   # grade 4 maths, science and English kinds (school_picture_g4core.gd)
		SchoolPictureG4Core.draw(self, data, r)
		return
	if SchoolPictureG5Life.KINDS.has(str(data.kind)):   # grade 5 health, D&T and projects kinds (school_picture_g5life.gd)
		SchoolPictureG5Life.draw(self, data, r)
		return
	if SchoolPictureG5Arts.KINDS.has(str(data.kind)):   # grade 5 computing, art and music kinds (school_picture_g5arts.gd)
		SchoolPictureG5Arts.draw(self, data, r)
		return
	if SchoolPictureG5Core.KINDS.has(str(data.kind)):   # grade 5 maths, science and English kinds (school_picture_g5core.gd)
		SchoolPictureG5Core.draw(self, data, r)
		return
	if SchoolPictureG6Hum.KINDS.has(str(data.kind)):   # grade 6 history, geography and citizenship kinds (school_picture_g6hum.gd)
		SchoolPictureG6Hum.draw(self, data, r)
		return
	if SchoolPictureG6Arts.KINDS.has(str(data.kind)):   # grade 6 computing, art and music kinds (school_picture_g6arts.gd)
		SchoolPictureG6Arts.draw(self, data, r)
		return
	if SchoolPictureG6Health.KINDS.has(str(data.kind)):   # grade 6 health, D&T and projects kinds (school_picture_g6health.gd)
		SchoolPictureG6Health.draw(self, data, r)
		return
	if SchoolPictureG6Core.KINDS.has(str(data.kind)):   # grade 6 maths, science and English kinds (school_picture_g6core.gd)
		SchoolPictureG6Core.draw(self, data, r)
		return
	if SchoolPictureG7Arts.KINDS.has(str(data.kind)):   # grade 7 computing, art and music kinds (school_picture_g7arts.gd)
		SchoolPictureG7Arts.draw(self, data, r)
		return
	if SchoolPictureG7Hum.KINDS.has(str(data.kind)):   # grade 7 history, geography and citizenship kinds (school_picture_g7hum.gd)
		SchoolPictureG7Hum.draw(self, data, r)
		return
	if SchoolPictureG7Life.KINDS.has(str(data.kind)):   # grade 7 health, D&T and projects kinds (school_picture_g7life.gd)
		SchoolPictureG7Life.draw(self, data, r)
		return
	if SchoolPictureG8Hum.KINDS.has(str(data.kind)):   # grade 8 history, geography and citizenship kinds (school_picture_g8hum.gd)
		SchoolPictureG8Hum.draw(self, data, r)
		return
	if SchoolPictureG8Arts.KINDS.has(str(data.kind)):   # grade 8 computing, art and music kinds (school_picture_g8arts.gd)
		SchoolPictureG8Arts.draw(self, data, r)
		return
	if SchoolPictureG8Life.KINDS.has(str(data.kind)):   # grade 8 health, D&T and projects kinds (school_picture_g8life.gd)
		SchoolPictureG8Life.draw(self, data, r)
		return
	if SchoolPictureG7Core.KINDS.has(str(data.kind)):   # grade 7 maths, science and English kinds (school_picture_g7core.gd)
		SchoolPictureG7Core.draw(self, data, r)
		return
	if SchoolPictureG8Core.KINDS.has(str(data.kind)):   # grade 8 maths, science and English kinds (school_picture_g8core.gd)
		SchoolPictureG8Core.draw(self, data, r)
		return
	if SchoolPictureQuality.KINDS.has(str(data.kind)):   # owner #94's lesson-quality kinds (school_picture_quality.gd)
		SchoolPictureQuality.draw(self, data, r)
		return
	match str(data.kind):
		"blocks":
			_draw_base_ten(r)
		"array":
			_draw_array(r)
		"groups":
			_draw_groups(r)
		"bar":
			_draw_bars(r)
		"number_line":
			_draw_number_line(r)
		"rect":
			_draw_farm(r)
		"angle":
			_draw_angle(r)
		"lines":
			_draw_lines(r)
		"shape":
			_draw_shape(r)
		"line_plot":
			_draw_line_plot(r)
		"layers":
			_draw_layers(r)
		"towers":
			_draw_towers(r)
		"clock":
			_draw_clock(r)
		"table":
			_draw_table(r)
		"icon":
			_draw_icon(r)


# --- Kinds -----------------------------------------------------------------------------------------------------

func _draw_base_ten(r: Rect2) -> void:
	var counts: Array[int] = [_int(data, "thousands", 0), _int(data, "hundreds", 0), _int(data, "tens", 0), _int(data, "ones", 0)]
	# widths in units: a thousand cube 13, a hundred flat 10.6, a ten rod 1.6, the ones two columns 2.6; gaps 1.2
	var units := counts[0] * 14.2 + counts[1] * 11.8 + counts[2] * 1.6 + (2.6 if counts[3] > 0 else 0.0) + 1.2
	var u := minf(r.size.x / maxf(units, 1.0), r.size.y / 13.5)
	var x := r.position.x + (r.size.x - units * u) * 0.5
	var bottom := r.end.y - (r.size.y - 13.0 * u) * 0.5
	var cols: Array[Color] = [Color("f08a1c"), Color("3a7be8"), Color("2fae4e"), Color("e5b700")]
	for i in counts[0]:
		_cube(Vector2(x, bottom), 10.0 * u, 3.0 * u, cols[0])
		x += 14.2 * u
	for i in counts[1]:
		_grid_rect(Rect2(x, bottom - 10.0 * u, 10.0 * u, 10.0 * u), 10, 10, cols[1])
		x += 11.8 * u
	for i in counts[2]:
		_grid_rect(Rect2(x, bottom - 10.0 * u, u, 10.0 * u), 1, 10, cols[2])
		x += 1.6 * u
	for i in counts[3]:
		_grid_rect(Rect2(x + (i % 2) * 1.3 * u, bottom - (int(i / 2.0) + 1) * 1.3 * u, u, u), 1, 1, cols[3])


func _draw_array(r: Rect2) -> void:
	var rows := _int(data, "rows", 1)
	var cols := _int(data, "cols", 1)
	var cell := minf(minf(r.size.x / cols, r.size.y / rows), 44.0)
	var origin := r.position + (r.size - Vector2(cols, rows) * cell) * 0.5
	var tex := BlockIcons.icon(_int(data, "block", BlockIds.BRICK))
	for y in rows:
		for x in cols:
			_block(Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell)).grow(-1.5), tex)


func _draw_groups(r: Rect2) -> void:
	var g := _int(data, "groups", 1)
	var each := _int(data, "each", 0)
	var left := _int(data, "left", 0)
	var per_row := mini(g + (1 if left > 0 else 0), 5)
	var rows := ceili(float(g + (1 if left > 0 else 0)) / per_row)
	var box := Vector2(r.size.x / per_row, r.size.y / rows)
	var inner := ceili(sqrt(maxf(each, left)))
	var cell := minf(minf((box.x - 18.0) / maxi(inner, 1), (box.y - 18.0) / maxi(inner, 1)), 30.0)
	var tex := BlockIcons.icon(BlockIds.PLANKS)
	for i in g + (1 if left > 0 else 0):
		var at := r.position + Vector2(i % per_row, int(i / float(per_row))) * box
		var frame := Rect2(at, box).grow(-5)
		var n := each if i < g else left
		if i < g:
			_rounded(frame, Color(0, 0, 0, 0), SchoolUi.INK)
		var start := frame.get_center() - Vector2(inner, ceili(float(n) / maxi(inner, 1))) * cell * 0.5
		for k in n:
			_block(Rect2(start + Vector2(k % maxi(inner, 1), int(k / float(maxi(inner, 1)))) * cell, Vector2(cell, cell)).grow(-1), tex)


func _draw_bars(r: Rect2) -> void:
	var bars := _bars(data)
	var h := minf(r.size.y / bars.size(), 70.0)
	var y := r.position.y + (r.size.y - h * bars.size()) * 0.5
	for b: Dictionary in bars:
		var den := _int(b, "den", 1)
		var num := _int(b, "num", 0)
		var label_w := 76.0
		var bar := Rect2(r.position.x + label_w, y + 6, r.size.x - label_w, h - 12)
		if den == 100:
			var side := minf(bar.size.y, bar.size.x)
			bar = Rect2(bar.position, Vector2(side, side))
			var c := side / 10.0
			for k in 100:
				var cell := Rect2(bar.position + Vector2(k % 10, int(k / 10.0)) * c, Vector2(c, c))
				draw_rect(cell, SHADE if k < num else Color.WHITE)
				draw_rect(cell, SchoolUi.INK, false, 1.0)
		else:
			var w := bar.size.x / den
			for k in den:
				var cell := Rect2(bar.position + Vector2(k * w, 0), Vector2(w, bar.size.y))
				draw_rect(cell, SHADE if k < num else Color.WHITE)
				draw_rect(cell, SchoolUi.INK, false, 2.0)
		_text(Vector2(r.position.x + label_w * 0.5, y + h * 0.5 + 8), "%d/%d" % [num, den], FONT)
		y += h


func _draw_number_line(r: Rect2) -> void:
	var from_t := str(data.from)
	var step_t := str(data.step)
	var from := NumberAnswer.value(from_t)
	var to := NumberAnswer.value(str(data.to))
	var step := NumberAnswer.value(step_t)
	var n := roundi((to - from) / step)
	var y := r.position.y + r.size.y * 0.55
	var x0 := r.position.x + 24.0
	var x1 := r.end.x - 24.0
	var at := func(v: float) -> float: return x0 + (v - from) / (to - from) * (x1 - x0)
	draw_line(Vector2(x0 - 16, y), Vector2(x1 + 16, y), SchoolUi.INK, LINE_W)
	var labels := str(data.get("labels", "ends"))
	for i in n + 1:
		var x: float = at.call(from + i * step)
		var big := i == 0 or i == n
		draw_line(Vector2(x, y - (14 if big else 9)), Vector2(x, y + (14 if big else 9)), SchoolUi.INK, LINE_W)
		if labels == "all" or (labels == "ends" and big):
			_text(Vector2(x, y + 42), _tick_label(from_t, step_t, i), FONT - (4 if n > 12 and labels == "all" else 0))
	for m: Variant in data.get("marks", []):
		var mx: float = at.call(NumberAnswer.value(str(m)))
		draw_colored_polygon(PackedVector2Array([Vector2(mx, y - 12), Vector2(mx - 9, y - 28), Vector2(mx + 9, y - 28)]),
			Color("3a7be8"))
		_text(Vector2(mx, y - 36), str(m), FONT - 2)
	if data.get("dot") != null:
		var dx: float = at.call(NumberAnswer.value(str(data.dot)))
		draw_circle(Vector2(dx, y), 11.0, SHADE)
		draw_arc(Vector2(dx, y), 11.0, 0, TAU, 24, SchoolUi.INK, 2.0, true)


func _draw_farm(r: Rect2) -> void:
	var w := _int(data, "w", 1)
	var h := _int(data, "h", 1)
	var unit := str(data.get("unit", ""))
	var cell := minf(minf((r.size.x - 90.0) / w, (r.size.y - 60.0) / h), 40.0)
	var size_px := Vector2(w, h) * cell
	var origin := r.position + Vector2((r.size.x - size_px.x) * 0.5 + 20.0, (r.size.y - size_px.y) * 0.5 + 10.0)
	var field := Rect2(origin, size_px)
	draw_rect(field, Color("7cc34a"))
	if bool(data.get("grid", true)):
		for x in range(1, w):
			draw_line(field.position + Vector2(x * cell, 0), field.position + Vector2(x * cell, size_px.y), Color("5a9a32"), 1.5)
		for y in range(1, h):
			draw_line(field.position + Vector2(0, y * cell), field.position + Vector2(size_px.x, y * cell), Color("5a9a32"), 1.5)
	draw_rect(field, Color("8d5a2b"), false, 5.0)   # the fence
	var unknown := str(data.get("unknown", ""))
	var wl := "?" if unknown == "w" else str(data.get("label_w", ("%d %s" % [w, unit]).strip_edges()))
	var hl := "?" if unknown == "h" else str(data.get("label_h", ("%d %s" % [h, unit]).strip_edges()))
	_text(Vector2(field.get_center().x, field.position.y - 8), wl, FONT)
	_text(Vector2(field.position.x - 40, field.get_center().y + 8), hl, FONT)


func _draw_angle(r: Rect2) -> void:
	var deg := _int(data, "deg", 90)
	var reflex := deg > 180
	var c := Vector2(r.get_center().x, r.end.y - 20.0) if not reflex else r.get_center()
	var reach := minf(r.size.x * 0.42, r.size.y * (0.85 if not reflex else 0.45))
	var dir := func(a: float) -> Vector2: return Vector2(cos(-deg_to_rad(a)), sin(-deg_to_rad(a)))
	if bool(data.get("protractor", false)) and not reflex:
		draw_arc(c, reach, PI, TAU, 48, Color("9fb4d8"), 2.0, true)
		for a in range(0, 181, 10):
			var d: Vector2 = dir.call(float(a))
			draw_line(c + d * (reach - (14 if a % 30 == 0 else 8)), c + d * reach, Color("6b7fa8"), 2.0)
			if a % 30 == 0:
				_text(c + d * (reach + 18) + Vector2(0, 8), str(a), FONT - 6, Color("6b7fa8"))
	draw_line(c, c + dir.call(0.0) * reach, SchoolUi.INK, LINE_W + 1)
	draw_line(c, c + dir.call(float(deg)) * reach, SchoolUi.INK, LINE_W + 1)
	var parts: Array = data.get("parts", [])
	if parts.size() == 2:
		draw_line(c, c + dir.call(float(parts[0])) * reach, Color("3a7be8"), LINE_W)
		var hide := _int(data, "hide", -1)
		_arc_label(c, 0.0, float(parts[0]), reach * 0.32, "?" if hide == 0 else "%d°" % int(parts[0]))
		_arc_label(c, float(parts[0]), float(deg), reach * 0.48, "?" if hide == 1 else "%d°" % int(parts[1]))
	elif deg == 90 and not bool(data.get("show", false)):
		var s := reach * 0.12
		draw_polyline(PackedVector2Array([c + Vector2(s, 0), c + Vector2(s, -s), c + Vector2(0, -s)]), SchoolUi.INK, 2.0)
	elif bool(data.get("show", false)) or bool(data.get("unknown", false)):
		_arc_label(c, 0.0, float(deg), reach * 0.3, "?" if bool(data.get("unknown", false)) else "%d°" % deg)
	draw_circle(c, 5.0, SchoolUi.INK)


func _draw_lines(r: Rect2) -> void:
	var c := r.get_center()
	var half := r.size.x * 0.36
	match str(data.what):
		"point":
			draw_circle(c, 9.0, SchoolUi.INK)
			_text(c + Vector2(0, -20), "A", FONT)
		"line":
			_arrow_line(c - Vector2(half, 0), c + Vector2(half, 0), true, true)
			_point(c - Vector2(half * 0.5, 0), "A")
			_point(c + Vector2(half * 0.5, 0), "B")
		"ray":
			_arrow_line(c - Vector2(half, 0), c + Vector2(half, 0), false, true)
			_point(c - Vector2(half, 0), "A")
			_point(c + Vector2(half * 0.3, 0), "B")
		"segment":
			draw_line(c - Vector2(half, 0), c + Vector2(half, 0), SchoolUi.INK, LINE_W)
			_point(c - Vector2(half, 0), "A")
			_point(c + Vector2(half, 0), "B")
		"parallel":
			for dy: float in [-r.size.y * 0.2, r.size.y * 0.2]:
				_arrow_line(c + Vector2(-half, dy), c + Vector2(half, dy), true, true)
				_chevron(c + Vector2(0, dy))
		"perpendicular":
			_arrow_line(c - Vector2(half, 0), c + Vector2(half, 0), true, true)
			_arrow_line(c + Vector2(0, r.size.y * 0.4), c - Vector2(0, r.size.y * 0.4), true, true)
			var s := 16.0
			draw_polyline(PackedVector2Array([c + Vector2(s, 0), c + Vector2(s, -s), c + Vector2(0, -s)]), SchoolUi.INK, 2.0)
		"intersecting":
			var d := Vector2(cos(deg_to_rad(35)), sin(deg_to_rad(35))) * half
			_arrow_line(c - Vector2(half, 0), c + Vector2(half, 0), true, true)
			_arrow_line(c - d, c + d, true, true)


func _draw_shape(r: Rect2) -> void:
	var what := str(data.what)
	var box := minf(r.size.x, r.size.y) * 0.86
	if what == "circle":
		draw_circle(r.get_center(), box * 0.5, SOFT)
		draw_arc(r.get_center(), box * 0.5, 0, TAU, 64, SchoolUi.INK, LINE_W, true)
		if bool(data.get("symmetry", false)):
			for a in 4:
				var d := Vector2(cos(a * PI / 4), sin(a * PI / 4)) * box * 0.55
				_dashed(r.get_center() - d, r.get_center() + d)
		return
	var unit := ShapeFacts.points(what)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in unit:
		lo = lo.min(p)
		hi = hi.max(p)
	var k := minf(r.size.x * 0.86 / maxf(hi.x - lo.x, 0.01), r.size.y * 0.86 / maxf(hi.y - lo.y, 0.01))
	var offset := r.get_center() - (lo + hi) * 0.5 * k
	var pts := PackedVector2Array()
	for p in unit:
		pts.append(offset + p * k)
	draw_colored_polygon(pts, SOFT)
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, SchoolUi.INK, LINE_W, true)
	if bool(data.get("marks", false)):
		for i in pts.size():
			var a := (pts[i - 1] - pts[i]).normalized()
			var b := (pts[(i + 1) % pts.size()] - pts[i]).normalized()
			if absf(a.dot(b)) < 0.01:
				var s := 14.0
				draw_polyline(PackedVector2Array([pts[i] + a * s, pts[i] + (a + b) * s, pts[i] + b * s]), SchoolUi.INK, 2.0)
	if bool(data.get("symmetry", false)):
		for line in _symmetry_lines(what, pts):
			_dashed(line[0], line[1])


func _draw_line_plot(r: Rect2) -> void:
	var den := _int(data, "den", 8)
	var from := _int(data, "from", 0)
	var to := _int(data, "to", den)
	var n := to - from
	var y := r.end.y - 50.0
	var x0 := r.position.x + 30.0
	var x1 := r.end.x - 30.0
	draw_line(Vector2(x0 - 14, y), Vector2(x1 + 14, y), SchoolUi.INK, LINE_W)
	for i in n + 1:
		var x := x0 + (x1 - x0) * i / n
		var k := from + i
		draw_line(Vector2(x, y - 8), Vector2(x, y + 8), SchoolUi.INK, 2.0)
		_text(Vector2(x, y + 32), "0" if k == 0 else "%d/%d" % [k, den], FONT - (6 if n > 8 else 2))
		var count := int((data.counts as Dictionary).get(str(k), 0))
		for j in count:
			_text(Vector2(x, y - 16 - j * 26), "X", FONT, Color("3a7be8"))
	var unit := str(data.get("unit", ""))
	if unit != "":
		_text(Vector2((x0 + x1) * 0.5, r.end.y - 2), unit, FONT - 4)


func _draw_layers(r: Rect2) -> void:
	var blocks: Array = data.blocks
	var fossils: Dictionary = data.get("fossils", {})
	var labels := bool(data.get("labels", false))
	var width := r.size.x - (130.0 if labels else 0.0)
	var h := r.size.y / blocks.size()
	var cell := minf(h, 40.0)
	for i in blocks.size():
		var band := Rect2(r.position.x, r.end.y - (i + 1) * h, width, h)
		var tex := BlockIcons.icon(int(blocks[i]))
		var x := band.position.x
		while x < band.end.x - 0.5:
			var w := minf(cell, band.end.x - x)
			if tex:
				draw_texture_rect_region(tex, Rect2(x, band.position.y, w, h), Rect2(Vector2.ZERO, Vector2(tex.get_width() * w / cell, tex.get_height())))
			x += cell
		draw_line(band.position, band.position + Vector2(width, 0), Color(0, 0, 0, 0.35), 2.0)
		if fossils.has(str(i)):
			_fossil(str(fossils[str(i)]), band.get_center(), minf(h * 0.4, 26.0))
	if labels:
		_text(Vector2(r.end.x - 60, r.position.y + 24), "youngest", FONT - 4)
		_text(Vector2(r.end.x - 60, r.end.y - 8), "oldest", FONT - 4)
		draw_line(Vector2(r.end.x - 60, r.end.y - 34), Vector2(r.end.x - 60, r.position.y + 36), SchoolUi.INK, 2.0)


# --- Grade 4 science kinds (owner #68, the grade 4 agent) -----------------------------------------------------------
## - wave {waves: [{amp: 1-4, count: 1-8}] (1-3 waves, one under another), names? (A, B, C at their left), labels?
##   (one wave only: any of "crest", "trough", "amplitude", "wavelength")}: waves on their middle line; `count` is how
##   many wavelengths fit across, so more of them means a shorter wavelength.
## - pixels {rows: ["01110", …] (1-8 rows of 1-12 digits, all as long), digits?}: a picture sent as 1s and 0s: 1 is a
##   dark square, 0 a light one (digits: each row's numbers beside it).
## - map {rows: ["~~v..^", …] (1-8 rows of 1-14 letters, all as long), key?}: "~" sea, "=" deep trench, "." land,
##   "^" mountain, "v" volcano, "*" an earthquake on land, "x" one under the sea; key: what each shown thing means.
## - rays {source: "sun" | "lamp" | "none", object: a block id, mirror?}: light from its source to the object and on
##   into an eye (bouncing off a mirror when mirror); "none" is a dark cave: no light, so nothing is seen.

const WAVE_LABELS: Array[String] = ["crest", "trough", "amplitude", "wavelength"]
const MAP_ORDER := "~=.^v*x"
const MAP_KEY := {"~": "sea", "=": "deep trench", ".": "land", "^": "mountain", "v": "volcano", "*": "earthquake",
	"x": "earthquake"}
const LIGHT_SOURCES: Array[String] = ["sun", "lamp", "none"]
const MAX_PIXELS := Vector2i(12, 8)
const MAX_MAP := Vector2i(14, 8)
const WAVE := Color("2f7fd8")
const SEA := Color("6db3ec")
const TRENCH := Color("1d4f91")
const LAND := Color("93cf6e")
const ROCK := Color("8d8a86")
const VOLCANO := Color("8a5a3c")
const LAVA := Color("e5482b")
const SUN := Color("ffc93c")
const RAY := Color("f0a500")


static func _science_problem(p: Dictionary) -> String:
	match str(p.kind):
		"wave":
			var waves: Variant = p.get("waves")
			if not waves is Array or (waves as Array).is_empty() or (waves as Array).size() > 3:
				return "1-3 waves"
			for w: Variant in waves:
				if not w is Dictionary or not _in(_int(w, "amp", 0), 1, 4) or not _in(_int(w, "count", 0), 1, 8):
					return "a wave needs amp 1-4 and count 1-8"
			var labels: Variant = p.get("labels", [])
			if not labels is Array:
				return "labels: a list"
			for l: Variant in labels:
				if not WAVE_LABELS.has(str(l)):
					return "a wave's labels: %s" % [WAVE_LABELS]
			if not (labels as Array).is_empty() and (waves as Array).size() != 1:
				return "labels on a single wave only"
		"pixels":
			return _grid_problem(p.get("rows"), "01", MAX_PIXELS)
		"map":
			return _grid_problem(p.get("rows"), MAP_ORDER, MAX_MAP)
		"rays":
			if not LIGHT_SOURCES.has(str(p.get("source", ""))):
				return "a source: %s" % [LIGHT_SOURCES]
			if typeof(p.get("object")) not in [TYPE_INT, TYPE_FLOAT] or BlockIcons.icon(int(p.object)) == null:
				return "an object: a block id"
	return ""


## Rows of letters, all as long, each one of `letters`, at most `most` (columns, rows).
static func _grid_problem(rows: Variant, letters: String, most: Vector2i) -> String:
	if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > most.y:
		return "1-%d rows" % most.y
	var w := str(rows[0]).length()
	if w < 1 or w > most.x:
		return "rows of 1-%d" % most.x
	for row: Variant in rows:
		if str(row).length() != w:
			return "rows all as long"
		for ch in str(row):
			if not letters.contains(ch):
				return "'%s' is not one of %s" % [ch, letters]
	return ""


## The wave's line across `r`: `count` wavelengths, starting on the middle line and rising, its crests `amp_px` above
## the middle line (screen y grows downwards); a point lands exactly on every crest and trough. Owner #94: `phase`
## (radians, SchoolPictureMotion.wave_phase) moves the wave to the right as it travels.
static func wave_line(r: Rect2, amp_px: float, count: int, phase: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 48 * maxi(count, 1)
	var mid := r.get_center().y
	for i in steps + 1:
		var t := float(i) / steps
		pts.append(Vector2(r.position.x + t * r.size.x, mid - amp_px * sin(TAU * count * t - phase)))
	return pts


## What a map's key lists: the name of every thing the map shows, once, in MAP_ORDER.
static func map_key(rows: Array) -> Array[String]:
	var out: Array[String] = []
	for ch in MAP_ORDER:
		for row: Variant in rows:
			if str(row).contains(ch) and not out.has(MAP_KEY[ch]):
				out.append(MAP_KEY[ch])
	return out


func _draw_science(r: Rect2) -> void:
	match str(data.kind):
		"wave":
			_draw_waves(r)
		"pixels":
			_draw_pixels(r)
		"map":
			_draw_map(r)
		"rays":
			_draw_rays(r)


func _draw_waves(r: Rect2) -> void:
	var waves: Array = data.waves
	var labels: Array = data.get("labels", [])
	var band_h := r.size.y / waves.size()
	for i in waves.size():
		var band := Rect2(r.position.x, r.position.y + i * band_h, r.size.x, band_h)
		if bool(data.get("names", false)):
			_text(Vector2(band.position.x + 16, band.get_center().y + 10), ["A", "B", "C"][i], FONT + 4)
			band = band.grow_individual(-44, 0, 0, 0)
		if not labels.is_empty():
			band = band.grow_individual(-8, -58, -8, -30)
		var w: Dictionary = waves[i]
		var count := _int(w, "count", 1)
		var amp := _int(w, "amp", 1) / 4.0 * (band.size.y * 0.5 - 6.0)
		draw_dashed_line(Vector2(band.position.x, band.get_center().y), Vector2(band.end.x, band.get_center().y),
			Color(0, 0, 0, 0.25), 2.0, 8.0)
		draw_polyline(wave_line(band, amp, count, SchoolPictureMotion.wave_phase(count, time_of(self))), WAVE, 4.0, true)
		if not labels.is_empty():
			_wave_labels(band, amp, count, labels)


## Labels on a single wave: its first crest and trough, a wavelength from crest to crest above it, the amplitude from
## the middle line up to its last crest.
func _wave_labels(band: Rect2, amp: float, count: int, labels: Array) -> void:
	var wl := band.size.x / count
	var mid := band.get_center().y
	var crest := Vector2(band.position.x + wl * 0.25, mid - amp)
	if labels.has("crest"):
		_text(crest + Vector2(0, -10), "crest", FONT - 4)
	if labels.has("trough"):
		_text(Vector2(band.position.x + wl * 0.75, mid + amp + 24), "trough", FONT - 4)
	if labels.has("wavelength"):
		var y := mid - amp - 34
		var a := Vector2(crest.x if count > 1 else band.position.x, y)
		var b := Vector2(crest.x + wl if count > 1 else band.end.x, y)
		_ray(a, b, SchoolUi.INK, true)
		_ray(b, a, SchoolUi.INK, true)
		for x: float in [a.x, b.x]:
			draw_dashed_line(Vector2(x, y), Vector2(x, mid - amp if count > 1 else mid), Color(0, 0, 0, 0.35), 2.0, 6.0)
		_text(Vector2((a.x + b.x) * 0.5, y - 8), "wavelength", FONT - 4)
	if labels.has("amplitude"):
		var x := band.position.x + wl * (count - 0.75)
		_ray(Vector2(x, mid), Vector2(x, mid - amp), Color("d9463b"), true)
		var font := get_theme_default_font()
		draw_string(font, Vector2(x + 10, mid - amp * 0.5 + 8), "amplitude", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT - 4,
			Color("d9463b"))


func _draw_pixels(r: Rect2) -> void:
	var rows: Array = data.rows
	var n_cols := str(rows[0]).length()
	var digits := bool(data.get("digits", false))
	var text_w := n_cols * 20.0 + 20.0 if digits else 0.0
	var side := minf(minf((r.size.x - text_w) / n_cols, r.size.y / rows.size()), 44.0)
	var origin := r.position + (r.size - Vector2(side * n_cols + text_w, side * rows.size())) * 0.5
	var font := get_theme_default_font()
	for y in rows.size():
		var row := str(rows[y])
		for x in n_cols:
			var cell := Rect2(origin + Vector2(x, y) * side, Vector2(side, side))
			draw_rect(cell, SchoolUi.INK if row[x] == "1" else Color.WHITE)
			draw_rect(cell, Color(0.55, 0.55, 0.6), false, 1.5)
		if digits:
			var spaced := ""
			for ch in row:
				spaced += ch + " "
			draw_string(font, Vector2(origin.x + side * n_cols + 20, origin.y + (y + 0.5) * side + 8), spaced.strip_edges(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, mini(FONT, int(side * 0.8)), SchoolUi.INK)


func _draw_map(r: Rect2) -> void:
	var rows: Array = data.rows
	var key: Array[String] = []
	if bool(data.get("key", false)):
		key = map_key(rows)
	var key_w := 200.0 if not key.is_empty() else 0.0
	var n_cols := str(rows[0]).length()
	var side := minf(minf((r.size.x - key_w) / n_cols, r.size.y / rows.size()), 48.0)
	var origin := r.position + Vector2((r.size.x - key_w - side * n_cols) * 0.5, (r.size.y - side * rows.size()) * 0.5)
	for y in rows.size():
		for x in n_cols:
			_map_cell(Rect2(origin + Vector2(x, y) * side, Vector2(side, side)), str(rows[y])[x])
	draw_rect(Rect2(origin, Vector2(side * n_cols, side * rows.size())), SchoolUi.INK, false, 2.0)
	if key.is_empty():
		return
	var font := get_theme_default_font()
	var line_h := minf(r.size.y / key.size(), 40.0)
	var top := r.position.y + (r.size.y - line_h * key.size()) * 0.5
	var box := minf(line_h - 6.0, 30.0)
	for i in key.size():
		var sym := "~"
		for ch in MAP_ORDER:
			if MAP_KEY[ch] == key[i]:
				sym = ch
				break
		var cell := Rect2(Vector2(r.end.x - key_w + 14, top + i * line_h + (line_h - box) * 0.5), Vector2(box, box))
		_map_cell(cell, sym)
		draw_rect(cell, SchoolUi.INK, false, 1.5)
		draw_string(font, Vector2(cell.end.x + 10, cell.get_center().y + 7), key[i], HORIZONTAL_ALIGNMENT_LEFT, -1,
			FONT - 3, SchoolUi.INK)


func _map_cell(cell: Rect2, ch: String) -> void:
	draw_rect(cell, SEA if ch in ["~", "x"] else (TRENCH if ch == "=" else LAND))
	draw_rect(cell, Color(0, 0, 0, 0.08), false, 1.0)
	var c := cell.get_center()
	var s := cell.size.x
	match ch:
		"^":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.42, s * 0.36), c + Vector2(0, -s * 0.38),
				c + Vector2(s * 0.42, s * 0.36)]), ROCK)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.13, -s * 0.13), c + Vector2(0, -s * 0.38),
				c + Vector2(s * 0.13, -s * 0.13)]), Color.WHITE)
		"v":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.44, s * 0.36), c + Vector2(-s * 0.12, -s * 0.3),
				c + Vector2(s * 0.12, -s * 0.3), c + Vector2(s * 0.44, s * 0.36)]), VOLCANO)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.12, -s * 0.3), c + Vector2(0, -s * 0.12),
				c + Vector2(s * 0.12, -s * 0.3)]), LAVA)
			draw_circle(c + Vector2(0, -s * 0.38), s * 0.07, LAVA)
		"*", "x":
			draw_circle(c, s * 0.16, LAVA)
			draw_arc(c, s * 0.32, 0, TAU, 20, LAVA, 2.0, true)


func _draw_rays(r: Rect2) -> void:
	var source := str(data.source)
	var s := minf(r.size.y * 0.32, 84.0)
	if source == "none":
		var cave := StyleBoxFlat.new()
		cave.bg_color = Color("1b1b2a")
		cave.set_corner_radius_all(12)
		draw_style_box(cave, r)
	var src := r.position + Vector2(s * 0.7, s * 0.7)
	var obj := Rect2(Vector2(r.position.x + r.size.x * 0.32 - s * 0.5, r.end.y - s - 4), Vector2(s, s))
	var eye := Vector2(r.end.x - s * 0.75, obj.get_center().y)
	var tex := BlockIcons.icon(int(data.object))
	if tex:
		draw_texture_rect(tex, obj, false, Color(0.22, 0.22, 0.3) if source == "none" else Color.WHITE)
	_eye(eye, s * 1.1)
	match source:
		"sun":
			draw_circle(src, s * 0.36, SUN)
			for i in 8:
				var d := Vector2.RIGHT.rotated(TAU * i / 8.0)
				draw_line(src + d * s * 0.46, src + d * s * 0.62, SUN, 4.0)
		"lamp":
			var lamp := BlockIcons.icon(BlockIds.LANTERN)
			if lamp:
				draw_texture_rect(lamp, Rect2(src - Vector2(s, s) * 0.45, Vector2(s, s) * 0.9), false)
		"none":
			return
	var o := obj.get_center()
	_ray(src + (o - src).normalized() * s * 0.6, o + (src - o).normalized() * s * 0.55, RAY, false)
	if bool(data.get("mirror", false)):
		var m := Vector2((o.x + eye.x) * 0.5, r.position.y + 12)
		draw_line(m - Vector2(s * 0.7, 0), m + Vector2(s * 0.7, 0), Color("a9d8f5"), 10.0)
		draw_line(m + Vector2(-s * 0.7, -6), m + Vector2(s * 0.7, -6), SchoolUi.INK, 3.0)   # its back, facing up
		var hit := m + Vector2(0, 8)
		_ray(o + (hit - o).normalized() * s * 0.55, hit, RAY, false)
		_ray(hit, eye + (hit - eye).normalized() * s * 0.55, RAY, false)
	else:
		_ray(o + (eye - o).normalized() * s * 0.55, eye + (o - eye).normalized() * s * 0.6, RAY, false)


## A line from a to b with an arrowhead at b (`thin`: the measuring arrows of a wave's labels).
func _ray(a: Vector2, b: Vector2, color: Color, thin: bool) -> void:
	draw_line(a, b, color, 2.5 if thin else 4.5)
	var back := (a - b).normalized() * (12.0 if thin else 18.0)
	var side := back.orthogonal() * 0.5
	draw_colored_polygon(PackedVector2Array([b, b + back + side, b + back - side]), color)


## An eye looking left: white, a blue iris and its pupil.
func _eye(c: Vector2, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		pts.append(c + Vector2((i / 16.0 - 0.5) * w, -sin(i / 16.0 * PI) * w * 0.3))
	for i in range(15, 0, -1):
		pts.append(c + Vector2((i / 16.0 - 0.5) * w, sin(i / 16.0 * PI) * w * 0.3))
	draw_colored_polygon(pts, Color.WHITE)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, SchoolUi.INK, 2.5, true)
	draw_circle(c + Vector2(-w * 0.12, 0), w * 0.19, Color("3a7be8"))
	draw_circle(c + Vector2(-w * 0.12, 0), w * 0.08, Color.BLACK)


func _draw_towers(r: Rect2) -> void:
	var heights: Array = data.heights
	var missing := bool(data.get("missing", false))
	var count := heights.size() + (1 if missing else 0)
	var tallest := 1
	for v: Variant in heights:
		tallest = maxi(tallest, int(v))
	var cell := minf(minf((r.size.y - 34.0) / tallest, r.size.x / (count * 1.8)), 36.0)
	var gap := r.size.x / count
	var tex := BlockIcons.icon(BlockIds.BRICK)
	for i in count:
		var cx := r.position.x + gap * (i + 0.5)
		var ground := r.end.y - 30.0
		if i < heights.size():
			for k in int(heights[i]):
				_block(Rect2(cx - cell * 0.5, ground - (k + 1) * cell, cell, cell).grow(-1), tex)
		else:
			_text(Vector2(cx, ground - cell), "?", FONT + 18, SHADE)
		_text(Vector2(cx, r.end.y - 4), str(i + 1), FONT - 2)


func _draw_clock(r: Rect2) -> void:
	var c := r.get_center()
	var rad := minf(r.size.x, r.size.y) * 0.46
	draw_circle(c, rad, Color.WHITE)
	draw_arc(c, rad, 0, TAU, 64, SchoolUi.INK, LINE_W + 1, true)
	for i in range(1, 13):
		var a := -PI / 2 + TAU * i / 12.0
		_text(c + Vector2(cos(a), sin(a)) * rad * 0.8 + Vector2(0, 8), str(i), FONT - 2)
	var h := _int(data, "h", 12)
	var m := _int(data, "m", 0)
	var ha := -PI / 2 + TAU * ((h % 12) + m / 60.0) / 12.0
	var ma := -PI / 2 + TAU * m / 60.0
	draw_line(c, c + Vector2(cos(ha), sin(ha)) * rad * 0.5, SchoolUi.INK, 6.0)
	draw_line(c, c + Vector2(cos(ma), sin(ma)) * rad * 0.75, SchoolUi.INK, 3.5)
	draw_circle(c, 6.0, SchoolUi.INK)


func _draw_table(r: Rect2) -> void:
	var rows: Array = data.rows
	var cols := 0
	for row: Array in rows:
		cols = maxi(cols, row.size())
	var cw := minf(r.size.x / cols, 190.0)
	var ch := minf(r.size.y / rows.size(), 48.0)
	var origin := r.position + (r.size - Vector2(cw * cols, ch * rows.size())) * 0.5
	for y in rows.size():
		for x in cols:
			var cell := Rect2(origin + Vector2(x * cw, y * ch), Vector2(cw, ch))
			draw_rect(cell, Color("d9e6ff") if y == 0 else Color.WHITE)
			draw_rect(cell, SchoolUi.INK, false, 2.0)
			var row: Array = rows[y]
			if x < row.size():   # owner #94: long words shrink to fit their cell, never over the next one
				var fs := table_font_size(get_theme_default_font(), str(row[x]), cw - 6.0)
				_text(Vector2(cell.get_center().x, cell.get_center().y + fs * 0.36), str(row[x]), fs)


## Owner #94: the font size a table cell's words fit their cell at: FONT, or smaller (TABLE_LEAST_FONT at least).
static func table_font_size(font: Font, text: String, width: float) -> int:
	var fs := FONT
	while fs > TABLE_LEAST_FONT and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width:
		fs -= 1
	return fs


func _draw_icon(r: Rect2) -> void:
	if data.has("animal"):
		return   # AnimalPortrait children draw it
	var count := _int(data, "count", 1)
	var side := minf(r.size.y * 0.8, r.size.x / count - 8.0)
	var start := r.get_center() - Vector2(count * (side + 8.0) - 8.0, side) * 0.5
	for i in count:
		var box := Rect2(start + Vector2(i * (side + 8.0), 0), Vector2(side, side))
		if data.has("picture"):
			ProgressPictures.draw(self, StringName(str(data.picture)), box)
		else:
			var tex := BlockIcons.icon(int(data.block))
			if tex:
				draw_texture_rect(tex, box, false)


# --- Drawing helpers -----------------------------------------------------------------------------------------------

func _text(pos_center: Vector2, text: String, font_size: int = FONT, color: Color = SchoolUi.INK) -> void:
	var font := get_theme_default_font()
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(pos_center.x - w * 0.5, pos_center.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _block(rect: Rect2, tex: Texture2D) -> void:
	if tex:
		draw_texture_rect(tex, rect, false)
	else:
		draw_rect(rect, SHADE)
	draw_rect(rect, Color(0, 0, 0, 0.35), false, 1.5)


func _grid_rect(rect: Rect2, cols: int, rows: int, color: Color) -> void:
	draw_rect(rect, color)
	for x in range(1, cols):
		draw_line(rect.position + Vector2(rect.size.x * x / cols, 0), rect.position + Vector2(rect.size.x * x / cols, rect.size.y),
			color.darkened(0.3), 1.0)
	for y in range(1, rows):
		draw_line(rect.position + Vector2(0, rect.size.y * y / rows), rect.position + Vector2(rect.size.x, rect.size.y * y / rows),
			color.darkened(0.3), 1.0)
	draw_rect(rect, color.darkened(0.45), false, 1.5)


## A base-ten thousand: a front face of 10 × 10 with a top and a side in depth.
func _cube(bottom_left: Vector2, side: float, depth: float, color: Color) -> void:
	var front := Rect2(bottom_left - Vector2(0, side), Vector2(side, side))
	var d := Vector2(depth, -depth)
	draw_colored_polygon(PackedVector2Array([front.position, front.position + d, front.position + Vector2(side, 0) + d,
		front.position + Vector2(side, 0)]), color.lightened(0.25))
	draw_colored_polygon(PackedVector2Array([front.position + Vector2(side, 0), front.position + Vector2(side, 0) + d,
		front.end + d, front.end]), color.darkened(0.2))
	_grid_rect(front, 10, 10, color)


func _rounded(rect: Rect2, fill: Color, border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(3)
	sb.border_color = border
	draw_style_box(sb, rect)


func _arrow_line(a: Vector2, b: Vector2, head_a: bool, head_b: bool) -> void:
	draw_line(a, b, SchoolUi.INK, LINE_W)
	for pair: Array in [[head_a, a, b], [head_b, b, a]]:
		if pair[0]:
			var tip: Vector2 = pair[1]
			var back: Vector2 = (pair[2] - tip).normalized() * 16.0
			var side := back.orthogonal() * 0.55
			draw_colored_polygon(PackedVector2Array([tip, tip + back + side, tip + back - side]), SchoolUi.INK)


func _point(p: Vector2, label: String) -> void:
	draw_circle(p, 7.0, SchoolUi.INK)
	_text(p + Vector2(0, -16), label, FONT)


func _chevron(p: Vector2) -> void:
	draw_polyline(PackedVector2Array([p + Vector2(-6, -8), p + Vector2(4, 0), p + Vector2(-6, 8)]), SchoolUi.INK, 3.0)


func _dashed(a: Vector2, b: Vector2) -> void:
	draw_dashed_line(a, b, Color("d9463b"), 3.0, 10.0)


func _arc_label(c: Vector2, from_deg: float, to_deg: float, rad: float, text: String) -> void:
	draw_arc(c, rad, -deg_to_rad(to_deg), -deg_to_rad(from_deg), 32, Color("3a7be8"), 2.5, true)
	var mid := -deg_to_rad((from_deg + to_deg) * 0.5)
	_text(c + Vector2(cos(mid), sin(mid)) * (rad + 26.0) + Vector2(0, 8), text, FONT - 2)


func _fossil(kind: String, c: Vector2, s: float) -> void:
	var bone := Color("f5f0e1")
	match kind:
		"shell":
			for i in 3:
				draw_arc(c, s * (1.0 - i * 0.28), PI, TAU, 16, bone, 3.0, true)
			draw_line(c - Vector2(s, 0), c + Vector2(s, 0), bone, 3.0)
		"fish":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s, 0), c + Vector2(0, -s * 0.5), c + Vector2(s * 0.7, 0),
				c + Vector2(0, s * 0.5)]), bone)
			draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.6, 0), c + Vector2(s * 1.1, -s * 0.4),
				c + Vector2(s * 1.1, s * 0.4)]), bone)
		"leaf":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s, 0), c + Vector2(0, -s * 0.45), c + Vector2(s, 0),
				c + Vector2(0, s * 0.45)]), bone)
			draw_line(c - Vector2(s, 0), c + Vector2(s, 0), Color("b8a888"), 2.0)
		"bone":
			draw_line(c - Vector2(s * 0.8, 0), c + Vector2(s * 0.8, 0), bone, s * 0.3)
			for e: float in [-1.0, 1.0]:
				draw_circle(c + Vector2(e * s * 0.85, -s * 0.15), s * 0.2, bone)
				draw_circle(c + Vector2(e * s * 0.85, s * 0.15), s * 0.2, bone)
		"footprint":
			draw_circle(c, s * 0.45, bone)
			for i in 3:
				draw_circle(c + Vector2((i - 1) * s * 0.4, -s * 0.7), s * 0.16, bone)


## The shape's lines of symmetry as segments, from its drawn corners.
func _symmetry_lines(what: String, pts: PackedVector2Array) -> Array:
	var out: Array = []
	var n := pts.size()
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= n
	var candidates: Array = []
	for i in n:
		candidates.append([pts[i], c])
		candidates.append([(pts[i] + pts[(i + 1) % n]) * 0.5, c])
	for cand: Array in candidates:
		var a: Vector2 = cand[0]
		var dir := (a - c).normalized()
		if dir == Vector2.ZERO:
			continue
		var mirrored := true
		for p in pts:
			var rel := p - c
			var m := c + rel.reflect(dir.orthogonal())
			var found := false
			for q in pts:
				if q.distance_to(m) < 1.5:
					found = true
			mirrored = mirrored and found
		if mirrored:
			var dup := false
			for l: Array in out:
				if absf(((l[1] as Vector2) - (l[0] as Vector2)).normalized().cross(dir)) < 0.01:
					dup = true
			if not dup:
				var reach := 0.0
				for p in pts:
					reach = maxf(reach, p.distance_to(c))
				out.append([c - dir * (reach + 10.0), c + dir * (reach + 10.0)])
	return out


## A tick's words: fractions over the step's bottom ("3/8"), decimals to the step's places, whole numbers with commas.
static func _tick_label(from_t: String, step_t: String, i: int) -> String:
	var from := NumberAnswer.parse(from_t)
	var step := NumberAnswer.parse(step_t)
	if step_t.contains("/"):
		var den := int(step[1])
		var top := int(from[0]) * den / int(from[1]) + i * int(step[0])
		if top == 0:
			return "0"
		return str(top / den) if top % den == 0 else "%d/%d" % [top, den]
	if step_t.contains("."):
		var places := step_t.get_slice(".", 1).length()
		var v := NumberAnswer.value(from_t) + i * NumberAnswer.value(step_t)
		return String.num(v, places) if absf(v - roundf(v)) > 0.000001 else str(roundi(v))
	return GenKit.fmt(roundi(NumberAnswer.value(from_t) + i * NumberAnswer.value(step_t)))


static func _bars(p: Dictionary) -> Array:
	if p.get("bars") is Array:
		return (p.bars as Array).filter(func(b: Variant) -> bool: return b is Dictionary)
	return [p] if p.has("den") else []


static func _int(p: Dictionary, key: String, default: int) -> int:
	var v: Variant = p.get(key, default)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else default


static func _in(v: int, lo: int, hi: int) -> bool:
	return v >= lo and v <= hi
