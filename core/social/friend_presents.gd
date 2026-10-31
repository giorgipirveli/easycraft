class_name FriendPresents
extends RefCounted
## Owner #81, #82 (brief docs/superpowers/plans/2026-09-30-daily-mission-brief.md item 3; the world game plan §1
## "Giving"): presents a friend opens in the game. Only a kind travels (server module 0.2.18, SocialRules.PRESENT_KINDS:
## nothing personal); the server holds a present for its friend, once, one a day to each friend and SENDS_PER_DAY in
## all; one can wait on the sender's invite code for the next new friend (LINK_GIFTS_MAX). Opening gives the thing here:
## - rocket_part: a Fuel Tank (every rocket needs tanks) for the Sandbox's rockets and, in the backpack, the next Survivor
##   world's bag (owner #98: RocketParts.grant, like the Gold Shop's parts);
## - seeds: Wheat and Flowers into the backpack for the next Survivor world (the colony dome's garden comes later);
## - buddy_egg: it hatches a secret buddy shape not found yet (BuddyRecipes: build it and wake it with the Magic Wand),
##   or pet treats once every shape is found;
## - map_piece: a treasure map piece kept for the prospecting quests (SocialData.map_pieces, a hook).
## THANK YOU sends the sender THANK_GOLD (the server pays, a few times a day).

const KINDS: Array[String] = ["rocket_part", "seeds", "buddy_egg", "map_piece"]
## The server's numbers (SocialRules): the game only says them.
const THANK_GOLD := 10
const SENDS_PER_DAY := 5
const LINK_GIFTS_MAX := 3

const ROCKET_PART_BLOCK := BlockIds.FUEL_TANK
const SEEDS := 4
const TREATS := 3

const NAMES := {"rocket_part": "a rocket part", "seeds": "seeds", "buddy_egg": "a buddy egg",
	"map_piece": "a treasure map piece"}
const TITLES := {"rocket_part": "ROCKET PART", "seeds": "SEEDS", "buddy_egg": "BUDDY EGG", "map_piece": "MAP PIECE"}
const WHAT := {"rocket_part": "A Fuel Tank for their rocket.", "seeds": "Wheat and flowers to plant.",
	"buddy_egg": "It hatches a secret buddy shape.", "map_piece": "A piece of a treasure map."}
const COLORS := {"rocket_part": Color("d9463b"), "seeds": Color("2fae4e"), "buddy_egg": Color("7b4bd6"),
	"map_piece": Color("c9901a")}

const ERRORS := {
	"sent_today": "You sent this friend a present today. Tomorrow you can send another!",
	"too_many_today": "That's all the presents for today. Tomorrow you can send more!",
	"inbox_full": "Your friend has lots of presents to open. Try again another day!",
	"too_many_waiting": "Three presents already wait for new friends. That's plenty!",
	"not_friends": "Presents go to friends.",
	"not_found": "That present is gone.",
	"already_thanked": "You said thank you already. That was kind!",
	"not_opened": "Open it first!",
	"not_claimed": "Pick your online name first.",
}


static func name_of(kind: String) -> String:
	return str(NAMES.get(kind, "a present"))


static func title_of(kind: String) -> String:
	return str(TITLES.get(kind, "PRESENT"))


static func what_it_is(kind: String) -> String:
	return str(WHAT.get(kind, ""))


static func color_of(kind: String) -> Color:
	return COLORS.get(kind, UiKit.BLUE)


static func error_words(code: String) -> String:
	return str(ERRORS.get(code, OnlineRules.message(code)))


## Opens a present of `kind` into the profile (the caller saves); what it gave, in a child's words ("" for no such kind).
static func open(profile: ProfileData, kind: String) -> String:
	match kind:
		"rocket_part":   # owner #98 (bug 2): the Sandbox's rockets and the next Survivor world's bag, like the Gold Shop's
			RocketParts.grant(profile, ROCKET_PART_BLOCK, 1)
			return "A %s for your rocket! %s" % [BlockIds.display_name(ROCKET_PART_BLOCK), RocketParts.GRANT_WORDS]
		"seeds":
			for id: int in [BlockIds.WHEAT, BlockIds.FLOWERS]:
				profile.backpack[id] = mini(int(profile.backpack.get(id, 0)) + SEEDS, Inventory.MAX_COUNT)
			return "%d Wheat and %d Flowers wait in your backpack for your next Survivor world." % [SEEDS, SEEDS]
		"buddy_egg":
			for r: Dictionary in BuddyRecipes.RECIPES:
				if profile.buddy_magic.add_found(r.id):
					return "It hatched a secret buddy shape: the %s! Build it and wake it with the Magic Wand." % r.title
			profile.backpack[ItemIds.TREAT_BISCUIT] = mini(int(profile.backpack.get(ItemIds.TREAT_BISCUIT, 0)) + TREATS,
				Inventory.MAX_COUNT)
			return "It hatched %d pet treats! They wait in your backpack." % TREATS
		"map_piece":
			profile.social.map_pieces = mini(profile.social.map_pieces + 1, 9999)
			return "A treasure map piece! Keep it: Tilly's prospecting quests use map pieces."
	return ""
