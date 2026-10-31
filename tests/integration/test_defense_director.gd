extends GutTest
## M2 Task 8 (spec §12.6): the DefenseDirector. On the host, spike traps hurt monsters that stand on
## them or in them 2 a second (take_hit(2, trap, ZERO)), never players, bot friends or animals, and the
## spikes pop up for everyone (Fx, one cached mesh). Weak monsters learn where the lanterns near them
## are from a lantern index: each 16-block chunk is copied once when it is loaded (a copy waits on the
## voxel threads while terrain streams: 19 ms on average in the benchmark, 0.02 ms once settled), kept
## up to date from the host's block changes, a few scans a tick. On every game, up to MAX_LIGHTS
## shared warm lights sit on the lanterns nearest the camera: never a light per lantern.
## Solo play: this game is the host.

const FLOOR := 10
const TRAP := Vector3i(0, FLOOR - 1, 0)       # flush with the ground
const ON_TRAP := Vector3(0.5, FLOOR, 0.5)

var _cells := {}
var _lanterns: Array[Vector3i] = []            # every lantern in the stub world
var _scans: Array[Vector3i] = []               # chunks copied so far
var _loaded := true
var _n := 0


## Stands in for a bot friend or an animal that could be hurt (it records every call).
class Bystander:
	extends Node3D
	var calls := 0

	func take_hit(_damage: int, _from: Vector3, _knockback: Vector3) -> void:
		calls += 1

	func hurt(_amount: int, _from: Vector3) -> void:
		calls += 1

	func knockback(_impulse: Vector3) -> void:
		calls += 1


func before_each() -> void:
	_cells = {TRAP: BlockIds.SPIKE_TRAP}
	_lanterns = []
	_scans = []
	_loaded = true


## Stop sounds still playing when the run quits (they show up as leaks at exit).
func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _block(p: Vector3i) -> int:
	if _cells.has(p):
		return _cells[p]
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _director() -> DefenseDirector:
	var d := DefenseDirector.new()
	d.name = "Defenses"
	d.block_at = _block
	d.chunk_ready = func(_chunk: Vector3i) -> bool: return _loaded
	d.scan_chunk = func(chunk: Vector3i) -> Array[Vector3i]:
		_scans.append(chunk)
		var out: Array[Vector3i] = []
		for l in _lanterns:
			if DefenseDirector.chunk_of(l) == chunk:
				out.append(l)
		return out
	add_child_autofree(d)
	return d


func _monster(kind: StringName, level: int, pos: Vector3) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "d%d" % _n, "pos": pos, "yaw": 0.0, "wild": true, "universe": 1})
	m.block_at = _block
	add_child_autofree(m)
	m.set_physics_process(false)          # it stands where the test puts it
	return m


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _ticks(d: DefenseDirector, n: int) -> void:
	for i in n:
		d.tick(DefenseDirector.TICK)


# --- Spike traps ------------------------------------------------------------------------------------

func test_a_trap_hurts_a_monster_standing_on_it_2_a_second() -> void:
	var d := _director()
	var m := _monster(MonsterRules.GOBLIN, 5, ON_TRAP)       # 22 HP
	_ticks(d, 30)                                             # 3 s: hits at 0, 1 and 2 s
	assert_eq(m.hp, 22 - 6)
	_ticks(d, 70)                                             # 10 s in all
	assert_eq(m.hp, 22 - 20, "2 per second")


func test_a_monster_in_a_trap_placed_on_it_is_hurt_too() -> void:
	_cells = {Vector3i(0, FLOOR, 0): BlockIds.SPIKE_TRAP}
	var d := _director()
	var m := _monster(MonsterRules.SLIME, 3, ON_TRAP)
	_ticks(d, 1)
	assert_eq(m.hp, MonsterRules.hp(MonsterRules.SLIME, 3) - DefenseRules.TRAP_DAMAGE)


