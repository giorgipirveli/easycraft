extends GutTest
## Owner feedback #36 (spec §14.6b): the Storybook costume pack. Public-domain storybook heroes drawn our own way
## from the books (never a film's look), and our own genre costumes. A costume is a whole look made of catalogue
## parts (the CLOTHES cuts, hair, hats, faces, colours, outfits, capes, trails); earning it gives everything in it.
## Every costume is earned by playing in a fixed way (a boss, a story, a level, a title, a badge, a Secret Book
## find, a code): never random, never for gold or money, never locked to BOY or GIRL.

const C := preload("res://core/avatar/avatar_catalog.gd")

## The brief's costumes: the storybook heroes, then our own genre costumes.
const STORYBOOK: Array[StringName] = [&"alice", &"hatter", &"pinocchio", &"robin_hood", &"king_arthur", &"merlin",
	&"sherlock", &"dorothy", &"tin_woodman", &"aladdin", &"hercules", &"nemo"]
const GENRE: Array[StringName] = [&"wizard", &"cube_hero", &"astronaut", &"ninja", &"pirate", &"dragon", &"knight",
	&"fairy", &"robot"]
## The Cube Hero's secret code (codes live only as salted hashes in shipped files; tests and docs may hold them).
const HERO_CODE := "cubehero2026"
## Names that are someone else's (films, TV, comics, games, toys) and must never be shown to a player. Checked as
## whole words, ignoring case, in every string literal of the shipped code.
const BANNED: Array[String] = ["Marvel", "DC Comics", "Hogwarts", "Harry Potter", "Gryffindor", "Slytherin",
	"Hufflepuff", "Ravenclaw", "Dumbledore", "Voldemort", "Quidditch", "Muggle", "Spider-Man", "Spiderman", "Batman",
	"Superman", "Superhero", "Super Hero", "Superheroes", "Avengers", "Iron Man", "Captain America", "Hulk",
	"Wonder Woman", "Elsa", "Olaf", "Frozen II", "Mickey", "Minnie", "Disney", "Pixar", "Finding Nemo", "Buzz Lightyear",
	"Simba", "Moana", "Peter Pan", "Tinker Bell", "Tinkerbell", "Captain Hook", "Winnie", "Pooh", "Shrek", "Pokemon",
	"Pokémon", "Pikachu", "Super Mario", "Star Wars", "Jedi", "Yoda", "Darth", "Gandalf", "Hobbit", "Paw Patrol", "Peppa",
	"Bluey", "Barbie", "Lego", "Minecraft", "Roblox", "Fortnite", "Ruby Slippers", "Jack Sparrow", "Dreamworks",
	"Toothless", "Hello Kitty"]
## The shipped code's folders (tests/, docs/, tools/ and addons/ never ship to a child's screen).
const SHIPPED: Array[String] = ["res://autoloads", "res://core", "res://data", "res://entities", "res://scenes",
	"res://ui", "res://world"]
## Shipped files whose strings are never shown: the name filter's word lists (typed names are checked against them).
const NEVER_SHOWN: Array[String] = ["res://core/validation/username_rules.gd", "res://core/net/common_passwords.gd"]


func _profile() -> ProfileData:
	return ProfileData.new()


## Makes `p` meet a way of earning (the same data a child's play writes).
func _meet(p: ProfileData, event: StringName) -> void:
	var s := String(event)
	var kind := s.get_slice("/", 0)
	var arg := s.substr(kind.length() + 1)
	match kind:
		"level":
			p.progress.xp = LevelRules.xp_to_reach(int(arg))
		"title":
			p.progress.style_xp[arg] = LevelRules.TITLE_XP
		"quest":
			p.progress.quests.done.append(arg)
		"badge":
			p.progress.achievements.append(arg)
		"count":
			p.progress.record(StringName(arg))
		"secret":
			p.record_secret(StringName(arg))
		"secret_page":
			for k: StringName in SecretRules.KINDS:
				p.record_secret(k)
		_:
			AvatarUnlocks.earn(p, event)   # a boss: the event itself


