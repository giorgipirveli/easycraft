extends Node
## The steps of tools/wonders_smoke.gd (owner #78, spec §24), on real terrain through the real systems: the child's body
## climbs as flying does (its own position), the SpaceDirector opens the Star Map, Earth's card lands through the
## sandbox's trip (saves, the new world scene), the wonders are reached by standing at them (WonderSights), the hidden
## rooms open with the SecretDirector's knock (the pyramid's; the second tour's pyramid inside El Castillo; the third
## tour's ice cave by the frozen lake), the plaques' cards and quiz are the WondersDirector's, the northern lights
## NatureSky's (shown at night, not by day), and the way home is owner #39's portal by the landing square. The New Seven
## Wonders (the second tour, at the end of the Wonders Road) and the Seven Natural Wonders (the third, at the end of the
## Nature Trail) are visited before the first tour's last six.

const TIMEOUT := 600.0
const SEED := 12345
const CLIMB_SPEED := 60.0
const OFF_SPAWN := Vector3(12, 0, 7)
## Where the child stands at each of the other wonders (its own frame: y up from the tour's ground): the New Seven (on
## the Great Wall's walkway in its middle tower, in Petra's court, in the Colosseum's arena, in El Castillo's temple, on
## Machu Picchu's plaza, in the Taj Mahal's hall, on Corcovado's summit), then the first tour's six (the Lighthouse last:
## its chest comes next).
const VISITS := {&"great_wall": Vector3i(0, 11, 0), &"petra": Vector3i(0, 0, 10), &"colosseum": Vector3i(0, 0, 0),
	&"chichen_itza": Vector3i(0, 18, 0), &"machu_picchu": Vector3i(0, 12, 0), &"taj_mahal": Vector3i(0, 3, 13),
	&"christ_redeemer": Vector3i(0, 40, -5),
	# the third tour (on the canyon's rim, the reef's jetty, the bay's promenade, Everest's base camp, the valley's
	# deck, Parícutin's farm track, the path facing Victoria Falls)
	&"grand_canyon": Vector3i(0, 12, -30), &"barrier_reef": Vector3i(0, -6, -20), &"rio_harbour": Vector3i(-18, 0, -22),
	&"everest": Vector3i(28, 0, -68), &"northern_lights": Vector3i(0, 1, -5), &"paricutin": Vector3i(0, 0, -40),
	&"victoria_falls": Vector3i(0, 0, -6),
	&"gardens": Vector3i(0, 16, -3), &"artemis": Vector3i(0, 3, 0), &"zeus": Vector3i(-5, 10, 0),
	&"mausoleum": Vector3i(0, 9, 0), &"colossus": Vector3i(0, 7, -4), &"lighthouse": Vector3i(0, 35, 1)}

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scene: Node
var _left: Node
var _take_off := Vector2i.ZERO
var _gold := 0
var _visit: Array[StringName] = []
var _chest_id := ""
var _spawned_at: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot: String in ["sandbox_1", "sandbox_41"]:
		WorldSaves.delete(slot)
	Profile.data.wonder.wonders.clear()
	Profile.data.wonder.quiz.clear()
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("WONDERS_SMOKE begin")


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
		_wait = 1.5   # a new world: let it settle (and build its portal home)
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, delta)


func _w(id: StringName, p: Vector3i) -> Vector3:
	return Vector3(WondersSecretRules._w(id, p)) + Vector3(0.5, 0.05, 0.5)


