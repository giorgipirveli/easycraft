class_name DiscoveryDirector
extends Node
## Owner #132 (W1; docs/devlog/parts/play-w1.md): learning inside the world (node "Discovery" of the sandbox), beside
## Life Town's director. Stage 1:
## - **DISCOVER** (MORE's picture button, more_button(); the pause menu's, which asks open_discover): the School over the
##   world (DiscoverPanel), and the world again after; while it shows the child's avatar is held still and kept safe
##   (take_over, keep_safe: the sandbox's, as for Life Town's practice rooms).
## - **Professor Hoot's invitation** (HootCard): once the child has stood in a home world for DiscoveryRules.HOOT_AFTER
##   seconds with no menu over it, on the world's first visit (and in a world seen before at most once a day:
##   DiscoveryRules.hoot_due, remembered on this device by DiscoveryLog), Hoot pops in and says his line by himself
##   (owner #133); DISCOVER on his card opens the School. In a headset (the HUD hides while playing, owner #127) his line
##   goes on the toast strip (`toast`) and is spoken.
## Stage 2 (owner #133, #134):
## - **The discovery crystal** (DiscoveryCrystal, under `world_parent`; its rules DiscoveryCrystalRules): after a few
##   minutes of play in a home world (not busy, nothing over the world, a grown-up's switch), a crystal rises near the
##   child with a chime and a spoken line; walking up to it, tapping it (`tap`: the sandbox's interactor asks first) or a
##   hand in a headset starts its play (DiscoveryPlays.pick: real play from the child's own learning, never a written
##   question; DiscoveryChallenge: the rules); the strip (DiscoveryStrip) shows the goal as numbers or a picture with a
##   speaker and a cross. Each challenge solved with no miss pays the School's answer gold (EarnRules, its daily cap).
##   Untouched, it fades; walking away, a fight, the cross or the School opening end the play quietly. What it played
##   (and a unit with no real play yet: its play debt) is kept on the device (DiscoveryLog, "crystals").
## Everything here is this device's own: nothing goes over the network (a guest's Hoot, School and crystal are its own).

signal crystal_finished(result: Dictionary)

## The pause and the panel's own clock (tests drive step()).
const SAFE_EVERY := 1.0
## Seconds between a challenge solved and the next one showing (the flash and the sparkle first).
const NEXT_PAUSE := 1.2
## Play G0 (merged): a crystal's short round in G0's play place (about a minute: 3-5 challenges).
const CRYSTAL_ROUND := 4
## When no ground is found for a crystal, look again this many seconds later.
const RETRY := 10.0
const MADE_LINE := "Yes! %s!"
const MADE_ORDER_LINE := "Yes! Smallest to biggest!"
const MISS_MAKE_LINE := "Too far! Try another one."
const MISS_ORDER_LINE := "Find a smaller one!"
const DONE_LINE := "Well done, discoverer!"

## Stage 2: the crystal now (null when none), its play (null while it waits), the strip.
var crystal: DiscoveryCrystal
var challenge: DiscoveryChallenge
var strip: DiscoveryStrip
var world_parent: Node3D           # where a crystal stands (the sandbox)
var block_at := Callable()         # (Vector3i) -> int: the world's block
var player_feet := Callable()      # () -> Vector3: the local player's feet (INF while not spawned)
var player_yaw := Callable()       # () -> float: where the child faces
var busy := Callable()             # () -> bool: a fight, a race, a round, riding, flying, sleeping: no crystal
var hand_points := Callable()      # () -> Array[Vector3]: a headset's hands (none off VR)
var next_seed := Callable()        # () -> int
## Stage 3: the world's Discovery Academy (its placer: null where none) and the card of a door with no game yet.
var academy: AcademyPlacer
var academy_card: AcademyCard
var _door := ""   # the Academy door the child stands at
## Play G0's place while a crystal's or a door's round plays in it (PlayHost: far above the world, its own camera; the
## world's HUD layer hides), else null; `play_holder`: where it opens (a Control in the HUD's layer).
var place: PlayHost
var play_holder: Control
## (unit id) -> bool: the unit plays without reading in G0's place (DiscoveryPlays.g0_plays; tests set theirs).
var unit_plays := Callable()
var _place_crystal := false   # the place is a crystal's (its end takes the crystal); else a door's
## Hoot himself, flying in to the child while his invitation shows (null when he is not here).
var hoot_flyer: HootFlyer
var _flyer_wait := -1.0   # a headset (no card): seconds until he flies off

