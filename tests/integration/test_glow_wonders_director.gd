extends GutTest
## Universe 6, the Glow Caves (owner #122, docs/design/learning-is-play.md §3): the Cave Wonders played by this game's
## child (GlowWondersDirector). The problem comes first (a hook near the wonder, never its answer), the move that wins is
## the real fact, and the fact line comes only after the try, with fixed gold once per wonder (never random), its Cave
## Book page and nothing personal kept. A fake world here: the wonders' rock and air around it.

const SEED := 20261017
const W := preload("res://core/rules/glow_wonder_rules.gd")

var _wonders: GlowWonders
var _d: GlowWondersDirector
var _at := Vector3.INF
var _noise := 0.0
var _light := false
var _blocks := {}
var _toasts: Array[String] = []
var _paid: Array[int] = []
var _book: Array[StringName] = []
var _voice := false
var _spoken: Array[String] = []


func before_all() -> void:
	_wonders = GlowWonders.new(SEED, GlowShape.new(SEED))


func before_each() -> void:
	_at = Vector3.INF
	_noise = 0.0
	_light = false
	_blocks = {}
	_toasts.clear()
	_paid.clear()
	_book.clear()
	_voice = false
	_spoken.clear()
	_d = GlowWondersDirector.new()
	_d.wonders = _wonders
	_d.universe = 6
	_d.found = {}
	_d.auto_tick = false
	_d.player_position = func() -> Vector3: return _at
	_d.noise = func() -> float: return _noise
	_d.holds_light = func() -> bool: return _light
	_d.toast = func(text: String, _seconds: float) -> void: _toasts.append(text)
	_d.pay = func(gold: int) -> void: _paid.append(gold)
	_d.book = func(kind: StringName) -> void: _book.append(kind)
	_d.voice_on = func() -> bool: return _voice
	_d.speak = func(text: String) -> void: _spoken.append(text)
	_d.block_at = func(p: Vector3i) -> int: return int(_blocks[p]) if _blocks.has(p) else _rock(p)
	_d.set_block = func(p: Vector3i, id: int) -> void: _blocks[p] = id
	add_child_autofree(_d)


func _rock(p: Vector3i) -> int:
	var b := _wonders.block_at(p)
	return b if b >= 0 else BlockIds.AIR


## The nearest wonder of `kind` to the spawn.
func _first(kind: StringName) -> Dictionary:
	var sp := _wonders.spawn
	var best := {}
	var best_d := INF
	for w: Dictionary in _wonders.wonders_near(Vector3(sp.x, 0, sp.y), 400.0):
		var d := Vector2(w.anchor.x - sp.x, w.anchor.z - sp.y).length()
		if w.kind == kind and d < best_d:
			best = w
			best_d = d
	return best


func _stand(w: Dictionary, offset: Vector3) -> void:
	_at = Vector3(w.anchor) + Vector3(0.5, 0.0, 0.5) + offset


func _ticks(n: int, dt: float = 0.1) -> void:
	for i in n:
		_d.tick(dt)


func _said(words: String) -> int:
	return _toasts.filter(func(t: String) -> bool: return t.contains(words)).size()


func test_the_problem_comes_first_once_and_never_its_answer() -> void:
	var w := _first(W.DRIP)
	_stand(w, Vector3(-4, 0, 0))
	_ticks(5)
	assert_eq(_said(str(W.HOOKS[W.DRIP])), 1, "the hook near the wonder")
	assert_eq(_said(str(W.FACTS[W.DRIP])), 0, "no fact before the try")
	_ticks(20)
	assert_eq(_said(str(W.HOOKS[W.DRIP])), 1, "said once")
	assert_eq(_paid, [] as Array[int])


func test_the_glow_worms_shine_for_a_still_dark_child() -> void:
	var w := _first(W.GROTTO)
	_stand(w, Vector3(2, 0, 0))
	_noise = StealthRules.NOISE_WALK
	_ticks(100)
	assert_false(_d.is_solved(w.id), "walking about: they stay dim")
	assert_lt(_d.worm_glow(w.id), W.WORM_REST + 0.01)
	_noise = 0.0
	_light = true
	_ticks(100)
	assert_false(_d.is_solved(w.id), "a lamp in hand: they stay dim")
	_light = false
	_ticks(30)
	assert_gt(_d.worm_glow(w.id), W.WORM_REST, "dark and still: they brighten")
	_ticks(70)
	assert_true(_d.is_solved(w.id), "held bright: the way shows")
	assert_eq(_said(str(W.FACTS[W.GROTTO])), 1, "the fact after the try")
	assert_eq(_paid, [W.reward_gold(6)] as Array[int], "fixed gold, once")
	assert_eq(_book, [W.GROTTO] as Array[StringName], "the Cave Book's page")
	assert_true(_d.found.has("wonder:" + str(w.id)), "kept with the world")


