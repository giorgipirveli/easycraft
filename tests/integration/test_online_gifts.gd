extends GutTest
## Friends when they are not online together, through OnlineService (M4 Wave 3, agent I; spec §17.5):
## a present opened into a stamp, a showcase visited while its owner is away with stickers the owner
## reads next time, a bottle with a tiny build, REPORT on everything received; friends only, consent
## first, every received thing deletable. Against the fake server (tests/fakes/, the module's answers).

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_online_gifts_%d/" % OS.get_process_id()
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


func _player(device: String, username: String, band: StringName = AgeBand.TEEN_PLUS, consent: String = "") -> OnlineService:
	server.make_account(device, username, band, consent if consent != "" else
		(OnlineRules.CONSENT_VERIFIED if band == AgeBand.UNDER_13 else OnlineRules.CONSENT_NONE),
		consent != OnlineRules.CONSENT_NONE)
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = band
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.gift_book = GiftStampBook.new()
	s.gift_book_path = DIR + device + "_gifts.json"
	s.clock = func() -> int: return now
	add_child_autofree(s)
	s.prefs.safe_card_seen = now
	assert_eq(await s.sign_in(), "")
	return s


func _pair() -> Array:   # [mine, friend]
	var mine := await _player("dev-me", "Hopper")
	var friend := await _player("dev-mia", "Mia_2")
	server.befriend(mine.backend.user_id(), friend.backend.user_id())
	await mine.refresh_friends()
	await friend.refresh_friends()
	return [mine, friend]


func _build(n: int, id: int = BlockIds.PLANKS) -> String:
	var b := {}
	for x in n:
		for y in n:
			for z in n:
				b[Vector3i(x, y, z)] = id
	return BuildCodec.encode(b)


# --- Blueprint gifts ---

func test_a_present_arrives_and_opens_into_a_stamp() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	watch_signals(friend)
	assert_eq(await mine.send_gift(friend.backend.user_id(), _build(3)), "")
	await wait_process_frames(2)
	assert_signal_emitted(friend, "gifts_changed", "the nudge (104) makes the friend's game look")
	assert_eq(friend.gifts.size(), 1)
	assert_eq(friend.gifts[0].from, "Hopper")
	assert_eq(friend.gifts[0].count, 27)
	assert_eq(mine.gift_book.mine, [_build(3)] as Array[String], "the sender keeps it on its shelf to send again")
	var opened := await friend.open_gift(friend.gifts[0].id)
	assert_eq(opened.text, "")
	assert_eq(opened.slot, 0)
	assert_eq(friend.gifts.size(), 0)
	assert_eq(friend.gift_book.stamp(0).from, "Hopper")
	assert_eq(friend.gift_book.blocks_of(0).size(), 27)
	assert_true(FileAccess.file_exists(friend.gift_book_path), "kept on the device")
	var again := await friend.open_gift("g-gone")
	assert_eq(again.text, GiftRules.message("gift_gone"))


func test_friends_only_and_a_child_waits_for_a_grown_up() -> void:
	var mine := await _player("dev-me", "Hopper")
	var stranger := await _player("dev-x", "Stranger")
	assert_eq(await mine.send_gift(stranger.backend.user_id(), _build(2)), GiftRules.message("not_friends"))
	var kid := await _player("dev-kid", "Kiddo", AgeBand.UNDER_13, OnlineRules.CONSENT_NONE)
	server.befriend(kid.backend.user_id(), mine.backend.user_id())
	assert_eq(await kid.send_gift(mine.backend.user_id(), _build(2)), OnlineRules.message("consent_needed"))
	assert_eq(await kid.showcase_of(mine.backend.user_id()), {"text": OnlineRules.message("consent_needed"), "showcase": {}})
	assert_eq(await kid.send_bottle(mine.backend.user_id(), "Hi!"), OnlineRules.message("consent_needed"))
	assert_eq(server.calls.count("send_gift"), 1, "the child's game never asked the server")


func test_too_big_or_broken_builds_never_leave_and_ten_unopened_per_friend() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend_id: String = p[1].backend.user_id()
	assert_eq(await mine.send_gift(friend_id, _build(9)), GiftRules.message("too_big"))
	assert_eq(await mine.send_gift(friend_id, "junk"), GiftRules.message("bad_build"))
	for i in GiftRules.GIFTS_PER_FRIEND:
		assert_eq(await mine.send_gift(friend_id, _build(1 + i % 3)), "")
	assert_eq(await mine.send_gift(friend_id, _build(1)), GiftRules.message("too_many_gifts"))


func test_every_present_can_be_deleted_and_a_muted_friends_are_hidden() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	await mine.send_gift(friend.backend.user_id(), _build(2))
	await mine.send_gift(friend.backend.user_id(), _build(1))
	await friend.refresh_gifts()
	assert_eq(await friend.discard_gift(friend.gifts[0].id), "")
	assert_eq(friend.gifts.size(), 1)
	friend.mute(mine.backend.user_id())
	await friend.refresh_gifts()
	assert_eq(friend.gifts.size(), 0, "muted: not shown")
	friend.unmute(mine.backend.user_id())
	await friend.refresh_gifts()
	var opened := await friend.open_gift(friend.gifts[0].id)
	friend.delete_stamp(opened.slot)
	assert_eq(friend.gift_book.slots(), [] as Array[int], "a stamp can be deleted too")