func test_a_monster_next_to_a_trap_is_not_hurt() -> void:
	var d := _director()
	var m := _monster(MonsterRules.GOBLIN, 1, ON_TRAP + Vector3(1, 0, 0))
	_ticks(d, 30)
	assert_eq(m.hp, m.max_hp)


## The host remembers what is under a monster's feet until it moves to another cell; a trap placed or
## broken (the world's block_changed) counts at once.
func test_a_trap_placed_under_a_monster_standing_still_hurts_it() -> void:
	_cells = {}
	var d := _director()
	var m := _monster(MonsterRules.GOBLIN, 5, ON_TRAP)
	_ticks(d, 5)
	assert_eq(m.hp, m.max_hp)
	_cells[TRAP] = BlockIds.SPIKE_TRAP
	d.note_block(TRAP, BlockIds.GRASS, BlockIds.SPIKE_TRAP)
	_ticks(d, 1)
	assert_eq(m.hp, m.max_hp - DefenseRules.TRAP_DAMAGE)
	_cells.erase(TRAP)
	d.note_block(TRAP, BlockIds.SPIKE_TRAP, BlockIds.GRASS)
	_ticks(d, 20)
	assert_eq(m.hp, m.max_hp - DefenseRules.TRAP_DAMAGE, "a broken trap stabs no more")


func test_a_trap_defeats_a_monster_like_a_weapon() -> void:
	var d := _director()
	var m := _monster(MonsterRules.SLIME, 1, ON_TRAP)          # 4 HP: two stabs
	watch_signals(m)
	_ticks(d, 11)
	assert_signal_emitted(m, "defeated")


func test_players_bot_friends_and_animals_are_never_hurt() -> void:
	var d := _director()
	var p := _player(ON_TRAP)
	var hp := p.health.hp
	var bot := Bystander.new()
	bot.add_to_group(&"bots")
	bot.add_to_group(&"bot_friends")
	var animal := Bystander.new()
	animal.add_to_group(&"animals")
	for b in [bot, animal]:
		add_child_autofree(b)
		b.global_position = ON_TRAP
	watch_signals(Session)
	_ticks(d, 50)
	assert_eq(p.health.hp, hp, "the player")
	assert_signal_not_emitted(Session, "player_hurt")
	assert_eq(bot.calls, 0, "a bot friend")
	assert_eq(animal.calls, 0, "an animal")


func test_the_spikes_pop_up_with_one_shared_mesh() -> void:
	var d := _director()
	_monster(MonsterRules.GOBLIN, 5, ON_TRAP)
	_monster(MonsterRules.GOBLIN, 5, ON_TRAP + Vector3(4, 0, 0))
	_cells[TRAP + Vector3i(4, 0, 0)] = BlockIds.SPIKE_TRAP
	var before := _spike_fx().size()
	_ticks(d, 1)
	var fx := _spike_fx()
	assert_eq(fx.size() - before, 2, "one pop per stab")
	assert_same(fx[-1].mesh, fx[-2].mesh, "no mesh made per pop")
	assert_same(fx[-1].mesh, Fx.spike_mesh())
	assert_same((fx[-1].mesh as PrimitiveMesh).material, Fx.material(), "the shared Fx material: no new shader")
	assert_almost_eq(fx[-1].global_position.y, float(TRAP.y + 1), 0.01, "on top of the trap")


func _spike_fx() -> Array:
	return get_tree().root.find_children("*", "CPUParticles3D", true, false).filter(
		func(n: Node) -> bool: return (n as CPUParticles3D).mesh == Fx.spike_mesh() and not n.is_queued_for_deletion())


# --- Lanterns: weak monsters learn where they are ---------------------------------------------------

func test_weak_monsters_learn_the_lanterns_near_them_and_strong_ones_do_not_care() -> void:
	_cells = {}
	_lanterns = [Vector3i(5, FLOOR, 0), Vector3i(30, FLOOR, 0)]
	var d := _director()
	var weak := _monster(MonsterRules.GOBLIN, 2, Vector3(0.5, FLOOR, 0.5))
	var strong := _monster(MonsterRules.GOBLIN, 3, Vector3(0.5, FLOOR, 3.5))
	_ticks(d, DefenseDirector.LANTERN_REFRESH_TICKS)
	assert_eq(weak.lanterns, [Vector3i(5, FLOOR, 0)] as Array[Vector3i], "only the one within 8 blocks")
	assert_eq(strong.lanterns, [] as Array[Vector3i])


