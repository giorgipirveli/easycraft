class_name VrComfortPage
extends VBoxContainer
## VR on the Meta Quest (owner #101): SETTINGS' VR COMFORT page, only in a headset (SettingsPanel shows its button
## while Vr is active). The plan's comfort ruling 3 chooses the first answers: SNAP 45° turning (SMOOTH only if the
## child picks it), a LIGHT comfort view (the vignette while moving), walking where the head looks, the eye at the
## avatar's height, teleport on, a break card every 30 minutes, BIG text; RECENTER puts the world in front again.
## Every choice is one of the profile's vr_* settings (VrRules' keys; ProfileData checks them when read: value_of),
## kept on this device (ProfileBackup.DEVICE_ONLY_SETTINGS). VR-RIG's body reads them (turning, the vignette, walking,
## the height, teleport); VrUi the break card's time; TextSize the text size.

const TURNS := ["snap45", "snap30", "smooth"]
const VIGNETTES := ["strong", "light", "off"]
const WALKS := ["head", "hand"]
const HEIGHTS := ["game", "real"]
const TELEPORTS := [true, false]
const BREAKS := [30, 60, 0]
const TEXTS := ["normal", "big"]
## Each setting's choices (the first answer of each is VrRules' default, or TextSize.VR_DEFAULT).
const CHOICES := {VrRules.TURN: TURNS, VrRules.VIGNETTE: VIGNETTES, VrRules.WALK_DIR: WALKS, VrRules.HEIGHT: HEIGHTS,
	VrRules.TELEPORT: TELEPORTS, VrRules.BREAK_MINUTES: BREAKS, TextSize.VR_KEY: TEXTS}
## The settings on the page, in its order.
const ROWS_KEYS := [VrRules.TURN, VrRules.VIGNETTE, VrRules.WALK_DIR, VrRules.HEIGHT, VrRules.TELEPORT,
	VrRules.BREAK_MINUTES, TextSize.VR_KEY]
const BUTTON_H := 66.0

## (key: String, value: Variant) -> void: stores one choice (SettingsPanel's _store: the profile, saved, applied).
var store := Callable()
## () -> void: RECENTER (default: recenter_now).
var recenter := Callable()

var _rows := {}   # key -> {value: its button}


func _init(settings: Dictionary = {}) -> void:
	name = "VrComfortPage"
	add_theme_constant_override("separation", 14)
	add_child(_row([[VrWords.TURNING, VrRules.TURN, "VrTurn_", VrWords.TURN_WORDS, 200.0]], settings))
	add_child(_row([[VrWords.VIGNETTE, VrRules.VIGNETTE, "VrVignette_", VrWords.VIGNETTE_WORDS, 200.0]], settings))
	add_child(_row([[VrWords.WALKING, VrRules.WALK_DIR, "VrWalk_", VrWords.WALK_WORDS, 220.0],
		[VrWords.HEIGHT, VrRules.HEIGHT, "VrHeight_", VrWords.HEIGHT_WORDS, 150.0]], settings))
	add_child(_row([[VrWords.TELEPORT, VrRules.TELEPORT, "VrTeleport_", VrWords.TELEPORT_WORDS, 120.0],
		[VrWords.BREAK, VrRules.BREAK_MINUTES, "VrBreak_", VrWords.BREAK_WORDS, 140.0]], settings))
	var text := _row([[VrWords.TEXT, TextSize.VR_KEY, "VrText_", VrWords.TEXT_WORDS, 170.0]], settings)
	var again := UiKit.big_button(VrWords.RECENTER, UiKit.BLUE, Vector2(240, BUTTON_H))
	again.name = "VrRecenter"
	again.add_theme_font_size_override("font_size", 26)
	again.pressed.connect(func() -> void:
		if recenter.is_valid():
			recenter.call()
		else:
			recenter_now())
	text.add_child(again)
	add_child(text)
	var about := Label.new()
	about.text = VrWords.ABOUT
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size.x = 1000
	about.add_theme_font_size_override("font_size", 24)
	add_child(about)


## The value of `key` in `settings`: one of the page's choices, else its default (a wrong type, an unknown answer).
static func value_of(settings: Dictionary, key: String) -> Variant:
	var fallback: Variant = VrRules.DEFAULTS[key] if VrRules.DEFAULTS.has(key) else TextSize.VR_DEFAULT
	if not settings.has(key):
		return fallback
	var v: Variant = settings[key]
	if typeof(fallback) == TYPE_INT and typeof(v) == TYPE_FLOAT and float(v) == floorf(float(v)):
		v = int(v)   # a number read back from JSON
	if typeof(v) != typeof(fallback):
		return fallback
	return v if (CHOICES.get(key, []) as Array).has(v) else fallback


## The headset's own recenter (Vr.recenter once the rig has one; else the XR server's, keeping the height).
static func recenter_now() -> void:
	if Vr.has_method(&"recenter"):
		Vr.call(&"recenter")
		return
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
	Vr.recentered.emit()


## One row of one or two settings: [label, key, name prefix, words by value, button width] each.
func _row(groups: Array, settings: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var first := true
	for g: Array in groups:
		var l := Label.new()
		l.text = g[0]
		l.custom_minimum_size.x = 230.0 if first and groups.size() == 1 else 150.0 if first else 130.0
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if first else HORIZONTAL_ALIGNMENT_RIGHT
		l.add_theme_font_size_override("font_size", 26)
		row.add_child(l)
		var key: String = g[1]
		var chosen: Variant = value_of(settings, key)
		var buttons := {}
		for v: Variant in CHOICES[key]:
			var b := UiKit.big_button((g[3] as Dictionary)[v], Color(), Vector2(float(g[4]), BUTTON_H))
			b.name = str(g[2]) + str(v)
			b.toggle_mode = true
			b.button_pressed = v == chosen
			b.add_theme_font_size_override("font_size", 24)
			b.pressed.connect(_pick.bind(key, v))
			buttons[v] = b
			row.add_child(b)
		_rows[key] = buttons
		first = false
	return row


func _pick(key: String, value: Variant) -> void:
	var buttons: Dictionary = _rows[key]
	for v: Variant in buttons:
		(buttons[v] as Button).set_pressed_no_signal(v == value)
	if store.is_valid():
		store.call(key, value)
	else:
		Profile.data.settings[key] = value