func test_report_on_a_gift_stamp_mutes_deletes_it_and_keeps_a_copy_for_the_reviewer() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	await mine.send_gift(friend.backend.user_id(), _build(2, BlockIds.RED))
	await friend.refresh_gifts()
	var slot: int = (await friend.open_gift(friend.gifts[0].id)).slot
	var stamp := friend.gift_book.stamp(slot)
	assert_eq(await friend.report_build(stamp.from_id, "gift", stamp.build, slot), "")
	assert_eq(server.build_reports.size(), 1)
	assert_eq(server.build_reports[0].build, {"build": _build(2, BlockIds.RED), "source": "reporter"})
	assert_true(friend.is_muted(mine.backend.user_id()))
	assert_true(friend.gift_book.stamp(slot).is_empty(), "gone from the GIFTS page")


# --- Showcases and the guestbook ---

func test_a_showcase_is_visited_while_its_owner_is_away_and_stickers_wait_for_it() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	var area := _build(6, BlockIds.BRICK)
	var buddy := {"build": _build(2, BlockIds.CRYSTAL), "at": [1, 0, 1]}
	assert_eq(await mine.publish_showcase(area, buddy), "")
	mine.sign_out()   # away
	var visit := await friend.showcase_of(mine.backend.user_id() if mine.backend.user_id() != "" else server.id_of("Hopper"))
	assert_eq(visit.text, "")
	assert_eq(visit.showcase.owner, "Hopper")
	assert_eq(visit.showcase.build, area)
	assert_eq(visit.showcase.buddy.at, Vector3i(1, 0, 1))
	assert_eq(await friend.sign_guestbook(server.id_of("Hopper"), "rainbow"), "")
	assert_eq(await friend.sign_guestbook(server.id_of("Hopper"), "nice words"), GiftRules.message("bad_sticker"))
	assert_eq(await mine.sign_in(), "")
	var own := await mine.my_showcase()
	assert_eq(own.guestbook.size(), 1)
	assert_eq(own.guestbook[0].from, "Mia_2")
	assert_eq(own.guestbook[0].sticker, "rainbow")
	var removed := await mine.remove_sticker(own.guestbook[0].id)
	assert_eq(removed, {"text": "", "guestbook": [] as Array[Dictionary]})
	assert_eq(await mine.remove_showcase(), "")
	assert_eq((await friend.showcase_of(server.id_of("Hopper"))).text, GiftRules.message("no_showcase"))


func test_a_sticker_while_online_is_heard_at_once() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	await mine.publish_showcase(_build(4))
	watch_signals(mine)
	await friend.sign_guestbook(mine.backend.user_id(), "star")
	assert_signal_emitted_with_parameters(mine, "sticker_received", ["Mia_2", "star"])
	assert_eq(mine.new_stickers, 1)
	await mine.my_showcase()
	assert_eq(mine.new_stickers, 0, "seen")


## M4 Task 10 review G: a sticker note from a player this child blocked is not counted or shown (the server already
## refuses a guestbook sticker from a non-friend; this is the game's own guard, like every other received thing).
func test_a_sticker_note_from_a_blocked_player_is_not_heard() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	var friend_id := friend.backend.user_id()
	assert_eq(await mine.block(friend_id), "")
	await mine.refresh_friends()
	watch_signals(mine)
	server.notify(mine.backend.user_id(), GiftRules.NOTE_STICKER,
		{"from_user_id": friend_id, "from_username": "Mia_2", "sticker": "star"})
	await wait_process_frames(1)
	assert_signal_not_emitted(mine, "sticker_received")
	assert_eq(mine.new_stickers, 0)


func test_an_empty_or_too_detailed_area_never_goes_up() -> void:
	var mine := await _player("dev-me", "Hopper")
	var air := PackedInt32Array()
	air.resize(8)
	assert_eq(await mine.publish_showcase(BuildCodec.encode_cells(Vector3i(2, 2, 2), air)), ShowcaseArea.message("empty"))
	assert_false(server.calls.has("publish_showcase"))


# --- Bottle mail ---

func test_a_bottle_brings_a_phrase_and_its_tiny_build_becomes_a_stamp() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	assert_eq(await mine.send_bottle(friend.backend.user_id(), "meet me at the park"), GiftRules.message("bad_phrase"))
	assert_eq(await mine.send_bottle(friend.backend.user_id(), "Hi!", _build(5)), GiftRules.message("too_big"))
	assert_eq(await mine.send_bottle(friend.backend.user_id(), "Nice build!", _build(2, BlockIds.YELLOW)), "")
	assert_eq(await mine.send_bottle(friend.backend.user_id(), "Bye!"), "")
	await wait_process_frames(2)
	assert_eq(friend.bottles.size(), 2)
	var first := await friend.open_bottle(friend.bottles[0].id)
	assert_eq(first.bottle.phrase, "Nice build!")
	assert_eq(first.bottle.from, "Hopper")
	assert_eq(friend.gift_book.stamp(first.slot).kind, GiftStampBook.KIND_BOTTLE)
	var second := await friend.open_bottle(friend.bottles[0].id)
	assert_eq(second.bottle.phrase, "Bye!")
	assert_eq(second.slot, -1, "no build, no stamp")
	assert_eq(friend.bottles.size(), 0)


# --- The online account deleted ---

func test_deleting_the_online_account_forgets_friends_stamps_on_this_device() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	await mine.send_gift(friend.backend.user_id(), _build(2))
	await friend.refresh_gifts()
	await friend.open_gift(friend.gifts[0].id)
	assert_true(FileAccess.file_exists(friend.gift_book_path))
	assert_true(friend.online_files().has(friend.gift_book_path))
	var start := await friend.delete_account_start()
	assert_eq(await friend.delete_account(start.confirm, FakeServer.FAKE_PASSWORD), "")   # owner #105: the password too
	assert_false(FileAccess.file_exists(friend.gift_book_path))
	assert_eq(friend.gift_book.slots(), [] as Array[int])
