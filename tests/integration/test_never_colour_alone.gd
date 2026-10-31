extends GutTest
## M5 Task 1 (spec §5.15, §15.1a): never colour alone. Everything colour-coded also has a shape, a mark or a word:
## rarity rims come with pips (tier items, blasters, avatar and shop tiles), hearts are solid, half or hollow, the chat's
## game lines, errors and bot friends' lines carry a mark, the danger arrow is an arrow, the stealth eye opens and
## closes. (The game has no team colours: the co-op games are one team and the seeker is named in words.)


## How many white pips sit in a tier icon's top-left corner.
func _pips(img: Image) -> int:
	var n := 0
	for i in 5:
		var p := BlockIcons.pip_center(i)
		if img.get_pixelv(p).is_equal_approx(BlockIcons.PIP_COLOR):
			n += 1
	return n


func test_every_rarity_of_a_tier_item_has_its_own_number_of_pips() -> void:
	for kind: int in BlockIcons.KIND_TILES:
		var seen := {}
		for tier in ItemRarity.LEGENDARY + 1:
			var n := _pips(BlockIcons.tier_image(kind, tier))
			assert_eq(n, tier + 1, "kind %d tier %d" % [kind, tier])
			seen[n] = true
		assert_eq(seen.size(), ItemRarity.LEGENDARY + 1, "a different count for every rarity")


func test_every_rarity_of_a_blaster_has_its_own_number_of_pips() -> void:
	var blank := Image.create(BlockIcons.ITEM_TILE, BlockIcons.ITEM_TILE, false, Image.FORMAT_RGBA8)
	for rarity in ItemRarity.LEGENDARY + 1:
		assert_eq(_pips(BlasterIcons.framed(blank, rarity)), rarity + 1, "rarity %d" % rarity)


func test_an_avatar_or_shop_tile_counts_its_rarity_in_pips_even_when_worn() -> void:
	var seen := {}
	for rarity: StringName in AvatarCatalog.RARITY_COLORS:
		var t := AvatarTile.new(AvatarCatalog.HAT, &"")
		t.rarity_color = AvatarCatalog.RARITY_COLORS[rarity]
		seen[t.rarity_pips()] = rarity
		t.selected = true
		assert_gt(t.rarity_pips(), 0, "%s: pips while worn too (the rim turns gold then)" % rarity)
		t.free()
	assert_eq(seen.size(), AvatarCatalog.RARITY_COLORS.size(), "a different count for every rarity")


func test_hearts_are_solid_half_or_hollow() -> void:
	assert_eq(HeartsBar.shape_of(5, 0), HeartsBar.SOLID)
	assert_eq(HeartsBar.shape_of(5, 2), HeartsBar.HALF)
	assert_eq(HeartsBar.shape_of(5, 3), HeartsBar.HOLLOW)
	assert_gt(HeartsBar.EMPTY_RIM.get_luminance(), 0.6, "an empty heart's outline is light: a hollow heart")
	assert_lt(HeartsBar.OUTLINE.get_luminance(), 0.2, "a full heart's is dark")


func test_the_chats_kinds_of_line_each_carry_a_mark() -> void:
	var marks := {}
	for kind: StringName in ChatPanel.COLORS:
		if kind == &"chat":
			assert_eq(ChatPanel.mark(kind), "", "players' words are shown as they are")
			continue
		var m := ChatPanel.mark(kind)
		assert_ne(m, "", "%s lines have a mark, not only a colour" % kind)
		assert_false(marks.has(m), "%s's mark is its own" % kind)
		marks[m] = kind
		for ch in m:
			assert_true(ThemeDB.fallback_font.has_char(ch.unicode_at(0)), "the game's font draws '%s'" % ch)
	var panel := ChatPanel.new()
	add_child_autofree(panel)
	await wait_process_frames(1)
	panel.add_line("Too far away!", &"error")
	panel.add_line("hello friend", &"bot", "Pip")
	panel.add_line("hi", &"chat", "Nika")
	await wait_process_frames(1)
	var shown: Array[String] = []
	for l in panel._labels:
		if l.visible:
			shown.append(l.text)
	assert_eq(shown, [ChatPanel.mark(&"error") + "Too far away!", ChatPanel.mark(&"bot") + "Pip: hello friend", "Nika: hi"])


func test_the_danger_arrow_and_the_eye_are_shapes() -> void:
	assert_ne(StealthRules.EYE_OPEN, StealthRules.EYE_CLOSED, "the eye opens and closes (a shape)")
	assert_gt(DangerArrows.SIZE, 0.0, "the danger arrow is an arrow drawn at the edge, pointing")
