extends GutTest
## Photo mode and the rest of the game (M3 Task 16 rulings): solo play freezes the world while you
## take a picture; on LAN nothing pauses, and getting hurt drops you out of photo mode so you can react.


func test_only_solo_play_pauses_the_world() -> void:
	assert_true(PhotoRules.pauses_world(&"solo"))
	assert_false(PhotoRules.pauses_world(&"host"), "friends keep playing")
	assert_false(PhotoRules.pauses_world(&"client"))


func test_a_hit_leaves_photo_mode_but_healing_does_not() -> void:
	assert_true(PhotoRules.exits_on_hurt(10, 8))
	assert_false(PhotoRules.exits_on_hurt(8, 9), "hearts coming back")
	assert_false(PhotoRules.exits_on_hurt(8, 8))
	assert_false(PhotoRules.exits_on_hurt(-1, 3), "hearts not known yet")
