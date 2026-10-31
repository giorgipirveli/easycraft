extends GutTest
## Owner #45a (spec §14.17): the world's QuestDirector (node "Quests" on every peer). The universe's quest
## giver stands by the spawn (every game places it from the seed); its bubble says a story waits ("!") or
## "come back to me" ("?"); a story moves on through the child's real events, by walking to its place (the
## arrow shows the way) and back to the giver; a story done gives its keepsake, title, place and Survivor
## gold once; a story can wait for ever and go on where it was. Co-op: the host shares its story, a
## friend's matching events count, and everyone who helped (nobody else) gets the rewards.

const HOST := 1
const TILLY_AT := Vector3(10.5, 20.0, 0.5)

var d: ProgressData
var me: Player
var hud: Hud
var q: QuestDirector
var u := [1]
var targets := {}
var paid: Array = []
var rewarded: Array = []
var peers: Array = []
var _saved := {}


func before_each() -> void:
	d = ProgressData.new()
	u[0] = 1
	targets = {}
	paid = []
	rewarded = []
	peers = []
	_saved = {"universe": Progress.universe, "survivor": Progress.survivor, "ask_goal_gold": Progress.ask_goal_gold}
	Progress.universe = func() -> int: return u[0]
	Progress.survivor = func() -> bool: return false
	Progress.ask_goal_gold = func(_goal: StringName) -> void: pass
	Progress.begin(d)
	me = _player(HOST, Vector3(0.5, 20, 0.5))
	hud = Hud.new()
	add_child_autofree(hud)
	q = _director(ModeRules.SANDBOX, 1)


func after_each() -> void:
	Progress.end()
	for key: String in _saved:
		Progress.set(key, _saved[key])


func after_all() -> void:
	Audio.stop_all()


