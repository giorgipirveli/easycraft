class_name WalletReport
extends RefCounted
## Survivor gold changes of one player in an online world, reported to the server's wallet ledger
## (wallet_award; M4 Wave 2, agent F; spec §17.1, §17.6). The host's game decides gold during play
## (§7.3) and reports every change of every player in its match (OnlineWallets); the server keeps
## the balance and limits it per player. Changes are batched: one report BATCH_MSEC after the first
## unsent change, earned and spent netted; a gain goes in pieces the server takes at once, a spend
## as one report (the server checks the balance).

const BATCH_MSEC := 5_000
## The server's limit for one award (WalletRules.AWARD_MAX_BASE), times 2^(universe − 1).
const AWARD_MAX_BASE := 2000
const MAX_UNIVERSE := 12

var pending := 0
## The gold-double bug's leftover (module 0.2.19, docs/devlog/parts/gold-double.md): every change counted (1, 2, 3,
## ...). The host tells a guest's game each move with its count and sends the count with the last piece of the batch
## (OnlineService.send_wallet_report): the guest's game knows when the server has every move it was told.
var seq := 0
## The count the server has heard (or refused: the host never sends that piece again).
var sent_seq := 0
var _since := -1   # when the first change not taken yet came (-1: none)


func add(amount: int, now_msec: int) -> void:
	if amount == 0:
		return
	if _since < 0:
		_since = now_msec
	pending += amount
	seq += 1


## Changes (or their count) the server has not heard yet.
func unsent() -> bool:
	return pending != 0 or seq > sent_seq


func due(now_msec: int) -> bool:
	return unsent() and _since >= 0 and now_msec - _since >= BATCH_MSEC


## Everything pending: gains in pieces of at most max_award(universe), a spend whole; pending is then 0.
func take(universe: int) -> Array[int]:
	var out: Array[int] = []
	if pending < 0:
		out.append(pending)
		pending = 0
	var cap := max_award(universe)
	while pending > 0:
		var piece := mini(pending, cap)
		out.append(piece)
		pending -= piece
	_since = -1
	return out


## A piece the network lost (maybe the count alone, 0): it goes with the next batch, with the count. No new change.
func give_back(amount: int, now_msec: int) -> void:
	if _since < 0:
		_since = now_msec
	pending += amount


static func max_award(universe: int) -> int:
	return AWARD_MAX_BASE << (clampi(universe, 1, MAX_UNIVERSE) - 1)
