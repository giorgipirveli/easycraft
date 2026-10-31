class_name VrBreakCard
extends Control
## VR on the Meta Quest (owner #101, P2; the plan's ruling 3): after vr_break_minutes in the headset (30 first; never
## when the child picked NEVER on VR COMFORT) a card on the eye panel says it is time for a rest. The game waits behind
## it (paused, as the pause menu does; a game already paused stays so) and I'M BACK starts the time again. VrUi counts
## the time (VrUi.worn) and opens it; PadFocus takes it, so A presses I'M BACK.

signal back

## Over the routed layers' menus, under the keyboard (125).
const LAYER := 115

var words := Label.new()
var back_button := UiKit.big_button(VrWords.BREAK_BACK, UiKit.GREEN, Vector2(380, 100))

var _was_paused := false


## True when the next card is due: `minutes` (> 0) since the last one (`last_at`, seconds in the headset).
static func due(worn_seconds: float, minutes: int, last_at: float) -> bool:
	return minutes > 0 and worn_seconds - last_at >= minutes * 60.0


func _init() -> void:
	name = "VrBreakCard"
	theme = UiKit.theme()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS   # it is what the paused game shows
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	panel.add_child(v)
	v.add_child(ReadAloud.with_speaker(UiKit.title(VrWords.BREAK_TITLE), v))
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.custom_minimum_size.x = 640
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(words)
	back_button.name = "BreakBack"
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(close)
	v.add_child(back_button)


## Shows the card after `minutes` in the headset; the game waits.
func open(minutes: int) -> void:
	words.text = VrWords.BREAK_SAY % minutes
	visible = true
	ReadAloud.auto(VrWords.BREAK_TITLE)
	PadFocus.take(self, back_button)
	if is_inside_tree():
		_was_paused = get_tree().paused
		get_tree().paused = true


## I'M BACK: the card goes and the game goes on (as it was).
func close() -> void:
	if not visible:
		return
	visible = false
	if is_inside_tree() and not _was_paused:
		get_tree().paused = false
	back.emit()
