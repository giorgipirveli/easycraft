extends GutTest
## M3 Task 9: the look and the owned avatar items live in the profile (account-wide), parsed
## defensively: old profiles get the default look; bad data never breaks the rest of the profile.


func test_a_new_profile_has_the_default_look_and_owns_nothing_extra() -> void:
	var p := ProfileData.new()
	assert_true(p.avatar.equals(AvatarLook.new()))
	assert_eq(p.cosmetics, [] as Array[String])


func test_round_trip() -> void:
	var p := ProfileData.new()
	p.username = "Hopper"
	p.survivor_gold = 321
	AvatarUnlocks.grant(p, "hat.crown")
	AvatarUnlocks.grant(p, "emote.dance_star")
	p.avatar.hat = &"crown"
	p.avatar.shirt = &"pink"
	p.avatar.emotes[7] = &"dance_star"
	var q := ProfileData.from_json(p.to_json())
	assert_eq(q.cosmetics, ["hat.crown", "emote.dance_star"] as Array[String])
	assert_true(q.avatar.equals(p.avatar))
	assert_eq(q.survivor_gold, 321, "other fields survive")
	assert_eq(q.username, "Hopper")


## Owner 43: the look it showed then, the classic one (the new default is for new players).
func test_an_old_profile_without_avatar_data_gets_the_default() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop","age_band":"13_plus","survivor_gold":40}')
	assert_true(q.avatar.equals(AvatarLook.classic()))
	assert_eq(q.cosmetics, [] as Array[String])
	assert_eq(q.survivor_gold, 40)


func test_bad_avatar_data_falls_back_without_breaking_the_profile() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop","age_band":"13_plus","survivor_gold":40,' +
		'"avatar":"crown","cosmetics":{"hat.crown":true}}')
	assert_true(q.avatar.equals(AvatarLook.classic()), "owner 43: a saved profile falls back to the classic look")
	assert_eq(q.cosmetics, [] as Array[String])
	assert_eq(q.username, "Hop")
	assert_true(q.is_onboarded())


func test_a_saved_look_wearing_something_not_owned_is_taken_off() -> void:
	## A hand-edited profile can't wear what it never unlocked.
	var q := ProfileData.from_json('{"version":1,"avatar":{"hat":"crown","outfit":"cosmic","cape":"hero"},"cosmetics":[]}')
	assert_eq(q.avatar.hat, &"none")
	assert_eq(q.avatar.outfit, &"none")
	assert_eq(q.avatar.cape, &"hero")
	var r := ProfileData.from_json('{"version":1,"avatar":{"hat":"crown"},"cosmetics":["hat.crown"]}')
	assert_eq(r.avatar.hat, &"crown")