func test_each_chunk_is_copied_once() -> void:
	_cells = {}
	_lanterns = [Vector3i(5, FLOOR, 0)]
	var d := _director()
	for i in 6:
		_monster(MonsterRules.SLIME, 1, Vector3(i * 1.5 + 0.5, FLOOR, 0.5))
	_ticks(d, 20)
	var unique := {}
	for c in _scans:
		unique[c] = true
	assert_eq(unique.size(), _scans.size(), "no chunk copied twice")
	assert_lte(_scans.size(), 12, "the chunks around them (3 x 2 x 2), once")


## Each weak monster's list is refreshed every LANTERN_REFRESH_TICKS ticks, in turn (0.3 s: at most about a
## block of walking, well inside the 2 blocks between the list's 8 and the fear's 6).
func test_weak_monsters_are_refreshed_in_turn() -> void:
	_cells = {}
	_lanterns = [Vector3i(2, FLOOR, 0)]
	var d := _director()
	var list: Array[Monster] = []
	for i in 6:
		list.append(_monster(MonsterRules.SLIME, 1, Vector3(0.5, FLOOR, 0.5 + i * 0.2)))
	_ticks(d, 1)
	var told := list.filter(func(m: Monster) -> bool: return not m.lanterns.is_empty())
	assert_eq(told.size(), 2, "a third of them this tick")
	_ticks(d, DefenseDirector.LANTERN_REFRESH_TICKS - 1)
	for m in list:
		assert_eq(m.lanterns, _lanterns, "every one within %d ticks" % DefenseDirector.LANTERN_REFRESH_TICKS)


func test_at_most_a_few_chunks_are_copied_per_tick() -> void:
	_cells = {}
	var d := _director()
	for i in 10:
		_monster(MonsterRules.SLIME, 1, Vector3(i * 20 + 0.5, FLOOR, 0.5))
	_ticks(d, 1)
	assert_eq(_scans.size(), DefenseDirector.MAX_SCANS_PER_TICK)
	_ticks(d, 30)
	assert_gt(_scans.size(), DefenseDirector.MAX_SCANS_PER_TICK, "the rest follow")


func test_a_lantern_placed_or_broken_later_is_known_within_a_few_ticks() -> void:
	_cells = {}
	var d := _director()
	var m := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, 0.5))
	_ticks(d, 2 * DefenseDirector.LANTERN_REFRESH_TICKS)
	var scans := _scans.size()
	d.note_block(Vector3i(3, FLOOR, 0), BlockIds.AIR, BlockIds.LANTERN)
	_ticks(d, DefenseDirector.LANTERN_REFRESH_TICKS)
	assert_eq(m.lanterns, [Vector3i(3, FLOOR, 0)] as Array[Vector3i])
	d.note_block(Vector3i(3, FLOOR, 0), BlockIds.LANTERN, BlockIds.AIR)
	_ticks(d, DefenseDirector.LANTERN_REFRESH_TICKS)
	assert_eq(m.lanterns, [] as Array[Vector3i])
	assert_eq(_scans.size(), scans, "no new copies for it")


func test_a_chunk_still_loading_is_not_remembered() -> void:
	_cells = {}
	_lanterns = [Vector3i(4, FLOOR, 0)]
	_loaded = false
	var d := _director()
	var m := _monster(MonsterRules.SLIME, 2, Vector3(0.5, FLOOR, 0.5))
	_ticks(d, 3)
	assert_eq(_scans.size(), 0, "nothing copied from terrain that is not there yet")
	_loaded = true
	_ticks(d, DefenseDirector.LANTERN_REFRESH_TICKS)
	assert_eq(m.lanterns, [Vector3i(4, FLOOR, 0)] as Array[Vector3i])


