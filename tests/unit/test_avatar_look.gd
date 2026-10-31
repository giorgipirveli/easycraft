extends GutTest
## M3 Task 9 (spec §5.9, §14.6): the avatar look is plain data (AvatarLook). Every field is an id
## from AvatarCatalog; anything else (old saves, a tampered LAN peer) falls back to the default,
## field by field, so a bad value never breaks the rest of the look.


## Owner 43: the default is EasyCraft's own (peach skin, curly brown hair, an orange tee, teal trousers); the old
## yellow-and-blue default is AvatarLook.classic(), which saved profiles keep (test_default_avatar.gd).
func test_the_default_look_is_easycrafts_own() -> void:
	var look := AvatarLook.new()
	assert_eq(look.skin, &"peach")
	assert_eq(look.shirt, &"orange")
	assert_eq(look.pants, &"teal")
	assert_eq(look.face, &"rosy")
	assert_eq(look.hair, &"curly")
	assert_eq(look.hat, &"none")
	assert_eq(look.outfit, &"none")
	assert_eq(look.emotes.size(), AvatarCatalog.WHEEL_SLOTS, "the wheel has 8 slots")
	assert_eq(AvatarCatalog.SKIN_TONES[&"peach"], BlockyAvatar.SKIN, "the body's first colours are the default's")
	assert_eq(AvatarCatalog.CLOTH[&"orange"], BlockyAvatar.TORSO)
	assert_eq(AvatarCatalog.CLOTH[&"teal"], BlockyAvatar.LEGS)
	assert_eq(AvatarCatalog.SKIN_TONES[&"classic"], Color("f5cd30"), "the classic yellow is still there to wear")


func test_the_default_wheel_holds_only_free_emotes() -> void:
	for e: StringName in AvatarLook.new().emotes:
		assert_true(AvatarCatalog.is_free(AvatarCatalog.item_id(AvatarCatalog.EMOTE, e)), "%s is free" % e)


func test_round_trip_through_a_dictionary() -> void:
	var look := AvatarLook.new()
	look.skin = &"tan"
	look.hair = &"long"
	look.hair_color = &"red"
	look.face = &"wink"
	look.hat = &"crown"
	look.shirt = &"green"
	look.pants = &"black"
	look.cape = &"royal"
	look.wings = &"butterfly"
	look.trail = &"rainbow"
	look.outfit = &"pirate"
	look.emotes[0] = &"dance_star"
	var back := AvatarLook.from_dict(look.to_dict())
	assert_true(back.equals(look), "every field survives")
	assert_eq(back.emotes[0], &"dance_star")


func test_round_trip_through_the_network_code() -> void:
	var look := AvatarLook.new()
	look.hat = &"cowboy"
	look.trail = &"stars"
	var code := look.to_code()
	assert_typeof(code, TYPE_STRING)
	assert_lt(code.length(), AvatarLook.MAX_CODE_LENGTH, "small enough to sync")
	assert_true(AvatarLook.from_code(code).equals(look))


func test_unknown_ids_fall_back_field_by_field() -> void:
	var look := AvatarLook.from_dict({"skin": "purple_polka", "hat": "crown", "shirt": "gold_lame", "wings": 7,
		"trail": "sparkles", "outfit": "evil_king", "face": null, "hair": ["long"]})
	assert_eq(look.skin, &"peach")
	assert_eq(look.hat, &"crown", "a good field is kept")
	assert_eq(look.shirt, &"orange")
	assert_eq(look.wings, &"none")
	assert_eq(look.trail, &"sparkles")
	assert_eq(look.outfit, &"none")
	assert_eq(look.face, &"rosy")
	assert_eq(look.hair, &"curly")
	# Owner 43: with a base look (a saved profile's classic one), bad fields fall back to it instead.
	var saved := AvatarLook.from_dict({"skin": "purple_polka", "hair": ["long"]}, AvatarLook.classic())
	assert_eq(saved.skin, &"classic")
	assert_eq(saved.hair, &"none")


func test_a_hat_is_never_accepted_as_wings() -> void:
	var look := AvatarLook.from_dict({"wings": "crown", "hat": "angel", "cape": "rainbow"})
	assert_eq(look.wings, &"none", "ids are checked per slot")
	assert_eq(look.hat, &"none")
	assert_eq(look.cape, &"none")


