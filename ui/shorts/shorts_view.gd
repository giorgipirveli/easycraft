class_name ShortsView
extends Control
## EasyCraft Shorts in the Theater (owner #94, spec §5.12b): the SHORTS tab's view, 780 × 512 in the design space
## under the tabs.
##
##   SHOWS LESSONS LIKED   |  the Short, 9:16  |  its topic (its colour), its title, "3 of 40"
##   (grades 3-7)          |  (swipe up and    |  LIKE (a heart: the child's own list)
##   the feed's list: its  |   down: it snaps  |  LEARN IT (what it teaches)
##   Shorts, seen ones     |   to the next or  |  BACK  NEXT
##   ticked, this one      |   the last one)   |  VOICE
##   framed               |                   |  EXIT
##   Grown-ups             |                   |
##
## A finger drags the Shorts up and down and lets go: past a sixth of the screen (or a flick) the next one snaps in
## with a little overshoot, else it springs back; the mouse wheel, ↑ / ↓ (the panel's keys) and a controller's D-pad
## do the same. A tap plays and pauses, a double tap gives a heart (it grows over the Short). The Short that snaps in
## plays from its start and loops; walking in shows the first one still (nothing starts by itself). A Short counts
## as seen at half-way. After BREAK_AFTER Shorts, "That's the show for now!" offers two equal choices (a natural
## stopping point). No gold, points or streaks for watching; only our own Shorts. The game's music rests while a Short
## plays (its own voice and sounds play). The next and the last Short are built in later frames, one at a time.
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): a fourth filter, MY SHORTS (the child's own, on this device), with a
## big MAKE A SHORT button that opens the maker (MyShortMakerView) over the view; a Short of one's own plays in the same
## player with its heart and LEARN IT where it fits, and CHANGE or DELETE (tapped twice: SURE?) under the list.

signal learn_requested(link: Dictionary)
signal exit_requested
signal grown_ups_requested
signal layout_changed

const SIZE := Vector2(780, 512)
const PLAYER_SIZE := Vector2(288, 512)
const GAP := 12.0
const SIDE_W := 234.0
const PLAYER_X := 246.0
const RIGHT_X := 546.0
const SNAP_SECONDS := 0.34
const SNAP_OVERSHOOT := 0.9       # a gentler "back" than a pop's
const SWIPE_FRACTION := 1.0 / 6.0
const FLICK_SPEED := 800.0        # design px a second
const TAP_MOVE := 14.0
const DOUBLE_TAP_MSEC := 320
const BUMP := 36.0                # the end of the feed: a little spring
const THUMP := 0.24
const BREAK_AFTER := 10
const SEEN_AT := 0.5
const ROW_H := 52.0
const ROW_GAP := 4.0
const LIST_BOTTOM := 462.0
const PINK := Color("d9437a")
const MUSIC_BUS := &"Music"

const EMPTY_LIKED := "Tap the heart on a Short you like: it waits for you here."
const EMPTY_MINE := "Make your very own Short: your photos, your words, your music! It stays on this device."
const MAKE_WORDS := "MAKE A SHORT"
const SURE_MSEC := 4000
const MINE_LIST_TOP := 150.0
const MINE_LIST_BOTTOM := 410.0
const BREAK_WORDS := "That's the show for now!"
const BACK_TO_WORLD := "BACK TO MY WORLD"
const MORE_SHORTS := "MORE SHORTS"

var profile: ProfileData
var save_profile := Callable()
var clock := Callable()            # () -> int, unix seconds (tests); default the system's
var reduce_motion := false
var voice_on := true
var filter: StringName = ShortFeed.HAND
var grade := 3
var feed: Array = []
var index := 0
## Shorts shown by a move since the view opened (or since MORE SHORTS): the break card comes after BREAK_AFTER.
var shown := 0
var on_break := false

var window := ShortsWindow.new()
var title_label := Label.new()
var topic_label := Label.new()
var position_label := Label.new()
var empty_label := Label.new()
var like_button: Button
var learn_button: Button
var back_button: Button
var next_button: Button
var voice_button: Button
var exit_button: Button
var grownups_button: Button
var filter_buttons := {}
var grade_buttons: Array[Button] = []
var rows: Array[FeedRow] = []
var break_card := PanelContainer.new()
var break_buttons: Array[Button] = []
## MAKE MY SHORT: the maker over the view, its buttons (in the list's column, and big in the player while MY SHORTS is
## empty), CHANGE and DELETE for the child's own Short on the screen.
var maker := MyShortMakerView.new()
var make_button: Button
var make_big: Button
var change_button: Button
var delete_button: Button
var _sure_until := -1

var _players: Array[ShortPlayer] = []
var _offset := 0.0
var _snap := {}
var _press := {}
var _last_tap := -100000
var _thump := -1.0
var _list_top := 0
var _music_held := false
var _music_was_muted := false
var _covered_playing := false
var _opened := false


func _init() -> void:
	name = "ShortsView"
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.view = self
	window.position = Vector2(PLAYER_X, 0)
	window.size = PLAYER_SIZE
	window.set_meta(&"pad_first", true)
	add_child(window)
	for k in 3:
		var p := ShortPlayer.new()
		p.size = PLAYER_SIZE
		p.set_meta(&"feed_index", -2)
		window.add_child(p)
		_players.append(p)
	empty_label.text = EMPTY_LIKED
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.add_theme_font_size_override("font_size", 24)
	empty_label.position = Vector2(20, 0)
	empty_label.size = Vector2(PLAYER_SIZE.x - 40, PLAYER_SIZE.y)
	empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_label.visible = false
	window.add_child(empty_label)
	_build_break_card()
	_build_right()
	_build_left()
	_build_mine()
	set_process(false)


# --- Opening, leaving, the feed ------------------------------------------------------------------------------------

## Shows the feed (built the first time; afterwards where the child left it). Nothing plays until picked.
func open() -> void:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = Profile.save
	reduce_motion = bool(profile.settings.get("reduce_motion", false))
	shown = 0
	on_break = false
	break_card.visible = false
	ReelPack.wanted = true   # owner #96: the reels' videos may come now (an iPhone waits for this)
	Scene3DModels.warm()   # owner #96: the live reels' maps and pictures start on worker threads (not in a Short's frame)
	StarMap.body(&"sun")   # the planets' colours: the class loads here, not in the frame a Short is built (~0.3 s cold)
	ReadAloud.available()   # the voice service answers here once (its first answer took ~0.5 s on a Linux desktop)
	if not _opened:
		_opened = true
		var g := profile.school.grade   # the School's grade (grade 8: the last with lessons in a minute)
		grade = clampi(g, ShortFeed.GRADES[0], ShortFeed.GRADES[ShortFeed.GRADES.size() - 1]) if g > 0 else ShortFeed.GRADES[0]
		set_filter(filter)
	else:
		_refresh()
	set_process(true)


## Leaves (the tab changes, EXIT, walking out): the Short stops, its voice too, and the game's music comes back.
func leave() -> void:
	if maker.is_open():   # MAKE MY SHORT: walking out leaves the Short being made unsaved
		maker.close()
	for p in _players:
		p.pause()
	_snap = {}
	_press = {}
	_hold_music(false)
	set_process(false)


## A menu over the screen pauses the Short; it goes on when the menu closes.
func set_covered(covered: bool) -> void:
	if maker.is_open():
		maker.preview.pause()
		return
	if covered:
		_covered_playing = player().playing
		player().pause()
	elif _covered_playing:
		_covered_playing = false
		player().play()
	_hold_music(player().playing)


func set_filter(f: StringName) -> void:
	filter = f if ShortFeed.FILTERS.has(f) else ShortFeed.HAND
	feed = ShortFeed.build(filter, grade, profile.shorts, profile.my_shorts)
	_jump(ShortFeed.start_index(feed), false)
	layout_changed.emit()


func set_grade(g: int) -> void:
	grade = g
	if filter == ShortFeed.LESSONS:
		set_filter(ShortFeed.LESSONS)
	else:
		_refresh()


func current_entry() -> Dictionary:
	return feed[index] if index >= 0 and index < feed.size() else {}


## The Short on the screen.
func player() -> ShortPlayer:
	return _players[1]


# --- Moving through the feed -------------------------------------------------------------------------------------

## One Short on (+1: the next comes up) or back (-1), with the snap. False at the ends (a little spring), on the break
## card, or while a snap is still moving.
func step(dir: int) -> bool:
	if on_break or not _snap.is_empty() or feed.is_empty() or dir == 0:
		return false
	var to := index + signi(dir)
	if to < 0 or to >= feed.size():
		_offset = -signi(dir) * BUMP
		_start_snap(0, index)
		return false
	if shown >= BREAK_AFTER:
		_show_break()
		return false
	_move_to(to)
	return true


## A row of the list: that Short snaps in (the one on the screen: play or pause).
func go_to(i: int) -> void:
	if i == index:
		toggle_play()
		return
	if on_break or not _snap.is_empty() or i < 0 or i >= feed.size():
		return
	if shown >= BREAK_AFTER:
		_show_break()
		return
	_move_to(i)


func toggle_play() -> void:
	if on_break or feed.is_empty():
		return
	player().toggle()
	_hold_music(player().playing)


## The heart: on or off; kept in the profile at once. Returns whether it is on.
func toggle_like() -> bool:
	var e := current_entry()
	if e.is_empty():
		return false
	var on := profile.shorts.toggle_like(str(e.id), _now())
	save_profile.call()
	if on:
		player().burst_heart()
		Audio.play(&"pop")
	_refresh()
	return on


## LEARN IT: what this Short teaches (the School's unit, the Mission Board, the Star Map).
func learn() -> void:
	var e := current_entry()
	if e.is_empty() or not (e.get("link") is Dictionary) or (e.link as Dictionary).is_empty():
		return
	player().pause()
	_hold_music(false)
	learn_requested.emit(e.link)


func toggle_voice() -> void:
	voice_on = not voice_on
	for p in _players:
		if not voice_on:
			p.stop_voice()
		p.voice_on = voice_on
	_refresh()


func _move_to(i: int) -> void:
	var dir := signi(i - index)
	var slot := 2 if dir > 0 else 0
	_ensure(slot, i)
	Audio.play(&"whoosh", Vector3.INF, -10.0)
	_start_snap(dir, i)


func _start_snap(dir: int, to_index: int) -> void:
	_snap = {"from": _offset, "to": -dir * (PLAYER_SIZE.y + GAP), "t": 0.0, "dir": dir, "index": to_index}
	set_process(true)


## A snap ended on the next (or the last) Short: the ring of players turns and it plays from its start.
func _arrive(dir: int, to_index: int) -> void:
	player().pause()
	if dir > 0:
		_players = [_players[1], _players[2], _players[0]]
	else:
		_players = [_players[2], _players[0], _players[1]]
	index = to_index
	_offset = 0.0
	shown += 1
	_layout_players()
	_after_arrive(true)


## Straight to Short `i` (a filter, the start): built now, its poster shown (play: it plays).
func _jump(i: int, play: bool) -> void:
	for p in _players:
		p.pause()
	index = clampi(i, 0, maxi(feed.size() - 1, 0))
	_offset = 0.0
	_snap = {}
	empty_label.visible = feed.is_empty()
	if feed.is_empty():
		for p in _players:
			p.visible = false
			p.set_meta(&"feed_index", -2)
		_refresh()
		return
	_ensure(1, index)
	_layout_players()
	_after_arrive(play)


func _after_arrive(play: bool) -> void:
	for p in _players:
		p.reduce_motion = reduce_motion
		p.voice_on = voice_on
	if play:
		player().play(true)
		_thump = 0.0
	_hold_music(player().playing)
	_list_top = clampi(index - 2, 0, maxi(0, feed.size() - rows.size()))
	_refresh()
	set_process(true)


## Slot k (0 above, 1 on the screen, 2 below) shows feed entry i: built now if it does not yet.
func _ensure(k: int, i: int) -> void:
	var p := _players[k]
	var want := i if i >= 0 and i < feed.size() else -1
	if int(p.get_meta(&"feed_index", -2)) == want:
		return
	p.set_meta(&"feed_index", want)
	p.reduce_motion = reduce_motion
	p.voice_on = voice_on
	if want < 0:
		p.build({})
	else:
		p.build(ShortFeed.short_of(feed[want]))   # MAKE MY SHORT: a child's own is made from its recipe


func _layout_players() -> void:
	for k in 3:
		var p := _players[k]
		var y := _offset + (k - 1) * (PLAYER_SIZE.y + GAP)
		p.position = Vector2(0, y)
		p.visible = int(p.get_meta(&"feed_index", -2)) >= 0 and absf(y) < PLAYER_SIZE.y + GAP


func _process(delta: float) -> void:
	if not _snap.is_empty():
		_snap.t = float(_snap.t) + delta
		var p := clampf(float(_snap.t) / SNAP_SECONDS, 0.0, 1.0)
		_offset = lerpf(float(_snap.from), float(_snap.to), _snap_ease(p))
		_layout_players()
		if p >= 1.0:
			var dir := int(_snap.dir)
			var to_index := int(_snap.index)
			_snap = {}
			if dir != 0:
				_arrive(dir, to_index)
			else:
				_offset = 0.0
				_layout_players()
	if _thump >= 0.0:
		_thump += delta
		var k := clampf(_thump / THUMP, 0.0, 1.0)
		var s := 1.0 if reduce_motion else lerpf(0.95, 1.0, ShortTimeline.ease_value("back", k))
		player().pivot_offset = PLAYER_SIZE * 0.5
		player().scale = Vector2(s, s)
		if k >= 1.0:
			_thump = -1.0
	_mark_seen()
	if _sure_until >= 0 and _msec() > _sure_until:   # DELETE's SURE? waits a few seconds, then is DELETE again
		_sure_until = -1
		delete_button.text = "DELETE"
	if _snap.is_empty() and _press.is_empty():   # the neighbours, one a frame
		if int(_players[2].get_meta(&"feed_index", -2)) != _want(index + 1):
			_ensure(2, index + 1)
			_layout_players()
		elif int(_players[0].get_meta(&"feed_index", -2)) != _want(index - 1):
			_ensure(0, index - 1)
			_layout_players()
	_hold_music(player().playing and is_visible_in_tree())


func _want(i: int) -> int:
	return i if i >= 0 and i < feed.size() else -1


func _snap_ease(p: float) -> float:
	if reduce_motion:
		return ShortTimeline.ease_value("out", p)
	var c := SNAP_OVERSHOOT
	return 1.0 + (c + 1.0) * pow(p - 1.0, 3.0) + c * pow(p - 1.0, 2.0)


## Half-way through a Short (or once it looped) it is seen: ticked in the list, kept in the profile.
func _mark_seen() -> void:
	var e := current_entry()
	var p := player()
	if e.is_empty() or bool(e.get("seen", false)) or not p.is_built():
		return
	if p.passes > 0 or (p.time >= p.length() * SEEN_AT and p.playing):
		e.seen = true
		profile.shorts.mark_seen(str(e.id))
		save_profile.call()
		_refresh_rows()


# --- Touch, mouse and the pad on the Short ------------------------------------------------------------------------

func _window_input(event: InputEvent) -> void:
	if on_break or feed.is_empty():
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		step(-1 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
		window.accept_event()
		return
	var touch := event as InputEventScreenTouch
	if touch and touch.index == 0:
		if touch.pressed:
			if not _snap.is_empty():
				return
			_press = {"pos": touch.position, "msec": _msec(), "dragging": false, "last": touch.position, "last_msec": _msec(),
				"speed": 0.0}
		elif not _press.is_empty():
			_release()
		window.accept_event()
		return
	var drag := event as InputEventScreenDrag
	if drag and drag.index == 0 and not _press.is_empty():
		var dy := drag.position.y - Vector2(_press.pos).y
		if not bool(_press.dragging) and absf(dy) > TAP_MOVE:
			_press.dragging = true
			_ensure(0, index - 1)
			_ensure(2, index + 1)
		if bool(_press.dragging):
			var end := (dy > 0.0 and index == 0) or (dy < 0.0 and index == feed.size() - 1)
			_offset = dy * (0.3 if end else 1.0)
			var now := _msec()
			var dt := maxf((now - int(_press.last_msec)) / 1000.0, 0.001)
			_press.speed = (drag.position.y - Vector2(_press.last).y) / dt
			_press.last = drag.position
			_press.last_msec = now
			_layout_players()
		window.accept_event()


func _release() -> void:
	var press := _press
	_press = {}
	if bool(press.dragging):
		var h := PLAYER_SIZE.y
		var dir := 0
		if _offset < -h * SWIPE_FRACTION or float(press.speed) < -FLICK_SPEED:
			dir = 1
		elif _offset > h * SWIPE_FRACTION or float(press.speed) > FLICK_SPEED:
			dir = -1
		var to := index + dir
		if dir != 0 and to >= 0 and to < feed.size():
			if shown >= BREAK_AFTER:
				_start_snap(0, index)
				_show_break()
				return
			Audio.play(&"whoosh", Vector3.INF, -10.0)
			_start_snap(dir, to)
		else:
			_start_snap(0, index)
		return
	var now := _msec()
	if now - _last_tap <= DOUBLE_TAP_MSEC:
		_last_tap = -100000
		toggle_play()   # the first tap's pause or play, undone
		if not profile.shorts.is_liked(str(current_entry().get("id", ""))):
			toggle_like()
		else:
			player().burst_heart()
		return
	_last_tap = now
	toggle_play()


## A controller's D-pad on the Short: up and down move through the feed; Cross / A plays and pauses.
func pad_move(dir: Vector2i) -> bool:
	if dir.y == 0:
		return false
	step(dir.y)
	return true


func pad_press() -> bool:
	toggle_play()
	return true


# --- The break card --------------------------------------------------------------------------------------------------

func _show_break() -> void:
	on_break = true
	player().pause()
	_hold_music(false)
	break_card.visible = true
	_refresh()


func _on_break_choice(more: bool) -> void:
	on_break = false
	break_card.visible = false
	if more:
		shown = 0
		step(1)
	else:
		exit_requested.emit()


# --- The words and buttons ----------------------------------------------------------------------------------------

func _refresh() -> void:
	var e := current_entry()
	var has := not e.is_empty()
	var topic := str(e.get("topic", ""))
	var colour := ShortRules.topic_colour(topic) if has else PINK
	title_label.text = str(e.get("title", "")) if has else ("Liked Shorts" if filter == ShortFeed.LIKED else "")
	var words := ShortRules.topic_title(topic) if has else ""
	if has and str(e.get("kind", "")) == str(ShortFeed.LESSON):
		words += " · Grade %d" % int(e.get("grade", grade))
	topic_label.text = words
	topic_label.visible = has
	(topic_label.get_theme_stylebox("normal") as StyleBoxFlat).bg_color = colour
	position_label.text = "%d of %d" % [index + 1, feed.size()] if has else "0 of 0"
	var liked := has and profile.shorts.is_liked(str(e.id))
	like_button.text = "LIKED" if liked else "LIKE"
	(like_button.get_node("Icon") as ShortsIcon).set_shape(&"heart_full" if liked else &"heart")
	like_button.disabled = not has or on_break
	learn_button.disabled = not has or on_break or not (e.get("link") is Dictionary) or (e.link as Dictionary).is_empty()
	back_button.disabled = not has or on_break or index <= 0
	next_button.disabled = not has or on_break or index >= feed.size() - 1
	voice_button.text = "VOICE ON" if voice_on else "VOICE OFF"
	(voice_button.get_node("Icon") as ShortsIcon).set_shape(&"speaker" if voice_on else &"speaker_off")
	for f: StringName in filter_buttons:
		(filter_buttons[f] as Button).button_pressed = f == filter
	for i in grade_buttons.size():
		grade_buttons[i].visible = filter == ShortFeed.LESSONS
		grade_buttons[i].button_pressed = ShortFeed.GRADES[i] == grade
	_refresh_mine(e)
	_refresh_rows()
	queue_redraw()


func _refresh_rows() -> void:
	var top := 92.0 + (46.0 if filter == ShortFeed.LESSONS else 0.0)
	var bottom := LIST_BOTTOM
	if filter == ShortFeed.MINE:   # MAKE A SHORT above the list, CHANGE and DELETE under it
		top = MINE_LIST_TOP
		bottom = MINE_LIST_BOTTOM
	var room := int((bottom - top + ROW_GAP) / (ROW_H + ROW_GAP))
	_list_top = clampi(_list_top, 0, maxi(0, feed.size() - room))
	for r in rows.size():
		var row := rows[r]
		var k := _list_top + r
		row.visible = r < room and k < feed.size()
		row.position = Vector2(0, top + r * (ROW_H + ROW_GAP))
		if row.visible:
			var e: Dictionary = feed[k]
			row.show_entry(e, k == index)


## The frame round the Short, in its topic's colour.
func _draw() -> void:
	var colour := ShortRules.topic_colour(str(current_entry().get("topic", ""))) if not feed.is_empty() else PINK
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	box.border_color = colour
	box.set_border_width_all(6)
	box.set_corner_radius_all(16)
	draw_style_box(box, Rect2(Vector2(PLAYER_X - 6, -6), PLAYER_SIZE + Vector2(12, 12)))


# --- Building -------------------------------------------------------------------------------------------------------

func _build_right() -> void:
	var x := RIGHT_X
	topic_label.position = Vector2(x, 0)
	topic_label.size = Vector2(SIDE_W, 30)
	topic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topic_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	topic_label.add_theme_font_size_override("font_size", 17)
	topic_label.add_theme_constant_override("outline_size", 0)
	var pill := StyleBoxFlat.new()
	pill.bg_color = PINK
	pill.set_corner_radius_all(15)
	topic_label.add_theme_stylebox_override("normal", pill)
	topic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(topic_label)
	title_label.position = Vector2(x, 36)
	title_label.size = Vector2(SIDE_W, 62)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.max_lines_visible = 2
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_label)
	position_label.position = Vector2(x, 100)
	position_label.size = Vector2(SIDE_W, 24)
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position_label.add_theme_font_size_override("font_size", 18)
	position_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	position_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(position_label)
	like_button = _button("LIKE", &"heart", PINK, Rect2(x, 132, SIDE_W, 76), 26)
	like_button.name = "Like"
	like_button.pressed.connect(func() -> void: toggle_like())
	learn_button = _button("LEARN IT", &"bulb", UiKit.GREEN, Rect2(x, 216, SIDE_W, 76), 26)
	learn_button.name = "LearnIt"
	learn_button.pressed.connect(learn)
	back_button = _button("BACK", &"up", UiKit.BLUE, Rect2(x, 300, 111, 76), 19)
	back_button.name = "Back"
	back_button.set_meta(&"pad_skip", false)
	back_button.pressed.connect(func() -> void: step(-1))
	next_button = _button("NEXT", &"down", UiKit.BLUE, Rect2(x + 123, 300, 111, 76), 19)
	next_button.name = "Next"
	next_button.pressed.connect(func() -> void: step(1))
	voice_button = _button("VOICE ON", &"speaker", Color(0.16, 0.2, 0.32, 0.95), Rect2(x, 384, SIDE_W, 40), 17)
	voice_button.name = "Voice"
	voice_button.pressed.connect(toggle_voice)
	exit_button = _button("EXIT", &"cross", UiKit.RED, Rect2(x, 432, SIDE_W, 80), 26)
	exit_button.name = "Exit"
	exit_button.set_meta(&"pad_back", true)
	exit_button.pressed.connect(func() -> void: exit_requested.emit())


func _build_left() -> void:
	var words := {ShortFeed.HAND: ["SHOWS", &"star"], ShortFeed.LESSONS: ["LESSONS", &"book"], ShortFeed.LIKED: ["LIKED", &"heart_full"],
		ShortFeed.MINE: ["MY SHORTS", &"person"]}
	for i in ShortFeed.FILTERS.size():   # MAKE MY SHORT: four filters, two by two, each a picture beside its word
		var f: StringName = ShortFeed.FILTERS[i]
		var b := _filter_chip(str(words[f][0]), words[f][1], Rect2((i % 2) * 120.0, (i / 2) * 44.0, 114, 40))
		b.name = "Filter_" + String(f)
		b.pressed.connect(func() -> void: set_filter(f))
		filter_buttons[f] = b
	for i in ShortFeed.GRADES.size():
		var g: int = ShortFeed.GRADES[i]
		var b := _chip(str(g), &"", Rect2(i * 48.0, 92, 42, 40))
		b.name = "Grade_%d" % g
		b.pressed.connect(func() -> void: set_grade(g))
		b.add_theme_font_size_override("font_size", 22)
		grade_buttons.append(b)
	for r in 8:
		var row := FeedRow.new(Vector2(SIDE_W, ROW_H))
		row.pressed.connect(func() -> void: go_to(_list_top + r))
		row.gui_input.connect(_list_input)
		add_child(row)
		rows.append(row)
	grownups_button = _button("Grown-ups", &"gear", Color(0.16, 0.2, 0.32, 0.95), Rect2(0, 472, SIDE_W, 40), 17)
	grownups_button.name = "GrownUps"
	grownups_button.pressed.connect(func() -> void: grown_ups_requested.emit())


## The mouse wheel over the list scrolls it (the Short on the screen stays).
func _list_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_list_top += -1 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1
		_refresh_rows()


func _build_break_card() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.05, 0.1, 0.96)
	box.set_corner_radius_all(16)
	box.set_content_margin_all(14)
	break_card.add_theme_stylebox_override("panel", box)
	break_card.position = Vector2.ZERO
	break_card.size = PLAYER_SIZE
	break_card.visible = false
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	break_card.add_child(col)
	var star := ShortsIcon.new(&"star", 70.0, Color("ffd23f"))
	star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(star)
	var words := Label.new()
	words.text = BREAK_WORDS
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.custom_minimum_size.x = PLAYER_SIZE.x - 40
	words.add_theme_font_size_override("font_size", 28)
	col.add_child(words)
	for choice: Array in [[BACK_TO_WORLD, false], [MORE_SHORTS, true]]:
		var b := UiKit.big_button(str(choice[0]), Color(0.16, 0.2, 0.32, 0.95), Vector2(PLAYER_SIZE.x - 40, 72))
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_on_break_choice.bind(bool(choice[1])))
		col.add_child(b)
		break_buttons.append(b)
	window.add_child(break_card)


