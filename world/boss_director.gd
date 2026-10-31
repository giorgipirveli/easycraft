class_name BossDirector
extends Node
## The Stone Golem's fight in a world (M2 Task 10, spec §12.9; research G3 "honest help", D8 "portal
## peek"). The sandbox adds one on every peer, always named "Boss", so its spawners (the Golem, the
## portal) and RPCs line up across the network.
## Host:
## - start(totem_pos): the Golem rises next to the Totem (Task 9 calls it after wave 5 through the
##   sandbox's start_boss; Sandbox's /summon golem through summon_boss) with health by team size
##   (players and bot friends), tired after three lost fights (it says so). One at a time.
## - A win: 300 gold split among the players (pay_gold = Session.gold_add; nothing in Sandbox), the
##   portal opens by the Totem (one per world), universe 2 unlocks in every player's profile
##   (Survivor only, Session.boss_unlock), and the help resets.
## - A loss (every player knocked out at once in Survivor, or nobody near it for a while): it goes back
##   to sleep and everyone's bar says how far the team got ("You got it to 20%!").
## - help and portal_pos are saved per world (save_into / restore).
## Every peer: the HUD's BossBar follows the Golem's synced health; the start, win and loss messages
## arrive by RPC. Nothing here changes a block.

## Host: a fight began (tired: the honest-help Golem) / ended (percent of its health left; 0 = won).
## Task 9's Totem can listen: offer the boss again after a loss, celebrate a win.
signal fight_started(tired: bool)
signal fight_ended(won: bool, percent: int)
## Host: a boss of `kind` was beaten at `at` (M3 Task 20b: its tiny version hops out, MiniRules).
signal boss_won(kind: StringName, at: Vector3)
## Every peer: this game's player walked into the portal, which leads to universe `target` (M3 Task 5;
## the portal hub travels).
signal portal_entered(target: int)

const BUSY_MESSAGE := "The Stone Golem is already here!"
const PORTAL_OPEN_MESSAGE := "A portal opened by the Totem!"
const RESULT_TIME := 6.0
const CHECK_EVERY := 0.1
const WIN_GOLD := Color("ffd23f")
const CONFETTI: Array[Color] = [Color("ffd23f"), Color("ff5c8a"), Color("3fc1ff"), Color("7be05e")]

## Host: the honest help ({losses, best, wins}) and where the portal stands (INF: not open yet).
var help: Dictionary = BossRules.new_help()
## The world's boss (M3 Task 2: UniverseRegistry.boss_kind; the Sand Serpent in the Sandstorm Desert).
var boss_kind: StringName = BossRules.GOLEM
var portal_pos := Vector3.INF
## Monster Wave (owner feedback #44, spec §12.20): the arena's raid boss opens no portal (a choice comes instead).
var opens_portal := true
## Host: block_at(pos: Vector3i) -> int, the world read only (tests use stubs).
var block_at: Callable = _world_block
## Host: pay_gold(peer_id, amount) (tests use stubs).
var pay_gold: Callable = func(peer_id: int, amount: int) -> void: Session.gold_add(peer_id, amount, "boss")
## Host: everyone's victory dance after a win (Session.celebrate_all, M3 Task 9).
var celebrate: Callable = func() -> void:
	Session.celebrate_all()
## Every peer: the HUD's bar (null without a HUD).
var bar: BossBar

var _list := Node3D.new()
var _spawner := MultiplayerSpawner.new()
var _portals := Node3D.new()
var _portal_spawner := MultiplayerSpawner.new()
var _totem := Vector3.ZERO
var _fighting: StoneGolem         # every peer: the Golem from its spawn (golem())
var _next_id := 1
var _check_t := 0.0
var _away_t := 0.0
var _result_t := 0.0