var panel: DiscoverPanel
var hoot: HootCard
var log: DiscoveryLog
## The world this is (DiscoveryRules.world_key) and whether Hoot comes to it (a home world).
var world_key := ""
var hoot_on := false
var profile: ProfileData = null   # tests give theirs; the game's own otherwise
var save_profile := Callable()
var today := Callable()            # () -> int: the day (SchoolClock.today)
var player_ready := Callable()     # () -> bool: the child stands in the world
var overlay_open := Callable()     # () -> bool: a menu or a panel covers the screen
var keep_safe := Callable()        # () -> void: the avatar safe a moment (the sandbox: health.protect)
var take_over := Callable()        # (on: bool) -> void: hold the avatar still while the School shows
var toast := Callable()            # (text: String, seconds: float) -> void: the HUD's toast (a headset's toast strip)
var in_vr := Callable()            # () -> bool: a headset session (Vr.active)

var _stood := 0.0
var _hoot_done := false
var _taken := false
var _safe_wait := 0.0
var _pick := {}
var _play := 0.0          # seconds of play towards the next crystal
var _first_crystal := true
var _waited := 0.0        # seconds the crystal has waited untouched
var _next_in := -1.0      # seconds until the next challenge shows (after one solved)
var _hands_in := {}       # hand index -> the gem it is touching (a hand takes a gem once each time it comes)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Makes the panel and Hoot's card under `ui_parent` (the HUD's layer) for world `key`; `hoot_comes`: a home world.
func setup(ui_parent: Node, key: String, hoot_comes: bool) -> void:
	world_key = key
	hoot_on = hoot_comes
	if log == null:
		log = DiscoveryLog.new()
	if not today.is_valid():
		today = SchoolClock.today
	if not in_vr.is_valid():
		in_vr = Vr.active
	panel = DiscoverPanel.new()
	panel.profile = profile
	panel.save_profile = save_profile
	hoot = HootCard.new()
	hoot.discover_pressed.connect(open_discover)
	hoot.gone.connect(_hoot_leaves)
	strip = DiscoveryStrip.new()
	strip.left.connect(func() -> void: _end(false))
	academy_card = AcademyCard.new()
	play_holder = Control.new()
	play_holder.name = "PlayPlace"
	play_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unit_plays.is_valid():
		unit_plays = DiscoveryPlays.g0_plays
	if not next_seed.is_valid():
		next_seed = func() -> int: return randi()
	if ui_parent:
		ui_parent.add_child(strip)
		ui_parent.add_child(play_holder)
		ui_parent.add_child(academy_card)
		ui_parent.add_child(hoot)
		ui_parent.add_child(panel)


## DISCOVER: Hoot's card goes away. With no subject (MORE's, the pause menu's, Hoot's card) it starts a game at once,
## Hoot's pick (owner #133, the lead on the emulator, 2026-10-18: the School's map is a grid of written lesson titles a
## child who does not read cannot choose from): a review due, else the next unit that plays without reading
## (DiscoveryPlays.pick), a whole round in G0's place. The School over the world (on `subject`'s map, or Life:
## DiscoverPanel.LIFE) opens for a subject, and when nothing in the grade plays yet.
func open_discover(subject: String = "") -> void:
	if hoot:
		hoot.hide_card()
	if playing():
		_end(false)   # a crystal's play ends quietly: the School is over the world now
	if not _hoot_done and hoot_on and log != null:   # the child found DISCOVER: no invitation needed today
		log.state = DiscoveryRules.after_hoot(log.state, world_key, int(today.call()))
		log.save()
	_hoot_done = true
	if subject == "" and place == null:
		var pick := DiscoveryPlays.pick(_profile(), int(today.call()), int(next_seed.call()), unit_plays)
		if bool(pick.get("place", false)) and _open_place(str(pick.unit), 0, false, DiscoveryRules.PICK_LINE):
			return
	panel.open(subject)


