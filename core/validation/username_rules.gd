class_name UsernameRules
extends RefCounted
## Local username checks (format + filters). Server-side uniqueness arrives in M4.
## Callers store normalize(name), the same string that was validated.

const MIN_LEN := 3
const MAX_LEN := 16
## Stems of 4+ letters, so short ones don't hit innocent names ("grass", "class"). They are matched
## anywhere in the name, since usernames have no spaces ("iamstupid"), except inside INNOCENT_WORDS.
const BLOCKED_WORDS: Array[String] = [
	"stupid", "idiot", "dumb", "loser", "moron", "hate", "kill", "murder", "suicide",
	"nazi", "hitler", "racist", "porn", "sexy", "nude", "naked", "fuck", "shit", "bitch",
	"dick", "cock", "pussy", "slut", "whore", "bastard", "damn", "crap", "penis", "vagina",
	"boob", "drug", "weed", "cocaine",
]
## Innocent words with a blocked stem inside (the Scunthorpe problem). A stem inside one of these
## doesn't count; the same stem anywhere else in the name still does ("Peacock_dick").
const INNOCENT_WORDS: Array[String] = [
	"peacock", "hancock", "hitchcock", "shuttlecock", "woodcock", "cockatoo", "cockatiel", "cockpit",
	"cockroach", "cocker", "whatever", "chateau", "skill", "scrap", "dickens", "dickinson", "dickory",
	"tweed", "weedle", "closer", "dumbo", "dumbledore", "dumbbell",
]
const LEET := {"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t", "8": "b", "_": ""}

static var _chars_re := RegEx.create_from_string("^[A-Za-z0-9_]+$")
static var _digits_re := RegEx.create_from_string("[0-9]")
const MAX_DIGITS := 6   # 7+ digits anywhere (even split by _) could be a phone number


static func normalize(name: String) -> String:
	return name.strip_edges()


## Returns "" when valid, else one of: too_short, too_long, bad_chars,
## must_start_with_letter, personal_info, blocked_word.
static func validate(name: String) -> String:
	var n := normalize(name)
	if n.length() < MIN_LEN:
		return "too_short"
	if n.length() > MAX_LEN:
		return "too_long"
	if _chars_re.search(n) == null:
		return "bad_chars"
	var first := n.unicode_at(0)
	var is_letter := (first >= 65 and first <= 90) or (first >= 97 and first <= 122)
	if not is_letter:
		return "must_start_with_letter"
	if _digits_re.search_all(n).size() > MAX_DIGITS:
		return "personal_info"
	var plain := n.to_lower()
	var unleet := plain
	for k: String in LEET:
		unleet = unleet.replace(k, LEET[k])
	for text: String in [_cover_innocent(plain), _cover_innocent(unleet)]:
		for word in BLOCKED_WORDS:
			if text.contains(word):
				return "blocked_word"
	return ""


## Covers each innocent word with "|", so the stem inside it no longer matches and no new word
## can form across the cover ("Peacock" -> "|", "Peacock_dick" -> "|_dick").
static func _cover_innocent(text: String) -> String:
	for word in INNOCENT_WORDS:
		text = text.replace(word, "|")
	return text


static func message(code: String) -> String:
	match code:
		"too_short":
			return Lang.t("Use at least %d characters.") % MIN_LEN
		"too_long":
			return Lang.t("Use at most %d characters.") % MAX_LEN
		"bad_chars":
			return "Only letters A–Z, numbers and _ are allowed."
		"must_start_with_letter":
			return "Start with a letter."
		"personal_info":
			return "Don't put phone numbers or personal info in your name."
		"blocked_word":
			return "That name isn't allowed. Try another one!"
		_:
			return ""
