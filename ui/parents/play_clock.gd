class_name PlayClock
extends Node
## Counts the time the game is open and in front of the player, per local day (PlayTime), for the
## grown-up area (M4 Wave 2, agent F; spec §5.14 parent corner, §17.2 "see play time"). Menus and the
## pause menu count too (it is screen time); the game in the background does not. Kept on the device
## only (user://play_time.json), saved every SAVE_EVERY seconds, when leaving and when it goes to the
## background. Session makes one (never headless).

const SAVE_EVERY := 60.0

var path := PlayTime.PATH
var record: PlayTime
var day := Callable()        # () -> "YYYY-MM-DD"; default PlayTime.today()
var ticks := Callable()      # () -> msec; default Time.get_ticks_msec

var _active := true
var _last_tick := -1
var _unsaved := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if record == null:
		record = PlayTime.load_from(path)


func _process(_delta: float) -> void:
	tick()


## Adds the time since the last tick (PlayTime caps one step: a long sleep counts nothing).
func tick() -> void:
	var now := int(ticks.call()) if ticks.is_valid() else Time.get_ticks_msec()
	if _last_tick >= 0 and _active:
		var step := (now - _last_tick) / 1000.0
		record.add(step, _today())
		_unsaved += minf(step, PlayTime.MAX_STEP)
		if _unsaved >= SAVE_EVERY:
			save()
	_last_tick = now


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			tick()
			_active = false
			save()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_active = true
			_last_tick = -1   # the time away is not play time
		NOTIFICATION_WM_CLOSE_REQUEST:
			tick()
			save()


func minutes_today() -> int:
	return record.minutes_on(_today()) if record else 0


func save() -> void:
	if record and _unsaved > 0.0:
		record.save_to(path)
		_unsaved = 0.0


func _today() -> String:
	return str(day.call()) if day.is_valid() else PlayTime.today()
