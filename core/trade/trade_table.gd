class_name TradeTable
extends RefCounted
## The host's asks and open trades between players (owner #37, spec §14.23). Pure bookkeeping: Session's section
## "Trading" checks who may trade (the world, the players, the age rule), keeps the offers covered by the bags and
## does the swap. A player has at most one ask out, one ask waiting for them, and one open trade. An ask waits until
## it is answered, taken back, or one of the two leaves (no timer). Every change of an offer makes both sides not
## ready, so what READY agreed to is what moves.
## A trade is {"id", "a", "b", "offers": {peer: offer}, "ready": {peer: bool}} (TradeRules offers).

const ASK_GAP_MS := 3000

var trades := {}      # trade id -> trade
var _asks := {}       # the child asked -> the child asking
var _asked_at := {}   # the child asking -> msec of their last ask
var _of := {}         # peer -> trade id
var _next := 1


## `asker` asks `target` to trade at `now_ms`: {"error": "" or self / you_busy / busy / too_soon, "dropped": the
## child an earlier ask of theirs went to (it is taken back), or 0}.
func ask(asker: int, target: int, now_ms: int) -> Dictionary:
	if asker == target:
		return {"error": "self", "dropped": 0}
	if _of.has(asker):
		return {"error": "you_busy", "dropped": 0}
	if _of.has(target) or (_asks.has(target) and int(_asks[target]) != asker):
		return {"error": "busy", "dropped": 0}
	if _asked_at.has(asker) and now_ms - int(_asked_at[asker]) < ASK_GAP_MS:
		return {"error": "too_soon", "dropped": 0}
	var dropped := unask(asker)
	_asks[target] = asker
	_asked_at[asker] = now_ms
	return {"error": "", "dropped": dropped if dropped != target else 0}


## Who is asking `target` (0: nobody).
func asker_of(target: int) -> int:
	return int(_asks.get(target, 0))


## Whom `asker` is asking (0: nobody).
func asked_by(asker: int) -> int:
	for target: int in _asks:
		if int(_asks[target]) == asker:
			return target
	return 0


## Takes back `asker`'s ask; returns whom it went to (0: none).
func unask(asker: int) -> int:
	var target := asked_by(asker)
	if target != 0:
		_asks.erase(target)
	return target


## `target` answers `asker`: YES opens their trade (returned), NO THANKS or a stale answer opens nothing ({}).
func answer(target: int, asker: int, yes: bool) -> Dictionary:
	if asker_of(target) != asker or asker == 0:
		return {}
	_asks.erase(target)
	if not yes or _of.has(asker) or _of.has(target):
		return {}
	var t := {"id": _next, "a": asker, "b": target,
		"offers": {asker: TradeRules.empty_offer(), target: TradeRules.empty_offer()},
		"ready": {asker: false, target: false}}
	_next += 1
	trades[t.id] = t
	_of[asker] = t.id
	_of[target] = t.id
	return t


## The open trade of `peer` ({} = none).
func trade_of(peer: int) -> Dictionary:
	return trades.get(_of.get(peer, -1), {})


static func other(t: Dictionary, peer: int) -> int:
	return int(t.b) if int(t.a) == peer else int(t.a)


## `peer` puts `offer` in their side of their trade: both sides are not ready any more. Returns the trade ({}).
func set_offer(peer: int, offer: Dictionary) -> Dictionary:
	var t := trade_of(peer)
	if t.is_empty():
		return t
	t.offers[peer] = offer
	for p: int in t.ready:
		t.ready[p] = false
	return t


func set_ready(peer: int, on: bool) -> Dictionary:
	var t := trade_of(peer)
	if not t.is_empty():
		t.ready[peer] = on
	return t


func both_ready(t: Dictionary) -> bool:
	return not t.is_empty() and bool(t.ready[t.a]) and bool(t.ready[t.b])


func unready(t: Dictionary) -> void:
	for p: int in t.ready:
		t.ready[p] = false


func close(t: Dictionary) -> void:
	if t.is_empty():
		return
	trades.erase(t.id)
	for p: int in [int(t.a), int(t.b)]:
		if int(_of.get(p, -1)) == int(t.id):
			_of.erase(p)


## `peer` left: their trade closes and their asks go. {"trade": the closed trade or {}, "asked": the child their
## ask went to (0), "asker": the child whose ask was waiting for them (0)}.
func forget(peer: int) -> Dictionary:
	var t := trade_of(peer)
	close(t)
	var asked := unask(peer)
	var asker := asker_of(peer)
	_asks.erase(peer)
	_asked_at.erase(peer)
	return {"trade": t, "asked": asked, "asker": asker}


## The trade as `peer` sees it: {"id", "other", "name" (the other's), "mine" and "theirs" (TradeRules.to_wire),
## "my_ready", "their_ready"}.
func state_for(t: Dictionary, peer: int, other_name: String) -> Dictionary:
	var o := other(t, peer)
	return {"id": int(t.id), "other": o, "name": other_name, "mine": TradeRules.to_wire(t.offers[peer]),
		"theirs": TradeRules.to_wire(t.offers[o]), "my_ready": bool(t.ready[peer]), "their_ready": bool(t.ready[o])}


func clear() -> void:
	trades.clear()
	_asks.clear()
	_asked_at.clear()
	_of.clear()
