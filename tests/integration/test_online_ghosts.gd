extends GutTest
## M4 ghost races through OnlineService, two players on the fake server (tests/fakes/, the module 0.2.6's
## answers): my best runs go on my showcase and a friend who visits races them, even offline later (kept on the
## device with the showcase); a new best replaces my ghost; a gift that holds a whole course brings my ghost
## along; REPORT covers ghosts; friends only, consent first; names only for viewers who may see them; deleting
## the online account forgets friends' ghosts.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const WORLD := "sandbox_1:42"
const ORIGIN := Vector3i(100, 10, 200)

var DIR := "user://test_online_ghosts_%d/" % OS.get_process_id()
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
	s.ghost_book = GhostBook.new()
	s.ghost_book_path = DIR + device + "_ghosts.json"
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


## A 10 x 3 x 10 area: a stone floor, START at (1, 0, 1), FINISH at (8, 0, 8) (+ `more` START/FINISH pairs).
func _area(more: Array = []) -> String:
	var b := {}
	for x in 10:
		for z in 10:
			b[Vector3i(x, 0, z)] = BlockIds.STONE
	b[Vector3i(1, 0, 1)] = BlockIds.START
	b[Vector3i(8, 0, 8)] = BlockIds.FINISH
	for pair: Array in more:
		b[pair[0]] = BlockIds.START
		b[pair[1]] = BlockIds.FINISH
	return BuildCodec.encode(b, Vector3i(10, 3, 10))


## A straight run from START's top to FINISH's top in `ms`, in the area's cells.
func _ghost(ms: int = 2000, start := Vector3i(1, 0, 1), finish := Vector3i(8, 0, 8)) -> RaceGhost:
	var g := RaceGhost.new()
	g.start = start
	g.finish = finish
	g.ms = ms
	var n := RaceGhost.sample_count(ms)
	for i in n:
		g.points.append((Vector3(finish - start) * i / float(n - 1) * 10.0).round() / 10.0)
	var look := AvatarLook.new()
	look.hat = &"crown"
	g.look = look.to_code()
	return g


func _share(mine: OnlineService, ghosts: Array) -> Dictionary:
	var list: Array[Dictionary] = []
	for g: RaceGhost in ghosts:
		list.append({"start": ORIGIN + g.start, "ghost": g})
	return await mine.share_showcase_ghosts(list, WORLD, ORIGIN, Vector3i(10, 3, 10))


# --- On my showcase ---

func test_my_best_run_goes_on_my_showcase_and_a_visiting_friend_races_it() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	assert_eq(await mine.publish_showcase(_area()), "")
	var r := await _share(mine, [_ghost()])
	assert_eq(r, {"text": "", "shared": 1})
	assert_eq(mine.ghost_book.shared_at(WORLD, ORIGIN + Vector3i(1, 0, 1)).ms, 2000, "remembered: a new best can replace it")
	var visit := await friend.showcase_of(mine.backend.user_id())
	assert_eq(visit.text, "")
	var ghosts: Array = visit.showcase.ghosts
	assert_eq(ghosts.size(), 1, "the showcase comes with its ghosts")
	var g: RaceGhost = ghosts[0]
	assert_eq([g.owner, g.ms, g.start, g.finish], ["Hopper", 2000, Vector3i(1, 0, 1), Vector3i(8, 0, 8)])
	assert_eq(AvatarLook.from_code(g.look).hat, &"crown", "the racer's look")
	assert_false(friend.ghost_book.showcase_for(mine.backend.user_id()).is_empty(), "kept on the device")
	assert_true(FileAccess.file_exists(friend.ghost_book_path))


