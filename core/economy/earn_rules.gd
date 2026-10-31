class_name EarnRules
extends RefCounted
## Owner #79 (spec §25.1): how Survivor gold is earned by learning, in one table. The School pays for answers right the
## first time (a few gold, a daily cap so it never becomes a grind) and 100 once for a unit mastered; the Science Lab's
## first star of each experiment pays once; the worlds' secrets and puzzles already pay once each (a treasure chest, a
## puzzle temple's vault, the Wanderer's riddle, a golden animal: LootRules, unchanged); a friend who joins and learns
## pays both (the server decides: InviteRules). Rows "by": "hook" are numbers waiting for their callers (the first
## secret of each kind: SecretDirector, a one-line call). A wonder's fact quiz pays (owner #78, spec §24:
## WondersPassportRules.answer, a question right the first time; the planets' quizzes may use the row later). Never
## for time, for opening a lesson, for reading or for coming back (spec §22.2, the fair-fun rules). Survivor's own ways (waves,
## monsters, bosses, treasure, the farm, selling) stay as they are.
##
## Tuning (spec §25.1, §25.5): a day of learning (the answers' cap, a unit mastered, a Lab star) is about 275 gold.
## Owner #98 (SpendRules.GUIDE): Mission Control's Moon rocket about a good day of learning, Mars's a little more.
##
## Gold earned outside a world goes into the profile (the caller saves it); the wallet sync takes it to the server.

const ANSWER_GOLD := 5            # a School answer right the first time
const ANSWER_DAY_CAP := 150       # answer gold in one day (30 answers: five rounds)
const UNIT_GOLD := MasteryRules.UNIT_GOLD   # a unit mastered the first time (spec §22.2 ruling 8)
const LAB_STAR_GOLD := 25         # a Lab experiment's first star (spec §23)
const SECRET_KIND_GOLD := 50      # the first secret of each kind in the Secret Book (spec §12.16)
const FACT_QUIZ_GOLD := 10        # a wonder's fact quiz, each question once, right the first time (owner #78)
## Spec §26 (prospecting): a prospecting quest finished the first time (its map, clues, problems and quiz, and the walk);
## each later deposit found with its quest again (the next one is farther on), up to a cap a day (ProspectRewards).
## The quests' exercises also pay ANSWER_GOLD like the School's, inside its cap.
const PROSPECT_QUEST_GOLD := 100
const PROSPECT_FIND_GOLD := 20
const PROSPECT_FIND_DAY_CAP := 100
const DAILY_STAR_GOLD := 10       # owner #85: a star in the Daily Mission (answer right the first time), once a day (DailyData)
## Owner #78 (spec §21e): an invention's "try it" moment done (the kite flown, the balloon risen, …), once per invention.
const INVENT_TRY_GOLD := 20
## Owner #112 (Life, spec §27): a Life skill (an Experience on a track) practised to its end the first time, like a
## lesson mastered (LifePassport.GOLD).
const LIFE_SKILL_GOLD := UNIT_GOLD
## Owner #115 (Success S3): a customer served in My Business's shop while the child plays it, up to a day's cap
## (SuccessShop.GOLD_PER_CUSTOMER and DAY_CAP are these; test_success_shop.gd keeps them equal).
const SHOP_CUSTOMER_GOLD := 5
const SHOP_DAY_CAP := 50

