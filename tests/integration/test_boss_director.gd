extends GutTest
## M2 Task 10: the host's BossDirector (spec §12.9; research G3, D8): the Golem comes to the Totem with
## health by team size, one at a time; a win pays 300 gold split among the players (nothing in
## Sandbox), opens the desert portal by the Totem and unlocks universe 2 in the profile once; a lost
## fight shows how far the team got, three lost fights bring a tired Golem that says so, a win resets
## the help; the HUD's boss bar follows the fight; help and the portal are saved per world.

const FLOOR := 10
const DT := 1.0 / 60.0
const TOTEM := Vector3(20.5, FLOOR, 3.5)

var _mode_before: StringName
var _gold_before := 0
var _universe_before := 1
var _paid: Array = []
var _toasts: Array = []
var _ended: Array = []
var _started: Array = []


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	_universe_before = Profile.data.universe_unlocked
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 0
	Profile.data.universe_unlocked = 1
	_paid.clear()
	_toasts.clear()
	_ended.clear()
	_started.clear()
	Session.magic_feedback.connect(_on_toast)
	UniverseRegistry.use(2, null)   # M3 Task 5: M2's portal, while the desert's file isn't there


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_toast)
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.universe_unlocked = _universe_before
	Session.survivor_reset()
	Music.reset()
	UniverseRegistry.reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_toast(text: String) -> void:
	_toasts.append(text)


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _director(stub_gold: bool = false) -> BossDirector:
	var d := BossDirector.new()
	d.name = "Boss"
	d.block_at = _flat
	if stub_gold:
		d.pay_gold = func(peer: int, amount: int) -> void: _paid.append([peer, amount])
	d.fight_started.connect(func(tired: bool) -> void: _started.append(tired))
	d.fight_ended.connect(func(won: bool, percent: int) -> void: _ended.append([won, percent]))
	var bar := BossBar.new()
	add_child_autofree(bar)
	d.bar = bar
	add_child_autofree(d)
	return d


## A player standing still at `feet` (peer 1 is this game's own).
func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


## Stands in for a bot friend (team size counts the group "bot_friends").
func _friend() -> Node3D:
	var n := Node3D.new()
	n.add_to_group(&"bot_friends")
	add_child_autofree(n)
	return n


func _ready_golem(d: BossDirector) -> StoneGolem:
	var g := d.golem()
	g.start_phase(BossRules.Phase.WALK)   # past its rise: it can be hit
	return g


func _win(d: BossDirector) -> void:
	var g := _ready_golem(d)
	g.take_hit(100000, g.global_position + Vector3(0, 1, 3), Vector3.ZERO)


# --- Start ---

func test_the_golem_rises_next_to_the_totem_with_health_by_team_size() -> void:
	_player(TOTEM + Vector3(2, 0, 0))
	await get_tree().physics_frame
	var d := _director()
	assert_eq(d.start(TOTEM), "")
	var g := d.golem()
	assert_not_null(g)
	var spot := BossRules.golem_spot(TOTEM)
	assert_almost_eq(g.global_position.x, spot.x, 0.01)
	assert_almost_eq(g.global_position.z, spot.z, 0.01)
	assert_eq(g.global_position.y, float(FLOOR), "standing on the ground")
	assert_eq(g.max_hp, 300, "one player")
	assert_eq(g.phase, BossRules.Phase.RISE)
	assert_eq(_started, [false])
	assert_true(d.fighting())


func test_bot_friends_make_it_stronger_like_players() -> void:
	_player(TOTEM)
	_friend()
	_friend()
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	assert_eq(d.golem().max_hp, 600, "a player and two friends: a team of 3")


func test_only_one_golem_at_a_time() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	assert_eq(d.start(TOTEM), BossDirector.BUSY_MESSAGE)
	assert_eq(d.golems().size(), 1)


# --- A win ---

func test_a_win_pays_300_gold_opens_the_portal_and_unlocks_universe_2_once() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	_win(d)
	assert_eq(Profile.data.survivor_gold, 300, "one player: all 300")
	assert_eq(Profile.data.universe_unlocked, 2)
	assert_eq(_ended, [[true, 0]])
	assert_false(d.fighting())
	var portals := d.portals()
	assert_eq(portals.size(), 1, "a portal by the Totem")
	var spot := BossRules.portal_spot(TOTEM)
	assert_almost_eq(Vector2(portals[0].global_position.x, portals[0].global_position.z).distance_to(Vector2(spot.x, spot.z)), 0.0, 0.01)
	assert_eq(d.portal_pos, portals[0].global_position)
	assert_eq(d.help.wins, 1)
	await get_tree().process_frame
	d.start(TOTEM)
	_win(d)
	assert_eq(Profile.data.universe_unlocked, 2, "a second win opens nothing more")
	assert_eq(d.portals().size(), 1, "still one portal")
	assert_eq(Profile.data.survivor_gold, 600)