func test_offline_a_kept_showcase_still_races() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	await mine.publish_showcase(_area())
	await _share(mine, [_ghost()])
	await friend.showcase_of(mine.backend.user_id())
	server.down = true
	friend.sign_out()
	var kept := friend.kept_showcases()
	assert_eq(kept.size(), 1)
	assert_eq(kept[0].owner, "Hopper")
	var s := friend.kept_showcase(str(kept[0].owner_id))
	assert_true(s.offline)
	assert_eq((s.ghosts as Array).size(), 1)
	assert_eq(s.build, _area(), "the whole course, to race on without the server")
	# The book is read again from the device (a fresh game, still offline).
	var again := GhostBook.load_from(friend.ghost_book_path)
	assert_eq(again.showcase_for(mine.backend.user_id()).ghosts.size(), 1)


func test_a_new_best_replaces_my_ghost_and_a_new_showcase_takes_them_down() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	await mine.publish_showcase(_area())
	await _share(mine, [_ghost(3000)])
	assert_eq(await mine.share_ghost(_ghost(2000), WORLD, ORIGIN + Vector3i(1, 0, 1)), "")
	var visit := await friend.showcase_of(mine.backend.user_id())
	assert_eq(visit.showcase.ghosts.size(), 1, "one ghost per course")
	assert_eq((visit.showcase.ghosts[0] as RaceGhost).ms, 2000)
	assert_eq(mine.ghost_book.shared_at(WORLD, ORIGIN + Vector3i(1, 0, 1)).ms, 2000)
	await mine.publish_showcase(_area())
	assert_eq((await friend.showcase_of(mine.backend.user_id())).showcase.ghosts.size(), 0, "a new area: shared again")


func test_what_the_server_refuses_has_kind_words() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	assert_eq(await mine.share_ghost(_ghost(), WORLD, ORIGIN + Vector3i(1, 0, 1)), GhostRaceRules.message("no_showcase"))
	await mine.publish_showcase(_area())
	var bad := _ghost()
	bad.start = Vector3i(2, 0, 1)
	var r := await _share(mine, [bad])
	assert_eq(r.shared, 0)
	assert_eq(r.text, GhostRaceRules.message("not_on_course"))


# --- With a gift ---

func test_a_gift_with_my_whole_course_brings_my_ghost_along() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	var b := {}
	for x in 8:
		b[Vector3i(x, 0, 0)] = BlockIds.STONE
	b[Vector3i(0, 0, 0)] = BlockIds.START
	b[Vector3i(7, 0, 0)] = BlockIds.FINISH
	var build := BuildCodec.encode(b)
	assert_eq(await mine.send_gift(friend.backend.user_id(), build, _ghost(2000, Vector3i.ZERO, Vector3i(7, 0, 0))), "")
	assert_eq(server.calls.count("share_ghost"), 1, "one present with the ghost in it")
	await friend.refresh_gifts()
	assert_true(friend.gifts[0].ghost, "PRESENTS can say a race comes with it")
	var opened := await friend.open_gift(friend.gifts[0].id)
	assert_eq(opened.text, "")
	var e := friend.ghost_book.gift_entry(opened.slot)
	assert_eq(e.owner, "Hopper")
	assert_eq((e.ghost as RaceGhost).ms, 2000)
	friend.delete_stamp(opened.slot)
	assert_eq(friend.ghost_book.gift_entry(opened.slot), {}, "the stamp's ghost goes with it")


# --- REPORT covers ghosts ---

func test_report_covers_ghosts_and_forgets_that_players() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	var b := {Vector3i(0, 0, 0): BlockIds.START, Vector3i(7, 0, 0): BlockIds.FINISH}
	await mine.send_gift(friend.backend.user_id(), BuildCodec.encode(b), _ghost(2000, Vector3i.ZERO, Vector3i(7, 0, 0)))
	await friend.refresh_gifts()
	var slot: int = (await friend.open_gift(friend.gifts[0].id)).slot
	await mine.publish_showcase(_area())
	await _share(mine, [_ghost()])
	await friend.showcase_of(mine.backend.user_id())
	var stamp := friend.gift_book.stamp(slot)
	assert_eq(await friend.report_build(stamp.from_id, "gift", stamp.build, slot), "")
	var report: Dictionary = server.build_reports.back()
	assert_eq(report.ghost.source, "reporter", "the gift's ghost as this game had it")
	assert_eq(report.ghost.ms, 2000)
	assert_eq(friend.ghost_book.ghosts.size(), 0, "everything of that player is forgotten here")
	assert_eq(friend.ghost_book.showcase_for(mine.backend.user_id()), {})


