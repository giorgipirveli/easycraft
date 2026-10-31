class_name GlowWondersDirector
extends Node
## Universe 6, the Glow Caves: the Cave Wonders played by this game's own child (owner #122, docs/design/learning-is-play.md
## §3; the rules GlowWonderRules, the places and their rock GlowWonders). The sandbox adds one ("GlowWonders") on every
## game of a Glow Caves world, as SpaceSights. A few times a second it looks up the wonders round the child: near one it
## makes its tap spots (WonderThing) and its looks (GlowWonderLooks), and the first time this visit it says the wonder's
## problem (its hook, never its answer) and puts it on MY MAP. The plays:
## - Glow-worm Grotto: standing in it dark (no lamp in hand, none near) and quiet (still or crouch-walking) brightens the
##   worms; bright for a moment, their threads show the way to the nearest buried chest (the compass too).
## - Drip Stone: a drop falls from the stalactite every DROP_EVERY; a tap on the stump as it lands catches it (once a
##   drop); every DROPS_PER_STEP drops a flowstone step grows towards the pearls' ledge.
## - Echo Fork: a tap on the bat roost clicks; each tunnel's echo comes back after its own delay (a click at its mouth,
##   a glint on its crystal); tapping the crystal of the latest echo opens the long tunnel to its pocket of pearls.
## - Rain Carver: a tap on the basin scoops rainwater, a tap on the wall pours it: limestone fizzes and dissolves after
##   POURS_TO_OPEN pours (the pocket of pearls behind it), granite never does.
## - Blind Fish Lake: the lamp stone's light means nothing to the pale fish; taps on the ripple stone make ripples, and
##   after RIPPLES_NEEDED the fish nudge the lake's pearl ashore.
## A play won says the world's cheer and its real fact (GlowWonderRules.win_words), pays fixed gold once (REWARD_GOLD at
## the universe's scale; never random), opens its Cave Book page and is kept with the world (SecretState.found,
## "wonder:<id>"). Two sights say their fact once per world, no gold: the first crystal hall stood in, and a long walk
## under the roof (LONGEST_WALK). Changes to the world (a step, the plug, the door, the pearl) are the host's: a guest's
## director asks the host's (_rpc_change, checked against the wonder's own cells). Nothing personal is kept or sent.

## A play was won (its wonder's id and kind).
signal wonder_solved(id: String, kind: StringName)

const W := preload("res://core/rules/glow_wonder_rules.gd")
const LOOK_EVERY := 0.25          # the wonders round the child are looked up this often
const NEAR := 26.0                # tap spots and looks for wonders this close ...
const FAR := 40.0                 # ... and gone beyond this
const HOOK_NEAR := 9.0            # the problem is said this close
const SIGHT_EVERY := 0.5
const HALL_FEET := 4              # feet this near a crystal hall's floor find it
const UNDER_ROOF := 3             # this far under the roof (and not in a shaft) is in the caves: the long walk
const QUIET := 5.0                # a gentle word (a missed drop, the wrong crystal) at most this often
const COMPASS_EVERY := 1.0
const COMPASS_REACH := 220.0
const HINT_REACHED := 3.0
const SOUND_NEAR := 14.0          # the drips' plinks are heard this close
const FISH := 3
const FISH_RING := 1.6
const FISH_GATHER := 4.0          # seconds the fish stay by a ripple
const PREFIX := "wonder:"
const PARTS: Array[StringName] = [&"step", &"plug", &"door", &"pearl"]

var wonders: GlowWonders
## The world's found secrets (SecretState.found): solved wonders and found sights go in as "wonder:<id>".
var found := {}
var universe := 6
## () -> Vector3: this game's player's feet (INF when there is none).
var player_position: Callable
## () -> float: how far away the child is heard (StealthDirector.local_noise).
var noise: Callable
## () -> bool: a lamp in hand or a light block near (the worms dim).
var holds_light: Callable
## (text, seconds) -> void: the HUD's toast.
var toast: Callable
## Owner #133/#134: () -> bool, the play's voice is on (PlayVoice.on), and (text) -> void, it says the words
## (PlayVoice.say): then the screen keeps only a few words.
var voice_on: Callable
var speak: Callable
## (gold) -> void: this child's wallet (Survivor through the host, the Sandbox's profile).
var pay: Callable
## (kind) -> void: the Cave Book's page (the profile's WonderData.find_cave).
var book: Callable
## (pos: Vector3i) -> int, and the host's (pos, id) -> void.
var block_at: Callable
var set_block: Callable
## (entry {id, kind, name, pos}) -> void: MY MAP (PlacesDirector.mark).
var mark: Callable
## (from: Vector3) -> Vector3: the nearest buried chest not opened (INF: none): where the worms' threads point.
var nearest_chest: Callable
## Off in tests (they call tick()).
var auto_tick := true

