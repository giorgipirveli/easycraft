extends Node
## The steps of tools/discovery_smoke.gd (owner #132, Play W1): learning inside the world through the real systems.

const TIMEOUT := 240.0
const SEED := 12345

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scene: Node
var _frames: Array[float] = []
## `-- --shots=<dir>` in a real window (headless draws nothing): pictures of Hoot's card, the School over the world,
## MORE and the pause menu.
var _shots := ""
var _snapped := {}
var _gold := 0
var _result := {}
var _tap_t := 0.0
var _rose_at := -1.0
var _soon_door := ""


## The child turns to look at `target` (the camera follows the rig's yaw).
func _look_at(p: Player, target: Vector3) -> void:
	var to := target - p.global_position
	p.rig.yaw = atan2(-to.x, -to.z)
	p.rig.pitch = clampf(atan2(to.y - 1.5, Vector2(to.x, to.z).length()), -0.5, 0.6)


## Headless there is no floor to stand on: the child is held on the ground's top at its column.
func _stand_on_ground(sandbox: Node, p: Player) -> void:
	var world: WorldService = sandbox.world
	var x := floori(p.global_position.x)
	var z := floori(p.global_position.z)
	p.global_position.y = world.find_standing_y(x, z) + 0.01
	p.velocity = Vector3.ZERO


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			_shots = a.trim_prefix("--shots=")
			DirAccess.make_dir_recursive_absolute(_shots)
	process_mode = Node.PROCESS_MODE_ALWAYS
	WorldSaves.delete("sandbox_1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DiscoveryLog.PATH))   # Hoot has never been here
	Profile.data.school.grade = 4
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("DISCOVERY_SMOKE begin")


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if sandbox != _scene:
		_scene = sandbox
		_wait = 1.5
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, delta)


