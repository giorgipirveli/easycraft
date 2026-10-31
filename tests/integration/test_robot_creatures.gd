extends GutTest
## Owner #86 (spec §21f): "on the planets we should have some aliens, robots as well". On Mars (a real planet with
## sights): the helper robot by the landing pad points the way the planet guide's compass points and gives a science
## quest (dig a sample with the rover buddy, explore a place, come back and answer a question: gold once, right the
## first time); the rover follows the child; the drone scouts ahead; the aliens' camp is a short walk away, its explorer
## becomes a friend for a sample (a present, and it comes along: the buddy system), its trader sells souvenirs.

const SEED := 12345
const MARS := 19

var d: SpaceCreatures
var shape: SpaceShape
var layer: CanvasLayer
var child := Vector3.INF
var toasts: Array[String] = []
var marks: Array[Dictionary] = []
var gold_seen: Array[int] = []
var brought := 0
var sent_home: Array[StringName] = []
var saves := 0


func before_each() -> void:
	SpendRules.clear_extra()
	toasts.clear()
	marks.clear()
	gold_seen.clear()
	sent_home.clear()
	brought = 0
	saves = 0
	layer = CanvasLayer.new()
	add_child_autofree(layer)
	d = _director(MARS, SpaceShape.MARS)


func after_each() -> void:
	SpendRules.clear_extra()


func _director(u: int, planet: StringName) -> SpaceCreatures:
	shape = SpaceShape.new(SEED, planet)
	var pad := shape.spawn_column()
	child = Vector3(pad.x + 0.5, shape.height_at(pad.x, pad.y), pad.y + 0.5)
	var c := SpaceCreatures.new()
	c.universe = u
	c.shape = shape
	c.world_seed = SEED
	c.ground_y = func(x: int, z: int) -> float: return float(shape.height_at(x, z))
	c.player_position = func() -> Vector3: return child
	c.player_forward = func() -> Vector3: return Vector3.FORWARD
	c.found = {}
	c.sights = UniverseRegistry.sights(u)
	c.profile = ProfileData.new()
	c.save_profile = func() -> void: saves += 1
	c.toast = func(text: String) -> void: toasts.append(text)
	c.mark = func(e: Dictionary) -> void: marks.append(e)
	c.gold_changed = func(n: int) -> void: gold_seen.append(n)
	c.bring_buddy = func() -> void: brought += 1
	c.send_home = func(kind: StringName) -> void: sent_home.append(kind)
	c.ui_parent = layer
	c.players = func() -> Array[Vector3]: return [child] if child.is_finite() else [] as Array[Vector3]
	add_child_autofree(c)
	c.setup()
	return c


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _texts() -> String:
	return " | ".join(PackedStringArray(d.card.texts()))


func _press(text: String) -> void:
	var b := d.card.button_named(text)
	assert_not_null(b, "a button %s in [%s]" % [text, _texts()])
	if b:
		b.pressed.emit()


func test_a_robot_a_rover_a_drone_and_the_aliens_camp_wait_on_mars() -> void:
	var pad := shape.spawn_column()
	var pad3 := Vector3(pad.x + 0.5, 0, pad.y + 0.5)
	assert_not_null(d.robot)
	assert_eq(d.robot.display_name, "Dusty")
	assert_almost_eq(_flat(d.robot.global_position, pad3), RobotRules.HELPER_RING, 0.8, "by the landing pad")
	assert_gt(d.robot.global_position.x, pad3.x, "front-right of a child facing north")
	assert_eq(int(d.robot.global_position.y), shape.height_at(floori(d.robot.global_position.x), floori(d.robot.global_position.z)),
		"on the ground")
	assert_not_null(d.rover)
	assert_not_null(d.drone)
	assert_gt(d.drone.global_position.y, d.robot.global_position.y + 2.0, "the drone hovers")
	assert_not_null(d.camp, "a camp on a real planet")
	assert_null(d.village)
	var dist := _flat(d.camp.global_position, pad3)
	assert_between(dist, 25.0, 52.0, "a short walk away (%.0f)" % dist)
	assert_eq(d.camp.explorer.display_name, "Zib")
	assert_eq(d.camp.trader.display_name, "Quix")
	assert_eq(marks.size(), 1, "MY MAP shows the camp from the landing")
	assert_eq(str(marks[0].name), CreatureWords.CAMP_NAME)
	assert_eq(d.robot.mark_text(), "!", "its quest waits")


