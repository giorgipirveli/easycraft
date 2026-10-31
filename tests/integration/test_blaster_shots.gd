extends GutTest
## M3 Task 14b: blaster shots in a world (solo play: this game is the host). The host checks every shot
## (the blaster, a sane aim, its rate and reload, Survivor ammo) and flies it for everyone from a fixed pool
## (no node per shot, so 200 shots never grow the tree); shots stop at the first block (never through a
## wall), pass through players, and hit monsters, animals and practice targets.

const FLOOR := 10
const DT := 1.0 / 60.0
const F := ItemIds.FOAM_BLASTER

var _mode_before: StringName
var _feedback: Array[String] = []
var _cells := {}
var _n := 0


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	_feedback.clear()
	_cells = {}
	Session.magic_feedback.connect(_on_feedback)
	Session.blaster_reset()


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_feedback)
	Game.mode = _mode_before
	Session.survivor_reset()
	Session.blaster_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_feedback(text: String) -> void:
	_feedback.append(text)


func _block(p: Vector3i) -> int:
	if _cells.has(p):
		return _cells[p]
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _director() -> BlasterDirector:
	var d := BlasterDirector.new()
	d.name = "Blasters"
	d.block_at = _block
	add_child_autofree(d)
	d.set_physics_process(false)
	return d


## This game's own player, facing -Z.
func _player(feet: Vector3 = Vector3(0.5, FLOOR, 0.5), peer: int = 0) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer if peer != 0 else multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	p.avatar.rotation.y = 0.0
	return p


## `universe`: a later universe's monsters have more health (owner #53: rarer blasters one-shot small monsters in
## universe 1, so a test that watches a hit's effect uses a tougher one).
func _monster(kind: StringName, level: int, pos: Vector3, universe: int = 1) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "bm%d" % _n, "pos": pos, "yaw": 0.0, "wild": false,
		"universe": universe})
	m.block_at = _block
	add_child_autofree(m)
	m.set_physics_process(false)
	return m


func _fly(d: BlasterDirector, seconds: float = 3.0) -> void:
	for i in int(seconds / DT):
		d._physics_process(DT)
		if d.active_shots() == 0:
			return


# --- The host's checks ---

func test_a_blast_flies_one_pooled_shot_from_the_players_eye() -> void:
	var d := _director()
	var p := _player()
	Session.request_blast(F, Vector3(0, 0, -1))
	assert_eq(d.active_shots(), 1)
	var shot := d.pool().shot_position(d.pool().newest_id())
	assert_lt(shot.distance_to(p.eye_position()), 1.0, "it starts at the shooter")


func test_the_host_caps_the_rate_and_waits_for_the_reload() -> void:
	_player()
	var me := multiplayer.get_unique_id()
	var t := 5000
	var iv := int(BlasterRules.interval(F) * 1000.0)
	assert_true(Session.accept_blast(me, F, Vector3.FORWARD, t))
	assert_false(Session.accept_blast(me, F, Vector3.FORWARD, t + 20), "too fast")
	for i in BlasterRules.magazine(F) - 1:
		t += iv
		assert_true(Session.accept_blast(me, F, Vector3.FORWARD, t), "dart %d" % (i + 2))
	t += iv
	assert_false(Session.accept_blast(me, F, Vector3.FORWARD, t), "the magazine is empty: reloading")
	t += int(BlasterRules.reload_time(F) * 1000.0)
	assert_true(Session.accept_blast(me, F, Vector3.FORWARD, t), "reloaded")


func test_a_bad_aim_or_a_non_blaster_is_refused() -> void:
	_player()
	var me := multiplayer.get_unique_id()
	assert_false(Session.accept_blast(me, F, Vector3.ZERO, 1000))
	assert_false(Session.accept_blast(me, F, Vector3(NAN, 0, 1), 2000))
	assert_false(Session.accept_blast(me, ItemIds.SWORD, Vector3.FORWARD, 3000))
	assert_eq(_feedback, [] as Array[String], "nothing to tell")


func test_survivor_uses_one_ammo_a_shot_and_says_when_it_runs_out() -> void:
	Game.mode = ModeRules.SURVIVOR
	var p := _player()
	var inv := Inventory.new()
	inv.add(F, 1)
	inv.add(ItemIds.FOAM_DARTS, 2)
	Session.set_inventory(p.peer_id, inv)
	assert_true(Session.accept_blast(p.peer_id, F, Vector3.FORWARD, 1000))
	assert_true(Session.accept_blast(p.peer_id, F, Vector3.FORWARD, 2000))
	assert_eq(inv.count(ItemIds.FOAM_DARTS), 0, "two darts used")
	assert_false(Session.accept_blast(p.peer_id, F, Vector3.FORWARD, 3000))
	assert_eq(_feedback.size(), 1)
	assert_string_contains(_feedback[0], "Foam Darts")
	assert_false(Session.accept_blast(p.peer_id, F, Vector3.FORWARD, 3100))
	assert_eq(_feedback.size(), 1, "said once, not at every tap")


