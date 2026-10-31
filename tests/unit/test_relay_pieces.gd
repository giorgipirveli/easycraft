extends GutTest
## Big multiplayer packets cut into pieces for the Nakama relay and put back together (M4 spike):
## Nakama closes a session that sends one message over socket.max_message_size_bytes, and the
## host's voxel sync sent a 537 KB packet when a guest joined.


func _bytes(n: int, seed_value: int = 7) -> PackedByteArray:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := PackedByteArray()
	out.resize(n)
	for i in n:
		out[i] = rng.randi() % 256
	return out


func test_a_packet_is_cut_into_pieces_no_bigger_than_asked() -> void:
	var pieces := RelayPieces.split(_bytes(100), 32)
	assert_eq(pieces.size(), 4, "32 + 32 + 32 + 4")
	for p in pieces:
		assert_lte(p.size(), 32 + RelayPieces.HEADER_BYTES)


func test_the_pieces_put_back_together_give_the_packet() -> void:
	var packet := _bytes(537551)
	var join := RelayPieces.Assembler.new()
	var out := PackedByteArray()
	var pieces := RelayPieces.split(packet, RelayPieces.PIECE_BYTES)
	for i in pieces.size():
		out = join.add("host", pieces[i])
		if i < pieces.size() - 1:
			assert_true(out.is_empty(), "nothing before the last piece")
	assert_eq(out, packet)


func test_a_packet_that_fits_in_one_piece_is_one_piece() -> void:
	var packet := _bytes(10)
	var pieces := RelayPieces.split(packet, 32)
	assert_eq(pieces.size(), 1)
	assert_eq(RelayPieces.Assembler.new().add("a", pieces[0]), packet)


func test_senders_are_put_back_together_separately() -> void:
	var from_a := _bytes(70, 1)
	var from_b := _bytes(50, 2)
	var pa := RelayPieces.split(from_a, 32)
	var pb := RelayPieces.split(from_b, 32)
	var join := RelayPieces.Assembler.new()
	var done := {}
	for i in maxi(pa.size(), pb.size()):
		if i < pa.size():
			var out := join.add("a", pa[i])
			if not out.is_empty():
				done["a"] = out
		if i < pb.size():
			var out := join.add("b", pb[i])
			if not out.is_empty():
				done["b"] = out
	assert_eq(done.get("a"), from_a)
	assert_eq(done.get("b"), from_b)


func test_a_missing_piece_drops_that_packet_and_the_next_one_still_arrives() -> void:
	var join := RelayPieces.Assembler.new()
	var first := RelayPieces.split(_bytes(100, 3), 32)
	join.add("a", first[0])
	join.add("a", first[2])   # piece 1 never came: out of order, dropped
	assert_true(join.add("a", first[3]).is_empty(), "never a packet with a hole")
	var second := _bytes(40, 4)
	var out := PackedByteArray()
	for p in RelayPieces.split(second, 32):
		out = join.add("a", p)
	assert_eq(out, second)


func test_garbage_and_oversized_claims_are_refused() -> void:
	var join := RelayPieces.Assembler.new()
	assert_true(join.add("a", PackedByteArray([1, 2, 3])).is_empty(), "shorter than a header")
	var huge := PackedByteArray()
	huge.resize(RelayPieces.HEADER_BYTES + 4)
	huge.encode_u32(0, RelayPieces.MAX_PACKET_BYTES + 1)
	huge.encode_u32(4, 0)
	assert_true(join.add("a", huge).is_empty(), "no allocating what a sender claims beyond the limit")
	var empty := PackedByteArray()
	empty.resize(RelayPieces.HEADER_BYTES)
	assert_true(join.add("a", empty).is_empty(), "a packet of 0 bytes is nothing")


func test_forgetting_a_sender_drops_its_half_packet() -> void:
	var join := RelayPieces.Assembler.new()
	var pieces := RelayPieces.split(_bytes(64, 5), 32)
	join.add("a", pieces[0])
	join.forget("a")
	assert_true(join.add("a", pieces[1]).is_empty(), "the second half alone is not a packet")