func test_the_robot_points_the_way_the_compass_points() -> void:
	d.tick()
	var list := PlanetGuideRules.checklist(shape.sights(), d.sights, d.found, d.robot.global_position)
	var next := PlanetGuideRules.next(list, d.robot.global_position)
	assert_false(next.is_empty())
	assert_eq(d.robot.point_at, next.pos as Vector3, "the guide's next place")
	for e: Dictionary in list:
		d.found[SpaceSights.PREFIX + String(e.id)] = true
	d.tick()
	assert_eq(d.robot.point_at, d.site.pos as Vector3, "every place found: the aliens' camp")


func test_taps_find_a_creature_near_its_middle_never_through_a_wall() -> void:
	var at := d.robot.tap_center()
	var eye := at + Vector3(0, 0.3, 3.0)
	var dir := (at - eye).normalized()
	assert_same(SpaceCreature.find(get_tree(), eye, dir, eye), d.robot)
	assert_null(SpaceCreature.find(get_tree(), eye, Vector3.UP, eye), "looking away")
	var far := at + Vector3(0, 0, 12)
	assert_null(SpaceCreature.find(get_tree(), far, (at - far).normalized(), far), "too far")
	var wall := func(_f: Vector3, _d: Vector3, _t: float) -> bool: return true
	assert_null(SpaceCreature.find(get_tree(), eye, dir, eye, wall), "not through a block")
	assert_true(d.robot.tapped(), "a tap is heard")
	assert_true(d.card.is_open())


func test_the_science_quest_dig_explore_come_back_and_answer() -> void:
	d.robot.tapped()
	assert_string_contains(_texts(), "Dusty")
	assert_string_contains(_texts(), CreatureWords.robot(MARS).fact)
	_press("LET'S GO!")
	assert_false(d.card.is_open())
	assert_eq(RobotRules.quest_step(d.found), RobotRules.DIG)
	var place := RobotRules.quest_place(d.found)
	assert_true(place.begins_with("sight:"), "the guide's next place (%s)" % place)
	d.tick()
	assert_eq(d.robot.mark_text(), "", "nothing waits at the robot")
	d.rover.tapped()
	assert_true(d.found.has(RobotRules.SAMPLE), "the rover dug a sample")
	assert_true(d.rover.digging())
	await wait_seconds(SpaceCreatures.SAY_DELAY + 0.2)
	assert_true(toasts.has(CreatureWords.robot(MARS).sample), "what the sample is: %s" % [toasts])
	d.tick()
	var spot := d.place_position(place)
	assert_eq(d.robot.point_at, spot, "the robot points to the quest's place")
	d.found[place] = true   # SpaceSights found it
	d.tick()
	assert_eq(d.robot.mark_text(), "?", "come back to me")
	d.robot.tapped()
	assert_eq(d.card.choice_buttons.size(), 3, "a question with three answers: %s" % _texts())
	var q := RobotRules.next_question(MARS, d.profile.creatures)
	var gold := d.profile.survivor_gold
	d.card.choice_buttons[int(q.answer)].pressed.emit()
	assert_eq(d.profile.survivor_gold, gold + EarnRules.FACT_QUIZ_GOLD, "right the first time pays")
	assert_eq(gold_seen, [d.profile.survivor_gold], "the gold counter shows it")
	assert_gt(saves, 0, "the profile is saved")
	assert_string_contains(_texts(), CreatureWords.QUEST_DONE)
	assert_eq(RobotRules.quest_step(d.found), RobotRules.FINISHED)
	d.tick()
	assert_eq(d.robot.mark_text(), "")


func test_a_wrong_answer_says_not_yet_with_a_hint_and_pays_nothing_after() -> void:
	d.found[RobotRules.STARTED] = true
	d.found[RobotRules.SAMPLE] = true
	d.found[RobotRules.PLACE + RobotRules.CAMP_PLACE] = true
	d.found[RobotRules.CAMP] = true
	d.robot.tapped()
	var q := RobotRules.next_question(MARS, d.profile.creatures)
	var wrong := (int(q.answer) + 1) % 3
	d.card.choice_buttons[wrong].pressed.emit()
	assert_string_contains(_texts(), "Not yet!")
	assert_string_contains(_texts(), str(q.hint))
	assert_true(d.card.choice_buttons[wrong].disabled)
	var gold := d.profile.survivor_gold
	d.card.choice_buttons[int(q.answer)].pressed.emit()
	assert_eq(d.profile.survivor_gold, gold, "right after a miss: praise, no gold")
	assert_string_contains(_texts(), CreatureWords.QUIZ_RIGHT_AGAIN)
	assert_false(d.profile.creatures.paid(str(q.id)), "it can still pay another day")