func test_drops_caught_as_they_land_grow_the_steps_to_the_pearls() -> void:
	var w := _first(W.DRIP)
	_stand(w, Vector3(-2, 0, 0))
	_ticks(1)
	while W.caught(_d.drip_time(w.id)):
		_ticks(1)
	assert_true(_d.tap(w.id, &"stump", 0), "a tap at the wrong time is a tap")
	assert_eq(_d.drops(w.id), 0, "too early or too late: the drop splashes")
	var steps: Array = w.steps
	var need := W.DROPS_PER_STEP * steps.size()
	var guard := 0
	while _d.drops(w.id) < need and guard < 5000:
		guard += 1
		_ticks(1, 0.05)
		if W.caught(_d.drip_time(w.id)) and _d.drops(w.id) < W.drop_number(_d.drip_time(w.id)) + 1:
			_d.tap(w.id, &"stump", 0)
	assert_eq(_d.drops(w.id), need, "a drop caught as it lands, one at a time")
	for k in steps.size():
		for cell: Vector3i in steps[k]:
			assert_eq(int(_blocks.get(cell, -1)), BlockIds.FLOWSTONE, "step %d grew" % k)
	assert_true(_d.is_solved(w.id))
	assert_eq(_said(str(W.FACTS[W.DRIP])), 1)
	assert_eq(_paid.size(), 1)


func test_the_latest_echo_is_the_long_tunnel() -> void:
	var w := _first(W.ECHO)
	_stand(w, Vector3(-3, 0, 0))
	_ticks(1)
	var long := int(w.long)
	var wrong := (long + 1) % 3
	_d.tap(w.id, &"marker", long)
	for p: Vector3i in w.plug:
		assert_eq(_d.block_at.call(p), BlockIds.CAVE_STONE, "no guessing before listening")
	assert_true(_d.tap(w.id, &"roost", 0), "a click")
	_ticks(30)
	var heard := _d.echoes_heard(w.id)
	assert_eq(heard.size(), 3, "three echoes")
	assert_eq(heard[2], long, "the latest echo comes from the long tunnel")
	_d.tap(w.id, &"marker", wrong)
	assert_false(_d.is_solved(w.id), "not that one")
	for p: Vector3i in w.plug:
		assert_eq(_d.block_at.call(p), BlockIds.CAVE_STONE)
	_d.tap(w.id, &"marker", long)
	for p: Vector3i in w.plug:
		assert_eq(_d.block_at.call(p), BlockIds.AIR, "the long tunnel opens to its pocket")
	assert_true(_d.is_solved(w.id))
	assert_eq(_said(str(W.FACTS[W.ECHO])), 1)


func test_rainwater_opens_limestone_never_granite() -> void:
	var w := _first(W.RAIN)
	_stand(w, Vector3(-2, 0, 0))
	_ticks(1)
	_d.tap(w.id, &"granite", 0)
	assert_false(_d.carrying(), "nothing to pour yet")
	for i in 5:
		_d.tap(w.id, &"basin", 0)
		assert_true(_d.carrying(), "a scoop of rainwater")
		_d.tap(w.id, &"granite", i % 5)
		assert_false(_d.carrying(), "poured")
	for p: Vector3i in w.granite:
		assert_eq(_d.block_at.call(p), BlockIds.GRANITE, "granite never dissolves")
	assert_false(_d.is_solved(w.id))
	for i in W.POURS_TO_OPEN:
		_d.tap(w.id, &"basin", 0)
		_d.tap(w.id, &"limestone", i % 2)
	for p: Vector3i in w.limestone:
		assert_eq(_d.block_at.call(p), BlockIds.AIR, "the limestone door dissolved")
	assert_true(_d.is_solved(w.id))
	assert_eq(_said(str(W.FACTS[W.RAIN])), 1)


func test_ripples_call_the_blind_fish_a_lamp_never_does() -> void:
	var w := _first(W.LAKE)
	_stand(w, Vector3(0, 0, -4))
	_ticks(1)
	for i in 6:
		_d.tap(w.id, &"lamp", 0)
		_ticks(3)
	assert_false(_d.fish_called(w.id), "eyeless fish don't come to light")
	assert_eq(_d.block_at.call(w.pearl), BlockIds.CAVE_PEARL, "the pearl stays on the bottom")
	for i in W.RIPPLES_NEEDED:
		_d.tap(w.id, &"ripple", 0)
		_ticks(3)
	assert_true(_d.fish_called(w.id), "they feel the ripples")
	assert_eq(_d.block_at.call(w.pearl), BlockIds.LAKE_STONE, "they nudged the pearl ...")
	var shore: Vector3i = (w.ripple as Vector3i) + Vector3i.UP
	assert_eq(_d.block_at.call(shore), BlockIds.CAVE_PEARL, "... ashore by the ripple stone")
	assert_true(_d.is_solved(w.id))


func test_a_wonder_solved_in_this_world_stays_solved_and_never_pays_twice() -> void:
	var w := _first(W.ECHO)
	_d.found["wonder:" + str(w.id)] = true
	_stand(w, Vector3(-3, 0, 0))
	_ticks(5)
	assert_eq(_said(str(W.HOOKS[W.ECHO])), 0, "no hook for a solved wonder")
	_d.tap(w.id, &"roost", 0)
	_ticks(30)
	_d.tap(w.id, &"marker", int(w.long))
	assert_eq(_paid, [] as Array[int])