func _ready() -> void:
	_list.name = "Golems"
	add_child(_list)
	_spawner.name = "GolemSpawner"
	add_child(_spawner)
	_spawner.spawn_path = _spawner.get_path_to(_list)
	_spawner.spawn_function = _make_golem
	_portals.name = "Portals"
	add_child(_portals)
	_portal_spawner.name = "PortalSpawner"
	add_child(_portal_spawner)
	_portal_spawner.spawn_path = _portal_spawner.get_path_to(_portals)
	_portal_spawner.spawn_function = _make_portal


func _world_block(pos: Vector3i) -> int:
	return Session.world.get_block(pos) if Session.world else BlockIds.AIR


## Every Golem in the world (one fighting, maybe one going back to sleep).
func golems() -> Array[StoneGolem]:
	var out: Array[StoneGolem] = []
	for n in _list.get_children():
		if n is StoneGolem and not n.is_queued_for_deletion():
			out.append(n)
	return out


## The Golem that is fighting now, or null (kept from its spawn: no search every frame).
func golem() -> StoneGolem:
	if is_instance_valid(_fighting) and not _fighting.is_queued_for_deletion() and not _fighting.is_down():
		return _fighting
	_fighting = null
	return null


func fighting() -> bool:
	return golem() != null


func portals() -> Array[DesertPortal]:
	var out: Array[DesertPortal] = []
	for n in _portals.get_children():
		if n is DesertPortal and not n.is_queued_for_deletion():
			out.append(n)
	return out


# --- Host: the fight --------------------------------------------------------------------------------

## Host: the Golem (the world's boss, or `kind`: M3 Task 2) rises next to the Totem at `totem_pos`.
## Returns why it can't ("" = it comes).
func start(totem_pos: Vector3, kind: StringName = &"") -> String:
	if not multiplayer.is_server() or not totem_pos.is_finite():
		return ""
	if fighting():
		return BUSY_MESSAGE.replace("Stone Golem", BossRules.words(_kind_of(golem())).name)
	var k := kind if kind != &"" else boss_kind
	_totem = totem_pos
	var spot := BossRules.golem_spot(totem_pos)
	spot.y = BossRules.stand_y(spot.x, spot.z, totem_pos.y, block_at)
	var tired := BossRules.is_tired(help)
	var to := totem_pos - spot
	_spawner.spawn({"id": "golem%d" % _next_id, "pos": spot, "yaw": atan2(-to.x, -to.z),
		"max_hp": BossRules.max_hp_of(k, BotFriend.team_size(get_tree()), tired), "tired": tired, "boss": String(k),
		"center": totem_pos})   # owner 39: the Sky Dragon circles over the Totem (the others ignore it)
	_next_id += 1
	_away_t = 0.0
	_check_t = 0.0
	_rpc_started.rpc(tired, String(k))
	fight_started.emit(tired)
	return ""


func _make_golem(data: Variant) -> Node:
	var g := _new_boss(str((data as Dictionary).get("boss", "")) if data is Dictionary else "")   # M3 Tasks 2-4
	g.setup(data)
	g.block_at = block_at
	if multiplayer.is_server():
		g.defeated.connect(_on_defeated)
	_fighting = g
	return g


## Host: a win. Gold, the portal, the next universe, the help resets.
func _on_defeated(g: StoneGolem) -> void:
	_rpc_won.rpc(g.hit_center(), String(_kind_of(g)), opens_portal)
	boss_won.emit(_kind_of(g), g.hit_center())   # M3 Task 20b
	_pay()
	if opens_portal:
		_open_portal()
	if BossRules.unlocks_universe(Game.mode):
		Session.boss_unlock(UniverseRules.next_universe(Game.universe))   # M3 Task 5: the next one of the ladder
		_earn_boss_items(g)   # M3 Task 4: the Cake Monster's cosmic outfit
	help = BossRules.after_win(help)
	celebrate.call()
	fight_ended.emit(true, 0)


