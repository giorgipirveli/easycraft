extends Node
## The steps of tools/shorts_smoke.gd (owner #94, spec §5.12b), in a new Sandbox world on real terrain: the player
## walks into the Theater (the TV shows room) and its panel opens on the SHORTS tab, the first Short still; ten swipes
## by finger (touch events on the Short) each snap the next one in and play it; a double tap gives a heart, kept in
## profile.json; LEARN IT on a Lesson in a minute opens its School page over the Theater and Android Back closes it;
## LEARN IT on the rocket Short leaves the Theater for the Mission Board; walking out stops everything.

const TIMEOUT := 180.0

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _swipes := 0
var _swipe_t := -1.0
var _start_index := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.universe = 1
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	_step_t += delta
	_run_step(sandbox, sandbox.player)


func _run_step(sandbox: Node, p: Player) -> void:
	var theater := sandbox.get_node_or_null("Theater") as TheaterDirector
	if theater == null:
		if _step_t > 5.0:
			_check(false, "the Theater is in the world")
			_finish()
		return
	var panel := theater.panel
	match _step:
		0:   # the Theater stands (its site is searched on a worker), then the player walks in
			if theater.building == null:
				if _step_t > 20.0:
					_check(false, "the Theater stands")
					_finish()
				return
			var c: Vector3i = theater.site.pos
			p.global_position = Vector3(c.x + 0.5, c.y + 0.05, c.z + 0.5)
			p.velocity = Vector3.ZERO
			_next()
		1:   # its panel opens on SHORTS, the first Short still
			if not panel.is_open():
				if _step_t > 5.0:
					_check(false, "walking in opens the Theater")
					_finish()
				return
			_check(panel.view == TheaterPanel.VIEW_SHORTS, "it opens on the SHORTS tab (%s)" % panel.view)
			_check(panel._tabs.get_child(0) == panel.shorts_tab, "SHORTS is the first tab")
			_check(panel.shorts.is_visible_in_tree(), "the Shorts show")
			_check(not panel.shorts.player().playing, "the first Short waits, still")
			_check(panel.shorts.feed.size() >= 16, "the hand-made Shorts: %d" % panel.shorts.feed.size())
			var hud: Hud = sandbox.get("hud")
			_check(hud.look_area.blockers.has(panel.shorts), "a tap on the Shorts never builds behind them")
			_start_index = panel.shorts.index
			_next()
		2:   # ten swipes up by finger, each snapping the next Short in, playing
			if _swipe_t < 0.0:
				_swipe(panel.shorts)
				_swipe_t = 0.0
				return
			_swipe_t += get_process_delta_time()
			if _swipe_t < ShortsView.SNAP_SECONDS + 0.3:
				return
			_swipe_t = -1.0
			_swipes += 1
			var s := panel.shorts
			var want := mini(_start_index + _swipes, s.feed.size() - 1)
			_check(s.index == want and s.player().playing, "swipe %d: Short %d of %d plays (%s)" % [_swipes, s.index + 1,
				s.feed.size(), s.current_entry().get("title", "")])
			if _swipes >= 10:
				_next()
		3:   # a double tap gives a heart, kept in profile.json
			var s := panel.shorts
			var id: String = s.current_entry().id
			for i in 2:
				_touch(s, true, Vector2(140, 250))
				_touch(s, false, Vector2(140, 250))
			_check(Profile.data.shorts.is_liked(id), "a double tap: a heart on %s" % id)
			var saved := ProfileData.from_json(FileAccess.get_file_as_string(Profile.PATH))
			_check(saved.shorts.is_liked(id), "profile.json keeps the heart")
			_check(s.like_button.text == "LIKED", "the heart button says LIKED")
			_next()
		4:   # LEARN IT on a Lesson in a minute: its School page over the Theater; Android Back closes it
			var s := panel.shorts
			s.set_filter(ShortFeed.LESSONS)
			var unit: String = s.current_entry().get("unit", "")
			s.learn_button.pressed.emit()
			_check(panel.school.is_open() and panel.school.screen.unit_id == unit, "LEARN IT opens %s in the School" % unit)
			_check(panel.is_open(), "the Theater stays under it")
			sandbox.call(&"go_back")
			_check(not panel.school.is_open(), "Android Back closes the School page")
			_check(panel.is_open() and panel.view == TheaterPanel.VIEW_SHORTS, "the Shorts are there again")
			_next()
		5:   # LEARN IT on the rocket Short: the Mission Board, in the world
			var s := panel.shorts
			s.set_filter(ShortFeed.HAND)
			var at := -1
			for i in s.feed.size():
				if s.feed[i].id == "rocket_parts":
					at = i
			s._jump(at, false)
			s.learn_button.pressed.emit()
			var site: LaunchDirector = sandbox.get("launch_site")
			_check(not panel.is_open(), "LEARN IT on a rocket Short leaves the Theater")
			_check(site != null and site.board != null and site.board.visible, "and opens the Mission Board")
			if site != null and site.board != null:
				site.board.close()
			_next()
		6:   # walking out: nothing plays, the music is back
			p.global_position += Vector3(0, 0, 30)
			if _step_t < 1.0:
				return
			_check(not panel.is_open() and not panel.shorts.player().playing, "walked out: no Short plays")
			_check(not panel.shorts.is_holding_music(), "the game's music is back")
			_finish()


## A finger drags the Short up by 240 (in the view) and lets go.
func _swipe(s: ShortsView) -> void:
	var from := Vector2(140, 380)
	_touch(s, true, from)
	for i in 6:
		var e := InputEventScreenDrag.new()
		e.index = 0
		e.position = from - Vector2(0, 40.0 * (i + 1))
		s._window_input(e)
	_touch(s, false, from - Vector2(0, 240))


func _touch(s: ShortsView, pressed: bool, at: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pressed
	e.position = at
	s._window_input(e)


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("SHORTS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("SHORTS_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