## MORE's DISCOVER: the HUD's picture button (a magnifying glass), its word spoken when a pointer comes over it.
func more_button() -> TouchButton:
	var b := TouchButton.new()
	b.name = "Discover"
	b.text = DiscoveryRules.DISCOVER_LABEL
	b.symbol = &"discover"
	b.ready.connect(func() -> void: b.mouse_filter = Control.MOUSE_FILTER_PASS)   # TouchButton ignores the mouse itself
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.mouse_entered.connect(func() -> void: PlayVoice.say(DiscoveryRules.DISCOVER_WORD))
	b.pressed.connect(func() -> void: open_discover())
	return b


## What covers the world's look area while it shows (the panel; Hoot's card and the crystal's strip themselves).
func blockers() -> Array[Control]:
	var out: Array[Control] = []
	if panel:
		out.append_array(panel.blockers())
	if hoot:
		out.append_array(hoot.blockers())
	if strip:
		out.append_array(strip.blockers())
	if academy_card:
		out.append_array(academy_card.blockers())
	return out


## Android Back: true when DISCOVER took it (the panel closed, or a practice room's own card takes it).
func close_if_open() -> bool:
	return panel != null and panel.close_if_open()


func _process(delta: float) -> void:
	step(delta)


## One tick of `delta` seconds (tests call it with their own time).
func step(delta: float) -> void:
	_hold_while_open(delta)
	_wait_for_hoot(delta)
	if _flyer_wait >= 0.0:   # a headset: Hoot leaves after his line's while
		_flyer_wait -= delta
		if _flyer_wait < 0.0:
			_hoot_leaves()
	_follow_doors()
	_step_crystal(delta)


func _hold_while_open(delta: float) -> void:
	var open := (panel != null and panel.is_open()) or place_open()
	if open != _taken:
		_taken = open
		if take_over.is_valid():
			take_over.call(open)
		_safe_wait = 0.0
	if not open:
		return
	_safe_wait -= delta
	if _safe_wait <= 0.0:
		_safe_wait = SAFE_EVERY
		if keep_safe.is_valid():
			keep_safe.call()


func _wait_for_hoot(delta: float) -> void:
	if _hoot_done or not hoot_on:
		return
	if player_ready.is_valid() and not bool(player_ready.call()):
		return
	if (overlay_open.is_valid() and bool(overlay_open.call())) or (panel != null and panel.is_open()):
		return
	_stood += delta
	if _stood < DiscoveryRules.HOOT_AFTER:
		return
	_hoot_done = true
	var day := int(today.call())
	if not DiscoveryRules.hoot_due(log.state, world_key, day):
		return
	log.state = DiscoveryRules.after_hoot(log.state, world_key, day)
	log.save()
	_hoot_arrives()
	if bool(in_vr.call()):
		if toast.is_valid():
			toast.call(DiscoveryRules.HOOT_LINE_VR, 8.0)
		PlayVoice.say(DiscoveryRules.HOOT_LINE_VR)
		_flyer_wait = DiscoveryRules.HOOT_STAYS
	else:
		hoot.show_line(DiscoveryRules.HOOT_LINE)


## Hoot flies in out of the sky and lands near the child (dry ground a few metres off), when there is such ground.
func _hoot_arrives() -> void:
	if world_parent == null or not block_at.is_valid() or not player_feet.is_valid():
		return
	var feet: Vector3 = player_feet.call()
	if not feet.is_finite():
		return
	var at := DiscoveryCrystalRules.spot_near(feet, float(player_yaw.call()) if player_yaw.is_valid() else 0.0, block_at)
	if not at.is_finite():
		return
	hoot_flyer = HootFlyer.new()
	world_parent.add_child(hoot_flyer)
	hoot_flyer.fly_in(at, feet)


