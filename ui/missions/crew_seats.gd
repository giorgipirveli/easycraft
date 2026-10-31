class_name CrewSeats
extends Control
## Crew flights (spec §21d.6 phase 2, the brief's item 2: "crew members see each other in their seats"): the crew in
## their seats, on every crew member's cockpit, down its right side under the view button. A seat per crew member:
## their avatar sitting (AvatarIcon.figure in EmotePoses' sit, from the look the world shows), their name (the one the
## world shows), PILOT on the pilot's seat, YOU on this child's own. WAVE waves this child's avatar on everyone's
## screen (wave(peer) plays anyone's). A crew member who left keeps an empty seat.

signal wave_pressed

const SEAT := Vector2(200, 84)
const GAP := 8.0
const TOP := 112.0
const RIGHT := 18.0
const WAVE_SECONDS := 2.2
const FIGURE := Vector2(58, 78)
const SEAT_COLOR := Color(0.05, 0.08, 0.14, 0.82)
const PILOT_COLOR := Color(1.0, 0.85, 0.35)
const ME_COLOR := Color(0.55, 1.0, 0.85)

## [{peer, name, look, seat}], the pilot first.
var crew: Array = []
## This game's peer id.
var me := 0
var wave_button: Button

var _looks := {}     # peer -> AvatarLook.resolve()
var _waves := {}     # peer -> seconds into its wave
var _gone := {}      # peer -> true: left the crew


func _ready() -> void:
	name = "CrewSeats"
	theme = UiKit.theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	wave_button = UiKit.big_button(CrewFlightRules.WAVE, UiKit.BLUE, Vector2(SEAT.x, 64))
	wave_button.name = "Wave"
	wave_button.add_theme_font_size_override("font_size", 28)
	wave_button.pressed.connect(func() -> void: wave_pressed.emit())
	add_child(wave_button)
	_layout()
	var parent := get_parent() as Control
	if parent:
		parent.resized.connect(_layout)


## The crew to show (the pilot first) and which seat is this child's.
func setup(p_crew: Array, p_me: int) -> void:
	crew = p_crew.duplicate(true)
	me = p_me
	_looks.clear()
	for c: Dictionary in crew:
		_looks[int(c.get("peer", 0))] = AvatarLook.from_code(str(c.get("look", ""))).resolve()
	_layout()
	queue_redraw()


## `peer` waves from their seat.
func wave(peer: int) -> void:
	_waves[peer] = 0.0
	queue_redraw()


func waving(peer: int) -> bool:
	return _waves.has(peer)


## `peer` left the crew: their seat stays, empty.
func gone(peer: int) -> void:
	_gone[peer] = true
	queue_redraw()


## The name shown on seat i ("" for none).
func seat_name(i: int) -> String:
	return CrewFlightRules.shown_name(str((crew[i] as Dictionary).get("name", ""))) if i < crew.size() else ""


func _layout() -> void:
	var parent := get_parent() as Control
	var w := parent.size.x if parent else 1280.0
	size = Vector2(SEAT.x, crew.size() * (SEAT.y + GAP) + 70.0)
	position = Vector2(w - SEAT.x - RIGHT, TOP)
	if wave_button:
		wave_button.position = Vector2(0, crew.size() * (SEAT.y + GAP))
		wave_button.size = Vector2(SEAT.x, 64)
		wave_button.visible = not crew.is_empty()


func _process(delta: float) -> void:
	if _waves.is_empty():
		return
	for p: int in _waves.keys():
		_waves[p] = float(_waves[p]) + delta
		if float(_waves[p]) >= WAVE_SECONDS:
			_waves.erase(p)
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	for i in crew.size():
		var c: Dictionary = crew[i]
		var peer := int(c.get("peer", 0))
		var top := Vector2(0, i * (SEAT.y + GAP))
		draw_style_box(UiKit.box(SEAT_COLOR, 14, 8), Rect2(top, SEAT))
		if _gone.has(peer):
			draw_string(font, top + Vector2(16, SEAT.y * 0.6), "…", HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
			continue
		var pose := EmotePoses.sample(&"sit", 10.0)
		if _waves.has(peer):
			pose.r_arm = (EmotePoses.sample(&"wave", float(_waves[peer])) as Dictionary).r_arm
		AvatarIcon.figure(self, Rect2(top + Vector2(6, 3), FIGURE), _looks.get(peer, AvatarLook.new().resolve()), pose)
		var tag := ""
		var tag_color := Color.WHITE
		if i == 0:
			tag = CrewFlightRules.PILOT
			tag_color = PILOT_COLOR
		elif peer == me:
			tag = "YOU"
			tag_color = ME_COLOR
		draw_string(font, top + Vector2(FIGURE.x + 14, 36), seat_name(i).left(12), HORIZONTAL_ALIGNMENT_LEFT,
			SEAT.x - FIGURE.x - 20, 24)
		if tag != "":
			draw_string(font, top + Vector2(FIGURE.x + 14, 66), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, tag_color)
