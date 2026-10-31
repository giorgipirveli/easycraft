extends Node
## The steps of tools/my_shorts_smoke.gd (spec §5.12b "As built (My Shorts)"), in a new Sandbox world on real terrain:
## two photos in photo mode (each kept small in the Shorts' album); the player walks into the Theater, MY SHORTS is
## empty with MAKE A SHORT; the maker makes "How I built it" from the two photos with a quick phrase, a backdrop and
## music, and SAVE keeps it in profile.json (never in the server backup's text) and plays it; Android Back goes a step
## back in the maker, then closes it, the Theater staying; DELETE twice deletes it; walking out stops everything.

const TIMEOUT := 180.0

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _photos_taken := 0


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
	var photo: PhotoMode = sandbox.get("photo")
	match _step:
		0:   # two photos, a second apart (each gets its own name)
			if photo == null:
				_check(false, "photo mode is in the sandbox")
				_finish()
				return
			if _photos_taken < 2 and _step_t > 1.2 * (_photos_taken + 1):
				if not photo.is_open():
					photo.open()
				photo.take_photo()
				_photos_taken += 1
			elif _photos_taken >= 2 and _step_t > 4.5:
				photo.close()
				MyShortAlbum.finish()
				var kept := MyShortAlbum.photos()
				_check(kept.size() >= 2, "photo mode kept %d small copies in the Shorts' album" % kept.size())
				for ph: Dictionary in kept:
					_check(str(ph.path).begins_with(MyShortAlbum.root()), "%s is in the album (user://my_shorts)" % ph.file)
				_next()
		1:   # the Theater stands; the player walks in
			if theater == null or theater.building == null:
				if _step_t > 60.0:   # the lead (2026-10-01): 20 s ran out once on a busy PC (load 13)
					_check(false, "the Theater stands")
					_finish()
				return
			var c: Vector3i = theater.site.pos
			p.global_position = Vector3(c.x + 0.5, c.y + 0.05, c.z + 0.5)
			p.velocity = Vector3.ZERO
			_next()
		2:   # MY SHORTS: empty, MAKE A SHORT
			var panel := theater.panel
			if not panel.is_open():
				if _step_t > 5.0:
					_check(false, "walking in opens the Theater")
					_finish()
				return
			var v := panel.shorts
			v.filter_buttons[ShortFeed.MINE].pressed.emit()
			_check(v.filter == ShortFeed.MINE and v.feed.is_empty(), "MY SHORTS is empty")
			_check(v.make_big.is_visible_in_tree() and v.make_button.is_visible_in_tree(), "MAKE A SHORT shows")
			v.make_big.pressed.emit()
			_check(v.maker.is_open() and not v.window.visible, "the maker opens over the feed")
			_next()
		3:   # How I built it: the two photos, a quick phrase, a backdrop, music, SAVE
			var v := theater.panel.shorts
			var m := v.maker
			m.content.get_node("Kind_built").pressed.emit()
			m.toggle_photo(0)
			m.toggle_photo(1)
			_check(not m.next_button.disabled, "two photos picked: NEXT")
			m.next()
			m.choose_slot("body:0")
			m.choose_words(MyShortRules.PHOTO_PHRASES[0])
			m.next()
			m.choose_backdrop("grass")
			m.choose_music("spring")
			m.next()
			_check(m.step == MyShortMakerView.SAVE, "the last step: SAVE")
			_check(ShortCheck.problems(m.current_short()) == [], "the Short passes ShortCheck")
			m.next()
			_check(not m.is_open(), "SAVE closes the maker")
			_check(Profile.data.my_shorts.count() == 1, "the profile keeps one Short")
			var saved := ProfileData.from_json(FileAccess.get_file_as_string(Profile.PATH))
			_check(saved.my_shorts.count() == 1, "profile.json keeps it")
			var backup := ProfileBackup.to_backup(Profile.data)
			_check(not backup.contains("mine:") and not backup.contains(MyShortRules.PHOTO_PHRASES[0]),
				"the server backup's text has none of it")
			_next()
		4:   # it plays in MY SHORTS
			var v := theater.panel.shorts
			if _step_t < 0.5:
				return
			_check(v.feed.size() == 1 and v.player().playing, "the new Short plays in MY SHORTS")
			_check(v.player().short.get("music") == "spring", "with its music")
			_next()
		5:   # Android Back in the maker: a step back, then closed; the Theater stays
			var panel := theater.panel
			var v := panel.shorts
			v.open_maker()
			v.maker.choose_template(MyShortRules.FACTS)
			sandbox.call(&"go_back")
			_check(v.maker.is_open() and v.maker.step == MyShortMakerView.KIND, "Back: a step back")
			sandbox.call(&"go_back")
			_check(not v.maker.is_open(), "Back on the first step closes the maker")
			_check(panel.is_open() and panel.view == TheaterPanel.VIEW_SHORTS, "the Theater stays, on MY SHORTS")
			_next()
		6:   # DELETE, SURE?
			var v := theater.panel.shorts
			v.delete_button.pressed.emit()
			_check(Profile.data.my_shorts.count() == 1, "one tap on DELETE asks SURE?")
			v.delete_button.pressed.emit()
			_check(Profile.data.my_shorts.count() == 0 and v.feed.is_empty(), "SURE? deletes it")
			_next()
		7:   # walking out: nothing plays, the music is back
			p.global_position += Vector3(0, 0, 30)
			if _step_t < 1.0:
				return
			var panel := theater.panel
			_check(not panel.is_open() and not panel.shorts.player().playing, "walked out: nothing plays")
			_check(not panel.shorts.is_holding_music(), "the game's music is back")
			_finish()


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("MY_SHORTS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("MY_SHORTS_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
