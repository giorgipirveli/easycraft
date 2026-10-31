class_name DeviceMoveRules
extends RefCounted
## Owner #99 (spec §5.13 "As built (owner #99)"; server module 0.2.20: server/modules/src/server/moves.ts): the same
## name on a new device, with proof and never by the name alone, and LOG OUT and LOG IN (one player on a device). The pure
## rules of the game's side and every word a child sees there (short, plain, read aloud; English only).
##
## The new device shows a 6-digit code from the server; a device already signed in to the account shows a card ("Someone
## wants to play as Anna on a computer.") where a grown-up types that code; then the new device gets a one-time key and
## signs in with it. The lead's security review (2026-10-15): the new device is never told whether the other device is
## online, or what it did (NOT ME, wrong codes): it waits until the code's 5 minutes are over.

## The lead's quick-ship round (2026-10-15 23:06; the second review's HIGH finding): the move by code is OFF, as on the
## server (MoveRules.ENABLED). Off: no MOVE YOUR GAME HERE and no card on the old device; a taken name's YES and I HAVE AN
## ACCOUNT open LOG IN (the name and the password, owner #105), whose USE A KEY is a grown-up's way. Tests written for the
## move switch it on for themselves.
static var enabled := false
const MOVE_OFF := "Moving with a code is resting for now. Ask a grown-up for a key."

## The server's notification about moves ({"what": "asked" | "moved", "kind"} to the account; {"what": "approved"} to
## the asking device).
const NOTE := 110
const CODE_DIGITS := 6
const CODE_SECONDS := 300
const WRONG_MAX := 3
## How often the new device asks how its ask stands (a notification also says "approved" at once).
const POLL_SECONDS := 3.0
const KINDS: Array[String] = ["phone", "tablet", "computer", "device"]
## Android's own line between phones and tablets: the shorter side in density-independent pixels.
const TABLET_DP := 600.0
const NOTE_WHATS: Array[String] = ["asked", "moved", "approved"]

# --- The words ---
# A taken name asks (UsernameClaim)
const TAKEN := "Someone already has the name %s. Is it you, from another phone, tablet or computer?"
const YES_ME := "YES, IT'S ME"
const NO_OTHER := "NO, ANOTHER NAME"
const PICK_ANOTHER := "Pick another name. RANDOM can help!"
# Move your game here (MoveGamePage, the new device)
const MOVE_TITLE := "Move your game here"
const GETTING_CODE := "Getting your code..."
const TYPE_THERE := "On your other device: open EasyCraft, and type this code there."
const WAITING := "The code works for 5 minutes."
const MOVING := "Yes! Moving your game..."
const WELCOME := "Welcome back, %s! Your name, progress, looks and gold are here."
const HAVE_KEY := "Has a grown-up made a key? They can type it instead."
const NEW_CODE := "NEW CODE"
const USE_KEY := "USE A KEY"
const SELF := "That's you! You play as that name here already."
const ENDED_WORDS := {
	"expired": "This code is old now. Get a new code and try again!",
	"cancelled": "You stopped. Get a new code to try again!",
}
const ENDED_ANY := "This code does not work any more. Get a new code and try again!"
# The card on the account's own devices (MoveAskCard)
const ASK := "Someone wants to play as %s %s."
const ASK_IF := "If it's you, a grown-up types the code from that screen."
const ASK_NEVER := "Never type a code someone tells you."
const TYPE_CODE := "TYPE THE CODE"
const NOT_ME := "NOT ME"
const PAD_PROMPT := "Type the code from the other screen."
const WRONG := "That code is not right. %d more %s."
const APPROVED_HERE := "Done! Your game goes there now."
const ENDED_HERE := "This ask is over. On the other device, tap NEW CODE to try again."
const DECLINED_HERE := "OK! Nothing moves. Your game is safe."
const MOVED := "Your game is on %s now too."
# LOG OUT and LOG IN (AccountsFlow; the final review's simple model: one player on a device, no kept slots)
const LOG_OUT := "LOG OUT"
const LOG_OUT_TITLE := "Log out"
const SAVING := "Saving your game..."
const OFFLINE := "Connect to the internet first, so your game is saved."
const NOT_SAVED := "Your game could not be saved yet. Try again in a moment."
const NEW_PLAYER := "NEW PLAYER"
const LOG_IN := "LOG IN"
const LOG_IN_TITLE := "Log in"
const NEXT := "NEXT"
const SWITCHING := "One moment..."
const IN_WORLD := "Go to the main menu to log out."
# LOG OUT asks once, never a grown-up's step
const LOG_OUT_ASK := "Log out, %s?"
const LOG_OUT_SAVED_FIRST := "Your game is saved to your account first. LOG IN with your name and password brings it back."
const MAKE_FIRST := "Make a password first, so you can log back in."
const YES_LOG_OUT := "YES, LOG OUT"
const NO := "NO"
const NO_ACCOUNT := "This player has no online account to log out of."
## The final review: LOG OUT never forgets gold the server has not taken yet (its hourly cap).
const GOLD_ON_ITS_WAY := "Some of your gold is still on its way: try LOG OUT again in an hour."
## LOG IN asks first when this device's player is a guest with progress (it goes; the worlds stay).
const GUEST_GOES := "%s's gold and progress on this device will go. Your worlds stay. Log in as %s?"
## The logged-out card's NEW PLAYER asks first.
const NEW_PLAYER_ASK := "Start as a new player? What you played here since you were logged out goes. Your worlds stay."
const YES := "YES"
const SWITCH_BUSY := "One moment: your game is still saving. Try again!"

