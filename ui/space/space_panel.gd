class_name SpacePanel
extends Control
## The Star Map (owner feedback #55, spec §21.1; #72 and #74, spec §21b.1): what the sky shows when a flyer crosses the
## space line. Over the stars, our solar system in its real order out from the Sun with its moons, far away the game's
## own planets and every universe (StarMap), and the planet the child flew up from glowing at the bottom. A tap on a
## body opens its card: its name, three real facts (read aloud), and LAND (a built space world: travel_requested), HOME
## (home_requested) or honest words (coming soon, no ground, locked, a universe's portal). HOME also sits by STAY HERE
## when the child is in a space world. Why a trip can't happen shows above the buttons (say()). While it shows it
## takes every touch (the world and the HUD never hear one) and, when `hold` (a game played alone), the game holds
## still. Per device, never sent.

signal travel_requested(universe: int)
signal home_requested
signal stay_requested
## A body's card was opened (the Space Book learns it, spec §21b.2).
signal body_seen(id: StringName)
signal opened
signal closed

const TITLE_COLOR := Color("fff3b0")
const STAR_COUNT := 160
const STAR_SEED := 5505
const MAP_TOP := 84.0
const MAP_BOTTOM := 124.0         # the room under the map: the hint and the buttons
## Owner #91 ("animation, movements, cyrcle as it is in reality"): the solar system as a moving orrery. The Sun in the
## middle; each planet on its orbit (a tilted circle: an ellipse ORBIT_RX of the width across, TILT as tall) where it
## really is today (StarMap.longitude of the device's date), going round at its real year's speed with an Earth year
## lasting EARTH_YEAR_SECONDS; the moons round their planets (MOON_SECONDS a turn: slowed down, the real ones would
## blur). A card open holds everything still, so a moving planet is easy to tap.
const ORBIT_RX := {&"mercury": 0.075, &"venus": 0.12, &"earth": 0.165, &"mars": 0.21, &"jupiter": 0.27,
	&"saturn": 0.33, &"uranus": 0.385, &"neptune": 0.435, &"pluto": 0.475}
const TILT := 0.24
const EARTH_YEAR_SECONDS := 40.0
const SUN_RADIUS := 36.0
const MOON_GAP := 26.0            # a moon's ring: this far outside its planet's disc
## A planet's moons go round it together, evenly spaced (so a finger can pick each one), a turn in this many seconds.
const MOON_RING_SECONDS := {&"earth": 27.0, &"jupiter": 24.0, &"saturn": 20.0, &"neptune": 16.0}
const SOLAR_Y := 0.62             # the Sun's height, of the map's height
const FAR_Y := 0.13

## Pause the game while open (the sandbox: solo play).
var hold := false
var bodies: Array[StarBody] = []
var _days := 0.0                  # days since 2000 the orrery shows (the device's date at open, then sped up)
var _moon_t := 0.0
var stay_button: Button
var home_button: Button
var action_button: Button
var map_button: Button
## Universe 6 (brief, owner #72): PEEK on a locked universe's card that has a free peek (UniversePeek).
var peek_button: Button

var _title: Label
var _hint := Label.new()
var _card := PanelContainer.new()
var _card_picture: StarBody
var _card_holder := CenterContainer.new()
var _card_name: Label
var _facts: Array[Label] = []
var _state_words := Label.new()
var _selected: StringName = &""
var _states := {}
var _here := 1
var _planet := {"top": Color("5aa9f0"), "bottom": Color("bfe3ff"), "ground": Color("5cb85c")}
var _stars: PackedVector3Array = []
var _held := false

