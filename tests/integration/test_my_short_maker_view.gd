extends GutTest
## MAKE MY SHORT in the Theater's SHORTS tab: a MY SHORTS filter with a big MAKE A SHORT button; the maker's five steps
## with a few taps (a kind, the pieces, the words, the look, SAVE); quick phrases and typed words through the filter;
## the Short kept in the profile, playing in MY SHORTS with its heart, LEARN IT where it fits, CHANGE and DELETE; at
## most 20; Back and Esc go a step back; nothing talks to a network while making.

class FakeVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)


var _voice: ReadAloud.Voice
var _fake: FakeVoice
var _saves := 0
var _t := 1_800_000_000
var _root := ""
var profile: ProfileData
var _added: Array[String] = []


func before_each() -> void:
	_voice = ReadAloud.voice
	_fake = FakeVoice.new()
	ReadAloud.voice = _fake
	_saves = 0
	profile = ProfileData.new()
	profile.username = "BlueFox42"
	profile.school.grade = 4
	_root = "user://test_my_maker_%d" % OS.get_process_id()
	MyShortAlbum.use(_root, PackedStringArray())
	for i in 3:
		MyShortAlbum.keep_png_now(_png(Color(0.2 + 0.2 * i, 0.5, 0.8)), "p_20261001_10000%d.jpg" % i)
	MyStampBook.use(MyStampBook.new(), "user://test_my_maker_stamps_%d.json" % OS.get_process_id())
	_added.clear()


func after_each() -> void:
	ReadAloud.voice = _voice
	MyShortAlbum.forget()
	MyShortAlbum.use(MyShortAlbum.ROOT)
	MyStampBook.use(null)
	ShortLibrary.clear_cache()
	for sub in ["photos", "builds"]:
		var d := _root.path_join(sub)
		if DirAccess.dir_exists_absolute(d):
			for f in DirAccess.get_files_at(d):
				DirAccess.remove_absolute(d.path_join(f))
			DirAccess.remove_absolute(d)
	DirAccess.remove_absolute(_root)
	var bus := AudioServer.get_bus_index(ShortsView.MUSIC_BUS)
	if bus >= 0:
		AudioServer.set_bus_mute(bus, false)


func _png(c: Color) -> PackedByteArray:
	var img := Image.create(1280, 720, false, Image.FORMAT_RGB8)
	img.fill(c)
	return img.save_png_to_buffer()


func _view() -> ShortsView:
	var v := ShortsView.new()
	v.profile = profile
	v.save_profile = func() -> void: _saves += 1
	v.clock = func() -> int:
		_t += 1
		return _t
	add_child_autofree(v)
	await wait_process_frames(1)
	v.open()
	await wait_process_frames(2)
	return v


func _press(b: BaseButton) -> void:
	assert_true(b.is_visible_in_tree(), "%s shows" % b.name)
	assert_false(b.disabled, "%s can be tapped" % b.name)
	b.pressed.emit()


func _in(m: MyShortMakerView, name: String) -> BaseButton:
	var n := m.find_child(name, true, false)
	assert_not_null(n, name)
	return n as BaseButton


func _mine(v: ShortsView) -> void:
	_press(v.filter_buttons[ShortFeed.MINE])
	await wait_process_frames(1)


func test_my_shorts_has_a_big_make_a_short_button() -> void:
	var v := await _view()
	assert_eq(ShortFeed.FILTERS, [ShortFeed.HAND, ShortFeed.LESSONS, ShortFeed.LIKED, ShortFeed.MINE] as Array[StringName])
	assert_eq(v.filter_buttons[ShortFeed.MINE].text, "MY SHORTS")
	await _mine(v)
	assert_eq(v.feed.size(), 0)
	assert_true(v.make_big.is_visible_in_tree(), "big in the player while there is none")
	assert_true(v.make_button.is_visible_in_tree(), "and above the list")
	assert_eq(v.empty_label.text, ShortsView.EMPTY_MINE)
	assert_false(v.change_button.is_visible_in_tree() and not v.change_button.disabled, "nothing to change yet")
	var font: Font = (v.filter_buttons[ShortFeed.MINE] as Button).get_theme_font(&"font")
	for f: StringName in ShortFeed.FILTERS:
		var b: Button = v.filter_buttons[f]
		var w: float = font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size(&"font_size")).x
		assert_lte(w + 36.0, b.size.x, "%s fits its chip" % b.text)


