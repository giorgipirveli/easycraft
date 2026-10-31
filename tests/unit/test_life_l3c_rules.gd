extends GutTest
## Owner #112, #118 (Life L3c): the small rules L3c adds to Life's framework. The region's own words for Find Your Way's
## metro ({metro_where}: Tbilisi's two lines for Georgia) and Home Helper's bins ({bins_where}); the plants' soil words on
## the pour gauge; Life Town's third row (Online City, Find Your Way, Home Helper) in front of the second, its doors facing
## the spawn, never near another's.


func test_the_regions_metro_words() -> void:
	assert_string_contains(LifeRegion.metro_words("ge"), "Tbilisi", "Georgia's own")
	assert_string_contains(LifeRegion.metro_words("ge"), "two lines")
	assert_string_contains(LifeRegion.metro_words("ge"), "Station Square", "where the two lines meet")
	assert_string_contains(LifeRegion.metro_words("uk"), "London")
	assert_eq(LifeRegion.metro_words("no_such"), LifeRegion.METRO_DEFAULT)
	var v := LifeExperience.vars("find_way", "middle", 1, "ge")
	assert_eq(str(v.metro_where), LifeRegion.metro_words("ge"))


func test_the_regions_bins_words() -> void:
	assert_string_contains(LifeRegion.bins_words("ge"), "Georgia")
	assert_string_contains(LifeRegion.bins_words("uk"), "council")
	assert_eq(LifeRegion.bins_words("no_such"), LifeRegion.BINS_DEFAULT)
	for id in LifeRegion.ids():
		assert_lte(LifeRegion.bins_words(id).length(), 160, id + ": one short sentence")
		assert_lte(LifeRegion.metro_words(id).length(), 160, id)
	var v := LifeExperience.vars("home_helper", "middle", 1, "uk")
	assert_eq(str(v.bins_where), LifeRegion.bins_words("uk"))


func test_the_soil_on_the_pour_gauge() -> void:
	assert_eq(LifeRoomHud.amount_words(0.1, "soil", 0.5), "the soil is still dry")
	assert_eq(LifeRoomHud.amount_words(0.5, "soil", 0.5), "damp: just right")
	assert_eq(LifeRoomHud.amount_words(0.9, "soil", 0.5), "too wet")


func test_life_towns_third_row_faces_the_spawn() -> void:
	var third: Array[String] = []
	for id: String in LifeTown.SPOTS:
		var s: Dictionary = LifeTown.SPOTS[id]
		if (s.min as Vector2i).y >= LifeTown.THIRD_ROW_Z:
			third.append(str(s.experience))
			assert_gt((s.door as Vector2).y, float((s.max as Vector2i).y), id + ": its door in front, towards the spawn")
			assert_lte((s.door as Vector2).y, float(LifeTown.PLAZA_MAX.y + 1), id + ": on the plaza")
	third.sort()
	assert_eq(third, ["find_way", "home_helper", "online_city"] as Array[String], "L3c's three, in the third row")
	assert_gt(LifeTown.THIRD_ROW_Z, LifeTown.SECOND_ROW_Z + 3, "in front of the second row")