# --- Owner #110 (VR round 4, VR-WONDER, idea 1 "hold a planet"; docs/devlog/parts/vr-r4-wonder.md): in a headset the
# solar system is also a moving orrery within reach (VrOrrery, under Vr while the map is open); this map stays on the eye
# panel for the cards and the buttons. Off VR none of it is made and the map is as before. ---
const VR_HINT := "Take a planet in your hand! Drop it in the gold ring to fly there."
const TRUE_SIZE_WORD := "TRUE SIZE"
const ORRERY_WORD := "ORRERY"
## The orrery while the map is open in a headset, else null.
var vr_orrery: VrOrrery = null
## TRUE SIZE / ORRERY under the map (VR only): the orrery's planets in a row in their true sizes, or on their orbits.
var true_size_button: Button


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true   # the planet below stays inside the screen
	theme = UiKit.theme()
	var rng := RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	for i in STAR_COUNT:
		_stars.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.8, 2.6)))
	_title = UiKit.title(SpaceRules.TITLE, 44)
	_title.add_theme_color_override("font_color", TITLE_COLOR)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 14
	_title.offset_bottom = 74
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	for d in StarMap.bodies():
		var b := StarBody.new(d)
		b.pressed.connect(select.bind(d.id))
		if str(d.kind) == "star":   # the orrery's Sun in the middle, small enough for Mercury's orbit round it
			b.radius = SUN_RADIUS
			b.custom_minimum_size = Vector2(SUN_RADIUS * 2.0 + 8.0, SUN_RADIUS * 2.0 + 8.0 + StarBody.NAME_SIZE + 6.0)
			b.size = b.custom_minimum_size
		bodies.append(b)
	for b in bodies:   # planets first, their moons over them (a moon's tap wins where they touch)
		if str(b.data.kind) != "moon":
			add_child(b)
	for b in bodies:
		if str(b.data.kind) == "moon":
			add_child(b)
	_build_bottom()
	_build_card()
	resized.connect(_layout)
	_layout()
	PadFocus.watch(self)   # owner #90: the bodies, HOME and STAY HERE with a game controller
	PadFocus.watch(_card_holder)   # a body's card over the map has the pad while it shows (LAND, MAP)


func _build_bottom() -> void:
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 24)
	_hint.add_theme_color_override("font_color", Color("ffe14d"))
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -MAP_BOTTOM
	_hint.offset_bottom = -MAP_BOTTOM + 34
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -88
	row.offset_bottom = -8
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_button = UiKit.big_button(SpaceRules.HOME_WORD, UiKit.GREEN, Vector2(240, 76))
	home_button.focus_mode = Control.FOCUS_NONE
	home_button.pressed.connect(func() -> void: home_requested.emit())
	row.add_child(home_button)
	stay_button = UiKit.big_button(SpaceRules.STAY_WORD, UiKit.BLUE, Vector2(300, 76))
	stay_button.focus_mode = Control.FOCUS_NONE
	stay_button.pressed.connect(_on_stay)
	row.add_child(stay_button)
	true_size_button = UiKit.big_button(TRUE_SIZE_WORD, UiKit.ORANGE, Vector2(260, 76))   # owner #110: VR only
	true_size_button.name = "TrueSize"
	true_size_button.focus_mode = Control.FOCUS_NONE
	true_size_button.visible = false
	true_size_button.pressed.connect(_vr_true_size)
	row.add_child(true_size_button)
	add_child(row)


func _build_card() -> void:
	_card_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_holder.offset_top = MAP_TOP - 10
	_card_holder.offset_bottom = -MAP_BOTTOM + 4
	_card_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_holder.visible = false
	add_child(_card_holder)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.07, 0.18, 0.96)
	box.border_color = Color("ffe14d")
	box.set_border_width_all(3)
	box.set_corner_radius_all(24)
	box.set_content_margin_all(22)
	_card.add_theme_stylebox_override("panel", box)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card_holder.add_child(_card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	_card.add_child(row)
	_card_picture = StarBody.new({"id": &"card", "name": "", "kind": "planet", "size": 78.0, "color": Color.WHITE,
		"color2": Color.WHITE, "ring": true})   # room for Saturn's rings
	_card_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_card_picture)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size.x = 540
	row.add_child(column)
	_card_name = UiKit.title("", 38)
	_card_name.add_theme_color_override("font_color", TITLE_COLOR)
	column.add_child(ReadAloud.with_speaker(_card_name, _card, _card_words))
	for i in 3:
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 540
		l.add_theme_font_size_override("font_size", 23)
		column.add_child(l)
		_facts.append(l)
	_state_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_state_words.custom_minimum_size.x = 540
	_state_words.add_theme_font_size_override("font_size", 22)
	_state_words.add_theme_color_override("font_color", Color("ffe14d"))
	column.add_child(_state_words)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	action_button = UiKit.big_button("LAND", UiKit.GREEN, Vector2(230, 72))
	action_button.focus_mode = Control.FOCUS_NONE
	action_button.pressed.connect(_on_action)
	buttons.add_child(action_button)
	peek_button = UiKit.big_button("PEEK", UiKit.BLUE, Vector2(180, 72))   # universe 6: a locked universe's free peek
	peek_button.focus_mode = Control.FOCUS_NONE
	peek_button.visible = false
	peek_button.pressed.connect(func() -> void: UniversePeek.show_for(int(StarMap.body(_selected).get("world", 0)), self))
	buttons.add_child(peek_button)
	map_button = UiKit.big_button("MAP", UiKit.BLUE, Vector2(180, 72))
	map_button.focus_mode = Control.FOCUS_NONE
	map_button.pressed.connect(close_card)
	buttons.add_child(map_button)
	column.add_child(buttons)