func _run_step(sandbox: Node, delta: float) -> void:
	var p: Player = sandbox.player
	var space: SpaceDirector = sandbox.get("space")
	match _step:
		0:
			_check(Game.slot() == "sandbox_1", "a new Green Meadows Sandbox world (%s)" % Game.slot())
			_check(UniverseRegistry.trip_available().has(EarthRules.WONDERS), "world 41 is a world to land on")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += OFF_SPAWN + Vector3(0, 3, 0)
			_take_off = Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_next(0.1)
		1:
			if _climb(p, space, delta):
				_next(0.0)
		2:
			space.panel.body_for(&"earth").pressed.emit()
			_check(space.panel.card_title() == "Earth" and space.panel.card_facts().size() == 3,
				"Earth's card: %s, %d facts" % [space.panel.card_title(), space.panel.card_facts().size()])
			_check(space.panel.action_button.text == "Wonders of the World: LAND",
				"the Earth card says \"%s\"" % space.panel.action_button.text)
			space.panel.action_button.pressed.emit()
			_left = sandbox
			_next(0.1)
		3:
			if not _arrived(sandbox, "landing at the Wonders of the World"):
				return
			_check(Game.universe == EarthRules.WONDERS and Game.slot() == "sandbox_41",
				"world 41's own Sandbox world (%s)" % Game.slot())
			_check(p.world.generator_shape() is WondersShape, "its ground is the wonders'")
			_check(is_equal_approx(LabRules.world_gravity, 1.0), "Earth's gravity (%.2f)" % LabRules.world_gravity)
			var sky: SkyCycle = sandbox.sky
			_check(sky.space == 0.0, "Earth's own sky, never space's black")
			var animals: Node = sandbox.get_node_or_null("AnimalDirector")
			_check(animals != null and animals.process_mode != Node.PROCESS_MODE_DISABLED, "Earth's animals")
			var monsters: MonsterDirector = sandbox.get_node("Monsters")
			_check(not bool(monsters.enabled.call()), "peaceful: no night monsters")
			var feet := Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor())
			_check(p.world.get_block(feet) == BlockIds.PAVING, "standing on the landing square (%s at %s)" % [
				BlockIds.display_name(p.world.get_block(feet)), feet])
			var ids: Array = sandbox.places_director.marks.map(func(m: Dictionary) -> String: return str(m.id))
			_check(ids.has(WondersDirector.LANDING_ID), "MY MAP shows the landing spot")
			for id in WonderTour.ids():
				_check(ids.has("sight_" + String(id)), "MY MAP shows the %s" % WonderFacts.display_name(id))
			var wonders: WondersDirector = sandbox.get("wonders")
			_check(wonders != null, "the tour is watched (WondersDirector)")
			_check(wonders != null and wonders.labels.size() == 49, "the signposts' and plaques' names")
			var card := sandbox.find_child("PlanetGuideCard", true, false) as PlanetGuideCard
			_check(card != null and card.lines.size() == 21, "the explorer's card lists the three tours' wonders")
			if card != null:
				card.go_button.pressed.emit()
			_check((sandbox.hud as Hud).compass.guide.is_valid(), "the compass points to the nearest wonder")
			_next(1.0)
		4:
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			_check(frames.gates.gate_to(1) != null, "the portal home stands by the landing square")
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			p.spawn_at(_w(&"pyramid", Vector3i(0, 0, -25)))   # at the pyramid's foot, by its entrance
			_next(0.0)
		5:
			if not _reached(sandbox, &"pyramid"):
				return
			_check(Profile.data.wonder.stamped(&"pyramid"), "the Wonders Passport's stamp for the pyramid")
			p.spawn_at(_w(&"pyramid", Vector3i(0, 11, 5)))   # in the King's Chamber
			_next(0.5)
		6:
			var under := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor()))
			_check(under == BlockIds.GRANITE, "standing on the King's Chamber's granite (%s)" % BlockIds.display_name(under))
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			var s := (secrets.rules as WondersSecretRules).secret_of(&"pyramid")
			var fake: Vector3i = s.fake_wall[0]
			_check(SecretRules.is_fake_wall(p.world.get_block(fake)), "a fake block in the Grand Gallery's wall")
			p.spawn_at(Vector3(fake + (s.dir as Vector3i)) + Vector3(0.5, 0.05, 0.5))   # in the gallery before it
			_next(0.5)
		7:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			var s := (secrets.rules as WondersSecretRules).secret_of(&"pyramid")
			var fake: Vector3i = s.fake_wall[0]
			secrets._on_knock_requested(p.peer_id, fake)
			_check(p.world.get_block(fake) == BlockIds.AIR, "a knock opens the hidden room's door")
			_check(secrets.state.found.has(s.id), "the hidden room is found")
			var hud: Hud = sandbox.hud
			_check(hud.banner.showing() == "You found a hidden room!" or hud.banner.waiting() > 0,
				"its banner (%s)" % hud.banner.showing())
			_next(0.5)
		8:
			var wonders: WondersDirector = sandbox.get("wonders")
			_gold = Profile.data.survivor_gold
			_check(wonders.open_plaque(WonderTour.plaque(&"pyramid")), "the pyramid's plaque opens its card")
			var card := wonders.card
			_check(card != null and card.is_inside_tree() and card.quiz_button.visible, "its card with QUIZ (stamped)")
			if card != null:
				card.quiz_button.pressed.emit()
				var q: Dictionary = WondersPassportRules.questions(&"pyramid")[0]
				card.quiz.pick(int(q.right))
				_check(Profile.data.survivor_gold == _gold + EarnRules.FACT_QUIZ_GOLD,
					"a right first answer pays %d gold (%d -> %d)" % [EarnRules.FACT_QUIZ_GOLD, _gold, Profile.data.survivor_gold])
				card.close()
			_visit.assign(VISITS.keys())
			_next(0.2)
		9:
			if _visit.is_empty():
				_next(0.0)
				return
			var id: StringName = _visit[0]
			if _spawned_at != id:
				_spawned_at = id
				_step_t = 0.0
				p.spawn_at(_w(id, VISITS[id]))
				return
			if not _reached(sandbox, id):
				return
			_check(Profile.data.wonder.stamped(id), "the passport's stamp for %s" % WonderFacts.called(id))
			_visit.pop_front()
			_step_t = 0.0
		10:
			var wonders: WondersDirector = sandbox.get("wonders")
			for id in WonderTour.ids():
				_check(Profile.data.wonder.stamped(id), "%s stamped" % id)
			_check(wonders.compass_target(p.global_position).is_empty(), "every wonder reached: the arrow rests")
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			_chest_id = (secrets.rules as WondersSecretRules).secret_of(&"lighthouse").id
			_next(0.0)
		11:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			var chest := secrets.thing("chest_" + _chest_id)
			if chest == null:
				if _step_t > 12.0:
					_check(false, "the golden chest stands by the Lighthouse's fire")
					_next(0.0)
				return
			_check(true, "the golden chest stands by the Lighthouse's fire")
			secrets._on_chest_requested(p.peer_id, "chest_" + _chest_id)
			_check(secrets.state.opened.has(_chest_id) and secrets.state.found.has(_chest_id),
				"opening it finds the lighthouse's treasure")
			_next(0.5)
		12:   # the second tour: its square's plaque, then the pyramid inside El Castillo
			var wonders: WondersDirector = sandbox.get("wonders")
			_check(wonders.open_plaque(WonderTour.tour_plaque(&"new")), "the New Seven's square's plaque opens its card")
			var card := wonders.card
			_check(card != null and ReadAloud.words_of(card).contains("New Seven Wonders")
				and ReadAloud.words_of(card).contains("2007"), "its card tells the New Seven Wonders, chosen in 2007")
			if card != null:
				card.close()
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			var s := (secrets.rules as WondersSecretRules).secret_of(&"chichen_itza")
			var fake: Vector3i = s.fake_wall[0]
			p.spawn_at(Vector3(fake + (s.dir as Vector3i)) + Vector3(0.5, 0.05, 0.5))   # before the stair's fake stone
			_next(0.5)
		13:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			var s := (secrets.rules as WondersSecretRules).secret_of(&"chichen_itza")
			var fake: Vector3i = s.fake_wall[0]
			_check(SecretRules.is_fake_wall(p.world.get_block(fake)), "a fake stone low in El Castillo's north stair")
			secrets._on_knock_requested(p.peer_id, fake)
			_check(p.world.get_block(fake) == BlockIds.AIR, "a knock opens the way into the pyramid")
			_check(secrets.state.found.has(s.id), "the pyramid inside the pyramid is found")
			var lo: Vector3i = s.inside[0]
			var throne := false
			for x in range(lo.x, (s.inside[1] as Vector3i).x):
				for z in range(lo.z, (s.inside[1] as Vector3i).z):
					throne = throne or p.world.get_block(Vector3i(x, lo.y, z)) == BlockIds.JAGUAR_THRONE
			_check(throne, "the red jaguar throne inside")
			_next(0.5)
		14:   # the third tour: its square's plaque, then the northern lights' ice cave
			var wonders: WondersDirector = sandbox.get("wonders")
			_check(wonders.open_plaque(WonderTour.tour_plaque(&"nature")), "the nature square's plaque opens its card")
			var card := wonders.card
			_check(card != null and ReadAloud.words_of(card).contains("Natural Wonders")
				and ReadAloud.words_of(card).contains("1997"), "its card tells the Seven Natural Wonders, a list from 1997")
			if card != null:
				card.close()
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			var s := (secrets.rules as WondersSecretRules).secret_of(&"northern_lights")
			var fake: Vector3i = s.fake_wall[0]
			p.spawn_at(Vector3(fake + (s.dir as Vector3i)) + Vector3(0.5, 0.05, 0.5))   # before the mound's snow door
			_next(0.5)
		15:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			var s := (secrets.rules as WondersSecretRules).secret_of(&"northern_lights")
			var fake: Vector3i = s.fake_wall[0]
			_check(p.world.get_block(fake) == BlockIds.FAKE_SNOW, "a snow door in the mound by the frozen lake")
			secrets._on_knock_requested(p.peer_id, fake)
			_check(p.world.get_block(fake) == BlockIds.AIR, "a knock opens the ice cave")
			_check(secrets.state.found.has(s.id), "the ice cave is found")
			var wonders: WondersDirector = sandbox.get("wonders")
			var sky: SkyCycle = sandbox.sky
			sky.set_time(DayCycle.MIDNIGHT)
			wonders.nature_sky.look()
			_check(wonders.nature_sky.aurora.visible, "at night the northern lights shine over the valley")
			sky.set_time(DayCycle.NOON)
			wonders.nature_sky.look()
			_check(not wonders.nature_sky.aurora.visible, "by day they cannot be seen")
			_next(0.5)
		16:
			space.open_picker()
			var states := StarMap.states(Game.universe, space.home, space.available.call(), 1)
			_check(states[&"earth"] == StarMap.HERE, "on the Star Map Earth says \"You are here!\"")
			_check(space.panel.home_button.visible, "HOME from the wonders")
			space.panel.close()
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			var core: Variant = frames.gates.gate_to(1)
			if core == null:
				_check(false, "the portal home")
				_finish()
				return
			var shape_of := frames.gates.shape_of(core)
			p.spawn_at(Vector3(shape_of.lo as Vector3i) + Vector3(0.5, 0.05, 0.5))
			_left = sandbox
			_next(0.1)
		17:
			if not _arrived(sandbox, "walking into the portal home"):
				return
			_check(Game.universe == 1 and Game.slot() == "sandbox_1", "home in Green Meadows (%s)" % Game.slot())
			var col := Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_check(col == _take_off, "landed on the take-off column (%s, took off at %s)" % [col, _take_off])
			_check(Profile.data.wonder.stamped(&"lighthouse"), "the passport keeps its stamps")
			_finish()