func test_bad_emote_lists_are_repaired() -> void:
	var short := AvatarLook.from_dict({"emotes": ["wave", "dance_hop"]})
	assert_eq(short.emotes.size(), AvatarCatalog.WHEEL_SLOTS, "always 8 slots")
	assert_eq(short.emotes[0], &"wave")
	assert_eq(short.emotes[1], &"dance_hop")
	var junk := AvatarLook.from_dict({"emotes": ["moonwalk", 3, null, "sit", "sit", "sit", "sit", "sit", "sit", "sit", "sit"]})
	assert_eq(junk.emotes.size(), AvatarCatalog.WHEEL_SLOTS)
	for e: StringName in junk.emotes:
		assert_true(AvatarCatalog.has_item(AvatarCatalog.EMOTE, e), "%s is a real emote" % e)
	assert_eq(AvatarLook.from_dict({"emotes": "wave"}).emotes, AvatarLook.new().emotes, "not a list: the default wheel")


func test_broken_codes_give_the_default_look() -> void:
	for code: Variant in ["", "{", "[1,2]", "null", "{\"hat\": \"crown\"", "x".repeat(AvatarLook.MAX_CODE_LENGTH + 1)]:
		assert_true(AvatarLook.from_code(code).equals(AvatarLook.new()), "code %s" % str(code).left(20))
	assert_true(AvatarLook.from_dict(null).equals(AvatarLook.new()))
	assert_true(AvatarLook.from_dict(42).equals(AvatarLook.new()))


func test_an_oversized_code_is_refused_even_when_it_parses() -> void:
	var d := AvatarLook.new().to_dict()
	d["padding"] = "x".repeat(AvatarLook.MAX_CODE_LENGTH)
	assert_true(AvatarLook.from_code(JSON.stringify(d)).equals(AvatarLook.new()))


func test_duplicate_is_independent() -> void:
	var look := AvatarLook.new()
	var copy := look.duplicate()
	copy.hat = &"crown"
	copy.emotes[0] = &"sit"
	assert_eq(look.hat, &"none")
	assert_eq(look.emotes[0], AvatarLook.new().emotes[0])


func test_resolve_gives_colours_and_parts() -> void:
	var look := AvatarLook.new()
	look.shirt = &"red"
	look.hair = &"spiky"
	look.hair_color = &"blond"
	var r := look.resolve()
	assert_eq(r.skin, AvatarCatalog.SKIN_TONES[&"peach"])
	assert_eq(r.shirt, AvatarCatalog.CLOTH[&"red"])
	assert_eq(r.pants, AvatarCatalog.CLOTH[&"teal"])
	assert_eq(r.hair, &"spiky")
	assert_eq(r.hair_color, AvatarCatalog.HAIR_COLORS[&"blond"])
	assert_eq(r.hat, &"none")
	assert_eq(r.pattern, AvatarCatalog.PATTERN_NONE)
	assert_eq(r.extras, [])


func test_an_outfit_dresses_the_whole_body_but_keeps_the_childs_own_choices() -> void:
	var look := AvatarLook.new()
	look.skin = &"brown"
	look.shirt = &"red"
	look.hat = &"crown"
	look.cape = &"hero"
	look.trail = &"hearts"
	look.outfit = &"knight"
	var r := look.resolve()
	var knight: Dictionary = AvatarCatalog.OUTFITS[&"knight"]
	assert_eq(r.shirt, knight.shirt, "the outfit's clothes")
	assert_eq(r.pants, knight.pants)
	assert_eq(r.hat, knight.hat, "the outfit's helmet replaces the hat")
	assert_eq(r.skin, AvatarCatalog.SKIN_TONES[&"brown"], "skin stays the child's")
	assert_eq(r.cape, &"hero", "cape, wings and trail stay the child's")
	assert_eq(r.trail, &"hearts")
	assert_true(r.hides_hair, "a full helmet hides the hair")


func test_every_skin_the_spec_names_is_an_outfit() -> void:
	for skin: StringName in [&"knight", &"astronaut", &"dino", &"robot", &"pirate", &"ninja", &"candy", &"cosmic"]:
		assert_true(AvatarCatalog.OUTFITS.has(skin), "%s outfit" % skin)
		assert_true(AvatarCatalog.has_item(AvatarCatalog.OUTFIT, skin))
		var o: Dictionary = AvatarCatalog.OUTFITS[skin]
		for key: String in ["shirt", "pants", "shoes", "hat", "pattern", "extras"]:
			assert_true(o.has(key), "%s has %s" % [skin, key])
