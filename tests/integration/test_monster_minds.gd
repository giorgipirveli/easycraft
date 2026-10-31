extends GutTest
## Monsters with minds (M2 Task 18 part 2, owner feedback #24, spec §12.17): while a monster chases
## what it sees, its mind picks a fair, signalled tactic — zigzag, go round, wait by cover, back off
## when hurt, call a friend, or straight at you — and its kind's table in the world learns (a goblin
## shot from far learns to zigzag within a few encounters). Never faster, stronger, sharper-eyed or
## tougher than §12.4/§12.5; it eases off after the child's knock-outs; Cozy worlds never learn;
## golden slimes never think. Solo: this game is the host.

const FLOOR := 10
const DT := 1.0 / 60.0

var _mode: StringName
var _book: MindBook
var _minds: MonsterMinds
var _n := 0
var _cells := {}


func before_each() -> void:
	_mode = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_book = MindBook.current
	MindBook.current = MindBook.new()
	_minds = MonsterMinds.current
	MonsterMinds.current = MonsterMinds.new()
	StealthDirector.clear_noises()
	_cells.clear()


func after_each() -> void:
	Game.mode = _mode
	MindBook.current = _book
	MonsterMinds.current = _minds
	StealthDirector.clear_noises()
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _block(p: Vector3i) -> int:
	return _cells.get(p, BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR)


func _ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)


func _monster(kind: StringName, pos: Vector3, yaw := 0.0, golden := false) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": 1, "id": "mm%d" % _n, "pos": pos, "yaw": yaw, "wild": true, "universe": 1,
		"golden": golden})
	m.block_at = _block
	add_child_autofree(m)
	return m


## A child standing at `feet`, looking along -Z (the avatar's yaw 0), holding `held`.
func _player(feet: Vector3, held := 0, peer := 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.set_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	p.held_item = held
	return p


func _steps(m: Monster, n: int) -> void:
	for i in n:
		if is_instance_valid(m):
			m._physics_process(DT)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Off the straight line from `from` to `to`, sideways.
func _off_line(p: Vector3, from: Vector3, to: Vector3) -> float:
	var line := Vector2(to.x - from.x, to.z - from.z).normalized()
	var v := Vector2(p.x - from.x, p.z - from.z)
	return absf(line.x * v.y - line.y * v.x)


## A goblin 12 blocks from a child in daylight, facing them, that has seen them.
func _goblin_seeing(p: Player, from := Vector3(0.5, FLOOR, 12.5)) -> Monster:
	var g := _monster(MonsterRules.GOBLIN, from)            # faces -Z: towards the child at z 0.5
	await get_tree().physics_frame                           # players are looked up once a frame
	for i in 30:
		_steps(g, 1)
		if g.awareness.sees:
			break
	return g


# --- Thinking at all ---

func test_a_monster_that_sees_a_child_picks_a_tactic_and_golden_slimes_never_think() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var g := await _goblin_seeing(p)
	assert_true(g.awareness.sees, "it saw the child")
	assert_not_null(g.mind)
	assert_ne(g.tactic, &"", "and picked a tactic")
	assert_has(MonsterSpecies.ACTIONS, g.tactic)
	var gold := _monster(MonsterRules.SLIME, Vector3(3.5, FLOOR, 6.5), 0.0, true)
	_steps(gold, 30)
	assert_null(gold.mind, "golden slimes run away and never think")
	assert_eq(gold.tactic, &"")


# --- The tactics, each fair and signalled ---

func _approach(g: Monster, p: Player, tactic: StringName, frames: int) -> Dictionary:
	g.use_tactic(tactic, p)
	var start := g.global_position
	var fastest := 0.0
	var off := 0.0
	for i in frames:
		_steps(g, 1)
		fastest = maxf(fastest, Vector2(g.velocity.x, g.velocity.z).length())
		off = maxf(off, _off_line(g.global_position, start, p.global_position))
	return {"fastest": fastest, "off": off, "end": _flat(g.global_position, p.global_position), "start": _flat(start, p.global_position)}


func test_a_zigzag_weaves_in_and_is_never_faster_than_the_spec() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5), ItemIds.BOW)
	var g := await _goblin_seeing(p)
	var r := _approach(g, p, MonsterSpecies.ZIGZAG, 150)
	assert_gt(r.off, 0.5, "it weaves from side to side: %s" % [r])
	assert_lt(r.end, r.start - 3.0, "and still comes closer")
	assert_lte(r.fastest, MonsterRules.speed(MonsterRules.GOBLIN, 1) + 0.01, "never faster than §12.4")


