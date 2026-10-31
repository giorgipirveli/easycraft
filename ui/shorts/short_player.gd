class_name ShortPlayer
extends Control
## Plays one Short (owner #94, spec §5.12b) on a 9:16 stage the game draws itself: its backdrop, its actors moving as
## ShortTimeline says, the caption always on screen (big white letters on a dark band, popping in with each scene), a
## thin progress bar per scene at the top, the words read aloud (the game's read-aloud voice) and the sounds on cue.
## `seek(t)` shows any moment exactly as playing to it would; `play()` goes on from there and loops. The voice reads
## each scene on the first pass only (a loop is quiet but for its sounds). While paused a big PLAY sign shows.
## Built once per Short (build()), every scene's actors at once, so nothing is made while it plays.
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): a Short may say `"voice": false` (its maker turned the voice off:
## captions only) and `"music": "<a MusicPieces id>"` (one of the game's pieces under it, from its start, quietly, on the
## effects' bus: the game's music bus rests while a Short plays; it loads on a worker when the Short is built).

signal scene_entered(index: int)
signal looped

const CAPTION_MARGIN := 10.0
const CAPTION_PAD := Vector2(12, 8)
const BAR_TOP := 10.0
const BAR_H := 5.0
const CAPTION_POP := 0.3
const CAMERA_PUSH := 1.04
const CAMERA_FOCUS := Vector2(180, 240)
## The caption's letter sizes (the style guide's), biggest first: the first that fits the band under the actors.
const CAPTION_SIZES := ShortStyle.CAPTION_SIZES
const BURST_SECONDS := 0.9

var short: Dictionary = {}
var time := 0.0
var playing := false
var voice_on := true
var reduce_motion := false
## Whole passes played (the voice reads on the first only).
var passes := 0
## Pictures (tools/shorts_shots.gd): no PLAY sign over a paused frame.
var hide_play_sign := false
## What was played, for the tests: "effect:pop", "tune", "say:<words>".
var events: Array[String] = []
## The Reel Studio (owner #96): a cinematic reel's picture (its `stage` live: Scene3DView; its `video`: VideoView), under
## the actors and the caption. prefer_live: the live stage even for a video reel (the studio's tools); plate_only: only
## that picture (tools/reel_render.gd films it into the reel's video).
var prefer_live := false
var plate_only := false
var _plate: Control

var stage := Control.new()
var caption := Label.new()
var _caption_box := PanelContainer.new()
var _back := ShortBackdrop.new()
var _back_before := ShortBackdrop.new()
var _layer := Control.new()
var _overlay := PlayerOverlay.new()
var _actors: Array = []          # per scene: [ShortActor]
var _tunes := {}                 # "scene:sound" -> the tune's key in the shared cache (made on a worker)
var _tune_player := AudioStreamPlayer.new()
var _music_player := AudioStreamPlayer.new()
var _music_path := ""
var _scene := -1
var _caption_scene := -1
var _burst := -1.0
var _length := 0.0
var _started := false            # played since it was built (before: its poster, a preview)
var _spoke := false

static var _tune_cache := {}      # a tune's JSON -> {stream, task (while its worker runs)}
static var _music_cache := {}     # a piece's path -> its stream (My Shorts' music)
static var _reaping := false


func _init() -> void:
	set_meta(VrReadability.PICTURE, true)   # owner #101: a Short's stage is a picture: its words keep their own size in VR
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.size = ShortRules.STAGE
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	stage.add_child(_back)
	stage.add_child(_back_before)
	_back_before.visible = false
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.size = ShortRules.STAGE
	stage.add_child(_layer)
	var band := StyleBoxFlat.new()
	band.bg_color = Color(0.04, 0.05, 0.1, 0.84)
	band.set_corner_radius_all(18)
	band.content_margin_left = CAPTION_PAD.x
	band.content_margin_right = CAPTION_PAD.x
	band.content_margin_top = CAPTION_PAD.y
	band.content_margin_bottom = CAPTION_PAD.y
	band.border_width_bottom = 5
	_caption_box.add_theme_stylebox_override("panel", band)
	_caption_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_constant_override("outline_size", 0)
	caption.add_theme_constant_override("line_spacing", -2)
	caption.custom_minimum_size.x = ShortRules.STAGE.x - 2.0 * (CAPTION_MARGIN + CAPTION_PAD.x)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_box.add_child(caption)
	stage.add_child(_caption_box)
	_overlay.player = self
	_overlay.size = ShortRules.STAGE
	stage.add_child(_overlay)
	_tune_player.bus = Audio.BUS
	add_child(_tune_player)
	_music_player.bus = Audio.BUS
	_music_player.volume_db = MyShortRules.MUSIC_DB
	add_child(_music_player)
	resized.connect(_fit)
	set_process(false)


## Makes every scene's actors for `s` (and its tunes), and shows its poster: the first scene just before its end.
func build(s: Dictionary) -> void:
	stop_voice()
	for list: Array in _actors:
		for a: ShortActor in list:
			a.queue_free()
	_actors.clear()
	_tunes.clear()
	_music_player.stop()
	short = s
	_music_path = _ask_music(s)
	_length = ShortTimeline.length(s)
	_make_plate(s)
	var topic := ShortRules.topic_colour(str(s.get("topic", "")))
	(_caption_box.get_theme_stylebox("panel") as StyleBoxFlat).border_color = topic
	var scenes := ShortTimeline.scenes(s)
	for i in scenes.size():
		var list: Array = []
		for d: Variant in scenes[i].get("actors", []):
			if d is Dictionary:
				var a := ShortActor.new(d)
				a.visible = false
				_layer.add_child(a)
				list.append(a)
		_actors.append(list)
		var sounds: Array = scenes[i].get("sounds", [])
		for k in sounds.size():
			if sounds[k] is Dictionary and (sounds[k] as Dictionary).has("tune"):
				_tunes["%d:%d" % [i, k]] = make_tune(sounds[k].tune)
	passes = 0
	_scene = -1
	_caption_scene = -1
	playing = false
	_started = false
	seek(poster_time())
	_fit()


## The poster's moment: the first scene with its actors arrived.
func poster_time() -> float:
	var scenes := ShortTimeline.scenes(short)
	if scenes.is_empty():
		return 0.0
	return ShortTimeline.seconds_of(scenes[0]) * 0.85


func length() -> float:
	return _length


func is_built() -> bool:
	return not short.is_empty()


## Plays on from here (from the start the first time: the poster is only a preview).
func play(from_start: bool = false) -> void:
	if short.is_empty() or not can_play():
		_overlay.queue_redraw()
		return
	if from_start or not _started:
		passes = 0
		_scene = -1
		seek(0.0)
		_started = true
	playing = true
	set_process(true)
	_media(true)
	_overlay.queue_redraw()
	_enter(ShortTimeline.at(short, time).scene if _scene < 0 else _scene, true)


func pause() -> void:
	stop_voice()
	playing = false
	_media(false)
	_tune_player.stop()
	_music_player.stop()
	_overlay.queue_redraw()
	set_process(_burst >= 0.0)


func toggle() -> void:
	if playing:
		pause()
	else:
		play()


## The voice stops (a pause, a swipe, leaving).
func stop_voice() -> void:
	if _spoke:
		_spoke = false
		ReadAloud.voice.stop()


## A heart grows over the Short and floats away (a double tap likes it).
func burst_heart() -> void:
	_burst = 0.0
	set_process(true)


func _process(delta: float) -> void:
	if playing and _music_path != "" and not _music_player.playing:
		_start_music()
	if _burst >= 0.0:
		_burst += delta
		if _burst > BURST_SECONDS:
			_burst = -1.0
		_overlay.queue_redraw()
	if not playing:
		if _burst < 0.0:
			set_process(false)
		return
	advance(delta)


## Moves the Short on by `delta` seconds: sounds whose cue passes play, a new scene is read aloud, the end loops.
func advance(delta: float) -> void:
	var from := time
	var to := time + delta
	if to >= _length:
		_cues(from, _length)
		passes += 1
		looped.emit()
		_music_player.stop()   # the music starts again with the Short
		to = fposmod(to - _length, maxf(_length, 0.001))
		_scene = -1
		seek(to)
		_cues(0.0, to)
		_enter(ShortTimeline.at(short, to).scene, false)
		return
	_cues(from, to)
	seek(to)
	var now: int = ShortTimeline.at(short, to).scene
	if now != _scene:
		_enter(now, false)


## Shows the moment `t` (0 .. length) exactly: the scene, its actors, the backdrop, the caption, the bars.
func seek(t: float) -> void:
	time = clampf(t, 0.0, _length)
	var where := ShortTimeline.at(short, time)
	var i: int = where.scene
	var local: float = where.local
	var scenes := ShortTimeline.scenes(short)
	if scenes.is_empty():
		return
	var before := i - 1 if i > 0 and local < ShortTimeline.TRANSITION else -1
	for k in _actors.size():
		if k != i and k != before:
			for a: ShortActor in _actors[k]:
				if a.visible:
					a.visible = false
	if before >= 0:
		var fade := 1.0 - local / ShortTimeline.TRANSITION
		var end := ShortTimeline.seconds_of(scenes[before])
		var list: Array = _actors[before]
		for k in list.size():
			var st := ShortTimeline.actor_state(list[k].data, end, reduce_motion)
			st.alpha = float(st.alpha) * fade
			(list[k] as ShortActor).apply(st, end)
		_back_before.visible = true
		_back_before.modulate.a = fade
		_back_before.show_scene(scenes[before], end)
	elif _back_before.visible:
		_back_before.visible = false
	_back.show_scene(scenes[i], local)
	_camera(scenes[i], local)
	for a: ShortActor in _actors[i]:
		a.apply(ShortTimeline.actor_state(a.data, local, reduce_motion), local)
	_show_caption(i, local)
	if _plate != null:
		_plate.call(&"show_at", time)
	_overlay.queue_redraw()


## The Reel Studio (owner #96): a cinematic reel's picture under its actors: its video when it has one (unless the live
## stage is preferred), else its 3D stage live; none for any other Short.
func _make_plate(s: Dictionary) -> void:
	if _plate != null:
		_plate.queue_free()
		_plate = null
	if s.has("video") and not (prefer_live and s.has("stage")):
		_plate = VideoView.new(str(s.video))
	elif s.get("stage") is Dictionary:
		var view := Scene3DView.new()
		if plate_only:
			view.quality = StudioRules.RENDER
		_plate = view
	if _plate == null:
		_layer.visible = true
		return
	_plate.name = "Plate"
	_plate.size = ShortRules.STAGE
	stage.add_child(_plate)
	stage.move_child(_plate, _back_before.get_index() + 1)
	if _plate is Scene3DView:
		(_plate as Scene3DView).build(s.stage)
	_layer.visible = not plate_only
	_caption_box.visible = not plate_only
	_overlay.visible = not plate_only


## The reel's picture (null for a Short without one): tests and tools.
func plate() -> Control:
	return _plate


## False while a video reel waits for its video (the browser's reels pack): its still and "coming…" show instead.
func can_play() -> bool:
	return not (_plate is VideoView) or (_plate as VideoView).can_play()


## The videos play or hold with the Short: the reel's picture and every video actor.
func _media(on: bool) -> void:
	if _plate is VideoView:
		(_plate as VideoView).set_playing(on)
	for list: Array in _actors:
		for a: ShortActor in list:
			var v: Variant = a.get_meta(&"view") if a.has_meta(&"view") else null
			if v is VideoView:
				(v as VideoView).set_playing(on)


## The camera (owner #96's review: long still moments looked cheap): over each scene it pushes in slowly on the actors,
## CAMERA_PUSH by default, round `focus`; a scene's `camera` {zoom: [from, to], focus: [x, y]} says its own; reduce
## motion holds it still. The captions and the bars never move.
func _camera(scene: Dictionary, local: float) -> void:
	var cam: Dictionary = scene.get("camera", {}) if scene.get("camera") is Dictionary else {}
	var zoom := ShortRules.point(cam.get("zoom")) if ShortRules.is_point(cam.get("zoom")) else Vector2(1.0, CAMERA_PUSH)
	var focus := ShortRules.point(cam.get("focus")) if ShortRules.is_point(cam.get("focus")) else CAMERA_FOCUS
	var k := 1.0 if reduce_motion else lerpf(zoom.x, zoom.y,
		ShortTimeline.ease_value("smooth", local / maxf(ShortTimeline.seconds_of(scene), 0.01)))
	_layer.pivot_offset = focus
	_layer.scale = Vector2(k, k)


## The actors showing now, for the tests: [[name, position, scale, rotation, alpha]].
func snapshot() -> Array:
	var out: Array = []
	for list: Array in _actors:
		for a: ShortActor in list:
			if a.visible:
				out.append([a.name, a.position, a.scale, a.rotation, a.modulate.a, a.draw_amount, a.value])
	return out


## The actors of scene `i` (tests).
func actors_of(i: int) -> Array:
	return _actors[i] if i >= 0 and i < _actors.size() else []


## The caption's band on the stage (at rest: after its pop).
func caption_rect() -> Rect2:
	return Rect2(_caption_box.position, _caption_box.size)


## The caption band's colour (the quality checks: its words against it).
func caption_colour() -> Color:
	return (_caption_box.get_theme_stylebox("panel") as StyleBoxFlat).bg_color


func scene_index() -> int:
	return ShortTimeline.at(short, time).scene


## A scene begins while playing: its words are read (the first pass), the moment's sounds play.
func _enter(i: int, _resumed: bool) -> void:
	_scene = i
	scene_entered.emit(i)
	var scenes := ShortTimeline.scenes(short)
	if i < 0 or i >= scenes.size():
		return
	if voice_on and passes == 0 and short.get("voice", true) != false:   # My Shorts: the maker may turn it off
		var words := str(scenes[i].get("say", ""))
		events.append("say:" + words)
		if ReadAloud.available():
			ReadAloud.voice.stop()
			ReadAloud.voice.speak(SchoolSpeech.spoken(words), Lang.current())
			_spoke = true


## Plays the sounds whose cues fall in (from, to] (a cue at 0 plays when a scene starts from its beginning).
func _cues(from: float, to: float) -> void:
	var scenes := ShortTimeline.scenes(short)
	var start := 0.0
	for i in scenes.size():
		var sounds: Array = scenes[i].get("sounds", [])
		for k in sounds.size():
			var cue := start + float(sounds[k].get("at", 0.0))
			if (cue > from or (from == 0.0 and cue == 0.0)) and cue <= to:
				_play_sound(sounds[k], "%d:%d" % [i, k])
		start += ShortTimeline.seconds_of(scenes[i])


func _play_sound(sound: Dictionary, key: String) -> void:
	if sound.has("effect"):
		events.append("effect:" + str(sound.effect))
		Audio.play(StringName(str(sound.effect)))
	elif _tunes.has(key):
		var stream := tune_stream(str(_tunes[key]))
		if stream:
			events.append("tune")
			_tune_player.stream = stream
			_tune_player.play()


## My Shorts: a Short's music (its path, "" for none: no music, or its file is not in yet: a browser's music pack),
## asked for on a worker thread now so that playing never waits.
func _ask_music(s: Dictionary) -> String:
	var id := StringName(str(s.get("music", "")))
	if id == &"" or not MusicPieces.present(id):
		return ""
	var path := MusicPieces.path(id)
	if not _music_cache.has(path) and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_request(path)
	return path


## The music from where the Short is (once its stream is in).
func _start_music() -> void:
	if not _music_cache.has(_music_path):
		if ResourceLoader.load_threaded_get_status(_music_path) != ResourceLoader.THREAD_LOAD_LOADED:
			return
		_music_cache[_music_path] = ResourceLoader.load_threaded_get(_music_path)
	var stream: AudioStream = _music_cache[_music_path]
	if stream == null:
		_music_path = ""
		return
	_music_player.stream = stream
	_music_player.play(fmod(time, maxf(stream.get_length(), 1.0)))


## Whether the Short's music is playing (tests).
func music_playing() -> bool:
	return _music_player.playing


## A tune's samples are made on a worker thread when its Short is built (a long tune took ~100 ms of a frame), kept for
## every Short that plays the same one. Returns its key.
static func make_tune(d: Variant) -> String:
	var key := JSON.stringify(d)
	if not _tune_cache.has(key):
		var box := {}
		_tune_cache[key] = box
		box.task = WorkerThreadPool.add_task(func() -> void: box.stream = SchoolSound.stream(d), false, "Short tune")
		_reap_later()
	return key


## Every worker's task is waited for once it is done (a frame's look; the pool wants each task waited).
static func _reap_later() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or _reaping:
		return
	_reaping = true
	tree.process_frame.connect(func() -> void: _reap(), CONNECT_ONE_SHOT)


static func _reap() -> void:
	_reaping = false
	var waiting := false
	for key: String in _tune_cache:
		var box: Dictionary = _tune_cache[key]
		if box.has("task"):
			if WorkerThreadPool.is_task_completed(int(box.task)):
				WorkerThreadPool.wait_for_task_completion(int(box.task))
				box.erase("task")
			else:
				waiting = true
	if waiting:
		_reap_later()


## The tune's stream (waiting for its worker if it is not done yet: it has had the Short's time since it was built).
static func tune_stream(key: String) -> AudioStreamWAV:
	var box: Dictionary = _tune_cache.get(key, {})
	if box.has("task"):
		WorkerThreadPool.wait_for_task_completion(int(box.task))
		box.erase("task")
	return box.get("stream")


func _show_caption(i: int, local: float) -> void:
	var scenes := ShortTimeline.scenes(short)
	if i != _caption_scene:
		_caption_scene = i
		caption.text = str(scenes[i].get("caption", ""))
		fit_caption()
	var box := _caption_box.size
	_caption_box.position = Vector2(CAPTION_MARGIN, ShortRules.STAGE.y - CAPTION_MARGIN - box.y)
	_caption_box.pivot_offset = box * 0.5
	var p := clampf(local / CAPTION_POP, 0.0, 1.0)
	var k := ShortTimeline.ease_value("out" if reduce_motion else "back", p)
	_caption_box.scale = Vector2.ONE * lerpf(0.9, 1.0, k)
	_caption_box.modulate.a = clampf(p * 3.0, 0.0, 1.0)


## The caption's letters as big as the band under the actors holds (CAPTION_SIZES, biggest first).
func fit_caption() -> void:
	var room := ShortRules.STAGE.y - CAPTION_MARGIN - ShortRules.CAPTION_TOP
	for fs: int in CAPTION_SIZES:
		caption.add_theme_font_size_override("font_size", fs)
		_caption_box.reset_size()
		var box := _caption_box.get_combined_minimum_size()
		if box.y <= room or fs == CAPTION_SIZES[CAPTION_SIZES.size() - 1]:
			_caption_box.size = Vector2(ShortRules.STAGE.x - 2.0 * CAPTION_MARGIN, box.y)
			return


## The whole stage fits the player's box (9:16), in its middle.
func _fit() -> void:
	var s := minf(size.x / ShortRules.STAGE.x, size.y / ShortRules.STAGE.y)
	if s <= 0.0:
		return
	stage.scale = Vector2(s, s)
	stage.position = (size - ShortRules.STAGE * s) * 0.5


## The bars at the top, the PLAY sign while paused and a liked heart's burst: over the Short.
class PlayerOverlay:
	extends Control
	var player: ShortPlayer

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if player == null or player.short.is_empty():
			return
		var scenes := ShortTimeline.scenes(player.short)
		var n := scenes.size()
		var w := ShortRules.STAGE.x - 24.0
		var gap := 4.0
		var seg := (w - gap * (n - 1)) / n
		var where := ShortTimeline.at(player.short, player.time)
		for i in n:
			var r := Rect2(Vector2(12.0 + i * (seg + gap), BAR_TOP), Vector2(seg, BAR_H))
			draw_rect(r, Color(1, 1, 1, 0.35))
			var fill := 1.0 if i < int(where.scene) else (float(where.local) / maxf(ShortTimeline.seconds_of(scenes[i]), 0.01) \
				if i == int(where.scene) else 0.0)
			if fill > 0.0:
				draw_rect(Rect2(r.position, Vector2(r.size.x * fill, r.size.y)), Color.WHITE)
		if not player.playing and not player.hide_play_sign and player.can_play():
			var c := Vector2(ShortRules.STAGE.x * 0.5, ShortRules.STAGE.y * 0.42)
			draw_circle(c, 58.0, Color(0, 0, 0, 0.45))
			draw_arc(c, 58.0, 0.0, TAU, 48, Color(1, 1, 1, 0.9), 5.0, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-18, -28), c + Vector2(30, 0), c + Vector2(-18, 28)]), Color.WHITE)
		if player._burst >= 0.0:
			var p := player._burst / BURST_SECONDS
			var k := ShortTimeline.ease_value("back", minf(p * 2.5, 1.0))
			var c := Vector2(ShortRules.STAGE.x * 0.5, ShortRules.STAGE.y * 0.42 - p * 60.0)
			var r := 70.0 * k
			var pts := PackedVector2Array()
			for i in 41:
				var t := TAU * i / 40.0
				pts.append(c + Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * r / 17.0)
			draw_colored_polygon(pts, Color(0.93, 0.25, 0.35, 1.0 - maxf(p - 0.6, 0.0) / 0.4))
