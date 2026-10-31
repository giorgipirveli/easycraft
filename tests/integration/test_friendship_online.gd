extends GutTest
## Owner #81, #82, #85: OnlineService's better-together part against the fake server (module 0.2.18's answers). What
## this device learned (a day, the units mastered) and its proud moments wait in the profile and go up at the next
## sign-in; two friends who learn the same day have a day together; a present sent, opened (the game gives the thing)
## and thanked (the sender's gold arrives by the wallet sync); friends' news reach the main menu's card in a child's
## words; crews. Nothing personal travels: ids and kinds.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_friendship_online_%d/" % OS.get_process_id()
var server: RefCounted


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _service(device: String, username: String) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.in_online_world = func() -> bool: return false
	add_child_autofree(s)
	return s


func _friends() -> Array[OnlineService]:
	var a: String = server.make_account("dev-alex", "Alex_7")
	var b: String = server.make_account("dev-sam", "Sam_22")
	server.befriend(a, b)
	var alex := _service("dev-alex", "Alex_7")
	var sam := _service("dev-sam", "Sam_22")
	assert_eq(await alex.sign_in(), "")
	assert_eq(await sam.sign_in(), "")
	return [alex, sam] as Array[OnlineService]


func test_learning_and_moments_kept_offline_go_up_at_the_next_sign_in() -> void:
	server.make_account("dev-alex", "Alex_7")
	var alex := _service("dev-alex", "Alex_7")
	SocialSender.learned("g4.maths.big_numbers", alex.profile)
	SocialSender.moment(PostcardRules.landed("moon"), alex.profile)
	assert_eq(alex.profile.social.units, ["g4.maths.big_numbers"] as Array[String], "kept while offline")
	assert_eq(alex.profile.social.moments.size(), 1)
	assert_eq(await alex.sign_in(), "")
	assert_true(server.calls.has("social_learned"))
	assert_true(server.calls.has("social_moment"))
	assert_true(alex.profile.social.units.is_empty(), "the server heard it")
	assert_eq(alex.profile.social.learned_day, -1)
	assert_true(alex.profile.social.moments.is_empty())
	var id: String = server.id_of("Alex_7")
	assert_eq(server.soc[id].week.units, ["g4.maths.big_numbers"])


func test_two_friends_who_learn_the_same_day_have_a_day_together_and_hear_it() -> void:
	var pair := await _friends()
	var alex := pair[0]
	var sam := pair[1]
	SocialSender.learned("", alex.profile)
	await alex.send_social_events()
	SocialSender.learned("", sam.profile)
	await sam.send_social_events()
	var info := await alex.social_info()
	assert_eq(info.text, "")
	assert_eq(info.friends.size(), 1)
	assert_eq(int(info.friends[0].days), 1)
	assert_eq(int(info.friends[0].level), 1)
	await wait_process_frames(8)   # note 109 nudged the open game: the news went onto the menu's card
	await alex.refresh_social_news()
	var words: Array = alex.take_invite_news().map(func(n: Dictionary) -> String: return InviteRules.news_words(n))
	assert_has(words, "You and Sam_22 are Good friends now: a friendship badge!")


func test_a_present_is_opened_into_the_game_and_thanked_with_gold() -> void:
	var pair := await _friends()
	var alex := pair[0]
	var sam := pair[1]
	var sam_id: String = server.id_of("Sam_22")
	var sent := await alex.send_present(sam_id, "rocket_part")
	assert_eq(sent.text, "")
	var again := await alex.send_present(sam_id, "seeds")
	assert_eq(again.text, FriendPresents.error_words("sent_today"))
	var info := await sam.social_info()
	assert_eq(info.presents.size(), 1)
	var p: Dictionary = info.presents[0]
	var opened := await sam.open_present(str(p.id))
	assert_eq(opened.text, "")
	assert_eq(opened.kind, "rocket_part")
	assert_eq(int(sam.profile.missions.parts.get(FriendPresents.ROCKET_PART_BLOCK, 0)), 1, "the game gave the part")
	assert_string_contains(str(opened.gave), "Fuel Tank")
	var gold := alex.profile.survivor_gold
	assert_eq(await sam.thank_present(str(p.id)), "")
	assert_eq(await sam.thank_present(str(p.id)), FriendPresents.error_words("already_thanked"))
	await wait_process_frames(8)   # note 109 nudged Alex's open game
	await alex.refresh_social_news()
	await wait_process_frames(4)
	assert_eq(alex.profile.survivor_gold, gold + FriendPresents.THANK_GOLD, "the thank-you's gold reached the phone")
	var words: Array = alex.take_invite_news().map(func(n: Dictionary) -> String: return InviteRules.news_words(n))
	assert_has(words, "Sam_22 said thank you for the rocket part! +10 gold")


func test_a_present_for_a_new_friend_waits_on_the_invite_code() -> void:
	server.make_account("dev-alex", "Alex_7")
	var alex := _service("dev-alex", "Alex_7")
	assert_eq(await alex.sign_in(), "")
	var code := str((await alex.invite_info()).code)
	var r := await alex.send_link_present("buddy_egg")
	assert_eq(r.text, "")
	assert_eq(int(r.waiting), 1)
	server.make_account("dev-new", "New_1")
	var newbie := _service("dev-new", "New_1")
	assert_eq(await newbie.sign_in(), "")
	assert_true((await newbie.use_invite(code)).ok)
	var info := await newbie.social_info()
	assert_eq(info.presents.size(), 1)
	assert_eq(str(info.presents[0].name), "Alex_7")
	var opened := await newbie.open_present(str(info.presents[0].id))
	assert_eq(newbie.profile.buddy_magic.found.size(), 1, "the egg hatched a secret buddy shape")
	assert_string_contains(str(opened.gave), "secret buddy shape")


func test_cheers_and_study_buddies_and_a_crew() -> void:
	var pair := await _friends()
	var alex := pair[0]
	var sam := pair[1]
	var alex_id: String = server.id_of("Alex_7")
	var sam_id: String = server.id_of("Sam_22")
	SocialSender.moment(PostcardRules.landed("moon"), alex.profile)
	await alex.send_social_events()
	var feed: Array = (await sam.social_info()).feed
	assert_eq(feed.size(), 1)
	assert_eq(await sam.send_cheer(str(feed[0].id), "amazing"), "")
	await wait_process_frames(8)
	await alex.refresh_social_news()
	var words: Array = alex.take_invite_news().map(func(n: Dictionary) -> String: return InviteRules.news_words(n))
	assert_has(words, "Sam_22 cheered: Amazing! (you landed on the Moon)")
	assert_eq((await alex.study_buddy("ask", sam_id)).state, "asked")
	assert_eq((await sam.study_buddy("yes", alex_id)).state, "yes")
	var made := await alex.crew_action("make", {"adjective": "Brave", "noun": "Comets", "badge": "rocket"})
	assert_eq(made.text, "")
	assert_eq(str(made.crew.name), "Brave Comets")
	assert_false((made.crew.members[0].look as Dictionary).has("base"), "never the boy / girl choice")
	assert_eq((await alex.crew_action("invite", {"user_id": sam_id})).text, "")
	var invites: Array = (await sam.social_info()).crew_invites
	assert_eq(invites.size(), 1)
	var joined := await sam.crew_action("join", {"crew": str(invites[0].crew)})
	assert_eq((joined.crew.members as Array).size(), 2)
	var bad := await alex.crew_action("make", {"adjective": "Kind", "noun": "Owls", "badge": "owl"})
	assert_eq(bad.text, CrewRules.error_words("in_a_crew"))
