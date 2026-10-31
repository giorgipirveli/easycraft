extends GutTest
## M3 Task 7 (spec §14.4): power is one step, kid-simple. A source (a pressed button, a lever or light
## switch that is on, a pressure plate someone stands on) powers the blocks touching its six faces; a
## powered door (its whole stack of up to 3) opens while powered, a lamp lights. Nothing powered passes power
## on: no chains, no redstone logic. A tap is a request; a player gets at most 5 toggles a second.

var cells := {}


func before_each() -> void:
	cells = {}


func _at(p: Vector3i) -> int:
	return cells.get(p, BlockIds.AIR)


func test_sources_and_what_a_tap_does() -> void:
	assert_eq(PowerRules.tapped(BlockIds.BUTTON), BlockIds.BUTTON_ON, "a button presses")
	assert_eq(PowerRules.tapped(BlockIds.BUTTON_ON), BlockIds.BUTTON_ON, "pressing again keeps it pressed (its second starts again)")
	assert_eq(PowerRules.tapped(BlockIds.LEVER), BlockIds.LEVER_ON)
	assert_eq(PowerRules.tapped(BlockIds.LEVER_ON), BlockIds.LEVER)
	assert_eq(PowerRules.tapped(BlockIds.LIGHT_SWITCH), BlockIds.LIGHT_SWITCH_ON)
	assert_eq(PowerRules.tapped(BlockIds.LIGHT_SWITCH_ON), BlockIds.LIGHT_SWITCH)
	assert_eq(PowerRules.tapped(BlockIds.STONE), BlockIds.STONE, "other blocks don't change")
	for id in [BlockIds.BUTTON, BlockIds.BUTTON_ON, BlockIds.LEVER, BlockIds.LEVER_ON, BlockIds.LIGHT_SWITCH, BlockIds.LIGHT_SWITCH_ON]:
		assert_true(PowerRules.is_switch(id), BlockIds.display_name(id))
	for id in [BlockIds.STONE, BlockIds.DOOR, BlockIds.PRESSURE_PLATE, BlockIds.LAMP, BlockIds.POWERED_DOOR, BlockIds.START]:
		assert_false(PowerRules.is_switch(id), "a tap does nothing to %s" % BlockIds.display_name(id))
	for id in [BlockIds.BUTTON_ON, BlockIds.LEVER_ON, BlockIds.LIGHT_SWITCH_ON]:
		assert_true(PowerRules.gives_power(id, false), BlockIds.display_name(id))
	for id in [BlockIds.BUTTON, BlockIds.LEVER, BlockIds.LIGHT_SWITCH, BlockIds.LAMP_ON, BlockIds.POWERED_DOOR_OPEN, BlockIds.LIGHT, BlockIds.CRYSTAL]:
		assert_false(PowerRules.gives_power(id, false), "%s gives no power" % BlockIds.display_name(id))
	assert_true(PowerRules.gives_power(BlockIds.PRESSURE_PLATE, true), "a plate someone stands on")
	assert_false(PowerRules.gives_power(BlockIds.PRESSURE_PLATE, false), "an empty plate")
	assert_eq(PowerRules.BUTTON_TIME, 1.0, "a button powers for one second")


func test_a_source_powers_all_six_faces() -> void:
	var lever := Vector3i(0, 10, 0)
	cells[lever] = BlockIds.LEVER_ON
	for d: Vector3i in PowerRules.FACES:
		assert_true(PowerRules.is_powered(lever + d, _at, {}), "face %s" % d)
	assert_eq(PowerRules.FACES.size(), 6)
	assert_false(PowerRules.is_powered(lever + Vector3i(1, 1, 0), _at, {}), "an edge neighbour is not touching")
	assert_false(PowerRules.is_powered(lever + Vector3i(2, 0, 0), _at, {}), "two away is not touching")
	cells[lever] = BlockIds.LEVER
	assert_false(PowerRules.is_powered(lever + Vector3i.UP, _at, {}), "an off lever powers nothing")


func test_power_is_one_step_with_no_chains() -> void:
	cells[Vector3i(0, 10, 0)] = BlockIds.LEVER_ON
	cells[Vector3i(1, 10, 0)] = BlockIds.LAMP_ON        # powered by the lever
	cells[Vector3i(2, 10, 0)] = BlockIds.LAMP           # touches only the lit lamp
	cells[Vector3i(0, 10, 1)] = BlockIds.POWERED_DOOR_OPEN
	cells[Vector3i(0, 10, 2)] = BlockIds.LAMP           # touches only the open door
	cells[Vector3i(-1, 10, 0)] = BlockIds.LEVER_ON      # a lever next to a lever
	assert_true(PowerRules.is_powered(Vector3i(1, 10, 0), _at, {}))
	assert_false(PowerRules.is_powered(Vector3i(2, 10, 0), _at, {}), "a lit lamp passes nothing on")
	assert_false(PowerRules.is_powered(Vector3i(0, 10, 2), _at, {}), "an open door passes nothing on")
	assert_eq(PowerRules.consumer_changes(Vector3i(2, 10, 0), _at, {}), [], "it stays dark")
	assert_eq(PowerRules.consumer_changes(Vector3i(-2, 10, 0), _at, {}), [], "air is nothing to change")


func test_a_pressed_plate_powers_while_someone_stands_on_it() -> void:
	var plate := Vector3i(5, 10, 5)
	cells[plate] = BlockIds.PRESSURE_PLATE
	cells[plate + Vector3i(1, 0, 0)] = BlockIds.LAMP
	assert_eq(PowerRules.consumer_changes(plate + Vector3i(1, 0, 0), _at, {}), [], "nobody on it: dark")
	assert_eq(PowerRules.consumer_changes(plate + Vector3i(1, 0, 0), _at, {plate: true}),
		[[plate + Vector3i(1, 0, 0), BlockIds.LAMP_ON]], "stepped on: the lamp lights")


