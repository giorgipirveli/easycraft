extends Node
## The steps of tools/trade_smoke.gd (owner #37), in a new Survivor world of the Sandstorm Desert on real terrain,
## through the real systems (the sandbox's wiring, the interactor's taps, the host's trades, the HUD): the first-time
## tip points at Tilly; MORE → SHOP shows her way and distance, SHOW ME points the find arrow, and arriving opens her
## shop by itself; Zara keeps a stand beside her whose tap opens "Zara's stand" with the desert's things, and buying
## one goes through the host; market day (the host's clock past a sunrise on day 2) brings Nico's cart beside Tilly's
## stall with the banner, a tap on it opens his market and a purchase goes through the host; at sunset the cart goes;
## the world's save keeps the day count.

const TIMEOUT := 240.0
const UNIVERSE := 2

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _tilly: Trader


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = UNIVERSE
	Game.start_new_world = true
	Profile.data.universe_unlocked = maxi(Profile.data.universe_unlocked, UNIVERSE)
	Profile.data.hints_seen.erase(ShopGuide.TIP)
	var fixed := OS.get_environment("TRADE_SMOKE_SEED")   # a world again: TRADE_SMOKE_SEED=<its seed>
	if fixed.is_valid_int():
		Game.new_world_seed = fixed.to_int()
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


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _wait(ok: bool, seconds: float, what: String) -> bool:
	if ok:
		return true
	if _step_t > seconds:
		_check(false, what)
		_finish()
	return false


func _tap(p: Player, at: Vector3) -> bool:
	var cam := p.camera()
	if cam.is_position_behind(at):
		return false
	return (p.get_node("BlockInteractor") as BlockInteractor).place_at_screen(cam.unproject_position(at))


## A spot 2.5-3 blocks from `n` on its own ground level (a helper may stand on a mesa's edge), in front first.
func _beside(sandbox: Node, n: Node3D) -> Vector3:
	var shape: MeadowsShape = sandbox.world.generator_shape()
	for off: Vector3 in [Vector3(0, 0, -3), Vector3(0, 0, 3), Vector3(-3, 0, 0), Vector3(3, 0, 0), Vector3(-2.5, 0, -2.5),
			Vector3(2.5, 0, -2.5), Vector3(-2.5, 0, 2.5), Vector3(2.5, 0, 2.5)]:
		var at := n.global_position + off.rotated(Vector3.UP, n.rotation.y)
		var h := shape.height_at(floori(at.x), floori(at.z))
		if absf(h - n.global_position.y) < 0.5:
			return Vector3(floorf(at.x) + 0.5, h + 0.5, floorf(at.z) + 0.5)
	return n.global_position + Vector3(0, 0.5, -3.0).rotated(Vector3.UP, n.rotation.y)


func _face(p: Player, at: Vector3) -> void:
	var to := at - p.global_position
	p.rig.yaw = atan2(-to.x, -to.z)


