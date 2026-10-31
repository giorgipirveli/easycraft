extends GutTest
## Owner #79 (spec §25.2): OnlineService's invite part against the fake server (module 0.2.16's answers). A friend's code
## brings the welcome gift at once (its gold reaches the phone by the wallet sync) and names the guide; a code typed
## offline waits in the profile and goes up at the next sign-in; a refused code is not kept; the first unit mastered is
## reported once, and the inviter hears "Your friend Sam_22 joined and learned! +250 gold" with the gold on the phone.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_invite_online_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000


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
	s.clock = func() -> int: return now
	s.in_online_world = func() -> bool: return false
	add_child_autofree(s)
	return s


func _player(device: String, username: String) -> OnlineService:
	server.make_account(device, username)
	var s := _service(device, username)
	assert_eq(await s.sign_in(), "")
	return s


func test_an_account_reads_its_code_and_keeps_it_for_offline_pages() -> void:
	var alex := await _player("dev-alex", "Alex_7")
	var info := await alex.invite_info()
	assert_eq(info.text, "")
	assert_true(InviteRules.looks_like_code(info.code), info.code)
	assert_eq(alex.profile.invite.code, info.code)
	assert_eq(int(info.rewards.inviter), InviteRules.INVITER_GOLD)


func test_a_friend_s_code_brings_the_welcome_gift_and_names_the_guide() -> void:
	var alex := await _player("dev-alex", "Alex_7")
	var code: String = (await alex.invite_info()).code
	var sam := await _player("dev-sam", "Sam_22")
	var gold := sam.profile.survivor_gold
	var r := await sam.use_invite(code.to_lower().replace("-", " "))
	assert_true(r.ok)
	assert_eq(r.text, "Welcome, explorer! Alex_7's code brought you +100 gold.")
	assert_true(sam.profile.invite.used)
	assert_eq(sam.profile.invite.guide, "Alex_7")
	assert_eq(sam.profile.survivor_gold, gold + InviteRules.WELCOME_GOLD, "the server's gift reached the phone")
	var again := await sam.use_invite(code)
	assert_false(again.ok)
	assert_eq(again.text, InviteRules.error_words("already_used"))


func test_a_code_typed_offline_waits_for_the_next_sign_in() -> void:
	var alex := await _player("dev-alex", "Alex_7")
	var code: String = (await alex.invite_info()).code
	server.make_account("dev-sam", "Sam_22")
	var sam := _service("dev-sam", "Sam_22")
	var kept := await sam.use_invite(code)
	assert_true(kept.get("waiting", false))
	assert_eq(sam.profile.invite.pending_code, code)
	watch_signals(sam)
	assert_eq(await sam.sign_in(), "")
	assert_signal_emitted(sam, "invite_code_result")
	assert_eq(sam.profile.invite.pending_code, "")
	assert_true(sam.profile.invite.used)


func test_a_refused_code_is_not_kept() -> void:
	var sam := await _player("dev-sam", "Sam_22")
	var r := await sam.use_invite("RED-FOX-99")
	assert_false(r.ok)
	assert_eq(r.text, InviteRules.error_words("unknown"))
	assert_eq(sam.profile.invite.pending_code, "")
	assert_eq((await sam.use_invite("hello")).text, InviteRules.error_words("unknown"), "not even a code")


func test_the_first_unit_learned_pays_both_and_the_inviter_hears_it() -> void:
	var alex := await _player("dev-alex", "Alex_7")
	var code: String = (await alex.invite_info()).code
	var sam := await _player("dev-sam", "Sam_22")
	await sam.use_invite(code)
	sam.profile.invite.note_learned(20_000)
	var before := sam.profile.survivor_gold
	await sam.send_invite_events()
	assert_eq(sam.profile.invite.events_to_send(), [] as Array[Dictionary], "reported once")
	assert_eq(sam.profile.survivor_gold, before + InviteRules.LEARNER_GOLD)
	var mine := sam.take_invite_news()
	assert_eq(InviteRules.news_words(mine[0]), "You learned a whole unit with your guide Alex_7: +50 gold!")
	# Alex's game: the note nudged it; its news and gold arrive.
	await wait_process_frames(2)
	var gold := alex.profile.survivor_gold
	await alex.refresh_invite_news()
	var words: Array[String] = []
	for n in alex.take_invite_news():
		words.append(InviteRules.news_words(n))
	assert_has(words, "Your friend Sam_22 joined and learned! +250 gold")
	assert_gte(alex.profile.survivor_gold, gold, "the gold came to the phone")
	var info := await alex.invite_info()
	assert_eq(int(info.counts.learned), 1)
	assert_eq(str(info.friends[0].name), "Sam_22")


func test_a_grown_up_makes_a_family_code_that_a_new_player_joins() -> void:
	var mum := await _player("dev-mum", "Mum_1")
	var made := await mum.invite_group("make", "family")
	assert_eq(made.text, "")
	assert_string_starts_with(made.code, "FAMILY-")
	var kid := await _player("dev-kid", "Kid_1")
	var r := await kid.use_invite(made.code)
	assert_true(r.ok)
	assert_string_starts_with(r.text, "Welcome to the family!")
	var info := await mum.invite_info()
	assert_eq(int(info.groups.family.members), 2)
