extends GutTest
## M3 Task 21b: the books fill themselves while the child plays (BooksDirector, one per game): animals close by are
## met, food from the hand marks them fed, counted events and level-ups become memories (once each, dated), a photo
## taken soon after goes with the newest one, the first Survivor night got through is a memory, a new universe is
## explored, a finished Secret Book page gives its reward once, and the world owner's showcase (badges, the Hub
## Tree) reaches the shelves and the tree — a guest's from the host.

var DIR := "user://test_books_director_%d/" % OS.get_process_id()
var _p: ProfileData
var _d: ProgressData
var _book: MemoryBook
var _said: Array[String] = []
var _banners: Array[String] = []
var _clock := 1000
var _time := DayCycle.NOON
var _saves := 0


func before_each() -> void:
	_p = ProfileData.new()
	_d = _p.progress
	_book = MemoryBook.new()
	_said.clear()
	_banners.clear()
	_clock = 1000
	_time = DayCycle.NOON
	_saves = 0


func after_each() -> void:
	Progress.end()


func after_all() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	DirAccess.remove_absolute(DIR)


func _director(universe: int = 1, start: bool = true) -> BooksDirector:
	Progress.begin(_d)
	var b := BooksDirector.new()
	b.universe = universe
	b.profile = func() -> ProfileData: return _p
	b.progress = func() -> ProgressData: return _d
	b.save_profile = func() -> void: _saves += 1
	b.memories = func() -> MemoryBook: return _book
	b.save_memories = func() -> void: pass
	b.memory_dir = func() -> String: return DIR
	b.clock = func() -> int: return _clock
	b.date = func() -> String: return "2026-09-25"
	b.time_of_day = func() -> float: return _time
	b.said.connect(func(t: String) -> void: _said.append(t))
	b.bannered.connect(func(t: String) -> void: _banners.append(t))
	add_child_autofree(b)
	b.set_process(false)
	if start:
		b.start()
	return b


func _ids() -> Array[String]:
	var out: Array[String] = []
	for e in _book.entries:
		out.append(str(e.id))
	return out


func test_animals_close_by_are_met_once() -> void:
	var b := _director()
	var list: Array = [[&"horse", Vector3(3, 10, 0)], [&"penguin", Vector3(40, 10, 0)]]
	b.animals = func() -> Array: return list
	b.tick()
	assert_eq(_said, [] as Array[String], "no player in the world yet: nothing")
	b.center = func() -> Vector3: return Vector3(0, 10, 0)
	b.tick()
	assert_true(AnimalBookRules.knows(_p.wonder, &"horse"))
	assert_false(AnimalBookRules.knows(_p.wonder, &"penguin"), "too far to meet")
	assert_eq(_said, ["New in your Animal Book: Horse!"] as Array[String])
	b.tick()
	assert_eq(_said.size(), 1, "once")


func test_food_from_the_hand_marks_an_animal_fed() -> void:
	var b := _director()
	b.note_fed(&"goat")
	assert_eq(AnimalBookRules.flags(_p.wonder, &"goat"), WonderData.MET | WonderData.FED)
	assert_eq(_said.back(), "New in your Animal Book: Goat!")
	var n := _said.size()
	b.note_fed(&"goat")
	assert_eq(_said.size(), n, "nothing new, nothing said")


func test_counted_events_fill_the_books() -> void:
	_director()
	Progress.event(&"animal_tamed/fox")
	assert_eq(AnimalBookRules.flags(_p.wonder, &"fox"), WonderData.MET | WonderData.FRIEND, "a pet friend")
	assert_has(_ids(), "first_pet", "and a memory")
	Progress.event(&"buddy_woken")
	Progress.event(&"buddy_woken")
	assert_eq(_ids().count("first_buddy"), 1, "a moment once")
	Progress.event(&"boss_beaten/golem")
	assert_has(_ids(), "boss_golem")
	assert_eq(_book.entries[0].date, "2026-09-25")
	assert_has(_said, "New memory: We beat the Stone Golem!")


func test_nothing_counts_outside_a_world() -> void:
	_director()
	Progress.end()
	Progress.event(&"buddy_woken")
	assert_false(_ids().has("first_buddy"), "menus and tests never add memories")


func test_levels_five_and_ten_are_memories() -> void:
	var b := _director()
	b._on_level(4)
	b._on_level(5)
	assert_eq(_ids(), ["level_5"] as Array[String])


