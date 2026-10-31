extends Node
## The steps of tools/reel_preview.gd (a Node, so it may use the autoloads and the Shorts' classes): the reel studio's
## window, its frame sheets and its pictures.

const SHEET_STEP := 0.5
const CELL := Vector2i(180, 320)
const SHEET_COLUMNS := 12
const STUDIO := Vector2i(1280, 760)

var ids: Array[String] = []
var at := 0
var player: ShortPlayer
var slider: HSlider
var time_label := Label.new()
var title := Label.new()
var findings := Label.new()
var scenes_box := VBoxContainer.new()
var play_button: Button
var marks := SceneMarks.new()
var _out := ""
## The Reel Studio (owner #96): a cinematic reel is reviewed live (its 3D stage); --video shows its rendered video.
var _live := true


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED   # the studio and its sheets pixel for pixel
	Scene3DModels.warm()   # owner #96: the 3D stages' maps and pictures, as the Theater opening makes them
	Scene3DModels.sync_blocks = true   # round 2: a sheet never shows a blocks model still being meshed
	FlightLooks.settle()
	_out = ProjectSettings.globalize_path("user://reel_studio")
	DirAccess.make_dir_recursive_absolute(_out)
	print("REEL dir %s" % _out)
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	_live = not args.has("video")
	if args.has("all"):
		ids.append_array(ShortLibrary.hand_ids())
	if args.has("short"):
		ids.append_array(str(args.short).split(",", false))
	if ids.is_empty():
		ids.append(ShortLibrary.hand_ids()[0])
	if args.has("sheet"):
		for id in ids:
			await _sheet(id)
		get_tree().quit()
		return
	_build_studio()
	_open(0)
	if args.has("shot"):
		player.seek(float(args.get("at", "0")))
		_sync()
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "%s/studio_%s.png" % [_out, ids[0].replace(":", "_")]
		get_viewport().get_texture().get_image().save_png(path)
		print("REEL studio picture %s" % path)
		get_tree().quit()


# --- Frame sheets ---------------------------------------------------------------------------------------------------

## Every half second of the Short as one picture: CELL-sized frames in rows of SHEET_COLUMNS, each with its time and
## scene in its corner. The player runs the real Short (its own actors, captions, backdrops) at half the stage's size.
func _sheet(id: String) -> void:
	var s := ShortLibrary.get_short(id)
	if s.is_empty():
		print("REEL no short %s" % id)
		return
	var length := ShortTimeline.length(s)
	var times: Array[float] = []
	var t := SHEET_STEP * 0.5
	while t < length:
		times.append(t)
		t += SHEET_STEP
	var rows := ceili(float(times.size()) / SHEET_COLUMNS)
	get_window().size = CELL
	await get_tree().process_frame
	var p := ShortPlayer.new()
	p.size = Vector2(CELL)
	p.hide_play_sign = true
	p.prefer_live = _live
	add_child(p)
	p.build(s)
	if p.plate() is VideoView:
		(p.plate() as VideoView).exact = true   # every half second as the video shows it
	var stamp := Label.new()
	stamp.add_theme_font_size_override("font_size", 13)
	stamp.add_theme_color_override("font_color", Color.WHITE)
	stamp.add_theme_color_override("font_outline_color", Color.BLACK)
	stamp.add_theme_constant_override("outline_size", 4)
	stamp.position = Vector2(4, 12)
	add_child(stamp)
	var sheet := Image.create(CELL.x * mini(times.size(), SHEET_COLUMNS), CELL.y * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.12))
	for i in times.size():
		p.seek(times[i])
		stamp.text = "%.1f s  #%d" % [times[i], int(ShortTimeline.at(s, times[i]).scene) + 1]
		for k in (4 if p.plate() != null else 2):   # a 3D stage renders the frame after its pose; a video decodes
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		if img.get_size() != CELL:
			img.resize(CELL.x, CELL.y)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % SHEET_COLUMNS) * CELL.x, (i / SHEET_COLUMNS) * CELL.y))
	var path := "%s/%s_sheet.png" % [_out, id.replace(":", "_")]
	sheet.save_png(path)
	print("REEL sheet %s %d frames %.1f s %s" % [id, times.size(), length, path])
	p.queue_free()
	stamp.queue_free()
	await get_tree().process_frame


# --- The studio -----------------------------------------------------------------------------------------------------