## BossRules.GOLD split among the players in the world, in peer order (Survivor; Sandbox gold is ∞).
func _pay() -> void:
	if Game.allows(ModeRules.INFINITE_GOLD):
		return
	var peers: Array[int] = []
	for p in Monster.players_now(get_tree()):
		peers.append(p.peer_id)
	peers.sort()
	var shares := BossRules.gold_split(peers.size())
	for i in peers.size():
		pay_gold.call(peers[i], UniverseRules.gold(shares[i], Game.universe))   # × 2^(u−1) (M3 Task 5)


## One portal per world, by the Totem the Golem came to, facing it.
func _open_portal() -> void:
	if portal_pos.is_finite() and not portals().is_empty():
		return
	var pos := BossRules.portal_spot(_totem)
	pos.y = BossRules.stand_y(pos.x, pos.z, _totem.y, block_at)
	portal_pos = pos
	_spawn_portal(pos)


func _spawn_portal(pos: Vector3) -> void:
	var to := _totem - pos
	var yaw := atan2(-to.x, -to.z) if Vector2(to.x, to.z).length() > 0.01 else 0.0
	_portal_spawner.spawn({"id": "portal", "pos": pos, "yaw": yaw,
		"target": UniverseRules.boss_portal_target(Game.universe, UniverseRegistry.size())})   # M3 Task 4: the hub after the last


func _make_portal(data: Variant) -> Node:
	var p := DesertPortal.new()
	p.setup(data)
	p.entered.connect(portal_entered.emit)   # M3 Task 5
	return p


## Host, CHECK_EVERY: lost when every player is knocked out at once (Survivor) or nobody has been near
## the Golem for BossRules.LEAVE_TIME.
func _check_fight(g: StoneGolem, dt: float) -> void:
	var up := 0
	var near := false
	for p in Monster.players_now(get_tree()):
		if p.knocked_out:
			continue
		up += 1
		if Vector2(p.global_position.x - g.global_position.x, p.global_position.z - g.global_position.z).length() <= BossRules.ARENA:
			near = true
	_away_t = 0.0 if near else _away_t + dt
	if BossRules.is_lost(up, _away_t, Game.allows(ModeRules.LOSSES)):
		_lose(g)


func _lose(g: StoneGolem) -> void:
	var percent := BossRules.percent_left(g.hp, g.max_hp)
	help = BossRules.after_loss(help, percent)
	g.go_to_sleep()
	_rpc_lost.rpc(percent)
	fight_ended.emit(false, percent)


# --- Task 9's Totem (host) --------------------------------------------------------------------------

## Links the Totem's wave director (M2 Task 9, `sandbox.waves()`): its Stone Golem button
## (`boss_requested(peer_id, totem_pos)`) starts the fight (the child who tapped hears why not when
## it can't), and `set_boss_running(on)` follows the fight (meanwhile the Totem glows and refuses
## waves, and no night monsters come). Anything without those hooks is left alone.
func link_waves(waves: Object) -> void:
	if waves == null:
		return
	if waves.has_signal(&"boss_requested"):
		waves.connect(&"boss_requested", func(peer_id: int, totem_pos: Vector3) -> void:
			var said := start(totem_pos)
			if said != "":
				Session.send_feedback(peer_id, said))
	if waves.has_method(&"set_boss_running"):
		fight_started.connect(func(_tired: bool) -> void: waves.call(&"set_boss_running", true))
		fight_ended.connect(func(_won: bool, _percent: int) -> void: waves.call(&"set_boss_running", false))


# --- Saving (host) ------------------------------------------------------------------------------------

## A world's saved help and portal (the portal stands again where it opened).
func restore(saved_help: Dictionary, saved_portal: Vector3) -> void:
	help = BossRules.clean_help(saved_help)
	if saved_portal.is_finite() and portals().is_empty():
		portal_pos = saved_portal
		_totem = saved_portal - BossRules.PORTAL_OFFSET
		_spawn_portal(saved_portal)


func save_into(meta: WorldMeta) -> void:
	meta.boss_help = help.duplicate()
	meta.portal_pos = portal_pos


# --- Every peer: the bar and the messages -------------------------------------------------------

