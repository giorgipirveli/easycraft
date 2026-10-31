extends GutTest
## World edits on the wire (M4 Wave 1 A): a chunk's edit list and single changes, packed small, and
## read back safely (a guest never trusts bytes blindly).


func test_a_chunk_list_and_single_changes_cross_in_one_packet() -> void:
	var records := EditCodec.pack_list(Vector3i(-3, 2, 7), PackedInt32Array([5, BlockIds.RED, 4095, BlockIds.AIR]))
	records.append_array(EditCodec.pack_cells([[Vector3i(-1000, -64, 123456), BlockIds.BLUE], [Vector3i(5, 191, -5), 0]]))
	var got := EditCodec.open(EditCodec.seal(records))
	assert_eq(got.size(), 2)
	assert_eq(got[0].kind, EditCodec.LIST)
	assert_eq(got[0].chunk, Vector3i(-3, 2, 7))
	assert_eq(got[0].edits, PackedInt32Array([5, BlockIds.RED, 4095, BlockIds.AIR]))
	assert_eq(got[1].kind, EditCodec.CELLS)
	assert_eq(got[1].cells, [[Vector3i(-1000, -64, 123456), BlockIds.BLUE], [Vector3i(5, 191, -5), 0]])


func test_an_empty_list_says_the_chunk_is_as_generated() -> void:
	var got := EditCodec.open(EditCodec.seal(EditCodec.pack_list(Vector3i.ONE, PackedInt32Array())))
	assert_eq(got.size(), 1)
	assert_eq(got[0].edits.size(), 0)


func test_big_packets_are_compressed_and_small_ones_are_not() -> void:
	var small := EditCodec.seal(EditCodec.pack_cells([[Vector3i(1, 2, 3), 4]]))
	assert_eq(small[0] & EditCodec.FLAG_DEFLATE, 0)
	var many := []
	for i in 600:
		many.append([Vector3i(100 + i % 10, 40, 200 + i / 10), BlockIds.BRICK])
	var raw := EditCodec.pack_cells(many)
	var sealed := EditCodec.seal(raw)
	assert_ne(sealed[0] & EditCodec.FLAG_DEFLATE, 0)
	assert_lt(sealed.size(), raw.size() / 3, "a stamp's cells squeeze well")
	assert_eq(EditCodec.open(sealed)[0].cells.size(), 600)


func test_garbage_is_refused_without_a_crash() -> void:
	assert_eq(EditCodec.open(PackedByteArray()), [])
	assert_eq(EditCodec.open(PackedByteArray([0, 9, 9, 9])), [], "an unknown record kind")
	var good := EditCodec.seal(EditCodec.pack_list(Vector3i.ZERO, PackedInt32Array([1, 2, 3, 4])))
	assert_eq(EditCodec.open(good.slice(0, good.size() - 2)), [], "cut short")
	var claims_many := EditCodec.pack_cells([[Vector3i.ZERO, 1]])
	claims_many.encode_u16(1, 60000)
	assert_eq(EditCodec.open(EditCodec.seal(claims_many)), [], "a count longer than the bytes")
	var bomb := PackedByteArray([EditCodec.FLAG_DEFLATE])
	bomb.resize(5)
	bomb.encode_u32(1, 1 << 30)
	bomb.append_array(PackedByteArray([1, 2, 3]).compress(FileAccess.COMPRESSION_DEFLATE))
	assert_eq(EditCodec.open(bomb), [], "claims a gigabyte")


func test_cells_and_ids_out_of_range_are_left_out() -> void:
	var bad := EditCodec.pack_list(Vector3i.ZERO, PackedInt32Array([4096, 1, 3, 2]))
	var got := EditCodec.open(EditCodec.seal(bad))
	assert_eq(got[0].edits, PackedInt32Array([3, 2]), "cell 4096 is outside a chunk")
	var high := EditCodec.pack_cells([[Vector3i(0, 500, 0), 1], [Vector3i(0, 10, 0), EditCodec.MAX_ID + 1], [Vector3i(0, 11, 0), 3]])
	assert_eq(EditCodec.open(EditCodec.seal(high))[0].cells, [[Vector3i(0, 11, 0), 3]])
