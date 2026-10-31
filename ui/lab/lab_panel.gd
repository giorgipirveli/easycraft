class_name LabPanel
extends Control
## Spec §23.1: the Science Lab over a world, opened by a tap on a lab bench (the sandbox's hook): the screen dimmed, the
## Lab (LabScreen) on the menu's panel in the middle, drawn smaller on a screen too low for it. The Lab's BACK on its
## list, or Android Back (close_if_open), closes it. Built when it first opens (nothing at a world's start).

## The Lab's profile (the game's own by default; tests set theirs) and its supplies (LabScreen.supplies).
var screen_profile: ProfileData
var supplies := Callable()
var screen: LabScreen
var _panel: PanelContainer
## Owner #110 (VR round 4, VR-WONDER, idea 4): in a headset the bench by hand while float-or-sink or magnets shows.
var vr_bench: VrLabBench = null
## What the panel says to do on the bench (VR), in place of the 2D cards and scene the bench does by hand.
const VR_SORT_WORDS := "On the bench: put each cube in the basket you think it goes in."
const VR_TANK_WORDS := "On the bench: take each cube and let it go over the tank."
const VR_MAGNET_WORDS := "On the bench: take the magnet and hold it near each thing."
var _vr_words: Label
var _vr_hidden: Array[WeakRef] = []


func _ready() -> void:
	name = "LabPanel"
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()


func open() -> void:
	if _panel == null:
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.5)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(center)
		_panel = PanelContainer.new()
		center.add_child(_panel)
	if screen:
		_panel.remove_child(screen)
		screen.queue_free()
	screen = LabScreen.new()
	if screen_profile:
		screen.profile = screen_profile
	screen.supplies = supplies
	screen.closed.connect(close)
	_panel.add_child(screen)
	visible = true
	_fit()
	Audio.play(&"ui_click")


func close() -> void:
	visible = false
	_vr_close_bench()   # owner #110


## Android Back: true when the Lab was open (now closed).
func close_if_open() -> bool:
	if not visible:
		return false
	close()
	return true


## A screen lower than the Lab's panel draws it smaller.
func _fit() -> void:
	var room := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var need := _panel.get_combined_minimum_size()
	var s := minf(1.0, minf((room.y - 16.0) / maxf(need.y, 1.0), (room.x - 16.0) / maxf(need.x, 1.0)))
	_panel.scale = Vector2(s, s)
	_panel.pivot_offset = need * 0.5


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()


# --- Owner #110 (VR round 4, VR-WONDER, idea 4 "the Lab bench by hand"; docs/devlog/parts/vr-r4-wonder.md): in a headset
# float-or-sink and magnets are done with the hands on a real bench (VrLabBench, under Vr) while their PREDICT, TRY and
# WHY pages show; the panel keeps the prompt, TRY IT!, WHAT HAPPENED? and the why cards. Off VR nothing of it is made. ---

func _process(_delta: float) -> void:
	vr_step()


## Every frame: the bench for the experiment showing (made, kept, or gone with its page or the Lab).
func vr_step() -> void:
	var want := visible and Vr.active() and screen != null and is_instance_valid(screen) \
		and screen.page in [LabScreen.PREDICT, LabScreen.TRY, LabScreen.WHY] \
		and LabBenchRules.by_hand(screen.experiment.get("scene", {}))
	if not want:
		_vr_close_bench()
		return
	if vr_bench == null or not is_instance_valid(vr_bench) or vr_bench.experiment_id != screen.experiment_id \
			or vr_bench.screen != screen:
		_vr_close_bench()
		vr_bench = VrLabBench.new()
		Vr.add_child(vr_bench)
		vr_bench.open(screen)
	_vr_dress()


## The words on the panel for the bench (VR; "" without one).
func vr_words() -> String:
	return _vr_words.text if _vr_words != null and is_instance_valid(_vr_words) and _vr_words.is_inside_tree() else ""


## While the bench is open: the page's 2D cards (PREDICT) or 2D scene (TRY) are not drawn twice (they stay, hidden: the
## bench presses the scene's buttons) and a line under the prompt says what to do on the bench.
func _vr_dress() -> void:
	var words := ""
	var copy: Control = null
	if screen.page == LabScreen.PREDICT:
		words = VR_SORT_WORDS
		copy = screen.predict_answer
	elif screen.page == LabScreen.TRY:
		words = VR_MAGNET_WORDS if screen.model is LabMagnet else VR_TANK_WORDS
		copy = screen.view
	if copy != null and is_instance_valid(copy) and copy.visible:
		copy.visible = false
		_vr_hidden.append(weakref(copy))
	if words == "":
		_vr_drop_words()
		return
	if _vr_words == null or not is_instance_valid(_vr_words) or _vr_words.get_parent() != screen:
		_vr_drop_words()
		_vr_words = SchoolUi.words(words, 28, 1100)
		_vr_words.name = "VrBenchWords"
		_vr_words.add_theme_color_override("font_color", SchoolUi.HINT)
		screen.add_child(_vr_words)
		screen.move_child(_vr_words, mini(2, screen.get_child_count() - 1))   # under the header and the prompt
	_vr_words.text = words


func _vr_drop_words() -> void:
	if _vr_words != null and is_instance_valid(_vr_words):
		_vr_words.queue_free()
		if _vr_words.get_parent():
			_vr_words.get_parent().remove_child(_vr_words)
	_vr_words = null


func _vr_undress() -> void:
	for w: WeakRef in _vr_hidden:
		var c := w.get_ref() as Control
		if c != null and is_instance_valid(c):
			c.visible = true
	_vr_hidden.clear()
	_vr_drop_words()


func _vr_close_bench() -> void:
	if vr_bench != null and is_instance_valid(vr_bench):
		vr_bench.close()
	vr_bench = null
	if not _vr_hidden.is_empty() or _vr_words != null:
		_vr_undress()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		_vr_close_bench()
