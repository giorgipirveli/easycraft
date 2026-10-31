class_name PasswordRules
extends RefCounted
## Owner #105 (2026-10-15 23:14; spec §5.13 "As built (owner #99, #105)"): "when starting playing create a password. so
## when logging in another device you can use password and username again to login, but if you login another device you
## should logout automatically from old device". The game's side of the password rules (the server checks them again:
## server/modules/src/rules/password_rules.ts; the same common list, test_account_password_rules.gd) and every word a
## child sees about passwords and logging in. English only.

const MIN_LEN := 6
const MAX_LEN := 64
## bcrypt (the server) reads at most 72 bytes; a longer password is refused with clear words, never cut (owner #105 review).
const MAX_BYTES := 72
## Straight runs (either way) of RUN_LEN or more are refused (the server's RUNS): 123456, abcdef, qwerty, keyboard rows.
const RUN_LEN := 6
const RUNS: Array[String] = ["0123456789", "1234567890", "abcdefghijklmnopqrstuvwxyz", "qwertyuiop", "asdfghjkl", "zxcvbnm"]
## The commonest passwords (lower case), never allowed (the server's PasswordRules.COMMON); plus one character again
## and again. The list lives in CommonPasswords (core/net/common_passwords.gd): it is never shown to a child, and the
## banned-name check of shipped strings leaves that file out (test_costumes.gd's NEVER_SHOWN).
const COMMON := CommonPasswords.LIST

# --- The words ---
const NEVER_TELL := "Never tell anyone your password. Not even a friend."
## No real password to copy (owner #105 review): a shape, not a word a child would then use.
const IDEA := "Make it two words and a number that only you would think of."
const MAKE_TITLE := "Make a password"
const MAKE_WHY := "Make a password so you can play on your other devices."
const CHANGE_TITLE := "Change the password"
const PASSWORD := "PASSWORD"
const AGAIN := "AGAIN"
const OLD := "OLD"
const SHOW := "SHOW"
const HIDE := "HIDE"
const MAKE := "MAKE IT"
const CHANGE := "CHANGE IT"
const LATER := "LATER"
const SAVED := "Your password is made. Keep it secret!"
const CHANGED := "The password is changed. Keep it secret!"
const WRONG := "That name and password don't match."
## A wrong password of one's own account (CHANGE's old one, DELETE): no name was typed.
const WRONG_OWN := "That password is not right."
## The final review's 8: the same words whether the account was used on another device or deleted (this device cannot
## tell the two apart), so they never say something untrue.
const LOGGED_OUT := "This device was logged out. LOG IN to play here."
## The final review's 3: with the account's name (LOGGED_OUT_SAVED % name).
const LOGGED_OUT_SAVED := "Everything you played here is kept on this device and goes up when you log in again as %s."
## The final review's 7: the logged-out card in a world (LOG IN and NEW PLAYER are on the main menu only: a world's files
## are open there).
const LOGGED_OUT_MENU := "Go to the main menu to LOG IN."
const FORGOT := "FORGOT PASSWORD?"
const FORGOT_WORDS := "Ask a grown-up: on a device where you are still logged in, open GROWN-UPS and choose CHANGE PASSWORD."
const LOG_IN_TITLE := "Log in"
const LOG_IN_WORDS := "Type your online name and your password."
const LOGGING_IN := "Logging in..."
const ONE_DEVICE := "Your game moves here: your other devices are logged out."
const GROWN_UP_KEY := "Don't know the old password? Leave it empty: a key made on this device proves it's you."
## Owner #105 (the second review): the empty-old change makes a NEW key to prove it, which stops the old written-down
## one; the grown-up is shown the new key, never a silent swap.
const NEW_KEY_MADE := "A new sign-in key was made. Your old key stopped working. Write this one down."
const DELETE_PASSWORD := "Type the password to delete."
const SLOW_DOWN := "Too many tries for this name. Try again in %d minute%s, or ask a grown-up for a key."
const TRIED := "Someone tried to log in as you on a new device. If it wasn't you, a grown-up can change your password."