func test_a_guest_looks_again_now_and_then() -> void:
	_lanterns = [Vector3i(2, FLOOR, 0)]
	var d := _director()
	d.cache_seconds = 2.0                       # a guest's world does not announce edits
	for i in 4:                                 # a few chunks a look, nearest first
		d.update_lights(Vector3(0, FLOOR + 1, 0), DayCycle.MIDNIGHT)
	var scans := _scans.size()
	d.update_lights(Vector3(0, FLOOR + 1, 0), DayCycle.MIDNIGHT)
	assert_eq(_scans.size(), scans, "still fresh")
	_lanterns = [Vector3i(2, FLOOR, 0), Vector3i(4, FLOOR, 0)]
	d.advance(2.5)
	d.update_lights(Vector3(0, FLOOR + 1, 0), DayCycle.MIDNIGHT)
	assert_gt(_scans.size(), scans, "copied again")
	assert_eq(_lit().size(), 2, "and the new lantern shines")


# --- The warm light near lanterns (this game only) -------------------------------------------------

func _light_nodes() -> Array[Node]:
	return get_tree().root.find_children("*", "OmniLight3D", true, false).filter(
		func(n: Node) -> bool: return n.get_parent() is DefenseDirector)


func _lit() -> Array[Node]:
	return _light_nodes().filter(func(l: Node) -> bool: return (l as OmniLight3D).visible)


func test_shared_lights_sit_on_the_nearest_lanterns() -> void:
	_lanterns = [Vector3i(9, FLOOR, 0), Vector3i(2, FLOOR, 0), Vector3i(-4, FLOOR, 0), Vector3i(20, FLOOR, 0)]
	var d := _director()
	d.update_lights(Vector3(0, FLOOR + 1, 0), DayCycle.MIDNIGHT)
	d.update_lights(Vector3(0, FLOOR + 1, 0), DayCycle.MIDNIGHT)
	var lights := _light_nodes()
	assert_eq(lights.size(), DefenseDirector.MAX_LIGHTS, "a few shared lights, never one per lantern")
	var spots: Array = lights.map(func(l: Node) -> Vector3: return (l as OmniLight3D).global_position)
	assert_has(spots, Vector3(2.5, FLOOR + 0.5, 0.5))
	assert_has(spots, Vector3(-3.5, FLOOR + 0.5, 0.5))
	for l: OmniLight3D in lights:
		assert_true(l.visible)
		assert_false(l.shadow_enabled, "no shadows: cheap")


func test_no_lantern_near_no_light_and_the_day_dims_it() -> void:
	var d := _director()
	d.update_lights(Vector3(0, FLOOR + 1, 0), DayCycle.MIDNIGHT)
	assert_eq(_lit().size(), 0, "nothing to light")
	d.note_block(Vector3i(2, FLOOR, 0), BlockIds.AIR, BlockIds.LANTERN)
	d.update_lights(Vector3(0, FLOOR + 1, 0), DayCycle.MIDNIGHT)
	assert_eq(_lit().size(), 1, "one lantern, one light")
	var night := (_lit()[0] as OmniLight3D).light_energy
	d.update_lights(Vector3(0, FLOOR + 1, 0), DayCycle.NOON)
	assert_lt((_lit()[0] as OmniLight3D).light_energy, night, "softer by day")


func test_the_low_graphics_preset_has_no_lantern_lights() -> void:
	_lanterns = [Vector3i(2, FLOOR, 0)]
	var d := _director()
	d.set_light_count(DefenseDirector.lights_for("low"))
	d.update_lights(Vector3(0, FLOOR + 1, 0), DayCycle.MIDNIGHT)
	assert_eq(_lit().size(), 0)
	assert_eq(DefenseDirector.lights_for("medium"), DefenseDirector.MAX_LIGHTS)
	assert_eq(DefenseDirector.lights_for("high"), DefenseDirector.MAX_LIGHTS)
