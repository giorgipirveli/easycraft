class_name AgeSignalsRules
extends RefCounted
## Google Play Age Signals mapped to our bands (M4 Wave 2, agent F; spec §17.2 "store age signals").
## The Play Age Signals API (com.google.android.play:age-signals 0.0.4) answers an age range,
## ageLower..ageUpper (inclusive; ageUpper is null for the top range; both null when the user did not
## share it or must verify first). The default ranges are 0-12, 13-15, 16-17 and 18+; custom Play
## Console minimum ages change them. A range with any age under 13 in it counts as under 13.
## The signal only ever makes things stricter: it never lifts a child's under-13 band (AgeSignals).

const MIN_TEEN_AGE := 13


## Our band for a signal {"age_lower": int or null, "age_upper": int or null, ...}; &"" = no signal.
static func band_from(result: Dictionary) -> StringName:
	var lower: Variant = result.get("age_lower")
	if typeof(lower) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(lower)) or float(lower) < 0.0:
		return &""
	return AgeBand.UNDER_13 if float(lower) < MIN_TEEN_AGE else AgeBand.TEEN_PLUS


## The plugin's answer, a JSON object with the same keys ("" or broken = no signal).
static func band_from_json(text: String) -> StringName:
	var json := JSON.new()   # not JSON.parse_string: that logs an engine error on bad text
	if text == "" or json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return &""
	return band_from(json.data)


## The stricter of two bands; &"" (unknown) never wins over a known band.
static func stricter(a: StringName, b: StringName) -> StringName:
	if not AgeBand.restrictions:   # the owner, 2026-09-29: no age limits for now (AgeBand.restrictions)
		return AgeBand.TEEN_PLUS if AgeBand.is_valid(a) or AgeBand.is_valid(b) else &""
	if a == AgeBand.UNDER_13 or b == AgeBand.UNDER_13:
		return AgeBand.UNDER_13
	return a if AgeBand.is_valid(a) else b