## An icon-first button with its word underneath or beside (spec §5.15), placed in the view.
func _button(text: String, icon: StringName, colour: Color, r: Rect2, font: int) -> Button:
	var b := UiKit.big_button(text, colour, r.size)
	for state: String in ["normal", "hover", "pressed"]:
		var c := colour.lightened(0.12) if state == "hover" else (colour.darkened(0.15) if state == "pressed" else colour)
		b.add_theme_stylebox_override(state, UiKit.box(c, 16, 6))
	b.add_theme_stylebox_override("disabled", UiKit.box(Color(0.22, 0.22, 0.26, 0.75), 16, 6))
	b.add_theme_font_size_override("font_size", font)
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	var side := minf(r.size.y * 0.55, 40.0 if r.size.x > 150.0 else 30.0)
	var pic := ShortsIcon.new(icon, side)
	pic.name = "Icon"
	pic.position = Vector2(10 if r.size.x > 150.0 else 8, (r.size.y - side) * 0.5)
	pic.size = Vector2(side, side)
	b.add_child(pic)
	if r.size.x <= 150.0:   # a narrow button: the picture on the left, the word on the right
		b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			(b.get_theme_stylebox(state) as StyleBoxFlat).content_margin_right = 10
	add_child(b)
	return b


## MAKE MY SHORT: a filter's chip, its picture beside its word (four fit the list's column).
func _filter_chip(text: String, icon: StringName, r: Rect2) -> Button:
	var b := _chip(text, &"", r)
	b.add_theme_font_size_override("font_size", 13)
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		(b.get_theme_stylebox(state) as StyleBoxFlat).content_margin_right = 8
	var pic := ShortsIcon.new(icon, 20.0)
	pic.position = Vector2(8, (r.size.y - 20.0) * 0.5)
	pic.size = Vector2(20, 20)
	b.add_child(pic)
	return b


