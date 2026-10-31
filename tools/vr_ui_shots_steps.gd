extends Node
## The steps of tools/vr_ui_shots.gd (a Node, so it may use the autoloads and the game's classes).

const SCREENS := preload("res://tools/vr_ui_screens.gd")

var _out := ""


class Owner:
	extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	_out = ProjectSettings.globalize_path("user://vr_ui_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	Profile.data = ProfileData.new()
	Profile.data.username = "Mia"
	Profile.data.age_band = AgeBand.TEEN_PLUS
	Profile.data.settings.simple_asked = true
	Vr.simulate(true)
	Vr.ui_viewport()
	for n: String in SCREENS.NAMES:
		await _screen(n)
	await _keyboard()
	await _break_card()
	get_tree().quit()


func _holder() -> Array:
	var o := Owner.new()
	add_child(o)
	var layer := CanvasLayer.new()
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(VrPanelRules.CANVAS)
	var bg := ColorRect.new()   # the eye panel shows the world behind it; a dim sky here
	bg.color = Color(0.25, 0.42, 0.6)
	bg.size = holder.size
	holder.add_child(bg)
	layer.add_child(holder)
	UiLayers.route(layer, o)
	return [o, holder]


func _screen(screen_name: String) -> void:
	var made := _holder()
	var screen: Control = SCREENS.build(screen_name, made[1])
	await _wait(0.1)
	SCREENS.open(screen_name, screen)
	await _wait(0.3)
	if screen_name == "shorts_maker":
		(screen as ShortsView).filter_buttons[ShortFeed.MINE].pressed.emit()
		await _wait(0.1)
		(screen as ShortsView).make_big.pressed.emit()
	await _wait(0.5)
	await _save(screen_name, made[1])
	(made[0] as Node).free()
	await _wait(0.1)


func _keyboard() -> void:
	var made := _holder()
	var box := VBoxContainer.new()
	box.position = Vector2(380, 70)
	var title := UiKit.title("Pick your name")
	box.add_child(title)
	var edit := LineEdit.new()
	edit.placeholder_text = "Your name"
	edit.custom_minimum_size = Vector2(520, 84)
	box.add_child(edit)
	(made[1] as Control).add_child(box)
	await _wait(0.1)
	edit.grab_focus()
	await _wait(0.2)
	for k: String in ["SHIFT", "m", "i", "a"]:
		VrUi.instance.keyboard.key(k).pressed.emit()
		await _wait(0.05)
	await _wait(0.3)
	await _save("keyboard", made[1])
	(made[0] as Node).free()
	await _wait(0.1)


func _break_card() -> void:
	VrUi.instance.break_card.open(30)
	await _wait(0.4)
	await _save("break_card", VrUi.instance.break_card)
	VrUi.instance.break_card.close()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _save(shot_name: String, root: Node) -> void:
	await RenderingServer.frame_post_draw
	var image := Vr.ui_viewport().get_texture().get_image()
	var path := _out.path_join("%s.png" % shot_name)
	image.save_png(path)
	var smallest := INF
	for c in _texts(root):
		smallest = minf(smallest, VrReadability.drawn_px(c))
	var small := VrReadability.too_small(root)
	print("VR_UI_SHOT %s %dx%d smallest_word=%.0fpx under_24=%d" % [path, image.get_width(), image.get_height(),
		smallest if smallest < INF else 0.0, small.size()])


func _texts(n: Node) -> Array[Control]:
	var out: Array[Control] = []
	if n.has_meta(VrReadability.PICTURE):
		return out
	if n is Control and VrReadability.is_text(n as Control) and (n as Control).is_visible_in_tree() \
			and VrReadability._words(n as Control) != "":
		out.append(n as Control)
	for c in n.get_children():
		out.append_array(_texts(c))
	return out