func _run_step(sandbox: Node, p: Player) -> void:
	var d: TradeDirector = sandbox.trading
	var hud: Hud = sandbox.hud
	match _step:
		0:
			print("TRADE_SMOKE seed %d" % (sandbox.world.generator_shape() as MeadowsShape).seed)
			_check(d != null and d.name == "Trading" and d.enabled() and d.universe == UNIVERSE, "the world's trade director")
			_check(d.more_button != null and hud.more.buttons().has(d.more_button), "SHOP is in the MORE panel")
			Profile.data.survivor_gold = 500
			# M3 Task 15: a first Survivor world offers Pip's lesson, and Tilly's first-time tip waits for the answer;
			# this run is about trading, so it answers SKIP (the tutorial has its own smoke run)
			var tutorial := sandbox.get("tutorial") as TutorialDirector
			if tutorial:
				tutorial.skip_offer()
			_next()
		1:
			_tilly = d.tilly.call()
			if not _wait(_tilly != null, 20.0, "Tilly's stall never came"):
				return
			_check(Profile.data.hints_seen.has(ShopGuide.TIP), "the first-time tip was shown (once per profile)")
			_check(d.guiding() == _tilly, "the tip's arrow points at Tilly")
			d.more_button.pressed.emit()
			_check(d.shop_menu.is_open() and not d.shop_menu.rows.is_empty(), "SHOP opens the card with Tilly's row")
			var r: Dictionary = d.shop_menu.rows[0]
			var way := ShopGuide.way(p.eye_position(), p.rig.yaw, _tilly.global_position)
			_check((r.distance as Label).text == ShopGuide.distance_words(int(way.distance)),
				"her distance: %s" % (r.distance as Label).text)
			(r.button as Button).pressed.emit()
			var runner: Node = sandbox.get_node("ChatCommands")
			var arrow: FindArrow = runner.get("find_arrow")
			_check(arrow != null and arrow.is_pointing() and arrow.target == _tilly.global_position, "SHOW ME points the find arrow")
			p.spawn_at(_beside(sandbox, _tilly))
			_next()
		2:
			if not _wait(hud.shop.visible, 10.0, "arriving never opened her shop"):
				return
			_check(hud.shop.title_text() == "Tilly's Shop", "arriving opens Tilly's shop by itself")
			hud.shop.close()
			_next()
		3:
			if not _wait(d.stand != null, 30.0, "Zara's stand never came"):
				return
			var zara: Node3D = d.giver.call(&"zara")
			var off := Vector2(d.stand.global_position.x - zara.global_position.x, d.stand.global_position.z - zara.global_position.z)
			_check(off.length() < 4.0, "the stand stands beside Zara (%.1f blocks)" % off.length())
			var shape: MeadowsShape = sandbox.world.generator_shape()
			var ground := shape.height_at(floori(d.stand.global_position.x), floori(d.stand.global_position.z))
			_check(absf(d.stand.global_position.y - ground) < 0.01, "on the ground")
			p.spawn_at(_beside(sandbox, d.stand))
			_next()
		4:
			if _step_t < 0.6:
				return
			_face(p, d.stand.global_position + Vector3(0, 1.0, 0))
			if _step_t < 1.0:
				return
			var chest := d.stand.global_position + Vector3(0, TraderRules.CHEST_HEIGHT, 0)
			var tapped := _tap(p, chest)
			_check(tapped and hud.shop.visible and hud.shop.title_text() == "Zara's stand", "a tap on the stand opens Zara's stand")
			if not hud.shop.visible:
				var cam := p.camera()
				var from := cam.global_position
				var dir := (chest - from).normalized()
				print("TRADE_SMOKE stand tap: eye=%s feet=%s stand=%s zara=%s reach=%.1f behind=%s blocked=%s quest_card=%s" % [
					p.eye_position(), p.global_position, d.stand.global_position, (d.giver.call(&"zara") as Node3D).global_position,
					p.eye_position().distance_to(chest), cam.is_position_behind(chest),
					p.world.raycast(from, dir, from.distance_to(chest)) != null, sandbox.quests().card.is_open()])
			if not hud.shop.visible:
				hud.open_shop(d.stand)
			var id: int = StandRules.stock(UNIVERSE)[0]
			var before := Session.inventory_of(p.peer_id).count(id)
			Session.request_trade(true, id, 1)
			_check(Session.inventory_of(p.peer_id).count(id) > before, "bought %s at the stand" % ItemIds.display_name(id))
			hud.shop.close()
			_next()
		5:
			if not _wait(not d._cart_spot.is_empty(), 30.0, "the cart's spot was never found"):
				return
			d.market = {"day": 1}
			d._last_time = 0.95
			sandbox.sky.time = DayCycle.SUNRISE + 0.02
			d.tick()
			_check(int(d.market.day) == 2 and d.cart != null, "a sunrise into day 2 brings Nico's cart")
			if d.cart == null:
				_finish()
				return
			var c: Vector3 = d.cart.global_position
			var to_tilly := Vector2(c.x - _tilly.global_position.x, c.z - _tilly.global_position.z).length()
			_check(to_tilly >= 3.0 and to_tilly <= 6.5, "beside Tilly's stall (%.1f blocks)" % to_tilly)
			_check(hud.banner.showing() == MarketRules.ARRIVED or hud.banner._queue.any(func(e: Array) -> bool: return e[0] == MarketRules.ARRIVED),
				"the market's banner")
			p.spawn_at(_beside(sandbox, d.cart))
			_next()
		6:
			if _step_t < 0.6:
				return
			_face(p, d.cart.global_position + Vector3(0, 1.0, 0))
			if _step_t < 1.0:
				return
			var tapped := _tap(p, d.cart.global_position + Vector3(0, TraderRules.CHEST_HEIGHT, 0))
			_check(tapped and hud.shop.visible and hud.shop.title_text() == MarketRules.SHOP_TITLE, "a tap on the cart opens Nico's market")
			var gold := Profile.data.survivor_gold
			Session.request_trade(true, BlockIds.ROOF_TILES, 1)
			_check(Session.inventory_of(p.peer_id).count(BlockIds.ROOF_TILES) == MarketRules.amount(BlockIds.ROOF_TILES),
				"bought roof tiles from Nico")
			_check(gold - Profile.data.survivor_gold == MarketRules.price(BlockIds.ROOF_TILES, UNIVERSE),
				"at his fixed price (%d gold)" % (gold - Profile.data.survivor_gold))
			hud.shop.close()
			sandbox.sky.time = DayCycle.SUNSET + 0.01
			d.tick()
			_check(d.cart == null, "at sunset the cart goes")
			sandbox.save_world()
			var meta := WorldSaves.load_meta(Game.slot())
			_check(int(meta.market.get("day", 0)) == 2, "the save keeps the day count (%s)" % str(meta.market))
			_finish()


func _check(ok: bool, what: String) -> void:
	print("TRADE_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("TRADE_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