# --- MAKE MY SHORT -------------------------------------------------------------------------------------------------------

func _build_mine() -> void:
	make_button = _button(MAKE_WORDS, &"plus", PINK, Rect2(0, 92, SIDE_W, 52), 20)
	make_button.name = "MakeShort"
	make_button.pressed.connect(func() -> void: open_maker())
	change_button = _button("CHANGE", &"pencil", UiKit.BLUE, Rect2(0, 418, 111, 46), 16)
	change_button.name = "ChangeShort"
	change_button.pressed.connect(func() -> void: open_maker(str(current_entry().get("id", ""))))
	delete_button = _button("DELETE", &"bin", UiKit.RED, Rect2(123, 418, 111, 46), 16)
	delete_button.name = "DeleteShort"
	delete_button.pressed.connect(delete_mine)
	make_big = UiKit.big_button(MAKE_WORDS, PINK, Vector2(PLAYER_SIZE.x - 48, 84))
	make_big.name = "MakeShortBig"
	make_big.add_theme_font_size_override("font_size", 24)
	make_big.focus_mode = Control.FOCUS_NONE
	make_big.position = Vector2(24, 330)
	make_big.size = Vector2(PLAYER_SIZE.x - 48, 84)
	make_big.visible = false
	make_big.pressed.connect(func() -> void: open_maker())
	window.add_child(make_big)
	maker.saved.connect(_on_made)
	maker.closed.connect(_on_maker_closed)
	add_child(maker)


