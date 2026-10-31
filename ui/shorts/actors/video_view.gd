class_name VideoView
extends Control
## The Reel Studio (owner #96, spec §5.12b): a rendered reel's video (ReelPack: `assets/reels/<file>.ogv`, Theora) in a
## Short: a cinematic reel's whole picture (ShortPlayer's plate, its time the Short's) or a `video` actor's clip (its
## time the scene's plus `start`). The video is driven by the Short's clock: show_at(t) while playing lets it play on
## by itself and only seeks when it drifts (a seek decodes from the last keyframe: tens of ms). Before it first plays
## (a neighbour in the feed, its poster) it shows the reel's still and opens nothing: the video is opened when it plays.
## `exact` (the studio's frame sheets) decodes every moment sought instead. Until the video is here at all (the
## browser's reels pack) the still shows with a "coming…" sticker, and can_play() is false: the Short waits.

const DRIFT := 0.25            # seconds the video may be off the Short's clock while playing before it is sought
const COMING := "This video is on its way…"

var file := ""
var start := 0.0
var playing := false
var time := -1.0
## Decode every moment sought, paused or not (the frame sheets): else the still stands in until the video plays.
var exact := false

var video := VideoStreamPlayer.new()
var _still := TextureRect.new()
var _coming := Label.new()
var _loaded := false
var _started := false


func _init(reel_file: String = "", start_at: float = 0.0) -> void:
	name = "VideoView"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	file = reel_file
	start = start_at
	add_to_group(ReelPack.VIEWS)
	_still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_still.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_still.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_still)
	video.expand = true
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video.volume_db = -80.0   # the pictures only: the Short plays its own voice and sounds
	video.loop = false
	video.visible = false
	add_child(video)
	_coming.text = COMING
	_coming.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coming.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_coming.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_coming.add_theme_font_size_override("font_size", 24)
	_coming.add_theme_color_override("font_color", Color.WHITE)
	_coming.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.1))
	_coming.add_theme_constant_override("outline_size", 8)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.12, 0.2, 0.82)
	box.set_corner_radius_all(18)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	_coming.add_theme_stylebox_override("normal", box)
	_coming.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_coming)
	resized.connect(_layout)
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree():
			stop())   # a scene that ends, a Short that leaves the screen: no decoding behind it
	_look()


## True when the video is here (it can play).
func can_play() -> bool:
	return _loaded


## True once the video itself shows (it played, or a moment was sought exactly).
func shows_video() -> bool:
	return video.visible


## The reels pack came in (ReelPack.on_pack_loaded): the video may be here now.
func reels_arrived() -> void:
	if not _loaded:
		_look()


func _look() -> void:
	_loaded = file != "" and ReelPack.present(file)
	_still.texture = ReelPack.still(file) if file != "" else null
	_coming.visible = not _loaded
	_layout()


## Opens the video (the first time it is needed) and shows it instead of the still.
func _open() -> void:
	if video.stream == null:
		var s := VideoStreamTheora.new()
		s.file = ReelPack.video_path(file)
		video.stream = s
	video.visible = true
	_still.visible = false


func _layout() -> void:
	video.position = Vector2.ZERO
	video.size = size
	_still.position = Vector2.ZERO
	_still.size = size
	var w := minf(size.x - 40.0, 300.0)
	_coming.size = Vector2(w, 0)
	_coming.reset_size()
	_coming.position = Vector2((size.x - _coming.size.x) * 0.5, size.y * 0.38)


## Plays (the Short plays) or holds (paused: a seek shows the exact moment once it has played).
func set_playing(on: bool) -> void:
	playing = on
	if not _loaded or not is_inside_tree():
		return
	if on:
		_started = true
		_open()
		if not video.is_playing():
			video.play()
			video.stream_position = maxf(time, 0.0) + start
		video.paused = false
	elif video.is_playing():
		video.paused = true


## The moment `t` (the Short's or the scene's seconds).
func show_at(t: float) -> void:
	var was := time
	time = t
	if not _loaded or not is_inside_tree() or not (playing or _started or exact):
		return   # a poster: the still stands in, nothing is decoded
	_open()
	var want := t + start
	if not video.is_playing():
		video.play()
		video.paused = not playing
		video.stream_position = want
		return
	if playing:
		video.paused = false
		if absf(video.stream_position - want) > DRIFT or t < was:
			video.stream_position = want
	elif t != was:
		video.paused = true
		video.stream_position = want


## Stops decoding (the Short left the screen); the still stands in again until it plays.
func stop() -> void:
	playing = false
	_started = false
	if video.is_playing():
		video.stop()
	if not exact:
		video.visible = false
		_still.visible = true