func _run_step(sandbox: Node, delta: float) -> void:
	var p: Player = sandbox.player
	var d: DiscoveryDirector = sandbox.get("discovery")
	match _step:
		0:
			_check(d != null and d.panel != null and d.hoot != null, "the world has Discovery, its panel and Hoot's card")
			if d == null:
				_finish()
				return
			var hud: Hud = sandbox.hud
			var b: TouchButton = sandbox.get("discover_button")
			_check(b != null and hud.more.buttons().size() > 0 and hud.more.buttons()[0] == b, "DISCOVER is MORE's first picture")
			_check(b != null and b.symbol == &"discover", "a magnifying glass")
			_next(0.0)
		1:   # Hoot comes once the child has stood a while with nothing over the world
			_stand_on_ground(sandbox, p)
			var keys: KeysCard = sandbox.get("keys_card")
			if keys != null and keys.visible and _step_t > 2.0:
				keys.close()   # a PC's first world shows its KEYS card: Hoot waits until the child closes it
				print("DISCOVERY_SMOKE closed the PC's KEYS card")
				_step_t = 0.0
			if not d.hoot.visible:
				if _step_t > DiscoveryRules.HOOT_AFTER + 15.0:
					_check(false, "Hoot comes after %.0f s in a new world (covered: %s)" % [DiscoveryRules.HOOT_AFTER,
						sandbox.call("_discovery_covered")])
					_finish()
				return
			if _snap("hoot_card"):
				return
			print("DISCOVERY_SMOKE Hoot came %.1f s after the child stood in the world" % (_step_t + 1.5))
			_check(DiscoveryRules.word_count(ReadAloud.words_of(d.hoot)) <= DiscoveryRules.MAX_SCREEN_WORDS,
				"his card shows few words")
			_check(d.hoot_flyer != null and d.hoot_flyer.landing.is_finite(), "Hoot himself flies in and lands near the child")
			_check(not DiscoveryRules.hoot_due(DiscoveryLog.new().state, d.world_key, SchoolClock.today()),
				"the device remembers his visit today")
			_frames.clear()
			_next(0.0)
		2:
			_stand_on_ground(sandbox, p)
			_frames.append(delta * 1000.0)
			if _step_t > 2.7 and _snap("hoot_landed"):
				return
			if _step_t >= 3.0:
				var avg := 0.0
				var worst := 0.0
				for f in _frames:
					avg += f
					worst = maxf(worst, f)
				avg /= maxf(_frames.size(), 1.0)
				print("DISCOVERY_SMOKE frames with Hoot's card=%d avg=%.1f ms worst=%.1f ms (headless, this desktop)" % [
					_frames.size(), avg, worst])
				d.hoot.discover.pressed.emit()
				_next(0.4)
		3:
			if _snap("school_over_the_world"):
				return
			_check(d.panel.is_open() and not d.hoot.visible, "his DISCOVER opens the School and he goes")
			_check(d.panel.screen is SchoolScreen and (d.panel.screen as SchoolScreen).page == SchoolScreen.MAP,
				"the grade's map")
			_check(not p.is_physics_processing(), "the avatar is held while it shows")
			(d.panel.screen as SchoolScreen).closed.emit()   # the map's BACK
			_next(0.4)
		4:
			_check(not d.panel.is_open(), "BACK gives the world back")
			_check(p.is_physics_processing(), "the avatar is free again")
			if _shots != "" and not _snapped.has("more"):
				(sandbox.hud as Hud).more.open()
				_snap("more")
				return
			(sandbox.hud as Hud).more.close()
			(sandbox.get("discover_button") as TouchButton).pressed.emit()
			_next(0.4)
		5:
			_check(d.panel.is_open(), "MORE's DISCOVER opens the School")
			d.panel.close()
			(sandbox.pause_menu as PauseMenu).open()
			_next(0.3)
		6:
			var pause: PauseMenu = sandbox.pause_menu
			if _snap("pause_menu"):
				return
			var found := pause.find_children("Discover", "DiscoverButton", true, false)
			_check(not found.is_empty(), "the pause menu has DISCOVER")
			if not found.is_empty():
				(found[0] as DiscoverButton).pressed.emit()
			_next(0.4)
		7:
			_check(not (sandbox.pause_menu as PauseMenu).visible and not get_tree().paused, "it resumes")
			_check(d.panel.is_open(), "and opens the School")
			d.panel.close()
			_gold = Profile.data.survivor_gold
			_stand_on_ground(sandbox, p)
			d.set("_play", DiscoveryCrystalRules.FIRST_SECONDS - 0.5)   # skip the minutes of play: the crystal now
			_next(0.0)
		8:   # stage 2: the crystal rises near the child on dry, open ground
			_stand_on_ground(sandbox, p)
			if d.crystal == null:
				if _step_t > 10.0:
					_check(false, "a crystal rises (busy: %s)" % sandbox.call("_discovery_busy"))
					_finish()
				return
			if _shots != "" and not _snapped.has("crystal_waiting"):
				if _rose_at < 0.0:
					_rose_at = _step_t
				if _step_t - _rose_at < 1.4:
					return   # it rises out of the ground first
				_snap("crystal_waiting")
				return
			var at := d.crystal.global_position
			var world: WorldService = sandbox.world
			var below := world.get_block(Vector3i(floori(at.x), int(at.y) - 1, floori(at.z)))
			_check(BlockIds.is_solid(below) and below != BlockIds.WATER, "on dry ground (block %d under it)" % below)
			_check(world.get_block(Vector3i(floori(at.x), int(at.y), floori(at.z))) == BlockIds.AIR, "not in a wall")
			var dist := Vector2(at.x - p.global_position.x, at.z - p.global_position.z).length()
			print("DISCOVERY_SMOKE the crystal rose %.1f m from the child at %s" % [dist, at])
			_check(dist >= DiscoveryCrystalRules.NEAR - 0.8 and dist <= DiscoveryCrystalRules.FAR + 1.0, "a few metres away")
			# the child taps it (the real tap path: the HUD's look area → BlockInteractor → the crystal)
			var cam := p.camera()
			var target := at + Vector3.UP * (DiscoveryCrystal.LIFT + DiscoveryCrystal.HEIGHT * 0.5)
			var tapped := not cam.is_position_behind(target) and (p.get_node("BlockInteractor") as BlockInteractor) \
				.place_at_screen(cam.unproject_position(target))
			_check(tapped and d.playing(), "a tap on it starts its play")
			_frames.clear()
			d.crystal_finished.connect(func(r: Dictionary) -> void: _result = r, CONNECT_ONE_SHOT)
			_next(0.6)
		9:   # Play G0's place: the crystal's short round on the child's own unit (the world's HUD hidden, the avatar held)
			_frames.append(delta * 1000.0)
			if _step_t < 0.5:
				return
			if not _snapped.has("crystal_play_place"):
				_check(d.place_open(), "the crystal opens Play G0's place")
				if d.place_open():
					print("DISCOVERY_SMOKE G0's short round: %s, %d challenges" % [d.place.unit_id,
						d.place.loop.challenges.size()])
					_check(d.place.loop.challenges.size() == DiscoveryDirector.CRYSTAL_ROUND, "a short round")
				_check(not (sandbox.get("_layer") as CanvasLayer).visible, "the world's HUD hides under the place")
				_check(not p.is_physics_processing(), "the avatar is held while the child plays")
				if _shots == "":
					_snapped["crystal_play_place"] = true   # checked once (with pictures, _snap marks it)
				if _snap("crystal_play_place"):
					return
			if _step_t < 3.5:
				return
			var avg := 0.0
			var worst := 0.0
			for f in _frames:
				avg += f
				worst = maxf(worst, f)
			avg /= maxf(_frames.size(), 1.0)
			print("DISCOVERY_SMOKE frames in G0's place=%d avg=%.1f ms worst=%.1f ms" % [_frames.size(), avg, worst])
			if d.place_open():
				d.place.stop_for_now()
			_check(d.crystal == null and not d.playing(), "STOP FOR NOW: the crystal goes quietly")
			_check((sandbox.get("_layer") as CanvasLayer).visible, "the world's HUD comes back")
			_next(0.5)
		10:   # stage 3: the Discovery Academy stands by the spawn, saved, marked on MY MAP
			_stand_on_ground(sandbox, p)
			var ac: AcademyPlacer = d.academy
			if ac == null or not ac.stood:
				if _step_t > 90.0:
					_check(false, "the Academy stands (%s)" % [ac.site if ac else "no placer"])
					_finish()
				return
			var sp: Vector2i = (sandbox.world as WorldService).spawn_column()
			var at: Vector3i = ac.site.pos
			var town: LifeTownDirector = sandbox.get("life_town")
			var from_town := Vector2(at.x - town.site.pos.x, at.z - town.site.pos.z).length() if town and not town.site.is_empty() \
				else NAN
			print("DISCOVERY_SMOKE the Academy stood at %s%s: %.0f m from the spawn, %.0f m from Life Town's middle" % [at,
				" (an island)" if ac.site.get("island", false) else "", Vector2(at.x - sp.x, at.z - sp.y).length(), from_town])
			_check(AcademyPlaza.from_save(sandbox.meta.academy) == ac.site, "the save keeps it")
			var places: PlacesDirector = sandbox.get("places_director")
			_check(places.marks.any(func(m: Dictionary) -> bool: return m.get("id") == "academy"), "MY MAP marks it")
			_check(not d.compass_target(p.global_position).is_empty(), "the compass points to it")
			p.global_position = LifeTown.to_world_point(ac.site, Vector2(0, 21), float(at.y))   # in front of it, towards the spawn
			_stand_on_ground(sandbox, p)
			_look_at(p, Vector3(at) + Vector3(0, 7, 0))
			_next(1.0)
		11:
			_stand_on_ground(sandbox, p)
			if _snap("academy_from_spawn"):
				return
			# walk up to a door whose subject has nothing to play without reading yet: the calm "coming soon" (if every
			# subject plays for this grade, the History Museum: its whole round)
			_soon_door = ""
			for door: String in AcademyPlaza.DOORS:
				if door != "life" and DiscoveryPlays.subject_unit(Profile.data, str(AcademyPlaza.SPOTS[door].subject),
						SchoolClock.today()) == "":
					_soon_door = door
					break
			print("DISCOVERY_SMOKE a door with nothing to play yet: %s" % (_soon_door if _soon_door != "" else "none"))
			p.global_position = d.academy.door_position(_soon_door if _soon_door != "" else "history") + Vector3(0, 0.1, 0)
			_look_at(p, LifeTown.to_world_point(d.academy.site, Vector2.ZERO, float(d.academy.site.pos.y) + 4.0))
			_next(0.6)
		12:
			p.velocity = Vector3.ZERO
			if _snap("academy_door_soon"):
				return
			if _soon_door != "":
				_check(d.academy_card.visible and d.academy_card.door == _soon_door, "a door with no game yet: coming soon")
			else:
				_check(d.place_open(), "the History Museum opens its whole round")
				if d.place_open():
					d.place.stop_for_now()
			_check(d.compass_target(p.global_position).is_empty(), "been in: the compass is the world's again")
			p.global_position = d.academy.door_position("maths") + Vector3(0, 0.1, 0)
			_look_at(p, LifeTown.to_world_point(d.academy.site, Vector2.ZERO, float(d.academy.site.pos.y) + 2.0))
			_next(0.6)
		13:
			p.velocity = Vector3.ZERO
			_check(not d.academy_card.visible, "walking away closes the card")
			_check(d.place_open() and d.place.unit_id.contains(".maths."), "the Maths Workshop opens a whole round of maths")
			if _snap("academy_maths_door"):
				return
			if d.place_open():
				d.place.stop_for_now()
			p.global_position = d.academy.door_position("life") + Vector3(0, 0.1, 0)
			_next(0.6)
		14:
			p.velocity = Vector3.ZERO
			_check(d.panel.is_open() and d.panel.subject == DiscoverPanel.LIFE, "Life's door opens Life")
			d.panel.close()
			(sandbox.sky as SkyCycle).time = DayCycle.MIDNIGHT
			p.global_position = LifeTown.to_world_point(d.academy.site, Vector2(0, 21), float(d.academy.site.pos.y))
			_stand_on_ground(sandbox, p)
			_look_at(p, Vector3(d.academy.site.pos) + Vector3(0, 7, 0))
			_next(1.5)
		15:
			_stand_on_ground(sandbox, p)
			if _snap("academy_night"):
				return
			_frames.clear()
			_next(0.0)
		16:   # frames with the Academy in view
			_stand_on_ground(sandbox, p)
			_frames.append(delta * 1000.0)
			if _step_t >= 3.0:
				var avg := 0.0
				var worst := 0.0
				for f in _frames:
					avg += f
					worst = maxf(worst, f)
				avg /= maxf(_frames.size(), 1.0)
				print("DISCOVERY_SMOKE frames with the Academy in view=%d avg=%.1f ms worst=%.1f ms" % [_frames.size(), avg,
					worst])
				_finish()


## With --shots: true the first time a step asks (its picture is being taken; the step waits a moment, then goes on).
func _snap(shot_name: String) -> bool:
	if _shots == "" or _snapped.has(shot_name):
		return false
	_snapped[shot_name] = true
	_take(shot_name)
	_wait = 1.2
	return true


func _take(shot_name: String) -> void:
	await get_tree().create_timer(UiMotion.POP_TIME + 0.15).timeout   # after the card's pop-in
	for i in 2:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_shots, shot_name]
	image.save_png(path)
	print("DISCOVERY_SHOT %s %s" % [path, image.get_size()])


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("DISCOVERY_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("DISCOVERY_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
