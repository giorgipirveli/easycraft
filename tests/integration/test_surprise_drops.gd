extends GutTest
## M3 Task 14b (spec §13.5): the DropDirector with stubs (solo play: this game is the host). A Party Piñata
## floats down after 10 minutes of play (never two at once) 8-30 blocks from a player; anything that hits
## (a weapon, a blaster, fists) counts, 3 hits burst it into supplies for every player near it (Survivor:
## blocks, a potion, ammo; never gold; Sandbox: the fun only); after 5 minutes on the ground it floats away.
## In Survivor waves from wave 3 one supply balloon drifts in over the Totem and settles beside it; one pop
## gives ammo and a potion; it leaves with the wave. The clock is saved with the world.

const FLOOR := 10
const TOTEM := Vector3(30.5, FLOOR, 0.5)

var _mode_before: StringName
var _gold_before := 0
var _wave := 0
var _feedback: Array[String] = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_gold_before = Profile.data.survivor_gold
	_wave = 0
	_feedback.clear()
	Session.magic_feedback.connect(_on_feedback)


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_feedback)
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_feedback(text: String) -> void:
	_feedback.append(text)


func _drops(survivor: bool = true) -> DropDirector:
	var d := DropDirector.new()
	d.name = "Drops"
	d.world_seed = 20260924
	d.survivor = survivor
	d.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	d.is_ready = func(_p: Vector3) -> bool: return true
	d.wave_now = func() -> int: return _wave
	d.totem_pos = func() -> Vector3: return TOTEM
	add_child_autofree(d)
	d.set_process(false)
	return d


func _player(feet: Vector3, peer: int = 0) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer if peer != 0 else multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _run(d: DropDirector, seconds: float, step: float = 0.5) -> void:
	for i in roundi(seconds / step):
		d.advance(step)


func _land(d: DropDirector) -> void:
	_run(d, (DropRules.PINATA_HEIGHT + 1.0) / DropRules.PINATA_FALL, 0.25)


# --- The Party Piñata ---

func test_a_pinata_comes_after_10_minutes_of_play_and_only_one_at_a_time() -> void:
	var d := _drops()
	_player(Vector3(0.5, FLOOR, 0.5))
	await get_tree().physics_frame
	_run(d, 590.0, 5.0)
	assert_eq(d.drops().size(), 0, "not before 10 minutes")
	_run(d, DropRules.pinata_gap(d.world_seed, 0) - 590.0 + 1.0, 0.5)
	assert_eq(d.drops().size(), 1, "then one floats down")
	assert_true(d.pinata() != null)
	_run(d, 1200.0, 5.0)
	assert_eq(d.drops().size(), 1, "never two at once (it waits on the ground)")
	assert_true(_feedback.any(func(t: String) -> bool: return t.contains("Piñata")), "the child is told")


func test_no_clock_without_players() -> void:
	var d := _drops()
	_run(d, 2000.0, 10.0)
	assert_eq(d.drops().size(), 0)
	assert_eq(d.to_save().clock, 0.0, "only play time counts")


func test_it_floats_down_8_to_30_blocks_from_a_player_and_lands() -> void:
	var d := _drops()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	await get_tree().physics_frame
	d.spawn_pinata_now()
	var pin := d.pinata()
	assert_not_null(pin)
	var flat := Vector2(pin.global_position.x - p.global_position.x, pin.global_position.z - p.global_position.z).length()
	assert_between(flat, DropRules.PINATA_MIN_DISTANCE - 1.0, DropRules.PINATA_MAX_DISTANCE + 1.0)
	assert_gt(pin.global_position.y, FLOOR + 10.0, "high up")
	assert_true(pin.chute_open(), "on its parachute")
	_land(d)
	assert_almost_eq(pin.global_position.y, float(FLOOR), 0.01, "on the ground")
	assert_false(pin.chute_open())


func test_three_hits_burst_it_into_supplies_for_everyone_near_never_gold() -> void:
	var d := _drops()
	var near := _player(Vector3(0.5, FLOOR, 0.5))
	var far := _player(Vector3(200.5, FLOOR, 0.5), 7)
	var inv := Inventory.new()
	Session.set_inventory(near.peer_id, inv)
	var far_inv := Inventory.new()
	Session.set_inventory(far.peer_id, far_inv)
	await get_tree().physics_frame
	d.spawn_pinata_now()
	_land(d)
	var pin := d.pinata()
	near.global_position = pin.global_position + Vector3(2, 0, 0)
	pin.take_hit(1, near.global_position, Vector3.ZERO)
	pin.take_hit(1, near.global_position, Vector3.ZERO)
	assert_eq(pin.hits, 1, "two hits at once count as one")
	d.advance(0.3)
	pin.take_hit(4, near.global_position, Vector3.ZERO)
	d.advance(0.3)
	assert_true(is_instance_valid(pin) and not pin.is_queued_for_deletion(), "2 hits: still there")
	pin.take_hit(2, near.global_position, Vector3.ZERO)
	assert_true(pin.is_queued_for_deletion(), "3 hits: it bursts")
	assert_gt(inv.ids().size(), 2, "supplies for the child next to it")
	assert_true(inv.ids().any(func(id: int) -> bool: return BlasterRules.is_ammo(id)), "ammo")
	assert_true(inv.ids().any(func(id: int) -> bool: return PotionRules.is_potion(id)), "a potion")
	assert_eq(far_inv.ids().size(), 0, "nothing for a child far away")
	assert_eq(Profile.data.survivor_gold, _gold_before, "never gold")
	assert_eq(d.drops().size(), 0)


