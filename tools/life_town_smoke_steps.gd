extends Node
## The steps of tools/life_town_smoke.gd (owner #112, Life L2): Life Town on real terrain through the real systems.

const TIMEOUT := 300.0
const SEED := 12345
const ROOM_SECONDS := 6.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scene: Node
var _places: Array[String] = []
var _frames: Array[float] = []
var _layer_was := true
var _market_done := false   # owner #115 (S3): the Market Square stood and its places were added
var _market_wait := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	WorldSaves.delete("sandbox_1")
	Profile.data.life.track = "middle"
	Profile.data.life.set_skill("kitchen.middle", {"b": 2, "q": 5})   # the before-check done: TRY IT goes into the room
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("LIFE_TOWN_SMOKE begin")


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
	var town: LifeTownDirector = sandbox.get("life_town")
	match _step:
		0:
			_check(town != null and town.panel != null, "the world has Life Town and its panel")
			if town == null:
				_finish()
				return
			_next(0.0)
		1:
			if not town.stood:
				if _step_t > 120.0:
					_check(false, "Life Town stands (site %s)" % [town.site])
					_finish()
				return
			print("LIFE_TOWN_SMOKE stood after %.1f s at %s" % [_t, town.site.pos])
			_check(LifeTown.from_save(sandbox.meta.life_town) == town.site, "the save keeps it")
			_check(town.buildings != null and town.buildings.signs.size() == LifeTown.SPOTS.size(), "six places with signs")
			var launch: LaunchDirector = sandbox.get("launch_site")
			if launch != null and not launch.site.is_empty():
				var p2: Vector3i = launch.site.pos
				var c: Vector3i = town.site.pos
				_check(Vector2(c.x - p2.x, c.z - p2.z).length() > 20.0, "clear of the Launch Site")
			_places.assign(LifeTown.SPOTS.keys())
			_next(0.0)
		2:   # walk up to each place in turn: Life opens on its Experience
			if _places.is_empty():
				if not _market_done:   # owner #115 (S3): then the Market Square's two, once it stands beside the town
					_market_wait += delta
					var m := town.market_square
					if m == null or not m.stood:
						if _market_wait > 90.0:
							_check(false, "the Market Square stands beside Life Town")
							_market_done = true
						return
					print("LIFE_TOWN_SMOKE the Market Square stood at %s, %.0f m from the town's middle" % [m.site.pos,
						Vector2(m.site.pos.x - town.site.pos.x, m.site.pos.z - town.site.pos.z).length()])
					_check(LifeTown.from_save(sandbox.meta.life_town).get("market", {}) == m.site,
						"the save keeps the Market Square with the town")
					_check(m.buildings != null and m.buildings.signs.size() == MarketPlaza.SPOTS.size(), "its two places with signs")
					_market_done = true
					for mid: String in MarketPlaza.SPOTS:
						_places.append("market/" + mid)
					_step_t = 0.0
					return
				_next(0.0)
				return
			var id: String = _places[0]
			if _step_t < 0.0:
				return   # walked away: a moment before the next place
			# the child stands at the place (headless: no floor to stand on, so it is held there each frame)
			p.global_position = _door(town, id) + Vector3(0, 0.1, 0)
			p.velocity = Vector3.ZERO
			if town.panel.visible and town.panel.experience == _experience(id):
				_check(true, "%s opens %s" % [id, town.panel.experience])
				_places.pop_front()
				town.panel.close()
				p.global_position += Vector3(30, 0, 30)   # walk away, then the next place
				_step_t = -0.4
			elif _step_t > 4.0:
				_check(false, "%s opens its Experience (panel %s, %s)" % [id, town.panel.visible, town.panel.experience])
				_places.pop_front()
				_step_t = 0.0
		3:   # TRY IT at the kitchen: the practice room over the loaded world
			p.global_position = LifeTown.door_position(town.site, "kitchen", town.ground) + Vector3(0, 0.1, 0)
			p.velocity = Vector3.ZERO
			if not town.panel.visible:
				if _step_t > 4.0:
					_check(false, "the kitchen's panel opens again")
					_finish()
				return
			town.panel.screen.start_experience("kitchen", "middle", false)
			_next(0.5)
		4:
			_check(town.panel.room_open(), "TRY IT opens the practice room")
			_check(not sandbox.get("_layer").visible, "the world's HUD hides under the room")
			_check(not p.is_physics_processing(), "the avatar is held still")
			_frames.clear()
			_next(0.0)
		5:
			_frames.append(delta * 1000.0)
			if _step_t >= ROOM_SECONDS:
				var avg := 0.0
				var worst := 0.0
				for f in _frames:
					avg += f
					worst = maxf(worst, f)
				avg /= maxf(_frames.size(), 1.0)
				print("LIFE_TOWN_SMOKE room frames=%d avg=%.1f ms worst=%.1f ms (headless, this desktop)" % [_frames.size(), avg,
					worst])
				town.panel.screen.host.stop_for_now()
				_next(0.5)
		6:
			_check(not town.panel.room_open(), "STOP FOR NOW ends the room")
			_check(sandbox.get("_layer").visible, "the HUD comes back")
			_check(p.is_physics_processing(), "the avatar is free again")
			_check(town.panel.screen.page == LifeScreen.CALM, "the calm words")
			p.global_position += Vector3(30, 0, 30)
			_next(0.6)
		7:
			_check(not town.panel.visible, "walking away closes Life")
			_finish()


## Owner #115 (S3): a place's door: the town's, or the Market Square's ("market/<id>").
func _door(town: LifeTownDirector, id: String) -> Vector3:
	if id.begins_with("market/"):
		return MarketPlaza.door_position(town.market_square.site, id.trim_prefix("market/"), town.ground)
	return LifeTown.door_position(town.site, id, town.ground)


func _experience(id: String) -> String:
	if id.begins_with("market/"):
		return str(MarketPlaza.SPOTS[id.trim_prefix("market/")].experience)
	return str(LifeTown.SPOTS[id].experience)


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("LIFE_TOWN_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("LIFE_TOWN_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
