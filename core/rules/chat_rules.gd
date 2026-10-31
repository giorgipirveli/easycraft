class_name ChatRules
extends RefCounted
## Chat messages between players, as pure rules (spec §3b, §5.13): cleanup (control characters out,
## spaces squeezed, trimmed, at most 120 characters), the age-band rule (under_13 players send and
## receive the quick-chat phrases only), the bad-word and personal-info filter for 13_plus free text
## (the username word list, matched per word), and the host's rate limit (5 messages per 10 s).

const MAX_LENGTH := 120
## Network input longer than this is cut before any other work is done on it.
const MAX_RAW_LENGTH := 1000
const RATE_COUNT := 5
const RATE_WINDOW := 10.0
## Quick chat: the only messages under_13 players can send or receive (text only; emoji may not
## render in the default font).
const QUICK_PHRASES: Array[String] = [
	"Hi!", "Follow me!", "Look!", "Nice build!", "Thanks!", "Help!", "Bye!",
	"Come here!", "Wow!", "Let's build!", "Good job!", "Yes!", "No!",
]
## A run of this many digits (spaces, dashes, dots, brackets and + allowed between them) looks
## like a phone number, as in usernames.
const PHONE_DIGITS := 7
## Whole words or phrases that share contact details or where someone lives.
const PERSONAL_PHRASES: Array[String] = [
	"address", "street", "zip code", "postcode", "phone number", "my number", "call me", "text me",
	"email", "e mail", "gmail", "hotmail", "snapchat", "snap me", "instagram", "insta", "whatsapp",
	"discord", "telegram", "facebook", "tiktok", "kik", "password", "where do you live", "i live at",
	"i live on", "my school", "what school",
]
## Matched anywhere inside a word (never innocent inside other words).
const STRONG_WORDS: Array[String] = ["fuck", "shit", "bitch", "slut", "whore", "porn"]

# The checks read a normalised copy of the message (normalize), so digits and letters of other
# scripts can't slip past them (review M9). The message itself keeps its accents.
## The zero of every run of ten Unicode decimal digits (category Nd, Unicode 16) besides ASCII:
## Arabic-Indic, Persian, Devanagari, Bengali, Thai, fullwidth, the maths digits and the rest.
const DIGIT_ZEROS: Array[int] = [
	0x660, 0x6F0, 0x7C0, 0x966, 0x9E6, 0xA66, 0xAE6, 0xB66, 0xBE6, 0xC66, 0xCE6, 0xD66,
	0xDE6, 0xE50, 0xED0, 0xF20, 0x1040, 0x1090, 0x17E0, 0x1810, 0x1946, 0x19D0, 0x1A80, 0x1A90,
	0x1B50, 0x1BB0, 0x1C40, 0x1C50, 0xA620, 0xA8D0, 0xA900, 0xA9D0, 0xA9F0, 0xAA50, 0xABF0, 0xFF10,
	0x104A0, 0x10D30, 0x10D40, 0x11066, 0x110F0, 0x11136, 0x111D0, 0x112F0, 0x11450, 0x114D0, 0x11650, 0x116C0,
	0x116D0, 0x116DA, 0x11730, 0x118E0, 0x11950, 0x11BF0, 0x11C50, 0x11D50, 0x11DA0, 0x11F50, 0x16130, 0x16A60,
	0x16AC0, 0x16B50, 0x16D70, 0x1CCF0, 0x1D7CE, 0x1D7D8, 0x1D7E2, 0x1D7EC, 0x1D7F6, 0x1E140, 0x1E2F0, 0x1E4F0,
	0x1E5F1, 0x1E950, 0x1FBF0,
]
## Digit look-alikes that are not decimal digits: the character at index d reads as d.
const DIGIT_LOOKALIKES: Array[String] = ["⁰¹²³⁴⁵⁶⁷⁸⁹", "₀₁₂₃₄₅₆₇₈₉", "⓪①②③④⑤⑥⑦⑧⑨"]
## Plain text -> the characters read as it: accented Latin letters, look-alike Greek and Cyrillic
## letters, ligatures, other spaces and dashes. A capital listed here wins over its small letter
## (a capital eta looks like H, a small one like n); other capitals are lower-cased first.
const CHAR_FOLDS := {
	"a": "àáâãäåāăąǎαа", "b": "βвь", "c": "çćĉċčсϲ", "d": "ďđðԁ", "e": "èéêëēĕėęěεеё",
	"g": "ĝğġģ", "h": "ĥħһнΗ", "i": "ìíîïĩīĭįıιіїɩ", "j": "ĵј", "k": "ķκк", "l": "ĺļľŀłӏ",
	"m": "мΜ", "n": "ñńņňŉηпΝ", "o": "òóôõöøōŏőοоσ", "p": "ρр", "r": "ŕŗřг", "s": "śŝşšșѕ",
	"t": "ţťŧțτт", "u": "ùúûüũūŭůűųυμ", "v": "ν", "w": "ŵωш", "x": "χх", "y": "ýÿŷуүΥ", "z": "źżž",
	"ss": "ß", "ae": "æ", "oe": "œ", "th": "þ",
	" ": "              　",
	"-": "‐‑‒–—―−﹣",
}