var _now := 0.0
var _look_t := 0.0
var _sight_t := 0.0
var _st := {}                     # wonder id -> its play's state (this visit)
var _carrying := false            # a scoop of rainwater in hand
var _walked := 0.0
var _last := Vector3.INF
var _hint := Vector3.INF
var _compass := {}
var _compass_t := -INF
var _root := Node3D.new()


func _ready() -> void:
	_root.name = "Looks"
	add_child(_root)


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


func tick(delta: float) -> void:
	if wonders == null or not player_position.is_valid():
		return
	_now += delta
	var at: Vector3 = player_position.call()
	if not at.is_finite():
		_last = Vector3.INF
		return
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = LOOK_EVERY
		_look(at)
	for id: String in _st:
		var s: Dictionary = _st[id]
		if not s.active:
			continue
		match StringName(s.w.kind):
			W.GROTTO:
				_grotto_tick(s, at, delta)
			W.DRIP:
				_drip_tick(s, at)
			W.ECHO:
				_echo_tick(s)
			W.LAKE:
				_lake_tick(s, delta)
	_walk(at)
	_sight_t -= delta
	if _sight_t <= 0.0:
		_sight_t = SIGHT_EVERY
		_crystals(at)


# --- What tests and the HUD ask -------------------------------------------------------------------------------------

func is_solved(id: String) -> bool:
	return found.has(PREFIX + id)


func worm_glow(id: String) -> float:
	return float(_st[id].glow) if _st.has(id) else W.WORM_REST


## Seconds into this visit's drip at the drip stone `id` (its drops fall from 0).
func drip_time(id: String) -> float:
	return _now - float(_st[id].t0) if _st.has(id) else 0.0


func drops(id: String) -> int:
	return int(_st[id].drops) if _st.has(id) else 0


## The tunnels whose echoes came back since the last click, in the order heard.
func echoes_heard(id: String) -> Array[int]:
	var out: Array[int] = []
	if _st.has(id):
		out.assign(_st[id].heard)
	return out


func carrying() -> bool:
	return _carrying


func fish_called(id: String) -> bool:
	return _st.has(id) and bool(_st[id].called)


func things() -> Array[WonderThing]:
	var out: Array[WonderThing] = []
	for n in _root.get_children():
		if n is WonderThing:
			out.append(n)
	return out


## The HUD's compass: the worms' way to a chest after a grotto, else the nearest wonder not solved yet ({} for none).
func compass_target(from: Vector3) -> Dictionary:
	if _hint.is_finite():
		if Vector2(from.x - _hint.x, from.z - _hint.z).length() > HINT_REACHED:
			return {"chest": Vector3i(_hint.floor())}
		_hint = Vector3.INF
	if _now - _compass_t < COMPASS_EVERY:
		return _compass
	_compass_t = _now
	_compass = {}
	var best := INF
	var a0 := SecretRules.area_of(floori(from.x - COMPASS_REACH), floori(from.z - COMPASS_REACH))
	var a1 := SecretRules.area_of(floori(from.x + COMPASS_REACH), floori(from.z + COMPASS_REACH))
	var here := Vector2(from.x, from.z) / SecretRules.AREA
	var unknown := Vector2i.MAX
	for az in range(a0.y, a1.y + 1):
		for ax in range(a0.x, a1.x + 1):
			var area := Vector2i(ax, az)
			var got: Variant = wonders.known(area)
			if got == null:   # worked out one area a look at most (a phone's frame), the nearest first
				if unknown == Vector2i.MAX or (Vector2(area) + Vector2(0.5, 0.5)).distance_to(here) \
						< (Vector2(unknown) + Vector2(0.5, 0.5)).distance_to(here):
					unknown = area
				continue
			var w: Dictionary = got
			if w.is_empty() or is_solved(w.id):
				continue
			var d := Vector2(w.anchor.x + 0.5 - from.x, w.anchor.z + 0.5 - from.z).length()
			if d <= COMPASS_REACH and d < best:
				best = d
				_compass = {"chest": w.anchor as Vector3i}
	if unknown != Vector2i.MAX:
		wonders.wonder_in_area(unknown)
		_compass_t = _now - COMPASS_EVERY * 0.75   # the next area soon, until all round are known
	return _compass


