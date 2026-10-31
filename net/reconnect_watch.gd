class_name ReconnectWatch
extends Node
## Owner #95: signs the game in again by itself once the internet is back (ReconnectRules), so what was played offline
## goes up to the account (the profile's backup, gold, codes, invite and learning events: OnlineService.sign_in sends
## them all), and says so once: back_online (the HUD's and the menu's words). Session makes one on the first autostart;
## tests make their own with auto_tick off and call tick(now).

## A try that followed failures succeeded: the child's offline play is on the account now.
signal back_online

var service: OnlineService
## () -> bool: this device has been online before (Session: the safe card seen, or a friend's code kept).
var wanted: Callable = func() -> bool: return false
## () -> bool: a friend's world is rejoining by itself (RejoinRules): no competing sign-in.
var busy: Callable = func() -> bool: return false
## () -> bool: the browser's navigator.onLine (true elsewhere): offline, no try; back online, a try at once.
var online_hint: Callable = func() -> bool: return true
var auto_tick := true

## Failed tries since the last success.
var tries := 0
var _next_at := 0.0
var _trying := false
var _hint_was := true
var _saw_offline := false   # an offline spell this watch has seen (a failed start, a dropped link)


func _process(_delta: float) -> void:
	if auto_tick and not _trying:
		tick(Time.get_ticks_msec() / 1000.0)


func tick(now: float) -> void:
	if service == null or _trying:
		return
	var hint: bool = online_hint.call()
	if hint and not _hint_was:
		_next_at = now   # the browser says online again: try at once
	_hint_was = hint
	if service.status == OnlineService.ONLINE:
		tries = 0
		return
	if service.status == OnlineService.OFFLINE and wanted.call():
		_saw_offline = true
	if not hint or now < _next_at:
		return
	if not ReconnectRules.should_try(wanted.call(), service.status, service.has_server(), busy.call()):
		return
	_trying = true
	var err: String = await service.sign_in()
	_trying = false
	if err == "" and service.status == OnlineService.ONLINE:
		tries = 0
		if _saw_offline:
			_saw_offline = false
			back_online.emit()
		return
	tries += 1
	_next_at = now + ReconnectRules.wait_after(tries)