## True once wonder `id` was reached (its fact said); fails after 12 s.
func _reached(sandbox: Node, id: StringName) -> bool:
	var wonders: WondersDirector = sandbox.get("wonders")
	if wonders != null and wonders.found.has("sight:" + String(id)):
		_check(true, "reaching %s says its fact" % WonderFacts.called(id))
		return true
	if _step_t > 12.0:
		_check(false, "reaching %s (at %s)" % [WonderFacts.called(id), (sandbox.player as Player).global_position])
		if _step == 9:
			_visit.pop_front()
			_step_t = 0.0
		else:
			_next(0.0)
	return false


## The flyer climbs (its own position, as flying does); true once the Star Map shows.
func _climb(p: Player, space: SpaceDirector, delta: float) -> bool:
	if space.panel.visible:
		return true
	if _step_t > 20.0:
		_check(false, "the Star Map opened above the space line (y %.1f)" % p.global_position.y)
		_finish()
		return false
	p.global_position.y = minf(p.global_position.y + CLIMB_SPEED * delta, SpaceRules.SPACE_Y + 2.0)
	return false


## True once a new world scene stands (after `_left`); fails after 20 s.
func _arrived(sandbox: Node, what: String) -> bool:
	if sandbox != _left:
		return true
	if _step_t > 20.0:
		_check(false, what)
		_finish()
	return false


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("WONDERS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("WONDERS_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