func test_a_new_universe_is_explored_and_remembered_once() -> void:
	_director(3)
	assert_eq(_p.wonder.universes, [3] as Array[int])
	assert_has(_ids(), "universe_3")
	_director(3)
	assert_eq(_ids().count("universe_3"), 1)
	_director(1)
	assert_false(_ids().has("universe_1"), "home is no memory")
	assert_eq(_p.wonder.universes, [1, 3] as Array[int], "but the Hub Tree grows a crown for it")


func test_the_first_night_got_through_is_a_memory() -> void:
	var b := _director(1, false)
	b.nights = true
	b.start()
	_time = 0.9 if DayCycle.is_night(0.9) else 0.0
	assert_true(DayCycle.is_night(_time), "a night time for the test")
	b._watch_night()
	_time = DayCycle.NOON
	b._watch_night()
	assert_has(_ids(), "first_night")


func test_a_knocked_out_night_is_no_memory() -> void:
	var b := _director(1, false)
	b.nights = true
	b.peer_id = 7
	b.start()
	_time = 0.9 if DayCycle.is_night(0.9) else 0.0
	b._watch_night()
	b._on_knockout(7, true)
	_time = DayCycle.NOON
	b._watch_night()
	assert_false(_ids().has("first_night"))


func test_a_sandbox_night_is_no_memory() -> void:
	var b := _director(1, false)
	b.nights = false
	b.start()
	_time = 0.9 if DayCycle.is_night(0.9) else 0.0
	b._watch_night()
	_time = DayCycle.NOON
	b._watch_night()
	assert_false(_ids().has("first_night"))


func test_a_finished_page_gives_its_reward_once() -> void:
	for kind in SecretRules.KINDS:
		_p.secret_book[String(kind)] = 1
	_director()
	assert_true(AvatarUnlocks.is_owned("wings.fairy", _p.cosmetics), "the Fairy Wings")
	assert_eq(_banners.size(), 1)
	assert_string_contains(_banners[0], "Fairy Wings")
	assert_has(_ids(), "page_secrets")
	assert_eq(_saves, 1, "the reward is saved")
	_director()
	assert_eq(_banners.size(), 1, "once")


func test_the_last_secret_of_a_page_rewards_at_once() -> void:
	for kind in SecretRules.KINDS.slice(1):
		_p.secret_book[String(kind)] = 1
	_director()
	assert_eq(_banners.size(), 0)
	_p.record_secret(SecretRules.KINDS[0])
	Progress.event(StringName("secret_found/" + String(SecretRules.KINDS[0])))
	assert_eq(_banners.size(), 1)
	assert_eq(_p.wonder.pages, [BookPages.SECRETS] as Array[String])


func test_a_photo_soon_after_goes_with_the_newest_moment() -> void:
	var b := _director()
	Progress.event(&"buddy_woken")
	_clock += 30
	var img := Image.create_empty(640, 360, false, Image.FORMAT_RGB8)
	img.fill(Color.SKY_BLUE)
	b.note_photo(img.save_png_to_buffer())
	b.finish_photo()
	assert_eq(_book.photo_of(&"first_buddy"), "first_buddy.png")
	var small := Image.load_from_file(DIR.path_join("first_buddy.png"))
	assert_eq(small.get_width(), BooksDirector.THUMB_WIDTH, "a small copy")
	assert_eq(small.get_height(), 144)
	_clock += MemoryRules.PHOTO_WINDOW + 60
	b.note_photo(img.save_png_to_buffer())
	b.finish_photo()
	assert_eq(_book.entries.filter(func(e: Dictionary) -> bool: return e.photo != "").size(), 1, "a late photo stays a photo")


func test_the_owners_showcase_goes_to_the_shelves_and_the_tree() -> void:
	_d.achievements.append_array(["first_buddy", "golem"])
	_d.record(&"boss_beaten/golem")
	var b := _director(1, false)
	b.shelves = TrophyShelves.new()
	add_child_autofree(b.shelves)
	b.tree = HubTree.new()
	add_child_autofree(b.tree)
	b.start()
	assert_eq(b.shelves.badges, ["first_buddy", "golem"] as Array[String])
	assert_eq(b.tree.state.b, ["golem"])
	assert_eq(b.tree.state.u, [1])


func test_a_guest_shows_the_hosts_showcase_cleaned() -> void:
	var b := _director(1, false)
	b.is_owner = false
	b.shelves = TrophyShelves.new()
	add_child_autofree(b.shelves)
	b.start()
	Session._rpc_books_showcase({"badges": ["golem", "nonsense", "golem", 5], "tree": {"u": [1, 2], "b": ["cake"], "p": []}})
	assert_eq(b.shelves.badges, ["golem"] as Array[String], "the host's, cleaned")
	assert_eq(b.showcase().tree.u, [1, 2])
