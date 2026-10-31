extends GutTest
## Secret codes (spec §5.11, §14.10; M3 Task 13): normalised, only salted SHA-256 hashes ship, once
## per device profile, friendly messages, and a rate limit so mashing can't guess codes.

## The owner's first code. It lives only here: tests never ship (the game presets exclude tests/*),
## and test_the_plain_code_never_ships checks that no shipped file holds it.
const FIRST_CODE := "sasa192974"
## sha256("easycraft:codes:v1:5d3f8a61c2" + "abc"), computed outside Godot with sha256sum.
const KNOWN_VECTOR := "8764c42a183660d928b90caff8f0be2a5b9d811dde5df56970079ea15e439208"

var profile: ProfileData
var tries: CodeTries


func before_each() -> void:
	profile = ProfileData.new()
	profile.survivor_gold = 25
	tries = CodeTries.new()


func test_codes_are_trimmed_and_lowercased() -> void:
	assert_eq(CodeRules.normalize("  HeLLo2026 \n"), "hello2026")
	assert_eq(CodeRules.normalize("\tAbC 12  "), "abc 12", "only the ends are trimmed")
	assert_eq(CodeRules.normalize("   "), "")


func test_the_hash_is_salted_sha256_of_the_normalised_code() -> void:
	assert_eq(CodeRules.hash_code("abc"), KNOWN_VECTOR, "known vector (pins the salt and the algorithm)")
	assert_eq(CodeRules.hash_code("  ABC "), KNOWN_VECTOR, "normalised before hashing")
	assert_ne(CodeRules.hash_code("abc"), "abc".sha256_text(), "salted")


func test_only_hashes_ship_in_the_table() -> void:
	assert_gt(CodeRules.REWARDS.size(), 0)
	for key: Variant in CodeRules.REWARDS:
		assert_true(CodeRules.is_hash(key), "a table key is a salted hash: %s" % key)
		var reward: Dictionary = CodeRules.REWARDS[key]
		assert_true(reward.has("kind"), "every reward says its kind")


func test_the_first_code_gives_1000_survivor_gold() -> void:
	var reward: Dictionary = CodeRules.REWARDS.get(CodeRules.hash_code(FIRST_CODE), {})
	assert_eq(reward.get("kind"), CodeRules.KIND_GOLD)
	assert_eq(reward.get("amount"), 1000)


func test_the_plain_code_never_ships() -> void:
	var hits: Array[String] = []
	_scan("res://", hits)
	assert_eq(hits, [] as Array[String], "files outside tests/ and docs/ holding the plain code")


func test_a_right_code_gives_its_reward_once() -> void:
	var r := CodeRules.redeem(profile, FIRST_CODE, tries, 0)
	assert_eq(r.status, CodeRules.ACCEPTED)
	assert_eq(r.message, "Code accepted! +1,000 gold")
	assert_eq(profile.survivor_gold, 1025)
	assert_eq(profile.codes_redeemed, [CodeRules.hash_code(FIRST_CODE)] as Array[String], "the hash is kept, never the code")


func test_a_code_works_once_per_profile() -> void:
	CodeRules.redeem(profile, FIRST_CODE, tries, 0)
	var again := CodeRules.redeem(profile, "  " + FIRST_CODE.to_upper() + " ", tries, 10)
	assert_eq(again.status, CodeRules.ALREADY_USED)
	assert_eq(again.message, "You already used that code.")
	assert_eq(profile.survivor_gold, 1025, "no second payout")
	assert_eq(profile.codes_redeemed.size(), 1)
	var other := ProfileData.new()
	assert_eq(CodeRules.redeem(other, FIRST_CODE, tries, 20).status, CodeRules.ACCEPTED, "another profile may use it")


func test_an_unknown_code_changes_nothing() -> void:
	var r := CodeRules.redeem(profile, "banana", tries, 0)
	assert_eq(r.status, CodeRules.UNKNOWN)
	assert_eq(r.message, "That code doesn't work.")
	assert_eq(profile.survivor_gold, 25)
	assert_eq(profile.codes_redeemed.size(), 0)


func test_an_empty_code_is_not_a_try() -> void:
	for i in CodeTries.MAX_WRONG + 1:
		assert_eq(CodeRules.redeem(profile, "   ", tries, i).status, CodeRules.EMPTY)
	assert_false(tries.is_locked(10))


func test_five_wrong_tries_lock_the_field_for_30_seconds() -> void:
	for i in CodeTries.MAX_WRONG:
		assert_false(tries.is_locked(i), "not locked before try %d" % (i + 1))
		CodeRules.redeem(profile, "guess%d" % i, tries, i)
	assert_true(tries.is_locked(CodeTries.MAX_WRONG))
	var locked := CodeRules.redeem(profile, FIRST_CODE, tries, 1000)
	assert_eq(locked.status, CodeRules.LOCKED, "even the right code waits")
	assert_eq(locked.message, "Too many tries! Wait 30 seconds.")
	assert_eq(profile.survivor_gold, 25, "and gives nothing")
	assert_eq(tries.wait_seconds(4 + CodeTries.LOCK_MSEC - 1500), 2, "rounded up")
	assert_eq(CodeRules.redeem(profile, FIRST_CODE, tries, 4 + CodeTries.LOCK_MSEC - 500).message,
		"Too many tries! Wait 1 second.")
	assert_eq(CodeRules.redeem(profile, FIRST_CODE, tries, 4 + CodeTries.LOCK_MSEC).status, CodeRules.ACCEPTED,
		"30 s after the fifth wrong try")