# --- The pack ------------------------------------------------------------------------------------------------------

func test_the_pack_has_every_costume_of_the_brief() -> void:
	for id: StringName in STORYBOOK + GENRE:
		assert_true(CostumeRules.COSTUMES.has(id), "%s is in the pack" % id)
		assert_true(C.ITEMS.has(CostumeRules.item_id(id)), "%s is an avatar item" % id)
		assert_has(CostumeRules.ORDER, id, "%s shows in the COSTUME tab" % id)
	assert_eq(CostumeRules.ORDER.size(), CostumeRules.COSTUMES.size(), "each costume once")
	assert_eq(CostumeRules.item_id(&"alice"), "costume.alice")
	assert_eq(C.display_name("costume.alice"), "Alice")
	assert_eq(C.display_name("costume.tin_woodman"), "Tin Woodman", "the book's name, not a film's")


func test_every_costume_is_made_of_real_catalogue_parts() -> void:
	for id: StringName in CostumeRules.ORDER:
		var recipe: Dictionary = CostumeRules.COSTUMES[id]
		assert_false(recipe.has("skin"), "%s keeps the child's own skin tone" % id)
		assert_false(recipe.has("base"), "%s is never a boy or girl look" % id)
		for field: String in recipe:
			assert_true(AvatarLook.FIELDS.has(field), "%s: %s is a look field" % [id, field])
			assert_true(C.has_item(AvatarLook.FIELDS[field], recipe[field]), "%s: %s %s exists" % [id, field, recipe[field]])
		var special := CostumeRules.parts(id).filter(func(p: String) -> bool: return not C.is_free(p))
		assert_gt(special.size(), 0, "%s gives something that isn't free" % id)


func test_every_costume_is_earned_by_play_never_random_and_never_sold() -> void:
	for id: StringName in CostumeRules.ORDER:
		var item_id := CostumeRules.item_id(id)
		var item: Dictionary = C.ITEMS[item_id]
		assert_has([C.BOSS, C.ACHIEVEMENT, C.SECRET, C.CODE], item.kind, "%s is earned by playing" % id)
		assert_eq(C.price(item_id), 0, "%s has no gold price" % id)
		assert_ne(AvatarUnlocks.lock_reason(item_id), "", "%s says how to earn it" % id)
		var p := _profile()
		p.survivor_gold = 999_999
		assert_eq(AvatarUnlocks.buy(p, item_id), AvatarUnlocks.NOT_FOR_SALE, "gold never buys %s" % id)
		assert_eq(p.survivor_gold, 999_999)
		for part in CostumeRules.parts(id):
			assert_ne(C.ITEMS.get(part, {}).get("kind", C.FREE), C.PACK, "%s: %s is never a grown-up's pack item" % [id, part])
	for product in ShopCatalog.ids():
		for sold in ShopCatalog.items_of(product):
			assert_false(sold.begins_with("costume."), "%s never sells a costume" % product)
			assert_ne(C.ITEMS[sold].kind, C.IN_COSTUME, "%s never sells a costume part" % product)


func test_costume_only_parts_come_only_with_their_costume() -> void:
	var n := 0
	for part: String in C.ITEMS:
		var item: Dictionary = C.ITEMS[part]
		if item.kind != C.IN_COSTUME:
			continue
		n += 1
		var costume := StringName(str(item.get("costume", "")))
		assert_true(CostumeRules.COSTUMES.has(costume), "%s names its costume" % part)
		assert_has(CostumeRules.parts(costume), part, "%s is worn by %s" % [part, costume])
		var p := _profile()
		p.survivor_gold = 999_999
		assert_false(AvatarUnlocks.is_owned(part, p.cosmetics), "%s starts locked" % part)
		assert_eq(AvatarUnlocks.buy(p, part), AvatarUnlocks.NOT_FOR_SALE, "%s can't be bought" % part)
		assert_string_contains(AvatarUnlocks.lock_reason(part), C.display_name(CostumeRules.item_id(costume)),
			"%s says which costume brings it" % part)
		AvatarUnlocks.grant(p, CostumeRules.item_id(costume))
		assert_true(AvatarUnlocks.is_owned(part, p.cosmetics), "%s comes with %s" % [part, costume])
	assert_gte(n, 20, "the pack's own new parts")