func test_the_rover_follows_and_the_drone_scouts_ahead() -> void:
	child += Vector3(20, 0, -10)
	child.y = shape.height_at(floori(child.x), floori(child.z))
	var before := _flat(d.rover.global_position, child)
	for i in 30:
		d.rover.think()
		d.rover.ease_frame(1.0 / 30.0)
		d.drone.think()
		d.drone.ease_frame(1.0 / 30.0)
	assert_lt(_flat(d.rover.global_position, child), before, "the rover drives after the child")
	child += Vector3(60, 0, 0)
	child.y = shape.height_at(floori(child.x), floori(child.z))
	d.rover.think()
	assert_lt(_flat(d.rover.global_position, child), RobotRules.ROVER_FOLLOW + 2.0, "left far behind: it comes at once")
	var target := d.drone_target()
	assert_true(target.is_finite())
	for i in 90:
		d.drone.think()
		d.drone.ease_frame(1.0 / 30.0)
	var ahead := Vector2(d.drone.global_position.x - child.x, d.drone.global_position.z - child.z)
	var way := Vector2(target.x - child.x, target.z - child.z).normalized()
	assert_gt(ahead.normalized().dot(way), 0.8, "the drone is ahead, towards the next place")
	assert_gt(d.drone.global_position.y, child.y + 2.0, "over the child's head")
	d.drone.tapped()
	assert_string_contains(toasts[-1], "Your drone flew ahead")


func test_the_explorer_becomes_a_friend_for_a_sample_and_comes_along() -> void:
	var zib := d.camp.explorer
	zib.tapped()
	assert_string_contains(_texts(), CreatureWords.HONEST, "honest about life in space")
	assert_string_contains(_texts(), "story", "its world is make-believe")
	assert_null(d.card.button_named(CreatureWords.GIVE), "no sample yet")
	assert_true(d.profile.creatures.has_met(&"zib"))
	d.card.close()
	d.rover.tapped()
	zib.tapped()
	_press(CreatureWords.GIVE)
	assert_true(d.profile.creatures.is_friend(&"zib"))
	assert_true(d.profile.creatures.owns("gift_zib"), "its present")
	assert_string_contains(_texts(), "Glimmer Gem")
	_press(CreatureWords.COME)
	assert_eq(d.profile.creatures.buddy, "zib")
	assert_eq(brought, 1, "it comes along (the buddy system brings its mini-buddy)")
	d.tick()
	assert_false(zib.visible, "it walks with the child now, not at its camp")


func test_one_alien_buddy_at_a_time() -> void:
	AlienRules.befriend(d.profile, &"nuri")
	AlienRules.come_along(d.profile, &"nuri")
	d.found[RobotRules.SAMPLE] = true
	d.camp.explorer.tapped()
	_press(CreatureWords.GIVE)
	_press(CreatureWords.COME)
	assert_eq(sent_home, [&"alien_nuri"], "Nuri's mini-buddy leaves this world")
	assert_eq(d.profile.creatures.buddy, "zib")
	assert_true(d.profile.creatures.is_friend(&"nuri"), "still friends")


func test_the_trader_sells_souvenirs_for_gold() -> void:
	d.profile.survivor_gold = 100
	d.camp.trader.tapped()
	assert_string_contains(_texts(), "You have 100 gold.")
	var marble := "%s: %d gold" % [CreatureWords.souvenir("sun_marble").name, AlienRules.price("sun_marble")]
	_press(marble)
	assert_true(d.profile.creatures.owns("sun_marble"))
	assert_eq(d.profile.survivor_gold, 20)
	assert_eq(gold_seen[-1], 20)
	assert_string_contains(_texts(), "You got the Three-Sun Marble!")
	var pebble := "%s: %d gold" % [CreatureWords.souvenir("singing_pebble").name, AlienRules.price("singing_pebble")]
	_press(pebble)
	assert_string_contains(_texts(), "You need 40 more gold.")
	assert_false(d.profile.creatures.owns("singing_pebble"))


func test_walking_into_the_camp_visits_it() -> void:
	assert_false(d.found.has(RobotRules.CAMP))
	child = d.camp.global_position + Vector3(1, 0, 1)
	d.tick()
	assert_true(d.found.has(RobotRules.CAMP))
	assert_true(toasts.has(CreatureWords.CAMP_FOUND))
	d.tick()
	assert_eq(toasts.count(CreatureWords.CAMP_FOUND), 1, "once")


func test_the_robot_greets_once_when_the_child_comes_near() -> void:
	child = d.robot.global_position + Vector3(0, 0, 30)
	d.robot.think()
	assert_false(d.robot.greeted)
	child = d.robot.global_position + Vector3(0, 0, 3)
	d.robot.think()
	assert_true(d.robot.greeted)
	assert_string_contains(d.robot.bubble.text, "Dusty")


