class_name InventionsDirector
extends Node
## Owner #78 (spec §21e): "invent it" in a played world (the sandbox's node "Inventions", every mode but Monster
## Wave's arena). For this game's child:
## - the Inventions book (InventionsPanel: INVENT in MORE, I on a PC) and the page's answers;
## - MAKE IT (Survivor, this game's own world): the Workbench within reach, the materials taken from the bag, the gold
##   paid (free once its School unit is mastered), the invention kept in the profile (InventionData);
## - TRY IT: the challenge (InventionTry) fed from the child's body every frame, a banner (TryBanner) with the goal,
##   the bar, the hint and the wind's arrow; done, its science on the screen and EarnRules' gold once (Survivor through
##   the host's wallet, the Sandbox into the profile; a LAN guest's try in a friend's world pays nothing: try it at
##   home); the kite is held up for its try, a flying machine takes off, the rocket's is the bottle rocket in the book;
## - FLY WITH IT: Survivor's pick is saved (InventionData.craft), the Sandbox's is this session's (the Player's
##   chosen_craft; FREE FLYING clears it);
## - the wind: one of eight compass points from the world's seed and the time (FlightCrafts), given to the Player.
## Nothing per frame but the wind's slot and, during a try, one look at the body.

signal changed

const DONE_SHOW := 3.0   # s the banner stays after a try is done

# --- Injected by the sandbox (tests use stand-ins) ---
## Flying costs here (Survivor): the gates.
var survivor := false
## This game's own world (a LAN guest invents in its own world).
var host := true
var world_seed := 0
var data := InventionData.new()
var school: SchoolData = null
var player: Player = null
## () -> Inventory: this child's Survivor bag (the host's), or null.
var bag: Callable = func() -> Inventory: return null
var near_workbench: Callable = func() -> bool: return false
var gold: Callable = func() -> int: return 0
## (gold) -> bool: takes gold for an invention (Survivor: the host's wallet).
var spend: Callable = func(_g: int) -> bool: return false
## (gold) -> void: a try's gold (Survivor: the host's wallet; the Sandbox: the profile).
var pay: Callable = func(_g: int) -> void: pass
var toast: Callable = func(_text: String) -> void: pass
var save_profile: Callable = func() -> void: Profile.save()
var now: Callable = func() -> float: return Time.get_unix_time_from_system()
## () -> Dictionary: what the child's body does now (InventionTry.feed's sample); the player's own by default.
var sample: Callable = func() -> Dictionary: return _player_sample()
var auto_tick := true

var panel: InventionsPanel
var banner: TryBanner
var trial := InventionTry.new()
## The Sandbox's pick for this session (FlightCrafts.Craft; NONE: the classic flying).
var sandbox_craft: int = FlightCrafts.Craft.NONE

var _done_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


## The book under `ui_parent`, the try's banner under `hud_parent` (null: none; tests).
func setup(ui_parent: Node, hud_parent: Node = null) -> void:
	panel = InventionsPanel.new()
	panel.data = func() -> InventionData: return data
	panel.survivor = func() -> bool: return survivor
	panel.have = func(m: StringName) -> int:
		var inv: Inventory = bag.call()
		return InventionRules.have(m, inv) if inv != null else 0
	panel.gold = gold
	panel.mastered = is_mastered
	panel.near_workbench = near_workbench
	panel.chosen = chosen_craft
	panel.make_pressed.connect(func(id: StringName) -> void: _answer(make(id)))
	panel.try_pressed.connect(func(id: StringName) -> void: _answer(try_it(id)))
	panel.fly_pressed.connect(func(id: StringName) -> void: _answer(fly_with(id)))
	panel.bottle.launch = launch_bottle
	if ui_parent:
		ui_parent.add_child(panel)
	banner = TryBanner.new()
	banner.name = "TryBanner"
	if hud_parent:
		hud_parent.add_child(banner)


func open(id: StringName = &"") -> void:
	if panel:
		panel.open(id)


func close_if_open() -> bool:
	return panel != null and panel.close_if_open()


