class_name BooksDirector
extends Node
## Books and memories in a world (M3 Task 21b; spec §16's M3 core set): one per game (node `Books` in the sandbox),
## for this game's own player. It fills the books as the child plays:
## - the Animal Book (AnimalBookRules): once a second, animals within MEET_DISTANCE are met; the counted events
##   "pet_fed/<kind>" and "animal_tamed/<kind>" (Progress.counted), and food given from the hand (`note_fed`), mark
##   them fed or a pet;
## - the Memory Book (MemoryRules, MemoryBook on this device): moments from counted events and level-ups, a new
##   universe reached, the first Survivor night got through without a knock-out; a photo taken soon after goes with
##   the newest moment (a small copy made on a worker thread);
## - Secret Book pages done: their fixed reward, once (BookPages).
## It also shows the world owner's showcase: the badges on trophy shelves (TrophyShelves) and the Hub Tree by the
## stone circle (HubTree). The host (and solo) shows its own and sends it to every guest (Session section "M3 Task
## 21b"); a guest shows the host's. Decisions once a second; nothing per frame but timers.

const TICK := 1.0
## A photo's copy in the Memory Book is this wide (16:9 below it).
const THUMB_WIDTH := 256

signal said(text: String)
signal bannered(text: String)

## () -> Vector3: this game's player's feet (INF while it isn't in the world).
var center: Callable = func() -> Vector3: return Vector3.INF
## This game's player's peer id (its knock-outs spoil the night).
var peer_id := 1
## [species, position] of the world's animals (the sandbox's Animals node).
var animals: Callable = func() -> Array: return []
## The sky's time of day (DayCycle), for the first night; unset: no night watch.
var time_of_day: Callable
## Survivor: the first night counts.
var nights := false
## Playing a world of this universe explores it (not Monster Wave's arena).
var explores := true
var universe := 1
var profile: Callable = func() -> ProfileData: return Profile.data
var save_profile: Callable = func() -> void: Profile.save()
var progress: Callable = func() -> ProgressData: return Progress.data()
var memories: Callable = func() -> MemoryBook: return MemoryBook.current()
var save_memories: Callable = func() -> void: MemoryBook.save_current()
var memory_dir: Callable = func() -> String: return MemoryBook.current_path().get_base_dir()
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())
var date: Callable = func() -> String: return MemoryRules.today(Time.get_date_dict_from_system())
## This game is the world's owner (the host, or solo): it shows and sends its own showcase.
var is_owner := true

## The trophy shelves and the Hub Tree (every game).
var shelves: TrophyShelves
var tree: HubTree

var _t := 0.0
var _was_night := false
var _night_seen := false
var _knocked := false
var _host_showcase := {}           # a guest's copy of the host's {badges, tree}
var _thumb_task := -1
var _thumb_for: StringName = &""
var _started := false


## Starts watching (the world, the player and the Progress bus are ready): the book catches up with earlier play,
## this universe is explored, pages already done give their reward.
func start() -> void:
	_started = true
	Progress.counted.connect(_on_counted)
	Progress.leveled_up.connect(_on_level)
	Progress.badge_unlocked.connect(_on_badge)
	Session.knockout_received.connect(_on_knockout)
	Session.books_showcase_received.connect(_on_showcase)
	if is_owner:
		Session.client_ready.connect(_send_showcase)
	var p: ProfileData = profile.call()
	AnimalBookRules.catch_up(p.wonder, progress.call(), p)
	SavingRules.tidy(p.wonder, p)
	if explores and p.wonder.explore(universe):
		remember(StringName("universe_%d" % universe))
		share_showcase()
	claim_pages()
	if time_of_day.is_valid():
		_was_night = DayCycle.is_night(float(time_of_day.call()))
	show_showcase()


func _exit_tree() -> void:
	if not _started:
		return
	for pair: Array in [[Progress.counted, _on_counted], [Progress.leveled_up, _on_level],
			[Progress.badge_unlocked, _on_badge], [Session.knockout_received, _on_knockout],
			[Session.books_showcase_received, _on_showcase], [Session.client_ready, _send_showcase]]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])


func _process(delta: float) -> void:
	_t += delta
	if _t >= TICK:
		_t = 0.0
		tick()
	if _thumb_task >= 0 and WorkerThreadPool.is_task_completed(_thumb_task):
		_thumb_done()


## Once a second: animals met, the night watched.
func tick() -> void:
	var at: Vector3 = center.call()
	if not at.is_finite():
		return
	var p: ProfileData = profile.call()
	var met := AnimalBookRules.newly_met(p.wonder, animals.call(), at)
	if not met.is_empty():
		var names: Array[String] = []
		for sp in met:
			names.append(AnimalBookRules.name_of(sp))
		said.emit(tr("New in your Animal Book: %s!") % ", ".join(PackedStringArray(names)))
	_watch_night()


## Survivor: a night the child got through (on the spot when it began, never knocked out) is the first night.
func _watch_night() -> void:
	if not nights or not time_of_day.is_valid():
		return
	var night := DayCycle.is_night(float(time_of_day.call()))
	if night and not _was_night:
		_night_seen = true
		_knocked = false
	elif _was_night and not night:
		if _night_seen and not _knocked:
			remember(MemoryRules.NIGHT)
		_night_seen = false
	_was_night = night


func _on_knockout(who: int, _at_home: bool) -> void:
	if who == peer_id:
		_knocked = true


