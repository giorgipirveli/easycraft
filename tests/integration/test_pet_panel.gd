extends GutTest
## The pet's picture card (M3 Task 11): a tap on your own pet opens it — its name, a heart as big as it is
## happy, SIT / COME, a new name (from the list; a typed one only for 13+) and 8 collar colours. Small, in
## the middle, clear of the HUD's buttons; it closes when the pet goes.

const SCREEN := Vector2(1280, 720)

var _sent: Array = []


func before_each() -> void:
	_sent.clear()


func _pet(owner: int = 1, happiness := 0.7) -> Animal:
	var a := Animal.new()
	a.setup({"species": &"dog", "id": "d1", "pos": Vector3.ZERO, "owner": owner, "name": "Biscuit", "happiness": happiness})
	add_child_autofree(a)
	return a


func _panel(band: StringName = AgeBand.UNDER_13) -> PetPanel:
	var p := PetPanel.new()
	p.band = band
	p.request_sit = func(n: String) -> void: _sent.append(["sit", n])
	p.request_name = func(n: String, v: String) -> void: _sent.append(["name", n, v])
	p.request_collar = func(n: String, c: int) -> void: _sent.append(["collar", n, c])
	add_child_autofree(p)
	return p


func _button(p: PetPanel, button_name: String) -> Button:
	return p.find_child(button_name, true, false) as Button


func test_it_opens_with_the_pets_name_and_a_heart_as_big_as_it_is_happy() -> void:
	var p := _panel()
	var pet := _pet(1, 1.0)
	p.open(pet)
	assert_true(p.is_open())
	assert_eq((p.find_child("PetName", true, false) as Label).text, "Biscuit")
	var big := p.heart.fill
	pet.happiness = PetRules.HAPPY_FLOOR
	p._process(0.1)
	assert_lt(p.heart.fill, big, "a smaller heart when it is less happy")
	assert_gt(p.heart.fill, 0.0, "never an empty heart")
	assert_eq(p.heart.fill, PetRules.heart_scale(PetRules.HAPPY_FLOOR))


func test_sit_and_come() -> void:
	var p := _panel()
	var pet := _pet()
	p.open(pet)
	var sit := _button(p, "Sit")
	assert_eq(sit.text, "SIT")
	sit.pressed.emit()
	assert_eq(_sent, [["sit", "d1"]])
	pet.sitting = true
	p._process(0.1)
	assert_eq(sit.text, "COME")


func test_an_under_13_child_picks_a_name_from_the_list_only() -> void:
	var p := _panel(AgeBand.UNDER_13)
	p.open(_pet())
	_button(p, "Name").pressed.emit()
	assert_null(p.find_child("TypeName", true, false), "no typing under 13")
	var names := p.find_children("Name_*", "Button", true, false)
	assert_gte(names.size(), 8)
	for b: Button in names:
		assert_true(PetRules.FUN_NAMES.has(b.text.capitalize()) or PetRules.FUN_NAMES.has(b.text), b.text)
	var first := names[0] as Button
	first.pressed.emit()
	assert_eq(_sent.size(), 1)
	assert_eq(_sent[0][0], "name")
	assert_true(PetRules.FUN_NAMES.has(_sent[0][2]))
	assert_eq(p.page, PetPanel.MAIN, "back to the card")


func test_more_names_shows_the_rest_of_the_list() -> void:
	var p := _panel()
	p.open(_pet())
	_button(p, "Name").pressed.emit()
	var shown := {}
	for i in 5:
		for b: Button in p.find_children("Name_*", "Button", true, false):
			shown[b.text] = true
		_button(p, "MoreNames").pressed.emit()
	assert_eq(shown.size(), PetRules.FUN_NAMES.size(), "every name can be reached")


func test_a_13_plus_child_may_also_type_a_name() -> void:
	var p := _panel(AgeBand.TEEN_PLUS)
	p.open(_pet())
	_button(p, "Name").pressed.emit()
	var field := p.find_child("TypeName", true, false) as LineEdit
	assert_not_null(field)
	field.text = "Sparkles"
	_button(p, "TypeOk").pressed.emit()
	assert_eq(_sent, [["name", "d1", "Sparkles"]])


func test_a_typed_name_the_filter_refuses_is_not_sent() -> void:
	var p := _panel(AgeBand.TEEN_PLUS)
	p.open(_pet())
	_button(p, "Name").pressed.emit()
	(p.find_child("TypeName", true, false) as LineEdit).text = "stupiddog"
	_button(p, "TypeOk").pressed.emit()
	assert_eq(_sent, [])
	assert_eq(p.message.text, PetRules.name_message("blocked_word"))


func test_eight_collar_colours() -> void:
	var p := _panel()
	p.open(_pet())
	_button(p, "Collar").pressed.emit()
	var swatches := p.find_children("Collar_*", "Button", true, false)
	assert_eq(swatches.size(), 8)
	(swatches[3] as Button).pressed.emit()
	assert_eq(_sent, [["collar", "d1", 3]])


func test_it_closes_when_the_pet_goes() -> void:
	var p := _panel()
	var pet := Animal.new()
	pet.setup({"species": &"cat", "id": "c9", "pos": Vector3.ZERO, "owner": 1, "name": "Luna"})
	add_child(pet)
	p.open(pet)
	pet.free()
	p._process(0.1)
	assert_false(p.is_open())


func test_it_closes_with_its_button() -> void:
	var p := _panel()
	p.open(_pet())
	watch_signals(p)
	_button(p, "Close").pressed.emit()
	assert_false(p.is_open())
	assert_signal_emitted(p, "closed")


## Taps on the card never fall through to HUD buttons (TouchButtons read touches first, DEVELOPMENT.md §8):
## it sits in the middle, clear of every always-visible button, on a 16:9 and a 20:9 phone, on every page.
func test_the_card_is_clear_of_the_huds_buttons() -> void:
	for screen: Vector2 in [Vector2(1280, 720), Vector2(1600, 720)]:
		var p := _panel()
		p.open(_pet())
		for page: StringName in [PetPanel.MAIN, PetPanel.NAMES, PetPanel.COLLARS]:
			p.show_page(page)
			var card := p.card_rect(screen)
			assert_gte(card.position.y, 0.0)
			assert_lte(card.end.y, screen.y)
			for spot: StringName in [&"pause", &"chat", &"book", &"joystick", &"physics", &"more", &"attack", &"jump",
					&"crouch", &"hotbar", &"username", &"gold", &"compass"]:
				assert_false(card.intersects(HudLayout.rect(spot, screen)), "%s page %s over %s at %s" % [page, card, spot, screen])
		p.free()