func _refresh_mine(e: Dictionary) -> void:
	var mine := filter == ShortFeed.MINE
	var own := mine and str(e.get("kind", "")) == str(ShortFeed.MINE)
	make_button.visible = mine
	change_button.visible = mine and not feed.is_empty()
	delete_button.visible = mine and not feed.is_empty()
	change_button.disabled = not own or on_break
	delete_button.disabled = not own or on_break
	if _sure_until < 0:
		delete_button.text = "DELETE"
	make_big.visible = mine and feed.is_empty()
	empty_label.text = EMPTY_MINE if mine else EMPTY_LIKED
	if mine:
		empty_label.position = Vector2(20, 40)
		empty_label.size = Vector2(PLAYER_SIZE.x - 40, 270)
	else:
		empty_label.position = Vector2(20, 0)
		empty_label.size = Vector2(PLAYER_SIZE.x - 40, PLAYER_SIZE.y)


## The maker over the view: a new Short, or `id`'s to change (the feed rests meanwhile).
func open_maker(id: String = "") -> void:
	if maker.is_open():
		return
	for p in _players:
		p.pause()
	_snap = {}
	_press = {}
	_hold_music(false)
	for c in get_children():
		if c != maker:
			c.set_meta(&"before_maker", c.visible)
			c.visible = false
	maker.profile = profile
	maker.save_profile = save_profile
	maker.clock = clock
	maker.open(id)
	PadFocus.take(maker)   # a controller's focus goes into the maker (the feed under it rests); back here when it closes
	layout_changed.emit()


