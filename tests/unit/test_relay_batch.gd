extends GutTest
## Small packets to the same players share one relay message (M4 Wave 1 A): every Nakama message
## carries a JSON envelope of about 300 bytes, far more than a position update, so the host sends a
## run of packets for the same target as one message, taken apart again on arrival.


func test_packets_go_in_and_come_out_in_order() -> void:
	var batch := PackedByteArray()
	var packets: Array[PackedByteArray] = [PackedByteArray([1, 2, 3]), PackedByteArray(), PackedByteArray([9])]
	for p in packets:
		batch = RelayBatch.add(batch, p)
	assert_eq(RelayBatch.split(batch), packets)


func test_the_biggest_small_packet_fits() -> void:
	var big := PackedByteArray()
	big.resize(RelayPieces.PIECE_BYTES)
	big.fill(7)
	var batch := PackedByteArray()
	batch = RelayBatch.add(batch, big)
	assert_eq(RelayBatch.split(batch)[0], big)


func test_a_batch_cut_short_is_refused() -> void:
	var batch := PackedByteArray()
	batch = RelayBatch.add(batch, PackedByteArray([1, 2, 3, 4]))
	assert_eq(RelayBatch.split(batch.slice(0, batch.size() - 1)), [])
	assert_eq(RelayBatch.split(PackedByteArray([5])), [])