static var _phone_re := RegEx.create_from_string("[0-9][0-9 ()+.\\-]*[0-9]")
static var _email_re := RegEx.create_from_string("\\S+@\\S+\\.\\S+")
static var _link_re := RegEx.create_from_string(
	"(?i)(https?://|www\\.|\\b[a-z0-9-]+\\.(com|net|org|io|gg|me|co|tv|ly|app|xyz|uk|de)\\b)")
static var _non_word_re := RegEx.create_from_string("[^a-z0-9]+")
static var _non_letter_re := RegEx.create_from_string("[^a-z]+")
static var _spaces_re := RegEx.create_from_string("\\s+")
static var _fold_map := {}   # character -> plain text, built from the tables on first use


## Control and invisible formatting characters become spaces or go, runs of spaces become one,
## the ends are trimmed and the result is at most MAX_LENGTH characters.
static func clean(text: String) -> String:
	var out := ""
	for ch in text.substr(0, MAX_RAW_LENGTH):
		var c := ch.unicode_at(0)
		if c < 32 or (c >= 127 and c < 160):
			out += " "
		elif not _is_invisible(c):
			out += ch
	out = _spaces_re.sub(out, " ", true).strip_edges()
	return out.substr(0, MAX_LENGTH).strip_edges()


static func _is_invisible(c: int) -> bool:
	return (c >= 0x200B and c <= 0x200F) or (c >= 0x202A and c <= 0x202E) or (c >= 0x2060 and c <= 0x2069) \
		or c == 0xFEFF or c == 0x00AD


static func is_quick_phrase(text: String) -> bool:
	return QUICK_PHRASES.has(text)


## A missing or unknown band (a player who never told the host) gets the under_13 rules, while age rules are on
## (AgeBand.restrictions; off: everyone 13+).
static func effective_band(band: StringName) -> StringName:
	return AgeBand.effective(band)


## Checks a message from a player of `band`. Returns {"text": cleaned} or {"error": code}, with
## code one of: empty, quick_chat_only, personal_info, blocked_word.
static func check(text: String, band: StringName) -> Dictionary:
	var t := clean(text)
	if t == "":
		return {"error": "empty"}
	if is_quick_phrase(t):
		return {"text": t}
	if effective_band(band) != AgeBand.TEEN_PLUS:
		return {"error": "quick_chat_only"}
	var code := filter_code(t)
	return {"error": code} if code != "" else {"text": t}


## Whether a player of `band` may see this (already checked) message.
static func can_receive(text: String, band: StringName) -> bool:
	return effective_band(band) == AgeBand.TEEN_PLUS or is_quick_phrase(text)