## Every way to earn gold by learning, for the Gold Shop's "How to earn" list and the tests. `by`: who pays it.
const TABLE: Array[Dictionary] = [
	{"id": "answer", "gold": ANSWER_GOLD, "when": "An answer right the first time in the School",
		"limit": "up to %d a day" % ANSWER_DAY_CAP, "by": "game"},
	{"id": "unit", "gold": UNIT_GOLD, "when": "A School unit mastered", "limit": "once per unit", "by": "game"},
	{"id": "lab_star", "gold": LAB_STAR_GOLD, "when": "A new star in your Lab Book", "limit": "once per experiment",
		"by": "game"},
	{"id": "secret", "gold": LootRules.GOLDEN_GOLD.x, "when": "A treasure, a puzzle temple's vault or the Wanderer's riddle",
		"limit": "once each, in Survivor", "by": "world"},
	{"id": "secret_kind", "gold": SECRET_KIND_GOLD, "when": "The first secret of each kind you find",
		"limit": "once per kind", "by": "hook"},
	{"id": "fact_quiz", "gold": FACT_QUIZ_GOLD, "when": "A wonder's quiz question right the first time",
		"limit": "once each", "by": "game"},   # owner #78: the Wonders Passport
	{"id": "prospect_quest", "gold": PROSPECT_QUEST_GOLD, "when": "A prospecting quest with Gemma the geologist",
		"limit": "once per quest", "by": "game"},   # spec §26
	{"id": "prospect_find", "gold": PROSPECT_FIND_GOLD, "when": "Another gold vein, oil dome or salt flat found",
		"limit": "up to %d a day" % PROSPECT_FIND_DAY_CAP, "by": "game"},   # spec §26
	{"id": "daily", "gold": DAILY_STAR_GOLD, "when": "A star in today's Daily Mission", "limit": "up to 5 a day",
		"by": "game"},
	{"id": "invent_try", "gold": INVENT_TRY_GOLD, "when": "An invention's TRY IT done (the kite, the balloon, the plane …)",
		"limit": "once per invention", "by": "game"},   # owner #78, spec §21e
	{"id": "life_skill", "gold": LIFE_SKILL_GOLD, "when": "A Life skill practised to the end (Fire Escape, Safe Streets …)",
		"limit": "once per skill and track", "by": "game"},   # owner #112: Life L1's follow-up
	{"id": "shop_customer", "gold": SHOP_CUSTOMER_GOLD, "when": "A customer served in your shop (My Business)",
		"limit": "up to %d a day, while you play it" % SHOP_DAY_CAP, "by": "game"},   # owner #115: Success S3
	{"id": "friend_welcome", "gold": InviteRules.WELCOME_GOLD, "when": "You joined with a friend's code",
		"limit": "once", "by": "server"},
	{"id": "friend_learned", "gold": InviteRules.INVITER_GOLD, "when": "A friend you invited learned a whole unit",
		"limit": "once per friend", "by": "server"},
	{"id": "learned_with_guide", "gold": InviteRules.LEARNER_GOLD, "when": "You learned your first unit with your guide",
		"limit": "once", "by": "server"},
	{"id": "tree_learned", "gold": InviteRules.TREE_GOLD, "when": "A friend of your friend learned", "limit": "once each",
		"by": "server"},
	{"id": "friend_landed", "gold": InviteRules.LANDED_GOLD, "when": "A friend you invited landed on the Moon",
		"limit": "once per friend", "by": "server"},
]

const DAY_FULL_WORDS := "That's all the answer gold for today. Your stars and badges still count!"


## Adds `amount` Survivor gold to the profile (never past the wallet's top); what was added.
static func credit(profile: ProfileData, amount: int) -> int:
	if amount <= 0:
		return 0
	var wallet := Wallet.new(profile.survivor_gold)
	var before := wallet.balance
	wallet.add(amount)
	profile.survivor_gold = wallet.balance
	return wallet.balance - before


## Gold still to earn from answers on `today`.
static func answer_left(profile: ProfileData, today: int) -> int:
	var d := int(profile.earn_today.get("d", -1))
	if today < d:
		return 0   # the clock went back: the day already counted is never paid again
	var had := int(profile.earn_today.get("g", 0)) if d == today else 0
	return maxi(ANSWER_DAY_CAP - had, 0)


## An answer right the first time on `today`: pays ANSWER_GOLD while the day's cap has room; what was paid.
static func answer_gold(profile: ProfileData, today: int) -> int:
	var pay := mini(answer_left(profile, today), ANSWER_GOLD)
	if pay <= 0:
		return 0
	var had := int(profile.earn_today.get("g", 0)) if int(profile.earn_today.get("d", -1)) == today else 0
	profile.earn_today = {"d": today, "g": had + pay}
	return credit(profile, pay)


## Owner #85: the Daily Mission of `day` finished: DAILY_STAR_GOLD for each star, once a day (never for a day before the
## last one paid: a clock turned back pays nothing again). What was paid; the caller saves.
static func daily_gold(profile: ProfileData, day: int) -> int:
	if not profile.daily.is_done(day) or day <= profile.daily.paid:
		return 0
	profile.daily.paid = day
	return credit(profile, DailyMission.stars_in(profile.daily.stars_of(day)) * DAILY_STAR_GOLD)


static func daily_words(gold: int) -> String:
	return "+%d gold for today's stars!" % gold


## The Secret Book's count of a kind after a find: its first pays SECRET_KIND_GOLD.
static func secret_gold(count_after: int) -> int:
	return SECRET_KIND_GOLD if count_after == 1 else 0


## The profile's day record from saved data ({} when broken).
static func clean_today(v: Variant) -> Dictionary:
	if not v is Dictionary:
		return {}
	var d: Variant = (v as Dictionary).get("d")
	var g: Variant = (v as Dictionary).get("g")
	if typeof(d) not in [TYPE_INT, TYPE_FLOAT] or typeof(g) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(d)) \
			or not is_finite(float(g)) or float(d) < 0.0 or float(d) > 1e7 or float(g) < 0.0 or float(g) > ANSWER_DAY_CAP:
		return {}
	return {"d": int(d), "g": int(g)}


static func answer_words(gold: int) -> String:
	return "+%d gold: right the first time!" % gold


static func round_words(gold: int) -> String:
	return "+%d gold for answers right the first time!" % gold


static func lab_words() -> String:
	return "+%d gold!" % LAB_STAR_GOLD


static func secret_words() -> String:
	return "+%d gold: your first one of these!" % SECRET_KIND_GOLD