## Hoot flies off to the Academy's top (or up and away where there is none).
func _hoot_leaves() -> void:
	_flyer_wait = -1.0
	if hoot_flyer == null or not is_instance_valid(hoot_flyer):
		hoot_flyer = null
		return
	var to := hoot_flyer.landing + Vector3(0, 30, 0) + Vector3(sin(float(_stood)), 0, cos(float(_stood))) * 20.0
	if academy != null and is_instance_valid(academy) and academy.stood and academy.buildings != null:
		var y := float((academy.site.pos as Vector3i).y) + float(academy.buildings.floors.get("tower", 0.0)) \
			+ AcademyBuildings.TOWER_TOP + AcademyBuildings.PEDESTAL
		to = LifeTown.to_world_point(academy.site, Vector2(0, 1.2), y)   # beside the Hoot statue, on the pedestal
	hoot_flyer.fly_away(to)
	hoot_flyer = null


# --- Stage 2: the discovery crystal --------------------------------------------------------------------------------

## A crystal's play is running.
func playing() -> bool:
	return (crystal != null and challenge != null) or place_open()


## G0's play place is open (a crystal's or a door's round).
func place_open() -> bool:
	return place != null and is_instance_valid(place) and not place.closed


## A tap (or the headset's trigger) along the ray (origin, dir), before the world's own: true when the crystal took it
## (it starts the play; during the play every tap is the play's: a gem, or nothing, never a block built behind it).
func tap(origin: Vector3, dir: Vector3) -> bool:
	if crystal == null or not is_instance_valid(crystal) or crystal.phase == DiscoveryCrystal.GOING:
		return false
	if challenge == null:
		if not crystal.body_hit(origin, dir):
			return false
		_start()
		return true
	var i := crystal.gem_hit(origin, dir)
	if i >= 0:
		_take(i)
	return true


func _step_crystal(delta: float) -> void:
	if is_inside_tree() and get_tree().paused:
		return   # the pause menu: the crystal waits too
	if crystal != null and not is_instance_valid(crystal):
		crystal = null
		challenge = null
	if place_open():
		return   # the child plays in G0's place: the world waits (the avatar held and kept safe)
	if crystal == null:
		_wait_for_crystal(delta)
		return
	if challenge == null:
		_waited += delta
		if not _busy() and _touched():
			_start()
		elif _waited >= DiscoveryCrystalRules.WAIT_SECONDS:
			_end(false)   # untouched: it fades, nothing lost
		return
	if _busy() or _far():
		_end(false)   # a fight, a race, walking away: quietly, nothing lost
		return
	_hands_take()
	if _next_in >= 0.0:
		_next_in -= delta
		if _next_in < 0.0:
			_show_next()


func _wait_for_crystal(delta: float) -> void:
	if not hoot_on or world_parent == null or not block_at.is_valid() or not player_feet.is_valid():
		return
	if not DiscoveryCrystalRules.switched_on(_profile().settings):
		return
	if _busy() or (overlay_open.is_valid() and bool(overlay_open.call())) or (panel != null and panel.is_open()):
		return
	if player_ready.is_valid() and not bool(player_ready.call()):
		return
	_play += delta
	if DiscoveryCrystalRules.due(_play, _first_crystal):
		_spawn()


func _spawn() -> void:
	var feet: Vector3 = player_feet.call()
	if not feet.is_finite():
		return
	var yaw := float(player_yaw.call()) if player_yaw.is_valid() else 0.0
	var at := DiscoveryCrystalRules.spot_near(feet, yaw, block_at)
	if not at.is_finite():
		_play -= RETRY   # no dry, open ground near: look again a little later
		return
	_spawn_at(at)
	var crystals := _crystal_log()
	var met := bool(crystals.get("met", false))
	PlayVoice.say(DiscoveryCrystalRules.ARRIVE_LINE if met else DiscoveryCrystalRules.HOOT_CRYSTAL_LINE)
	if not met:
		crystals["met"] = true
		log.save()


func _spawn_at(at: Vector3) -> void:
	crystal = DiscoveryCrystal.new()
	world_parent.add_child(crystal)
	crystal.global_position = at
	crystal.rise()
	challenge = null
	_waited = 0.0