func is_making() -> bool:
	return maker.is_open()


## Android Back, Esc, Circle / B while making: a step back (the first step closes the maker). False when not making.
func back_if_making() -> bool:
	return maker.back() if maker.is_open() else false


func _on_maker_closed() -> void:
	for c in get_children():
		if c != maker and c.has_meta(&"before_maker"):
			c.visible = bool(c.get_meta(&"before_maker"))
			c.remove_meta(&"before_maker")
	_refresh()
	layout_changed.emit()


## A Short was kept: MY SHORTS shows it, playing.
func _on_made(id: String) -> void:
	filter = ShortFeed.MINE
	feed = ShortFeed.build(filter, grade, profile.shorts, profile.my_shorts)
	var at := 0
	for i in feed.size():
		if str(feed[i].id) == id:
			at = i
	for p in _players:
		p.set_meta(&"feed_index", -2)   # a changed Short is made again
	_jump(at, true)
	layout_changed.emit()


## DELETE, then SURE? within a few seconds: the child's own Short goes (its heart and seen mark too; the album keeps
## only what the others show).
func delete_mine() -> void:
	var e := current_entry()
	if str(e.get("kind", "")) != str(ShortFeed.MINE):
		return
	if _sure_until < 0 or _msec() > _sure_until:
		_sure_until = _msec() + SURE_MSEC
		delete_button.text = "SURE?"
		return
	_sure_until = -1
	var id := str(e.id)
	player().pause()
	profile.my_shorts.remove(id)
	profile.shorts.forget(id)
	save_profile.call()
	MyShortAlbum.tidy(profile.my_shorts.files())
	for p in _players:
		p.set_meta(&"feed_index", -2)
	set_filter(ShortFeed.MINE)