func test_earning_a_costume_gives_everything_in_it() -> void:
	for id: StringName in CostumeRules.ORDER:
		var p := _profile()
		assert_false(CostumeRules.is_complete(id, p.cosmetics), "%s starts locked" % id)
		assert_true(AvatarUnlocks.grant(p, CostumeRules.item_id(id)))
		assert_true(CostumeRules.is_complete(id, p.cosmetics), "%s is ready to wear" % id)
		for part in CostumeRules.parts(id):
			assert_true(AvatarUnlocks.is_owned(part, p.cosmetics), "%s gives %s" % [id, part])
		var look := CostumeRules.wear(id)
		assert_true(AvatarUnlocks.wearable(look, p.cosmetics).equals(look), "%s: DONE keeps all of it" % id)
		assert_false(AvatarUnlocks.wearable(look, []).equals(look), "%s: without it, DONE takes it off" % id)


func test_a_costume_bought_piece_by_piece_is_complete_too() -> void:
	var p := _profile()
	for part in CostumeRules.parts(&"knight"):
		if not C.is_free(part):
			AvatarUnlocks.grant(p, part)   # the knight outfit and the royal cape, bought with gold
	assert_true(CostumeRules.is_complete(&"knight", p.cosmetics), "everything in it is owned")


func test_wearing_a_costume_keeps_the_childs_own_things() -> void:
	var own := AvatarLook.new()
	own.skin = &"brown"
	own.base = C.GIRL
	own.emotes[3] = &"dance_star"
	for id: StringName in CostumeRules.ORDER:
		var look := CostumeRules.wear(id, own)
		assert_eq(look.skin, &"brown", "%s keeps the skin tone" % id)
		assert_eq(look.base, C.GIRL, "%s keeps the first choice" % id)
		assert_eq(look.emotes, own.emotes, "%s keeps the dance wheel" % id)
		for field: String in CostumeRules.COSTUMES[id]:
			assert_eq(String(look.get(field)), str(CostumeRules.COSTUMES[id][field]), "%s wears its %s" % [id, field])
	assert_eq(own.skin, &"brown", "the child's look is not changed")


func test_no_costume_is_locked_to_boy_or_girl() -> void:
	for b: StringName in C.BASES:
		var own := AvatarLook.start(b)
		for id: StringName in CostumeRules.ORDER:
			var look := CostumeRules.wear(id, own)
			assert_eq(look.base, b, "%s after %s: the first choice stays only a starting point" % [id, b])
			var p := _profile()
			p.avatar = own
			AvatarUnlocks.grant(p, CostumeRules.item_id(id))
			assert_true(AvatarUnlocks.wearable(look, p.cosmetics).equals(look), "%s is for everyone (%s)" % [id, b])

# --- Fixed unlocks ------------------------------------------------------------------------------------------------