## The child walks up to the waiting crystal, or a hand in a headset touches it.
func _touched() -> bool:
	var feet: Vector3 = player_feet.call() if player_feet.is_valid() else Vector3.INF
	if feet.is_finite():
		var p := crystal.global_position
		if Vector2(feet.x - p.x, feet.z - p.z).length() <= DiscoveryCrystalRules.TOUCH and absf(feet.y - p.y) <= 2.5:
			return true
	for h: Vector3 in _hands():
		if crystal.body_near(h, DiscoveryCrystalRules.HAND_TOUCH):
			return true
	return false


## The crystal's play starts (`said`: words spoken before the challenge: an Academy door's name).
func _start(said: String = "") -> void:
	_pick = DiscoveryPlays.pick(_profile(), int(today.call()), int(next_seed.call()), unit_plays)
	if not bool(_pick.own) and str(_pick.wanted) != "":   # owner #134: the unit had no real play yet: noted
		var crystals := _crystal_log()
		if not crystals.get("debt") is Dictionary:
			crystals["debt"] = {}
		var debt: Dictionary = crystals["debt"]
		debt[str(_pick.wanted)] = int(debt.get(str(_pick.wanted), 0)) + 1
		log.save()
	if bool(_pick.get("place", false)) and _open_place(str(_pick.unit), CRYSTAL_ROUND, true, said):
		crystal.on_made()   # it flashes as the child goes in
		return
	if not _pick.has("challenges"):
		_pick = DiscoveryPlays.pick(_profile(), int(today.call()), int(next_seed.call()),
			func(_id: String) -> bool: return false)   # the place had nothing after all: the crystal's own play
	challenge = DiscoveryChallenge.new(_pick.challenges)
	_hands_in.clear()
	_next_in = -1.0
	_show(challenge.current(), said)


func _show(c: Dictionary, said: String = "") -> void:
	var feet: Vector3 = player_feet.call() if player_feet.is_valid() else Vector3.INF
	if not feet.is_finite():
		feet = crystal.global_position + Vector3.BACK
	var yaw := float(player_yaw.call()) if player_yaw.is_valid() else 0.0
	crystal.show_challenge(c, feet, _held(c), Vector3(cos(yaw), 0.0, -sin(yaw)))   # the view's right
	strip.show_for(c)
	PlayVoice.say((said + " " if said != "" else "") + str(c.say))


func _held(c: Dictionary) -> String:
	return DiscoveryPlays.number(challenge.total, int(c.get("scale", 1))) if str(c.kind) == "make" else ""


func _take(i: int) -> void:
	if _next_in >= 0.0 or challenge.state() == DiscoveryChallenge.DONE:
		return   # between challenges: the flash first
	var c := challenge.current()
	var r := challenge.take(i)
	if r == DiscoveryChallenge.BOUNCED:
		crystal.on_bounced(i, challenge.shown_hint())
		PlayVoice.say(MISS_MAKE_LINE if str(c.kind) == "make" else MISS_ORDER_LINE)
		return
	crystal.on_taken(i, c, _held(c), challenge.taken)
	if r != DiscoveryChallenge.MADE:
		return
	crystal.on_made()
	if str(c.kind) == "make":
		PlayVoice.say(MADE_LINE % DiscoveryPlays.spoken(int(c.target), int(c.scale)))
	else:
		PlayVoice.say(MADE_ORDER_LINE)
	if challenge.misses == 0:   # right the first time: the School's answer gold, within its daily cap
		if EarnRules.answer_gold(_profile(), int(today.call())) > 0 and save_profile.is_valid():
			save_profile.call()
	_next_in = NEXT_PAUSE


func _show_next() -> void:
	if challenge.next():
		_hands_in.clear()
		_show(challenge.current())
	else:
		_finish()


func _finish() -> void:
	var result := {"unit": str(_pick.get("unit", "")), "wanted": str(_pick.get("wanted", "")),
		"own": bool(_pick.get("own", false)), "kind": str(_pick.get("kind", "")), "first_try": challenge.first_try,
		"challenges": challenge.challenges.size()}
	var crystals := _crystal_log()
	crystals["played"] = int(crystals.get("played", 0)) + 1
	crystals["last"] = {"day": int(today.call()), "unit": result.unit, "kind": result.kind,
		"first_try": result.first_try}
	log.save()
	PlayVoice.say(DONE_LINE)
	crystal_finished.emit(result)
	_end(true)