# --- The wonders round the child ------------------------------------------------------------------------------------

func _look(at: Vector3) -> void:
	for w: Dictionary in wonders.wonders_near(at, NEAR):
		var s := _state(w)
		if not s.active:
			_activate(s)
		var c: Vector3i = w.anchor
		if not s.hooked and not is_solved(w.id) and Vector2(at.x - c.x - 0.5, at.z - c.z - 0.5).length() <= HOOK_NEAR:
			s.hooked = true
			_say(str(W.HOOKS.get(w.kind, "")), 7.0, W.name_of(w.kind))
			if mark.is_valid():
				mark.call({"id": str(w.id), "kind": &"sight", "name": tr(W.name_of(w.kind)), "pos": Vector3(c)})
	for id: String in _st:
		var s: Dictionary = _st[id]
		var c: Vector3i = s.w.anchor
		if s.active and Vector2(at.x - c.x - 0.5, at.z - c.z - 0.5).length() > FAR:
			_deactivate(s)


func _state(w: Dictionary) -> Dictionary:
	var id: String = w.id
	if _st.has(id):
		return _st[id]
	var s := {"w": w, "active": false, "hooked": false, "t0": _now, "glow": W.WORM_REST, "held": 0.0, "level": -1,
		"drops": 0, "last_drop": -1, "grown": 0, "quiet": -INF, "heard": [] as Array[int], "pending": [],
		"pours": 0, "ripples": 0, "called": is_solved(id), "ripple_t": -INF, "lamp_said": false, "ripple_said": false,
		"scoop_said": false, "phase": 0.0, "things": [], "looks": null, "worms": null, "worm_meshes": [], "drop": null,
		"fish": []}
	if w.kind == W.DRIP:
		s.grown = _grown(w)
		s.drops = int(s.grown) * W.DROPS_PER_STEP
	_st[id] = s
	return s


## Steps already grown (a world saved with some, or another child's).
func _grown(w: Dictionary) -> int:
	var n := 0
	for cells: Array in w.steps:
		for cell: Vector3i in cells:
			if _block(cell) != BlockIds.FLOWSTONE:
				return n
		n += 1
	return n


func _activate(s: Dictionary) -> void:
	s.active = true
	s.t0 = _now
	s.last_drop = -1
	var w: Dictionary = s.w
	var id: String = w.id
	var spots: Array = []   # [part, index, cell]
	var looks := Node3D.new()
	looks.name = "Looks_" + id
	_root.add_child(looks)
	s.looks = looks
	match StringName(w.kind):
		W.GROTTO:
			spots.append([&"listen", 0, w.anchor])
			var ceiling := func(x: int, z: int) -> int: return wonders.shape.column(x, z).y
			s.worm_meshes = GlowWonderLooks.worm_meshes(w, ceiling)
			var worms := MeshInstance3D.new()
			worms.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			looks.add_child(worms)
			s.worms = worms
			s.level = -1
		W.DRIP:
			spots.append([&"stump", 0, w.anchor])
			var drop := MeshInstance3D.new()
			drop.mesh = GlowWonderLooks.drop_mesh()
			drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			drop.visible = false
			looks.add_child(drop)
			s.drop = drop
		W.ECHO:
			spots.append([&"roost", 0, w.roost])
			for i in (w.markers as Array).size():
				spots.append([&"marker", i, w.markers[i]])
		W.RAIN:
			spots.append([&"basin", 0, w.basin])
			for i in (w.limestone as Array).size():
				spots.append([&"limestone", i, w.limestone[i]])
			for i in (w.granite as Array).size():
				spots.append([&"granite", i, w.granite[i]])
		W.LAKE:
			spots.append([&"lamp", 0, w.lamp])
			spots.append([&"ripple", 0, w.ripple])
			var mesh := GlowWonderLooks.fish_mesh()
			var fish: Array = []
			for i in FISH:
				var f := MeshInstance3D.new()
				f.mesh = mesh
				f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				f.position = _fish_home(w, i)
				looks.add_child(f)
				fish.append(f)
			s.fish = fish
	var made: Array = []
	for spot: Array in spots:
		var t := WonderThing.make(self, id, spot[0], spot[1], spot[2])
		_root.add_child(t)
		made.append(t)
	s.things = made
	if w.kind == W.GROTTO and is_solved(id):
		_show_way(s)


