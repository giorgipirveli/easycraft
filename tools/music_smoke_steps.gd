extends Node
## The steps of tools/music_smoke.gd (owner #110, VR round 4 idea 7), in a new Sandbox world on real terrain, through
## the real systems: a xylophone and bongos placed through the host's edit path beside the player; a tap from the eyes
## on the xylophone's G bar plays G (and builds nothing on it); LOOP shows near them, counts in, records a C and a G and
## the low bongo, and plays them back; STOP clears it; in a simulated headset two mallets come over the nearest music
## block and a held one's hit plays its bar; out of VR they go.

const TIMEOUT := 150.0

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _xylo := Vector3i.ZERO
var _drum := Vector3i.ZERO
var _heard: Array = []


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


## An air cell with solid ground under it and air above, `r` blocks from the feet along `d`.
func _free_cell(world: WorldService, feet: Vector3i, d: Vector3i) -> Vector3i:
	for dy in range(-2, 4):
		var c := feet + d + Vector3i(0, dy, 0)
		if world.get_block(c) == BlockIds.AIR and world.get_block(c + Vector3i.UP) == BlockIds.AIR \
				and BlockIds.is_solid(world.get_block(c + Vector3i.DOWN)):
			return c
	return feet + d


func _run_step(sandbox: Node, p: Player) -> void:
	var world: WorldService = sandbox.get("world")
	var music: MusicDirector = sandbox.get("music")
	var interactor: BlockInteractor = sandbox.get("_interactor")
	match _step:
		0:   # a xylophone and bongos beside the player, through the host's edit path
			if _step_t < 1.0:
				return
			_check(music != null and music.get_parent() == sandbox and music.name == "Music", "node Music in the sandbox")
			var feet := Vector3i(p.global_position.floor())
			_xylo = _free_cell(world, feet, Vector3i(0, 0, -2))
			_drum = _free_cell(world, feet, Vector3i(2, 0, -2))
			Session.request_set_block(_xylo, BlockIds.XYLOPHONE)
			Session.request_set_block(_drum, BlockIds.DRUM)
			_check(world.get_block(_xylo) == BlockIds.XYLOPHONE, "a xylophone at %s" % _xylo)
			_check(world.get_block(_drum) == BlockIds.DRUM, "bongos at %s" % _drum)
			music.note_played.connect(func(v: int, _c: Vector3i, _db: float, _f: int) -> void: _heard.append(v))
			_next()
		1:   # a tap from the eyes on the G bar plays G; nothing is built on it
			p.rig.process_mode = Node.PROCESS_MODE_DISABLED   # the run aims the camera, from the eyes
			p.camera().look_at_from_position(p.eye_position(), Vector3(_xylo) + Vector3(4.5 / 8.0, 1.0, 0.5))
			var tapped := interactor.place_at_screen(interactor.get_viewport().get_visible_rect().size * 0.5)
			p.rig.process_mode = Node.PROCESS_MODE_INHERIT
			_check(tapped, "the tap was the xylophone's")
			_check(music.last_voice == 4, "it played G (voice %d)" % music.last_voice)
			_check(world.get_block(_xylo + Vector3i.UP) == BlockIds.AIR, "nothing was built on it")
			_check(music.letter.visible and music.letter.text == "G", "G's letter over it")
			_next()
		2:   # LOOP near them: a bar's count-in, then C, G and the low bongo recorded
			if _step_t < 1.0:
				return
			_check(music.loop_button.visible, "LOOP shows near the music blocks")
			_check(music.loop_button.get_parent() == sandbox.get("hud"), "on the HUD")
			music.loop_button.pressed.emit()
			_check(music.loop.state == MusicBlockRules.Loop.COUNT_IN, "LOOP counts in")
			_check(music.stop_button.visible, "STOP shows")
			_heard.clear()
			_next()
		3:
			var b := music.loop.beat_at(music.time)
			if b >= 15.8:
				_heard.clear()   # (the take's own notes heard; from here on the loop's)
				_next()
			elif b >= 0.0 and music.loop.take.is_empty():
				music.strike(_xylo, Vector3i.UP, Vector3(0.05, 1.0, 0.5), 1.5)
			elif b >= 2.0 and music.loop.take.size() == 1:
				music.strike(_xylo, Vector3i.UP, Vector3(0.6, 1.0, 0.5), 1.5)
			elif b >= 4.0 and music.loop.take.size() == 2:
				music.strike(_drum, Vector3i.UP, Vector3(0.25, 1.0, 0.5), 1.5)
		4:   # the second time round: the three notes again, in order
			if music.loop.beat_at(music.time) < 31.9:
				return
			_check(music.loop.state == MusicBlockRules.Loop.PLAYING, "after four bars it plays")
			_check(music.loop.layers.size() == 1 and music.loop.layers[0].size() == 3, "one layer of three notes")
			_check(music.metronome_ticks == 20, "the metronome: four counts and sixteen beats (%d)" % music.metronome_ticks)
			_check(_heard == [0, 4, MusicBlockRules.BONGO_LOW], "played back: %s" % [_heard])
			music.stop_button.pressed.emit()
			_check(music.loop.state == MusicBlockRules.Loop.IDLE, "STOP clears it")
			_next()
		5:   # a simulated headset: two mallets over the nearest music block
			Vr.simulate(true)
			Vr.anchor(p, &"feet")
			_next()
		6:
			if _step_t < 1.0:
				return
			_check(music.mallets.size() == 2, "two mallets in VR (%d)" % music.mallets.size())
			if music.mallets.size() == 2:
				var m := music.mallets[0]
				m.grabbable.holder = &"right"
				m.grabbable.grabbed.emit(&"right")
				var played := music.played
				for up: float in [0.12, -0.01]:   # its tip down onto the C bar in one frame
					var tip := Vector3(_xylo) + Vector3(0.1, 1.0 + up, 0.5)
					var hand := Transform3D(Basis(), tip - m.grabbable.hold_offset * MusicDirector.Mallet.TIP)
					Vr.sim_hand(&"right", Vr.rig.global_transform.affine_inverse() * hand)
					music.step(1.0 / 72.0)
				_check(music.played == played + 1 and music.last_voice == 0, "a mallet's hit plays C (%d)" % music.last_voice)
			Vr.simulate(false)
			Vr.anchor(p, &"feet")
			_check(music.mallets.is_empty(), "out of VR: no mallets")
			_finish()


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("MUSIC_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("MUSIC_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