func test_survivor_needs_the_blaster_itself() -> void:
	Game.mode = ModeRules.SURVIVOR
	var p := _player()
	var inv := Inventory.new()
	inv.add(ItemIds.PARTY_ROCKETS, 5)
	Session.set_inventory(p.peer_id, inv)
	assert_false(Session.accept_blast(p.peer_id, ItemIds.CONFETTI_ROCKET, Vector3.FORWARD, 1000), "not owned")
	assert_eq(inv.count(ItemIds.PARTY_ROCKETS), 5, "nothing used")


func test_sandbox_blasters_never_need_ammo() -> void:
	var p := _player()
	Session.set_inventory(p.peer_id, Inventory.new())
	for i in 3:
		assert_true(Session.accept_blast(p.peer_id, ItemIds.PAINT_SPLATTER, Vector3.FORWARD, 1000 + i * 1000))


# --- The pool ---

func test_200_shots_never_add_a_node_or_a_material() -> void:
	var d := _director()
	var p := _player()
	d.spawn_blast(p.peer_id, F, Vector3(0, 0.2, -1))
	_fly(d)
	await get_tree().process_frame
	await get_tree().process_frame   # the player's held item appears on its first frames
	var before := get_tree().get_node_count()
	for i in 200:
		var b: int = ItemIds.BLASTERS[i % ItemIds.BLASTERS.size()]
		d.spawn_blast(p.peer_id, b, Vector3(sin(i * 0.3), 0.3, -cos(i * 0.3)))
		assert_lte(d.active_shots(), ShotPool.SIZE)
		if i % 7 == 0:
			for k in 5:
				d._physics_process(DT)
	_fly(d, 6.0)
	await get_tree().process_frame
	assert_eq(d.active_shots(), 0, "every shot ended")
	assert_eq(get_tree().get_node_count(), before, "no node per shot, no burst node per hit")
	for mi in d.pool().find_children("*", "MeshInstance3D", true, false):
		assert_null((mi as MeshInstance3D).material_override, "no material per shot")


func test_the_oldest_shot_makes_room_when_the_pool_is_full() -> void:
	var d := _director()
	var p := _player()
	for i in ShotPool.SIZE + 5:
		d.spawn_blast(p.peer_id, F, Vector3(0, 1, -1))
	assert_eq(d.active_shots(), ShotPool.SIZE)


# --- Hits ---

func test_a_foam_dart_hits_a_monster_ahead() -> void:
	var d := _director()
	var p := _player()
	var m := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, -5.5))
	await get_tree().physics_frame
	d.spawn_blast(p.peer_id, F, m.hit_center() - p.eye_position())
	_fly(d)
	assert_eq(m.hp, m.max_hp - BlasterRules.damage(F))
	assert_eq(d.active_shots(), 0, "the dart stopped on it")


func test_a_shot_never_goes_through_a_wall() -> void:
	var d := _director()
	var p := _player()
	for y in range(FLOOR, FLOOR + 4):
		for x in range(-2, 3):
			_cells[Vector3i(x, y, -3)] = BlockIds.STONE
	var m := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, -5.5))   # within the rocket's 4 blocks, behind the wall
	await get_tree().physics_frame
	for b in ItemIds.BLASTERS:
		Session.blaster_reset()
		d.spawn_blast(p.peer_id, b, m.hit_center() - p.eye_position())
		_fly(d)
	assert_eq(m.hp, m.max_hp, "the wall took every shot, the rocket's blast too")


## (Bot friends are not in CombatDirector.hittables at all: shots fly through them too.)
func test_shots_pass_through_other_players() -> void:
	var d := _director()
	var p := _player()
	var friend := _player(Vector3(0.5, FLOOR, -3.5), 7)
	var m := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, -7.5))
	await get_tree().physics_frame
	d.spawn_blast(p.peer_id, F, m.hit_center() - p.eye_position())
	_fly(d)
	assert_eq(friend.health.hp, Health.MAX_HP)
	assert_eq(m.hp, m.max_hp - BlasterRules.damage(F), "it went on to the monster behind")