## Food from the child's hand reached an animal of kind `species` (BlockInteractor.animal_fed).
func note_fed(species: StringName) -> void:
	var p: ProfileData = profile.call()
	var knew := AnimalBookRules.knows(p.wonder, species)
	if AnimalBookRules.record(p.wonder, species, WonderData.FED) and not knew:
		said.emit(tr("New in your Animal Book: %s!") % AnimalBookRules.name_of(species))


func _on_counted(kind: StringName, _amount: int) -> void:
	var p: ProfileData = profile.call()
	var detail := StringName(String(kind).get_slice("/", 1)) if String(kind).contains("/") else &""
	var knew := AnimalBookRules.knows(p.wonder, detail)
	var sp := AnimalBookRules.from_event(p.wonder, kind)   # fed or a pet (the pet's own words come from PetDirector)
	if sp != &"" and not knew:
		said.emit(tr("New in your Animal Book: %s!") % AnimalBookRules.name_of(sp))
	for id in MemoryRules.for_event(kind):
		remember(id)
	var family := LevelRules.family(kind)
	if family == LevelRules.SECRET or family == LevelRules.QUEST_DONE:
		claim_pages()
	if family == LevelRules.BOSS:
		share_showcase()   # a fruit on the Hub Tree


func _on_level(level: int) -> void:
	remember(StringName("level_%d" % level))


func _on_badge(_badge_id: StringName) -> void:
	share_showcase()   # a trophy on the shelves


## Keeps moment `id` in the Memory Book (once); true when it is new.
func remember(id: StringName) -> bool:
	var book: MemoryBook = memories.call()
	if not book.add(id, date.call(), clock.call()):
		return false
	save_memories.call()
	said.emit(tr("New memory: %s") % MemoryRules.words_of(id))
	return true


## Every Secret Book page done and not rewarded yet gives its reward (once): the banner, a memory, the Hub Tree's
## star (the showcase).
func claim_pages() -> void:
	var p: ProfileData = profile.call()
	var got := BookPages.claim(p, progress.call(), p.wonder)
	for g in got:
		bannered.emit(BookPages.reward_words(g))
		remember(StringName("page_" + str(g.page)))
	if not got.is_empty():
		save_profile.call()
		share_showcase()


# --- Photos: the child's photo goes with the newest moment -------------------------------------------------

## Photo mode saved a photo (its PNG): a small copy goes with the newest memory still without a photo, taken within
## MemoryRules.PHOTO_WINDOW of it. The copy is made on a worker thread.
func note_photo(png: PackedByteArray) -> void:
	if png.is_empty() or _thumb_task >= 0:
		return
	var book: MemoryBook = memories.call()
	var id := MemoryRules.photo_target(book.entries, clock.call())
	if id == &"":
		return
	var dir: String = memory_dir.call()
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(String(id) + ".png")
	_thumb_for = id
	_thumb_task = WorkerThreadPool.add_task(func() -> void: BooksDirector.make_thumb(png, path))


## A small copy of a photo (THUMB_WIDTH wide) written to `path` (a worker thread's job).
static func make_thumb(png: PackedByteArray, path: String) -> void:
	var img := Image.new()
	if img.load_png_from_buffer(png) != OK or img.is_empty():
		return
	var w := mini(THUMB_WIDTH, img.get_width())
	img.resize(w, maxi(roundi(float(img.get_height()) * w / img.get_width()), 1), Image.INTERPOLATE_BILINEAR)
	img.save_png(path)


func _thumb_done() -> void:
	WorkerThreadPool.wait_for_task_completion(_thumb_task)
	_thumb_task = -1
	var file := String(_thumb_for) + ".png"
	var book: MemoryBook = memories.call()
	if FileAccess.file_exists(String(memory_dir.call()).path_join(file)) and book.attach_photo(_thumb_for, file):
		save_memories.call()
		said.emit("Your photo is in your Memory Book!")
	_thumb_for = &""


## Waits for a photo's copy (tests; the game polls it every frame).
func finish_photo() -> void:
	if _thumb_task >= 0:
		_thumb_done()

# --- The world owner's showcase: the trophy shelves' badges and the Hub Tree ------------------------------------

## The world owner's {badges, tree} (this game's own on the host and solo).
func showcase() -> Dictionary:
	if not is_owner:
		return _host_showcase
	var p: ProfileData = profile.call()
	var d: ProgressData = progress.call()
	return {"badges": d.achievements.duplicate(), "tree": HubTreeRules.state(p.wonder, d)}


## A showcase from the network, cleaned: known badges (at most one each) and a clean tree.
static func clean_showcase(v: Variant) -> Dictionary:
	var src: Dictionary = v if v is Dictionary else {}
	var badges: Array[String] = []
	var b: Variant = src.get("badges")
	if b is Array:
		for id: Variant in b:
			if (id is String or id is StringName) and not AchievementRules.badge(StringName(id)).is_empty() \
					and not badges.has(str(id)):
				badges.append(str(id))
	return {"badges": badges, "tree": HubTreeRules.clean(src.get("tree"))}


## The owner's showcase changed: show it here and send it to every guest.
func share_showcase() -> void:
	show_showcase()
	if is_owner:
		Session.books_share_showcase(showcase())


func _send_showcase(peer_id: int) -> void:
	Session.books_send_showcase(peer_id, showcase())


func _on_showcase(data: Dictionary) -> void:
	if is_owner:
		return
	_host_showcase = data
	show_showcase()


## The shelves and the tree show the owner's showcase.
func show_showcase() -> void:
	var s := showcase()
	var badges: Array[String] = []
	badges.assign(s.get("badges", []))
	if shelves:
		shelves.badges = badges
		shelves.refresh()
	if tree:
		tree.set_state(s.get("tree", HubTreeRules.clean({})))
