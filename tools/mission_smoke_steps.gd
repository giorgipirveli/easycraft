extends Node
## The steps of tools/mission_smoke.gd (spec §21d, §25.3), on real terrain through the real systems: the sandbox's
## Launch Site (LaunchDirector: the site searched on a worker, the pad stamped a batch a frame), the Star Map's route,
## the Mission Board's check, shop and LAUNCH (the sandbox's fly: RocketFlight, the child at the controls; the
## autopilot takes any step a child doesn't), the Moon's world and the way home. Owner #98: the Launch Site on MY MAP,
## the Star Map pointing there, BUILD IT FOR ME building Mission Control's plan on the pad layer by layer (its slowest
## frames printed), BUY THE PARTS FOR THIS ROCKET with its card, a Gold Shop part reaching the Survivor bag.
## Owner #106: the descent is the child's (no autopilot): the first LAUNCH (SKIP to its landing) leaves the throttle
## alone and crashes: the way home stands the child at the Mission Board in Green Meadows (no world loads, not on the
## route), the rocket on the pad and the parts owned lose 15-35%, the board says so on MY ROCKET, BUILD IT FOR ME and
## BUY THE PARTS FOR THIS ROCKET make it whole again; the second LAUNCH's descent is flown (FlightDescent.test_pilot) and
## lands on the Moon at 3 m/s or less.

const TIMEOUT := 960.0   # two flights: a crash (SKIP to its landing, the way home) and the Moon (2-3 minutes)
const SEED := 12345

var _t := 0.0
var _step := 0
var _flew := false   # a flight was seen (its landing's world load comes after it ends)
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scene: Node
var _left: Node
var _gold_before := 0
var _frames: Array[float] = []   # owner #98: frame times while Mission Control builds (ms)
var _plan := {}
var _front := Vector3.ZERO
var _skipped := false        # owner #106: the crash flight's SKIP
var _descent_seen := false
var _broke := 0              # parts the crash broke
var _touchdown := -1.0       # m/s of the flown landing


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot: String in ["sandbox_1", "sandbox_16", "survivor_1"]:
		WorldSaves.delete(slot)
	Profile.data.wonder.bodies.erase("moon")   # never landed on the Moon: it needs a mission
	Profile.data.missions = MissionData.new()
	Profile.data.survivor_gold = 5000
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("MISSION_SMOKE begin")


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
		_wait = 1.5   # a new world: let it settle
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox)