func test_a_showcase_report_keeps_its_ghosts_for_the_reviewer() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	await mine.publish_showcase(_area())
	await _share(mine, [_ghost()])
	assert_eq(await friend.report_build(mine.backend.user_id(), "showcase", _area()), "")
	assert_eq((server.build_reports.back().ghosts as Array).size(), 1)


# --- Consent, names, deletion ---

func test_friends_only_and_consent_first() -> void:
	var mine := await _player("dev-me", "Hopper")
	var stranger := await _player("dev-x", "Stranger")
	await mine.publish_showcase(_area())
	await _share(mine, [_ghost()])
	assert_eq((await stranger.ghosts_of(mine.backend.user_id())).text, GiftRules.message("not_friends"))
	var kid := await _player("dev-kid", "Kiddo", AgeBand.UNDER_13, OnlineRules.CONSENT_NONE)
	server.befriend(kid.backend.user_id(), mine.backend.user_id())
	var before: int = server.calls.count("list_ghosts")
	assert_eq((await kid.ghosts_of(mine.backend.user_id())).text, OnlineRules.message("consent_needed"))
	assert_eq(await kid.share_ghost(_ghost(), WORLD, ORIGIN), OnlineRules.message("consent_needed"))
	assert_eq(server.calls.count("list_ghosts"), before, "the child's game never asked the server")


func test_names_show_for_13_plus_and_with_a_grown_ups_yes() -> void:
	var teen := await _player("dev-t", "Teen_1")
	assert_true(teen.ghost_names_shown())
	var kid := await _player("dev-k", "Kid_1", AgeBand.UNDER_13, OnlineRules.CONSENT_VERIFIED)
	assert_true(kid.ghost_names_shown())
	var no := await _player("dev-n", "Kid_2", AgeBand.UNDER_13, OnlineRules.CONSENT_NONE)
	assert_false(no.ghost_names_shown(), "no name for an under-13 viewer without consent")
	kid.sign_out()
	assert_true(kid.ghost_names_shown(), "offline: the last known answer")
	no.sign_out()
	assert_false(no.ghost_names_shown())


func test_deleting_the_online_account_forgets_friends_ghosts() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	await mine.publish_showcase(_area())
	await _share(mine, [_ghost()])
	await friend.showcase_of(mine.backend.user_id())
	assert_true(friend.online_files().has(friend.ghost_book_path))
	friend.forget_online()
	assert_eq(friend.ghost_book.ghosts.size(), 0)
	assert_false(FileAccess.file_exists(friend.ghost_book_path))


func test_presents_say_when_a_race_comes_with_them() -> void:
	var p := await _pair()
	var mine: OnlineService = p[0]
	var friend: OnlineService = p[1]
	var b := {Vector3i(0, 0, 0): BlockIds.START, Vector3i(7, 0, 0): BlockIds.FINISH}
	await mine.send_gift(friend.backend.user_id(), BuildCodec.encode(b), _ghost(2000, Vector3i.ZERO, Vector3i(7, 0, 0)))
	await friend.refresh_gifts()
	var page := GiftsPage.new()
	page.service = friend
	add_child_autofree(page)
	await wait_process_frames(2)
	var words := page.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	assert_true(words.any(func(t: String) -> bool: return t.contains("and a race!")), "PRESENTS says a race comes with it")
	var open := page.find_children("*", "Button", true, false).filter(func(x: Button) -> bool: return x.text == "OPEN")
	assert_gt(open.size(), 0)
	(open[0] as Button).pressed.emit()
	await wait_until(func() -> bool: return page.message.text.contains("stamp"), 5.0)
	assert_string_contains(page.message.text, "step on START to race")
	assert_true(friend.ghost_race_in_slot(0))
