class_name JumpCounter
extends RefCounted
## Multi-jump rules: max_jumps total (1 from the ground + the rest in the air; 2 = double jump,
## 3 = triple jump, the default), with coyote time
## (a ground jump shortly after walking off an edge) and a jump buffer (a press shortly
## before landing still counts). Call press_jump() on input, then tick() once per physics frame.

const MIN_JUMPS := 2
const MAX_JUMPS := 3
const COYOTE_TIME := 0.1
const BUFFER_TIME := 0.1

var max_jumps := MAX_JUMPS
var jumps_used := 0
var _air_time := 0.0
var _buffer_left := 0.0


func press_jump() -> void:
	_buffer_left = BUFFER_TIME


## Returns true when a jump must happen this frame.
func tick(delta: float, on_floor: bool) -> bool:
	if on_floor:
		jumps_used = 0
		_air_time = 0.0
	else:
		_air_time += delta
		# Walking off an edge (not jumping) spends the ground jump once coyote time is over.
		if jumps_used == 0 and _air_time > COYOTE_TIME:
			jumps_used = 1
	var jump := false
	if _buffer_left > 0.0 and jumps_used < max_jumps:
		jumps_used += 1
		_buffer_left = 0.0
		jump = true
	_buffer_left = maxf(_buffer_left - delta, 0.0)
	return jump


func reset() -> void:
	jumps_used = 0
	_air_time = 0.0
	_buffer_left = 0.0