## Shows the map from world `here` (the trip started from `home`), with the space worlds `available` built and the
## universes up to `unlocked` opened (StarMap.states); `route` (spec §21d.5): the worlds reached (null: no missions).
func open(here: int, home: int, available: Array[int], unlocked: int, route: Variant = null) -> void:
	_here = here
	_states = StarMap.states(here, home, available, unlocked, route)
	for b in bodies:
		b.set_state(_states.get(b.body_id, StarMap.LOOK))
	home_button.visible = SpaceRules.is_away(here)   # owner #78: from an Earth world too
	close_card()
	_planet = UniverseRegistry.card_colors(here)
	_hint.text = ""
	_days = StarMap.days_since_2000(Time.get_unix_time_from_system())   # where the planets really are today
	_moon_t = 0.0
	visible = true
	_layout()
	if hold and not get_tree().paused:
		get_tree().paused = true
		_held = true
	if PlatformRules.captures_mouse(PlatformRules.current()):   # M7: a phone browser has no mouse to free
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	PadFocus.take(self, here_body())   # owner #90: a game controller starts on the planet the child is at
	_vr_open()   # owner #110: the orrery within reach (VR only)
	queue_redraw()
	opened.emit()


## Hides the map; the game it held goes on (release false: something else holds it now, the pause menu).
func close(release: bool = true) -> void:
	if not visible:
		return
	visible = false
	_vr_close()   # owner #110
	if _held:
		_held = false
		if release:
			get_tree().paused = false
	closed.emit()


func is_open() -> bool:
	return visible


## A body's card: its picture, name, facts and what a tap can do from here.
func select(id: StringName) -> void:
	var d := StarMap.body(id)
	if d.is_empty():
		return
	_selected = id
	var state: StringName = _states.get(id, StarMap.LOOK)
	var pic := d.duplicate()
	pic.size = 78.0
	pic.name = ""
	_card_picture.data = pic
	_card_picture.radius = 78.0
	_card_picture.set_state(state if state in [StarMap.HERE, StarMap.HOME] else StarMap.LOOK)   # its true colours
	_card_name.text = str(d.name)
	for i in _facts.size():
		_facts[i].text = "•  " + str((d.facts as Array)[i]) if i < (d.facts as Array).size() else ""
	action_button.visible = state in [StarMap.LAND, StarMap.HOME]
	action_button.text = StarMap.action_words_for(id, state) if action_button.visible else ""   # owner #78: Earth's place
	_state_words.text = "" if action_button.visible else StarMap.action_words(state)
	peek_button.visible = state == StarMap.LOCKED and str(d.get("kind", "")) == "universe" \
		and not UniverseRegistry.peek(int(d.get("world", 0))).is_empty()   # universe 6: a free peek inside
	_state_words.visible = _state_words.text != ""
	_hint.text = ""
	_card_holder.visible = true
	body_seen.emit(id)


func close_card() -> void:
	_selected = &""
	_card_holder.visible = false


## Owner #90: a game controller's Circle / B closes a body's card first (back to the map, the focus on that body), then
## the map (the game's Back: the space director closes it).
func pad_back() -> bool:
	if not card_open():
		return false
	close_card()
	return true


func card_open() -> bool:
	return _card_holder.visible


func card_title() -> String:
	return _card_name.text


## The card's facts, as StarMap has them.
func card_facts() -> Array:
	var out := []
	for l in _facts:
		if l.text != "":
			out.append(l.text.trim_prefix("•  "))
	return out


func card_state_words() -> String:
	return _state_words.text


## The body the child is at (it glows), null when the map has none.
func here_body() -> StarBody:
	for b in bodies:
		if _states.get(b.body_id, StarMap.LOOK) == StarMap.HERE:
			return b
	return null


func body_for(id: StringName) -> StarBody:
	for b in bodies:
		if b.body_id == id:
			return b
	return null


## Why a trip can't happen, above the buttons.
func say(text: String) -> void:
	_hint.text = text


func hint() -> String:
	return _hint.text


func title_text() -> String:
	return _title.text


## The colours of the planet glowing at the bottom ({top, bottom, ground}: UniverseRegistry.card_colors).
func planet_colors() -> Dictionary:
	return _planet


## What must not build or break under the panel (LookBuildArea reads touches first).
func blockers() -> Array[Control]:
	return [self]


func _card_words() -> String:
	var parts: Array[String] = [_card_name.text]
	for f in card_facts():
		parts.append(str(f))
	if _state_words.text != "":
		parts.append(_state_words.text)
	return " ".join(parts)


