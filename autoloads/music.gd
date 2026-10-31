extends Node
## Background music (M2 spec §12.10): a calm day loop, a tense night loop and a boss theme on the
## "Music" bus, cross-faded (MusicMix, MusicRules.CROSSFADE) on dusk, dawn and boss fights.
## - The menu calls play_menu(), the world scene follow_sky(its SkyCycle), and the
##   Stone Golem play_boss(true / false) on every peer when its fight starts and ends (Task 10).
## - The settings' music_volume sets the Music bus (on top of the overall volume on Master).
## - A silent track is stopped (no decoding on phones); a track fading in starts from its beginning.
## - It keeps playing in the pause menu. A separate autoload from Audio (short effects), so tasks
##   adding sounds to Audio.SOUNDS never touch the music code.
## The audio pass (owner feedback #31, docs/devlog/parts/audio-pass.md): classical music. The MUSIC
## setting (settings.music_style: game / classical / mix, MusicPlan) chooses what plays; classical pieces
## (MusicPieces) play once each on two piece players that cross-fade like the tracks, loaded on the
## loader thread when they start (a frame or two late). A piece starting shows "Now playing: Mozart —
## Eine kleine Nachtmusik" for NOW_PLAYING_TIME (settings.song_names hides it). Caves (set_underground, from Ambience) have their own mood.
## M7: in a browser the pieces and the universes' loops come in the music pack a little after the start (WebContent);
## until then the three core loops (STREAMS, in the first download) stand in (MusicPlan, use_tracks), and
## on_pack_loaded(PACK) lets a universe's loop play from its next start.

const BUS := &"Music"
const STREAMS := {
	MusicRules.DAY: preload("res://assets/music/day.ogg"),
	MusicRules.NIGHT: preload("res://assets/music/night.ogg"),
	MusicRules.BOSS: preload("res://assets/music/boss.ogg"),
}
const PIECE_PLAYERS := 2
const NOW_PLAYING_TIME := 4.0     # seconds the "Now playing" toast stays (then a 0.5 s fade)
const NOW_PLAYING_LAYER := 80     # over the HUD and the menus, under Feel's flash (90)
## M7: the web build's music pack (its name in packs.json, WebContent).
const PACK := "music"

## A classical piece started (its MusicPieces id).
signal piece_started(id: StringName)
## M7: the music pack came in (a browser; the settings' "More music is on its way…" goes).
signal more_music_arrived

var _mix := MusicMix.new()
var _plan := MusicPlan.new()
var _players := {}                # track -> AudioStreamPlayer
var _gains := {}                  # track -> dB: the universe's loop evened out (M5 Task 2, Loudness)
var _tracks := {}                 # M7: the universe's loops asked for last (use_tracks), asked again when the pack comes
var _later := {}                  # M7: track -> the universe loop's path, loading on the loader thread; taken while
                                  # that track is silent (never cut in the middle)
var _piece_players: Array[AudioStreamPlayer] = []
var _pieces := {}                 # piece id -> the AudioStreamPlayer it plays on
var _requested: Array[String] = []   # piece files asked of the loader thread, not taken yet
var _playing_menu := false
var _sky: WeakRef                 # the world's SkyCycle (anything with a `time` of day 0..1)
var _boss := false
var _underground := false
var _song_names := true
var _toast_layer := CanvasLayer.new()
var _toast := PanelContainer.new()
var _toast_label := Label.new()
var _toast_t := 0.0               # seconds the toast has left


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_add_bus()
	for track: StringName in MusicRules.TRACKS:
		var p := AudioStreamPlayer.new()
		p.name = "Music_%s" % track
		p.stream = STREAMS[track]
		p.bus = BUS
		p.volume_db = MusicMix.SILENT_DB
		add_child(p)
		_players[track] = p
	for i in PIECE_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.name = "Piece_%d" % i
		p.bus = BUS
		p.volume_db = MusicMix.SILENT_DB
		add_child(p)
		_piece_players.append(p)
	_build_toast()
	Game.settings_applied.connect(_apply_volume)
	_apply_volume(Profile.data.settings)