func test_weapons_blasters_and_fists_find_it() -> void:
	var d := _drops()
	_player(Vector3(0.5, FLOOR, 0.5))
	await get_tree().physics_frame
	d.spawn_pinata_now()
	var pin := d.pinata()
	var things := CombatDirector.hittables(get_tree())
	assert_true(things.any(func(t: Dictionary) -> bool: return t.node == pin and t.kind == WeaponRules.MONSTER),
		"every weapon hits it like a monster (and bot friends help)")
	assert_true(pin.is_in_group(&"monsters"))
	assert_eq(pin.collision_layer, Monster.LAYER, "a tap aims at it")


func test_a_sandbox_pinata_bursts_into_fun_only() -> void:
	Game.mode = ModeRules.SANDBOX
	var d := _drops(false)
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var inv := Inventory.new()
	Session.set_inventory(p.peer_id, inv)
	await get_tree().physics_frame
	d.spawn_pinata_now()
	var pin := d.pinata()
	for i in 3:
		pin.take_hit(1, p.global_position, Vector3.ZERO)
		d.advance(0.3)
	assert_eq(inv.ids().size(), 0, "Sandbox has everything already")
	assert_true(_feedback.any(func(t: String) -> bool: return t.contains("Piñata")))


func test_after_5_minutes_on_the_ground_it_floats_away_and_the_clock_goes_on() -> void:
	var d := _drops()
	_player(Vector3(0.5, FLOOR, 0.5))
	await get_tree().physics_frame
	d.spawn_pinata_now()
	_land(d)
	_run(d, DropRules.PINATA_STAY + 2.0, 1.0)
	assert_eq(d.drops().size(), 0, "gone")
	assert_eq(d.to_save().count, 1)


func test_the_clock_is_saved_with_the_world() -> void:
	var d := _drops()
	_player(Vector3(0.5, FLOOR, 0.5))
	await get_tree().physics_frame
	_run(d, 300.0, 5.0)
	var saved := d.to_save()
	assert_almost_eq(float(saved.clock), 300.0, 1.0)
	var meta := WorldMeta.new()
	meta.drops = saved
	var back := WorldMeta.from_json(meta.to_json())
	assert_eq(back.drops, saved)
	var d2 := _drops()
	d2.restore(back.drops)
	_run(d2, DropRules.pinata_gap(d2.world_seed, 0) - 300.0 + 1.0, 1.0)
	assert_eq(d2.drops().size(), 1, "the clock went on from where it was")


# --- Supply balloons ---

func test_a_supply_balloon_comes_in_survivor_waves_from_wave_3() -> void:
	var d := _drops()
	_player(TOTEM + Vector3(0, 0, -4))
	await get_tree().physics_frame
	_wave = 2
	_run(d, 40.0)
	assert_eq(d.drops().size(), 0, "wave 2: none")
	_wave = 0
	d.advance(0.5)
	_wave = 3
	_run(d, DropRules.BALLOON_DELAY - 1.0)
	assert_eq(d.drops().size(), 0, "a moment into the wave")
	_run(d, 2.0)
	assert_eq(d.drops().size(), 1, "then it comes")
	var b := d.drops()[0]
	assert_eq(b.kind, PartyPinata.BALLOON)
	_run(d, 60.0)
	assert_eq(d.drops().size(), 1, "one balloon a wave")
	var at := b.global_position
	assert_between(Vector2(at.x - TOTEM.x, at.z - TOTEM.z).length(), 2.0, 4.0, "it settled beside the Totem")
	_wave = 0
	_run(d, 3.0)
	assert_eq(d.drops().size(), 0, "it leaves with the wave")


func test_popping_the_balloon_gives_ammo_and_a_potion_to_the_team_near() -> void:
	var d := _drops()
	var p := _player(TOTEM + Vector3(0, 0, -4))
	var inv := Inventory.new()
	Session.set_inventory(p.peer_id, inv)
	await get_tree().physics_frame
	_wave = 5
	_run(d, DropRules.BALLOON_DELAY + DropRules.BALLOON_DRIFT + DropRules.BALLOON_SETTLE + 1.0)
	var b := d.drops()[0]
	b.take_hit(1, p.global_position, Vector3.ZERO)
	assert_true(b.is_queued_for_deletion(), "one pop")
	assert_true(inv.ids().any(func(id: int) -> bool: return BlasterRules.is_ammo(id)))
	assert_true(inv.ids().any(func(id: int) -> bool: return PotionRules.is_potion(id)))
	assert_eq(Profile.data.survivor_gold, _gold_before)


func test_sandbox_waves_have_no_balloons() -> void:
	Game.mode = ModeRules.SANDBOX
	var d := _drops(false)
	_player(TOTEM + Vector3(0, 0, -4))
	await get_tree().physics_frame
	_wave = 6
	_run(d, 60.0)
	assert_eq(d.drops().filter(func(x: PartyPinata) -> bool: return x.kind == PartyPinata.BALLOON).size(), 0)


# --- Everyone sees them ---

func test_a_guest_builds_the_same_drop_from_its_spawn_data() -> void:
	var d := _drops()
	var pin := d._make_drop({"id": "Drop9", "kind": PartyPinata.PINATA, "pos": Vector3(3, 40, 3), "ground": FLOOR}) as PartyPinata
	assert_not_null(pin)
	assert_eq(pin.kind, PartyPinata.PINATA)
	assert_eq(pin.name, "Drop9")
	assert_not_null(pin.find_children("*", "MultiplayerSynchronizer", false, false)[0], "its place is synced")
	pin.free()