func test_a_bubble_traps_a_small_monster_and_slows_a_big_one() -> void:
	var d := _director()
	var p := _player()
	var small := _monster(MonsterRules.GOBLIN, 2, Vector3(0.5, FLOOR, -5.5), 3)
	var big := _monster(MonsterRules.GOBLIN, 3, Vector3(3.5, FLOOR, -5.5), 3)
	await get_tree().physics_frame
	d.spawn_blast(p.peer_id, ItemIds.BUBBLE_CANNON, small.hit_center() - p.eye_position())
	_fly(d)
	Session.blaster_reset()
	d.spawn_blast(p.peer_id, ItemIds.BUBBLE_CANNON, big.hit_center() - p.eye_position())
	_fly(d)
	assert_true(small.bubbled(), "level 2: in a bubble")
	assert_false(big.bubbled(), "level 3: too big")
	assert_almost_eq(big.blast_speed(), BlasterRules.BUBBLE_SLOW, 0.001, "but slowed")
	assert_eq(d.marks_shown(), 1, "everyone sees the bubble")


func test_paint_slows_and_marks_a_monster() -> void:
	var d := _director()
	var p := _player()
	var m := _monster(MonsterRules.SLIME, 4, Vector3(0.5, FLOOR, -5.5))
	await get_tree().physics_frame
	d.spawn_blast(p.peer_id, ItemIds.PAINT_SPLATTER, m.hit_center() - p.eye_position())
	_fly(d)
	assert_true(m.painted())
	assert_almost_eq(m.blast_speed(), BlasterRules.PAINT_SLOW, 0.001)
	assert_eq(d.marks_shown(), 1)
	assert_eq(m.hp, m.max_hp - BlasterRules.damage(ItemIds.PAINT_SPLATTER))


func test_the_confetti_rocket_pushes_every_monster_within_4_blocks() -> void:
	var d := _director()
	var p := _player()
	var first := _monster(MonsterRules.GOBLIN, 3, Vector3(0.5, FLOOR, -8.5), 4)
	var near := _monster(MonsterRules.GOBLIN, 3, Vector3(3.0, FLOOR, -8.5), 4)
	var far := _monster(MonsterRules.GOBLIN, 3, Vector3(7.5, FLOOR, -8.5), 4)
	await get_tree().physics_frame
	d.spawn_blast(p.peer_id, ItemIds.CONFETTI_ROCKET, first.hit_center() - p.eye_position())
	_fly(d)
	var dmg := BlasterRules.damage(ItemIds.CONFETTI_ROCKET)
	assert_eq(first.hp, first.max_hp - dmg)
	assert_eq(near.hp, near.max_hp - dmg, "2.5 blocks from the blast")
	assert_gt(near.velocity.x, 1.0, "pushed away from it")
	assert_eq(far.hp, far.max_hp, "7 blocks away: untouched")


# --- Everyone sees them ---

func test_a_guest_flies_the_hosts_shot_and_stops_it_where_the_host_says() -> void:
	var d := _director()
	d._rpc_shot(42, F, Vector3(0, FLOOR + 1, 0), Vector3(0, 0, -20), 5)
	assert_eq(d.active_shots(), 1)
	d._physics_process(DT)
	d._rpc_end(42, Vector3(0, FLOOR + 1, -2), BlasterDirector.END_HIT)
	assert_eq(d.active_shots(), 0)


## Owner #53 made the Bubble Cannon hit hard (22): in universe 1 every small monster was defeated before its bubble could
## show (found by the acceptance smoke runs, 2026-09-25). A small one is trapped first and takes the hit when its
## bubble pops; the damage over a fight is the same (WeaponStrength).
func test_a_small_monster_floats_in_its_bubble_first_and_takes_the_hit_when_it_pops() -> void:
	var d := _director()
	var p := _player()
	var m := _monster(MonsterRules.GOBLIN, 2, Vector3(0.5, FLOOR, -5.5))   # universe 1: 10 hearts
	await get_tree().physics_frame
	d.spawn_blast(p.peer_id, ItemIds.BUBBLE_CANNON, m.hit_center() - p.eye_position())
	_fly(d)
	assert_true(is_instance_valid(m) and not m.is_queued_for_deletion(), "not defeated at once")
	if not is_instance_valid(m):
		return
	assert_true(m.bubbled(), "floating in its bubble")
	assert_eq(m.hp, m.max_hp, "the hit waits for the pop")
	for i in int((BlasterRules.BUBBLE_TIME + 0.3) / DT):
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			break
		m._blast_tick(DT)
	assert_true(not is_instance_valid(m) or m.is_queued_for_deletion() or m.hp <= m.max_hp - BlasterRules.damage(
		ItemIds.BUBBLE_CANNON), "pop: the hit lands")