## A filter's or a grade's chip: a picture over its word (a toggle; the chosen one is lit).
func _chip(text: String, icon: StringName, r: Rect2) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	b.custom_minimum_size = r.size
	b.add_theme_stylebox_override("normal", UiKit.box(Color(0.16, 0.2, 0.32, 0.95), 12, 4))
	b.add_theme_stylebox_override("hover", UiKit.box(Color(0.22, 0.28, 0.44, 0.97), 12, 4))
	var lit := UiKit.box(PINK, 12, 4)
	lit.border_color = Color("ffd23f")
	lit.set_border_width_all(3)
	b.add_theme_stylebox_override("pressed", lit)
	b.add_theme_stylebox_override("hover_pressed", lit)
	if icon != &"":
		b.text = "\n\n" + text
		b.add_theme_font_size_override("font_size", 13)
		var pic := ShortsIcon.new(icon, 28.0)
		pic.position = Vector2((r.size.x - 28.0) * 0.5, 6)
		pic.size = Vector2(28, 28)
		b.add_child(pic)
	else:
		b.text = text
	add_child(b)
	return b


func _hold_music(on: bool) -> void:
	if on == _music_held:
		return
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus < 0:
		return
	_music_held = on
	if on:
		_music_was_muted = AudioServer.is_bus_mute(bus)
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, _music_was_muted)