func test_every_costume_has_one_fixed_way_in_the_free_game() -> void:
	for id: StringName in CostumeRules.ORDER:
		var way := CostumeRules.way(id)
		assert_ne(way, &"", "%s has a way" % id)
		var s := String(way)
		var kind := s.get_slice("/", 0)
		var arg := s.substr(kind.length() + 1)
		match kind:
			"level":
				assert_between(int(arg), 2, 10, "%s: a level every child reaches" % id)
			"title":
				assert_true(LevelRules.STYLES.has(StringName(arg)), "%s: a real title" % id)
			"quest":
				assert_false(QuestRules.chain(StringName(arg)).is_empty(), "%s: a real story" % id)
				assert_lte(QuestRules.universe_of(StringName(arg)), 2, "%s: a story of a free universe" % id)
			"badge":
				assert_false(AchievementRules.badge(StringName(arg)).is_empty(), "%s: a real badge" % id)
			"count":
				assert_true(LevelRules.is_kind(StringName(arg)), "%s: a counted thing" % id)
			"secret":
				assert_has(TreasurePlaces.KINDS_BY_STYLE[TreasurePlaces.MEADOWS], StringName(arg), "%s: found in Green Meadows" % id)
			"secret_page", "code":
				pass
			_:
				assert_has([C.EARN_GOLEM, C.EARN_SERPENT], way, "%s: a boss of a free universe" % id)


func test_a_new_profile_has_no_costume_and_syncing_changes_nothing() -> void:
	var p := _profile()
	assert_eq(CostumeRules.sync(p), [] as Array[String])
	assert_eq(p.cosmetics, [] as Array[String])
	for id: StringName in CostumeRules.ORDER:
		assert_false(CostumeRules.is_complete(id, p.cosmetics), id)


func test_playing_the_way_earns_the_costume_once() -> void:
	for id: StringName in CostumeRules.ORDER:
		var way := CostumeRules.way(id)
		if not CostumeRules.is_derived(way):
			continue   # bosses and the code: below
		var p := _profile()
		assert_false(CostumeRules.met(p, way), "%s: not yet" % id)
		_meet(p, way)
		assert_true(CostumeRules.met(p, way), "%s: %s done" % [id, way])
		var got := CostumeRules.sync(p)
		assert_has(got, CostumeRules.item_id(id), "%s is earned" % id)
		assert_true(CostumeRules.is_complete(id, p.cosmetics))
		assert_eq(CostumeRules.sync(p), [] as Array[String], "%s: earned once" % id)


func test_the_fairy_wings_come_with_a_whole_secret_book_page() -> void:
	var p := _profile()
	for k: StringName in SecretRules.KINDS.slice(0, SecretRules.KINDS.size() - 1):
		p.record_secret(k)
	assert_eq(CostumeRules.sync(p), [] as Array[String], "one kind still missing")
	p.record_secret(SecretRules.KINDS[-1])
	var got := CostumeRules.sync(p)
	assert_has(got, "wings.fairy", "the Secret Book page's wings (M3 Task 9's hook, now earned)")
	assert_has(got, CostumeRules.item_id(&"fairy"))
	var q := _profile()
	for k: StringName in TreasurePlaces.KINDS:
		q.record_secret(k)
	assert_has(CostumeRules.sync(q), CostumeRules.item_id(&"fairy"), "the Treasure Hunt page counts too")


func test_bosses_earn_their_costumes() -> void:
	var p := _profile()
	assert_has(AvatarUnlocks.earn(p, C.EARN_GOLEM), CostumeRules.item_id(&"king_arthur"), "the sword in the stone")
	assert_has(AvatarUnlocks.earn(p, C.EARN_SERPENT), CostumeRules.item_id(&"hercules"), "the serpent")
	assert_eq(C.rarity(CostumeRules.item_id(&"hercules")), C.LEGENDARY, "a boss's costume is legendary")
	assert_string_contains(AvatarUnlocks.lock_reason(CostumeRules.item_id(&"hercules")), "Sand Serpent")
	assert_eq(CostumeRules.boss_event(&"serpent"), C.EARN_SERPENT, "the Sand Serpent's win earns it")
	assert_eq(CostumeRules.boss_event(&"cake"), C.EARN_CAKE_MONSTER, "the Cake Monster keeps its cosmic outfit")
	assert_eq(CostumeRules.boss_event(&"golem"), &"", "the Golem earns through its portal (Session.boss_apply_unlock)")
	assert_eq(CostumeRules.boss_event(&"giant"), &"", "no costume behind a universe a grown-up buys")
	assert_eq(CostumeRules.sync(_profile()), [] as Array[String], "a boss's costume never comes from counting")