func test_going_round_comes_from_the_side() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5), ItemIds.SWORD)
	p.avatar.rotation.y = PI                                 # the child looks at the goblin (+Z)
	var g := await _goblin_seeing(p)
	var r := _approach(g, p, MonsterSpecies.GO_ROUND, 150)
	assert_gt(r.off, 1.5, "a curve round the child's side: %s" % [r])
	assert_lt(r.end, 6.0, "then in")
	assert_lte(r.fastest, MonsterRules.speed(MonsterRules.GOBLIN, 1) + 0.01)


func test_a_hurt_goblin_backs_off_at_a_walk_then_comes_again() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var g := await _goblin_seeing(p, Vector3(0.5, FLOOR, 3.5))
	g.hp = 3
	var r := _approach(g, p, MonsterSpecies.BACK_OFF, 60)
	assert_gt(r.end, r.start + 1.0, "it stepped back: %s" % [r])
	assert_lte(r.fastest, MonsterRules.speed(MonsterRules.GOBLIN, 1) * Monster.WARY_SPEED + 0.01, "at the wary pace")
	assert_eq(g.alert, StealthRules.MARK_BANG, "still showing ! (it knows where you are)")
	g.mind.tick(5.0)                                         # its tactic has run its course
	_steps(g, 12)
	assert_ne(g.tactic, MonsterSpecies.BACK_OFF, "not twice in a row: the child can chase it")


func test_waiting_stands_and_the_child_coming_close_ends_it() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5), ItemIds.BOW)
	var g := await _goblin_seeing(p, Vector3(0.5, FLOOR, 13.5))
	g.use_tactic(MonsterSpecies.WAIT, p)
	var before := g.global_position
	_steps(g, 60)
	assert_lt(_flat(g.global_position, p.global_position), _flat(before, p.global_position) + 0.5)
	assert_gt(_flat(g.global_position, p.global_position), 10.0, "it waits instead of coming in")
	p.global_position = g.global_position + Vector3(0, 0, -3.0)
	await get_tree().physics_frame
	_steps(g, 30)
	assert_ne(g.tactic, MonsterSpecies.WAIT, "close up it thinks again")


func test_waiting_by_cover_means_a_spot_with_a_block_between_it_and_the_child() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 13.5))
	var child := Vector3(0.5, FLOOR, 0.5)
	assert_false(g._cover_spot(child).is_finite(), "open grass: no cover, it just stands")
	for y in 2:
		_cells[Vector3i(0, FLOOR + y, 10)] = BlockIds.STONE   # a pillar two blocks towards the child
	var spot := g._cover_spot(child)
	assert_true(spot.is_finite())
	assert_eq(Vector3i(spot.floor()), Vector3i(0, FLOOR, 11), "right behind the pillar")


func test_a_call_brings_a_quiet_friend_with_a_question_mark() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var g := await _goblin_seeing(p)
	var friend := _monster(MonsterRules.GOBLIN, Vector3(10.5, FLOOR, 16.5), PI)   # looks away, too far to see
	_steps(friend, 6)
	assert_eq(friend.awareness.state, StealthRules.Alert.NONE)
	g.use_tactic(MonsterSpecies.CALL, p)
	assert_eq(friend.awareness.state, StealthRules.Alert.SUSPICIOUS, "it heard the call: ?")
	assert_almost_eq(friend.awareness.spot, p.global_position, Vector3.ONE * 0.01, "and goes to where the child is")
	assert_eq(friend.alert, StealthRules.MARK_QUESTION, "shown to everyone")
	var far := _monster(MonsterRules.GOBLIN, Vector3(40.5, FLOOR, 40.5))
	g._call_t = 0.0
	g.use_tactic(MonsterSpecies.CALL, p)
	assert_eq(far.awareness.state, StealthRules.Alert.NONE, "a call carries 12 blocks, not further")