func _player(peer: int, at: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.viewer.free()
	p.set_physics_process(false)
	p.global_position = at
	p._spawned = true
	return p


func _director(mode: StringName, universe: int) -> QuestDirector:
	var dir := QuestDirector.new()
	dir.mode = mode
	dir.universe = universe
	dir.world_seed = 42
	dir.auto_tick = false
	dir.player = me
	dir.hud = hud
	dir.find_target = func(kind: StringName, _from: Vector3) -> Vector3: return targets.get(kind, Vector3.INF)
	dir.is_host = func() -> bool: return true
	dir.own_peer = func() -> int: return HOST
	dir.others = func() -> Array: return peers
	dir.give_gold = func(peer: int, gold: int) -> void: paid.append([peer, gold])
	dir.send_reward = func(peer: int, chain_id: StringName, _place: Dictionary) -> void: rewarded.append([peer, chain_id])
	add_child_autofree(dir)
	dir.arrow = FindArrow.new()
	hud.add_child(dir.arrow)
	dir.arrow.player = me
	return dir


func _banners() -> String:
	return hud.banner.showing() + " | " + " | ".join(hud.banner._queue.map(func(e: Array) -> String: return e[0]))


## Tilly's story "the lost map" to its last step (back to Tilly).
func _map_story_to_the_end() -> void:
	if not q.givers.has(&"tilly"):
		q.add_giver(&"tilly", TILLY_AT, 0.0)
	targets[&"treasure"] = Vector3(40.5, 20, 0.5)
	targets[&"ruins"] = Vector3(0.5, 20, 60.5)
	assert_true(q.start_chain(&"tilly_map"))
	Progress.event(&"secret_found/treasure")
	me.global_position = Vector3(0.5, 20, 58.5)
	Progress.event(&"secret_found/ruins")


# --- The givers ---

func test_the_universes_helper_stands_by_the_spawn_on_every_game() -> void:
	var z := _director(ModeRules.SURVIVOR, 2)
	var shape := UniverseRegistry.shape_for(2, 42)
	z.place_givers(shape, shape.spawn_column())
	for i in 600:
		if z.givers.has(&"zara"):
			break
		await get_tree().process_frame
	assert_true(z.givers.has(&"zara"), "Zara the explorer is placed (a worker thread finds her spot)")
	var spot := QuestRules.giver_for_world(42, shape, shape.spawn_column())
	assert_eq((z.givers[&"zara"] as Node3D).global_position, spot.pos)
	assert_true((z.givers[&"zara"] as Node3D).is_in_group(&"quest_givers"))


func test_tilly_stands_where_her_stall_would_be_only_in_a_sandbox() -> void:
	var shape := UniverseRegistry.shape_for(1, 42)
	q.place_givers(shape, shape.spawn_column())
	assert_true(q.givers.has(&"tilly"))
	assert_eq((q.givers[&"tilly"] as Node3D).global_position,
		TraderRules.stall_for_world(42, shape, shape.spawn_column()).pos)
	var s := _director(ModeRules.SURVIVOR, 1)
	s.place_givers(shape, shape.spawn_column())
	assert_false(s.givers.has(&"tilly"), "Survivor: Tilly is the trader at her stall")
	var w := _director(ModeRules.WAVE, 1)
	w.place_givers(shape, shape.spawn_column())
	assert_true(w.givers.is_empty(), "no stories in the Monster Wave arena")
	assert_false(w.tells_stories())


func test_the_bubble_says_a_story_waits_then_come_back() -> void:
	var tilly := q.add_giver(&"tilly", TILLY_AT, 0.0)
	q.tick()
	assert_eq(tilly.bubble_text(), QuestGiver.BUBBLE_NEW, "a story waits")
	_map_story_to_the_end()
	q.tick()
	assert_eq(tilly.bubble_text(), QuestGiver.BUBBLE_BACK, "come back to Tilly")
	me.global_position = TILLY_AT + Vector3(2, 0, 0)
	q.tick()
	assert_eq(tilly.bubble_text(), QuestGiver.BUBBLE_NEW, "the next story waits")


# --- A story through the real events ---

func test_a_step_moves_on_with_the_childs_own_events() -> void:
	q.add_giver(&"tilly", TILLY_AT, 0.0)
	Progress.event(&"secret_found/treasure")
	assert_true(q.start_chain(&"tilly_map"))
	assert_eq(QuestRules.step_index(d, &"tilly_map"), 0, "the treasure dug up before the story does not count")
	Progress.event(&"secret_found/treasure")
	assert_eq(QuestRules.step_index(d, &"tilly_map"), 1, "at once, through Progress.counted")
	assert_string_contains(_banners(), "Next: Find the old ruins on the map")
	assert_eq(d.count(&"quest_step"), 1)


func test_the_arrow_shows_the_way_and_coming_back_ends_the_story() -> void:
	_map_story_to_the_end()
	q.tick()
	assert_true(q.arrow.is_pointing())
	assert_eq(q.arrow.target, TILLY_AT, "back to Tilly")
	assert_eq(q.arrow.what, "Tilly")
	q.set_arrow(false)
	assert_false(q.arrow.is_pointing(), "the child turned the arrow off")
	q.set_arrow(true)
	assert_true(q.arrow.is_pointing())
	me.global_position = TILLY_AT + Vector3(2, 0, 0)
	q.tick()
	assert_true(QuestRules.is_done(d, &"tilly_map"))
	assert_has(QuestRules.keepsakes(d), &"old_key")
	assert_has(QuestRules.titles(d), &"q_tilly_map")
	assert_eq(d.quests.places.size(), 1)
	assert_almost_eq(float(d.quests.places[0].z), 58.5, 0.01, "the place is where the ruins were found")
	assert_eq(int(d.quests.places[0].seed), 42)
	assert_eq(d.count(&"quest_done/tilly_map"), 1)
	assert_string_contains(_banners(), "Story done: Tilly's lost map!")
	assert_true(paid.is_empty(), "the Sandbox pays no gold")
	q.tick()
	assert_false(q.arrow.is_pointing(), "nothing to show now")


func test_the_arrow_points_at_the_place_of_the_step() -> void:
	q.add_giver(&"tilly", TILLY_AT, 0.0)
	targets[&"treasure"] = Vector3(40.5, 20, 0.5)
	q.start_chain(&"tilly_map")
	assert_true(q.arrow.is_pointing())
	assert_eq(q.arrow.target, targets[&"treasure"])
	assert_eq(q.arrow.what, "the buried treasure")


## At the place itself the arrow rests: it doesn't blink on every second while the child digs there.
func test_the_arrow_rests_at_the_place() -> void:
	targets[&"treasure"] = me.global_position + Vector3(1, 0, 0)
	q.start_chain(&"tilly_map")
	assert_false(q.arrow.is_pointing(), "already there")
	q.tick()
	assert_false(q.arrow.is_pointing(), "and it stays off while the child stands there")
	me.global_position += Vector3(30, 0, 0)
	q.tick()
	assert_true(q.arrow.is_pointing(), "walking away shows the way again")


func test_follow_the_arrow_steps_are_done_by_walking_there() -> void:
	u[0] = 2
	var z := _director(ModeRules.SURVIVOR, 2)
	z.add_giver(&"zara", Vector3(0.5, 20, 15.5), 0.0)
	targets[&"treasure"] = Vector3(30.5, 20, 0.5)
	targets[&"temple"] = Vector3(-80.5, 20, 0.5)
	assert_true(z.start_chain(&"zara_scarab"))
	Progress.event(&"secret_found/treasure")
	z.tick()
	assert_eq(QuestRules.current_step(d, &"zara_scarab").type, QuestRules.REACH)
	assert_eq(z.arrow.target, targets[&"temple"], "the arrow shows the pyramid")
	me.global_position = Vector3(-60.5, 20, 0.5)
	z.tick()
	assert_eq(QuestRules.current_step(d, &"zara_scarab").type, QuestRules.REACH, "not there yet")
	me.global_position = Vector3(-75.5, 22, 3.5)
	z.tick()
	assert_eq(QuestRules.current_step(d, &"zara_scarab").type, QuestRules.DO, "arrived at the pyramid")


func test_a_story_done_in_survivor_pays_its_fixed_gold_once() -> void:
	u[0] = 2
	var z := _director(ModeRules.SURVIVOR, 2)
	var zara := z.add_giver(&"zara", Vector3(0.5, 20, 15.5), 0.0)
	targets[&"treasure"] = Vector3(30.5, 20, 0.5)
	targets[&"temple"] = Vector3(-80.5, 20, 0.5)
	z.start_chain(&"zara_scarab")
	Progress.event(&"secret_found/treasure")
	me.global_position = Vector3(-78.5, 20, 0.5)
	z.tick()
	Progress.event(&"secret_found/temple")
	me.global_position = zara.global_position + Vector3(1, 0, 1)
	z.tick()
	assert_true(QuestRules.is_done(d, &"zara_scarab"))
	assert_eq(paid, [[HOST, 200]], "100 × 2 in the desert, through the host")
	assert_false(z.host_gold(HOST, &"zara_scarab"), "once")
	assert_eq(paid.size(), 1)
	assert_string_contains(_banners(), "and 200 gold")


func test_a_story_can_wait_for_ever_and_go_on_where_it_was() -> void:
	q.add_giver(&"tilly", TILLY_AT, 0.0)
	q.start_chain(&"tilly_pets")
	Progress.event(&"animal_tamed/dog")
	Progress.event(&"monster_defeated/slime")
	q.stop_chain()
	var before := JSON.stringify(d.to_dict())
	for i in 2000:   # a very long time: nothing counts down, nothing is lost
		q.tick()
	assert_eq(JSON.stringify(d.to_dict()), before, "a waiting story never changes by itself")
	Progress.event(&"monster_defeated/slime")
	assert_eq(QuestRules.step_progress(d, &"tilly_pets").x, 1, "a waiting story counts nothing new, keeps what it had")
	assert_true(q.resume_chain(&"tilly_pets"))
	assert_eq(QuestRules.step_index(d, &"tilly_pets"), 1)
	assert_eq(QuestRules.step_progress(d, &"tilly_pets"), Vector2i(1, 3), "the slime beaten before the stop still counts")


func test_a_new_story_waits_for_nothing_the_old_one_keeps_its_place() -> void:
	q.start_chain(&"tilly_pets")
	Progress.event(&"animal_tamed/cat")
	assert_true(q.start_chain(&"tilly_map"))
	assert_eq(d.quests.active, &"tilly_map")
	assert_eq(QuestRules.step_index(d, &"tilly_pets"), 1, "waiting at its step")


func test_a_sandbox_is_offered_only_what_it_can_do() -> void:
	u[0] = 3
	var b := _director(ModeRules.SANDBOX, 3)
	assert_false(b.start_chain(&"bram_lantern"), "crafting is Survivor's")
	var s := _director(ModeRules.SURVIVOR, 3)
	assert_true(s.start_chain(&"bram_lantern"))


# --- Co-op: the host decides ---

func test_only_the_host_shares_a_story_of_this_world() -> void:
	assert_false(q.share(true), "no story to share")
	q.start_chain(&"tilly_map")
	q.is_host = func() -> bool: return false
	assert_false(q.share(true), "a guest can't")
	q.is_host = func() -> bool: return true
	assert_true(q.share(true))
	assert_true(q.is_sharing())
	assert_eq(q.team_state().chain, "tilly_map")
	assert_true(q.share(false))
	assert_false(q.is_sharing())
	u[0] = 2
	var z := _director(ModeRules.SURVIVOR, 2)
	d.quests.active = &""
	QuestRules.start(d, &"tilly_map")
	assert_false(z.share(true), "Tilly's story is not a desert story")


func test_a_friends_matching_events_count_for_the_shared_story() -> void:
	peers = [7]
	q.start_chain(&"tilly_map")
	q.share(true)
	assert_false(q.on_team_event(7, &"photo_taken", 1), "only what the step asks")
	assert_false(q.on_team_event(9, &"secret_found/treasure", 1), "only a player in the game")
	assert_false(q.on_team_event(7, &"cheat_code", 1))
	assert_true(q.on_team_event(7, &"secret_found/treasure", 1))
	assert_eq(QuestRules.step_index(d, &"tilly_map"), 1, "the friend's find moved the shared story on")
	assert_has(q.helpers(), 7)


func test_a_flood_of_events_from_a_guest_is_capped() -> void:
	peers = [7]
	q.start_chain(&"tilly_pets")
	q.share(true)
	for i in QuestDirector.TEAM_EVENTS:
		q.on_team_event(7, &"photo_taken", 1)
	assert_false(q.on_team_event(7, &"animal_tamed/dog", 1), "too many at once")


func test_everyone_who_helped_gets_the_reward_and_nobody_else() -> void:
	peers = [7, 8, 9]
	var far := _player(7, Vector3(300.5, 20, 0.5))
	var near := _player(8, Vector3(0.5, 20, 60.5))
	var away := _player(9, Vector3(-300.5, 20, 0.5))
	await get_tree().process_frame
	q.add_giver(&"tilly", TILLY_AT, 0.0)
	targets[&"ruins"] = Vector3(0.5, 20, 60.5)
	q.start_chain(&"tilly_map")
	assert_true(q.share(true))
	q.on_team_event(7, &"secret_found/treasure", 1)       # the far friend found the treasure
	me.global_position = Vector3(1.5, 20, 58.5)
	Progress.event(&"secret_found/ruins")                 # the host found the ruins, friend 8 was right there
	near.global_position = TILLY_AT + Vector3(-2, 0, 0)   # friend 8 walks back to Tilly
	q.tick()
	assert_true(QuestRules.is_done(d, &"tilly_map"))
	rewarded.sort()
	assert_eq(rewarded, [[7, &"tilly_map"], [8, &"tilly_map"]], "the helpers, not the friend far away")
	assert_false(q.is_sharing(), "the shared story is over")
	assert_true(is_instance_valid(far) and is_instance_valid(away))


func test_a_helper_gets_keepsake_title_place_and_survivor_gold_once() -> void:
	var s := _director(ModeRules.SURVIVOR, 1)
	var place := {"u": 1, "seed": 42, "x": 3.0, "y": 20.0, "z": 4.0}
	s.receive_team_reward(&"tilly_map", place)
	assert_true(QuestRules.is_done(d, &"tilly_map"))
	assert_has(QuestRules.keepsakes(d), &"old_key")
	assert_has(QuestRules.titles(d), &"q_tilly_map")
	assert_eq(d.quests.places.size(), 1)
	assert_eq(paid, [[HOST, 100]])
	s.receive_team_reward(&"tilly_map", place)
	assert_eq(paid.size(), 1, "rewards once")
	assert_eq(d.quests.places.size(), 1)
	s.receive_team_reward(&"no_such_story", place)
	assert_eq(d.quests.done.size(), 1)


func test_a_guest_sees_the_shared_story_and_its_arrow() -> void:
	q.is_host = func() -> bool: return false
	q._rpc_team({"chain": "tilly_map", "step": 1, "have": 0, "need": 1, "target": Vector3(5.5, 20, 5.5)})
	assert_eq(q.team_view.chain, &"tilly_map")
	assert_true(q.arrow.is_pointing())
	assert_eq(q.arrow.target, Vector3(5.5, 20, 5.5))
	q._rpc_team({"chain": "made_up"})
	assert_true(q.team_view.is_empty(), "an unknown story is nothing")


## Bot friends lead a child to its story's place ("follow the arrow"): the host knows every child's.
func test_bots_are_told_where_each_childs_story_leads() -> void:
	assert_eq(q.target_for(HOST), {}, "no story: nothing")
	targets[&"treasure"] = Vector3(40.5, 20, 0.5)
	q.start_chain(&"tilly_map")
	assert_eq(q.target_for(HOST), {"pos": targets[&"treasure"], "kind": &"quest"})
	q._guest_targets[7] = Vector3(1, 2, 3)
	assert_eq(q.target_for(7).pos, Vector3(1, 2, 3), "a guest's own story (its game tells the host)")
	assert_eq(q.target_for(9), {})


## The nearest place of a kind nobody found, from the world's real secret rules (the arrow's worker thread).
func test_the_nearest_place_skips_found_ones() -> void:
	var rules := SecretRules.new(12345)
	var from := Vector3(0, 30, 0)
	var first := QuestDirector.nearest_place(rules, &"treasure", from, {}, 500.0)
	assert_true(first.is_finite(), "buried treasure near the spawn")
	var skip := {}
	for s: Dictionary in rules.secrets_near(from, 500.0):
		if s.kind == &"treasure" and (Vector3(s.chest as Vector3i) + Vector3(0.5, 0, 0.5)) == first:
			skip[s.id] = true
	var second := QuestDirector.nearest_place(rules, &"treasure", from, skip, 500.0)
	assert_ne(second, first, "a found one is skipped")
	assert_eq(QuestDirector.nearest_place(rules, &"treasure", from, {}, 0.0), Vector3.INF)