func test_the_gold_is_split_among_the_players() -> void:
	_player(TOTEM)
	_player(TOTEM + Vector3(3, 0, 0), 7)
	await get_tree().physics_frame
	var d := _director(true)
	d.start(TOTEM)
	_win(d)
	assert_eq(_paid, [[1, 150], [7, 150]])


func test_sandbox_pays_nothing_and_unlocks_nothing_but_the_portal_still_opens() -> void:
	Game.mode = ModeRules.SANDBOX
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director(true)
	d.start(TOTEM)
	_win(d)
	assert_eq(_paid, [], "Sandbox gold is ∞")
	assert_eq(Profile.data.universe_unlocked, 1, "a summoned Sandbox Golem opens no universe")
	assert_eq(d.portals().size(), 1, "the peek is there to see")


func test_the_portal_peeks_into_the_desert_with_its_message_and_shared_looks() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	_win(d)
	var portal: DesertPortal = d.portals()[0]
	assert_eq(portal.message(), BossRules.PORTAL_MESSAGE)
	assert_same(portal.window().material_override, DesertPortal.window_material(), "one shared scrolling shader")
	assert_true(DesertPortal.window_material().shader.code.contains("TIME"), "it moves by itself on the GPU")
	assert_same(portal.frame().mesh, GolemModels.portal_frame_mesh())
	var other := DesertPortal.new()
	other.setup({"id": "p2", "pos": Vector3(0, FLOOR, 0), "yaw": 0.0})
	add_child_autofree(other)
	assert_same(other.window().material_override, portal.window().material_override)


func test_the_portal_tells_a_child_who_comes_close() -> void:
	var me := _player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.restore(BossRules.new_help(), TOTEM + Vector3(3, 0, 0))
	var portal: DesertPortal = d.portals()[0]
	me.global_position = portal.global_position + Vector3(0, 0, 10)
	portal.tick(1.0)
	assert_false(_toasts.has(BossRules.PORTAL_MESSAGE))
	me.global_position = portal.global_position + Vector3(0, 0, 1.5)
	portal.tick(1.0)
	assert_true(_toasts.has(BossRules.PORTAL_MESSAGE))
	assert_true(portal.is_blowing(), "sand blows out and the wind plays near it")


# --- Honest help ---

func test_a_lost_fight_shows_how_far_the_team_got() -> void:
	var me := _player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	var g := _ready_golem(d)
	g.take_hit(240, TOTEM, Vector3.ZERO)
	me.knocked_out = true                               # the only player is knocked out: the fight is lost
	d.tick(0.2)
	assert_eq(_ended, [[false, 20]])
	assert_eq(d.bar.title(), "You got it to 20%!")
	assert_almost_eq(d.bar.fraction(), 0.2, 0.001, "the bar stays where they got it")
	assert_true(g.is_down(), "it goes back to sleep")
	assert_eq(d.help.losses, 1)
	assert_eq(Profile.data.survivor_gold, 0, "no gold for a lost fight")


func test_three_lost_fights_bring_a_tired_golem_that_says_so() -> void:
	var me := _player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	for i in 3:
		me.knocked_out = false
		assert_eq(d.start(TOTEM), "", "fight %d" % (i + 1))
		assert_eq(d.golem().max_hp, 300)
		me.knocked_out = true
		d.tick(0.2)
		for g in d.golems():
			g.free()
	me.knocked_out = false
	d.start(TOTEM)
	assert_true(d.golem().tired)
	assert_eq(d.golem().max_hp, 225, "a quarter less health")
	assert_eq(_started[-1], true)
	assert_has(_toasts, BossRules.TIRED_MESSAGE, "announced, not hidden")
	assert_eq(d.bar.title(), BossBar.TIRED_TITLE)


func test_a_win_resets_the_help() -> void:
	var me := _player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.restore({"losses": 4, "best": 10, "wins": 0}, Vector3.INF)
	d.start(TOTEM)
	assert_true(d.golem().tired)
	_win(d)
	assert_eq(d.help.losses, 0)
	await get_tree().process_frame
	me.knocked_out = false
	d.start(TOTEM)
	assert_false(d.golem().tired, "a full-strength Golem again")


func test_in_sandbox_a_knock_out_does_not_end_the_fight_but_walking_away_does() -> void:
	Game.mode = ModeRules.SANDBOX
	var me := _player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	me.knocked_out = true
	d.tick(0.5)
	assert_true(d.fighting(), "Sandbox players pop right back up")
	me.knocked_out = false
	me.global_position = TOTEM + Vector3(80, 0, 0)
	for i in int(BossRules.LEAVE_TIME / 0.1) + 2:
		d.tick(0.1)
	assert_false(d.fighting(), "nobody near it for a while: it goes back to sleep")
	assert_eq(_ended.size(), 1)
	assert_false(_ended[0][0])


# --- The HUD bar ---