func _deactivate(s: Dictionary) -> void:
	s.active = false
	for t: Node in s.things:
		if is_instance_valid(t):
			t.queue_free()
	s.things = []
	if is_instance_valid(s.looks):
		(s.looks as Node).queue_free()
	s.looks = null
	s.worms = null
	s.drop = null
	s.fish = []
	s.pending = []


# --- Taps -----------------------------------------------------------------------------------------------------------

## A tap on spot `part` (`index`) of wonder `id` (WonderThing.tapped); true when it was this director's.
func tap(id: String, part: StringName, index: int = 0) -> bool:
	if not _st.has(id):
		return false
	var s: Dictionary = _st[id]
	var w: Dictionary = s.w
	if is_solved(id) and part != &"roost":
		Audio.play(&"sparkle", _center(w.anchor), -6.0)
		return true
	match part:
		&"listen":
			_say(str(W.HOOKS[W.GROTTO]), 5.0, "Shh...")
		&"stump":
			_catch(s)
		&"roost":
			_click(s)
		&"marker":
			_choose(s, index)
		&"basin":
			_scoop(s)
		&"limestone":
			_pour(s, (w.limestone as Array)[clampi(index, 0, (w.limestone as Array).size() - 1)])
		&"granite":
			_pour(s, (w.granite as Array)[clampi(index, 0, (w.granite as Array).size() - 1)])
		&"lamp":
			_lamp(s)
		&"ripple":
			_ripple(s)
		_:
			return false
	return true


func _catch(s: Dictionary) -> void:
	var w: Dictionary = s.w
	var t := _now - float(s.t0)
	var n := W.drop_number(t)
	if not W.caught(t) or n == int(s.last_drop):
		_quietly(s, "Splash! Tap just as a drop lands.", "Splash!")
		return
	s.last_drop = n
	s.drops = int(s.drops) + 1
	var land := _center(w.land)
	Audio.play(&"drip_plink", land)
	_burst(land, Color("bfe9ff"), 8, 1.5)
	var steps: Array = w.steps
	var want := mini(W.steps_for(int(s.drops)), steps.size())
	while int(s.grown) < want:
		_change(w, &"step", int(s.grown))
		s.grown = int(s.grown) + 1
	if int(s.grown) >= steps.size():
		_solve(s)
		return
	_say(tr("%d drops caught: %d years of dripping") % [int(s.drops), W.years(int(s.drops))], 2.5,
		tr("%d years") % W.years(int(s.drops)), false)   # the count on the screen, not spoken at every drop


func _click(s: Dictionary) -> void:
	if not (s.pending as Array).is_empty():
		return   # still listening
	var w: Dictionary = s.w
	Audio.play(&"echo_click", _center(w.roost))
	s.heard = [] as Array[int]
	var pending: Array = []
	for i in (w.lengths as Array).size():
		pending.append([_now + W.echo_delay(float(w.lengths[i])), i])
	s.pending = pending


func _echo_tick(s: Dictionary) -> void:
	var pending: Array = s.pending
	if pending.is_empty():
		return
	var w: Dictionary = s.w
	var left: Array = []
	for e: Array in pending:
		if float(e[0]) > _now:
			left.append(e)
			continue
		var i := int(e[1])
		(s.heard as Array[int]).append(i)
		Audio.play(&"echo_click", _center(w.mouths[i]), -9.0, 0.92)
		_burst(_center(w.markers[i]), Color("d8f4ff"), 10, 1.2)
	s.pending = left


