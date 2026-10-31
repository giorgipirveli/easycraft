extends GutTest
## Owner feedback #48 (spec §14.6a): "when choosing avatar there should be avatar of girls as well" and
## "beautifull girl". A BOY / GIRL / JUST ME first choice puts on a matching starting look; every part
## stays free to mix; girl hair, hats, faces and clothes are all FREE and never sold; two beautiful girl
## presets and two boy presets; old profiles load as neutral; the choice itself stays on this phone.

const C := preload("res://core/avatar/avatar_catalog.gd")
const GIRL_HAIR: Array[StringName] = [&"long", &"bangs", &"ponytail", &"pigtails", &"braid", &"bun", &"buns", &"bob"]
const GIRL_HATS: Array[StringName] = [&"clips", &"flower_crown", &"bow"]
const GIRL_FACES: Array[StringName] = [&"sweet", &"lovely", &"rosy"]
const CUTS: Array[StringName] = [&"dress", &"gown", &"skirt", &"leggings", &"hoodie", &"overalls", &"jacket"]


func _parts(look: AvatarLook) -> Dictionary:
	var d := look.to_dict()
	d.erase("base")
	return d


func test_the_brief_s_girl_parts_are_all_in_the_catalog() -> void:
	for hair in GIRL_HAIR:
		assert_true(C.has_item(C.HAIR, hair), "hair %s" % hair)
	for hat in GIRL_HATS:
		assert_true(C.has_item(C.HAT, hat), "hat %s" % hat)
	for face in GIRL_FACES:
		assert_true(C.has_item(C.FACE, face), "face %s" % face)
	for cut in CUTS:
		assert_true(C.has_item(C.CLOTHES, cut), "clothes %s" % cut)
	for colour: StringName in [&"pink", &"purple", &"blond", &"platinum"]:
		assert_true(C.HAIR_COLORS.has(colour), "hair colour %s" % colour)
	for colour: StringName in [&"pink", &"lilac", &"mint", &"sky", &"yellow", &"rose"]:
		assert_true(C.CLOTH.has(colour), "clothes colour %s" % colour)


func test_every_girl_part_is_free_and_never_for_gold_or_in_a_pack() -> void:
	assert_gte(C.GIRL_PARTS.size(), GIRL_HAIR.size() + GIRL_HATS.size() + GIRL_FACES.size() + CUTS.size() - 3,
		"the new parts are listed (long, bun and curly were there before)")
	var fresh := ProfileData.new()
	for id: String in C.GIRL_PARTS:
		assert_true(C.is_item(id), id)
		assert_true(C.is_free(id), "%s is free" % id)
		assert_eq(C.price(id), 0, "%s has no gold price" % id)
		assert_eq(ShopCatalog.pack_of(id), "", "%s is in no pack" % id)
		assert_eq(C.rarity(id), C.COMMON, "%s is a basic part, not a prize" % id)
		assert_eq(AvatarUnlocks.check_buy(id, fresh.cosmetics, 99_999), AvatarUnlocks.OWNED, "%s: everyone has it" % id)
		assert_eq(AvatarUnlocks.lock_reason(id), "", "%s: nothing to unlock" % id)
	for product in ShopCatalog.ids():
		for id in ShopCatalog.items_of(product):
			assert_false(id in C.GIRL_PARTS, "%s sells %s" % [product, id])


func test_the_clothes_tab_is_a_slot_of_free_cuts() -> void:
	assert_has(C.SLOTS, C.CLOTHES)
	assert_eq(C.SLOTS.size(), 12, "12 tabs: two full rows of six")
	var cuts := C.items_in(C.CLOTHES)
	assert_eq(cuts[0], &"none", "the classic tee and pants first")
	for cut: StringName in cuts:
		var id := C.item_id(C.CLOTHES, cut)
		if C.ITEMS.get(id, {}).get("kind", C.FREE) == C.IN_COSTUME:
			assert_false(id in C.GIRL_PARTS, "%s: owner #36's costume cuts come with their costume" % cut)
		else:
			assert_true(C.is_free(id), "%s is free" % cut)
		if cut != &"none":
			assert_true(C.CUTS.has(cut), "%s says what it wears" % cut)
	assert_eq(C.display_name("clothes.none"), "Classic")


