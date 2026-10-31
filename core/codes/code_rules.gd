class_name CodeRules
extends RefCounted
## Secret codes (spec §5.11, §14.10; M3 Task 13). A code is normalised (trimmed, lowercased) and
## hashed with the app salt; only those hashes ship, in REWARDS. Each code works once per device
## profile (the profile keeps the hashes it redeemed); from M4 the server redeems and validates.
## Codes are redeemed from the main menu, outside a world, so the rule changes the profile directly;
## the caller saves it.

## Changing the salt changes every hash: REWARDS and every profile's codes_redeemed would no longer match.
const SALT := "easycraft:codes:v1:5d3f8a61c2"
const MAX_LEN := 32            # the code field's limit
const MAX_REDEEMED := 256      # a profile keeps at most this many redeemed hashes
const RECORD_CHUNK := 50       # hashes per redeem_code {"hashes"} call (M4 F; the server's CodeRules.MAX_RECORD)

## Reward kinds. A gold reward is {"kind": KIND_GOLD, "amount": <Survivor gold>}. KIND_COSMETIC is
## reserved for the avatar editor (M3 Task 9): {"kind": KIND_COSMETIC, "item": &"<avatar item id>"}.
const KIND_GOLD := &"gold"
const KIND_COSMETIC := &"cosmetic"

## Salted hash of a normalised code -> its reward. Add a code: hash_code("<code>") (e.g. from a
## throwaway test), never write the plain code in a shipped file (tests/test_code_rules.gd scans them).
const REWARDS := {
	# the first code (spec §5.11): 1,000 Survivor gold
	"a59f43a363322b8e2604d1c43fcb5005cf099fdf8e4230fb593e8a918ec46f0a": {"kind": KIND_GOLD, "amount": 1000},
	# owner #36: the Cube Hero costume (the Storybook pack's code way)
	"8e79f20f226bca770f874899b8857906d11b6384903e2336272dbe3f89895885": {"kind": KIND_COSMETIC, "item": "costume.cube_hero"},
}

## redeem() outcomes.
const ACCEPTED := &"accepted"
const UNKNOWN := &"unknown"
const ALREADY_USED := &"already_used"
const LOCKED := &"locked"
const EMPTY := &"empty"


static func normalize(code: String) -> String:
	return code.strip_edges().to_lower()


static func hash_code(code: String) -> String:
	return (SALT + normalize(code)).sha256_text()


## A SHA-256 hash as hash_code writes it: 64 lowercase hex digits.
static func is_hash(text: Variant) -> bool:
	if typeof(text) != TYPE_STRING or (text as String).length() != 64:
		return false
	for c in (text as String):
		if not "0123456789abcdef".contains(c):
			return false
	return true


## The profile's redeemed list from saved data: only hashes (lowercased), no repeats, capped.
static func sanitize_redeemed(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for v: Variant in value:
		if typeof(v) != TYPE_STRING:
			continue
		var h := (v as String).to_lower()
		if is_hash(h) and not out.has(h) and out.size() < MAX_REDEEMED:
			out.append(h)
	return out


## The profile's unsettled gold codes from saved data (hash -> gold, ProfileData.codes_unsettled): hashes with a
## whole amount from 1 to 1,000,000, at most MAX_REDEEMED.
static func sanitize_unsettled(value: Variant) -> Dictionary:
	var out := {}
	if typeof(value) != TYPE_DICTIONARY:
		return out
	for k: Variant in value:
		var gold: Variant = value[k]
		if typeof(k) != TYPE_STRING or not is_hash((k as String).to_lower()) or typeof(gold) not in [TYPE_INT, TYPE_FLOAT]:
			continue
		if not is_finite(float(gold)) or float(gold) != floorf(float(gold)) or float(gold) < 1.0 or float(gold) > 1_000_000.0:
			continue
		if out.size() < MAX_REDEEMED:
			out[(k as String).to_lower()] = int(gold)
	return out


## Tries a code for this profile: gives the reward and records the code's hash when it is new.
## The gold-double bug's leftover (module 0.2.19): this is the phone's own check (offline, or the server's answer was
## lost), so the gold it gives waits in profile.codes_unsettled for the server's word (OnlineService settles it).
## Returns {"status": <outcome>, "message": <for the player>, "reward": {}, "wait": <seconds locked>}.
static func redeem(profile: ProfileData, code: String, tries: CodeTries, now_msec: int, rewards: Dictionary = REWARDS) -> Dictionary:
	var result := {"status": EMPTY, "reward": {}, "wait": 0}
	var norm := normalize(code)
	if norm == "":
		pass
	elif tries.is_locked(now_msec):
		result.status = LOCKED
		result.wait = tries.wait_seconds(now_msec)
	else:
		var h := hash_code(norm)
		if not rewards.has(h):
			tries.record_wrong(now_msec)
			result.status = UNKNOWN
		elif profile.codes_redeemed.has(h):
			result.status = ALREADY_USED
		elif profile.codes_redeemed.size() >= MAX_REDEEMED or not give(profile, rewards[h]):
			result.status = UNKNOWN   # a reward this build can't give: not used up, not a wrong guess
		else:
			profile.codes_redeemed.append(h)
			if StringName(str(rewards[h].get("kind", ""))) == KIND_GOLD:
				profile.codes_unsettled[h] = int(rewards[h].amount)   # the server's word on it comes later
			tries.record_right()
			result.status = ACCEPTED
			result.reward = rewards[h]
	result.message = message(result)
	return result


## Gives a reward to the profile; false (and nothing changes) when this build can't give it.
static func give(profile: ProfileData, reward: Dictionary) -> bool:
	match StringName(str(reward.get("kind", ""))):
		KIND_GOLD:
			var amount: Variant = reward.get("amount", 0)
			if typeof(amount) != TYPE_INT or amount <= 0:
				return false
			var wallet := Wallet.new(profile.survivor_gold)
			wallet.add(amount)
			profile.survivor_gold = wallet.balance
			return true
		KIND_COSMETIC:   # an avatar item (M3 Task 9); unknown items are not given
			return AvatarUnlocks.grant(profile, str(reward.get("item", "")))
	return false


static func message(result: Dictionary) -> String:
	match result.get("status"):
		ACCEPTED:
			var reward: Dictionary = result.get("reward", {})
			if reward.get("kind") == KIND_GOLD:
				return Lang.t("Code accepted! +%s gold") % thousands(int(reward.get("amount", 0)))
			if reward.get("kind") == KIND_COSMETIC:
				return Lang.t("Code accepted! New: %s") % Lang.t(AvatarCatalog.display_name(str(reward.get("item", ""))))
			return "Code accepted!"
		ALREADY_USED:
			return "You already used that code."
		LOCKED:
			var wait := int(result.get("wait", 0))
			return Lang.t("Too many tries! Wait %d second%s.") % [wait, Lang.plural_s(wait)]
		EMPTY:
			return "Type a code first."
	return "That code doesn't work."


## 1234567 -> "1,234,567".
static func thousands(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out
