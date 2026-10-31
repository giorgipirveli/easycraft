extends GutTest
## A donkey's chest on its picture card (owner feedback #41, spec §14.19): a tamed donkey's card has CHEST, which
## shows its 9 slots (a picture and a number each); PUT IN puts the held stack in, a tap on a slot takes it back
## (the host decides: Session's owner #41 section). It shows the donkey's synced chest and stays clear of the HUD.

var _sent: Array = []


func before_each() -> void:
	_sent.clear()


func _pet(species: StringName) -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": "p1", "pos": Vector3.ZERO, "owner": 1, "name": "Daisy"})
	add_child_autofree(a)
	return a


func _panel() -> PetPanel:
	var p := PetPanel.new()
	p.request_chest_put = func(n: String, item: int) -> void: _sent.append(["put", n, item])
	p.request_chest_take = func(n: String, slot: int) -> void: _sent.append(["take", n, slot])
	p.held_item = func() -> int: return BlockIds.PLANKS
	add_child_autofree(p)
	return p


func test_a_donkeys_card_has_a_chest_and_a_dogs_does_not() -> void:
	var p := _panel()
	p.open(_pet(&"donkey"))
	assert_not_null(p.find_child("Chest", true, false), "CHEST on a donkey's card")
	p.close()
	p.open(_pet(&"dog"))
	assert_null(p.find_child("Chest", true, false), "no chest on a dog")


func test_the_chest_page_puts_the_held_stack_in_and_takes_a_slot_out() -> void:
	var p := _panel()
	var donkey := _pet(&"donkey")
	p.open(donkey)
	(p.find_child("Chest", true, false) as Button).pressed.emit()
	assert_eq(p.page, PetPanel.CHEST_PAGE)
	var slots := p.find_children("Slot_*", "Button", true, false)
	assert_eq(slots.size(), DonkeyChest.SLOTS, "nine slots")
	(p.find_child("PutIn", true, false) as Button).pressed.emit()
	assert_eq(_sent, [["put", "p1", BlockIds.PLANKS]], "the held stack goes in (the host decides)")
	donkey.chest = DonkeyChest.put(donkey.chest, BlockIds.PLANKS, 40).chest   # the host's answer, synced
	p._process(0.1)
	var first := p.find_child("Slot_0", true, false) as Button
	assert_eq(first.text, "40", "the slot shows how many")
	assert_not_null(first.icon, "and a picture")
	first.pressed.emit()
	assert_eq(_sent.back(), ["take", "p1", 0], "a tap takes it back")
	(p.find_child("Slot_5", true, false) as Button).pressed.emit()
	assert_eq(_sent.size(), 2, "an empty slot does nothing")


func test_the_chest_card_is_clear_of_the_huds_buttons() -> void:
	for screen: Vector2 in [Vector2(1280, 720), Vector2(1600, 720)]:
		var p := _panel()
		p.open(_pet(&"donkey"))
		for page: StringName in [PetPanel.MAIN, PetPanel.CHEST_PAGE]:
			p.show_page(page)
			var card := p.card_rect(screen)
			assert_gte(card.position.y, 0.0)
			assert_lte(card.end.y, screen.y)
			for spot: StringName in [&"pause", &"chat", &"book", &"joystick", &"physics", &"more", &"attack", &"jump",
					&"crouch", &"hotbar", &"username", &"gold", &"compass"]:
				assert_false(card.intersects(HudLayout.rect(spot, screen)), "%s page %s over %s at %s" % [page, card, spot, screen])
		p.free()
