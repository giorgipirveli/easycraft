class_name SurvivorTour
extends AcceptanceTour
## The M2 "Survive the Night" acceptance tour (plan Task 12): the runner of the M1b tour (checks with
## time limits, TOUR / TOUR_SHOT / TOUR_FPS lines, never hangs) over the M2 features, in a NEW Survivor
## world (Normal), as the host and through the real systems: Session requests, the sandbox's
## directors (monsters, knock-outs, waves, the boss, bot friends, secrets, stealth) and the HUD.
## Android (debug): the developer menu's SURVIVOR TOUR. Desktop:
##   XDG_DATA_HOME=/tmp/easycraft-tour godot --path . --disable-vsync -- --tour --survivor [--tour-only=kit,wave]

## [name, time limit in seconds]; each runs as _check_<name>(gen) -> [ok, detail].
## Owner feedback #44 (spec §12.20): Survivor has no Totem waves and no boss any more, so the "wave" and "boss"
## checks left this list (their methods stay for a Monster Wave tour; tools/survivor_games_smoke.gd runs a
## Monster Wave run end to end).
const M2_CHECKS := [
	[&"kit", 30.0], [&"gather", 45.0], [&"trader", 60.0], [&"stealth", 30.0], [&"night", 150.0],
	[&"knockout", 75.0], [&"friends", 60.0], [&"minds", 60.0], [&"secrets", 60.0],
]
const TOUR_GOLD := 200            # the trader check's pocket money
const KILL := 1000                # a hit that defeats anything (the tour's stand-in for a long fight)


func _ready() -> void:
	if checks.is_empty():
		var only := _only_checks(OS.get_cmdline_user_args())
		for c: Array in M2_CHECKS:
			if only.is_empty() or only.has(String(c[0])):
				checks.append({"name": c[0], "limit": c[1], "run": Callable(self, "_check_" + String(c[0]))})
	super()


func _me() -> int:
	return multiplayer.get_unique_id()


func _hud() -> Hud:
	return sandbox.get("hud") as Hud


func _director(field: String) -> Node:
	return sandbox.get(field) as Node


## Faces `target` from the player (for a screenshot of it).
func _look_at(target: Vector3) -> void:
	var d := target - _player().global_position
	_face(Vector3(d.x, 0.0, d.z), -0.2)


# --- 1. A new Survivor world: the starter kit, hearts and gold on the HUD -------------------------

func _check_kit(gen: int) -> Array:
	var inv := Session.my_inventory
	var hud := _hud()
	var said: Array[String] = ["mode %s difficulty %s" % [Game.mode, sandbox.meta.difficulty]]
	var ok := Game.mode == ModeRules.SURVIVOR
	var kit := inv.has(ItemIds.SWORD) and inv.has(ItemIds.PICKAXE) and inv.count(BlockIds.PLANKS) >= 16 \
		and inv.count(BlockIds.DIRT) >= 8
	said.append("kit %s (planks %d, dirt %d)" % [kit, inv.count(BlockIds.PLANKS), inv.count(BlockIds.DIRT)])
	var huds := hud.hearts.visible and hud.gold_counter.visible and not hud.lab_button.visible
	said.append("hearts, gold, no LAB %s" % huds)
	said.append("gold %d" % Session.gold_of(_me()))
	if not await shot("survivor_hud", gen):
		return _abandoned()
	return [ok and kit and huds, ", ".join(said)]


# --- 2. Gathering: breaking gives the block's drop, placing takes one ----------------------------

func _check_gather(gen: int) -> Array:
	if not await _go_surface(_level_ground(), gen):
		return [false, "could not stand on level ground"]
	var p := _player()
	var inv := Session.my_inventory
	var feet := Vector3i(p.global_position.floor())
	var cell := feet + Vector3i(1, -1, 0)
	var was := _world().get_block(cell)
	var drop := GatherRules.drop(was, GatherRules.NONE)
	if drop == BlockIds.AIR:
		return [null, "the ground beside the feet (%s) gives nothing" % BlockIds.display_name(was)]
	var before := inv.count(drop)
	note("breaking %s at %s" % [BlockIds.display_name(was), cell])
	var broke := Session.request_set_block(cell, BlockIds.AIR)
	var got := inv.count(drop)
	var placed := Session.request_set_block(cell, drop)
	var after := inv.count(drop)
	return [broke and got == before + 1 and placed and after == before,
		"broke %s: %s %d -> %d; placed back: %d" % [BlockIds.display_name(was), BlockIds.display_name(drop), before, got, after]]


# --- 3. Tilly the trader: her shop opens and a tool is bought with gold ---------------------------