# --- Fair: never more than the spec ---

func test_tactics_never_add_speed_hits_hearts_or_sight() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5), ItemIds.BOW)
	for tactic in MonsterSpecies.ACTIONS:
		var g := await _goblin_seeing(p)
		assert_eq(g.max_hp, MonsterRules.hp(MonsterRules.GOBLIN, 1), tactic)
		var r := _approach(g, p, tactic, 90)
		assert_lte(r.fastest, MonsterRules.speed(MonsterRules.GOBLIN, 1) + 0.01, "%s: speed" % tactic)
		g.free()
	assert_eq(Monster.PERCEIVE_RANGE, StealthRules.SIGHT * StealthRules.HALF_SEEN, "sight is stealth's")
	var hp := p.health.hp
	var g2 := await _goblin_seeing(p, Vector3(0.5, FLOOR, 2.0))
	g2.use_tactic(MonsterSpecies.ZIGZAG, p)
	g2._hurt(p)
	assert_eq(hp - p.health.hp, MonsterRules.hit(MonsterRules.GOBLIN, 1), "a hit is §12.4's")


## Task 8's lantern fear still wins over any tactic: weak monsters weaving or curving in stay 6 blocks away.
func test_no_tactic_takes_a_weak_monster_into_a_lanterns_light() -> void:
	_ground()
	var lantern := Vector3i(8, FLOOR, 0)
	_cells[lantern] = BlockIds.LANTERN
	var p := _player(Vector3(8.5, FLOOR, 1.5), ItemIds.BOW)   # right next to the lantern
	var list: Array[Monster] = []
	for kind in MonsterRules.KINDS:
		var m := _monster(kind, Vector3(-6.5, FLOOR, 1.5 + 3.0 * list.size()), -PI * 0.5)
		m.lanterns.assign([lantern])
		list.append(m)
	await get_tree().physics_frame
	var closest := INF
	for i in 720:
		for m in list:
			m._target = p
			m.awareness.see(p.global_position)
			if i % 60 == 0:
				m.use_tactic(MonsterSpecies.ZIGZAG if (i / 60) % 2 == 0 else MonsterSpecies.GO_ROUND, p)
			m._physics_process(DT)
			closest = minf(closest, (Vector3(lantern) + Vector3(0.5, 0.5, 0.5)).distance_to(m.global_position))
	assert_gte(closest, DefenseRules.LANTERN_KEEP_AWAY - 0.25, "level 1 stays about 6 blocks away, whatever the tactic")


# --- Learning ---

## The plan's test: a goblin hit by arrows from far learns to zigzag within a few encounters (each
## night a new goblin; the world's goblin table remembers). Straight at an archer: arrows. Weaving in: it
## gets there.
func test_a_goblin_shot_from_far_learns_to_zigzag_within_a_few_encounters() -> void:
	_ground()
	var said: Array[String] = []
	MonsterMinds.current.hint.connect(func(t: String) -> void: said.append(t))
	var p := _player(Vector3(0.5, FLOOR, 0.5), ItemIds.BOW)
	var mask := MonsterSpecies.allowed(12.0, true, false, 1.0, false, false)
	var learned_after := -1
	for night in 10:
		var g := await _goblin_seeing(p)
		var odds := MonsterSpecies.odds(g.mind, mask)
		if learned_after < 0 and odds[MonsterSpecies.index(MonsterSpecies.ZIGZAG)] > odds[MonsterSpecies.index(MonsterSpecies.STRAIGHT)]:
			learned_after = night
		for shot in 3:
			if g.tactic == MonsterSpecies.ZIGZAG:
				g._hurt(p)                                   # weaving in, it reached the child
				break
			g.take_hit(1, g.global_position + Vector3(0, 0.6, -0.5), Vector3.ZERO)   # an arrow from far
			_steps(g, 8)                                     # it thinks again after the hit
		g.free()
		p.health.revive()
		if learned_after >= 0 and not said.is_empty():
			break
	assert_between(learned_after, 1, 5, "zigzags after %d encounters" % learned_after)
	assert_eq(said.size(), 1, "one hint, once zigzagging worked: %s" % [said])
	assert_string_contains(said[0], "zigzag")
	assert_true(MindBook.current.to_save().has("monster:goblin"), "saved with the world")