func test_clothes_are_worn_in_the_child_s_own_colours() -> void:
	var look := AvatarLook.new()
	look.shirt = &"lilac"
	look.pants = &"mint"
	look.clothes = &"dress"
	var r := look.resolve()
	assert_eq(r.clothes, &"dress")
	assert_eq(r.top, C.CLOTH[&"lilac"], "a dress in the shirt colour")
	assert_eq(r.shirt, C.CLOTH[&"lilac"])
	assert_eq(r.pants, C.CLOTH[&"mint"], "tights in the pants colour")
	assert_has(r.extras, &"dress_skirt")
	look.clothes = &"skirt"
	r = look.resolve()
	assert_eq(r.bottom, C.CLOTH[&"mint"], "a skirt in the pants colour")
	assert_eq(r.pants, C.TIGHTS, "over light tights")
	assert_has(r.extras, &"skirt")
	look.clothes = &"hoodie"
	r = look.resolve()
	assert_eq(r.sleeves, C.CLOTH[&"lilac"], "long sleeves")
	look.clothes = &"jacket"
	r = look.resolve()
	assert_true(r.boots, "the adventure jacket comes with boots")
	assert_gt((r.shoes as Color).a, 0.0)
	assert_eq(r.top, C.CLOTH[&"lilac"], "the shirt shows under the open jacket")
	assert_ne(r.shirt, r.top, "the jacket has its own colour")


func test_an_outfit_still_wins_over_clothes() -> void:
	var look := AvatarLook.new()
	look.clothes = &"gown"
	look.outfit = &"knight"
	var r := look.resolve()
	assert_eq(r.clothes, &"none")
	assert_false(r.extras.has(&"gown_skirt"))
	assert_eq(r.shirt, C.OUTFITS[&"knight"].shirt)


func test_girl_faces_have_eyelashes_and_rosy_cheeks_and_nothing_more() -> void:
	var look := AvatarLook.new()
	look.face = &"sweet"
	var r := look.resolve()
	assert_true(r.lashes)
	assert_true(r.blush)
	look.face = &"rosy"
	r = look.resolve()
	assert_false(r.lashes)
	assert_true(r.blush)
	look.face = &"smile"
	r = look.resolve()
	assert_false(r.lashes)
	assert_false(r.blush)
	for face: StringName in C.FACE_STYLES:
		for key: String in C.FACE_STYLES[face]:
			assert_true(key in ["lashes", "blush"], "%s: only cartoon lashes and rosy cheeks (%s)" % [face, key])


func test_the_first_choice_puts_on_a_starting_look() -> void:
	assert_eq(C.BASES, [C.BOY, C.GIRL, C.NEUTRAL] as Array[StringName])
	for b: StringName in C.BASES:
		var look := AvatarLook.start(b)
		assert_eq(look.base, b)
		assert_true(AvatarUnlocks.wearable(look, []).equals(look), "%s: a new profile can wear it" % b)
	var girl := AvatarLook.start(C.GIRL)
	assert_has(GIRL_HAIR, girl.hair, "girls start with girl hair")
	assert_true(bool(girl.resolve().lashes), "and a face with eyelashes")
	var boy := AvatarLook.start(C.BOY)
	assert_ne(boy.hair, &"none")
	assert_false(boy.hair in GIRL_HAIR)
	var neutral := AvatarLook.start(C.NEUTRAL)
	assert_eq(_parts(neutral), _parts(AvatarLook.new()), "JUST ME is today's look")


func test_the_choice_keeps_the_skin_tone_and_the_dance_wheel() -> void:
	var mine := AvatarLook.new()
	mine.skin = &"deep"
	mine.emotes[0] = &"bow"
	var girl := AvatarLook.start(C.GIRL, mine)
	assert_eq(girl.skin, &"deep")
	assert_eq(girl.emotes[0], &"bow")
	assert_eq(mine.base, C.NEUTRAL, "the old look is not changed")


func test_every_part_stays_free_to_mix_after_the_choice() -> void:
	var girl := AvatarLook.start(C.GIRL)
	girl.cape = &"hero"
	girl.hair = &"spiky"
	girl.hat = &"cap"
	girl.clothes = &"overalls"
	var kept := AvatarUnlocks.wearable(AvatarLook.from_dict(girl.to_dict()), [])
	assert_eq(kept.base, C.GIRL, "still a girl's look")
	assert_eq(kept.hair, &"spiky")
	assert_eq(kept.cape, &"hero")
	assert_eq(kept.clothes, &"overalls")
	var boy := AvatarLook.start(C.BOY)
	boy.hair = &"pigtails"
	boy.clothes = &"dress"
	boy.face = &"lovely"
	kept = AvatarUnlocks.wearable(AvatarLook.from_dict(boy.to_dict()), [])
	assert_eq(kept.hair, &"pigtails", "a boy can wear long hair")
	assert_eq(kept.clothes, &"dress")
	assert_eq(kept.face, &"lovely")