func _choose(s: Dictionary, i: int) -> void:
	var w: Dictionary = s.w
	if (s.heard as Array).size() < (w.lengths as Array).size():
		_quietly(s, "Tap the bat roost first, then listen to the echoes!", "The bat roost first!")
		return
	if i == int(w.long):
		_change(w, &"plug", 0)
		_solve(s)
		return
	_quietly(s, "Listen again: which echo came back last?", "Listen again!")


func _scoop(s: Dictionary) -> void:
	var w: Dictionary = s.w
	_carrying = true
	Audio.play(&"drip_plink", _center(w.basin))
	_burst(_center(w.basin), Color("7fc8ff"), 8, 1.5)
	if not s.scoop_said:
		s.scoop_said = true
		_say("You scooped some rainwater. Pour it on the wall!", 4.0, "Rainwater!")


func _pour(s: Dictionary, cell: Vector3i) -> void:
	var w: Dictionary = s.w
	if not _carrying:
		_quietly(s, "Scoop rainwater from the basin first.", "Scoop first!")
		return
	_carrying = false
	var at := _center(cell)
	if not W.dissolves(_block(cell)):
		Audio.play(&"drip_plink", at, -4.0)
		_burst(at, Color("9aa6b2"), 6, 1.0)
		_say("The water runs off. No fizz.", 3.0, "No fizz.")
		return
	s.pours = int(s.pours) + 1
	Audio.play(&"fizz", at)
	_burst(at, Color("f4fbff"), 16, 1.8)
	if W.pours_left(int(s.pours)) == 0:
		_change(w, &"door", 0)
		_solve(s)
		return
	_say("Fizz!", 2.0)


func _lamp(s: Dictionary) -> void:
	var w: Dictionary = s.w
	Audio.play(&"sparkle", _center(w.lamp), -6.0)
	_burst(_center(w.lamp), Color("ffe08a"), 10, 1.2)
	if not W.fish_come(W.LIGHT) and not s.lamp_said:
		s.lamp_said = true
		_say("The pale fish don't even turn...", 4.0, "Hmm...")


func _ripple(s: Dictionary) -> void:
	var w: Dictionary = s.w
	s.ripples = int(s.ripples) + 1
	s.ripple_t = _now
	var water := _ripple_spot(w)
	Audio.play(&"drip_plink", water, -2.0, 0.8)
	_burst(water, Color("a8e6ff"), 14, 1.4)
	if W.fish_come(W.RIPPLE):
		s.called = true
	if W.ripples_left(int(s.ripples)) == 0:
		_change(w, &"pearl", 0)
		_solve(s)
		return
	if not s.ripple_said:
		s.ripple_said = true
		_say("The fish turn towards the ripples!", 3.0, "Ripples!")


## Says `words` unless a gentle word was said here a moment ago (never nags).
func _quietly(s: Dictionary, words: String, caption: String) -> void:
	if _now - float(s.quiet) >= QUIET:
		s.quiet = _now
		_say(words, 3.5, caption)


func _solve(s: Dictionary) -> void:
	var w: Dictionary = s.w
	var key := PREFIX + str(w.id)
	if found.has(key):
		return
	found[key] = true
	var kind := StringName(w.kind)
	_say(W.win_words(kind), 9.0, str(W.WINS.get(kind, "")))   # the fact heard, the cheer seen
	if pay.is_valid():
		pay.call(W.reward_gold(universe))
	if book.is_valid():
		book.call(kind)
	var at := _center(w.anchor) + Vector3(0, 1.0, 0)
	Audio.play(&"sparkle", at)
	_burst(at, Color("ffd23f"), 24, 3.0)
	if kind == W.GROTTO:
		_show_way(s)
	wonder_solved.emit(str(w.id), kind)


# --- The plays' looks -----------------------------------------------------------------------------------------------