## "" when the text is fine, else personal_info or blocked_word.
static func filter_code(raw: String) -> String:
	var text := normalize(raw)
	for m in _phone_re.search_all(text):
		var digits := 0
		for ch in m.get_string():
			if ch >= "0" and ch <= "9":
				digits += 1
		if digits >= PHONE_DIGITS:
			return "personal_info"
	if _email_re.search(text) or _link_re.search(text):
		return "personal_info"
	var plain := " %s " % _non_word_re.sub(text.to_lower(), " ", true).strip_edges()
	for phrase in PERSONAL_PHRASES:
		if plain.contains(" %s " % phrase):
			return "personal_info"
	for word in _words(text):
		for bad in UsernameRules.BLOCKED_WORDS:
			if word.begins_with(bad):
				return "blocked_word"
		for bad in STRONG_WORDS:
			if word.contains(bad):
				return "blocked_word"
	return ""


## The text the checks read: lower case, every decimal digit (and digit look-alike) as an ASCII
## digit, fullwidth ASCII as ASCII, accented and look-alike letters as plain letters (CHAR_FOLDS),
## other spaces and dashes as " " and "-", and combining accents dropped ("u" + "¨" is "u").
static func normalize(text: String) -> String:
	var folds := _folds()
	var out := ""
	for ch in text:
		var c := ch.unicode_at(0)
		if c < 0x80:
			out += ch.to_lower()
		elif c >= 0x300 and c <= 0x36F:
			continue
		elif folds.has(ch):
			out += folds[ch]
		else:
			var low := ch.to_lower()
			out += folds.get(low, low)
	return out


static func _folds() -> Dictionary:
	if _fold_map.is_empty():
		for zero in DIGIT_ZEROS:
			for d in 10:
				_fold_map[char(zero + d)] = str(d)
		for digits in DIGIT_LOOKALIKES:
			for d in digits.length():
				_fold_map[digits[d]] = str(d)
		for c in range(0xFF01, 0xFF5F):   # fullwidth ASCII: ＡＢＣ ５ ＠ ．
			_fold_map[char(c)] = char(c - 0xFEE0).to_lower()
		for plain: String in CHAR_FOLDS:
			for ch in CHAR_FOLDS[plain] as String:
				_fold_map[ch] = plain
	return _fold_map


## The words of a message for the bad-word check, lower case, with "l33t" digits read as letters.
## A run of single letters is joined into one word, so "s t u p i d" is still caught.
static func _words(text: String) -> Array[String]:
	var s := text.to_lower()
	for k: String in UsernameRules.LEET:
		if k >= "0" and k <= "9":
			s = s.replace(k, UsernameRules.LEET[k])
	var words: Array[String] = []
	var letters := ""
	for w in _non_letter_re.sub(s, " ", true).split(" ", false):
		if w.length() == 1:
			letters += w
			continue
		if letters.length() > 1:
			words.append(letters)
		letters = ""
		words.append(w)
	if letters.length() > 1:
		words.append(letters)
	return words


static func message(code: String) -> String:
	match code:
		"empty":
			return "Type something first."
		"quick_chat_only":
			return "Use the quick chat buttons to talk to friends."
		"personal_info":
			return "Keep it safe: no phone numbers, addresses, emails or links."
		"blocked_word":
			return "That message isn't allowed. Try saying it another way!"
		"too_fast":
			return "Slow down a little! Wait a few seconds."
		_:
			return ""


## The host's per-player limit: at most RATE_COUNT messages in any RATE_WINDOW seconds.
class RateLimiter:
	var _times := {}   # peer id -> Array of send times (seconds)

	## True (and counted) when `peer_id` may send a message at time `now` (seconds).
	func allow(peer_id: int, now: float) -> bool:
		var times: Array = _times.get(peer_id, [])
		while not times.is_empty() and now - float(times[0]) >= ChatRules.RATE_WINDOW:
			times.pop_front()
		_times[peer_id] = times
		if times.size() >= ChatRules.RATE_COUNT:
			return false
		times.append(now)
		return true

	func forget(peer_id: int) -> void:
		_times.erase(peer_id)

	func clear() -> void:
		_times.clear()