func _on_action() -> void:
	var state: StringName = _states.get(_selected, StarMap.LOOK)
	if state == StarMap.HOME:
		home_requested.emit()
	elif state == StarMap.LAND:
		travel_requested.emit(int(StarMap.body(_selected).world))


func _on_stay() -> void:
	stay_requested.emit()
	close()


## Places every body: the solar system along the lower part in its order, its moons by their planets, the far worlds
## in a row across the top.
func _layout() -> void:
	if bodies.is_empty():
		return
	var w := size.x
	var top := MAP_TOP
	var h := maxf(size.y - MAP_TOP - MAP_BOTTOM, 200.0)
	var far: Array[StarBody] = []
	for b in bodies:
		if str(b.data.kind) in ["game", "universe"]:
			far.append(b)
	_layout_solar()
	for i in far.size():   # a zigzag, so the long names never run into each other
		var t := (i + 0.5) / far.size()
		_put(far[i], Vector2(w * lerpf(0.04, 0.96, t), top + h * FAR_Y + (4.0 if i % 2 == 0 else 58.0)))
	queue_redraw()


## The Sun, the planets on their orbits and the moons round their planets, for now.
func _layout_solar() -> void:
	var sun := sun_centre()
	var centres := {}
	for b in bodies:
		var kind := str(b.data.kind)
		if kind == "star":
			centres[b.body_id] = sun
			_put(b, sun)
		elif kind in ["planet", "dwarf"]:
			var o := orbit_size(b.body_id)
			var a := angle_of(b.body_id)
			centres[b.body_id] = sun + Vector2(cos(a) * o.x, -sin(a) * o.y)
			_put(b, centres[b.body_id])
	for b in bodies:
		if str(b.data.kind) == "moon":
			var parent: Vector2 = centres.get(b.data.parent, sun)
			var a := angle_of(b.body_id)
			var ring := float(StarMap.body(b.data.parent).get("size", 10.0)) + MOON_GAP
			_put(b, parent + Vector2(cos(a) * ring, -sin(a) * ring * 0.7))


## The Sun's place: the middle of the width, SOLAR_Y down the map.
func sun_centre() -> Vector2:
	var h := maxf(size.y - MAP_TOP - MAP_BOTTOM, 200.0)
	return Vector2(size.x * 0.5, MAP_TOP + h * SOLAR_Y)


## A planet's orbit on the screen: half its width and half its height (pixels); ZERO for anything else.
func orbit_size(id: StringName) -> Vector2:
	if not ORBIT_RX.has(id):
		return Vector2.ZERO
	var rx := size.x * float(ORBIT_RX[id])
	return Vector2(rx, rx * TILT)


## Where a planet is on its orbit now (radians), or a moon round its planet.
func angle_of(id: StringName) -> float:
	if ORBIT_RX.has(id):
		return StarMap.longitude(id, _days)
	var d := StarMap.body(id)
	if str(d.get("kind", "")) == "moon":
		var siblings: Array[StringName] = []
		for other: Dictionary in StarMap.bodies():
			if str(other.kind) == "moon" and other.parent == d.parent:
				siblings.append(other.id)
		var turn := float(MOON_RING_SECONDS.get(d.parent, 20.0))
		return fposmod(TAU * _moon_t / turn + TAU * siblings.find(id) / siblings.size() + 0.6, TAU)
	return 0.0


## Time goes on for the orrery (a card open holds it still).
func advance(seconds: float) -> void:
	if card_open():
		return
	_days += seconds * StarMap.year_days(&"earth") / EARTH_YEAR_SECONDS
	_moon_t += seconds
	if _vr_orrery_open():
		return   # owner #110: in a headset the orrery moves the solar system; the panel's own picture stays still
	_layout_solar()
	queue_redraw()


func _process(delta: float) -> void:
	if visible:
		advance(delta)


func _put(b: StarBody, centre: Vector2) -> void:
	b.size = b.custom_minimum_size
	var p := centre - b.centre()
	p.x = clampf(p.x, 2.0, maxf(size.x - b.size.x - 2.0, 2.0))
	p.y = clampf(p.y, 2.0, maxf(size.y - b.size.y - 2.0, 2.0))
	b.position = p


## Every new finger is the panel's while it shows (its buttons still get the touch's click).
func _input(event: InputEvent) -> void:
	if visible and event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		_vr_close()   # owner #110
	if what == NOTIFICATION_EXIT_TREE and _held:
		_held = false
		get_tree().paused = false