func test_a_secret_code_gives_the_cube_hero_once() -> void:
	var p := _profile()
	var tries := CodeTries.new()
	var r := CodeRules.redeem(p, HERO_CODE, tries, 0)
	assert_eq(r.status, CodeRules.ACCEPTED)
	assert_eq(r.message, "Code accepted! New: Cube Hero")
	assert_true(CostumeRules.is_complete(&"cube_hero", p.cosmetics))
	assert_eq(CodeRules.redeem(p, HERO_CODE.to_upper(), tries, 1).status, CodeRules.ALREADY_USED)
	assert_eq(CostumeRules.way(&"cube_hero"), &"code")
	assert_string_contains(AvatarUnlocks.lock_reason(CostumeRules.item_id(&"cube_hero")), "code")


func test_costume_lines_are_short_and_kind() -> void:
	for id: StringName in CostumeRules.ORDER:
		var line := CostumeRules.line(id)
		assert_string_starts_with(line, C.display_name(CostumeRules.item_id(id)))
		assert_lte(line.length(), 64, "%s fits the editor's message line" % id)
		for bad: String in ["hurry", "last chance", "only today", "miss", "don't go", "buy", "pay", "$"]:
			assert_false(line.to_lower().contains(bad), "%s: no pressure words" % id)

# --- Old profiles, saving ------------------------------------------------------------------------------------------

func test_earned_costumes_are_saved_and_old_profiles_load() -> void:
	var p := _profile()
	_meet(p, CostumeRules.way(&"alice"))
	CostumeRules.sync(p)
	p.avatar = CostumeRules.wear(&"alice")
	var q := ProfileData.from_json(p.to_json())
	assert_true(CostumeRules.is_complete(&"alice", q.cosmetics), "saved")
	assert_true(q.avatar.equals(p.avatar), "the costume is still worn after loading")
	var old := ProfileData.from_json('{"version":1,"username":"Hop","age_band":"13_plus","survivor_gold":40,' +
		'"cosmetics":["hat.crown","costume.peter_pan"],"avatar":{"hat":"crown","clothes":"pinafore","shirt":"pink"}}')
	assert_eq(old.cosmetics, ["hat.crown"] as Array[String], "unknown costumes are dropped")
	assert_eq(old.avatar.hat, &"crown", "an old look loads")
	assert_eq(old.avatar.clothes, &"none", "a costume part that isn't owned is taken off")
	assert_eq(old.avatar.shirt, &"pink")


func test_a_costume_look_travels_in_the_look_code() -> void:
	for id: StringName in CostumeRules.ORDER:
		var look := CostumeRules.wear(id)
		var code := look.to_code()
		assert_lte(code.length(), AvatarLook.MAX_CODE_LENGTH)
		assert_true(AvatarLook.from_code(code).equals(look), "%s: other players see it" % id)

# --- The books, not the films; nobody else's names ----------------------------------------------------------------

func test_each_storybook_costume_names_its_public_domain_book() -> void:
	for id: StringName in STORYBOOK:
		var s: Dictionary = CostumeRules.SOURCES[id]
		assert_false(bool(s.own), "%s comes from a book or a legend" % id)
		assert_ne(str(s.work), "", "%s names its source" % id)
		assert_lte(int(s.year), 1930, "%s: published long ago (public domain in the US: 1930 and before)" % id)
		assert_lte(int(s.died), 1955, "%s: its makers died over 70 years ago (life + 70)" % id)
	for id: StringName in GENRE:
		assert_true(bool(CostumeRules.SOURCES[id].own), "%s is our own design" % id)


