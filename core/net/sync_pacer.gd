class_name SyncPacer
extends RefCounted
## Pacing of world data on the one reliable stream (M4 Wave 1 A, spec §17.0). Over the Nakama relay
## every packet is reliable and in order on one WebSocket, so a big burst of world data delays the
## players' positions behind it (the spike measured pings 1.5–5× slower while a world streamed in).
## Each guest gets a token bucket: RATE bytes a second, at most BURST at once; a record bigger than
## what is left still goes (one at a time) and leaves a debt to pay back first. While the link still
## holds more than BACKLOG_LIMIT bytes (the WebSocket's queue plus RelayBridge's held packets), no
## world data goes at all: the network is slower than the budget.

const RATE := 32 * 1024          # bytes a second per guest: 256 kbit/s while catching up
const BURST := 4 * 1024          # bytes at once (about 30 ms at a phone's 1 Mbit/s upload)
const BACKLOG_LIMIT := 16 * 1024

var _tokens := {}   # peer -> float (may be below zero: a debt)
var _at := {}       # peer -> seconds of the last refill


## Bytes of world data this guest may be sent now (0: wait).
func budget(peer: int, now: float, backlog: int) -> int:
	if not _tokens.has(peer):
		_tokens[peer] = float(BURST)
		_at[peer] = now
	var t := minf(float(BURST), float(_tokens[peer]) + maxf(now - float(_at[peer]), 0.0) * RATE)
	_tokens[peer] = t
	_at[peer] = now
	if backlog > BACKLOG_LIMIT or t <= 0.0:
		return 0
	return int(t)


func spend(peer: int, bytes: int) -> void:
	_tokens[peer] = float(_tokens.get(peer, float(BURST))) - bytes


func forget(peer: int) -> void:
	_tokens.erase(peer)
	_at.erase(peer)
