extends GutTest
## Flow control on the relay (M4 Wave 1 A, spec §17.0): Godot's WebSocket drops a message that does
## not fit its buffer without a word (the spike's risk 4), so RelayBridge queues every message and
## hands the socket only what fits; a message the socket refuses stays first in line. Nothing is
## ever dropped or overtaken.

var sent: Array = []
var room := 1000
var refuse := false


func before_each() -> void:
	sent = []
	room = 1000
	refuse = false


func _room() -> int:
	return room


func _send(m: Dictionary) -> bool:
	if refuse:
		return false
	sent.append(m.bytes[0])
	room -= int(m.wire)
	return true


func _msg(q: RelayQueue, tag: int, wire: int) -> void:
	q.push(9002, PackedByteArray([tag]), null, wire)


func test_messages_that_fit_go_at_once_in_order() -> void:
	var q := RelayQueue.new()
	for i in 3:
		_msg(q, i, 100)
	assert_eq(q.flush(_room, _send), 3)
	assert_eq(sent, [0, 1, 2])
	assert_eq(q.size(), 0)


func test_what_does_not_fit_waits_and_nothing_overtakes_it() -> void:
	var q := RelayQueue.new()
	_msg(q, 0, 600)
	_msg(q, 1, 600)   # does not fit behind the first
	_msg(q, 2, 10)    # would fit, but must not overtake 1
	assert_eq(q.flush(_room, _send), 1)
	assert_eq(sent, [0])
	assert_eq(q.size(), 2)
	assert_eq(q.held_bytes(), 610)
	room = 1000   # the socket sent its buffer
	q.flush(_room, _send)
	assert_eq(sent, [0, 1, 2])
	assert_eq(q.held_bytes(), 0)


func test_a_refused_message_stays_first_in_line() -> void:
	var q := RelayQueue.new()
	_msg(q, 0, 10)
	_msg(q, 1, 10)
	refuse = true
	assert_eq(q.flush(_room, _send), 0)
	assert_eq(q.refused, 1)
	refuse = false
	q.flush(_room, _send)
	assert_eq(sent, [0, 1], "nothing lost, nothing reordered")


func test_a_message_bigger_than_the_whole_buffer_still_goes_when_the_buffer_is_empty() -> void:
	var q := RelayQueue.new()
	_msg(q, 0, 5000)
	room = 1000
	assert_eq(q.flush(_room, _send, 1000), 1, "an empty buffer takes it (the socket splits frames)")


func test_clearing_forgets_everything() -> void:
	var q := RelayQueue.new()
	_msg(q, 0, 5000)
	_msg(q, 1, 5000)
	room = 0
	q.flush(_room, _send)
	q.clear()
	assert_eq(q.size(), 0)
	assert_eq(q.held_bytes(), 0)


func test_the_wire_size_counts_base64_and_the_envelope() -> void:
	assert_eq(RelayQueue.wire_size(0, 300), 300)
	assert_eq(RelayQueue.wire_size(3, 300), 304)
	assert_eq(RelayQueue.wire_size(4, 300), 308)
	assert_eq(RelayQueue.wire_size(32 * 1024 + 8, 300), 4 * ((32 * 1024 + 8 + 2) / 3) + 300)