const _THINGS := {"phone": "a phone", "tablet": "a tablet", "computer": "a computer"}


## What this device is, for the card on the account's other devices: a phone or a tablet (by the shorter side of its
## screen in dp), else a computer (a desktop, or a browser on one).
static func device_kind(features: Dictionary, screen_px: Vector2i, dpi: int) -> String:
	if not PlatformRules.touch_device(features):
		return "computer"
	var short_px := float(mini(screen_px.x, screen_px.y))
	var dp := short_px / (float(dpi) / 160.0) if dpi > 0 else 0.0
	return "tablet" if dp >= TABLET_DP else "phone"


## This device's kind (device_kind of the running game).
static func this_device_kind() -> String:
	var screen := DisplayServer.screen_get_size() if DisplayServer.get_name() != "headless" else Vector2i(1920, 1080)
	var dpi := DisplayServer.screen_get_dpi() if DisplayServer.get_name() != "headless" else 96
	return device_kind(PlatformRules.current(), screen, dpi)


## "123 456": two threes, easy to read across a room.
static func pretty_code(code: String) -> String:
	return code.substr(0, 3) + " " + code.substr(3) if code.length() == CODE_DIGITS else code


## The digits of a typed code, or "" when it is not 6 digits (spaces and a dash allowed).
static func normalize_code(text: String) -> String:
	var plain := text.strip_edges().replace(" ", "").replace("-", "")
	if plain.length() != CODE_DIGITS:
		return ""
	for c in plain:
		if not "0123456789".contains(c):
			return ""
	return plain


static func kind_of(value: Variant) -> String:
	return value if value is String and KINDS.has(value) else "device"


## "a computer", "a phone", "another device".
static func thing(kind: String) -> String:
	return _THINGS.get(kind, "another device")


static func ask_text(username: String, kind: String) -> String:
	return ASK % [username, "on " + thing(kind_of(kind))]


static func moved_text(kind: String) -> String:
	return MOVED % thing(kind_of(kind))


static func taken_text(username: String) -> String:
	return TAKEN % username


static func welcome_text(username: String) -> String:
	return WELCOME % username


## Why this device's ask ended, for the new device (the server only ever says expired, or cancelled after BACK).
static func ended_text(why: String) -> String:
	return ENDED_WORDS.get(why, ENDED_ANY)