## Space: a deep blue-black sky of stars, the solar system's orbit line, captions, and at the bottom the planet the
## child flew up from with its air's glow.
func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.02, 0.02, 0.07))
	# owner #110 (VR-WONDER): in a headset the stars and the planet below are one draw (CanvasBatch), and the solar
	# system is the orrery under the panel (its bodies, orbits and captions are not drawn here)
	var on: Variant = CanvasBatch.new() if _vr_orrery_open() else self
	for st in _stars:
		on.draw_circle(Vector2(st.x * s.x, st.y * s.y), st.z, Color(1, 1, 1, 0.35 + 0.18 * st.z))
	var c := Vector2(s.x * 0.5, s.y * 1.95)
	var r := s.y * 1.05
	on.draw_circle(c, r + 16.0, Color(_planet.bottom, 0.3))
	on.draw_circle(c, r + 7.0, Color(_planet.top, 0.55))
	on.draw_circle(c, r, _planet.ground)
	var h := maxf(s.y - MAP_TOP - MAP_BOTTOM, 200.0)
	var font := get_theme_default_font()
	if on is CanvasBatch:
		(on as CanvasBatch).flush(self)
		draw_string(font, Vector2(24, MAP_TOP + h * FAR_Y - 22.0), "FAR AWAY: OUR OWN PLANETS AND THE UNIVERSES",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.5))
		return
	var sun := sun_centre()
	for id: StringName in ORBIT_RX:   # the orbits: faint tilted circles round the Sun
		var o := orbit_size(id)
		var pts := PackedVector2Array()
		for i in 65:
			var a := TAU * i / 64.0
			pts.append(sun + Vector2(cos(a) * o.x, sin(a) * o.y))
		draw_polyline(pts, Color(1, 1, 1, 0.13), 1.5, true)
	draw_string(font, Vector2(24, MAP_TOP + h * FAR_Y - 22.0), "FAR AWAY: OUR OWN PLANETS AND THE UNIVERSES",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.5))
	draw_string(font, Vector2(24, s.y - MAP_BOTTOM + 30.0), "OUR SOLAR SYSTEM", HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
		Color(1, 1, 1, 0.5))
	draw_string(font, Vector2(24, s.y - MAP_BOTTOM + 52.0), "A year on Earth: 40 seconds here", HORIZONTAL_ALIGNMENT_LEFT,
		-1, 16, Color(1, 1, 1, 0.5))


# --- Owner #110 (VR round 4, VR-WONDER, idea 1): the orrery within reach in a headset ---

## In a headset: the orrery under Vr (it goes on while a game played alone holds still), from the map's own date; a
## planet taken opens its card here, one dropped in the landing ring does what its card's button does.
func _vr_open() -> void:
	_vr_close()
	true_size_button.visible = Vr.active()
	true_size_button.text = TRUE_SIZE_WORD
	if not Vr.active():
		return
	vr_orrery = VrOrrery.new()
	Vr.add_child(vr_orrery)
	vr_orrery.open(_days, Vr.pointing_hand())
	vr_orrery.body_taken.connect(_vr_taken)
	vr_orrery.dropped_in_ring.connect(vr_land)
	_hint.text = VR_HINT
	for b in bodies:   # the solar system is the orrery now; the far worlds stay on the map
		b.visible = not _solar(b)
	if here_body() != null and not here_body().visible:
		PadFocus.take(self, home_button if home_button.visible else stay_button)
	queue_redraw()


## A planet taken in a hand: its card, its name and facts read aloud ("Read to me").
func _vr_taken(id: StringName) -> void:
	select(id)
	ReadAloud.auto(_card_words())


func _vr_close() -> void:
	if vr_orrery != null and is_instance_valid(vr_orrery):
		vr_orrery.close()
		for b in bodies:
			b.visible = true
	vr_orrery = null


func _vr_orrery_open() -> bool:
	return vr_orrery != null and is_instance_valid(vr_orrery)


static func _solar(b: StarBody) -> bool:
	return str(b.data.kind) in ["star", "planet", "dwarf", "moon"]


func _vr_true_size() -> void:
	if vr_orrery == null or not is_instance_valid(vr_orrery):
		return
	vr_orrery.set_true_size(not vr_orrery.true_size)
	true_size_button.text = ORRERY_WORD if vr_orrery.true_size else TRUE_SIZE_WORD


## A body dropped in the orrery's landing ring: LAND (or HOME) as its card's button, else why not (and its card).
func vr_land(id: StringName) -> void:
	var state: StringName = _states.get(id, StarMap.LOOK)
	if state == StarMap.LAND:
		travel_requested.emit(int(StarMap.body(id).world))
	elif state == StarMap.HOME:
		home_requested.emit()
	else:
		select(id)
		say(StarMap.action_words(state))
