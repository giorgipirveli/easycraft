class_name OnlineBackend
extends Node
## The server behind OnlineService (M4 Wave 1, Agent C): signing in, the game's RPCs and Nakama's
## own friends API. NakamaOnlineBackend (net/nakama_online_backend.gd) is the real one; tests use
## an in-memory fake (tests/fakes/fake_online_backend.gd) behind this same interface.
##
## Every call answers a Dictionary: {"ok": true, ...} or {"ok": false, "error": "<code or reason>"};
## OnlineRules.message turns the error into plain words. This base class is "not signed in" to
## everything, so a missing backend fails politely.

## A notification arrived (OnlineRules.INVITE and friends); content is its JSON text.
signal notified(code: int, content: String, sender_id: String)
## A followed friend came online or left.
signal presence_changed(user_id: String, online: bool)
## The connection to the server closed (network, server, or sign_out).
signal closed

const NOT_SIGNED_IN := {"ok": false, "error": "not_signed_in"}


## Signs in with this install's device id: {"ok", "user_id", "username"}. Owner #105: `create` false never makes an
## account: no account with this id answers {"ok": false, "error": "account_gone"}.
func sign_in(_server: Dictionary, _device_id: String, _create: bool = true) -> Dictionary:
	return NOT_SIGNED_IN


func is_signed_in() -> bool:
	return false


## Owner #105: another connection of the same kind, for asking the server on the side (LOG IN asks with the device's
## own asking account while the player plays on); null when there is none.
func make_twin() -> OnlineBackend:
	return null


func user_id() -> String:
	return ""


## A server RPC with a JSON object in and out (plan Wave 1: {"ok": bool, "error": "<code>", ...}).
func call_rpc(_id: String, _payload: Dictionary = {}) -> Dictionary:
	return NOT_SIGNED_IN


## {"ok", "friends": [{"id", "username", "state": 0-3 (Nakama's), "online": bool}]}.
func list_friends() -> Dictionary:
	return NOT_SIGNED_IN


## A friend request by exact username (or accepting theirs).
func add_friend_by_name(_username: String) -> Dictionary:
	return NOT_SIGNED_IN


## A friend request by user id (accepting a request that came in).
func add_friend_by_id(_id: String) -> Dictionary:
	return NOT_SIGNED_IN


## Declines a request, cancels one, or ends a friendship.
func remove_friend(_id: String) -> Dictionary:
	return NOT_SIGNED_IN


## Blocks a player: they are no longer a friend and can't ask again.
func block(_id: String) -> Dictionary:
	return NOT_SIGNED_IN


## Online status updates for these users (presence_changed).
func follow(_ids: Array[String]) -> void:
	pass


## This player's own storage object (M4 Wave 2, agent F: the profile backup): {"ok", "value": its
## JSON text, "" when there is none, "version"}.
func read_storage(_collection: String, _key: String) -> Dictionary:
	return NOT_SIGNED_IN


## Writes this player's own storage object, private (only its owner reads and writes it): {"ok", "version"}.
## Owner #67: `version` "" writes whatever is there, "*" only if there is nothing yet, else only over that
## version; a write refused for its version is {"ok": false, "error": "version_clash"} (another device wrote).
func write_storage(_collection: String, _key: String, _value: String, _version: String = "") -> Dictionary:
	return NOT_SIGNED_IN


func sign_out() -> void:
	pass

# --- M4 E: chat channels (friends' DMs, a match's team room) ---

## A chat message arrived on a joined channel: Nakama's fields {channel_id, message_id, sender_id,
## username, content (JSON text), create_time, code}; OnlineChatRules.parse reads it.
signal chat_message(message: Dictionary)


## Joins a channel: target = a friend's user id (OnlineChatRules.TYPE_DM) or a match id
## (TYPE_ROOM); persist = keep this player's messages in the history. {"ok", "channel_id"}.
func join_chat(_target: String, _type: int, _persist: bool) -> Dictionary:
	return NOT_SIGNED_IN


func leave_chat(_channel_id: String) -> Dictionary:
	return NOT_SIGNED_IN


## Sends {"text"} or {"emote"}: {"ok", "message_id"} or the server's refusal code.
func send_chat(_channel_id: String, _content: Dictionary) -> Dictionary:
	return NOT_SIGNED_IN


## The channel's kept messages, newest first: {"ok", "messages": [Nakama's fields]}.
func chat_history(_channel_id: String, _limit: int) -> Dictionary:
	return NOT_SIGNED_IN