## I on a PC opens the book (and closes it).
func _unhandled_input(event: InputEvent) -> void:
	if panel == null or not (event is InputEventKey) or not (event as InputEventKey).pressed \
			or (event as InputEventKey).echo or not event.is_action_pressed(&"inventions"):
		return
	if panel.is_open():
		panel.close()
	else:
		open()
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func is_mastered(id: StringName) -> bool:
	return InventionRules.unit_mastered(id, school)


## The flying machine picked now (the book's FLY WITH IT shows it).
func chosen_craft() -> int:
	if survivor:
		var picked := player.chosen_craft if player != null and is_instance_valid(player) else FlightCrafts.Craft.NONE
		return InventionRules.take_off_craft(false, data, picked)
	return sandbox_craft


## MAKE IT: "" when invented (the words say so), else why not.
func make(id: StringName) -> String:
	if not survivor:
		return InventionRules.message("sandbox", id, null)
	if not host:
		return InventionRules.message("guest", id, null)
	var inv: Inventory = bag.call()
	if inv == null:
		return InventionRules.message("guest", id, null)
	var free := is_mastered(id)
	var why := InventionRules.refusal(id, data, inv, bool(near_workbench.call()), int(gold.call()), free)
	if why != "":
		return InventionRules.message(why, id, inv)
	var price := InventionRules.price(id, free)
	if price > 0 and not bool(spend.call(price)):
		return InventionRules.message("gold", id, inv)
	InventionRules.take(id, inv)
	data.add(id)
	save_profile.call()
	var e := InventionLine.entry(id)
	Audio.play(&"fanfare")
	toast.call(Lang.t("You invented %s! %s") % [Lang.t(str(e.name)).to_lower(), Lang.t(str(e.opens))])
	if panel:
		panel.say(Lang.t("Invented! %s") % Lang.t(str(e.opens)))
		panel.refresh()
	changed.emit()
	return ""


## TRY IT: the challenge starts (or stops, pressed again); "" when it runs, else why not.
func try_it(id: StringName) -> String:
	if not InventionLine.has(id):
		return ""
	if survivor and not data.has(id):
		return Lang.t("Invent it first: MAKE IT at a Workbench.")
	if trial.active() and trial.id == id and id != InventionLine.ROCKET:
		stop_try()
		return Lang.t("Stopped. TRY IT again whenever you like!")
	var craft := FlightCrafts.of_invention(id)
	if craft != FlightCrafts.Craft.NONE:
		var no_air := InventionRules.air_refusal(InventionRules.air(Game.universe))
		if no_air != "":
			return no_air
	stop_try()
	trial.start(id)
	_done_t = 0.0
	if id == InventionLine.ROCKET:
		if panel:
			panel.open_bottle()
		return ""
	if banner:
		banner.show_try(StringName(InventionLine.entry(id).picture), trial.goal())
	if player != null and is_instance_valid(player):
		match craft:
			FlightCrafts.Craft.KITE:
				player.hold_kite(true)
			FlightCrafts.Craft.BALLOON, FlightCrafts.Craft.PLANE, FlightCrafts.Craft.JET:
				_pick(craft)
				player.set_physics_mode(PhysicsMode.Mode.FLY)
				if player.physics_mode != PhysicsMode.Mode.FLY:
					stop_try()   # refused (fuel, air): the player's words said why
					return ""
	if panel:
		panel.close()   # the banner says what to do
	ReadAloud.auto(trial.goal())
	return ""


func stop_try() -> void:
	if player != null and is_instance_valid(player) and player.kite_held:
		player.hold_kite(false)
	trial.stop()
	if banner:
		banner.visible = false


## The bottle rocket's LAUNCH (the book's): its height; done at 30 m pays once.
func launch_bottle(pumps: int) -> float:
	if trial.id != InventionLine.ROCKET:
		trial.start(InventionLine.ROCKET)
	var was := trial.done
	var h := trial.launch_bottle(pumps)
	if trial.done and not was:
		_finish(InventionLine.ROCKET)
	return h


