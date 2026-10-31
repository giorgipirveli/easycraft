extends GutTest
## M3 Task 8 (spec §14.5, §3a Build-and-Wear): a small build (at most 5 x 5 x 5, connected blocks) turned into a
## HAT, a BACKPACK or WINGS with the wand. It is kept as block ids and places (BuildCodec's text, checked on every
## load: size, count, only real blocks), saved in the profile with the avatar look and sent with it to other
## players (the look code grows to 2,048 characters: three of the biggest builds fit).


func _cube(n: int, id: int = BlockIds.BRICK) -> Dictionary:
	var out := {}
	for x in n:
		for y in n:
			for z in n:
				out[Vector3i(x, y, z)] = id
	return out


func test_three_slots() -> void:
	assert_eq(WearRules.SLOTS, [WearRules.HAT, WearRules.BACK, WearRules.WINGS] as Array[StringName])
	assert_eq(WearRules.word(WearRules.HAT), "HAT")
	assert_eq(WearRules.word(WearRules.BACK), "BACKPACK")
	assert_eq(WearRules.word(WearRules.WINGS), "WINGS")


func test_a_small_build_becomes_a_wearable_and_back() -> void:
	var build := {Vector3i(10, 5, 3): BlockIds.RED, Vector3i(11, 5, 3): BlockIds.PAINTED_BLUE, Vector3i(10, 6, 3): BlockIds.GLASS}
	var code := WearRules.from_blocks(build)
	assert_ne(code, "")
	assert_true(WearRules.valid(code))
	assert_eq(WearRules.blocks_of(code), {Vector3i(0, 0, 0): BlockIds.RED, Vector3i(1, 0, 0): BlockIds.PAINTED_BLUE,
		Vector3i(0, 1, 0): BlockIds.GLASS}, "from the build's lowest corner")


func test_at_most_5_on_a_side() -> void:
	assert_eq(WearRules.MAX_SIDE, 5)
	assert_eq(WearRules.refusal(_cube(5)), "", "a full 5 x 5 x 5 cube")
	assert_ne(WearRules.from_blocks(_cube(5)), "")
	assert_eq(WearRules.refusal(_cube(6)), WearRules.TOO_BIG)
	assert_eq(WearRules.from_blocks(_cube(6)), "")
	assert_eq(WearRules.refusal({Vector3i(0, 0, 0): BlockIds.RED, Vector3i(5, 0, 0): BlockIds.RED}), WearRules.TOO_BIG,
		"6 long")
	assert_eq(WearRules.refusal({}), WearRules.EMPTY)
	assert_eq(WearRules.message(WearRules.TOO_BIG), "Only small builds can be worn: at most 5 x 5 x 5 blocks!")


## Only blocks: never an item, bedrock, air or an id no block owns.
func test_only_blocks_can_be_worn() -> void:
	for bad in [ItemIds.WAND, BlockIds.BEDROCK, BlockIds.COUNT, 999, -3]:   # COUNT: the first id past the last block
		assert_eq(WearRules.refusal({Vector3i.ZERO: bad}), WearRules.NOT_BLOCKS, str(bad))
		assert_eq(WearRules.from_blocks({Vector3i.ZERO: bad}), "", str(bad))


## A code from a save or another player is decoded under the wear limits: too big, too many or anything that
## is not a block is refused whole.
func test_a_bad_code_is_refused() -> void:
	var big := BuildCodec.encode(_cube(6))
	var gift_sized := BuildCodec.encode({Vector3i.ZERO: BlockIds.RED, Vector3i(7, 0, 0): BlockIds.RED})
	for bad: Variant in ["", "nope", big, gift_sized, 5, null, "A" .repeat(600),
			BuildCodec.encode({Vector3i.ZERO: BlockIds.COUNT})]:
		assert_false(WearRules.valid(bad), str(bad).left(30))
		assert_eq(WearRules.blocks_of(bad), {}, str(bad).left(30))


func test_the_look_wears_builds_and_saves_them() -> void:
	var look := AvatarLook.new()
	assert_eq(look.builds, {})
	var hat := WearRules.from_blocks({Vector3i.ZERO: BlockIds.GOLD, Vector3i(0, 1, 0): BlockIds.PAINTED_PINK})
	look.wear(WearRules.HAT, hat)
	assert_eq(look.builds, {WearRules.HAT: hat})
	var back := AvatarLook.from_dict(JSON.parse_string(JSON.stringify(look.to_dict())))
	assert_eq(back.builds, {WearRules.HAT: hat}, "saved in the profile's look")
	assert_true(back.equals(look))
	var copy := AvatarLook.from_code(look.to_code())
	assert_eq(copy.builds, look.builds, "sent to other players with the look")
	assert_eq(look.duplicate().builds, look.builds)
	look.take_off(WearRules.HAT)
	assert_eq(look.builds, {})
	assert_false(look.equals(back))


## A built hat replaces the catalogue hat while worn; a backpack the cape; built wings the wings.
func test_a_built_wearable_takes_its_slot() -> void:
	var look := AvatarLook.new()
	look.hat = &"crown"
	look.cape = &"hero"
	look.wings = &"angel"
	var code := WearRules.from_blocks({Vector3i.ZERO: BlockIds.RED})
	for slot: StringName in WearRules.SLOTS:
		look.wear(slot, code)
	var r := look.resolve()
	assert_eq(r.hat, &"none")
	assert_eq(r.cape, &"none")
	assert_eq(r.wings, &"none")
	assert_eq(r.builds, {WearRules.HAT: code, WearRules.BACK: code, WearRules.WINGS: code})
	assert_eq(AvatarLook.new().resolve().builds, {})


func test_bad_builds_in_a_save_are_dropped_one_by_one() -> void:
	var good := WearRules.from_blocks({Vector3i.ZERO: BlockIds.RED})
	var d := AvatarLook.new().to_dict()
	d["hat"] = "crown"
	d["builds"] = {"hat": good, "back": BuildCodec.encode(_cube(6)), "wings": 7, "tail": good}
	var look := AvatarLook.from_dict(d)
	assert_eq(look.builds, {WearRules.HAT: good}, "the good hat stays; the rest is dropped")
	assert_eq(look.hat, &"crown")
	d["builds"] = "junk"
	assert_eq(AvatarLook.from_dict(d).builds, {})


## The look code (Player.look_code) carries the builds: three of the busiest builds (every cell a different
## block from the last) still fit, and the parts that are not builds are untouched.
func test_three_busy_builds_fit_the_look_code() -> void:
	var busy := {}
	var ids := [BlockIds.RED, BlockIds.PAINTED_PINK, BlockIds.GLASS, BlockIds.PAINTED_WHITE]
	var i := 0
	for x in 5:
		for y in 5:
			for z in 5:
				busy[Vector3i(x, y, z)] = ids[i % ids.size()]
				i += 1
	var code := WearRules.from_blocks(busy)
	assert_ne(code, "")
	assert_lte(code.length(), WearRules.MAX_TEXT)
	var look := AvatarLook.new()
	look.outfit = &"knight"
	look.emotes = AvatarCatalog.DEFAULT_WHEEL.duplicate()
	for slot: StringName in WearRules.SLOTS:
		look.wear(slot, code)
	var text := look.to_code()
	assert_lte(text.length(), AvatarLook.MAX_CODE_LENGTH)
	assert_eq(AvatarLook.MAX_CODE_LENGTH, 2048)
	var back := AvatarLook.from_code(text)
	assert_eq(back.builds.size(), 3)
	assert_eq(back.outfit, &"knight")
	assert_eq(WearRules.blocks_of(back.builds[WearRules.WINGS]).size(), 125)