const _MESSAGES := {
	"too_short": "Use at least 6 letters, numbers or signs.",
	"too_long": "That password is too long.",
	"bad_chars": "Use letters, numbers and signs only.",
	"is_name": "Your password can't be your name, even with numbers.",
	"too_common": "That password is too easy to guess. Make it two words and a number that only you would think of.",
	"straight_run": "No runs like 123456 or qwerty. Make it two words and a number that only you would think of.",
	"mismatch": "The two passwords are not the same.",
	"has_password": "This account has a password already.",
	"password_needed": "Type the password first.",
	"too_new": "One moment, then try again.",
}


## "" when `text` may be the password of `username`; else too_short, too_long, bad_chars, is_name or too_common.
static func problem(text: String, username: String) -> String:
	if text.length() < MIN_LEN:
		return "too_short"
	if text.length() > MAX_LEN or text.to_utf8_buffer().size() > MAX_BYTES:
		return "too_long"   # bcrypt reads at most 72 bytes (owner #105 review): clear words, never a silent cut
	for c in text:
		var code := c.unicode_at(0)
		if code < 32 or code == 127:
			return "bad_chars"
	var lower := text.to_lower()
	var name_letters := _letters(username.to_lower())
	if lower == username.to_lower() or (name_letters.length() >= 3 and _letters(lower) == name_letters):
		return "is_name"   # the name, or the name with numbers and signs around it (anna12, Anna2024)
	if COMMON.has(lower):
		return "too_common"
	var same := true
	for c in text:
		if c != text[0]:
			same = false
			break
	if same:
		return "too_common"
	return "straight_run" if has_run(lower) else ""


## A straight run of RUN_LEN or more (either way) from RUNS anywhere in `lower`.
static func has_run(lower: String) -> bool:
	for run in RUNS:
		for r: String in [run, run.reverse()]:
			for i in r.length() - RUN_LEN + 1:
				if lower.contains(r.substr(i, RUN_LEN)):
					return true
	return false


static func _letters(text: String) -> String:
	var out := ""
	for c in text:
		if c >= "a" and c <= "z":
			out += c
	return out


## A new password typed twice: "" or a code for message().
static func problem_twice(text: String, again: String, username: String) -> String:
	var p := problem(text, username)
	if p != "":
		return p
	return "" if text == again else "mismatch"


static func message(code: String) -> String:
	return _MESSAGES.get(code, "")


## The server's answers in plain words (`own`: the account's own password, no name typed: CHANGE, DELETE).
static func error_text(code: String, wait: int = 0, own: bool = false) -> String:
	match code:
		"wrong_password":
			return WRONG_OWN if own else WRONG
		"locked":
			var minutes := maxi(1, ceili(maxi(wait, 1) / 60.0))
			return "Too many tries: wait %d minute%s." % [minutes, "" if minutes == 1 else "s"]
		"slow_down":   # the name window (the frozen design): one try every 10 minutes for a new device; a key always works
			var minutes := maxi(1, ceili(maxi(wait, 1) / 60.0))
			return SLOW_DOWN % [minutes, "" if minutes == 1 else "s"]
	if _MESSAGES.has(code):
		return _MESSAGES[code]
	return OnlineRules.message(code)


## Every line of these screens (the sentence checks).
static func lines() -> Array[String]:
	var out: Array[String] = [NEVER_TELL, MAKE_WHY, SAVED, CHANGED, WRONG, WRONG_OWN, LOGGED_OUT, LOGGED_OUT_SAVED % "Anna", LOGGED_OUT_MENU, FORGOT,
		FORGOT_WORDS, LOG_IN_WORDS, ONE_DEVICE, GROWN_UP_KEY, NEW_KEY_MADE, DELETE_PASSWORD,
		error_text("locked", 900), error_text("slow_down", 120), TRIED, IDEA]
	for w: String in _MESSAGES.values():
		out.append(w)
	return out