## The crystal goes (`celebrate`: its play was finished); the next one waits EVERY_SECONDS of play.
func _end(celebrate: bool) -> void:
	if crystal != null and is_instance_valid(crystal):
		crystal.go(celebrate)
	crystal = null
	challenge = null
	_pick = {}
	if strip:
		strip.hide_strip()
	_play = 0.0
	_first_crystal = false
	_waited = 0.0
	_next_in = -1.0
	_hands_in.clear()


## A headset's hands take the gems they touch (once each time a hand comes to one).
func _hands_take() -> void:
	var hands := _hands()
	for k in hands.size():
		if crystal == null or challenge == null:
			return
		var i := crystal.gem_near(hands[k], DiscoveryCrystalRules.HAND_TOUCH)
		if i >= 0 and int(_hands_in.get(k, -1)) != i:
			_take(i)
		_hands_in[k] = i


func _hands() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if hand_points.is_valid():
		out.assign(hand_points.call())
	return out


func _far() -> bool:
	var feet: Vector3 = player_feet.call() if player_feet.is_valid() else Vector3.INF
	return feet.is_finite() and feet.distance_to(crystal.global_position) > DiscoveryCrystalRules.LEAVE


func _busy() -> bool:
	return busy.is_valid() and bool(busy.call())


func _profile() -> ProfileData:
	return profile if profile != null else Profile.data


## The crystals' part of the device's log ({"met", "played", "debt": {unit: n}, "last"}).
func _crystal_log() -> Dictionary:
	if log == null:
		log = DiscoveryLog.new("")
	var c: Variant = log.state.get("crystals")
	if not c is Dictionary:
		c = {}
		log.state["crystals"] = c
	return c


# --- Stage 3: the Discovery Academy's doors ------------------------------------------------------------------------

## Walking up to a door says its name and opens it (AcademyPlaza.opens): Maths its real play at the door, Life Life, the
## rest the calm "coming soon" card; walking away puts the card away. A door opens again only after walking away.
func _follow_doors() -> void:
	if academy == null or not is_instance_valid(academy) or not academy.stood or not player_feet.is_valid():
		return
	if place_open():
		return   # the child plays in G0's place: no other door opens meanwhile
	var feet: Vector3 = player_feet.call()
	var covered := (overlay_open.is_valid() and bool(overlay_open.call())) or (panel != null and panel.is_open())
	var door := "" if covered and _door == "" else academy.near(feet)
	if door == _door:
		return
	_door = door
	if academy_card.visible and academy_card.door != door:
		academy_card.hide_card()
	if door == "":
		return
	_mark_visited()
	var name_line := "%s!" % str(AcademyPlaza.SPOTS[door].name)
	match AcademyPlaza.opens(door):
		AcademyPlaza.PLAY:
			_door_play(door, name_line)
		AcademyPlaza.LIFE:
			if hoot:
				hoot.hide_card()
			if playing():
				_end(false)
			panel.open(DiscoverPanel.LIFE, "%s Let's discover!" % name_line)
		_:
			academy_card.show_door(door)


## A subject's door: a whole round of the subject's unit that plays without reading (DiscoveryPlays.subject_unit) in
## G0's place; none yet: the calm "coming soon" card. A crystal's play running ends quietly first.
func _door_play(door: String, name_line: String) -> void:
	var unit := DiscoveryPlays.subject_unit(_profile(), str(AcademyPlaza.SPOTS[door].subject), int(today.call()), unit_plays)
	if unit == "":
		academy_card.show_door(door)
		return
	if hoot:
		hoot.hide_card()
	if playing() or crystal != null:
		_end(false)
	if not _open_place(unit, 0, false, name_line):
		academy_card.show_door(door)