func _process(delta: float) -> void:
	tick(delta)


## Every peer: the bar follows the fighting Golem; the host checks whether the fight is lost.
func tick(delta: float) -> void:
	var g := golem()
	if bar:
		if g:
			bar.set_health(g.hp, g.max_hp, g.tired, g.is_dazed())
		elif _result_t > 0.0:
			_result_t -= delta
			if _result_t <= 0.0:
				bar.hide_bar()
		elif bar.visible:
			bar.hide_bar()
	if g and multiplayer.is_server():
		_check_t -= delta
		if _check_t <= 0.0:
			_check_t = CHECK_EVERY
			_check_fight(g, maxf(delta, CHECK_EVERY))


@rpc("authority", "call_local", "reliable")
func _rpc_started(tired: bool, kind: String = "golem") -> void:
	_result_t = 0.0
	var words := BossRules.words(StringName(kind))
	if bar:
		bar.use_boss(StringName(kind))
		bar.start(tired)
	if tired:
		Session.magic_feedback.emit(words.tired)   # honest help is announced, not hidden


@rpc("authority", "call_local", "reliable")
func _rpc_won(at: Vector3, kind: String = "golem", portal: bool = true) -> void:
	if not at.is_finite():
		return
	var root := get_tree().root
	var look := _win_look(StringName(kind), portal)   # M3 Tasks 2 and 4: each boss's bits, sound and words
	Fx.burst(root, at, look.colors[0], 36, 7.0, 0.3, 1.1, 14.0)
	Fx.burst(root, at, look.colors[1], 20, 5.0, 0.4, 1.0, 14.0)
	Fx.burst(root, at + Vector3(0, 1, 0), WIN_GOLD, 30, 8.0, 0.14, 1.2, 9.0)
	Fx.confetti(root, at + Vector3(0, 1, 0), CONFETTI, 40, 6.0, 0.1, 1.0, 7.0)   # M5 Task 2: one emitter
	if portal:
		Fx.portal(root, at + Vector3(0, 1.5, 0), 1.5)   # M5 Task 2: the way on opens (rainbow-gold)
	Audio.play(look.sound, at)
	Audio.play(&"coin", at)
	_show_result(BossRules.words(StringName(kind)).win, 0.0)
	if look.message != "":
		Session.magic_feedback.emit(look.message)
	if _last_universe():
		_grand_celebration(at)


@rpc("authority", "call_local", "reliable")
func _rpc_lost(percent: int) -> void:
	_show_result(BossRules.loss_message(clampi(percent, 0, 100)), clampi(percent, 0, 100) / 100.0)


func _show_result(text: String, fraction_left: float) -> void:
	_result_t = RESULT_TIME
	if bar:
		bar.show_result(text, fraction_left)


# --- M3 Task 2: each universe's boss ------------------------------------------------------------------

## Which boss `g` is (the Golem when there is none).
static func _kind_of(g: StoneGolem) -> StringName:
	return g.boss_kind() if g != null else BossRules.GOLEM

# --- M3 Task 4: the Candy Kingdom's boss, and after the last universe ----------------------------------------
# The Cake Monster is a StoneGolem to this director like the Sand Serpent. Universe 4 is the last on the ladder:
# its boss's portal leads to the hub (UniverseRules.HUB: every universe the child opened) instead of a new
# universe, its win is a grand celebration (fireworks and a fanfare on every screen), and beating it in Survivor
# earns every player the cosmic outfit (Session.boss_earn, AvatarCatalog.EARN_CAKE_MONSTER).

const FIREWORKS: Array[Color] = [Color("ff3b5c"), Color("ffd23f"), Color("3fb5ff"), Color("5ee05e"), Color("b57bff"),
	Color("ff8a3d")]
## Owner 39: the last universe's boss beaten where no portal opens (Monster Wave's raid boss: a choice comes instead).
const GRAND_WIN_NO_PORTAL := "Every universe is yours!"