func test_a_child_makes_how_i_built_it_in_a_few_taps() -> void:
	var v := await _view()
	await _mine(v)
	_press(v.make_big)
	var m := v.maker
	assert_true(m.is_open())
	assert_false(v.window.visible, "the feed rests under the maker")
	assert_eq(m.step, MyShortMakerView.KIND)
	_press(_in(m, "Kind_built"))
	assert_eq(m.step, MyShortMakerView.PICK)
	assert_true(m.next_button.disabled, "two photos first")
	_press(_in(m, "Photo_0"))
	_press(_in(m, "Photo_1"))
	assert_eq(m.recipe.photos, ["p_20261001_100002.jpg", "p_20261001_100001.jpg"], "newest first, in the order tapped")
	await wait_process_frames(2)
	assert_true(m.preview.is_built(), "the Short shows on the right as it is made")
	_press(m.next_button)
	assert_eq(m.step, MyShortMakerView.WORDS)
	_press(_in(m, "Slot_body_0"))
	var phrase: String = MyShortRules.PHOTO_PHRASES[1]
	m.choose_words(phrase)
	assert_eq(m.recipe.captions[0], phrase)
	assert_true(_fake.said.has(phrase), "a quick phrase is read aloud: no reading needed")
	_press(m.next_button)
	assert_eq(m.step, MyShortMakerView.LOOK)
	_press(_in(m, "Backdrop_grass"))
	_press(_in(m, "Music_spring"))
	_press(_in(m, "Voice_off"))
	_press(m.next_button)
	assert_eq(m.step, MyShortMakerView.SAVE)
	await wait_process_frames(3)
	assert_true(m.preview.playing, "the preview plays")
	assert_eq(ShortCheck.problems(m.preview.short), [] as Array[String])
	var saves := _saves
	_press(m.next_button)   # SAVE
	assert_false(m.is_open())
	assert_eq(profile.my_shorts.count(), 1)
	assert_gt(_saves, saves, "kept in the profile at once")
	var r := profile.my_shorts.recipe("mine:1")
	assert_eq(r.backdrop, "grass")
	assert_eq(r.music, "spring")
	assert_eq(r.voice, false)
	await wait_process_frames(2)
	assert_eq(v.filter, ShortFeed.MINE)
	assert_eq(v.feed.size(), 1)
	assert_true(v.window.visible)
	assert_true(v.player().playing, "the new Short plays")
	assert_eq(v.topic_label.text, MyShortRules.TOPIC_TITLE)
	assert_true(v.learn_button.disabled, "nothing to learn from a build of one's own")
	v.toggle_like()
	assert_true(profile.shorts.is_liked("mine:1"), "hearts work the same")
	_press(v.filter_buttons[ShortFeed.LIKED])
	assert_eq(v.feed.size(), 1, "and it waits in LIKED")


func test_typed_words_go_through_the_filter() -> void:
	var v := await _view()
	v.open_maker()
	var m := v.maker
	m.choose_template(MyShortRules.BUILT)
	m.toggle_photo(0)
	m.toggle_photo(1)
	m.next()
	assert_eq(m.step, MyShortMakerView.WORDS)
	m.choose_slot("body:1")
	_press(_in(m, "TypeOwn"))
	assert_true(m.type_field.is_inside_tree())
	assert_true(m.type_field.has_focus())
	assert_true(InputMap.action_get_events(&"jump").is_empty(), "typing never moves the player")
	assert_false(m.type_words("this is shit"))
	assert_eq(m.note.text, MyShortRules.message("blocked_word"))
	assert_false(m.type_words("My name is Sam"))
	assert_false(m.type_words("Made by BlueFox42"), "the child's username")
	assert_false(m.type_words("call me on 555 123 4567"))
	assert_false(m.type_words("Привет"))
	assert_true(m.type_words("I hid a secret door behind the waterfall"))
	assert_eq(m.recipe.captions[1], "I hid a secret door behind the waterfall")
	m.type_field.text = "My first tower"
	m.choose_slot("title")
	m.start_typing()
	m.type_field.text = "My first tower"
	m.type_field.text_submitted.emit(m.type_field.text)
	assert_eq(m.recipe.title, "My first tower")
	assert_false(m.type_field.is_inside_tree(), "the typing closes")
	assert_false(InputMap.action_get_events(&"jump").is_empty(), "the game keys are back")
	assert_true(m.can_type("title"))
	assert_false(m.can_type("ending"), "the ending is a question to pick")


func test_three_facts_about_a_wonder_links_learn_it() -> void:
	var v := await _view()
	v.open_maker()
	var m := v.maker
	_press(_in(m, "Kind_facts"))
	_press(_in(m, "Subject_wonder"))
	_press(_in(m, "Thing_pyramid"))
	assert_eq(m.recipe.subject, {"kind": "wonder", "id": "pyramid"})
	m.next()
	m.choose_slot("body:0")
	var facts := MyShortFacts.facts("wonder", "pyramid")
	m.choose_words(facts[2])
	assert_eq(m.recipe.facts, [2, 1, 0], "picked again elsewhere: the two swap")
	assert_false(m.can_type("body:0"), "facts are the game's own")
	m.next()
	m.next()
	m.next()
	assert_eq(profile.my_shorts.count(), 1)
	await wait_process_frames(2)
	assert_false(v.learn_button.disabled)
	watch_signals(v)
	v.learn()
	assert_signal_emitted_with_parameters(v, "learn_requested", [{"star_map": true}])