func test_the_boss_bar_follows_the_fight() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.tick(DT)
	assert_false(d.bar.visible, "no bar without a Golem")
	d.start(TOTEM)
	d.tick(DT)
	assert_true(d.bar.visible)
	assert_eq(d.bar.title(), BossBar.TITLE)
	assert_almost_eq(d.bar.fraction(), 1.0, 0.001)
	var g := _ready_golem(d)
	g.take_hit(150, TOTEM, Vector3.ZERO)
	d.tick(DT)
	assert_almost_eq(d.bar.fraction(), 0.5, 0.001, "half its health: half the bar (a bar, not a number)")
	g.start_phase(BossRules.Phase.DAZED)
	d.tick(DT)
	assert_true(d.bar.shows_double(), "the bar says hits count double now")
	_win(d)
	d.tick(DT)
	assert_eq(d.bar.title(), BossRules.WIN_MESSAGE)
	for i in int(BossDirector.RESULT_TIME / 0.5) + 2:
		d.tick(0.5)
	assert_false(d.bar.visible, "it goes away after a while")


# --- Saving ---

func test_help_and_the_portal_are_saved_and_restored() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.restore({"losses": 2, "best": 35, "wins": 1}, TOTEM + Vector3(3, 0, 0))
	assert_eq(d.help, {"losses": 2, "best": 35, "wins": 1})
	assert_eq(d.portals().size(), 1, "the portal is back where it opened")
	assert_eq(d.portal_pos, TOTEM + Vector3(3, 0, 0))
	var meta := WorldMeta.new_random()
	d.save_into(meta)
	assert_eq(meta.boss_help, d.help)
	assert_eq(meta.portal_pos, d.portal_pos)


## Stands in for Task 9's WaveDirector (merged separately): the Totem's Stone Golem button and the
## "boss running" switch (the Totem glows and refuses waves, no night monsters meanwhile).
class FakeWaves:
	extends Node
	signal boss_requested(peer_id: int, totem_pos: Vector3)
	signal boss_offered(totem_pos: Vector3)
	var running: Array[bool] = []

	func set_boss_running(on: bool) -> void:
		running.append(on)


func test_the_totems_golem_button_starts_the_fight_and_the_totem_knows_it_runs() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	var waves := FakeWaves.new()
	add_child_autofree(waves)
	d.link_waves(waves)
	waves.boss_requested.emit(1, TOTEM)
	assert_true(d.fighting(), "the Golem comes to the Totem")
	assert_eq(waves.running, [true] as Array[bool])
	waves.boss_requested.emit(1, TOTEM)
	assert_has(_toasts, BossDirector.BUSY_MESSAGE, "the child who tapped hears why not")
	assert_eq(d.golems().size(), 1)
	_win(d)
	assert_eq(waves.running, [true, false] as Array[bool], "won: the Totem takes waves again")
	await get_tree().process_frame
	waves.boss_requested.emit(1, TOTEM)
	d.golem().start_phase(BossRules.Phase.WALK)
	for p in get_tree().get_nodes_in_group(&"players"):
		(p as Player).knocked_out = true
	d.tick(0.2)
	assert_eq(waves.running, [true, false, true, false] as Array[bool], "lost: the same")


func test_linking_nothing_or_something_without_the_hooks_is_harmless() -> void:
	var d := _director()
	d.link_waves(null)
	var plain := Node.new()
	add_child_autofree(plain)
	d.link_waves(plain)
	assert_false(d.fighting())


func test_a_win_is_celebrated_by_everyone_when_the_game_can() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	var calls: Array = []
	d.celebrate = func() -> void: calls.append(true)
	d.start(TOTEM)
	_win(d)
	assert_eq(calls.size(), 1, "every player dances (Session.celebrate_all, M3 Task 9)")


## Stands in for the world and counts every change anybody makes to it.
class WatchedWorld:
	extends WorldService
	var edits := 0

	func get_block(pos: Vector3i) -> int:
		return BlockIds.GRASS if pos.y < 10 else BlockIds.AIR

	func set_block(_pos: Vector3i, _id: int) -> void:
		edits += 1

	func is_editable(_pos: Vector3i) -> bool:
		return true


func test_the_fight_and_the_portal_never_change_blocks() -> void:
	var w := WatchedWorld.new()
	autofree(w)
	var before := Session.world
	Session.register_world(w)
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.block_at = w.get_block
	d.start(TOTEM)
	for i in int(12.0 / DT):
		if d.golem():
			d.golem()._physics_process(DT)
		d.tick(DT)
	_win(d)
	for p in d.portals():
		p.tick(1.0)
	Session.register_world(before)
	assert_eq(w.edits, 0)
	for path in ["res://world/boss_director.gd", "res://entities/portal/desert_portal.gd", "res://ui/hud/boss_bar.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for call in ["set_block", "request_set_block", "set_voxel(", "do_box", "do_sphere"]:
			assert_false(src.contains(call), "%s never calls %s" % [path.get_file(), call])