func test_both_graphics_styles() -> void:
	CreatureLook.dress(d.robot, "realistic", true)
	var shell := d.robot.find_child("Shell", true, false) as MeshInstance3D
	assert_same(shell.material_override, Animal.pip_material(), "robots shine like Pip in the realistic style")
	CreatureLook.dress(d.camp, "realistic", false)
	var look := d.camp.explorer.find_child("Look", true, false) as MeshInstance3D
	assert_same(look.material_override, CreatureLook.soft(), "aliens: a softer sheen")
	CreatureLook.dress(d.robot, "blocky", true)
	assert_null(shell.material_override, "the blocky style: the animals' own material")
	assert_same(shell.mesh.surface_get_material(0), CreatureLook.material())
	var animal := BlockyAnimal._build([[Vector3.ZERO, Vector3.ONE, Color.WHITE]]).surface_get_material(0) as StandardMaterial3D
	var mine := CreatureLook.material()
	assert_eq([mine.vertex_color_use_as_albedo, mine.vertex_color_is_srgb], [animal.vertex_color_use_as_albedo,
		animal.vertex_color_is_srgb], "the animals' shader: nothing new to compile")


## Frame cost: every creature's per-frame work (its throttled thinking and its easing) on this desktop.
func test_their_frame_cost_is_tiny() -> void:
	var nodes := get_tree().get_nodes_in_group(SpaceCreature.GROUP)
	assert_gte(nodes.size(), 5, "robot, rover, drone, explorer, trader")
	var frames := 600
	var t0 := Time.get_ticks_usec()
	for f in frames:
		child.x += 0.05
		for n in nodes:
			(n as SpaceCreature)._process(1.0 / 60.0)
		d._process(1.0 / 60.0)
	var per_frame_ms := (Time.get_ticks_usec() - t0) / 1000.0 / frames
	gut.p("CREATURES_FRAME_MS %.4f (%d creatures)" % [per_frame_ms, nodes.size()])
	assert_lt(per_frame_ms, 0.25, "well under a millisecond a frame")
	var meshes := 0
	for n in d.find_children("*", "MeshInstance3D", true, false):
		meshes += 1
	gut.p("CREATURES_MESHES %d" % meshes)
	assert_lte(meshes, 16, "a handful of draw calls")


## Cosmos: Venus's cloud city: the helper robot and the rover stand on the landing deck, the aliens camp on their own
## deck; the rover never drives down into the clouds between two decks (it keeps its height over a gap).
func test_venus_robots_on_the_landing_deck_and_the_aliens_on_theirs() -> void:
	d = _director(24, SpaceShape.VENUS)
	var v := shape.venus
	assert_eq(int(d.robot.global_position.y), VenusTerrain.DECK_Y, "the robot on the landing deck")
	assert_eq(v.platform_at(floori(d.robot.global_position.x), floori(d.robot.global_position.z))[0], VenusTerrain.LANDING)
	assert_not_null(d.camp, "the aliens' camp")
	var at: Vector3 = d.site.pos
	assert_true(v.camp_spot(floori(at.x), floori(at.z)), "on the camp deck")
	var open := shape.spawn_column() - v.north() * 30
	assert_true(is_nan(d.rover.ground_y.call(open.x, open.y)), "no ground for the rover over the clouds")
	var sp := shape.spawn_column()
	assert_eq(d.rover.ground_y.call(sp.x + 5, sp.y), float(VenusTerrain.DECK_Y), "the deck is its ground")


## Cosmos: Saturn's rings: the helper robot stands on the landing chunk, the aliens camp on their own chunk; the rover
## never drops into the open space between two chunks (it keeps its height over a gap, like Venus's).
func test_ring_robots_on_the_landing_chunk_and_the_aliens_on_theirs() -> void:
	d = _director(25, SpaceShape.RINGS)
	var r := shape.rings
	var sp := shape.spawn_column()
	assert_eq(int(d.robot.global_position.y), RingsTerrain.TOP_BASE, "the robot on the landing chunk")
	assert_eq(r.chunk_at(floori(d.robot.global_position.x), floori(d.robot.global_position.z))[7], RingsTerrain.LANDING)
	assert_not_null(d.camp, "the aliens' camp")
	var at: Vector3 = d.site.pos
	assert_true(r.camp_spot(floori(at.x), floori(at.z)), "on the camp chunk")
	var open := sp + Vector2i(0, RingsTerrain.C_IN - 30)
	assert_true(is_nan(d.rover.ground_y.call(open.x, open.y)), "no ground for the rover in open space")
	assert_eq(d.rover.ground_y.call(sp.x + 5, sp.y), float(RingsTerrain.TOP_BASE), "the chunk is its ground")


