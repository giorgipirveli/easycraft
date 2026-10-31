extends GutTest
## M3 Task 13: the profile keeps the hashes of the codes it redeemed (never the codes themselves).
## Parsed defensively: anything that is not a list of salted hashes is dropped.

const H1 := "8764c42a183660d928b90caff8f0be2a5b9d811dde5df56970079ea15e439208"
const H2 := "0000000000000000000000000000000000000000000000000000000000000abc"


func test_a_new_profile_has_redeemed_nothing() -> void:
	assert_eq(ProfileData.new().codes_redeemed, [] as Array[String])
	assert_eq(ProfileData.from_json("{}").codes_redeemed, [] as Array[String], "old profiles")


func test_redeemed_codes_round_trip() -> void:
	var p := ProfileData.new()
	p.codes_redeemed.append(H1)
	p.codes_redeemed.append(H2)
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.codes_redeemed, [H1, H2] as Array[String])


func test_bad_redeemed_data_is_dropped() -> void:
	for bad: String in ['"%s"' % H1, "5", "{}", "null", "true"]:
		var q := ProfileData.from_json('{"codes_redeemed": %s}' % bad)
		assert_eq(q.codes_redeemed, [] as Array[String], "not a list: %s" % bad)
	var mixed := ProfileData.from_json(JSON.stringify({"codes_redeemed": [
		H1, 7, null, ["x"], "sasa", H1.substr(1), H1 + "0", "+" + H1.substr(1), "g" + H1.substr(1), H1.to_upper(), H2]}))
	assert_eq(mixed.codes_redeemed, [H1, H2] as Array[String], "only 64-digit hex hashes, lowercased, no repeats")


func test_the_redeemed_list_is_capped() -> void:
	var many: Array[String] = []
	for i in CodeRules.MAX_REDEEMED + 40:
		many.append(("%d" % i).sha256_text())
	var q := ProfileData.from_json(JSON.stringify({"codes_redeemed": many}))
	assert_eq(q.codes_redeemed.size(), CodeRules.MAX_REDEEMED)


func test_other_fields_survive_bad_redeemed_data() -> void:
	var q := ProfileData.from_json('{"username": "Hop", "survivor_gold": 70, "codes_redeemed": "oops"}')
	assert_eq(q.username, "Hop")
	assert_eq(q.survivor_gold, 70)