## FLY WITH IT (an invention) or FREE FLYING (&""): "" when picked.
func fly_with(id: StringName) -> String:
	var craft := FlightCrafts.of_invention(id)
	if id != &"" and craft == FlightCrafts.Craft.NONE:
		return ""
	if survivor:
		if id == &"" or not data.has(id):
			return Lang.t("Invent it first: MAKE IT at a Workbench.")
		data.craft = id
		save_profile.call()
	_pick(craft)
	if player != null and is_instance_valid(player) and player.physics_mode == PhysicsMode.Mode.FLY:
		player.set_physics_mode(PhysicsMode.Mode.FLY)   # already up: into the new machine now
	if panel:
		panel.refresh()
	if craft == FlightCrafts.Craft.NONE:
		return Lang.t("Free flying: FLY as always.")
	if craft == FlightCrafts.Craft.KITE:
		return Lang.t("Your kite is ready: FLY on a windy hill and it lifts you!")
	return Lang.t("Ready: FLY with %s!") % Lang.t(str(FlightCrafts.NAMES[craft]))


## Where the wind blows now (flat, WIND_SPEED long).
func wind() -> Vector3:
	return FlightCrafts.wind_dir(world_seed, FlightCrafts.wind_slot(float(now.call()))) * FlightCrafts.WIND_SPEED


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


func tick(delta: float) -> void:
	var w := wind()
	if player != null and is_instance_valid(player):
		player.wind = w
	if _done_t > 0.0:
		_done_t -= delta
		if _done_t <= 0.0 and banner:
			banner.visible = false
	if not trial.active() or trial.id == InventionLine.ROCKET:
		return
	var s: Dictionary = sample.call()
	if s.is_empty():
		return
	s["wind"] = w
	trial.feed(s, delta)
	if banner:
		var angle := NAN
		if trial.id == InventionLine.KITE or trial.id == InventionLine.BALLOON:
			angle = _screen_angle(w, float(s.get("yaw", 0.0)))
		banner.follow(trial.progress, trial.hint(), angle)
	if trial.done:
		_finish(trial.id)


func _finish(id: StringName) -> void:
	var gold_now := InventionRules.try_gold(id, data) if host else 0
	if gold_now > 0:
		data.mark_tried(id)
		pay.call(gold_now)
		save_profile.call()
	Audio.play(&"jingle_goal")
	var said := Lang.t(str(InventionLine.entry(id).try_done))
	if gold_now > 0:
		said += " +%d gold!" % gold_now
	elif not host and InventionRules.try_gold(id, data) > 0:
		said += " " + Lang.t("Try it in your own world to earn its gold!")
	toast.call(said)
	if banner:
		banner.follow(1.0, said, NAN)
	if panel and panel.bottle_open():
		panel.say(said)
	if player != null and is_instance_valid(player) and player.kite_held:
		player.hold_kite(false)
	_done_t = DONE_SHOW
	changed.emit()


func _pick(craft: int) -> void:
	if not survivor:
		sandbox_craft = craft
	if player != null and is_instance_valid(player):
		player.chosen_craft = craft


func _answer(text: String) -> void:
	if text != "" and panel and panel.is_open():
		panel.say(text)
	elif text != "":
		toast.call(text)


## The player's body for a try: where it is, its machine, flying or gliding, where the camera looks.
func _player_sample() -> Dictionary:
	if player == null or not is_instance_valid(player) or not player.is_spawned():
		return {}
	var yaw := player.rig.yaw
	return {"pos": player.global_position, "craft": player.flight_craft,
		"flying": player.physics_mode == PhysicsMode.Mode.FLY, "gliding": player.gadget_move == GadgetRules.Move.GLIDE,
		"on_floor": player.is_on_floor(), "facing": Basis(Vector3.UP, yaw) * Vector3.FORWARD, "yaw": yaw}


## The wind's direction on the screen for a camera turned `yaw`: 0 = straight ahead (up), clockwise.
static func _screen_angle(w: Vector3, yaw: float) -> float:
	var local := Basis(Vector3.UP, yaw).inverse() * Vector3(w.x, 0.0, w.z)
	if Vector2(local.x, local.z).length() < 0.001:
		return NAN
	return atan2(local.x, -local.z)