func play_menu() -> void:
	use_tracks({})   # the menu is Green Meadows (M3 Task 5)
	_plan.favourites = []
	_playing_menu = true
	_sky = null
	_boss = false
	_underground = false


## A world's clock: the night music plays from sunset to sunrise.
func follow_sky(sky: Node) -> void:
	_playing_menu = true           # falls back to the menu track if the sky goes away
	_sky = weakref(sky)
	_boss = false


func play_boss(on: bool) -> void:
	_boss = on


## Caves (Ambience, with some hysteresis): the cave mood (the game's Crystal Cave loop, or calm pieces).
func set_underground(on: bool) -> void:
	_underground = on


## The universe's own classical pieces (UniverseRegistry.classical), played first among equals.
## Owner #40's /music next: the next classical piece now (false when this mood plays the game's own music).
func next_piece() -> bool:
	if not _plan.skip():
		return false
	var cue := _plan.cue
	_mix.add(cue)
	_mix.want(cue)
	piece_started.emit(cue)
	_show_now_playing(cue)
	return true


func use_favourites(ids: Array) -> void:
	var list: Array[StringName] = []
	for id: Variant in ids:
		if (id is StringName or id is String) and MusicPieces.has(StringName(id)):
			list.append(StringName(id))
	_plan.favourites = list


func favourites() -> Array[StringName]:
	return _plan.favourites


## The track or piece playing or fading in (&"" = silence).
func current() -> StringName:
	return _mix.wanted


func player(track: StringName) -> AudioStreamPlayer:
	return _players.get(track)


## The player a classical piece plays on while it sounds (null when it doesn't).
func piece_player(id: StringName) -> AudioStreamPlayer:
	return _pieces.get(id)


func piece_player_count() -> int:
	return _piece_players.size()


func now_playing_visible() -> bool:
	return _toast.visible


func now_playing_text() -> String:
	return _toast_label.text if _toast.visible else ""


## Silence at once (tests).
func reset() -> void:
	_playing_menu = false
	_sky = null
	_boss = false
	_underground = false
	_mix = MusicMix.new()
	_plan = MusicPlan.new()
	_plan.set_style(Profile.data.settings.get("music_style", MusicPlan.MIX))
	for track: StringName in _players:
		_players[track].stop()
		_players[track].volume_db = MusicMix.SILENT_DB
	for p in _piece_players:
		p.stop()
		p.stream = null
		p.volume_db = MusicMix.SILENT_DB
	_pieces.clear()
	for path: String in _requested:
		ResourceLoader.load_threaded_get(path)   # waits for it and drops it: nothing is left loading
	_requested.clear()
	_drop_later()   # M7
	_toast_t = 0.0
	_toast.visible = false


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	var changed := _plan.update(_mood(), delta)
	var cue := _plan.cue
	if MusicPieces.has(cue):
		_mix.add(cue)
	_mix.want(cue)
	_mix.advance(delta)
	_update_tracks()
	_update_pieces()
	if changed and MusicPieces.has(cue):
		piece_started.emit(cue)
		_show_now_playing(cue)
	_update_toast(delta)


func _update_tracks() -> void:
	for track: StringName in _players:
		var p: AudioStreamPlayer = _players[track]
		if _mix.is_silent(track) and track != _mix.wanted:
			if p.playing:
				p.stop()
			if _later.has(track):
				_take_later(track)
			continue
		var db := _mix.volume_db(track)
		if db > MusicMix.SILENT_DB:
			db += float(_gains.get(track, 0.0))   # M5 Task 2: every universe's loops as loud as Green Meadows'
		if not is_equal_approx(p.volume_db, db):
			p.volume_db = db
		if not p.playing:
			p.play()


