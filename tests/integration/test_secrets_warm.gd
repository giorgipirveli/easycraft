extends GutTest
## The frame spikes (2026-09-30, docs/devlog/parts/frame-spikes.md): the secret director's first tick next to a child
## worked out every secret and mouse village in reach on the main thread (world 41's spawn: 18-24 ms on this PC, one
## frame; a phone 3-5x that, right as the child stands). While a child's spawn waits for its terrain (the loading card),
## a worker works them out (SecretRules' caches are the generator threads' too: locked), so the first tick finds them
## known.

const SEED := 12345


## SecretRules counting where its areas are worked out (a lock: the worker counts too).
class CountingRules:
	extends SecretRules
	var lock := Mutex.new()
	var on_main := 0
	var on_workers := 0

	func _place(area: Vector2i) -> Array:
		lock.lock()
		if OS.get_thread_caller_id() == OS.get_main_thread_id():
			on_main += 1
		else:
			on_workers += 1
		lock.unlock()
		return super(area)


func _director(rules: SecretRules) -> SecretDirector:
	var d := SecretDirector.new()
	d.name = "Secrets"
	d.auto_tick = false
	d.block_at = func(_p: Vector3i) -> int: return BlockIds.AIR
	d.set_block = func(_p: Vector3i, _id: int) -> void: pass
	d.is_ready = func(_p: Vector3) -> bool: return false   # nothing spawns: only the rules are asked
	d.ground_at = rules.shape.height_at
	d.standing_y = rules.shape.height_at
	d.time_of_day = func() -> float: return DayCycle.NOON
	d.save_profile = func() -> void: pass
	add_child_autofree(d)
	d.setup(SEED, SecretState.new())
	d.rules = rules
	return d


## A player whose spawn waits at `at` (parked there, not spawned yet).
func _waiting_player(at: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = false
	p.global_position = at
	return p


func test_a_waiting_spawn_s_secrets_are_worked_out_on_a_worker_before_the_child_stands() -> void:
	var rules := CountingRules.new(SEED)
	var d := _director(rules)
	var c := rules.shape.spawn_column()
	var p := _waiting_player(Vector3(c.x + 0.5, rules.shape.height_at(c.x, c.y), c.y + 0.5))
	d.warm_pending()
	assert_true(d.warming(), "a worker works out what is in reach of the waiting spawn")
	for i in 300:
		if not d.warming():
			break
		await wait_process_frames(1)
		d.warm_pending()
	assert_false(d.warming(), "done")
	assert_gt(rules.on_workers, 0, "worked out on a worker")
	assert_eq(rules.on_main, 0, "nothing on the main thread")
	p._spawned = true
	d.host_tick(SecretDirector.TICK)
	assert_eq(rules.on_main, 0, "the first tick next to the child finds them known")


func test_a_spawn_is_warmed_once_and_a_director_leaving_waits_for_its_worker() -> void:
	var rules := CountingRules.new(SEED)
	var d := _director(rules)
	var c := rules.shape.spawn_column()
	_waiting_player(Vector3(c.x + 0.5, 40.0, c.y + 0.5))
	d.warm_pending()
	for i in 300:
		if not d.warming():
			break
		await wait_process_frames(1)
		d.warm_pending()
	var worked := rules.on_workers
	d.warm_pending()
	assert_false(d.warming(), "the same waiting spawn is not worked out again")
	assert_eq(rules.on_workers, worked)
	_waiting_player(Vector3(c.x + 900.5, 40.0, c.y + 0.5))   # another child's spawn, far away
	d.warm_pending()
	assert_true(d.warming())
	remove_child(d)   # leaves the tree (the world goes) while its worker runs: it waits for it
	assert_false(d.warming(), "waited for")