func _check_trader(gen: int) -> Array:
	var traders := get_tree().get_nodes_in_group(&"traders")
	if traders.is_empty():
		return [false, "no Tilly in this Survivor world"]
	var t := traders[0] as Trader
	note("walking to Tilly at %s" % t.global_position)
	if not await _go_surface(Vector2i(floori(t.global_position.x) + 2, floori(t.global_position.z)), gen):
		return [false, "could not reach Tilly"]
	_look_at(t.global_position)
	Session.gold_add(_me(), TOUR_GOLD, "tour")
	var gold := Session.gold_of(_me())
	_hud().open_shop(t)
	if not await shot("shop", gen):
		return _abandoned()
	Session.request_trade(true, ItemIds.PICKAXE_STONE)
	var bought := await wait_until_true(func() -> bool: return Session.my_inventory.has(ItemIds.PICKAXE_STONE), 5.0, gen)
	_hud().shop.close()
	var paid := gold - Session.gold_of(_me())
	return [bought and paid == ShopRules.price(ItemIds.PICKAXE_STONE),
		"stone pickaxe bought %s for %d gold (expected %d)" % [bought, paid, ShopRules.price(ItemIds.PICKAXE_STONE)]]


# --- 4. Stealth: crouching halves how well monsters see you ---------------------------------------

func _check_stealth(gen: int) -> Array:
	var p := _player()
	p.set_crouching(false)
	await wait_seconds(0.5, gen)
	var standing := p.stealth_visibility()
	p.set_crouching(true)
	await wait_seconds(0.5, gen)
	var crouched := p.stealth_visibility()
	if not await shot("crouch", gen):
		return _abandoned()
	p.set_crouching(false)
	return [p.crouching == false and crouched > 0.0 and crouched <= standing * 0.51,
		"visibility standing %.2f, crouching %.2f" % [standing, crouched]]


# --- 5. Night: monsters come, the ? and ! show, they puff away at sunrise -------------------------

func _check_night(gen: int) -> Array:
	var md := _director("_monsters") as MonsterDirector
	sandbox.call("set_time_of_day", DayCycle.MIDNIGHT)
	note("waiting for night monsters")
	var came := await wait_until_true(func() -> bool: return not md.monsters().is_empty(), 120.0, gen)
	if not came:
		sandbox.call("set_time_of_day", DayCycle.NOON)
		return [false, "no monster came in 120 s of night"]
	var nearest := md.monsters()[0]
	for m in md.monsters():
		if m.global_position.distance_to(_player().global_position) < nearest.global_position.distance_to(_player().global_position):
			nearest = m
	_look_at(nearest.global_position)
	var detail := "%d monsters, the nearest a %s %d blocks away" % [md.monsters().size(), nearest.kind,
		roundi(nearest.global_position.distance_to(_player().global_position))]
	if not await shot("night_monsters", gen):
		return _abandoned()
	sandbox.call("set_time_of_day", DayCycle.NOON)
	var gone := await wait_until_true(func() -> bool:
		return md.monsters().all(func(m: Monster) -> bool: return not m.wild), 10.0, gen)
	return [gone, detail + "; wild ones puffed away at sunrise: %s" % gone]


# --- 6. Knock-out: the fade, getting up at home, the pickup bag gives the blocks back -------------

func _check_knockout(gen: int) -> Array:
	var p := _player()
	var inv := Session.my_inventory
	var planks := inv.count(BlockIds.PLANKS)
	var at := p.global_position
	Session.hurt_player(_me(), Health.MAX_HP * 2, at + Vector3(1, 0, 0))
	var down := await wait_until_true(func() -> bool: return p.knocked_out, 3.0, gen)
	if not await shot("knocked_out", gen):
		return _abandoned()
	var up := await wait_until_true(func() -> bool: return not p.knocked_out, 15.0, gen)
	var kd := _director("_knockout") as KnockoutDirector
	var bags := kd.find_children("*", "PickupBag", true, false)
	var dropped := inv.count(BlockIds.PLANKS) < planks
	var took := false
	if not bags.is_empty():
		var bag := bags[0] as PickupBag
		if await _go(bag.global_position + Vector3(1.5, 0.2, 0), PhysicsMode.Mode.NORMAL, gen):
			Session.request_take_bag(bag.name)
			took = await wait_until_true(func() -> bool: return inv.count(BlockIds.PLANKS) >= planks, 5.0, gen)
	return [down and up and dropped and took,
		"down %s, up %s, the blocks dropped %s, bags %d, taken back %s" % [down, up, dropped, bags.size(), took]]


# --- 7. The Monster Totem: a wave comes, is won, pays 10 x N gold ---------------------------------