## A piece plays once, from its start, on a player of its own while it sounds; a faded-out piece gives its
## player back (and its stream, so a phone keeps at most two pieces in memory).
func _update_pieces() -> void:
	for id: StringName in _pieces.keys():
		var p: AudioStreamPlayer = _pieces[id]
		if _mix.is_silent(id) and id != _mix.wanted:
			_release(id)
			continue
		var db := _piece_db(id)
		if not is_equal_approx(p.volume_db, db):
			p.volume_db = db
	var cue := _mix.wanted
	_drop_stale_loads(MusicPieces.path(cue))
	if MusicPieces.has(cue) and not _pieces.has(cue):
		var stream := _loaded(MusicPieces.path(cue))
		if stream == null:
			return                     # still loading (a frame or two), or broken (warned)
		var p := _free_piece_player()
		p.stream = stream
		p.volume_db = _piece_db(cue)
		p.play()
		_pieces[cue] = p


## A piece's volume now: its fade, evened out with the loops it takes turns with (M5 Task 2, Loudness).
func _piece_db(id: StringName) -> float:
	var db := _mix.volume_db(id)
	return db + Loudness.piece_gain_db(id) if db > MusicMix.SILENT_DB else db


## A piece's stream once the loader thread has it (null meanwhile): a 1 MB Vorbis file takes 5-20 ms to
## open on this PC, more on a phone, so it never loads on the main thread (the frame budget).
func _loaded(path: String) -> AudioStream:
	if not _requested.has(path):
		if ResourceLoader.load_threaded_request(path, "AudioStream") != OK:
			push_warning("Music: cannot load %s" % path)
			return null
		_requested.append(path)
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return null
	_requested.erase(path)
	var stream := ResourceLoader.load_threaded_get(path) as AudioStream if status == ResourceLoader.THREAD_LOAD_LOADED else null
	if stream == null:
		push_warning("Music: cannot load %s" % path)
	return stream


## Loads asked for a piece that is no longer wanted are taken (and dropped) once finished.
func _drop_stale_loads(keep: String) -> void:
	for path: String in _requested.duplicate():
		if path != keep and ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			ResourceLoader.load_threaded_get(path)
			_requested.erase(path)


func _free_piece_player() -> AudioStreamPlayer:
	for p in _piece_players:
		if not _pieces.values().has(p):
			return p
	var quietest: StringName = _pieces.keys()[0]
	for id: StringName in _pieces:
		if _mix.gain(id) < _mix.gain(quietest):
			quietest = id
	var p: AudioStreamPlayer = _pieces[quietest]
	_release(quietest)
	return p


func _release(id: StringName) -> void:
	var p: AudioStreamPlayer = _pieces[id]
	p.stop()
	p.stream = null
	p.volume_db = MusicMix.SILENT_DB
	_pieces.erase(id)
	_mix.remove(id)


func _mood() -> StringName:
	if _boss:
		return MusicPlan.BOSS
	var sky: Object = _sky.get_ref() if _sky else null
	if sky:
		return MusicPlan.mood_for(float(sky.get("time")), false, _underground)
	return MusicPlan.MENU if _playing_menu else &""


func _apply_volume(settings: Dictionary) -> void:
	var bus := AudioServer.get_bus_index(BUS)
	var v := clampf(float(settings.get("music_volume", 0.6)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(bus, v <= 0.0)
	_plan.set_style(settings.get("music_style", MusicPlan.MIX))
	_song_names = bool(settings.get("song_names", true))
	if not _song_names:
		_toast_t = 0.0
		_toast.visible = false


func _add_bus() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, BUS)
	AudioServer.set_bus_send(i, &"Master")

# --- The "Now playing" toast (the audio pass) -----------------------------------------------------------

## A small dark pill at the bottom centre, just above the hotbar; it never takes a tap and is hidden
## (no drawing at all) when it isn't showing.
func _build_toast() -> void:
	_toast_layer.layer = NOW_PLAYING_LAYER
	UiLayers.route(_toast_layer, self)   # owner #101: in VR on the panel
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.1, 0.17, 0.8)
	box.set_corner_radius_all(16)
	box.set_content_margin_all(8)
	box.content_margin_left = 20
	box.content_margin_right = 20
	_toast.name = "NowPlaying"
	_toast.add_theme_stylebox_override("panel", box)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label.add_theme_font_size_override("font_size", 22)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_child(_toast_label)
	_toast_layer.add_child(_toast)
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_top = -134.0     # above the hotbar (HudLayout: its top is 78 px from the bottom)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.visible = false


