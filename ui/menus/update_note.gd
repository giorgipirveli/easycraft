class_name UpdateNote
extends PanelContainer
## Owner #123 (2026-10-17): a phone's browser kept starting the copy of the game it had stored while the PC ran the new
## version. When a new version has downloaded during play, the main menu says so calmly with a RESTART button; nothing
## shows otherwise and nothing hurries (no timer, no countdown). It asks `is_ready` every POLL_SEC while it is in the
## tree; `restart` starts the new version. On the web: WebGlue.update_ready / reload_page (the page's service worker,
## web/shell.html). An installed Android app passes its updater's (autoloads/updater.gd) and no `restart`: there the note
## says the new game starts next time, without RESTART (tests/integration/test_update_note_app.gd).

const POLL_SEC := 5.0
const WORDS := "A new EasyCraft is ready!"

var words := Label.new()
var restart_button: Button
var _is_ready: Callable
var _restart: Callable
var _since := 0.0


func _init(is_ready: Callable = WebGlue.update_ready, restart: Callable = WebGlue.reload_page) -> void:
	_is_ready = is_ready
	_restart = restart
	name = "UpdateNote"
	visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	words.text = WORDS
	words.add_theme_font_size_override("font_size", 24)
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(words)
	restart_button = UiKit.big_button("RESTART", UiKit.GREEN, Vector2(180, 56))
	restart_button.pressed.connect(func() -> void: _restart.call())
	row.add_child(restart_button)
	add_child(row)
	if not _restart.is_valid():   # owner #123: an installed app (autoloads/updater.gd) cannot restart itself
		words.text = UpdateRules.READY_WORDS
		restart_button.visible = false


## Looks once: shows the note when a new version is ready.
func poll() -> void:
	if not visible and _is_ready.call():
		visible = true


func _process(delta: float) -> void:
	if visible:
		return
	_since += delta
	if _since >= POLL_SEC:
		_since = 0.0
		poll()