## Cosmos: Pluto: the helper robot Nixie stands on the uplands by the pad, the aliens camp on the calm uplands a short walk
## away (never on the heart's plain, the mountains or the Charon Lookout), the rover drives on the ground.
func test_pluto_robots_by_the_pad_and_the_aliens_on_the_uplands() -> void:
	d = _director(26, SpaceShape.PLUTO)
	var p := shape.pluto
	var pad := shape.spawn_column()
	assert_eq(d.robot.display_name, "Nixie")
	assert_eq(int(d.robot.global_position.y), shape.height_at(floori(d.robot.global_position.x), floori(d.robot.global_position.z)),
		"on the ground")
	assert_not_null(d.camp, "the aliens' camp")
	assert_eq(d.camp.explorer.display_name, "Wisp")
	assert_eq(d.camp.trader.display_name, "Tumble")
	var at: Vector3 = d.site.pos
	assert_eq(shape.pluto_kind(floori(at.x), floori(at.z)), PlutoTerrain.UPLANDS, "on the calm uplands")
	assert_false(p.on_lookout(floori(at.x), floori(at.z), 4), "clear of the Charon Lookout")
	assert_between(Vector2(at.x - pad.x, at.z - pad.y).length(), 25.0, 52.0, "a short walk away")
	assert_eq(d.rover.ground_y.call(pad.x + 5, pad.y), float(shape.height_at(pad.x + 5, pad.y)), "the ground is its ground")


## Cosmos: Triton: the helper robot Spout stands on the frost by the pad, the aliens camp on the calm band of frost a short
## walk away (never on the cap's geysers, the lake, the crater or the Neptune Lookout), the rover drives on the ground.
func test_triton_robots_by_the_pad_and_the_aliens_on_the_frost() -> void:
	d = _director(27, SpaceShape.TRITON)
	var t := shape.triton
	var pad := shape.spawn_column()
	assert_eq(d.robot.display_name, "Spout")
	assert_eq(int(d.robot.global_position.y), shape.height_at(floori(d.robot.global_position.x), floori(d.robot.global_position.z)),
		"on the ground")
	assert_not_null(d.camp, "the aliens' camp")
	assert_eq(d.camp.explorer.display_name, "Puffle")
	assert_eq(d.camp.trader.display_name, "Glim")
	var at: Vector3 = d.site.pos
	assert_eq(shape.triton_kind(floori(at.x), floori(at.z)), TritonTerrain.FROST, "on the calm frost")
	assert_false(t.on_lookout(floori(at.x), floori(at.z), 4), "clear of the Neptune Lookout")
	assert_between(Vector2(at.x - pad.x, at.z - pad.y).length(), 25.0, 52.0, "a short walk away")
	assert_eq(d.rover.ground_y.call(pad.x + 5, pad.y), float(shape.height_at(pad.x + 5, pad.y)), "the ground is its ground")


## Cosmos: Ganymede: the helper robot Compass stands on the smooth plain by the pad, the aliens camp on the smooth plain a
## short walk away (never on the grooves, the crater, the frost or a built part), the rover drives on the ground.
func test_ganymede_robots_by_the_pad_and_the_aliens_on_the_plain() -> void:
	d = _director(28, SpaceShape.GANYMEDE)
	var g := shape.ganymede
	var pad := shape.spawn_column()
	assert_eq(d.robot.display_name, "Compass")
	assert_eq(int(d.robot.global_position.y), shape.height_at(floori(d.robot.global_position.x), floori(d.robot.global_position.z)),
		"on the ground")
	assert_not_null(d.camp, "the aliens' camp")
	assert_eq(d.camp.explorer.display_name, "Lumo")
	assert_eq(d.camp.trader.display_name, "Ridgy")
	var at: Vector3 = d.site.pos
	assert_eq(shape.ganymede_kind(floori(at.x), floori(at.z)), GanymedeTerrain.SMOOTH, "on the smooth plain")
	assert_false(g.on_part(floori(at.x), floori(at.z), 4), "clear of the Jupiter Lookout")
	assert_between(Vector2(at.x - pad.x, at.z - pad.y).length(), 25.0, 52.0, "a short walk away")
	assert_eq(d.rover.ground_y.call(pad.x + 5, pad.y), float(shape.height_at(pad.x + 5, pad.y)), "the ground is its ground")