func test_tap_spots_come_near_the_child_and_go_when_far() -> void:
	var w := _first(W.RAIN)
	_stand(w, Vector3(-2, 0, 0))
	_ticks(6)
	var mine := _d.things().filter(func(t: WonderThing) -> bool: return t.wonder_id == w.id)
	assert_eq(mine.size(), 1 + (w.limestone as Array).size() + (w.granite as Array).size(), "the basin and the wall's blocks")
	for t: WonderThing in mine:
		assert_eq(t.collision_layer, SecretThing.LAYER, "only tap rays see them")
	_at += Vector3(200, 0, 0)
	_ticks(6)
	assert_eq(_d.things().filter(func(t: WonderThing) -> bool: return t.wonder_id == w.id and not t.is_queued_for_deletion()).size(), 0)


## The compass points to the nearest wonder not solved, and never works out many areas in one frame (a phone): one new
## area a look at most, the rest from the areas already known.
func test_the_compass_points_to_a_wonder_one_new_area_at_a_time() -> void:
	var fresh := GlowWonders.new(SEED, _wonders.shape)
	_d.wonders = fresh
	var from := Vector3(fresh.spawn.x + 0.5, 30, fresh.spawn.y + 0.5)
	var looks := 0
	var target := {}
	while target.is_empty() and looks < 40:
		var before := fresh.known_areas()
		_ticks(11)   # past the compass's second (no child standing: nothing else looks)
		target = _d.compass_target(from)
		assert_lte(fresh.known_areas() - before, 1, "one new area a look")
		looks += 1
	assert_false(target.is_empty(), "it finds one")
	var at: Vector3i = target.chest
	var w := {}
	for c: Dictionary in fresh.wonders_near(from, GlowWondersDirector.COMPASS_REACH):
		if c.anchor == at:
			w = c
	assert_false(w.is_empty(), "a wonder's place")
	assert_false(_d.is_solved(w.id))


## Owner #133/#134 (Play G0's rule): nothing to read. With the voice on, the hook, the cheer and the fact are spoken
## (PlayVoice), and the screen keeps a few words: the wonder's name, the cheer; without it, the words in full.
func test_the_voice_says_it_and_the_screen_keeps_few_words() -> void:
	_voice = true
	var w := _first(W.ECHO)
	_stand(w, Vector3(-3, 0, 0))
	_ticks(3)
	assert_true(_spoken.has(str(W.HOOKS[W.ECHO])), "the problem is spoken")
	assert_eq(_said(str(W.HOOKS[W.ECHO])), 0, "... not written")
	assert_eq(_said(W.name_of(W.ECHO)), 1, "the screen shows the wonder's name")
	_d.tap(w.id, &"marker", 0)
	assert_false(_spoken.is_empty())
	for t: String in _toasts:
		assert_lte(t.split(" ", false).size(), 5, "few words on the screen: %s" % t)
	_d.tap(w.id, &"roost", 0)
	_ticks(30)
	_d.tap(w.id, &"marker", int(w.long))
	assert_true(_spoken.has(W.win_words(W.ECHO)), "the cheer and the fact, spoken")
	assert_eq(_said(str(W.FACTS[W.ECHO])), 0, "the fact is heard, not read")
	assert_eq(_said(str(W.WINS[W.ECHO])), 1, "the cheer on the screen")


func test_a_crystal_hall_and_a_long_walk_are_sights() -> void:
	var shape := _wonders.shape
	var hall := Vector3.INF
	for z in range(-300, 300, 6):
		for x in range(-300, 300, 6):
			var c := shape.column(x, z)
			if c.x != c.y and c.y < c.z and c.x > GlowShape.LAKE_LEVEL + 1 and shape.crystal_hall(x, z):
				hall = Vector3(x + 0.5, c.x, z + 0.5)
				break
		if hall.is_finite():
			break
	assert_true(hall.is_finite(), "a crystal hall near the spawn")
	_at = hall
	_ticks(6)
	assert_true(_d.found.has("wonder:" + String(W.CRYSTALS)))
	assert_eq(_said(str(W.FACTS[W.CRYSTALS])), 1)
	assert_true(_book.has(W.CRYSTALS))
	_at = Vector3(5000.5, 30, 5000.5)
	_ticks(1)
	var steps := int(W.LONGEST_WALK / 3.0) + 40   # a shaft on the way is under the sky: not counted
	for i in steps:
		_at += Vector3(3, 0, 0)
		_ticks(1)
	assert_true(_d.found.has("wonder:" + String(W.LONGEST)), "a long walk under the roof")
	assert_eq(_said(str(W.FACTS[W.LONGEST])), 1)
	assert_eq(_paid, [] as Array[int], "sights pay nothing: the fact is the find")
