class_name BookPages
extends RefCounted
## Secret Book page rewards (M3 Task 21b; research C4): a page of the Secret Book is done when every kind on it
## was found — the M2 secrets (SecretRules.KINDS), the treasure hunt (TreasurePlaces.KINDS), the keepsakes (every
## quest story done, QuestRules.CHAINS). A done page gives a fixed reward once: its avatar item
## (AvatarUnlocks.earn with the page's event), its sticker in the sticker book, and a golden star on the Hub Tree
## (WonderData.pages). Nothing random, nothing to buy; the reward says "you explored everything here".

const SECRETS := "secrets"
const TREASURE := "treasure"
const KEEPSAKES := "keepsakes"

const PAGES: Array[Dictionary] = [
	{"id": SECRETS, "earn": AvatarCatalog.EARN_SECRET_PAGE, "sticker": "page_secrets", "picture": &"chest",
		"words": "You found every secret on page 1!"},
	{"id": TREASURE, "earn": AvatarCatalog.EARN_TREASURE_PAGE, "sticker": "page_treasure", "picture": &"map",
		"words": "You found every treasure on the Treasure Hunt page!"},
	{"id": KEEPSAKES, "earn": AvatarCatalog.EARN_KEEPSAKE_PAGE, "sticker": "page_keepsakes", "picture": &"scroll",
		"words": "Every story's keepsake is on your shelf!"},
]


static func ids() -> Array[String]:
	var out: Array[String] = []
	for p in PAGES:
		out.append(str(p.id))
	return out


static func is_page(id: String) -> bool:
	return ids().has(id)


static func page(id: String) -> Dictionary:
	for p in PAGES:
		if p.id == id:
			return p
	return {}


## Every page's sticker (ProgressData.is_sticker knows them).
static func stickers() -> Array[String]:
	var out: Array[String] = []
	for p in PAGES:
		out.append(str(p.sticker))
	return out


## Vector2i(kinds found, kinds on the page).
static func progress_of(id: String, profile: ProfileData, progress: ProgressData) -> Vector2i:
	match id:
		SECRETS:
			return _found(SecretRules.KINDS, profile)
		TREASURE:
			return _found(TreasurePlaces.KINDS, profile)
		KEEPSAKES:
			var n := 0
			for c: Dictionary in QuestRules.CHAINS:
				if QuestRules.is_done(progress, c.id):
					n += 1
			return Vector2i(n, QuestRules.CHAINS.size())
	return Vector2i.ZERO


static func _found(kinds: Array[StringName], profile: ProfileData) -> Vector2i:
	var n := 0
	for kind in kinds:
		if int(profile.secret_book.get(String(kind), 0)) > 0:
			n += 1
	return Vector2i(n, kinds.size())


static func complete(id: String, profile: ProfileData, progress: ProgressData) -> bool:
	var p := progress_of(id, profile, progress)
	return p.y > 0 and p.x >= p.y


## Gives the reward of every page done and not rewarded yet, each once: [{page, items (the avatar items that
## came), words, picture}]. The caller saves.
static func claim(profile: ProfileData, progress: ProgressData, wonder: WonderData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in PAGES:
		var id := str(p.id)
		if wonder.pages.has(id) or not complete(id, profile, progress):
			continue
		wonder.pages.append(id)
		var items := AvatarUnlocks.earn(profile, p.earn)
		progress.add_sticker(str(p.sticker))
		out.append({"page": id, "items": items, "words": p.words, "picture": p.picture})
	return out


## "You found every secret on page 1! You got the Fairy Wings!"
static func reward_words(got: Dictionary) -> String:
	var words := Lang.t(str(got.get("words", "")))
	var items: Array = got.get("items", [])
	if not items.is_empty():
		words = "%s %s" % [words, Lang.t("You got the %s!") % Lang.t(AvatarCatalog.display_name(str(items[0])))]
	return words
