extends GutTest
## A build as it travels to the server and to friends (M4 Wave 3, agent I): BuildCodec writes the
## server's format (server/modules/src/rules/build_rules.ts: a version byte, the box's size, then runs
## of (count, block id) as unsigned LEB128, cells x fastest, then z, then y, in base64) and reads it
## back only when it is whole and inside the limits. The same test vectors as the server's Node test
## (server/modules/test/gift_rules.test.ts); the server's numbers are read from its source here, so
## the two never drift apart.

const RULES_TS := "res://server/modules/src/rules/build_rules.ts"
const GIFT_TS := "res://server/modules/src/rules/gift_rules.ts"


func _cube(n: int, id: int) -> Dictionary:
	var b := {}
	for x in n:
		for y in n:
			for z in n:
				b[Vector3i(x, y, z)] = id
	return b


func test_the_servers_bytes_for_a_tiny_build() -> void:
	# 2 x 1 x 1: planks, then air -> [1, 2, 1, 1, run 1 x 6, run 1 x 0]
	var text := BuildCodec.encode({Vector3i(0, 0, 0): BlockIds.PLANKS}, Vector3i(2, 1, 1))
	assert_eq(Marshalls.base64_to_raw(text), PackedByteArray([1, 2, 1, 1, 1, 6, 1, 0]))
	# 200 cells of id 200: a two-byte count and a two-byte id
	var big := {}
	for x in 10:
		for y in 2:
			for z in 10:
				big[Vector3i(x, y, z)] = 200
	assert_eq(Marshalls.base64_to_raw(BuildCodec.encode(big)), PackedByteArray([1, 10, 2, 10, 0xc8, 0x01, 0xc8, 0x01]))


func test_a_build_goes_there_and_back_from_its_lowest_corner() -> void:
	var house := {Vector3i(10, 30, -5): BlockIds.PLANKS, Vector3i(11, 30, -5): BlockIds.GLASS, Vector3i(10, 32, -4): BlockIds.LIGHT}
	var text := BuildCodec.encode(house)
	var back := BuildCodec.decode(text, BuildCodec.GIFT)
	assert_eq(back.size(), 3)
	assert_eq(back[Vector3i(0, 0, 0)], BlockIds.PLANKS)
	assert_eq(back[Vector3i(1, 0, 0)], BlockIds.GLASS)
	assert_eq(back[Vector3i(0, 2, 1)], BlockIds.LIGHT)
	assert_eq(BuildCodec.size_of(text), Vector3i(2, 3, 2))
	assert_eq(BuildCodec.count_of(text), 3)


func test_items_and_bedrock_never_travel() -> void:
	var text := BuildCodec.encode({Vector3i.ZERO: BlockIds.STONE, Vector3i(1, 0, 0): ItemIds.SWORD,
		Vector3i(2, 0, 0): BlockIds.BEDROCK})
	assert_eq(BuildCodec.decode(text, BuildCodec.GIFT), {Vector3i.ZERO: BlockIds.STONE}, "a sword or bedrock becomes air")
	for id in [0, 1, 6, 17, 19, 99, 176, 208, 255, 256, 271, 399, 512, 527, 1023]:   # owner #45b: 256-399; cosmos: 512+
		assert_true(BuildCodec.is_block_id(id), str(id))
	for id in [18, 100, 101, 150, 175, 400, 451, 511, 1024, -1]:   # cosmos: 400-511 stay the items'
		assert_false(BuildCodec.is_block_id(id), str(id))


func test_every_block_of_the_game_can_travel() -> void:
	for id in range(1, BlockIds.COUNT):
		if BlockIds.is_valid(id):
			assert_true(BuildCodec.is_block_id(id), "%s (%d)" % [BlockIds.display_name(id), id])


func test_anything_broken_or_too_big_decodes_to_nothing() -> void:
	var bad: Array = [
		"", "not base64!", "abc",
		Marshalls.raw_to_base64(PackedByteArray([2, 1, 1, 1, 1, 6])),       # an unknown version
		Marshalls.raw_to_base64(PackedByteArray([1, 0, 1, 1])),             # a side of 0
		Marshalls.raw_to_base64(PackedByteArray([1, 2, 1, 1, 1, 6])),       # one cell missing
		Marshalls.raw_to_base64(PackedByteArray([1, 1, 1, 1, 2, 6])),       # one cell too many
		Marshalls.raw_to_base64(PackedByteArray([1, 1, 1, 1, 1, 6, 9])),    # bytes after the last run
		Marshalls.raw_to_base64(PackedByteArray([1, 1, 1, 1, 1, 18])),      # bedrock
		Marshalls.raw_to_base64(PackedByteArray([1, 1, 1, 1, 1, 0x86])),    # a varint cut short
		Marshalls.raw_to_base64(PackedByteArray([1, 1, 1, 1, 1, 0])),       # nothing but air
		BuildCodec.encode(_cube(9, BlockIds.PLANKS)),                        # a gift's side is at most 8
	]
	for text: String in bad:
		assert_eq(BuildCodec.decode(text, BuildCodec.GIFT), {}, text)
	assert_eq(BuildCodec.decode(BuildCodec.encode(_cube(8, BlockIds.BRICK)), BuildCodec.GIFT).size(), 512, "8^3 is the cap")
	assert_eq(BuildCodec.size_of("junk"), Vector3i.ZERO)


func test_the_limits_are_the_servers() -> void:
	var rules := FileAccess.get_file_as_string(RULES_TS)
	var gifts := FileAccess.get_file_as_string(GIFT_TS)
	assert_ne(rules, "", "the server's rules are in the project")
	for pair: Array in [["VERSION", BuildCodec.VERSION], ["BEDROCK", BlockIds.BEDROCK], ["ITEM_FIRST", BuildCodec.ITEM_FIRST],
			["ITEM_LAST", BuildCodec.ITEM_LAST], ["BLOCK_MAX", BuildCodec.BLOCK_MAX],
			["RESERVED_FIRST", BuildCodec.RESERVED_FIRST], ["RESERVED_END", BuildCodec.RESERVED_END]]:
		var m := RegEx.create_from_string("export const %s = (\\d+);" % pair[0]).search(rules)
		assert_not_null(m, pair[0])
		if m:
			assert_eq(int(m.get_string(1)), pair[1], pair[0])
	for pair: Array in [["GIFT", BuildCodec.GIFT], ["BOTTLE", BuildCodec.BOTTLE], ["BUDDY", BuildCodec.BUDDY]]:
		var m := RegEx.create_from_string("export const %s: BuildRules.Limits = \\{ maxDim: (\\d+), maxCount: (\\d+), maxText: (\\d+) \\};" % pair[0]).search(gifts)
		assert_not_null(m, pair[0])
		if m:
			assert_eq([int(m.get_string(1)), int(m.get_string(2)), int(m.get_string(3))],
				[pair[1].max_dim, pair[1].max_count, pair[1].max_text], pair[0])
	assert_eq([BuildCodec.SHOWCASE.max_dim, BuildCodec.SHOWCASE.max_count, BuildCodec.SHOWCASE.max_text], [32, 32768, 49152])
	assert_true(gifts.contains("export const SHOWCASE: BuildRules.Limits = { maxDim: 32, maxCount: 32 * 32 * 32, maxText: 48 * 1024 };"))


func test_the_worst_gift_still_fits_the_servers_text_cap() -> void:
	var checker := {}
	for x in 8:
		for y in 8:
			for z in 8:
				checker[Vector3i(x, y, z)] = 200 if (x + y + z) % 2 == 0 else 201
	assert_lte(BuildCodec.encode(checker).length(), BuildCodec.GIFT.max_text)
