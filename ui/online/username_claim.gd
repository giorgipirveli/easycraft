class_name UsernameClaim
extends VBoxContainer
## Claiming the profile's username on the server (M4 Wave 1, Agent C; spec §17.1): the name picked
## at first launch, one tap on OK. When someone already has it (or the server's filter says no), the
## name can be changed right here, with RANDOM like the first-launch screen. The claimed name
## becomes the profile's name too (OnlineService.claim_username).
## Owner #67: I HAVE AN ACCOUNT (a name already claimed on another device or before this browser's storage was
## wiped). Owner #99: it opens LOG IN (LogInPage: the name, then the code from the other device or a grown-up's key), and
## a taken name asks first: "Someone already has the name Anna. Is it you, from another phone, tablet or computer?"
## YES, IT'S ME opens MOVE YOUR GAME HERE (move_asked); NO, ANOTHER NAME comes back to the name, with RANDOM.

signal done
signal have_account   # owner #67
signal move_asked(username: String)   # owner #99: a taken name, and YES, IT'S ME

var service: OnlineService

var edit := LineEdit.new()
var hint: Label
var ok_button: Button
var random_button: Button
var have_account_button: Button   # owner #67
var taken_box: VBoxContainer      # owner #99: the question
var taken_label: Label
var yes_button: Button
var no_button: Button
var taken_name := ""
var _claim_rows: Array[Control] = []
var _busy := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_theme_constant_override("separation", 18)
	_rng.randomize()
	add_child(UiKit.title("Your online name"))
	var info := OnlineUi.words("Friends find you by this name.", 28)
	add_child(info)
	edit.max_length = UsernameRules.MAX_LEN
	edit.custom_minimum_size = Vector2(520, 84)
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.text = service.profile.username if service and service.profile else ""
	edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	edit.text_changed.connect(_on_text_changed)
	edit.text_submitted.connect(func(_t: String) -> void: if not ok_button.disabled: _claim())
	add_child(edit)
	hint = OnlineUi.words("", 24)
	hint.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(hint)
	random_button = OnlineUi.button("RANDOM", UiKit.BLUE, Vector2(240, 88))
	random_button.pressed.connect(func() -> void:
		edit.text = NameSuggester.suggest(_rng)
		_on_text_changed(edit.text))
	ok_button = OnlineUi.button("OK", UiKit.GREEN, Vector2(240, 88))
	ok_button.pressed.connect(_claim)
	add_child(OnlineUi.row([random_button, ok_button]))
	have_account_button = OnlineUi.button("I HAVE AN ACCOUNT", UiKit.ORANGE, Vector2(400, 72), &"grownup")   # owner #67
	have_account_button.add_theme_font_size_override("font_size", 24)
	have_account_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	have_account_button.pressed.connect(func() -> void: have_account.emit())
	add_child(have_account_button)
	for c in get_children():
		_claim_rows.append(c)
	_add_taken_box()   # owner #99
	_on_text_changed(edit.text)


func _on_text_changed(text: String) -> void:
	var code := UsernameRules.validate(text)
	ok_button.disabled = code != "" or _busy
	hint.text = UsernameRules.message(code) if code != "" and text != "" else ""


func _claim() -> void:
	if _busy:
		return
	_busy = true
	ok_button.disabled = true
	hint.text = "Checking..."
	var err: String = await service.claim_username(edit.text)
	_busy = false
	if not is_inside_tree():
		return
	if err == "":
		done.emit()
		return
	if err == OnlineRules.message("taken"):   # owner #99: maybe the child's own, from another device
		ask_taken(UsernameRules.normalize(edit.text))
		return
	hint.text = err
	ok_button.disabled = false

# --- Owner #99: a taken name asks whether it is this child's, from another device ---

func _add_taken_box() -> void:
	taken_box = OnlineUi.column(24)
	taken_box.visible = false
	taken_label = OnlineUi.words("", 32, 900)
	taken_label.name = "TakenQuestion"
	taken_box.add_child(ReadAloud.with_speaker(taken_label, taken_box))
	yes_button = OnlineUi.button(DeviceMoveRules.YES_ME, UiKit.GREEN, Vector2(360, 96))
	yes_button.pressed.connect(func() -> void: move_asked.emit(taken_name))
	no_button = OnlineUi.button(DeviceMoveRules.NO_OTHER, UiKit.BLUE, Vector2(400, 96))
	no_button.pressed.connect(_another_name)
	taken_box.add_child(OnlineUi.row([yes_button, no_button], 28))
	add_child(taken_box)


## "Someone already has the name Anna. Is it you, from another phone, tablet or computer?"
func ask_taken(username: String) -> void:
	taken_name = username
	taken_label.text = DeviceMoveRules.taken_text(username)
	for c in _claim_rows:
		c.visible = false
	taken_box.visible = true
	ReadAloud.auto(taken_label.text)


## NO, ANOTHER NAME: back to the name, with RANDOM.
func _another_name() -> void:
	taken_box.visible = false
	for c in _claim_rows:
		c.visible = true
	edit.text = ""
	_on_text_changed("")
	hint.text = DeviceMoveRules.PICK_ANOTHER