## A new boss of `kind` (the Stone Golem when there is no such kind).
func _new_boss(kind: String) -> StoneGolem:
	match StringName(kind):
		BossRules.SERPENT:
			return SandSerpent.new()   # M3 Task 2
		BossRules.FROST_GIANT:
			return FrostGiant.new()    # M3 Task 3
		BossRules.CAKE:
			return CakeMonster.new()
		BossRules.SKY_DRAGON:
			return SkyDragon.new()     # owner 39
		BossRules.SPORE_MOTHER:
			return SporeMother.new()   # universe 6: the Glow Caves
	return StoneGolem.new()


## What a win looks and sounds like: {colors: [2], sound, message}. `portal`: a portal opens (owner 39: Monster Wave's
## raid boss opens none, so its words promise none).
func _win_look(kind: StringName, portal: bool = true) -> Dictionary:
	var message := CakeRules.GRAND_WIN if _last_universe() else PORTAL_OPEN_MESSAGE
	if not portal:
		message = GRAND_WIN_NO_PORTAL if _last_universe() else ""
	match kind:
		BossRules.SPORE_MOTHER:   # universe 6: she bursts into rose cap bits and glowing teal spores
			return {"colors": [SporeMotherModels.CAP, SporeMotherModels.SPOT], "sound": &"mother_puff", "message": message}
		BossRules.SKY_DRAGON:   # owner 39: it bursts into teal scales and violet crystal sparkles
			return {"colors": [SkyDragonModels.SCALES, SkyDragonModels.CRYSTAL], "sound": &"sky_crystal_shatter",
				"message": message}
		BossRules.SERPENT:
			return {"colors": [SerpentModels.SCALES, SerpentModels.SAND], "sound": &"serpent_burst", "message": message}
		BossRules.FROST_GIANT:   # M3 Task 3: it bursts into snow and ice
			return {"colors": [GiantModels.SNOW, GiantModels.ICE], "sound": &"giant_stomp", "message": message}
		BossRules.CAKE:
			return {"colors": [CakeModels.SPONGE, CakeModels.PINK], "sound": &"layer_pop", "message": message}
	return {"colors": [GolemModels.STONE, GolemModels.STONE_DARK], "sound": &"golem_crumble", "message": message}


## This world's boss portal leads to the hub (the last universe of the ladder), not to a new universe.
func _last_universe() -> bool:
	return UniverseRules.boss_portal_target(Game.universe, UniverseRegistry.size()) == UniverseRules.HUB


## Every screen: fireworks over the Totem three times, and a fanfare.
func _grand_celebration(at: Vector3) -> void:
	Audio.play(&"fanfare", at)
	for i in 3:
		get_tree().create_timer(0.6 * i).timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			var root := get_tree().root
			for k in FIREWORKS.size():
				var a := TAU * (k + i * 0.5) / FIREWORKS.size()
				var spot := at + Vector3(cos(a) * 3.0, 7.0 + i * 2.0, sin(a) * 3.0)
				Fx.burst(root, spot, FIREWORKS[k], 16, 6.0, 0.12, 1.2, 4.0))


## Host: a boss's own avatar item for every player (Survivor only, like the next universe).
func _earn_boss_items(g: StoneGolem) -> void:
	var event := CostumeRules.boss_event(_kind_of(g))   # Owner 36: the Cake Monster's, and the Sand Serpent's Hercules
	if event != &"":
		Session.boss_earn(event)
	if _kind_of(g) == BossRules.SKY_DRAGON:
		Session.boss_give_dragon()   # owner 39: a baby dragon (once) and a Dragon Crystal for every player

# --- Monster Wave (owner feedback #44, spec §12.20) ---------------------------------------------------------

## Host: the run ended while the boss fought (everyone was knocked out): it goes back to sleep, no result and no
## help counted (the ArenaDirector says how the run went).
func end_fight() -> void:
	var g := golem()
	if g:
		g.go_to_sleep()