func test_step_by_step_with_one_of_my_stamps() -> void:
	var blocks := {}
	for y in 4:
		for x in 3:
			blocks[Vector3i(x, y, 0)] = BlockIds.PLANKS if y < 3 else BlockIds.RED
	MyStampBook.current().add(blocks)
	var v := await _view()
	v.open_maker()
	var m := v.maker
	m.choose_template(MyShortRules.STEPS)
	_press(_in(m, "Build_0"))
	var file := str(m.recipe.build.file)
	assert_true(FileAccess.file_exists(MyShortAlbum.build_path(file)), "a copy: the stamp's slot may change later")
	assert_eq(m.recipe.build.layers, 4)
	assert_eq(m.slots(), ["title", "body:0", "body:1", "body:2", "ending"] as Array[String])
	m.next()
	m.next()
	m.next()
	m.next()
	assert_eq(profile.my_shorts.files(), [file] as Array[String])
	assert_eq(profile.my_shorts.recipe("mine:1").build, {"kind": "stamp", "file": file, "layers": 4})


func test_at_most_twenty() -> void:
	for i in MyShortRules.MAX_SHORTS:
		profile.my_shorts.add({"template": "facts", "subject": {"kind": "planet", "id": "mars"}}, i)
	var v := await _view()
	await _mine(v)
	_press(v.make_button)
	var m := v.maker
	assert_true(m.is_open())
	assert_eq(m.step_label.text, "MY SHORTS is full")
	assert_false(m.next_button.visible)
	assert_eq(profile.my_shorts.count(), MyShortRules.MAX_SHORTS)
	m.back()
	assert_false(m.is_open())


func test_change_and_delete_my_short() -> void:
	profile.my_shorts.add({"template": "facts", "subject": {"kind": "planet", "id": "mars"}}, 1)
	profile.my_shorts.add({"template": "facts", "subject": {"kind": "animal", "id": "penguin"}}, 2)
	var v := await _view()
	await _mine(v)
	assert_eq(v.feed.size(), 2)
	assert_eq(v.current_entry().id, "mine:2", "the newest first")
	_press(v.change_button)
	var m := v.maker
	assert_eq(m.step, MyShortMakerView.PICK, "changing starts at its pieces")
	m.next()
	m.choose_slot("title")
	m.choose_words("All about Penguin")
	m.next()
	m.next()
	m.next()
	assert_eq(profile.my_shorts.count(), 2, "changed, not added")
	assert_eq(profile.my_shorts.recipe("mine:2").title, "All about Penguin")
	await wait_process_frames(2)
	assert_eq(v.title_label.text, "All about Penguin")
	profile.shorts.like("mine:2", 5)
	_press(v.delete_button)
	assert_eq(v.delete_button.text, "SURE?")
	assert_eq(profile.my_shorts.count(), 2, "one tap is not enough")
	_press(v.delete_button)
	assert_eq(profile.my_shorts.count(), 1)
	assert_false(profile.shorts.liked.has("mine:2"), "its heart goes too")
	assert_eq(v.feed.size(), 1)
	assert_eq(v.current_entry().id, "mine:1")


func test_back_goes_a_step_back_then_closes() -> void:
	var v := await _view()
	v.open_maker()
	var m := v.maker
	m.choose_template(MyShortRules.FACTS)
	m.choose_subject("planet", "venus")
	m.next()
	assert_eq(m.step, MyShortMakerView.WORDS)
	assert_true(v.back_if_making())
	assert_eq(m.step, MyShortMakerView.PICK)
	assert_true(v.back_if_making())
	assert_eq(m.step, MyShortMakerView.KIND)
	assert_true(v.back_if_making())
	assert_false(m.is_open(), "the first step's back closes it")
	assert_true(v.window.visible, "the feed is back")
	assert_false(v.back_if_making(), "Back goes on to the Theater")
	assert_eq(profile.my_shorts.count(), 0, "nothing kept without SAVE")


func test_nothing_talks_to_a_network_while_making() -> void:
	get_tree().node_added.connect(_on_added)
	var peer := multiplayer.multiplayer_peer
	var v := await _view()
	v.open_maker()
	var m := v.maker
	m.choose_template(MyShortRules.BUILT)
	m.toggle_photo(0)
	m.toggle_photo(2)
	m.next()
	m.start_typing()
	m.type_words("A tower by the sea")
	m.next()
	m.choose_music("ode_to_joy")
	m.next()
	await wait_process_frames(5)
	m.next()
	await wait_process_frames(5)
	get_tree().node_added.disconnect(_on_added)
	assert_eq(_added, [] as Array[String], "no HTTP request, no peer, no web call")
	assert_eq(multiplayer.multiplayer_peer, peer)
	assert_eq(profile.my_shorts.count(), 1)
	assert_false(ProfileBackup.to_backup(profile).contains("A tower by the sea"), "never in the server's copy")


