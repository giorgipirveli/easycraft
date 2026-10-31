class_name CodePanel
extends VBoxContainer
## The secret-code field (spec §5.11, §14.10; M3 Task 13) behind the main menu's small black
## "admin panel" text: a big input, OK / BACK and one friendly message line. The rules (salted
## hashes, once per profile, the rate limit) are CodeRules and CodeTries; a payout saves the
## profile at once and rains coins. profile / save_profile / tries / rewards can be swapped (tests).
## Signed in, the server redeems the code (once per account, spec §17.6; M4 Wave 2, agent F:
## OnlineService.redeem_code); offline the phone does, and the server hears of it at the next sign-in.

signal closed

## One rate limit for the whole app run, so leaving and reopening the field doesn't reset it.
static var shared_tries := CodeTries.new()

var profile: ProfileData          # default: Profile.data
var save_profile := Callable()    # default: Profile.save
var tries: CodeTries              # default: shared_tries
var rewards: Dictionary = CodeRules.REWARDS
## The online service that redeems codes when signed in (M4 F). Default: the game's own, only for
## the game's own profile (tests with their own profile stay on the phone).
var service: OnlineService

var _busy := false

var field := LineEdit.new()
var message := Label.new()
var ok := UiKit.big_button("OK", UiKit.GREEN, Vector2(240, 88))
var back := UiKit.big_button("BACK", UiKit.BLUE, Vector2(240, 88))


## The small black "admin panel" text for the bottom centre of the main menu (a flat button).
static func admin_link() -> Button:
	var b := Button.new()
	b.name = "AdminPanel"
	b.text = "admin panel"
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	for key: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, Color.BLACK)
	b.anchor_left = 0.5
	b.anchor_right = 0.5
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = -130.0     # a finger-sized tap area around the small text
	b.offset_right = 130.0
	b.offset_top = -64.0
	b.offset_bottom = -4.0
	b.grow_horizontal = Control.GROW_DIRECTION_BOTH
	b.grow_vertical = Control.GROW_DIRECTION_BEGIN   # a taller minimum size grows up, never off screen
	b.pressed.connect(Audio.play.bind(&"ui_click"))
	return b


func _ready() -> void:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = Profile.save
	if tries == null:
		tries = shared_tries
	add_theme_constant_override("separation", 20)
	add_child(ReadAloud.with_speaker(UiKit.title("Secret code"), self))   # M5 Task 1: read aloud on every screen

	field.placeholder_text = "Type a code"
	field.max_length = CodeRules.MAX_LEN
	field.custom_minimum_size = Vector2(560, 96)
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_theme_font_size_override("font_size", 44)
	field.text_changed.connect(func(_t: String) -> void: _refresh())
	field.text_submitted.connect(func(_t: String) -> void: submit())
	add_child(field)

	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.custom_minimum_size = Vector2(560, 40)
	message.add_theme_font_size_override("font_size", 30)
	add_child(message)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	ok.pressed.connect(submit)
	back.pressed.connect(func() -> void: closed.emit())
	row.add_child(ok)
	row.add_child(back)
	add_child(row)
	_refresh()
	field.grab_focus.call_deferred()


func submit() -> void:
	if _busy:
		return
	var online := _signed_in_service()
	var result: Dictionary
	if online:
		_busy = true
		ok.disabled = true
		message.text = "One moment..."
		result = await online.redeem_code(field.text, tries, Time.get_ticks_msec(), rewards)
		_busy = false
		if not is_inside_tree():
			return
	else:   # never waits: the phone decides at once
		result = CodeRules.redeem(profile, field.text, tries, Time.get_ticks_msec(), rewards)
	message.text = result.message
	message.add_theme_color_override("font_color", Color("8dff8a") if result.status == CodeRules.ACCEPTED else Color("ffb4a8"))
	if result.status == CodeRules.ACCEPTED:
		field.text = ""
		save_profile.call()
		add_child(CoinShower.new())
		Audio.play(&"ding")
	_refresh()


func _signed_in_service() -> OnlineService:
	var s := service
	if s == null and profile == Profile.data:
		s = Session.online_service_or_null()
	return s if s != null and s.status == OnlineService.ONLINE else null


## OK needs a code, and shows the countdown while the field is locked.
func _refresh() -> void:
	var now := Time.get_ticks_msec()
	var locked := tries.is_locked(now)
	ok.text = tr("WAIT %d") % tries.wait_seconds(now) if locked else "OK"
	ok.disabled = locked or _busy or CodeRules.normalize(field.text) == ""
	set_process(locked)


func _process(_delta: float) -> void:
	_refresh()
	if not is_processing():   # the wait is over
		message.text = ""
