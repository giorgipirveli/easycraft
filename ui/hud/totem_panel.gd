class_name TotemPanel
extends Control
## The Monster Totem's small picture panel (M2 Task 9; HUD: a centred overlay), opened by a tap on
## the Totem. It shows the wave the Totem offers as a picture: "Wave 3", a slime "× 9" and, in
## Survivor, the gold for winning it; one big START button. After a wave that was not won it offers
## TRY AGAIN and TRY AN EASIER WAVE instead, as two equal buttons (research G6: the easier wave pays
## the normal gold and the words never shame). Once wave 5 is won, the Stone Golem button (Task 10).
## Every choice goes to the host (Session.wave_request_start / wave_request_boss), then the panel
## closes: the countdown takes over. It also closes when a wave starts, on its X, a tap outside, Back,
## or when the player walks away.

signal opened
signal closed

const PANEL_SIZE := Vector2(760, 470)
const BUTTON := Vector2(320, 118)
const REACH_SLACK := 2.0          # the panel stays open this far past the tap reach
const REACH_CHECK_EVERY := 0.5
const TITLE := "Monster Totem"

var player: Player
var start_button: Button
var again_button: Button
var easier_button: Button
var boss_button: Button
var close_button: Button

var _totem: Totem
var _state: Dictionary = {}
var _count := 0
var _panel := PanelContainer.new()
var _wave_label := Label.new()
var _count_label := Label.new()
var _reward_row := HBoxContainer.new()
var _reward_label := Label.new()
var _choice := {}                 # button -> the wave it starts
var _reach_timer := Timer.new()


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.08, 0.17), 26, 22))
	add_child(_panel)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		_panel.set_anchor(side, 0.5)
	_panel.offset_left = -PANEL_SIZE.x * 0.5
	_panel.offset_right = PANEL_SIZE.x * 0.5
	_panel.offset_top = -PANEL_SIZE.y * 0.5
	_panel.offset_bottom = PANEL_SIZE.y * 0.5
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_panel.add_child(column)
	column.add_child(_header())
	column.add_child(_picture())
	column.add_child(_buttons())
	_reach_timer.wait_time = REACH_CHECK_EVERY
	_reach_timer.timeout.connect(check_reach)
	add_child(_reach_timer)


## Opens at `totem` with the wave state this game knows (WaveDirector.current).
func open(totem: Totem, state: Dictionary) -> void:
	_totem = totem
	visible = true
	_state = state
	_refresh()
	_reach_timer.start()
	if PlatformRules.captures_mouse(PlatformRules.current()):   # M7: a phone browser has no mouse to free
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	_reach_timer.stop()
	closed.emit()


## The host's wave state changed: a wave (or the boss) that begins closes the panel.
func show_state(state: Dictionary) -> void:
	_state = state
	if not visible:
		return
	if int(state.get("phase", WaveDirector.Phase.IDLE)) != WaveDirector.Phase.IDLE:
		close()
	else:
		_refresh()


## Closes the panel once the player has walked away from the Totem (or it is gone).
func check_reach() -> void:
	if not visible:
		return
	if not is_instance_valid(_totem) or not is_instance_valid(player) \
			or not WaveRules.in_reach(player.eye_position(), _totem.global_position, WaveRules.TAP_REACH + REACH_SLACK):
		close()


func wave_text() -> String:
	return _wave_label.text


func monster_count() -> int:
	return _count


func reward_text() -> String:
	return _reward_label.text if _reward_row.visible else ""


## Where the panel sits on a screen of `screen` size (layout checks).
func panel_rect(screen: Vector2) -> Rect2:
	return Rect2(screen * 0.5 + Vector2(_panel.offset_left, _panel.offset_top), PANEL_SIZE)


func _refresh() -> void:
	var lost := int(_state.get("lost", 0))
	var next := int(_state.get("next", WaveRules.FIRST_WAVE))
	var shown := lost if lost > 0 else next
	var gentle := bool(_state.get("gentle", false))
	_wave_label.text = tr("Wave %d") % shown
	_count = WaveRules.size(shown, gentle, int(_state.get("team", 1)))   # M4 E: the host's team
	_count_label.text = "× %d" % _count
	var gold := UniverseRules.gold(WaveRules.reward(shown, Game.allows(ModeRules.INFINITE_GOLD)), Game.universe)   # M3 Task 5
	_reward_row.visible = gold > 0
	_reward_label.text = GoldFormat.short(gold) if gold > 0 else ""
	start_button.visible = lost == 0
	again_button.visible = lost > 0
	easier_button.visible = lost > 0 and WaveRules.offers_easier(lost)
	boss_button.visible = bool(_state.get("boss", false))
	_choice = {start_button: next, again_button: lost, easier_button: WaveRules.easier(lost)}


func _choose(button: Button) -> void:
	Session.wave_request_start(int(_choice.get(button, 0)))
	close()


func _ask_boss() -> void:
	Session.wave_request_boss()
	close()


# --- Building the panel ---

func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	var title := Label.new()
	title.text = TITLE
	_style(title, 36, Color("c9a6ff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 56.0))   # M5 Task 1
	close_button = UiKit.big_button("X", UiKit.RED, Vector2(84, 84))
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.pressed.connect(close)
	row.add_child(close_button)
	return row


## The wave as a picture: "Wave 3", a slime "× 9", and a coin with the gold for winning it.
func _picture() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	_style(_wave_label, 48, Color.WHITE)
	row.add_child(_wave_label)
	row.add_child(MonsterIcon.new(64))
	_style(_count_label, 40, Color.WHITE)
	row.add_child(_count_label)
	_reward_row.add_theme_constant_override("separation", 6)
	_reward_row.add_child(CoinIcon.new(44))
	_style(_reward_label, 40, CoinIcon.GOLD)
	_reward_row.add_child(_reward_label)
	row.add_child(_reward_row)
	return row


func _buttons() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button = _icon_button("START", BlockIcons.icon(ItemIds.SWORD), UiKit.GREEN)
	start_button.pressed.connect(_choose.bind(start_button))
	grid.add_child(start_button)
	again_button = _icon_button(WaveRules.TRY_AGAIN, BlockIcons.icon(ItemIds.SWORD), UiKit.GREEN)
	again_button.pressed.connect(_choose.bind(again_button))
	grid.add_child(again_button)
	easier_button = _icon_button(WaveRules.TRY_EASIER, MonsterIcon.texture(), UiKit.BLUE)
	easier_button.pressed.connect(_choose.bind(easier_button))
	grid.add_child(easier_button)
	boss_button = _icon_button(WaveRules.BOSS_WORD, BlockIcons.icon(BlockIds.STONE), UiKit.ORANGE)
	boss_button.pressed.connect(_ask_boss)
	grid.add_child(boss_button)
	return grid


static func _icon_button(word: String, icon: Texture2D, color: Color) -> Button:
	var b := UiKit.big_button(word, color, BUTTON)
	b.icon = icon
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_constant_override("icon_max_width", 52)
	return b


static func _style(l: Label, font_size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Taps on the dimmed area (outside the panel) close it and never reach the world behind it.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