static func wrong_text(tries_left: int) -> String:
	return WRONG % [tries_left, "try" if tries_left == 1 else "tries"]


## The server's refusals in plain words (OnlineRules.message for the shared ones).
static func error_text(code: String, wait: int = 0) -> String:
	match code:
		"self":
			return SELF
		"rate_limited":
			return OnlineRules.key_locked_message(wait if wait > 0 else 60)
	return OnlineRules.message(code)


## A notification 110's content: {"what": one of NOTE_WHATS or "", "kind"}.
static func note(content: String) -> Dictionary:
	var json := JSON.new()
	var d: Dictionary = json.data if content != "" and json.parse(content) == OK and json.data is Dictionary else {}
	var what: Variant = d.get("what", "")
	return {"what": what if what is String and NOTE_WHATS.has(what) else "", "kind": kind_of(d.get("kind"))}


## The server's list of asks for this account (move_approve "list"), checked: [{"id", "kind", "left_s",
## "until_msec"}], never longer than a code lives.
static func asks_from(value: Variant, now_msec: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (value is Array):
		return out
	for a: Variant in value:
		if not (a is Dictionary):
			continue
		var id: Variant = a.get("id")
		var left: Variant = a.get("left_s")
		if not (id is String) or (id as String) == "" or (id as String).length() > 64 \
				or typeof(left) not in [TYPE_INT, TYPE_FLOAT] or float(left) <= 0.0:
			continue
		var s := mini(int(left), CODE_SECONDS)
		out.append({"id": id, "kind": kind_of(a.get("kind")), "left_s": s, "until_msec": now_msec + s * 1000})
	return out


## The final review's 2: what a player's first minutes set without playing (the name, the settings, the looks, the hints
## seen, the tutorial, the HUD's moves, the switches, the day's counters). A profile that differs from a new player's only
## in these has nothing to lose (LOG IN asks first only when it has: GUEST_GOES).
const NOT_PROGRESS: Array[String] = ["version", "username", "age_band", "settings", "updated_at", "avatar", "hints_seen",
	"tutorial", "hud_moves", "theater_switch", "photo_share", "daily", "earn_today"]


## Whether `p` has gold or progress a new player has not (more or less gold than the start, a universe, a level, a
## treasure, a sticker, a bought thing, a short...): see NOT_PROGRESS.
static func has_progress(p: ProfileData) -> bool:
	var mine: Variant = JSON.parse_string(p.to_json())
	var fresh: Variant = JSON.parse_string(ProfileData.new().to_json())
	if not (mine is Dictionary and fresh is Dictionary):
		return true   # unreadable: ask (never forget without asking)
	for k: String in NOT_PROGRESS:
		(mine as Dictionary).erase(k)
		(fresh as Dictionary).erase(k)
	return JSON.stringify(mine, "", true) != JSON.stringify(fresh, "", true)


## Every line of these screens with sample names (the sentence checks).
static func lines() -> Array[String]:
	var out: Array[String] = [taken_text("Anna"), PICK_ANOTHER, GETTING_CODE, TYPE_THERE, WAITING, MOVING,
		welcome_text("Anna"), HAVE_KEY, SELF, ENDED_ANY, ask_text("Anna", "computer"), ASK_IF, ASK_NEVER, PAD_PROMPT,
		wrong_text(2), APPROVED_HERE, ENDED_HERE, DECLINED_HERE, moved_text("phone"), SAVING, OFFLINE, NOT_SAVED,
		SWITCHING, IN_WORLD, MOVE_OFF, LOG_OUT_ASK % "Anna", LOG_OUT_SAVED_FIRST, MAKE_FIRST, NO_ACCOUNT, GOLD_ON_ITS_WAY,
		GUEST_GOES % ["Pip", "Anna"], NEW_PLAYER_ASK, SWITCH_BUSY]
	for w: String in ENDED_WORDS.values():
		out.append(w)
	return out
