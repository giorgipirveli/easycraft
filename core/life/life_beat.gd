class_name LifeBeat
extends RefCounted
## Owner #112 (docs/design/life-skills.md §5 #1, Little Lifesaver's Big track): hands-only CPR's beat. The ERC 2021 and
## the IFRC 2020 guidelines: push hard and fast in the centre of the chest, 100 to 120 a minute, and let the chest come
## back up (sources: docs/devlog/parts/life-l1-review.md). The rate is read from the last few pushes; in VR a push is
## the hands going down a few centimetres from where they rest and coming back up (Pusher; a controller cannot measure
## a real chest's 5-6 cm, so the game asks for a clear push, not a depth).

const MIN_RATE := 100.0
const MAX_RATE := 120.0
## The coach's beat (the window's middle), a soft tick the child pushes to.
const BEAT_SECONDS := 60.0 / 110.0
## The rate is read over the last this many intervals.
const WINDOW := 5


## Pushes a minute from push times (seconds), over the last WINDOW intervals; 0 with fewer than two pushes.
static func rate(times: Array) -> float:
	if times.size() < 2:
		return 0.0
	var first := maxi(times.size() - 1 - WINDOW, 0)
	var span := float(times[times.size() - 1]) - float(times[first])
	var intervals := times.size() - 1 - first
	return 60.0 * intervals / span if span > 0.0 else 0.0


static func good(r: float) -> bool:
	return r >= MIN_RATE and r <= MAX_RATE


## A push from the hands' height, frame by frame (metres): down DEPTH from where they rest, then up RISE again.
class Pusher:
	extends RefCounted
	const DEPTH := 0.035
	const RISE := 0.02
	## How fast the rest height follows hands that settle lower (a fraction of the gap a frame).
	const SETTLE := 0.02

	var top := NAN
	var bottom := 0.0
	var down := false

	## True at the frame a push ends (the hands came back up).
	func feed(y: float) -> bool:
		if is_nan(top):
			top = y
			return false
		if not down:
			if y > top:
				top = y
			elif top - y >= DEPTH:
				down = true
				bottom = y
			else:
				top -= (top - y) * SETTLE
			return false
		bottom = minf(bottom, y)
		if y - bottom >= RISE:
			down = false
			top = y
			return true
		return false