func _show_now_playing(id: StringName) -> void:
	if not _song_names:
		return
	_toast_label.text = "Now playing: " + MusicPieces.label(id)
	_toast.modulate.a = 1.0
	_toast.visible = true
	_toast.reset_size()
	_toast_t = NOW_PLAYING_TIME + 0.5


func _update_toast(delta: float) -> void:
	if not _toast.visible:
		return
	_toast_t -= delta
	if _toast_t <= 0.0:
		_toast.visible = false
	elif _toast_t < 0.5:
		_toast.modulate.a = _toast_t / 0.5

# --- M3 Task 5: each universe's music ---------------------------------------------------------------

## A universe's own loops {track: path} (UniverseRegistry.music; tracks MusicRules.DAY, NIGHT, BOSS).
## A track it doesn't name, or whose file can't be loaded, is Green Meadows' ({} = all of them). A
## playing track whose loop changes starts the new one.
func use_tracks(tracks: Dictionary) -> void:
	_tracks = tracks
	_drop_later()
	for track: StringName in MusicRules.TRACKS:
		var chosen := _track_stream(tracks, track)
		var stream: AudioStream = chosen[0]
		_gains[track] = chosen[1]
		var p: AudioStreamPlayer = _players[track]
		if p.stream != stream:
			var was_playing := p.playing
			p.stream = stream
			if was_playing:
				p.play()


## [stream, dB] for `track`: the universe's loop when its file is in the game (M7: in a browser it may come later in
## the music pack), else Green Meadows'.
func _track_stream(tracks: Dictionary, track: StringName) -> Array:
	var path: Variant = tracks.get(String(track), tracks.get(track))
	if path is String and MusicPieces.file_present(path):
		var loaded := load(path) as AudioStream
		if loaded != null:
			return [loaded, Loudness.music_gain_db(path)]
	return [STREAMS[track], 0.0]

# --- M7: the web build's music pack (WebContent) ------------------------------------------------------------

## A resource pack came in (WebContent.pack_loaded). The music pack: the universe's loops that were missing load on the
## loader thread (a 1 MB loop takes 5-20 ms here, more on a phone: never in a frame) and play from their next start (a
## silent one as soon as it is loaded, a playing one when it has faded out: never cut); MusicPlan picks pieces from the
## next change of music on.
func on_pack_loaded(pack_name: String) -> void:
	if pack_name != PACK:
		return
	for track: StringName in MusicRules.TRACKS:
		var path: Variant = _tracks.get(String(track), _tracks.get(track))
		var p: AudioStreamPlayer = _players[track]
		if _later.has(track) or not path is String or not MusicPieces.file_present(path) \
				or (p.stream != null and p.stream.resource_path == path):
			continue
		if ResourceLoader.load_threaded_request(path, "AudioStream") == OK:
			_later[track] = path
	more_music_arrived.emit()


## In a browser before the music pack is in: some pieces are not here yet (the settings say more is coming).
func more_music_coming() -> bool:
	return not MusicPieces.all_present()


## A silent track takes its universe loop once the loader thread has it.
func _take_later(track: StringName) -> void:
	var path: String = _later[track]
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	_later.erase(track)
	var stream := ResourceLoader.load_threaded_get(path) as AudioStream if status == ResourceLoader.THREAD_LOAD_LOADED else null
	if stream == null:
		push_warning("Music: cannot load %s" % path)
		return
	_players[track].stream = stream
	_gains[track] = Loudness.music_gain_db(path)


## Loads still asked of the loader thread are taken and dropped (waits for them: nothing is left loading).
func _drop_later() -> void:
	for path: String in _later.values():
		ResourceLoader.load_threaded_get(path)
	_later.clear()
