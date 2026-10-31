extends GutTest
## SleepDirector on the host (M1b Task 10), with a real world and two players (peers 2 and 3):
## sleeping in a bed, skipping the time only when every player sleeps (players who leave never
## block it), homes, and beds that break. Requests arrive the way a client's RPC delivers them.

const BED_A := Vector3i(3, 100, 3)
const BED_B := Vector3i(8, 100, 3)

## Keeps what the host tells each player: fake peers have no connection to send it over.
class TellingDirector:
	extends SleepDirector
	var told: Array = []   # [peer_id, text]

	func _tell(peer_id: int, text: String) -> void:
		told.append([peer_id, text])


var world: WorldService
var sky: SkyCycle
var director: TellingDirector
var players := {}


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 16
	viewer.position = Vector3(5, 100, 3)
	world.add_child(viewer)
	sky = SkyCycle.new()
	sky.world = world
	add_child_autofree(sky)
	sky.running = false
	sky.set_time(DayCycle.MIDNIGHT)
	director = TellingDirector.new()
	director.world = world
	director.sky = sky
	add_child_autofree(director)
	players = {}
	for id: int in [2, 3]:
		_add_player(id)
	_stand_next_to(2, BED_A)
	_stand_next_to(3, BED_B)
	await wait_until(func() -> bool: return world.is_editable(BED_A) and world.is_editable(BED_B), 10.0, "terrain loads")
	world.set_block(BED_A, BlockIds.BED)
	world.set_block(BED_B, BlockIds.BED)


func _add_player(id: int) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(id)
	p.world = world
	add_child_autofree(p)
	p.viewer.free()
	p._spawned = true
	players[id] = p
	return p


func _stand_next_to(id: int, bed: Vector3i) -> void:
	(players[id] as Player).global_position = Vector3(bed.x - 0.5, bed.y, bed.z + 0.5)


func _sleep(id: int, bed: Vector3i) -> void:
	Session.bed_sleep_requested.emit(id, bed)


func _asleep(id: int) -> bool:
	return (players[id] as Player).sleeping


func test_one_sleeper_never_skips_the_night_for_everyone() -> void:
	_sleep(2, BED_A)
	assert_true(_asleep(2))
	assert_eq(director.home_of(2), BED_A, "the bed is now player 2's home")
	director._process(SleepDirector.SKIP_DELAY + 1.0)
	assert_almost_eq(sky.time, DayCycle.MIDNIGHT, 0.0001, "still night: player 3 is awake")
	assert_true(_asleep(2), "player 2 keeps sleeping")


func test_when_everyone_sleeps_the_night_skips_to_sunrise_and_everyone_wakes() -> void:
	_sleep(2, BED_A)
	_sleep(3, BED_B)
	director._process(SleepDirector.SKIP_DELAY - 0.5)
	assert_almost_eq(sky.time, DayCycle.MIDNIGHT, 0.0001, "the fade plays first")
	director._process(1.0)
	assert_almost_eq(sky.time, DayCycle.SUNRISE, 0.0001)
	assert_false(_asleep(2))
	assert_false(_asleep(3))


func test_sleeping_by_day_skips_to_sunset() -> void:
	sky.set_time(DayCycle.NOON)
	_sleep(2, BED_A)
	_sleep(3, BED_B)
	director._process(SleepDirector.SKIP_DELAY + 0.1)
	assert_almost_eq(sky.time, DayCycle.SUNSET, 0.0001)


func test_a_player_who_leaves_never_blocks_the_skip() -> void:
	_sleep(2, BED_A)
	(players[3] as Player).queue_free()        # the sandbox frees the body as the peer leaves
	Session.peer_left.emit(3)
	director._process(SleepDirector.SKIP_DELAY + 0.1)
	assert_almost_eq(sky.time, DayCycle.SUNRISE, 0.0001)
	assert_false(_asleep(2))


func test_a_sleeper_who_leaves_does_not_count_as_asleep() -> void:
	_sleep(2, BED_A)
	(players[2] as Player).queue_free()
	Session.peer_left.emit(2)
	director._process(SleepDirector.SKIP_DELAY + 0.1)
	assert_almost_eq(sky.time, DayCycle.MIDNIGHT, 0.0001, "player 3 is still awake")
	_sleep(3, BED_B)
	director._process(SleepDirector.SKIP_DELAY + 0.1)
	assert_almost_eq(sky.time, DayCycle.SUNRISE, 0.0001)


func test_getting_up_cancels_the_skip() -> void:
	_sleep(2, BED_A)
	_sleep(3, BED_B)
	Session.bed_wake_requested.emit(3)
	assert_false(_asleep(3))
	director._process(SleepDirector.SKIP_DELAY + 0.1)
	assert_almost_eq(sky.time, DayCycle.MIDNIGHT, 0.0001)
	assert_true(_asleep(2))


func test_a_bed_too_far_away_or_taken_is_refused() -> void:
	_sleep(2, BED_B)
	assert_false(_asleep(2), "too far")
	_sleep(2, BED_A)
	_stand_next_to(3, BED_A)
	_sleep(3, BED_A)
	assert_false(_asleep(3), "somebody already sleeps there")
	world.set_block(BED_B + Vector3i.UP, BlockIds.STONE)
	_stand_next_to(3, BED_B)
	_sleep(3, BED_B)
	assert_false(_asleep(3), "no room on the bed")


func test_breaking_a_bed_wakes_its_sleeper_and_clears_the_home() -> void:
	_sleep(2, BED_A)
	world.set_block(BED_A, BlockIds.AIR)
	assert_false(_asleep(2))
	assert_eq(director.home_of(2), BedRules.NO_BED)


func test_home_is_the_last_bed_slept_in() -> void:
	_sleep(2, BED_A)
	Session.bed_wake_requested.emit(2)
	_stand_next_to(2, BED_B)
	_sleep(2, BED_B)
	assert_eq(director.home_of(2), BED_B)


## Review M6: a player who joins during the countdown is awake, so the skip stops and the sleepers
## are told. The sandbox adds the joiner's body only after this director has heard client_ready
## (it connects first), so the joiner has to count before its body exists.
func test_a_late_joiner_stops_the_skip_and_the_sleepers_are_told() -> void:
	_sleep(2, BED_A)
	_sleep(3, BED_B)
	director._process(SleepDirector.SKIP_DELAY - 1.0)   # the countdown runs
	director.told.clear()
	Session.client_ready.emit(4)
	_add_player(4)                                      # what the sandbox does next
	assert_eq(director.told.size(), 2, "both sleepers hear it")
	for line: Array in director.told:
		assert_has([2, 3], line[0])
		assert_string_contains(line[1], "2 of 3 asleep")
	director._process(1.5)
	assert_almost_eq(sky.time, DayCycle.MIDNIGHT, 0.0001, "still night: the new player is awake")
	assert_true(_asleep(2) and _asleep(3), "the sleepers keep sleeping")


## Whatever else stops the skip at the last moment, the sleepers hear why instead of nothing.
func test_a_skip_that_cannot_happen_tells_the_sleepers() -> void:
	_sleep(2, BED_A)
	_sleep(3, BED_B)
	_add_player(4)                                      # a body nobody announced
	director.told.clear()
	director._process(SleepDirector.SKIP_DELAY + 0.1)
	assert_almost_eq(sky.time, DayCycle.MIDNIGHT, 0.0001)
	assert_eq(director.told.size(), 2, "both sleepers hear it")
	for line: Array in director.told:
		assert_string_contains(line[1], "2 of 3 asleep")
