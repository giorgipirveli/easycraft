class_name MyStampBar
extends Control
## Saving a build as one of My Stamps (M3 Task 20b, spec §14.21): the palette's NEW STAMP opens this bar at the
## top of the screen (the world stays visible and tappable, like SHARE's picking bar); the next tap on the world
## picks the connected build under it (M4 I's BuildPicker, at most MyStampBook.MAX_SIDE a side), which glows (M4
## I's BuildOutline); SAVE STAMP keeps it in MyStampBook (this device), turned so the side the child sees is its
## front. The build stays in the world. While picking, BlockInteractor.tap_override takes the world's taps.

const PICK := &"pick"
const PICKED := &"picked"
const BAR_TOP := 130.0            # the toasts sit above it
const BAR_WORDS := 560.0          # clear of the top corners' buttons

var interactor: BlockInteractor
var world: WorldService
var outline: BuildOutline
## () -> Vector3i: the way the child looks (Blueprints.facing_for_yaw of the camera).
var facing: Callable = func() -> Vector3i: return Vector3i(0, 0, -1)
## A toast on the HUD (the sandbox gives it).
var toast: Callable = func(_text: String) -> void: pass
var now_unix: Callable = func() -> int: return int(Time.get_unix_time_from_system())

var step: StringName = &""
var picked := {}                  # BuildPicker.pick's answer
var message: Label
var save_button: Button

var _box := PanelContainer.new()
var _words: Label
var _cancel: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_box.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.96), 22, 18))
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_box)
	_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_box.offset_top = BAR_TOP
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.grow_vertical = Control.GROW_DIRECTION_END
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_box.add_child(column)
	_words = OnlineUi.words("", 30, BAR_WORDS)
	column.add_child(_words)
	save_button = OnlineUi.button("SAVE\nSTAMP", UiKit.GREEN, Vector2(220, 100))
	save_button.name = "SaveStamp"
	save_button.pressed.connect(save)
	_cancel = OnlineUi.button("CANCEL", UiKit.BLUE, Vector2(200, 100))
	_cancel.name = "Cancel"
	_cancel.pressed.connect(close)
	column.add_child(OnlineUi.row([save_button, _cancel], 14))
	message = OnlineUi.words("", 24, BAR_WORDS)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	column.add_child(message)


func is_open() -> bool:
	return visible


## NEW STAMP: the next tap on the world picks a build.
func open() -> void:
	visible = true
	step = PICK
	picked = {}
	if outline:
		outline.clear()
	interactor.tap_override = pick_at_screen
	_words.text = "Tap your build!"
	save_button.visible = false
	message.text = ""
	var book := MyStampBook.current()
	if book.is_full():
		message.text = MyStampBook.message("full")


func close() -> void:
	visible = false
	step = &""
	picked = {}
	if interactor and interactor.tap_override == Callable(self, &"pick_at_screen"):
		interactor.tap_override = Callable()
	if outline:
		outline.clear()


## A tap on the world while picking (true: the tap is used).
func pick_at_screen(screen_pos: Vector2) -> bool:
	var hit := interactor.ray_at(screen_pos)
	if hit == null:
		message.text = BuildPicker.message("not_a_build")
		return true
	return pick_cell(hit.position)


func pick_cell(cell: Vector3i) -> bool:
	var r := BuildPicker.pick(cell, world.get_block, MyStampBook.MAX_SIDE, MyStampBook.MAX_BLOCKS)
	if r.has("error"):
		message.text = MyStampBook.message("too_big") if r.error == "too_big" else BuildPicker.message(r.error)
		return true
	picked = r
	step = PICKED
	if outline:
		outline.show_blocks(r.blocks)
	Fx.burst(world, Vector3(cell) + Vector3(0.5, 0.5, 0.5), Color("b48cff"), 18, 4.0, 0.12, 0.7, 3.0)
	Audio.play(&"chime", Vector3(cell))
	_words.text = tr("This one? %s") % Lang.blocks((r.blocks as Dictionary).size())
	save_button.visible = true
	message.text = "Or tap another build."
	return true


## SAVE STAMP: into this device's book (the build stays in the world).
func save() -> void:
	if picked.is_empty():
		return
	var book := MyStampBook.current()
	var why := MyStampBook.refusal(picked.blocks, book)
	if why != "":
		message.text = MyStampBook.message(why)
		return
	var slot := book.add(picked.blocks, facing.call(), now_unix.call())
	if slot < 0:
		message.text = MyStampBook.message("too_big")
		return
	MyStampBook.save_current()
	Audio.play(&"sparkle")
	close()
	toast.call(tr("Saved as %s! Find it in the palette's STAMPS page.") % MyStampBook.name_of(slot))


## The bar's box, for the HUD's look area (its taps never build).
func blockers() -> Array[Control]:
	return [_box]