func _grotto_tick(s: Dictionary, at: Vector3, delta: float) -> void:
	var c: Vector3i = s.w.anchor
	var inside := Vector2(at.x - c.x - 0.5, at.z - c.z - 0.5).length() <= W.GROTTO_R + 0.5 and absf(at.y - c.y) < 3.0
	var heard := float(noise.call()) if noise.is_valid() else 0.0
	var lit := bool(holds_light.call()) if holds_light.is_valid() else false
	s.glow = W.worm_step(float(s.glow), W.worm_target(inside, heard, lit), delta)
	s.held = float(s.held) + delta if inside and float(s.glow) >= W.WORM_SHOW else 0.0
	if W.worms_solved(float(s.glow), float(s.held)):
		_solve(s)
	var level := clampi(roundi(float(s.glow) * (GlowWonderLooks.LEVELS - 1)), 0, GlowWonderLooks.LEVELS - 1)
	if level != int(s.level) and is_instance_valid(s.worms):
		s.level = level
		(s.worms as MeshInstance3D).mesh = (s.worm_meshes as Array)[level]


## The worms' threads towards the nearest buried chest (and the compass).
func _show_way(s: Dictionary) -> void:
	var w: Dictionary = s.w
	var from := _center(w.anchor)
	var to: Vector3 = nearest_chest.call(from) if nearest_chest.is_valid() else Vector3.INF
	if not to.is_finite():
		return
	_hint = to
	if not is_instance_valid(s.looks):
		return
	var mesh := GlowWonderLooks.way_mesh(from, to, func(x: int, z: int) -> Vector3i: return wonders.shape.column(x, z))
	if mesh != null:
		var way := MeshInstance3D.new()
		way.mesh = mesh
		way.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(s.looks as Node3D).add_child(way)


func _drip_tick(s: Dictionary, at: Vector3) -> void:
	var w: Dictionary = s.w
	var phase := fposmod(_now - float(s.t0), W.DROP_EVERY)
	var top := float((w.tip as Vector3i).y) + 0.15
	var bottom := float((w.land as Vector3i).y) + 0.08
	if is_instance_valid(s.drop):
		var drop := s.drop as MeshInstance3D
		drop.visible = phase < W.DROP_FALL
		if drop.visible:
			var k := phase / W.DROP_FALL
			drop.position = Vector3(w.tip.x + 0.5, lerpf(top, bottom, k * k), w.tip.z + 0.5)
	if float(s.phase) < W.DROP_FALL and phase >= W.DROP_FALL and at.distance_to(_center(w.land)) <= SOUND_NEAR:
		Audio.play(&"drip_plink", _center(w.land), -10.0)
	s.phase = phase


func _lake_tick(s: Dictionary, delta: float) -> void:
	var w: Dictionary = s.w
	var gather := _now - float(s.ripple_t) < FISH_GATHER
	var spot := _ripple_spot(w) + Vector3(0, -0.7, 0)
	for i in (s.fish as Array).size():
		var f := (s.fish as Array)[i] as MeshInstance3D
		if not is_instance_valid(f):
			continue
		var goal := _fish_home(w, i)
		if gather:
			var a := _now * 2.0 + i * TAU / FISH
			goal = spot + Vector3(cos(a), 0, sin(a)) * 0.45
		var from := f.position
		f.position = from.lerp(goal, clampf(delta * 2.5, 0.0, 1.0))
		var move := f.position - from
		if Vector2(move.x, move.z).length() > 0.0005:
			f.rotation.y = atan2(-move.z, move.x)


## Fish `i`'s place on its slow round of the pool.
func _fish_home(w: Dictionary, i: int) -> Vector3:
	var a := _now * 0.5 + i * TAU / FISH
	var c: Vector3i = w.anchor
	return Vector3(c.x + 0.5 + cos(a) * FISH_RING, c.y - 1.0, c.z + 0.5 + sin(a) * FISH_RING)


## The water by the ripple stone (where the ripples spread).
func _ripple_spot(w: Dictionary) -> Vector3:
	var c := _center(w.anchor)
	var r := Vector3(w.ripple) + Vector3(0.5, 0.5, 0.5)
	return Vector3(lerpf(r.x, c.x, 0.4), float((w.anchor as Vector3i).y) - 0.1, lerpf(r.z, c.z, 0.4))


# --- The sights -----------------------------------------------------------------------------------------------------

