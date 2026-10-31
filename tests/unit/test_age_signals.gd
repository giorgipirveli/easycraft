extends GutTest
## Google Play Age Signals (M4 Wave 2, agent F; spec §17.2): the store's age range mapped to our
## bands, only ever making things stricter, and an adapter that does nothing where there is no signal
## (desktop, tests, an APK without the plugin) and never blocks play.


class FakePlugin:
	extends Object
	signal age_signals_result(json: String)
	var asked := 0
	var answer := ""

	func requestAgeSignals() -> void:
		asked += 1
		age_signals_result.emit(answer)


func test_the_store_range_maps_to_our_bands() -> void:
	assert_eq(AgeSignalsRules.band_from({"age_lower": 0, "age_upper": 12}), AgeBand.UNDER_13)
	assert_eq(AgeSignalsRules.band_from({"age_lower": 13, "age_upper": 15}), AgeBand.TEEN_PLUS)
	assert_eq(AgeSignalsRules.band_from({"age_lower": 16, "age_upper": 17}), AgeBand.TEEN_PLUS)
	assert_eq(AgeSignalsRules.band_from({"age_lower": 18, "age_upper": null}), AgeBand.TEEN_PLUS)
	assert_eq(AgeSignalsRules.band_from({"age_lower": 11.0, "age_upper": 12.0}), AgeBand.UNDER_13, "JSON numbers")
	assert_eq(AgeSignalsRules.band_from({"age_lower": 0, "age_upper": 14}), AgeBand.UNDER_13,
		"a range with ages under 13 in it counts as under 13 (custom Play Console ranges)")


func test_no_signal_is_no_band() -> void:
	for r: Dictionary in [{}, {"age_lower": null, "age_upper": null}, {"age_lower": "twelve"}, {"age_lower": -1},
			{"age_lower": NAN}, {"status": "NOT_SHARED"}]:
		assert_eq(AgeSignalsRules.band_from(r), &"", str(r))


func test_the_signal_only_ever_makes_things_stricter() -> void:
	assert_eq(AgeSignalsRules.stricter(AgeBand.TEEN_PLUS, AgeBand.UNDER_13), AgeBand.UNDER_13)
	assert_eq(AgeSignalsRules.stricter(AgeBand.UNDER_13, AgeBand.TEEN_PLUS), AgeBand.UNDER_13)
	assert_eq(AgeSignalsRules.stricter(AgeBand.TEEN_PLUS, &""), AgeBand.TEEN_PLUS, "no signal changes nothing")
	assert_eq(AgeSignalsRules.stricter(&"", AgeBand.TEEN_PLUS), AgeBand.TEEN_PLUS)
	assert_eq(AgeSignalsRules.stricter(&"", &""), &"")


func test_the_plugins_json_answer() -> void:
	assert_eq(AgeSignalsRules.band_from_json('{"age_lower": 0, "age_upper": 12, "source": "TIER_B"}'), AgeBand.UNDER_13)
	assert_eq(AgeSignalsRules.band_from_json("not json"), &"")
	assert_eq(AgeSignalsRules.band_from_json(""), &"")


func test_desktop_and_tests_have_no_signal_and_never_wait() -> void:
	var a := AgeSignals.for_platform()
	assert_false(a.is_available(), "no Age Signals off Android")
	var got: Array = []
	a.answered.connect(func(band: StringName) -> void: got.append(band))
	a.request()
	assert_eq(got, [&""], "answers at once: nothing")
	assert_eq(a.band, &"")


func test_the_android_adapter_uses_the_plugin_when_the_apk_has_it() -> void:
	var plugin := FakePlugin.new()
	plugin.answer = '{"age_lower": 0, "age_upper": 12}'
	var a := AndroidAgeSignals.new(plugin)
	assert_true(a.is_available())
	var got: Array = []
	a.answered.connect(func(band: StringName) -> void: got.append(band))
	a.request()
	assert_eq(plugin.asked, 1)
	assert_eq(got, [AgeBand.UNDER_13])
	assert_eq(a.band, AgeBand.UNDER_13)
	plugin.free()


func test_the_android_adapter_without_the_plugin_is_a_no_op() -> void:
	var a := AndroidAgeSignals.new(null)
	assert_false(a.is_available())
	var got: Array = []
	a.answered.connect(func(band: StringName) -> void: got.append(band))
	a.request()
	assert_eq(got, [&""])