## The HUD's compass: the Academy's nearest door until the child has been to one in this world ({} after, or none).
func compass_target(from: Vector3) -> Dictionary:
	if academy == null or not is_instance_valid(academy) or not academy.stood or _visited():
		return {}
	if bool(academy.site.get("island", false)) or not from.is_finite():
		return {}
	var best := Vector3.INF
	for door: String in AcademyPlaza.DOORS:
		var p := academy.door_position(door)
		if not best.is_finite() or p.distance_to(from) < best.distance_to(from):
			best = p
	return {"chest": Vector3i(best.floor())} if best.is_finite() else {}


func _visited() -> bool:
	var a: Variant = log.state.get("academy") if log != null else null
	return a is Dictionary and bool((a as Dictionary).get(world_key, false))


func _mark_visited() -> void:
	if _visited() or log == null:
		return
	if not log.state.get("academy") is Dictionary:
		log.state["academy"] = {}
	(log.state["academy"] as Dictionary)[world_key] = true
	log.save()



# --- Play G0's place: a crystal's short round, a door's whole round ------------------------------------------------

## Opens G0's play place on `unit` (`count` challenges; 0: a whole round) under `play_holder` (the world's HUD layer
## hides while it shows); `crystal_round`: its end takes the crystal; `said`: spoken first (a door's name). The
## outcome records through SkillShown as the School's PLAY does. False when the unit had nothing to play after all.
## Owner #133, #134 (PlaySignature): the unit's deep game opens its own host (a whole voyage, whatever `count`), else
## G0's place; `params` (a deep game's `then`: the leaf's next voyage) change the play block's for this time only.
func _open_place(unit: String, count: int, crystal_round: bool, said: String = "", params: Dictionary = {}) -> bool:
	var prof := _profile()
	var day := int(today.call())
	var content := Curriculum.content(unit)
	if not params.is_empty():
		content = PlaySignature.with_params(content, params)
	var host := PlaySignature.make_host(content)
	host.setup(unit, content, int(next_seed.call()), MasteryRules.stars(prof.school.progress(unit)),
		Curriculum.unit(unit), count)
	if host.loop != null and host.loop.challenges.is_empty():   # a deep game's host has no exercise loop
		host.free()
		return false
	host.first_try_gold = func() -> int: return SkillShown.pay_first_try(prof, day)
	host.finished.connect(_on_place_finished)
	host.stopped.connect(_on_place_stopped)
	host.finished.connect(func(o: Dictionary) -> void:   # recorded first; then the game's next (`then`)
		var then := PlaySignature.then_of(o)
		if not then.is_empty():
			_open_place.call_deferred(unit, 0, false, "", then))
	place = host
	_place_crystal = crystal_round
	if strip:
		strip.hide_strip()
	if said != "":
		PlayVoice.say(said)
	host.open(play_holder if play_holder != null and play_holder.is_inside_tree() else self)
	return true


func _on_place_finished(outcome: Dictionary) -> void:
	var prof := _profile()
	var shown: Variant = outcome.get("shown")
	if shown is SkillShown:
		(shown as SkillShown).record(prof, int(today.call()), save_profile)
	elif save_profile.is_valid():
		save_profile.call()
	var was_crystal := _place_crystal
	var unit := place.unit_id if place != null and is_instance_valid(place) else str(_pick.get("unit", ""))
	place = null
	_place_crystal = false
	if not was_crystal:
		return
	var result := {"unit": unit, "wanted": str(_pick.get("wanted", "")), "own": bool(_pick.get("own", false)),
		"kind": "g0", "first_try": int(outcome.get("right_first", 0)), "challenges": int(outcome.get("total", 0))}
	var crystals := _crystal_log()
	crystals["played"] = int(crystals.get("played", 0)) + 1
	crystals["last"] = {"day": int(today.call()), "unit": unit, "kind": "g0", "first_try": result.first_try}
	log.save()
	PlayVoice.say(DONE_LINE)
	crystal_finished.emit(result)
	_end(true)


## STOP FOR NOW in the place: nothing recorded (the answers' gold is kept); a crystal goes quietly.
func _on_place_stopped(_outcome: Dictionary) -> void:
	if save_profile.is_valid():
		save_profile.call()
	var was_crystal := _place_crystal
	place = null
	_place_crystal = false
	if was_crystal:
		_end(false)