func test_the_presets_are_ready_to_wear_one_tap_looks() -> void:
	var girls := 0
	var boys := 0
	for id: StringName in C.PRESETS:
		var p: Dictionary = C.PRESETS[id]
		assert_ne(str(p.get("name", "")), "", "%s has a name" % id)
		assert_true(p.base in [C.BOY, C.GIRL], id)
		girls += 1 if p.base == C.GIRL else 0
		boys += 1 if p.base == C.BOY else 0
		for field: String in p.look:
			assert_true(C.has_item(AvatarLook.FIELDS[field], p.look[field]), "%s: %s = %s" % [id, field, p.look[field]])
		var look := AvatarLook.preset(id)
		assert_eq(look.base, p.base)
		assert_true(AvatarUnlocks.wearable(look, []).equals(look), "%s: everything in it is free" % id)
	assert_eq(girls, 2, "two beautiful girl presets")
	assert_eq(boys, 2, "and two boy presets")
	var adventurer := AvatarLook.preset(&"adventurer")
	assert_eq(adventurer.hair, &"ponytail")
	assert_eq(adventurer.clothes, &"jacket", "a jacket and boots")
	var princess := AvatarLook.preset(&"princess")
	assert_eq(princess.hat, &"flower_crown")
	assert_eq(princess.clothes, &"gown")
	assert_eq(C.PRESETS[&"princess"].name, "Princess of the Realms")
	assert_eq(C.presets_for(C.GIRL).slice(0, 2), [&"adventurer", &"princess"] as Array[StringName], "girls' first")
	assert_eq(C.presets_for(C.BOY).size(), C.PRESETS.size(), "every preset stays one tap away")


func test_a_preset_keeps_the_skin_tone_and_the_dance_wheel() -> void:
	var mine := AvatarLook.new()
	mine.skin = &"brown"
	mine.emotes[3] = &"dance_star"
	var look := AvatarLook.preset(&"princess", mine)
	assert_eq(look.skin, &"brown")
	assert_eq(look.emotes[3], &"dance_star")
	assert_eq(AvatarLook.preset(&"no_such_preset", mine).to_dict(), mine.to_dict(), "an unknown preset changes nothing")


func test_old_profiles_load_as_neutral() -> void:
	assert_eq(AvatarLook.new().base, C.NEUTRAL)
	assert_eq(AvatarLook.new().clothes, &"none")
	var old := AvatarLook.from_dict({"hair": "long", "shirt": "red"})
	assert_eq(old.base, C.NEUTRAL, "a look saved before #48")
	assert_eq(old.clothes, &"none")
	assert_eq(old.hair, &"long")
	for bad: Variant in ["queen", 7, null, ["girl"]]:
		assert_eq(AvatarLook.from_dict({"base": bad}).base, C.NEUTRAL, str(bad))
	var json := JSON.stringify({"version": 1, "username": "Ana", "avatar": {"hair": "bun", "face": "wink"}})
	var p := ProfileData.from_json(json)
	assert_eq(p.avatar.base, C.NEUTRAL)
	assert_eq(p.avatar.hair, &"bun")


func test_the_choice_stays_on_this_phone() -> void:
	var look := AvatarLook.preset(&"princess")
	assert_false(look.to_code().contains("base"), "other players get the parts, not the choice")
	var p := ProfileData.new()
	p.avatar = look
	var saved := ProfileData.from_json(p.to_json())
	assert_eq(saved.avatar.base, C.GIRL, "this phone's profile keeps it")
	assert_false(ProfileBackup.to_backup(p).contains("\"base\""), "the online backup doesn't carry it")
	var json := JSON.new()
	json.parse(ProfileBackup.to_backup(p))
	assert_eq((json.data as Dictionary).avatar.hat, "flower_crown", "the backup keeps the look itself")


func test_the_look_code_carries_every_girl_part() -> void:
	for id: StringName in C.PRESETS:
		var look := AvatarLook.preset(id)
		var code := look.to_code()
		assert_lt(code.length(), AvatarLook.MAX_CODE_LENGTH)
		assert_eq(_parts(AvatarLook.from_code(code)), _parts(look), "%s arrives whole" % id)
	var tampered := AvatarLook.from_code(JSON.stringify({"clothes": "bikini", "hair": "pigtails"}))
	assert_eq(tampered.clothes, &"none", "only real cuts")
	assert_eq(tampered.hair, &"pigtails")


func test_bot_friends_mix_girl_and_boy_looks() -> void:
	var girls := 0
	for i in BotRules.LOOKS.size():
		var look := BotRules.avatar_look(i)
		assert_true(AvatarUnlocks.wearable(look, []).equals(look), "bot look %d is free parts" % i)
		var girl := BotRules.is_girl(i)
		girls += 1 if girl else 0
		assert_eq(int(BotRules.LOOKS[i].base), 1 if girl else 0, "look %d: the realistic body matches" % i)
	assert_eq(girls, BotRules.LOOKS.size() / 2, "half the friends are girls")
	var taken: Array[int] = []
	var first := BotRules.pick_look(taken)
	assert_true(BotRules.is_girl(first), "the first friend is a girl")
	taken.append(first)
	assert_false(BotRules.is_girl(BotRules.pick_look(taken)), "then a boy")
