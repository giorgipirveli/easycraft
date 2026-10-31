class_name OnlineWallets
extends RefCounted
## Survivor gold in a world this game hosts online (M4 Wave 2, agent F; spec §7.3, §17.1, §17.6; the
## lead's review). The host decides gold during play, as always; online, the server keeps each
## player's balance: a guest's wallet starts from the server (get_gold_of), never from the guest's
## own word, and every change of every player in the match goes to the server's ledger (batched by
## OnlineService.report_gold; the server limits it per player). Session calls this only as an online
## host; LAN keeps trusting the guest (spec §12.11).

## The host's own peer id (Godot's multiplayer: the host is always 1).
const HOST_PEER := 1

var service: OnlineService
var user_of := Callable()    # (peer id) -> the player's Nakama user id, "" when the relay doesn't know it
var match_id := Callable()   # () -> the relayed match this game hosts


## A guest's starting Survivor gold from the server, or -1 when the server can't say (not signed in,
## no answer, a peer the relay doesn't know): then the caller falls back to LAN's trust.
func starting_gold(peer_id: int) -> int:
	var uid := str(user_of.call(peer_id)) if user_of.is_valid() else ""
	if uid == "" or service == null or service.status != OnlineService.ONLINE:
		return -1
	var r: Dictionary = await service.gold_of(uid, str(match_id.call()) if match_id.is_valid() else "")
	var gold: Variant = r.get("gold")
	if not r.get("ok", false) or typeof(gold) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(gold)) or float(gold) < 0.0:
		return -1
	return int(gold)


## The gold-double bug's leftover (module 0.2.19): the count of the gold moves reported for a guest so far (0: none, or
## a peer the relay doesn't know). The host tells the guest's game each move with it (Session._store_gold).
func seq_of(peer_id: int) -> int:
	var uid := str(user_of.call(peer_id)) if user_of.is_valid() else ""
	if uid == "" or service == null or peer_id == HOST_PEER:
		return 0
	return service.report_seq(uid)


## A player's gold changed by `delta` (the host's decision): reported to the server's ledger.
func moved(peer_id: int, delta: int) -> void:
	if service == null or delta == 0:
		return
	if peer_id == HOST_PEER:
		service.report_gold(delta)
		return
	var uid := str(user_of.call(peer_id)) if user_of.is_valid() else ""
	if uid != "":
		service.report_gold(delta, uid, str(match_id.call()) if match_id.is_valid() else "")
