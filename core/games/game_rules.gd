class_name GameRules
extends RefCounted
## The co-op games' shared rules (M4 Wave 3, agent H; spec §17.5): the kinds, who plays (players and bot
## friends, by key: "p<peer id>" and "b<bot name>"), when a round may start (no round, wave or boss on;
## hide-and-seek needs two), and everyone's same sticker (kept in the profile; never gold, never random).

const HIDE_SEEK := &"hide_seek"
const STORM_RUN := &"storm_run"
const KINDS: Array[StringName] = [HIDE_SEEK, STORM_RUN]
## Everyone who played gets the game's sticker (sticker id -> the name a child reads).
const STICKERS := {"hide_seek": "Hide & Seek", "storm_run": "Storm Run"}
const MAX_STICKERS := 999999
## How long the end of a round stays on the HUD before the world is back to normal.
const OVER_TIME := 6.0

# Why a round can't start (GameWords.refusal).
const RUNNING := &"running"
const WAVE := &"wave"
const BOSS := &"boss"
const ALONE := &"alone"
const UNKNOWN := &"unknown"


static func player_key(peer_id: int) -> String:
	return "p%d" % peer_id


static func bot_key(bot_name: String) -> String:
	return "b" + bot_name


static func is_bot(key: String) -> bool:
	return key.begins_with("b") and key.length() > 1


## The peer id of a player's key (0 for a bot or anything else).
static func peer_of(key: String) -> int:
	if not key.begins_with("p") or not key.substr(1).is_valid_int():
		return 0
	return key.substr(1).to_int()


static func bot_of(key: String) -> String:
	return key.substr(1) if is_bot(key) else ""


static func valid_kind(kind: StringName) -> bool:
	return KINDS.has(kind)


## Why a round of `kind` can't start now (&"" = it can). `busy`: &"wave" or &"boss" while the Totem's
## wave or a boss is on; `players`: players and bot friends in the world.
static func start_refusal(kind: StringName, running: bool, busy: StringName, players: int) -> StringName:
	if not valid_kind(kind):
		return UNKNOWN
	if running:
		return RUNNING
	if busy == WAVE:
		return WAVE
	if busy == BOSS:
		return BOSS
	if kind == HIDE_SEEK and players < HideSeekRound.MIN_PLAYERS:
		return ALONE
	return &""