func _check_wave(gen: int) -> Array:
	var wd := sandbox.call("waves") as WaveDirector
	var totem := wd.totem()
	if totem == null:
		return [false, "no Totem"]
	if not await _go_surface(Vector2i(floori(totem.global_position.x) + 3, floori(totem.global_position.z)), gen):
		return [false, "could not reach the Totem"]
	_look_at(totem.global_position)
	var n := wd.next_wave
	var gold := Session.gold_of(_me())
	var results: Array = []
	wd.wave_ended.connect(func(w: int, r: StringName) -> void: results.append([w, r]), CONNECT_ONE_SHOT)
	Session.wave_request_start(n)
	note("waiting for wave %d" % n)
	var running := await wait_until_true(func() -> bool: return wd.phase == WaveDirector.Phase.RUNNING, 15.0, gen)
	if not running:
		return [false, "wave %d did not start (phase %d)" % [n, wd.phase]]
	var seen := await wait_until_true(func() -> bool: return not wd.wave_monsters().is_empty(), 30.0, gen)
	if seen and not await shot("wave", gen):
		return _abandoned()
	note("defeating wave %d" % n)
	while results.is_empty():
		for m in wd.wave_monsters():
			m.take_hit(KILL, _player().global_position, Vector3.ZERO)
		if not await wait_seconds(0.5, gen):
			return _abandoned()
	var won: bool = results[0][1] == WaveRules.WON
	var paid := Session.gold_of(_me()) - gold
	return [won and paid == WaveRules.reward(n, false),
		"wave %d: %s, paid %d gold (expected %d), next %d" % [n, results[0][1], paid, WaveRules.reward(n, false), wd.next_wave]]


# --- 8. The Stone Golem: it rises, is beaten, the portal opens and universe 2 unlocks --------------

func _check_boss(gen: int) -> Array:
	var wd := sandbox.call("waves") as WaveDirector
	var bd := _director("_boss") as BossDirector
	var at := wd.totem().global_position if wd.totem() else _player().global_position + Vector3(6, 0, 0)
	var ended: Array = []
	bd.fight_ended.connect(func(won: bool, percent: int) -> void: ended.append([won, percent]), CONNECT_ONE_SHOT)
	var why: String = sandbox.call("start_boss", at)
	if why != "":
		return [false, "the Golem did not come: %s" % why]
	var rose := await wait_until_true(func() -> bool: return bd.golem() != null, 10.0, gen)
	if not rose:
		return [false, "no Golem"]
	await wait_seconds(3.0, gen)   # it rises
	_look_at(bd.golem().global_position)
	if not await shot("golem", gen):
		return _abandoned()
	var gold := Session.gold_of(_me())
	while ended.is_empty():
		if bd.golem():
			bd.golem().take_hit(KILL, _player().global_position, Vector3.ZERO)
		if not await wait_seconds(0.5, gen):
			return _abandoned()
	var unlocked := await wait_until_true(func() -> bool: return Profile.data.universe_unlocked >= 2, 10.0, gen)
	var portals := get_tree().current_scene.find_children("*", "DesertPortal", true, false)
	if not portals.is_empty():
		_look_at((portals[0] as Node3D).global_position)
		if not await shot("portal", gen):
			return _abandoned()
	return [bool(ended[0][0]) and unlocked and not portals.is_empty(),
		"won %s, gold +%d, universe %d, portal %s" % [ended[0][0], Session.gold_of(_me()) - gold,
			Profile.data.universe_unlocked, not portals.is_empty()]]


# --- 9. Bot friends: one joins, is labelled a bot and follows -------------------------------------

func _check_friends(gen: int) -> Array:
	var bots := _director("_bot_director") as BotDirector
	if bots == null:
		return [false, "no bot director"]
	var bot := bots.add(BotRules.BUILDER)
	if bot == null:
		return [false, "no friend came"]
	var close := await wait_until_true(func() -> bool:
		return is_instance_valid(bot) and bot.global_position.distance_to(_player().global_position) < 12.0, 20.0, gen)
	var badge := bot.find_child("BotBadge", true, false) != null
	_look_at(bot.global_position)
	if not await shot("friend", gen):
		return _abandoned()
	var name := bot.bot_name
	bots.remove(name)
	return [close and badge, "%s joined, close %s, bot badge %s" % [name, close, badge]]


# --- 10. Creature minds: animals think, and a treat makes one like you ----------------------------

func _check_minds(gen: int) -> Array:
	var got := await wait_until_true(func() -> bool:
		return _animals().any(func(a: Animal) -> bool: return a.mind != null), 30.0, gen)
	if not got:
		return [false, "no animal with a mind within reach"]
	var with_mind := _animals().filter(func(a: Animal) -> bool: return a.mind != null)
	_look_at((with_mind[0] as Animal).global_position)
	if not await shot("minds", gen):
		return _abandoned()
	return [true, "%d of %d animals think" % [with_mind.size(), _animals().size()]]


# --- 11. Secrets: the nearest one nobody found, and its things near the player --------------------

func _check_secrets(gen: int) -> Array:
	var hint: String = sandbox.call("find_secret", &"", _player().global_position)
	var found := hint.begins_with("No ") == false
	return [found, hint]
