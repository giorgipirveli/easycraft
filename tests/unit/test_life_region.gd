extends GutTest
## Owner #112 (docs/design/life-skills.md §6): the region a grown-up sets on the Life page for grown-ups: the emergency
## number the Experiences dial and say, and which side cars drive on. A short list (a ruling); the default comes from the
## device's locale; an unknown country falls back to Europe's 112.


func test_the_short_list_has_the_numbers_of_the_authorities() -> void:
	assert_eq(LifeRegion.number("ge"), "112", "Georgia: 112 since 2012 (112.gov.ge)")
	assert_eq(LifeRegion.number("eu"), "112", "the European emergency number")
	assert_eq(LifeRegion.number("uk"), "999")
	assert_eq(LifeRegion.number("us"), "911")
	assert_eq(LifeRegion.number("ca"), "911")
	assert_eq(LifeRegion.number("au"), "000")
	assert_eq(LifeRegion.number("nz"), "111")
	assert_eq(LifeRegion.number("in"), "112")
	assert_eq(LifeRegion.number("jp"), "119", "fire and ambulance")


func test_every_region_has_a_name_a_number_and_a_side_of_the_road() -> void:
	assert_gt(LifeRegion.ids().size(), 8)
	for id in LifeRegion.ids():
		var r := LifeRegion.of(id)
		assert_ne(str(r.get("name", "")), "", id)
		assert_true(str(r.number).is_valid_int() and str(r.number).length() == 3, "%s: %s" % [id, r.number])
		assert_has(["left", "right"], str(r.drive), id)


func test_cars_drive_on_the_left_in_the_uk_ireland_australia_new_zealand_india_and_japan() -> void:
	for id: String in ["uk", "ie", "au", "nz", "in", "jp"]:
		assert_eq(LifeRegion.drive(id), "left", id)
	for id: String in ["ge", "eu", "us", "ca"]:
		assert_eq(LifeRegion.drive(id), "right", id)


func test_the_kerb_drill_looks_first_the_way_the_nearest_cars_come_from() -> void:
	assert_eq(LifeRegion.look_order("ge"), "left, right, left")
	assert_eq(LifeRegion.look_order("uk"), "right, left, right")


func test_the_default_comes_from_the_devices_locale() -> void:
	assert_eq(LifeRegion.from_locale("ka_GE"), "ge")
	assert_eq(LifeRegion.from_locale("en_GB"), "uk")
	assert_eq(LifeRegion.from_locale("en_US"), "us")
	assert_eq(LifeRegion.from_locale("fr_CA"), "ca")
	assert_eq(LifeRegion.from_locale("de_DE"), "eu")
	assert_eq(LifeRegion.from_locale("en_IE"), "ie")
	assert_eq(LifeRegion.from_locale("mt_MT"), "ie", "Malta drives on the left and dials 112")
	assert_eq(LifeRegion.from_locale("en_AU"), "au")
	assert_eq(LifeRegion.from_locale("ja_JP"), "jp")
	assert_eq(LifeRegion.from_locale("hi_IN"), "in")
	assert_eq(LifeRegion.from_locale("en-NZ"), "nz", "a dash works too")


func test_an_unknown_or_missing_country_is_europes_112() -> void:
	assert_eq(LifeRegion.from_locale(""), LifeRegion.DEFAULT)
	assert_eq(LifeRegion.from_locale("en"), LifeRegion.DEFAULT)
	assert_eq(LifeRegion.from_locale("pt_BR"), LifeRegion.DEFAULT)
	assert_eq(LifeRegion.number(LifeRegion.DEFAULT), "112")
	assert_eq(LifeRegion.number("xx"), "112", "an unknown id reads as the default")


func test_a_chosen_region_wins_over_the_device() -> void:
	assert_eq(LifeRegion.resolve("uk", "ka_GE"), "uk")
	assert_eq(LifeRegion.resolve("", "ka_GE"), "ge")
	assert_eq(LifeRegion.resolve("nonsense", "en_US"), "us")


func test_a_number_is_read_digit_by_digit() -> void:
	assert_eq(LifeRegion.spoken("112"), "one one two")
	assert_eq(LifeRegion.spoken("999"), "nine nine nine")
	assert_eq(LifeRegion.spoken("000"), "zero zero zero")


func test_the_keys_to_dial() -> void:
	assert_eq(LifeRegion.keys("112"), ["key_1", "key_1", "key_2"] as Array[String])
	assert_eq(LifeRegion.keys("000"), ["key_0", "key_0", "key_0"] as Array[String])
