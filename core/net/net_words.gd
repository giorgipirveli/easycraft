class_name NetWords
extends RefCounted
## Plain words for every network problem (M4 Wave 1 A, spec §17.0). The online code fails with raw
## reasons ("sign-in: HTTPRequest failed!", "match: Match not found"); code_for() turns them into a
## few short codes (server RPCs answer with such codes too), and text() gives each code one kind
## sentence a child can read: what happened and what happens next, never how.

const NO_SERVER := &"no_server"
const SIGN_IN := &"sign_in"
const TIMEOUT := &"timeout"
const NO_WORLD := &"no_world"
const WORLD_FULL := &"world_full"
const NOT_INVITED := &"not_invited"
const HOST_LEFT := &"host_left"
const LINK_LOST := &"link_lost"
const GAVE_UP := &"gave_up"
const SERVER_GONE := &"server_gone"
const BACK := &"back"
const REMOVED := &"removed"   # spec §17.3: the host took this player out of its world
const UNKNOWN := &"unknown"
## Owner #123 (NetVersionCheck): the two games in a world are different versions.
const NEWER_WORLD := &"newer_world"   # a guest: the host's game is newer (the guest leaves)
const OLDER_WORLD := &"older_world"   # a guest: the host's game is older (the guest leaves)
const FRIEND_DIFFERENT := &"friend_different"   # the host: a guest with another version left
const MAYBE_DIFFERENT := &"maybe_different"   # either: the other game is older than the check itself

const WORDS := {
	NO_SERVER: "We can't reach the game right now. Check that the internet is on, then try again.",
	SIGN_IN: "We couldn't sign you in just now. Please try again in a moment.",
	TIMEOUT: "The internet is very slow right now. Please try again.",
	NO_WORLD: "That world isn't open any more. Ask your friend to invite you again.",
	WORLD_FULL: "That world is full: 4 players are in it already. Try again later!",
	NOT_INVITED: "You need an invite from your friend to join this world.",
	HOST_LEFT: "Your friend stopped playing, so their world closed. It's saved on their device.",
	LINK_LOST: "The internet went away. Trying again…",
	GAVE_UP: "We couldn't get back into your friend's world. Back to the menu for now!",
	SERVER_GONE: "Your friends can't reach this world right now. You can keep playing on your own.",
	BACK: "You're back! Welcome back.",
	REMOVED: "The host asked you to leave their world. Back to the menu for now!",
	UNKNOWN: "Something went wrong with the connection. Please try again.",
	NEWER_WORLD: "This world has a newer EasyCraft. Update yours: close EasyCraft and open it again.",
	OLDER_WORLD: "This world has an older EasyCraft. Ask your friend to close it and open it again.",
	FRIEND_DIFFERENT: "A friend has a different EasyCraft, so they can't join until you both update.",
	MAYBE_DIFFERENT: "Your friend has an older EasyCraft. Some things may look different until it updates.",
}
const CODES: Array[StringName] = [NO_SERVER, SIGN_IN, TIMEOUT, NO_WORLD, WORLD_FULL, NOT_INVITED,
	HOST_LEFT, LINK_LOST, GAVE_UP, SERVER_GONE, BACK, REMOVED, UNKNOWN, NEWER_WORLD, OLDER_WORLD, FRIEND_DIFFERENT,
	MAYBE_DIFFERENT]


## The kind words for `code` (an unknown code gets UNKNOWN's words).
static func text(code: StringName) -> String:
	return WORDS.get(code, WORDS[UNKNOWN])


## The code for a raw reason from NakamaLink / Session ("sign-in: …", "match: …", …) or a short
## error code from a server RPC ("not_invited", "match_full").
static func code_for(reason: String) -> StringName:
	var r := reason.strip_edges().to_lower()
	if r == "":
		return UNKNOWN
	if r == "version: newer":   # owner #123: Session's version check
		return NEWER_WORLD
	if r == "version: older":
		return OLDER_WORLD
	if r.contains("not_invited") or r.contains("not invited"):
		return NOT_INVITED
	if r.contains("full"):
		return WORLD_FULL
	if r.contains("timeout") or r.contains("timed out") or r.begins_with("no answer"):
		return TIMEOUT
	if r.contains("not found") or r.contains("not a match id") or r.contains("no_world"):
		return NO_WORLD
	if r.contains("host left"):
		return HOST_LEFT
	if r.contains("connection to the server closed"):
		return LINK_LOST
	if r.contains("httprequest failed") or r.contains("cancelled") or r.begins_with("socket"):
		return NO_SERVER
	if r.begins_with("sign-in") or r.contains("not signed in"):
		return SIGN_IN
	return UNKNOWN


static func for_reason(reason: String) -> String:
	return text(code_for(reason))