func _crystals(at: Vector3) -> void:
	if found.has(PREFIX + String(W.CRYSTALS)):
		return
	var x := floori(at.x)
	var z := floori(at.z)
	var shape := wonders.shape
	if not shape.crystal_hall(x, z):
		return
	var c := shape.column(x, z)
	if c.x == c.y or c.y >= c.z or absf(at.y - c.x) > HALL_FEET:
		return
	_sight(W.CRYSTALS, at)


func _walk(at: Vector3) -> void:
	if _last.is_finite() and not found.has(PREFIX + String(W.LONGEST)):
		var x := floori(at.x)
		var z := floori(at.z)
		if at.y < wonders.shape.roof_at(x, z) - UNDER_ROOF and not wonders.shape.in_shaft(x, z):
			_walked += W.walk_step(_last, at)
			if W.walked_far(_walked):
				_sight(W.LONGEST, at)
	_last = at


func _sight(kind: StringName, at: Vector3) -> void:
	found[PREFIX + String(kind)] = true
	_say("%s!\n%s" % [tr(W.name_of(kind)), tr(str(W.FACTS[kind]))], 8.0, tr(W.name_of(kind)) + "!")
	if book.is_valid():
		book.call(kind)
	Audio.play(&"sparkle")
	_burst(at + Vector3(0, 1.0, 0), Color("d8f4ff"), 20, 2.5)


# --- The world's changes (the host's) -------------------------------------------------------------------------------

func _change(w: Dictionary, part: StringName, index: int) -> void:
	if multiplayer.is_server():
		_apply(str(w.id), part, index)
	else:
		_rpc_change.rpc_id(1, str(w.id), part, index)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_change(id: String, part: StringName, index: int) -> void:
	if multiplayer.is_server() and PARTS.has(part):
		_apply(id, part, index)


## Host: one change of a wonder, only to its own cells and only where they still hold what the wonder put there.
func _apply(id: String, part: StringName, index: int) -> void:
	if wonders == null or not set_block.is_valid():
		return
	var w := wonders.find(id)
	if w.is_empty():
		return
	match part:
		&"step":
			var steps: Array = w.get("steps", [])
			if index < 0 or index >= steps.size():
				return
			for cell: Vector3i in steps[index]:
				if _block(cell) in [BlockIds.AIR, BlockIds.WATER]:
					set_block.call(cell, BlockIds.FLOWSTONE)
		&"plug":
			for p: Vector3i in w.get("plug", []):
				if _block(p) == BlockIds.CAVE_STONE:
					set_block.call(p, BlockIds.AIR)
		&"door":
			for p: Vector3i in w.get("limestone", []):
				if W.dissolves(_block(p)):
					set_block.call(p, BlockIds.AIR)
		&"pearl":
			if not w.has("pearl"):
				return
			if _block(w.pearl) == BlockIds.CAVE_PEARL:
				set_block.call(w.pearl, BlockIds.LAKE_STONE)
			var shore: Vector3i = (w.ripple as Vector3i) + Vector3i.UP
			if _block(shore) == BlockIds.AIR:
				set_block.call(shore, BlockIds.CAVE_PEARL)


# --- Helpers --------------------------------------------------------------------------------------------------------

func _block(p: Vector3i) -> int:
	return int(block_at.call(p)) if block_at.is_valid() else BlockIds.AIR


## Owner #133/#134 (Play G0's rule: nothing to read): with the voice on (`voice_on`, PlayVoice.on) the words are spoken
## (`speak`, PlayVoice.say) and the screen keeps `caption` (a name, a cheer, two words); without it, the words in full.
## `spoken`: false for a count shown as it goes (never spoken at every drop).
func _say(words: String, seconds: float, caption: String = "", spoken: bool = true) -> void:
	if words == "":
		return
	var voice := voice_on.is_valid() and bool(voice_on.call())
	if voice and spoken and speak.is_valid():
		speak.call(tr(words))
	if toast.is_valid():
		toast.call(tr(caption) if voice and caption != "" else tr(words), seconds)



func _burst(at: Vector3, color: Color, amount: int, speed: float) -> void:
	if is_inside_tree():
		Fx.burst(get_tree().root, at, color, amount, speed)


static func _center(cell: Vector3i) -> Vector3:
	return Vector3(cell) + Vector3(0.5, 0.5, 0.5)