func test_after_a_childs_knock_outs_they_come_straight_and_learn_nothing() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5), ItemIds.BOW)
	MonsterMinds.current.note_knockout(p.peer_id)
	MonsterMinds.current.note_knockout(p.peer_id)
	var net := MindBook.current.net_for(MonsterSpecies.table(MonsterRules.GOBLIN))
	var before := net.w2 + net.b2
	for i in 4:
		var g := await _goblin_seeing(p)
		assert_eq(g.tactic, MonsterSpecies.STRAIGHT, "straight at a child who was knocked out")
		g.take_hit(1, g.global_position + Vector3(0, 0.6, -0.5), Vector3.ZERO)
		g._hurt(p)
		g.free()
	assert_eq(net.w2 + net.b2, before, "no lessons from it")


func test_cozy_worlds_never_learn() -> void:
	_ground()
	MonsterMinds.current.difficulty = DifficultyRules.COZY
	var p := _player(Vector3(0.5, FLOOR, 0.5), ItemIds.BOW)
	var net := MindBook.current.net_for(MonsterSpecies.table(MonsterRules.GOBLIN))
	var before := net.w2 + net.b2
	for i in 4:
		var g := await _goblin_seeing(p)
		assert_true(g.tactic in [MonsterSpecies.STRAIGHT, MonsterSpecies.BACK_OFF], "plain tactics only")
		g.take_hit(1, g.global_position + Vector3(0, 0.6, -0.5), Vector3.ZERO)
		g.free()
	assert_eq(net.w2 + net.b2, before)


func test_sandbox_monsters_learn_slowly() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5), ItemIds.BOW)
	# A hit teaches the world's goblin table at the world's rate: fully in Survivor, GENTLE_LEARNING in
	# the Sandbox. (The exact drift ratio is a unit test on one moment: two goblins here never see
	# quite the same moment — on a busy PC the player still settles between them; lead 19:10.)
	for gentle in [false, true]:
		MindBook.current = MindBook.new()
		MonsterMinds.current.gentle = gentle
		var net := MindBook.current.net_for(MonsterSpecies.table(MonsterRules.GOBLIN))
		var g := await _goblin_seeing(p)
		g.use_tactic(MonsterSpecies.STRAIGHT, p)
		g.take_hit(1, g.global_position + Vector3(0, 0.6, -0.5), Vector3.ZERO)
		var d := 0.0
		for i in net.w2.size():
			d += absf(net.w2[i] - net.base2[i])
		assert_gt(d, 0.0, "a hit teaches the table (gentle: %s)" % gentle)
		assert_almost_eq(g.mind.learning, MonsterMinds.GENTLE_LEARNING if gentle else 1.0, 0.0001, "gentle: %s" % gentle)
		g.free()


func test_a_knock_out_eases_them_off_through_the_session() -> void:
	MonsterMinds.current = MonsterMinds.new()
	var calls := [0]
	# the sandbox connects Session.knockout_received to note_knockout; here the same line by hand
	var eased := func(peer_id: int, _at_home: bool) -> void:
		MonsterMinds.current.note_knockout(peer_id)
		calls[0] += 1
	Session.knockout_received.connect(eased)
	Session.broadcast_knockout(5, true)
	Session.knockout_received.disconnect(eased)
	assert_eq(calls[0], 1)
	assert_almost_eq(MonsterMinds.current.ease_of(5), MonsterMinds.EASE_PER_KNOCKOUT, 0.001)


func test_the_hints_given_are_saved_with_the_world() -> void:
	var meta := WorldMeta.new_random()
	meta.mind_hints = ["goblin:zigzag"] as Array[String]
	var back := WorldMeta.from_json(meta.to_json())
	assert_eq(back.mind_hints, ["goblin:zigzag"] as Array[String])
	var broken := JSON.parse_string(meta.to_json()) as Dictionary
	broken.mind_hints = ["goblin:zigzag", "free gold", 7]
	assert_eq(WorldMeta.from_json(JSON.stringify(broken)).mind_hints, ["goblin:zigzag"] as Array[String])
