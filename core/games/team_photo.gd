class_name TeamPhoto
extends RefCounted
## The team photo after a boss as pure rules (M4 Wave 3, agent H; spec §17.5, research T5). When a boss
## is beaten, the offer (a TEAM PHOTO button) stays OFFER_TIME; the one who taps it stands in the middle
## of a line of everyone within NEAR of them (players and bot friends), SPACING apart, across the way they
## face; a camera stands in front of the line, far enough to see all of them and never inside a block;
## at EMOTE_AT everyone cheers and at SHOT_AT photo mode takes the picture on every child's own game.

const OFFER_TIME := 20.0
const NEAR := 24.0
const SPACING := 1.4
const EMOTE := &"cheer"
const EMOTE_AT := 1.6             # seconds after the line-up: everyone cheers
const SHOT_AT := 2.4              # ... and the shutter, while the cheer plays
const CAMERA_HEIGHT := 1.7        # above the line's feet
const LOOK_HEIGHT := 1.0          # the camera looks at the line's middle, this high
const MIN_DISTANCE := 2.5
const EDGE := 0.8                 # room beside the outermost body
const ASPECT := 16.0 / 9.0        # the narrowest landscape phone
const STEP := 0.5


static func offer_open(now: float, offered_at: float) -> bool:
	return offered_at >= 0.0 and now >= offered_at and now - offered_at < OFFER_TIME


static func is_near(center: Vector3, pos: Vector3) -> bool:
	return pos.is_finite() and center.distance_to(pos) <= NEAR


## Who stands where, left to right: the one who asked in the middle, the others around them.
static func order(keys: Array[String], asker: String) -> Array[String]:
	var others: Array[String] = []
	for k in keys:
		if k != asker:
			others.append(k)
	var line: Array[String] = []
	line.resize(keys.size())
	var slots := _slots(keys.size())
	var queue: Array[String] = []
	if keys.has(asker):
		queue.append(asker)
	queue.append_array(others)
	for i in queue.size():
		line[slots[i]] = queue[i]
	return line


## Slot indices from the middle outwards: m, m - 1, m + 1, m - 2, ...
static func _slots(n: int) -> Array[int]:
	var m := n / 2
	var out: Array[int] = [m]
	var d := 1
	while out.size() < n:
		if m - d >= 0:
			out.append(m - d)
		if m + d < n and out.size() < n:
			out.append(m + d)
		d += 1
	return out


## The feet of `count` bodies in a line centred on `center`, across the way `yaw` faces.
static func line_up(center: Vector3, yaw: float, count: int) -> Array[Vector3]:
	var right := Basis(Vector3.UP, yaw) * Vector3.RIGHT
	var out: Array[Vector3] = []
	for i in count:
		out.append(center + right * ((float(i) - float(count - 1) * 0.5) * SPACING))
	return out


## Where the camera stands and looks for a line of `count` (vertical field of view `fov`, degrees): in
## front, far enough that the whole line fits a 16:9 picture; moved closer (not under MIN_DISTANCE)
## while its spot is inside a block. is_solid(cell) -> bool.
static func camera_view(center: Vector3, yaw: float, count: int, fov: float, is_solid: Callable) -> Transform3D:
	var forward := Basis(Vector3.UP, yaw) * Vector3.FORWARD
	var half_width := float(maxi(count - 1, 0)) * 0.5 * SPACING + EDGE
	var half_h := atan(tan(deg_to_rad(fov * 0.5)) * ASPECT)
	var dist := maxf(half_width / tan(half_h) + 1.0, MIN_DISTANCE)
	var look := center + Vector3(0, LOOK_HEIGHT, 0)
	var at := center + forward * dist + Vector3(0, CAMERA_HEIGHT, 0)
	while dist > MIN_DISTANCE and bool(is_solid.call(Vector3i(at.floor()))):
		dist = maxf(dist - STEP, MIN_DISTANCE)
		at = center + forward * dist + Vector3(0, CAMERA_HEIGHT, 0)
	return Transform3D(Basis(), at).looking_at(look, Vector3.UP)


## The way the bodies turn (an avatar's yaw, like Player's `Avatar:rotation`): towards the camera, which
## stands where `yaw` looks.
static func face_yaw(yaw: float) -> float:
	return wrapf(yaw, -PI, PI)