func _build_studio() -> void:
	get_window().size = STUDIO
	var back := ColorRect.new()
	back.color = Color("1b1f2e")
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var theme_holder := Control.new()
	theme_holder.theme = UiKit.theme()
	theme_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(theme_holder)
	player = ShortPlayer.new()
	player.prefer_live = _live
	player.position = Vector2(24, 20)
	player.size = Vector2(ShortRules.STAGE)
	theme_holder.add_child(player)
	var right := VBoxContainer.new()
	right.position = Vector2(410, 20)
	right.size = Vector2(840, 640)
	right.add_theme_constant_override("separation", 10)
	theme_holder.add_child(right)
	title.add_theme_font_size_override("font_size", 30)
	right.add_child(title)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	right.add_child(buttons)
	for b: Array in [["< SHORT", func() -> void: _open(at - 1)], ["PLAY", func() -> void: _toggle()],
			["SHORT >", func() -> void: _open(at + 1)], ["REDUCE MOTION", func() -> void: _reduce()]]:
		var btn := UiKit.big_button(str(b[0]), Color(0.2, 0.26, 0.42), Vector2(190, 56))
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(b[1])
		buttons.add_child(btn)
		if b[0] == "PLAY":
			play_button = btn
	time_label.add_theme_font_size_override("font_size", 22)
	right.add_child(time_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(840, 330)
	scroll.add_child(scenes_box)
	right.add_child(scroll)
	findings.add_theme_font_size_override("font_size", 16)
	findings.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	findings.custom_minimum_size = Vector2(840, 0)
	right.add_child(findings)
	slider = HSlider.new()
	slider.position = Vector2(24, 676)
	slider.size = Vector2(1232, 30)
	slider.step = 0.01
	slider.value_changed.connect(func(v: float) -> void:
		if player.playing:
			player.pause()
		player.seek(v)
		_sync())
	theme_holder.add_child(slider)
	marks.position = Vector2(24, 706)
	marks.size = Vector2(1232, 30)
	theme_holder.add_child(marks)


func _open(i: int) -> void:
	at = posmod(i, ids.size())
	var s := ShortLibrary.get_short(ids[at])
	player.build(s)
	slider.max_value = player.length()
	title.text = "%s  (%s, %.1f s)" % [s.get("title", ids[at]), ids[at], player.length()]
	for c in scenes_box.get_children():
		c.queue_free()
	var scenes := ShortTimeline.scenes(s)
	for k in scenes.size():
		var b := Button.new()
		b.text = "%d  %.1f s  %s" % [k + 1, ShortTimeline.scene_start(s, k), str(scenes[k].get("caption", ""))]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(func() -> void:
			player.pause()
			player.seek(ShortTimeline.scene_start(s, k) + 0.01)
			_sync())
		scenes_box.add_child(b)
	var problems := ShortCheck.problems(s, s.get("lesson", false) == true)
	problems.append_array(ReelCheck.problems(s))   # owner #96: a stage's and a video's own checks
	findings.text = "Style and checker: all good." if problems.is_empty() else "Checker:\n" + "\n".join(problems.slice(0, 8))
	marks.short = s
	marks.queue_redraw()
	_sync()


func _toggle() -> void:
	player.toggle()
	_sync()


func _reduce() -> void:
	player.reduce_motion = not player.reduce_motion
	player.seek(player.time)
	_sync()


func _process(delta: float) -> void:
	if player != null and player.playing:
		player.advance(delta)
		_sync()


func _sync() -> void:
	slider.set_value_no_signal(player.time)
	var where := ShortTimeline.at(player.short, player.time)
	time_label.text = "%.2f s of %.1f   scene %d   %s%s" % [player.time, player.length(), int(where.scene) + 1,
		"playing" if player.playing else "paused", "   (reduce motion)" if player.reduce_motion else ""]
	play_button.text = "PAUSE" if player.playing else "PLAY"


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if player == null or k == null or not k.pressed:
		return
	var step := 1.0 if k.shift_pressed else 0.1
	match k.keycode:
		KEY_SPACE:
			_toggle()
		KEY_LEFT, KEY_RIGHT:
			player.pause()
			player.seek(player.time + (step if k.keycode == KEY_RIGHT else -step))
			_sync()
		KEY_PAGEUP:
			_open(at - 1)
		KEY_PAGEDOWN:
			_open(at + 1)
		KEY_HOME:
			player.pause()
			player.seek(0.0)
			_sync()
		KEY_R:
			_reduce()


## The timeline's ticks: where each scene starts, and its number.
class SceneMarks:
	extends Control
	var short: Dictionary = {}

	func _draw() -> void:
		var length := ShortTimeline.length(short)
		if length <= 0.0:
			return
		var font := get_theme_default_font()
		for k in ShortTimeline.scenes(short).size():
			var x := size.x * ShortTimeline.scene_start(short, k) / length
			draw_line(Vector2(x, 0), Vector2(x, 12), Color("ffd23f"), 2.0)
			draw_string(font, Vector2(x + 4, 26), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