func test_consumers_follow_their_power_both_ways() -> void:
	cells[Vector3i(0, 10, 0)] = BlockIds.BUTTON_ON
	cells[Vector3i(1, 10, 0)] = BlockIds.LAMP
	assert_eq(PowerRules.consumer_changes(Vector3i(1, 10, 0), _at, {}), [[Vector3i(1, 10, 0), BlockIds.LAMP_ON]])
	cells[Vector3i(1, 10, 0)] = BlockIds.LAMP_ON
	assert_eq(PowerRules.consumer_changes(Vector3i(1, 10, 0), _at, {}), [], "already lit")
	cells[Vector3i(0, 10, 0)] = BlockIds.BUTTON
	assert_eq(PowerRules.consumer_changes(Vector3i(1, 10, 0), _at, {}), [[Vector3i(1, 10, 0), BlockIds.LAMP]], "released: dark")
	assert_true(PowerRules.is_consumer(BlockIds.LAMP) and PowerRules.is_consumer(BlockIds.LAMP_ON))
	assert_true(PowerRules.is_consumer(BlockIds.POWERED_DOOR) and PowerRules.is_consumer(BlockIds.POWERED_DOOR_OPEN))
	assert_false(PowerRules.is_consumer(BlockIds.DOOR), "the M2 door is opened by hand, not by power")
	assert_false(PowerRules.is_consumer(BlockIds.LIGHT), "LIGHT is always on (builds made before stay the same)")


func test_a_powered_doorway_opens_and_closes_as_one() -> void:
	var bottom := Vector3i(3, 10, 0)
	cells[bottom] = BlockIds.POWERED_DOOR
	cells[bottom + Vector3i.UP] = BlockIds.POWERED_DOOR
	cells[bottom + Vector3i(1, 0, 0)] = BlockIds.LEVER_ON   # touches only the bottom door
	var open := PowerRules.consumer_changes(bottom + Vector3i.UP, _at, {})
	assert_eq(open, [[bottom, BlockIds.POWERED_DOOR_OPEN], [bottom + Vector3i.UP, BlockIds.POWERED_DOOR_OPEN]],
		"the lever touches the bottom door; the whole doorway opens")
	cells[bottom] = BlockIds.POWERED_DOOR_OPEN
	cells[bottom + Vector3i.UP] = BlockIds.POWERED_DOOR_OPEN
	cells[bottom + Vector3i(1, 0, 0)] = BlockIds.LEVER
	assert_eq(PowerRules.consumer_changes(bottom, _at, {}),
		[[bottom, BlockIds.POWERED_DOOR], [bottom + Vector3i.UP, BlockIds.POWERED_DOOR]], "and closes as one")
	assert_eq(PowerRules.door_stack(bottom, _at).size(), 2)


func test_a_door_stack_is_at_most_three_doors() -> void:
	for y in range(10, 15):
		cells[Vector3i(0, y, 0)] = BlockIds.POWERED_DOOR
	assert_lte(PowerRules.door_stack(Vector3i(0, 12, 0), _at).size(), PowerRules.MAX_DOOR_STACK)
	assert_has(PowerRules.door_stack(Vector3i(0, 12, 0), _at), Vector3i(0, 12, 0), "always holding its own door")


func test_on_states_are_the_same_item() -> void:
	assert_eq(PowerRules.item_of(BlockIds.LEVER_ON), BlockIds.LEVER)
	assert_eq(PowerRules.item_of(BlockIds.BUTTON_ON), BlockIds.BUTTON)
	assert_eq(PowerRules.item_of(BlockIds.LIGHT_SWITCH_ON), BlockIds.LIGHT_SWITCH)
	assert_eq(PowerRules.item_of(BlockIds.LAMP_ON), BlockIds.LAMP)
	assert_eq(PowerRules.item_of(BlockIds.POWERED_DOOR_OPEN), BlockIds.POWERED_DOOR)
	assert_eq(PowerRules.item_of(BlockIds.STONE), BlockIds.STONE)


func test_what_a_change_near_power_makes_worth_a_look() -> void:
	assert_true(PowerRules.matters(BlockIds.LEVER, BlockIds.LEVER_ON))
	assert_true(PowerRules.matters(BlockIds.AIR, BlockIds.LAMP))
	assert_true(PowerRules.matters(BlockIds.POWERED_DOOR, BlockIds.AIR), "a doorway split in two")
	assert_true(PowerRules.matters(BlockIds.PRESSURE_PLATE, BlockIds.AIR))
	assert_false(PowerRules.matters(BlockIds.AIR, BlockIds.STONE))
	assert_false(PowerRules.matters(BlockIds.GRASS, BlockIds.DIRT))


func test_a_player_gets_at_most_five_toggles_a_second() -> void:
	var limit := PowerRules.TapLimiter.new()
	var ok := 0
	for i in 20:
		if limit.allow(i * 50):   # a tap every 50 ms: 20 taps in one second
			ok += 1
	assert_eq(ok, PowerRules.MAX_TOGGLES_PER_SECOND)
	assert_true(limit.allow(1100), "a moment later it works again")
	var steady := PowerRules.TapLimiter.new()
	for i in 10:
		assert_true(steady.allow(i * 250), "four a second are always fine")


func test_a_limiter_for_touches_takes_its_own_count() -> void:
	var limit := PowerRules.TapLimiter.new(20)
	var ok := 0
	for i in 40:
		if limit.allow(i * 10):
			ok += 1
	assert_eq(ok, 20)