## The rocket of tests/unit/test_rocket_check.gd that flies to the Moon (cells relative to the pad's corner).
static func moon_rocket() -> Dictionary:
	var c := {}
	for x in range(2, 6):
		for z in range(3, 5):
			c[Vector3i(x, 0, z)] = BlockIds.ROCKET_ENGINE
			c[Vector3i(x, 1, z)] = BlockIds.FUEL_TANK
	c[Vector3i(3, 2, 3)] = BlockIds.FUEL_TANK
	c[Vector3i(3, 2, 4)] = BlockIds.FUEL_TANK
	for f: Vector3i in [Vector3i(1, 0, 3), Vector3i(6, 0, 3), Vector3i(3, 0, 2), Vector3i(4, 0, 5)]:
		c[f] = BlockIds.ROCKET_FINS
	c[Vector3i(3, 3, 4)] = BlockIds.STAGE_SEPARATOR
	c[Vector3i(3, 4, 4)] = BlockIds.SPACE_ENGINE
	c[Vector3i(3, 4, 3)] = BlockIds.SPACE_ENGINE
	for y in [5, 6]:
		c[Vector3i(3, y, 3)] = BlockIds.FUEL_TANK
		c[Vector3i(3, y, 4)] = BlockIds.FUEL_TANK
	c[Vector3i(3, 7, 4)] = BlockIds.STAGE_SEPARATOR
	c[Vector3i(3, 8, 4)] = BlockIds.SPACE_ENGINE
	c[Vector3i(3, 9, 4)] = BlockIds.FUEL_TANK
	c[Vector3i(3, 10, 4)] = BlockIds.SERVICE_MODULE
	c[Vector3i(3, 11, 4)] = BlockIds.CREW_CAPSULE
	c[Vector3i(3, 12, 4)] = BlockIds.NOSE_CONE
	for leg: Vector3i in [Vector3i(2, 8, 4), Vector3i(4, 8, 4), Vector3i(3, 8, 5)]:
		c[leg] = BlockIds.LANDING_LEGS
	c[Vector3i(2, 10, 4)] = BlockIds.SOLAR_ARRAY
	return c


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var space: SpaceDirector = sandbox.get("space")
	var launch: LaunchDirector = sandbox.get("launch_site")
	match _step:
		0:
			_check(Game.slot() == "sandbox_1", "a new Green Meadows Sandbox world (%s)" % Game.slot())
			_check(launch != null and launch.board != null, "the world has a Launch Site and its Mission Board")
			if launch == null:
				_finish()
				return
			_next(0.0)
		1:
			if not launch.stamped:
				if _step_t > 60.0:
					_check(false, "the pad is stamped (site %s)" % [launch.site])
					_finish()
				return
			var site := launch.site
			var pos: Vector3i = site.pos
			_check(true, "the pad is stamped at %s, %.0f blocks from the spawn (%.1f s)" % [pos,
				Vector2(Vector2i(pos.x, pos.z) - p.world.spawn_column()).length(), _step_t])
			_check(p.world.get_block(pos) == BlockIds.PAD_CONCRETE, "the pad's concrete")
			_check(p.world.get_block(pos + Vector3i(LaunchSite.PAD_HALF, 0, 0)) == BlockIds.PAD_STRIPE, "its stripes")
			_check(launch.buildings != null and launch.buildings.is_inside_tree(), "the tower and Mission Control stand")
			_check(LaunchSite.from_save(sandbox.meta.launch_site).get("stamped") == true, "the save keeps it stamped")
			var theater := TheaterSite.from_save(sandbox.meta.theater)
			if not theater.is_empty():
				var t := Vector2i(theater.pos.x, theater.pos.z)
				_check(TheaterSite.edge_distance(t, Vector2i(pos.x, pos.z)) > LaunchSite.THEATER_CLEAR, "clear of the Theater")
			_next(0.0)
		2:
			space.open_picker()
			_check(space.panel.visible, "the Star Map opens")
			space.panel.body_for(&"moon").pressed.emit()
			_check(not space.panel.action_button.visible, "no LAND on the Moon before a mission")
			_check(space.panel.card_state_words() == StarMap.action_words(StarMap.MISSION),
				"\"%s\"" % space.panel.card_state_words())
			_check(space.panel.hint().contains("the Launch Site is"), "owner #98: the card shows the way: \"%s\""
				% space.panel.hint())
			_check(space.panel.card_facts().size() == 3, "its facts are free to see")
			var refused: String = sandbox.travel_to_space(SpaceRules.MOON)
			_check(refused.begins_with(StarMap.action_words(StarMap.MISSION)) and refused.contains("Launch Site is"),
				"flying there without a mission is refused, and the arrow points to the Launch Site: \"%s\"" % refused)
			var places: PlacesDirector = sandbox.get("places_director")
			_check(places != null and places.marks.any(func(e: Dictionary) -> bool: return e.get("id") == "launch_site"),
				"owner #98: MY MAP shows the Launch Site from the start")
			space.panel.body_for(&"boing").pressed.emit()
			_check(space.panel.action_button.visible and space.panel.action_button.text == "LAND",
				"Planet Boing: fly up and land")
			space.close_picker()
			var front := LaunchSite.to_world_point(launch.site, LaunchSite.BOARD_AT + Vector2(0, 1.6),
				(launch.site.pos as Vector3i).y + 1.05)
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			p.global_position = front
			p.velocity = Vector3.ZERO
			_next(0.0)
		3:
			if not launch.board.visible:
				if _step_t > 5.0:
					_check(false, "walking up to the board opens it (at %s)" % p.global_position)
					_finish()
				return
			_check(true, "walking up to the Mission Board opens it")
			_check(launch.board.card_names().size() >= 2 and launch.board.card_names()[0] == "Mission to the Moon",
				"its missions: %s" % [launch.board.card_names()])
			launch.board.choose(SpaceRules.MOON)
			_check(launch.board.result.empty and launch.board.build_button.visible, "an empty pad: BUILD IT FOR ME")
			_plan = RocketPlan.cells(MissionRules.for_world(SpaceRules.MOON), 1)
			_check(launch.board.press_build() == "", "owner #98: BUILD IT FOR ME (Mission Control's plan: %d parts)"
				% _plan.size())
			_check(launch.building() and not launch.board.visible, "Mission Control builds; the board closes to watch")
			_frames.clear()
			_front = p.global_position
			_next(0.0)
		4:
			p.global_position = _front   # the child stands at the board and watches (headless: no floor to stand on)
			p.velocity = Vector3.ZERO
			if launch.building():
				_frames.append(get_process_delta_time() * 1000.0)
				if _step_t > 60.0:
					_check(false, "Mission Control finished building (%d cells on the pad)" % launch.read_pad().size())
					_finish()
				return
			var built := RocketCheck.find_rocket(launch.read_pad())
			_check(built == _plan, "the plan stands on the pad, layer by layer, in %.1f s" % _step_t)
			_frames.sort()
			_check(true, ("frames while building: %d, slowest %.1f ms, median %.1f ms; Mission Control's slowest write %.2f ms "
				+ "(headless, the world still streaming round the board; the lead measures on the emulator)") % [_frames.size(),
				_frames.back() if not _frames.is_empty() else 0.0, _frames[_frames.size() / 2] if not _frames.is_empty() else 0.0,
				launch.build_slowest_ms])
			_check(launch.board.visible and launch.board.page == MissionBoard.ROCKET_PAGE,
				"the board opens again on MY ROCKET")
			var r := launch.board.result
			_check(not r.empty and r.stages.size() == RocketPlan.stages_for(MissionRules.for_world(SpaceRules.MOON), 1).size(),
				"the rocket on the pad: %d parts in %d stages" % [(r.cells as Dictionary).size(), r.stages.size()])
			_check(float(r.dv) > 15.35, "its fuel takes it %.2f km/s (the Moon needs 15.3)" % float(r.dv))
			_check(not r.ok and RocketParts.cost(r.missing) == RocketPlan.gold(MissionRules.for_world(SpaceRules.MOON), 1),
				"the Sandbox's parts are not bought yet (%d gold)" % RocketParts.cost(r.missing))
			_check(not launch.board.launch_ready() and launch.board.launch_button.text.begins_with("NOT YET"),
				"LAUNCH waits and says why")
			_gold_before = Profile.data.survivor_gold
			var cost := launch.board.missing_cost()
			_check(launch.board.buy_all_button.visible, "BUY THE PARTS FOR THIS ROCKET: %d gold" % cost)
			_check(launch.board.ask_buy(MissionBoard.BUY_ROCKET) == "" and launch.board.confirm_card.visible,
				"a card asks: \"%s\"" % launch.board.confirm_label.text)
			_check(launch.board.confirm_buy() == "", "YES")
			_check(Profile.data.survivor_gold == _gold_before - cost, "the child's gold paid: %d -> %d" % [_gold_before,
				Profile.data.survivor_gold])
			_check(launch.board.result.ok, "every line passes")
			_check(launch.board.launch_ready(), "LAUNCH is ready")
			_left = sandbox
			_check(launch.board.press_launch() == "", "LAUNCH")
			_next(0.1)
		5:   # owner #106: nobody flies this descent: it crashes, and the way home brings the child back to the board
			var f: Node = sandbox.get("flight")
			if is_instance_valid(f):
				_flew = true
				var run: FlightRun = f.get("run")
				if not _skipped:
					_skipped = true
					f.set("skippable", true)
					f.call("skip")   # a repeat visit's SKIP, straight to the landing (the smoke's time)
					_check(run.phase() == FlightPlan.DEORBIT, "SKIP to the landing")
				if run.phase() == FlightPlan.DESCENT and not _descent_seen:
					_descent_seen = true
					_check(run.waiting_for() == FlightPlan.DESCEND and run.descent != null,
						"owner #106: the descent waits for the child's throttle (%.0f m, %.0f m/s, no autopilot)" % [
						run.descent.height, run.descent.speed])
				return
			if not _flew:
				if _step_t > 10.0:
					_check(false, "LAUNCH flew the rocket")
					_finish()
				return
			_check(_descent_seen, "the flight came to the descent")
			_check(sandbox == _left and Game.slot() == "sandbox_1", "a crash stays home: no world loads (%s)" % Game.slot())
			_check(not Profile.data.missions.flown.has(SpaceRules.MOON), "the Moon is not on the route: only a landing")
			var cells := {}   # every rocket part still on the pad (the broken ones may have split it in pieces)
			var pad := launch.read_pad()
			for c: Vector3i in pad:
				if _plan.has(c) and int(pad[c]) == int(_plan[c]):
					cells[c] = pad[c]
			_broke = _plan.size() - cells.size()
			_check(_broke >= ceili(_plan.size() * 0.15) and _broke <= floori(_plan.size() * 0.35),
				"the rocket came back damaged: %d of %d parts broke (15-35%%)" % [_broke, _plan.size()])
			_check(Profile.data.missions.owned() == RocketParts.count(cells),
				"the Sandbox's parts owned lost the broken ones too (%s)" % RocketParts.list_words(
				RocketParts.missing(RocketParts.count(_plan), Profile.data.missions.owned())))
			var board_front := LaunchSite.to_world_point(launch.site, LaunchSite.BOARD_AT + Vector2(0, 1.6),
				(launch.site.pos as Vector3i).y + 1.05)
			_check(p.global_position.distance_to(board_front) < 3.0, "home at the Mission Board (%s)" % p.global_position)
			_check(p.visible and (sandbox.hud as Control).visible, "the player and the HUD are back")
			var said := str(sandbox.hud.get("_toast_label").text)
			_check(said.begins_with(CrashRules.SANDBOX_WORDS), "\"%s\"" % said)
			_front = board_front
			_next(0.0)
		6:   # the board opens on MY ROCKET with the crash's line; BUILD IT FOR ME on the damaged rocket
			p.global_position = _front
			p.velocity = Vector3.ZERO
			if not launch.board.visible:
				if _step_t > 10.0:
					_check(false, "the board opens with the crash's line")
					_finish()
				return
			var gold := RocketParts.cost(RocketParts.missing(RocketParts.count(_plan), Profile.data.missions.owned()))
			_check(launch.board.page == MissionBoard.ROCKET_PAGE and launch.board.message() == CrashRules.words(_broke,
				gold), "MY ROCKET says \"%s\"" % launch.board.message())
			launch.board.choose(SpaceRules.MOON)
			_check(launch.board.press_build() == "", "BUILD IT FOR ME rebuilds the damaged rocket")
			_next(0.0)
		7:   # whole again; BUY THE PARTS FOR THIS ROCKET; LAUNCH again
			p.global_position = _front
			p.velocity = Vector3.ZERO
			if launch.building():
				if _step_t > 60.0:
					_check(false, "Mission Control rebuilt the rocket")
					_finish()
				return
			_check(RocketCheck.find_rocket(launch.read_pad()) == _plan, "the rocket stands whole again (%.1f s)" % _step_t)
			if not launch.board.visible:
				launch.board.open()
			launch.board.choose(SpaceRules.MOON)
			var cost := launch.board.missing_cost()
			_check(cost > 0 and cost == RocketParts.cost(RocketParts.missing(RocketParts.count(_plan),
				Profile.data.missions.owned())), "BUY THE PARTS FOR THIS ROCKET: the broken parts' %d gold" % cost)
			var before := Profile.data.survivor_gold
			_check(launch.board.ask_buy(MissionBoard.BUY_ROCKET) == "" and launch.board.confirm_buy() == "",
				"bought: \"%s\"" % launch.board.message())
			_check(Profile.data.survivor_gold == before - cost, "the gold paid: %d -> %d" % [before,
				Profile.data.survivor_gold])
			_check(launch.board.launch_ready(), "LAUNCH is ready again: a second try is one rebuild away")
			_left = sandbox
			_flew = false
			_check(launch.board.press_launch() == "", "LAUNCH again")
			_next(0.1)
		8:
			var flying: Node = sandbox.get("flight")
			if is_instance_valid(flying):
				_flew = true
				_fly_descent(flying)
			if not _arrived(sandbox, "the rocket lands on the Moon"):
				return
			_check(_touchdown >= 0.0 and _touchdown <= FlightDescent.SAFE_SPEED,
				"owner #106: the child's descent touched down at %.1f m/s" % _touchdown)
			_check(_flew, "LAUNCH flew the rocket (the child at the controls)")
			_check(Game.universe == SpaceRules.MOON and Game.slot() == "sandbox_16", "the Moon's world (%s)" % Game.slot())
			_check(Profile.data.missions.flown.has(SpaceRules.MOON), "the mission is flown")
			_check(int(Profile.data.wonder.bodies.get("moon", 0)) & WonderData.LANDED != 0, "the Space Book marks the Moon")
			var toast := str(sandbox.hud.get("_toast_label").text)
			_check(toast.begins_with(MissionRules.COMPLETE), "\"%s\"" % toast)
			_check(sandbox.get("launch_site") == null, "no Launch Site on the Moon (its lander takes you home)")
			space.open_picker()
			space.panel.body_for(&"mars").pressed.emit()
			_check(space.panel.card_state_words() == StarMap.action_words(StarMap.MISSION), "Mars needs its own mission")
			space.close_picker()
			_left = sandbox
			_check(sandbox.go_home_from_space() == "", "HOME")
			_next(0.1)
		9:
			if not _arrived(sandbox, "home again"):
				return
			_check(Game.universe == 1 and Game.slot() == "sandbox_1", "home in Green Meadows (%s)" % Game.slot())
			if launch == null:
				_check(false, "the Launch Site again")
				_finish()
				return
			if launch.site.is_empty():
				return
			var cells := launch.read_pad()
			_check(RocketCheck.find_rocket(cells) == _plan, "the rocket still stands on the pad (a copy flew)")
			_check(launch.stamped, "the pad is not stamped again")
			space.open_picker()
			space.panel.body_for(&"moon").pressed.emit()
			_check(space.panel.action_button.visible and space.panel.action_button.text == "LAND",
				"the Moon is on the route: LAND")
			space.close_picker()
			Game.new_world_seed = SEED
			Profile.data.survivor_gold = 100
			Profile.data.backpack.clear()
			RocketParts.grant(Profile.data, BlockIds.FUEL_TANK, 2)   # owner #98 (bug 1): two tanks from the Gold Shop
			_left = sandbox
			Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.COZY, 1)
			_next(0.1)
		10:
			if not _arrived(sandbox, "a Survivor world"):
				return
			if launch == null or launch.board == null:
				_check(false, "Survivor has a Launch Site too")
				_finish()
				return
			_check(launch.board.owned.call() == null, "Survivor: the bag pays, no bought list")
			var bag := Session.inventory_of(p.peer_id)
			var before := bag.count(BlockIds.FUEL_TANK)
			_check(before >= 2, "owner #98: the Gold Shop's tanks reached the Survivor bag (%d)" % before)
			var said := launch.board.press_build()   # the rocket not invented yet, or the bag short, or not at the board
			_check(said != "" and not launch.building(), "BUILD IT FOR ME waits: \"%s\"" % said)
			_check(launch.board.buy.call(BlockIds.FUEL_TANK, 1) == "", "a fuel tank bought at the board")
			_check(bag.count(BlockIds.FUEL_TANK) == before + 1, "into the bag")
			_check(Profile.data.survivor_gold == 100 - RocketParts.price(BlockIds.FUEL_TANK), "for %d gold (%d left)" % [
				RocketParts.price(BlockIds.FUEL_TANK), Profile.data.survivor_gold])
			var capsule := RocketParts.price(BlockIds.CREW_CAPSULE)
			_check(launch.board.buy.call(BlockIds.CREW_CAPSULE, 1) == "", "a crew capsule for %d" % capsule)
			_check(launch.board.buy.call(BlockIds.CREW_CAPSULE, 1) == "", "a second one")
			var left := 100 - RocketParts.price(BlockIds.FUEL_TANK) - 2 * capsule
			_check(launch.board.buy.call(BlockIds.CREW_CAPSULE, 1) == "You need more gold!", "a third one needs more gold")
			_check(Profile.data.survivor_gold == left, "never below what the child has (%d)" % Profile.data.survivor_gold)
			_finish()


## Owner #106: the child flies the descent (the throttle lever where a good pilot holds it); the earlier steps are left
## to their autopilot. Keeps the touchdown's speed.
func _fly_descent(flight: Node) -> void:
	var run: FlightRun = flight.get("run")
	var cockpit: FlightCockpit = flight.get("cockpit")
	if run == null or cockpit == null:
		return
	if run.descent != null and run.descent.done():
		_touchdown = run.descent.touchdown_speed
	var flying := run.waiting_for() == FlightPlan.DESCEND
	if run.descent != null and run.descent.held():
		run.descent.release()   # GO on the first try's hint card
	cockpit.lever.held = flying
	cockpit.lever.value = run.test_throttle() if flying else 0.0


## True once a new world scene stands (after `_left`); fails after 25 s.
func _arrived(sandbox: Node, what: String) -> bool:
	if sandbox != _left:
		return true
	var flying := is_instance_valid(sandbox.get("flight"))   # LAUNCH flies the rocket now (RocketFlight, 2-3 minutes)
	if _step_t > (300.0 if flying or _flew else 25.0):
		_check(false, what)
		_finish()
	return false


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("MISSION_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("MISSION_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