func is_holding_music() -> bool:
	return _music_held


func _exit_tree() -> void:
	_hold_music(false)


func _now() -> int:
	return int(clock.call()) if clock.is_valid() else int(Time.get_unix_time_from_system())


func _msec() -> int:
	return Time.get_ticks_msec()


## The Short's window: it takes the finger, the mouse wheel and the controller's D-pad for the view.
class ShortsWindow:
	extends Control
	var view: ShortsView

	func _init() -> void:
		name = "ShortsWindow"
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE

	func _gui_input(event: InputEvent) -> void:
		if view:
			view._window_input(event)

	func pad_move(dir: Vector2i) -> bool:
		return view.pad_move(dir) if view else false

	func pad_press() -> bool:
		return view.pad_press() if view else false


## A row of the feed's list: its topic's colour, its title, a tick once seen; the Short on the screen framed.
class FeedRow:
	extends Button
	var entry: Dictionary = {}
	var current := false
	var _title := Label.new()
	var _tick := ShortsIcon.new(&"tick", 22.0, Color("8dff8a"))

	func _init(px: Vector2) -> void:
		custom_minimum_size = px
		size = px
		clip_contents = true
		focus_mode = Control.FOCUS_NONE
		_title.position = Vector2(16, 4)
		_title.size = Vector2(px.x - 44, px.y - 8)
		_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_title.max_lines_visible = 2
		_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_title.add_theme_font_size_override("font_size", 15)
		_title.add_theme_constant_override("line_spacing", -3)
		_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_title)
		_tick.position = Vector2(px.x - 28, (px.y - 22) * 0.5)
		_tick.size = Vector2(22, 22)
		add_child(_tick)

	func show_entry(e: Dictionary, is_current: bool) -> void:
		entry = e
		current = is_current
		_title.text = str(e.get("title", ""))
		tooltip_text = _title.text
		_tick.visible = bool(e.get("seen", false))
		var base := ShortRules.topic_colour(str(e.get("topic", ""))).darkened(0.55)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			var box := UiKit.box(base.lightened(0.1) if state == "hover" else base, 10, 0)
			box.border_width_bottom = 0
			if is_current:
				box.border_color = Color("ffd23f")
				box.set_border_width_all(3)
			add_theme_stylebox_override(state, box)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2(4, 6), Vector2(6, size.y - 12)), ShortRules.topic_colour(str(entry.get("topic", ""))))