func test_the_book_looks_not_the_films() -> void:
	var dorothy := CostumeRules.wear(&"dorothy").resolve()
	var shoes: Color = dorothy.shoes
	assert_lt(absf(shoes.r - shoes.b), 0.08, "Dorothy's shoes are silver as in Baum's book, never ruby slippers")
	assert_gt(shoes.v, 0.6, "bright silver")
	var alice := CostumeRules.wear(&"alice")
	assert_false(alice.shirt in [&"blue", &"sky"], "Alice's dress is Tenniel's yellow, not a film's blue")
	assert_eq(alice.shirt, &"yellow")
	var fairy := CostumeRules.wear(&"fairy")
	assert_false(fairy.shirt in [&"green", &"lime", &"mint"], "our fairy is not in a famous fairy's green dress")
	var hatter := CostumeRules.wear(&"hatter")
	assert_false(hatter.hair_color in [&"red"], "our Hatter has no film's orange hair")


func test_no_player_facing_string_uses_a_banned_name() -> void:
	var texts: Array[String] = []
	for id: String in C.ITEMS:
		texts.append(C.display_name(id))
		texts.append(AvatarUnlocks.lock_reason(id))
	for id: StringName in CostumeRules.ORDER:
		texts.append(CostumeRules.line(id))
	for text in texts:
		for name in BANNED:
			assert_false(_says(text, name), "\"%s\" names %s" % [text, name])
	var hits: Array[String] = []
	for dir in SHIPPED:
		_scan(dir, hits)
	assert_eq(hits, [] as Array[String], "shipped strings naming someone else's characters")


func test_the_banned_list_catches_what_it_should() -> void:
	assert_true(_says("Be a Superhero!", "Superhero"))
	assert_true(_says("the hogwarts robe", "Hogwarts"))
	assert_true(_says("Spider-Man cape", "Spider-Man"))
	assert_false(_says("a marvelous hat", "Marvel"), "whole words only")
	assert_false(_says("Pinocchio's cap", "Pooh"))
	assert_true(_literals('var a := "x Batman y" # Hulk').has("x Batman y"))
	assert_false(_literals('var a := 1 # "Hulk"').has("Hulk"), "comments are not shown to players")


## Whether `text` has `name` as a whole word or phrase (ignoring case).
func _says(text: String, name: String) -> bool:
	var re := RegEx.new()
	re.compile("(?i)(?<![\\p{L}\\p{N}])" + _escape(name) + "(?![\\p{L}\\p{N}])")
	return re.search(text) != null


func _escape(s: String) -> String:
	var out := ""
	for ch in s:
		out += ("\\" + ch) if "\\^$.|?*+()[]{}-".contains(ch) else ch
	return out


## The string literals of a GDScript source (comments skipped).
func _literals(source: String) -> Array[String]:
	var out: Array[String] = []
	var i := 0
	var n := source.length()
	while i < n:
		var ch := source[i]
		if ch == "#":
			while i < n and source[i] != "\n":
				i += 1
			continue
		if ch == "\"" or ch == "'":
			var triple := source.substr(i, 3) == ch + ch + ch
			var close := ch + ch + ch if triple else ch
			var j := i + close.length()
			var text := ""
			while j < n and source.substr(j, close.length()) != close:
				if source[j] == "\\" and j + 1 < n:
					text += source.substr(j, 2)
					j += 2
					continue
				if not triple and source[j] == "\n":
					break
				text += source[j]
				j += 1
			out.append(text)
			i = j + close.length()
			continue
		i += 1
	return out


func _scan(path: String, hits: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub in dir.get_directories():
		if not sub.begins_with("."):
			_scan(path.path_join(sub), hits)
	for f in dir.get_files():
		var file := path.path_join(f)
		if file in NEVER_SHOWN:
			continue
		var texts: Array[String] = []
		if f.ends_with(".gd"):
			texts = _literals(FileAccess.get_file_as_string(file))
		elif f.get_extension() in ["tscn", "tres", "json", "cfg", "csv", "txt"]:
			texts = [FileAccess.get_file_as_string(file)]
		for text in texts:
			for name in BANNED:
				if _says(text, name):
					hits.append("%s: %s" % [file, name])