func _on_added(n: Node) -> void:
	if n is HTTPRequest or n is MultiplayerSpawner or n is MultiplayerSynchronizer:
		_added.append(n.get_class())


func _buttons_fit(root: Control, box: Rect2, what: String, avoid: Control = null) -> void:
	var buttons: Array = root.find_children("*", "BaseButton", true, false).filter(
		func(b: Node) -> bool: return (b as Control).is_visible_in_tree())
	assert_gte(buttons.size(), 2, what)
	var rects := {}
	for b: BaseButton in buttons:
		var r := b.get_global_rect()   # what shows: a scrolled list's buttons are cut at its edges
		var n := b.get_parent()
		while n != null and n != root:
			if n is ScrollContainer:
				var clip := (n as Control).get_global_rect()
				r = r.intersection(clip) if r.intersects(clip) else Rect2()
			n = n.get_parent()
		rects[b] = r
		if r.size.x <= 0.5 or r.size.y <= 0.5:
			continue
		assert_true(box.grow(0.5).encloses(r), "%s: %s inside" % [what, b.name])
		if avoid != null:
			assert_false(r.intersects(avoid.get_global_rect()), "%s: %s beside the Short" % [what, b.name])
		assert_gte(b.size.y, 40.0, "%s: %s big enough for a finger" % [what, b.name])
	for i in buttons.size():
		for j in range(i + 1, buttons.size()):
			var a: BaseButton = buttons[i]
			var c: BaseButton = buttons[j]
			if a.is_ancestor_of(c) or c.is_ancestor_of(a):
				continue
			var ra: Rect2 = rects[a]
			var rc: Rect2 = rects[c]
			if ra.size.x <= 1.0 or ra.size.y <= 1.0 or rc.size.x <= 1.0 or rc.size.y <= 1.0:
				continue
			assert_false(ra.grow(-0.5).intersects(rc.grow(-0.5)),
				"%s: %s and %s overlap" % [what, a.name, c.name])


func test_my_shorts_buttons_fit_a_phone_and_never_overlap() -> void:
	profile.my_shorts.add({"template": "facts", "subject": {"kind": "planet", "id": "mars"}}, 1)
	var v := await _view()
	await _mine(v)
	await wait_process_frames(2)
	_buttons_fit(v, Rect2(v.global_position, ShortsView.SIZE), "MY SHORTS", v.window)
	v.open_maker()
	var m := v.maker
	var box := Rect2(m.global_position, MyShortMakerView.SIZE)
	await wait_process_frames(2)
	_buttons_fit(m, box, "KIND")
	m.choose_template(MyShortRules.BUILT)
	await wait_process_frames(2)
	_buttons_fit(m, box, "PICK photos")
	m.toggle_photo(0)
	m.toggle_photo(1)
	m.next()
	await wait_process_frames(2)
	_buttons_fit(m, box, "WORDS")
	m.start_typing()
	await wait_process_frames(2)
	_buttons_fit(m, box, "TYPING")
	m.next()
	await wait_process_frames(2)
	_buttons_fit(m, box, "LOOK")
	m.next()
	await wait_process_frames(2)
	_buttons_fit(m, box, "SAVE")
	for i in 4:
		m.back()
	m.choose_template(MyShortRules.FACTS)
	await wait_process_frames(2)
	_buttons_fit(m, box, "PICK things")
	m.back()
	m.choose_template(MyShortRules.STEPS)
	await wait_process_frames(2)
	_buttons_fit(m, box, "PICK builds")


func test_making_is_cheap_per_frame() -> void:
	var v := await _view()
	v.open_maker()
	var m := v.maker
	m.choose_template(MyShortRules.BUILT)
	m.toggle_photo(0)
	m.toggle_photo(1)
	m.toggle_photo(2)
	var worst := 0
	for i in 12:
		m.recipe.backdrop = MyShortRules.BACKDROPS[i % MyShortRules.BACKDROPS.size()]
		m._dirty = true
		var t0 := Time.get_ticks_usec()
		m._process(0.016)
		worst = maxi(worst, Time.get_ticks_usec() - t0)
	gut.p("MY_SHORT_MAKER rebuild worst %.2f ms" % (worst / 1000.0))
	assert_lt(worst, 25_000, "a change rebuilds the preview in a few ms (a phone: a few times more)")