func test_after_a_lock_there_are_five_new_tries() -> void:
	for i in CodeTries.MAX_WRONG:
		CodeRules.redeem(profile, "guess%d" % i, tries, 0)
	var later := CodeTries.LOCK_MSEC
	for i in CodeTries.MAX_WRONG - 1:
		CodeRules.redeem(profile, "again%d" % i, tries, later)
	assert_false(tries.is_locked(later))
	CodeRules.redeem(profile, "last", tries, later)
	assert_true(tries.is_locked(later))


func test_repeats_are_not_wrong_and_a_right_code_resets_the_count() -> void:
	CodeRules.redeem(profile, FIRST_CODE, tries, 0)
	for i in CodeTries.MAX_WRONG + 2:
		CodeRules.redeem(profile, FIRST_CODE, tries, 0)
	assert_false(tries.is_locked(0), "'already used' is not a wrong guess")
	var fresh := ProfileData.new()
	for i in CodeTries.MAX_WRONG - 1:
		CodeRules.redeem(fresh, "guess%d" % i, tries, 0)
	CodeRules.redeem(fresh, FIRST_CODE, tries, 0)
	for i in CodeTries.MAX_WRONG - 1:
		CodeRules.redeem(fresh, "more%d" % i, tries, 0)
	assert_false(tries.is_locked(0), "a right code starts the count again")


## Rewards of a kind this build can't give yet (cosmetics: M3 Task 9) are not used up.
func test_a_reward_this_build_cannot_give_is_not_used_up() -> void:
	var table := {CodeRules.hash_code("test-hat"): {"kind": CodeRules.KIND_COSMETIC, "item": &"hat_crown"}}
	var r := CodeRules.redeem(profile, "test-hat", tries, 0, table)
	assert_eq(r.status, CodeRules.UNKNOWN)
	assert_eq(profile.codes_redeemed.size(), 0, "still redeemable once the build can give it")
	assert_false(tries.is_locked(0))


func test_gold_rewards_respect_the_wallet_cap() -> void:
	profile.survivor_gold = Wallet.MAX_GOLD - 10
	CodeRules.redeem(profile, FIRST_CODE, tries, 0)
	assert_eq(profile.survivor_gold, Wallet.MAX_GOLD)


func test_a_broken_gold_reward_gives_nothing() -> void:
	var table := {CodeRules.hash_code("minus"): {"kind": CodeRules.KIND_GOLD, "amount": -500}}
	assert_eq(CodeRules.redeem(profile, "minus", tries, 0, table).status, CodeRules.UNKNOWN)
	assert_eq(profile.survivor_gold, 25)
	assert_eq(profile.codes_redeemed.size(), 0)


## The gold-double bug's leftover (module 0.2.19, docs/devlog/parts/gold-double.md): gold the phone paid by its own
## check (offline, or when the server's answer was lost) waits for the server's word: had it paid that code itself?
func test_gold_the_phone_paid_itself_waits_for_the_servers_word() -> void:
	var r := CodeRules.redeem(profile, FIRST_CODE, tries, 0)
	assert_eq(r.status, CodeRules.ACCEPTED)
	assert_eq(profile.codes_unsettled, {CodeRules.hash_code(FIRST_CODE): 1000},
		"whether the server paid it too (a lost answer) is not known yet")
	var table := {CodeRules.hash_code("test-hat"): {"kind": CodeRules.KIND_COSMETIC, "item": "hat.party"}}
	CodeRules.redeem(profile, "test-hat", tries, 0, table)
	assert_eq(profile.codes_unsettled.size(), 1, "a cosmetic moves no gold")
	var back := ProfileData.from_json(profile.to_json())
	assert_eq(back.codes_unsettled, profile.codes_unsettled, "kept on the phone")
	var bad := ProfileData.from_json('{"codes_unsettled": {"abc": 5, "%s": "x", "%s": -2, "%s": 1000.0}}' % [
		"1".repeat(64), "2".repeat(64), "3".repeat(64)])
	assert_eq(bad.codes_unsettled, {"3".repeat(64): 1000}, "only hashes with whole gold")
	assert_eq(ProfileData.from_json('{"codes_unsettled": [1]}').codes_unsettled, {})


func test_thousands_separators() -> void:
	assert_eq(CodeRules.thousands(0), "0")
	assert_eq(CodeRules.thousands(999), "999")
	assert_eq(CodeRules.thousands(1000), "1,000")
	assert_eq(CodeRules.thousands(1234567), "1,234,567")


func _scan(dir_path: String, hits: Array[String]) -> void:
	const TEXT := ["gd", "tscn", "tres", "json", "cfg", "godot", "gdshader", "csv", "txt"]
	const SKIP := ["res://tests", "res://docs", "res://addons", "res://build"]
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		var path := dir_path.path_join(sub)
		if not SKIP.has(path):
			_scan(path, hits)
	for f in dir.get_files():
		if TEXT.has(f.get_extension()):
			var path := dir_path.path_join(f)
			if FileAccess.get_file_as_string(path).to_lower().contains(FIRST_CODE):
				hits.append(path)
