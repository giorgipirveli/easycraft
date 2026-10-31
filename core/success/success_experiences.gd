class_name SuccessExperiences
extends RefCounted
## Owner #115 (docs/design/success-skills.md §2 systems 3, 4, 6, 7; spec §27 "As built (S2)"): Success S2's four Life
## Experiences, in Life's own format (LifeExperience: steps, checks, the name-it card, Try it for real, sources), their
## data in data/success/experiences/<id>.json and their practice rooms in entities/success/:
## - goal_board: The Goal Board (GoalRoom): a goal you can check, steps, if-then plans, saving, a habit;
## - talk_deal: Talk & Deal (TalkSquare): listen and say sorry, clear words for Robo, a win-win deal, the pitch;
## - connections: The Connections Book (VillageSquare): meet, remember, help first, keep promises, introduce, mentors;
## - success_stories: Success Stories (StoryStage): the Story Theatre's true stories and "Which skill did they use?".
## Success S3 (owner #115): my_shop: My Business's shop (ShopRoom: Little's stand, Middle's shop, Big's harder days;
## SuccessShop's values); market_square: the Market Square (MarketSquareRoom: Little's swap stall, Middle's supply and
## demand, Big's honest trading and the dice lesson; SuccessMarket's values).
## Life knows them through owner #115's hooks: LifeExperience.IDS and its data path, LifeExperience.vars ("vary":
## "success"), LifeRooms.make. Each try varies a little with its seed (vars): Mo's complaint, the cake's, Lina's present.

const DIR := "res://data/success/experiences"
const IDS: Array[String] = ["goal_board", "talk_deal", "connections", "success_stories",
	"my_shop", "market_square"]   # owner #115 (S3): My Business's shop, the Market Square
const ROOMS: Array[String] = ["goal_room", "talk_square", "village", "story_stage", "shop", "market_square"]
## Mo's complaint and what saying it back sounds like (Talk & Deal, Little).
const GRIPES := [["My bread got squashed in my bag!", "Your bread got squashed. Oh no!"],
	["My loaf was too hard to cut!", "Your loaf was too hard to cut. Oh dear!"],
	["You gave me the wrong bread!", "I gave you the wrong bread. Oh no!"]]
const CAKE_GRIPES: Array[String] = ["dry", "too sweet", "squashed"]
const GIFTS: Array[String] = ["crayons", "paints", "coloured pencils"]

static var _moon_gold := -1


static func path(id: String) -> String:
	return "%s/%s.json" % [DIR, id]


static func is_success(id: String) -> bool:
	return IDS.has(id)


## The practice room for a room kind (null for one that isn't Success's).
static func room(kind: String, track: String) -> LifeRoom:
	match kind:
		"goal_room":
			return GoalRoom.new(track)
		"talk_square":
			return TalkSquare.new(track)
		"village":
			return VillageSquare.new(track)
		"story_stage":
			return StoryStage.new(track)
		"shop":   # owner #115 (S3)
			return ShopRoom.new(track)
		"market_square":
			return MarketSquareRoom.new(track)
	return null


## A try's words that vary with its seed (LifeExperience.vars merges them for "vary": "success").
static func vars(id: String, track: String, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, id, "success"])
	var gripe: Array = GRIPES[rng.randi_range(0, GRIPES.size() - 1)]
	var v := {"gripe": gripe[0], "gripe_back": gripe[1], "cake_gripe": CAKE_GRIPES[rng.randi_range(0, CAKE_GRIPES.size() - 1)],
		"gift": GIFTS[rng.randi_range(0, GIFTS.size() - 1)], "moon_gold": moon_gold()}
	match id:   # owner #115 (S3): the shop's and the market's values
		"my_shop":
			v.merge(SuccessShop.vars(track, seed), true)
		"market_square":
			v.merge(SuccessMarket.vars(track, seed), true)
	return v


## Mission Control's plan for one astronaut to the Moon, in gold (the Goal Board's rocket goal: the child's real one).
static func moon_gold() -> int:
	if _moon_gold < 0:
		_moon_gold = 0
		for m in MissionRules.MISSIONS:
			if str(m.id) == "moon":
				_moon_gold = RocketPlan.gold(m, 1)
	return _moon_gold
