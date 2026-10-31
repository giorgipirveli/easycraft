class_name SchoolPictureMotion
extends RefCounted
## Owner #94 (the animations brief §4): the School's pictures that teach motion. It says which kinds move and how (the
## rules the moving pictures follow, which the tests check), and draws the kinds made for motion. A SchoolPicture's
## `time` is what they draw (SchoolPicture.time_of); time 0 is every kind's still picture, so a picture that never plays
## looks as it always did. The data's "animate": false keeps any picture still.
##
## Existing kinds that move (drawn in their own files, reading the time):
## - gears: each gear turns its way (gear_turns), the small ones faster (by the teeth: gear_spin); their marks go round.
## - pulleys {sizes}: the wheels' spokes turn with the belt, the small wheel faster (pulley_spin). A lift stays still.
## - cam: the cam turns clockwise (60 degrees a second from its `turn`), the follower rides up and down, the graph's
##   dot runs along its line.
## - lever: the effort pushes its end down and the load's end rises, and back (lever_tilt), when the pivot is between
##   them (the picture's arrow always pushes down, which would push a load between down too: those stay still).
## - circuit {lit, switch closed}: the current's dots flow round the wire from the cell's + end (circuit_way); a motor's
##   fan spins.
## - food_web: a dot of energy runs along every arrow, from the food to what eats it.
## - wave (without labels: the labels point at a still crest): the waves travel to the right; more waves in the band
##   (a higher pitch) go up and down faster at the same speed.
##
## Kinds made for motion, and their fields:
## - water_cycle {labels? (true, the default: the four STAGES named), hide? (a STAGE shown "?"), sun? (true, the
##   default)}: the sea, a hill, a cloud and the Sun: vapour rises from the sea (evaporation), gathers into the cloud
##   (condensation), rain falls on the hill (precipitation) and a river runs back to the sea (collection).
## - moon_phases {show? ("orbit", the default: the Moon going round the Earth, lit from the Sun on the left, and beside
##   it the Moon as it looks from Earth; "row": the eight PHASES in a row), phase? (0-7, 0 the new moon: where the still
##   picture has the Moon, or the row's ringed phase), names? (the phase's name under the Moon from Earth, or every
##   phase's in the row), hide? (0-7, the row only: that phase's name "?")}: the Moon goes round once in MONTH seconds.
## - orbit {centre? ("sun", the default, or "earth"), planets? (the Sun's: 1-4 of PLANETS, default ["Earth"]), moon?
##   (the Moon round the Earth, when the Earth is there), arrows? (on the first body: gravity's pull towards the centre
##   and its speed along its orbit), labels? (every body named)}: planets nearer the Sun go round faster (the real
##   years' ratios, ORBIT_PERIODS; the orbits' sizes are not to scale).
## - pendulum {lengths? (1-3 pendulums side by side, each 1-3: short, middle, long; default [2]), swing? (5-45 degrees,
##   default 30), labels? (pivot, string and bob named; with two or three, each one's length), energy? (one pendulum
##   only: bars of its kinetic and potential energy)}: a longer pendulum swings more slowly (its period grows with the
##   square root of its length, pendulum_period); the still picture has each at the end of its swing.
## - rocket_stages {stages? (2 or 3, default 3), step? (0 to stages - 1: the stages already dropped in the still
##   picture), labels? (each stage and the capsule named)}: the rocket climbs; each stage burns, falls away when empty,
##   and the next one fires; the sky turns black as it climbs.

const KINDS: Array[String] = ["water_cycle", "moon_phases", "orbit", "pendulum", "rocket_stages"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const GOLD := Color("ffd23f")
const SKY := Color("d6ecff")
const SPACE := Color("141a33")
const SEA := Color("3f8fd8")
const LAND := Color("7cbf5a")
const RIVER := Color("4aa3f0")
const SUN := Color("ffc93c")
const MOON_LIT := Color("f4f1de")
const MOON_DARK := Color("3a3f55")
const HIGH_SKY := Color("3f6fc4")

const STAGES: Array[String] = ["evaporation", "condensation", "precipitation", "collection"]
const PHASES: Array[String] = ["new moon", "waxing crescent", "first quarter", "waxing gibbous", "full moon",
	"waning gibbous", "last quarter", "waning crescent"]
const MOON_SHOWS: Array[String] = ["orbit", "row"]
const CENTRES: Array[String] = ["sun", "earth"]
const PLANETS: Array[String] = ["Mercury", "Venus", "Earth", "Mars"]
const PLANET_COLORS: Array[Color] = [Color("a8a8a8"), Color("e8c77a"), Color("3a7be8"), Color("d65a3a")]
const LENGTH_NAMES: Array[String] = ["short", "middle", "long"]
const SWING := Vector2(5, 45)

# --- How fast things move (seconds, or per second) ---------------------------------------------------------------
## Gears: teeth passing the meshing point in a second (every gear in a row shares it: the small ones turn faster).
const GEAR_TEETH_PER_S := 3.0
## Pulleys: the belt's speed, in wheel sizes a second.
const BELT_PER_S := 2.0
const CAM_DEG_PER_S := 60.0
## A lever pushes down and comes back in this many seconds, tipping at most LEVER_TILT degrees.
const LEVER_CYCLE := 2.4
const LEVER_TILT := 9.0
## A wave crosses its band in this many seconds (the same speed for every wave).
const WAVE_CROSS := 4.0
const CURRENT_PX_S := 45.0
## A dot of energy runs along a food web's arrow in this many seconds.
const WEB_TRIP := 1.6
## Motion fades in over its first moments, so time 0 is the still picture (the flowing dots start unseen).
const FADE_IN := 0.4
## The Moon goes round the Earth once in this many seconds (the phases picture).
const MONTH := 16.0
## A turn round the Sun, in seconds: the real years' ratios (Mercury 0.24, Venus 0.62, Earth 1, Mars 1.88 years).
const ORBIT_PERIODS: Array[float] = [2.4, 6.2, 10.0, 18.8]
## The Moon round the Earth in the orbit picture (not to scale: its real month would be a blur beside the year).
const MOON_ORBIT := 4.0
const MOON_ORBIT_ALONE := 8.0
## The period of a pendulum of length 1 (seconds).
const PENDULUM_BASE := 1.3
const ROCKET_BURN := 2.4
const ROCKET_COAST := 2.2
const ROCKET_FALL := 1.2
## "Nothing falling" (rocket_state's `since`).
const NOT_FALLING := 99.0


# --- Which pictures move -------------------------------------------------------------------------------------------

## True when a good picture `d` has motion to show (SchoolPicture.animates also checks the data and "animate").
static func moves(d: Dictionary) -> bool:
	var kind := str(d.get("kind", ""))
	match kind:
		"gears", "cam", "food_web":
			return true
		"pulleys":
			return d.has("sizes")
		"lever":
			var pivot := float(d.get("pivot", 0))
			return (float(d.get("load", 0)) - pivot) * (float(d.get("effort", 0)) - pivot) < 0.0
		"circuit":
			return bool(d.get("lit", false)) and str(d.get("switch", "closed")) == "closed"
		"wave":
			var labels: Variant = d.get("labels", [])
			return labels is Array and (labels as Array).is_empty()
	return KINDS.has(kind)


# --- The rules the moving pictures follow --------------------------------------------------------------------------

## How far gear `i` of a row with `teeth` has turned after `t` seconds, in radians on the page (> 0 clockwise): meshing
## gears turn opposite ways (SchoolPictureG5Life.gear_turns) and a gear with fewer teeth turns faster.
static func gear_spin(teeth: Array, i: int, turn: String, t: float) -> float:
	var ways := SchoolPictureG5Life.gear_turns(turn if turn != "" else "cw", teeth.size())
	return (1.0 if str(ways[i]) == "cw" else -1.0) * TAU * GEAR_TEETH_PER_S * t / float(teeth[i])


## How far pulley `i` of two has turned after `t` seconds (radians, > 0 clockwise): the belt turns the small wheel faster.
static func pulley_spin(sizes: Array, i: int, turn: String, crossed: bool, t: float) -> float:
	var ways := SchoolPictureG5Life.pulley_turns(turn if turn != "" else "cw", crossed)
	return (1.0 if str(ways[i]) == "cw" else -1.0) * BELT_PER_S * t / float(sizes[i])


## The cam's turn (degrees, clockwise) after `t` seconds, from its picture's `turn`.
static func cam_turn(d: Dictionary, t: float) -> float:
	return fposmod(float(d.get("turn", 0)) + CAM_DEG_PER_S * t, 360.0)


## The lever's tilt about its pivot (radians, > 0 clockwise on the page) after `t` seconds: the effort's end goes down.
static func lever_tilt(d: Dictionary, t: float) -> float:
	var way := signf(float(d.get("effort", 0)) - float(d.get("pivot", 0)))
	return way * deg_to_rad(LEVER_TILT) * (0.5 - 0.5 * cos(TAU * t / LEVER_CYCLE))


## A wave of `count` wavelengths in its band, `t` seconds on: its phase (radians; SchoolPicture.wave_line).
static func wave_phase(count: int, t: float) -> float:
	return TAU * count * t / WAVE_CROSS


## The way the current goes round a circuit of `parts` (SchoolPictureG4Life.SLOTS, clockwise from the top): 1
## clockwise, -1 anticlockwise. A cell's + end points along the wire's way on the top, right and left edges and against
## it on the bottom one (its parts are drawn left to right there).
static func circuit_way(parts: Array) -> int:
	var slots: Array = SchoolPictureG4Life.SLOTS.get(parts.size(), [])
	for i in mini(parts.size(), slots.size()):
		if str(parts[i]) == "cell":
			return -1 if int(slots[i][0]) == 2 else 1
	return 1


## How far round its month the Moon is after `t` seconds (0 new moon, 0.5 full), from the picture's `phase`.
static func moon_month(d: Dictionary, t: float) -> float:
	return fposmod(int(d.get("phase", 0)) / 8.0 + t / MONTH, 1.0)


## The nearest of the eight PHASES to a point in the month.
static func phase_index(month: float) -> int:
	return posmod(roundi(month * 8.0), 8)


## A pendulum's period (seconds): four times as long swings half as fast.
static func pendulum_period(length: float) -> float:
	return PENDULUM_BASE * sqrt(length)


## A pendulum's angle from straight down (radians, > 0 to the right) after `t` seconds, starting at the end of its swing.
static func pendulum_angle(length: float, swing_deg: float, t: float) -> float:
	return deg_to_rad(swing_deg) * cos(TAU * t / pendulum_period(length))


## The rocket after `t` seconds, from its still picture's `step`: `dropped` stages have fallen away (the top one never
## does), `since` seconds ago the last dropped (NOT_FALLING when none is falling now), `burning` (a stage fires) and
## `climb` (0 on the pad, 1 high in space). Then it starts again.
static func rocket_state(stages: int, step: int, t: float) -> Dictionary:
	var cycle := ROCKET_BURN * stages + ROCKET_COAST
	var at := fposmod(step * ROCKET_BURN + t, cycle)
	var dropped := mini(int(at / ROCKET_BURN), stages - 1)
	var since := at - dropped * ROCKET_BURN
	if dropped == 0 or since >= ROCKET_FALL or t <= since:
		since = NOT_FALLING   # the still picture's stages are gone already; a drop is seen only as it happens
	return {"dropped": dropped, "since": since, "burning": at < ROCKET_BURN * stages, "climb": at / cycle}


# --- The data ------------------------------------------------------------------------------------------------------

static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"water_cycle":
			if p.has("hide") and not STAGES.has(str(p.hide)):
				return "hide is one of %s" % [STAGES]
			return _bool_problem(p, ["labels", "sun"])
		"moon_phases":
			var show := str(p.get("show", "orbit"))
			if not MOON_SHOWS.has(show):
				return "show is one of %s" % [MOON_SHOWS]
			if p.has("phase") and not _whole_in(p.phase, 0, 7):
				return "phase is 0-7 (0 the new moon)"
			if p.has("hide") and (show != "row" or not _whole_in(p.hide, 0, 7)):
				return "hide is 0-7, in a row"
			return _bool_problem(p, ["names"])
		"orbit":
			var centre := str(p.get("centre", "sun"))
			if not CENTRES.has(centre):
				return "centre is one of %s" % [CENTRES]
			if p.has("planets"):
				if centre != "sun":
					return "planets go round the Sun"
				var list: Variant = p.planets
				if not list is Array or (list as Array).is_empty() or (list as Array).size() > PLANETS.size():
					return "planets: 1-%d of %s" % [PLANETS.size(), PLANETS]
				var seen := {}
				for n: Variant in list:
					if not PLANETS.has(str(n)) or seen.has(str(n)):
						return "planets: different ones of %s" % [PLANETS]
					seen[str(n)] = true
			if p.has("moon") and centre == "sun" and not _planets(p).has("Earth"):
				return "the Moon goes round the Earth"
			return _bool_problem(p, ["moon", "arrows", "labels"])
		"pendulum":
			var lengths: Variant = p.get("lengths", [2])
			if not lengths is Array or (lengths as Array).is_empty() or (lengths as Array).size() > 3:
				return "1-3 pendulums"
			for l: Variant in lengths:
				if not _whole_in(l, 1, 3):
					return "a pendulum's length is 1-3"
			if p.has("swing") and (not _number(p.swing) or float(p.swing) < SWING.x or float(p.swing) > SWING.y):
				return "swing is %d-%d degrees" % [SWING.x, SWING.y]
			if bool(p.get("energy", false)) and (lengths as Array).size() != 1:
				return "energy bars for one pendulum"
			return _bool_problem(p, ["labels", "energy"])
		"rocket_stages":
			var stages: Variant = p.get("stages", 3)
			if not _whole_in(stages, 2, 3):
				return "stages is 2 or 3"
			if p.has("step") and not _whole_in(p.step, 0, int(stages) - 1):
				return "step is 0 to stages - 1"
			return _bool_problem(p, ["labels"])
	return ""


static func _planets(p: Dictionary) -> Array:
	var chosen: Variant = p.get("planets", ["Earth"])
	var out: Array = []
	for name: String in PLANETS:   # from the Sun out, whatever the data's order
		if chosen is Array and (chosen as Array).has(name):
			out.append(name)
	return out


static func _bool_problem(p: Dictionary, keys: Array) -> String:
	for k: String in keys:
		if p.has(k) and not p[k] is bool:
			return "%s is true or false" % k
	return ""


static func _number(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


static func _whole_in(v: Variant, lo: int, hi: int) -> bool:
	return _number(v) and float(v) == floorf(float(v)) and int(v) >= lo and int(v) <= hi


# --- Drawing -------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	var t := SchoolPicture.time_of(pic)
	match str(d.kind):
		"water_cycle":
			_draw_water_cycle(pic, font, r, d, t)
		"moon_phases":
			if str(d.get("show", "orbit")) == "row":
				_draw_moon_row(pic, font, r, d, t)
			else:
				_draw_moon_orbit(pic, font, r, d, t)
		"orbit":
			_draw_orbit(pic, font, r, d, t)
		"pendulum":
			_draw_pendulum(pic, font, r, d, t)
		"rocket_stages":
			_draw_rocket(pic, font, r, d, t)


## Dots `gap` pixels apart moving along the polyline `pts` at `speed` pixels a second (backwards when negative). The
## other kinds' files use it too (a circuit's current, a food web's energy).
static func flow_dots(ci: CanvasItem, pts: PackedVector2Array, t: float, speed: float, gap: float, col: Color,
		rad: float) -> void:
	if pts.size() < 2 or gap <= 0.0:
		return
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	if total <= 0.0:
		return
	var s := fposmod(speed * t, gap)
	var seg := 0
	var seg_start := 0.0
	while s < total:
		var seg_len := pts[seg].distance_to(pts[seg + 1])
		while seg < pts.size() - 2 and seg_start + seg_len < s:
			seg_start += seg_len
			seg += 1
			seg_len = pts[seg].distance_to(pts[seg + 1])
		var f := clampf((s - seg_start) / seg_len, 0.0, 1.0) if seg_len > 0.0 else 0.0
		ci.draw_circle(pts[seg].lerp(pts[seg + 1], f), rad, col)
		s += gap


## How much of the flowing motion shows `t` seconds in (0 at the still picture).
static func fade_in(t: float) -> float:
	return clampf(t / FADE_IN, 0.0, 1.0)


# --- water_cycle ---------------------------------------------------------------------------------------------------

static func _draw_water_cycle(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, t: float) -> void:
	var fs := clampi(int(r.size.y * 0.075), 9, 18)
	var at := func(x: float, y: float) -> Vector2: return r.position + Vector2(x * r.size.x, y * r.size.y)
	var show := fade_in(t)
	var line_w := maxf(2.0, r.size.y * 0.012)
	ci.draw_rect(r, SKY)
	var sea_y := 0.74
	ci.draw_rect(Rect2(at.call(0.0, sea_y), Vector2(r.size.x * 0.5, r.size.y * (1.0 - sea_y))), SEA)
	for i in 4:   # little waves on the sea
		var wx: Vector2 = at.call(0.05 + i * 0.11, sea_y + 0.08)
		ci.draw_arc(wx, r.size.y * 0.025, PI * 1.15, PI * 1.85, 8, Color(1, 1, 1, 0.6), 1.5, true)
	var land := PackedVector2Array([at.call(0.44, 1.0), at.call(0.44, sea_y), at.call(0.55, 0.66), at.call(0.7, 0.46),
		at.call(0.82, 0.34), at.call(0.92, 0.42), at.call(1.0, 0.5), at.call(1.0, 1.0)])
	ci.draw_colored_polygon(land, LAND)
	ci.draw_colored_polygon(PackedVector2Array([at.call(0.82, 0.34), at.call(0.855, 0.375), at.call(0.8, 0.37),
		at.call(0.785, 0.365)]), Color.WHITE)   # snow on the top
	var river := PackedVector2Array([at.call(0.8, 0.42), at.call(0.76, 0.52), at.call(0.69, 0.58), at.call(0.62, 0.66),
		at.call(0.53, 0.71), at.call(0.47, sea_y + 0.005)])
	ci.draw_polyline(river, RIVER, maxf(3.0, r.size.y * 0.02), true)
	if show > 0.0:
		flow_dots(ci, river, t, r.size.y * 0.18, r.size.y * 0.09, Color(1, 1, 1, 0.8 * show), maxf(1.5, r.size.y * 0.008))
	_head(ci, at.call(0.465, sea_y + 0.01), (river[river.size() - 1] - river[river.size() - 2]).normalized(),
		maxf(7.0, r.size.y * 0.04), INK)
	if bool(d.get("sun", true)):
		var sc: Vector2 = at.call(0.08, 0.15)
		var sr := r.size.y * 0.075
		for k in 8:
			var a := TAU * k / 8.0 + t * 0.3
			ci.draw_line(sc + Vector2(cos(a), sin(a)) * sr * 1.3, sc + Vector2(cos(a), sin(a)) * sr * 1.75, SUN, 2.0, true)
		ci.draw_circle(sc, sr, SUN)
	# evaporation: wavy lines rising from the sea, vapour going up them
	for i in 3:
		var x := 0.17 + i * 0.1
		var wavy := PackedVector2Array()
		for k in 13:
			var y := sea_y - 0.03 - k * (sea_y - 0.47) / 12.0
			wavy.append(at.call(x + 0.012 * sin(k * 1.4), y))
		ci.draw_polyline(wavy, Color(INK, 0.55), line_w * 0.8, true)
		_head(ci, wavy[wavy.size() - 1], Vector2.UP, maxf(6.0, r.size.y * 0.035), Color(INK, 0.55))
		if show > 0.0:
			flow_dots(ci, wavy, t + i * 0.3, r.size.y * 0.12, r.size.y * 0.1, Color(1, 1, 1, 0.9 * show),
				maxf(1.5, r.size.y * 0.01))
	# condensation: the vapour into the cloud
	var bend := PackedVector2Array()
	for k in 9:
		var f := k / 8.0
		bend.append((at.call(0.4, 0.42) as Vector2).lerp(at.call(0.5, 0.2), f) + Vector2(-sin(f * PI) * r.size.x * 0.03, 0))
	ci.draw_polyline(bend, Color(INK, 0.55), line_w * 0.8, true)
	_head(ci, bend[bend.size() - 1], (bend[bend.size() - 1] - bend[bend.size() - 2]).normalized(),
		maxf(6.0, r.size.y * 0.035), Color(INK, 0.55))
	# the cloud, drifting a little
	var cloud: Vector2 = at.call(0.65 + 0.015 * sin(t * 0.8), 0.17)
	var cr := r.size.y * 0.065
	for o: Vector2 in [Vector2(-1.3, 0.25), Vector2(-0.5, -0.35), Vector2(0.45, -0.2), Vector2(1.25, 0.25), Vector2(0, 0.3)]:
		ci.draw_circle(cloud + o * cr, cr * 0.95, Color("f7f9fc"))
	ci.draw_line(cloud + Vector2(-2.2, 0.95) * cr, cloud + Vector2(2.1, 0.95) * cr, Color("aab4c3"), 1.5)
	# precipitation: rain from the cloud onto the hill
	var rain := Color("2f6fdc")
	var drop := r.size.y * 0.035
	for k in 7:
		var x := 0.575 + k * 0.025
		var top := 0.27
		var bottom := 0.45
		var fall := fposmod(k * 0.37 + t * 1.3, 1.0)
		var y := top + (bottom - top) * fall
		ci.draw_line(at.call(x, y) as Vector2, (at.call(x, y) as Vector2) + Vector2(-drop * 0.25, drop), rain, 2.0, true)
	if not bool(d.get("labels", true)):
		return
	var hide := str(d.get("hide", ""))
	var name := func(stage: String) -> String: return "?" if stage == hide else stage
	_fit_text(ci, font, r, at.call(0.27, 0.43), name.call("evaporation"), fs, INK)
	_fit_text(ci, font, r, at.call(0.65, 0.07), name.call("condensation"), fs, INK)
	_fit_text(ci, font, r, at.call(0.9, 0.23), name.call("precipitation"), fs, INK)
	_fit_text(ci, font, r, at.call(0.72, 0.86), name.call("collection"), fs, INK)


# --- moon_phases ---------------------------------------------------------------------------------------------------

static func _draw_moon_orbit(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, t: float) -> void:
	var fs := clampi(int(r.size.y * 0.07), 9, 18)
	var month := moon_month(d, t)
	ci.draw_rect(r, SPACE)
	_stars(ci, r, 16)
	var left := Rect2(r.position, Vector2(r.size.x * 0.6, r.size.y))
	var earth := left.get_center() + Vector2(left.size.x * 0.06, 0)
	var orbit := minf(left.size.x * 0.34, left.size.y * 0.36)
	for k in 3:   # sunlight from the left
		var y := r.position.y + r.size.y * (0.25 + 0.25 * k)
		_arrow(ci, Vector2(r.position.x + 4, y), Vector2(r.position.x + left.size.x * 0.14, y), SUN, maxf(2.0, fs * 0.16))
	_fit_text(ci, font, r, Vector2(r.position.x + left.size.x * 0.1, r.position.y + fs * 1.1), "sunlight", fs, SUN)
	_dashed_circle(ci, earth, orbit, Color(1, 1, 1, 0.35))
	var er := orbit * 0.3
	ci.draw_circle(earth, er, Color("2f6fdc"))
	ci.draw_circle(earth + Vector2(-er * 0.3, -er * 0.2), er * 0.35, Color("4caf50"))
	ci.draw_circle(earth + Vector2(er * 0.35, er * 0.3), er * 0.25, Color("4caf50"))
	_half_disc(ci, earth, er, false, Color(0, 0, 0, 0.45))   # night on the side away from the Sun
	var a := PI + month * TAU
	var moon := earth + Vector2(cos(a), -sin(a)) * orbit
	var mr := maxf(4.0, orbit * 0.13)
	ci.draw_circle(moon, mr, MOON_DARK)
	_half_disc(ci, moon, mr, true, MOON_LIT)   # the half facing the Sun is lit
	# which way it goes: anticlockwise, seen from above the North Pole
	var ahead := earth + Vector2(cos(a + 0.5), -sin(a + 0.5)) * orbit
	var tangent := Vector2(-sin(a + 0.5), -cos(a + 0.5))
	_head(ci, ahead, tangent, maxf(6.0, fs * 0.6), Color(1, 1, 1, 0.6))
	var right := Rect2(Vector2(r.position.x + r.size.x * 0.62, r.position.y), Vector2(r.size.x * 0.38, r.size.y))
	var big := minf(right.size.x * 0.38, right.size.y * 0.3)
	var c := right.get_center() + Vector2(0, -fs * 0.4)
	_fit_text(ci, font, right, Vector2(c.x, c.y - big - fs * 0.6), "from Earth", fs, Color.WHITE)
	moon_face(ci, c, big, month)
	if bool(d.get("names", false)):
		_fit_text(ci, font, right, Vector2(c.x, c.y + big + fs * 1.3), PHASES[phase_index(month)], fs, Color.WHITE)


static func _draw_moon_row(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, t: float) -> void:
	var names := bool(d.get("names", false))
	var fs := clampi(int(r.size.y * 0.06), 8, 16)
	ci.draw_rect(r, SPACE)
	var room := fs * 2.6 if names else fs * 0.6
	var one := minf(r.size.x / 8.0, r.size.y - room)
	var two := minf(r.size.x / 4.0, r.size.y * 0.5 - room)
	var rows := 2 if two > one * 1.15 else 1
	var cols := 8 / rows
	var cell := Vector2(r.size.x / cols, r.size.y / rows)
	var rad := minf(cell.x * 0.36, (cell.y - room) * 0.42)
	var now := phase_index(moon_month(d, t)) if t > 0.0 or d.has("phase") else -1
	for i in 8:
		var c := r.position + Vector2((i % cols + 0.5) * cell.x, (i / cols) * cell.y + (cell.y - room) * 0.5 + fs * 0.3)
		moon_face(ci, c, rad, i / 8.0)
		if i == now:
			ci.draw_arc(c, rad * 1.22, 0, TAU, 32, ORANGE, maxf(2.0, rad * 0.1), true)
		if names:
			var text := "?" if d.has("hide") and int(d.hide) == i else PHASES[i]
			var words := text.split(" ")
			for k in words.size():
				_fit_text(ci, font, Rect2(c - Vector2(cell.x * 0.5, 0), Vector2(cell.x, 1)),
					Vector2(c.x, c.y + rad * 1.3 + fs * (1.0 + k)), words[k], fs, Color.WHITE)


## The Moon as it looks from Earth `month` of the way round (0 new, 0.5 full): lit on the right as it grows, on the
## left as it shrinks (as seen from the north of the world).
static func moon_face(ci: CanvasItem, c: Vector2, rad: float, month: float) -> void:
	ci.draw_circle(c, rad, MOON_DARK)
	var m := fposmod(month, 1.0)
	if m < 0.012 or m > 0.988:
		ci.draw_arc(c, rad, 0, TAU, 32, Color(1, 1, 1, 0.25), 1.2, true)
		return
	if absf(m - 0.5) < 0.012:
		ci.draw_circle(c, rad, MOON_LIT)
		return
	var pts := PackedVector2Array()
	var n := 20
	if m < 0.5:
		var k := cos(m * TAU)
		for i in n + 1:   # the right edge, top to bottom
			var a := -PI * 0.5 + PI * i / n
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		for i in range(1, n):   # the shadow's edge, back up
			var a := PI * 0.5 - PI * i / n
			pts.append(c + Vector2(k * cos(a) * rad, sin(a) * rad))
	else:
		var k := cos((m - 0.5) * TAU)
		for i in n + 1:   # the left edge, bottom to top
			var a := PI * 0.5 + PI * i / n
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		for i in range(1, n):   # the shadow's edge, back down
			var a := -PI * 0.5 + PI * i / n
			pts.append(c + Vector2(k * cos(a) * rad, sin(a) * rad))
	ci.draw_colored_polygon(pts, MOON_LIT)
	ci.draw_arc(c, rad, 0, TAU, 32, Color(1, 1, 1, 0.3), 1.2, true)


# --- orbit ---------------------------------------------------------------------------------------------------------

static func _draw_orbit(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, t: float) -> void:
	var fs := clampi(int(r.size.y * 0.065), 9, 17)
	var labels := bool(d.get("labels", false))
	var arrows := bool(d.get("arrows", false))
	ci.draw_rect(r, SPACE)
	_stars(ci, r, 22)
	var c := r.get_center()
	# the orbits are ellipses (seen a little from above): the card's width is used, not only its height
	var room := Vector2(r.size.x * 0.47, r.size.y * 0.45) - Vector2.ONE * fs * (1.3 if labels else 0.3)
	var small := minf(room.x, room.y)
	var first := {}   # the body the arrows are on: {at, centre, turn (its way round), size}
	if str(d.get("centre", "sun")) == "earth":
		var er := small * 0.22
		_earth(ci, c, er)
		var orbit := room * 0.85
		_dashed_ellipse(ci, c, orbit, Color(1, 1, 1, 0.3))
		var a := -PI * 0.5 - TAU * t / MOON_ORBIT_ALONE
		var moon := c + Vector2(cos(a) * orbit.x, sin(a) * orbit.y)
		var mr := maxf(4.0, small * 0.07)
		ci.draw_circle(moon, mr, MOON_LIT)
		first = {"at": moon, "centre": c, "turn": Vector2(sin(a) * orbit.x, -cos(a) * orbit.y).normalized(),
			"size": orbit.y}
		if labels:
			_fit_text(ci, font, r, c + Vector2(0, er + fs * 1.2), "Earth", fs, Color.WHITE)
			_body_label(ci, font, r, moon, c, mr, "Moon", fs)
	else:
		var sr := small * 0.14
		ci.draw_circle(c, sr * 1.35, Color(SUN, 0.25))
		ci.draw_circle(c, sr, SUN)
		if labels:
			_fit_text(ci, font, r, c + Vector2(0, fs * 0.35), "Sun", fs, INK)
		var planets := _planets(d)
		var n := planets.size()
		for k in n:
			var p := PLANETS.find(str(planets[k]))
			var share := (sr * 1.7 + (small - sr * 1.7) * (k + 1) / float(n)) / small
			var orbit := room * share
			_dashed_ellipse(ci, c, orbit, Color(1, 1, 1, 0.28))
			var a := -PI * 0.5 + p * 1.9 - TAU * t / ORBIT_PERIODS[p]
			var at := c + Vector2(cos(a) * orbit.x, sin(a) * orbit.y)
			var pr := maxf(3.5, small * (0.06 if p >= 2 else 0.045))
			if first.is_empty() or PLANETS[p] == "Earth":   # the arrows ride the Earth when it is there
				first = {"at": at, "centre": c, "turn": Vector2(sin(a) * orbit.x, -cos(a) * orbit.y).normalized(),
					"size": orbit.y}
			if PLANETS[p] == "Earth" and bool(d.get("moon", false)):
				var mo := maxf(pr * 2.4, 9.0)
				var ma := -TAU * t / MOON_ORBIT
				ci.draw_arc(at, mo, 0, TAU, 20, Color(1, 1, 1, 0.22), 1.0, true)
				ci.draw_circle(at + Vector2(cos(ma), sin(ma)) * mo, maxf(2.0, pr * 0.35), MOON_LIT)
			if PLANETS[p] == "Earth":
				_earth(ci, at, pr)
			else:
				ci.draw_circle(at, pr, PLANET_COLORS[p])
			if labels:
				_body_label(ci, font, r, at, c, pr, PLANETS[p], fs)
	if arrows and not first.is_empty():
		var at: Vector2 = first.at
		var inward := (Vector2(first.centre) - at).normalized()
		var along: Vector2 = first.turn
		var len := clampf(float(first.size) * 0.55, 14.0, small * 0.4)
		var w := maxf(2.0, fs * 0.16)
		_arrow(ci, at + inward * 6.0, at + inward * len, Color("ff6b5a"), w)
		_arrow(ci, at + along * 6.0, at + along * len, Color("7fd4ff"), w)
		_fit_text(ci, font, r, at + inward * len * 0.55 - along * fs * 1.6 + Vector2(0, fs * 0.35), "gravity", fs,
			Color("ff9a8c"))
		_fit_text(ci, font, r, at + along * (len + fs * 1.6) + Vector2(0, fs * 0.35), "speed", fs, Color("a8e2ff"))


## A body's name just outside its orbit (away from the middle), inside the card.
static func _body_label(ci: CanvasItem, font: Font, r: Rect2, at: Vector2, centre: Vector2, rad: float, text: String,
		fs: int) -> void:
	var out := (at - centre).normalized()
	_fit_text(ci, font, r, at + out * (rad + fs * 0.9) + Vector2(0, fs * 0.35), text, fs, Color.WHITE)


static func _earth(ci: CanvasItem, c: Vector2, rad: float) -> void:
	ci.draw_circle(c, rad, Color("2f6fdc"))
	ci.draw_circle(c + Vector2(-rad * 0.3, -rad * 0.2), rad * 0.35, Color("4caf50"))
	ci.draw_circle(c + Vector2(rad * 0.35, rad * 0.3), rad * 0.25, Color("4caf50"))


# --- pendulum ------------------------------------------------------------------------------------------------------

static func _draw_pendulum(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, t: float) -> void:
	var lengths: Array = d.get("lengths", [2])
	var swing := float(d.get("swing", 30))
	var labels := bool(d.get("labels", false))
	var energy := bool(d.get("energy", false))
	var fs := clampi(int(r.size.y * 0.075), 9, 18)
	var n := lengths.size()
	var area := Rect2(r.position, Vector2(r.size.x * (0.66 if energy else 1.0), r.size.y))
	var cell_w := area.size.x / n
	var bob := clampf(r.size.y * 0.06, 5.0, 18.0)
	var top := area.position.y + fs * 0.4
	var foot := fs * 1.5 if (labels or n > 1) else fs * 0.3
	var sw := deg_to_rad(swing)
	# one scale for all, so their lengths compare truly: the longest fits the height, each swing fits its column
	var k := (area.size.y - (top - area.position.y) - bob * 2.0 - foot) / 3.0
	for l: Variant in lengths:
		k = minf(k, (cell_w * 0.5 - bob - 4.0) / (sin(sw) * float(l)))
	ci.draw_rect(Rect2(Vector2(area.position.x + 6.0, top - 5.0), Vector2(area.size.x - 12.0, 5.0)), Color("8a93a0"))
	for i in n:
		var length := float(lengths[i])
		var pivot := Vector2(area.position.x + cell_w * (i + 0.5), top)
		var lp := k * length
		var path := PackedVector2Array()
		for s in 17:
			var a := lerpf(-sw, sw, s / 16.0)
			path.append(pivot + Vector2(sin(a), cos(a)) * lp)
		for s in range(0, 16, 2):
			ci.draw_line(path[s], path[s + 1], Color(INK, 0.3), 1.5, true)
		for end: float in [-sw, sw]:
			ci.draw_circle(pivot + Vector2(sin(end), cos(end)) * lp, bob, Color(ORANGE, 0.18))
		var a := pendulum_angle(length, swing, t)
		var at := pivot + Vector2(sin(a), cos(a)) * lp
		ci.draw_line(pivot, at, INK, 2.0, true)
		ci.draw_circle(at, bob, ORANGE)
		ci.draw_arc(at, bob, 0, TAU, 20, INK, 1.5, true)
		ci.draw_circle(pivot, 3.5, INK)
		if n > 1:
			_fit_text(ci, font, r, Vector2(pivot.x, r.end.y - fs * 0.3), LENGTH_NAMES[int(length) - 1], fs, INK)
		if labels and i == 0:
			ci.draw_string(font, pivot + Vector2(8.0, fs * 1.0), "pivot", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
			var mid := pivot + Vector2(0, lp * 0.55)
			ci.draw_string(font, mid + Vector2(lp * sin(sw) * 0.55 + 6.0, 0), "string", HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
				Color(INK, 0.8))
			if n == 1:
				_fit_text(ci, font, r, Vector2(pivot.x, pivot.y + lp + bob + fs * 1.2), "bob", fs, INK)
	if energy:
		var a := pendulum_angle(float(lengths[0]), swing, t)
		var high := (1.0 - cos(a)) / maxf(1.0 - cos(sw), 0.0001)   # how high the bob is: its potential energy
		var bars := Rect2(Vector2(r.position.x + r.size.x * 0.7, r.position.y + fs * 0.6),
			Vector2(r.size.x * 0.3, r.size.y - fs * 2.4))
		var bw := bars.size.x * 0.3
		for b in 2:
			var share := 1.0 - high if b == 0 else high
			var x := bars.position.x + bars.size.x * (0.25 + 0.5 * b) - bw * 0.5
			var col := RED if b == 0 else BLUE
			ci.draw_rect(Rect2(Vector2(x, bars.position.y), Vector2(bw, bars.size.y)), Color(col, 0.12))
			ci.draw_rect(Rect2(Vector2(x, bars.end.y - bars.size.y * share), Vector2(bw, bars.size.y * share)), col)
			ci.draw_rect(Rect2(Vector2(x, bars.position.y), Vector2(bw, bars.size.y)), INK, false, 1.5)
			_fit_text(ci, font, r, Vector2(x + bw * 0.5, bars.end.y + fs * 1.2), "kinetic" if b == 0 else "potential",
				maxi(8, fs - 2), INK)


# --- rocket_stages -------------------------------------------------------------------------------------------------

static func _draw_rocket(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, t: float) -> void:
	var stages := int(d.get("stages", 3))
	var s := rocket_state(stages, int(d.get("step", 0)), t)
	var climb := float(s.climb)
	var fs := clampi(int(r.size.y * 0.065), 9, 17)
	var dark := clampf(climb * 1.8, 0.0, 1.0)
	var sky := SKY.lerp(HIGH_SKY, dark * 2.0) if dark < 0.5 else HIGH_SKY.lerp(SPACE, dark * 2.0 - 1.0)
	ci.draw_rect(r, sky)
	if dark > 0.5:
		_stars(ci, r, 18, (dark - 0.5) * 2.0)
	var sh := r.size.y * 0.66 / (stages + 1.3)   # a stage's height
	var sw := minf(sh * 0.62, r.size.x * 0.12)
	var cx := r.position.x + r.size.x * (0.4 if bool(d.get("labels", false)) else 0.5)
	var ground := r.end.y - r.size.y * 0.08
	var lift := smoothstep(0.0, 0.2, climb)
	var base := lerpf(ground, r.position.y + r.size.y * 0.74, lift)
	var gone := ground + (climb * r.size.y * 3.0)   # the ground drops away below
	if gone < r.end.y:
		ci.draw_rect(Rect2(Vector2(r.position.x, gone), Vector2(r.size.x, r.end.y - gone)), Color("7cbf5a"))
		var tower := Rect2(Vector2(cx - sw * 1.3, gone - sh * (stages + 0.8)), Vector2(sw * 0.35, sh * (stages + 0.8)))
		if tower.end.y > r.position.y:
			ci.draw_rect(tower, Color(INK, 0.6), false, 1.5)
			for k in int(stages + 1):
				ci.draw_line(Vector2(tower.position.x, tower.position.y + k * sh), Vector2(tower.end.x,
					tower.position.y + (k + 1) * sh), Color(INK, 0.45), 1.0)
	var dropped := int(s.dropped)
	if bool(s.burning):
		var flick := 0.85 + 0.15 * sin(t * 40.0)
		var fl := sh * 0.9 * flick
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - sw * 0.35, base), Vector2(cx + sw * 0.35, base),
			Vector2(cx, base + fl)]), ORANGE)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - sw * 0.18, base), Vector2(cx + sw * 0.18, base),
			Vector2(cx, base + fl * 0.6)]), GOLD)
	for i in range(dropped, stages):
		var y := base - (i - dropped + 1) * sh
		_stage(ci, Rect2(Vector2(cx - sw * 0.5, y), Vector2(sw, sh)), i, i == stages - 1)
	if float(s.since) < ROCKET_FALL:   # the stage that just dropped, falling away and turning
		var f := float(s.since)
		var box := Rect2(Vector2(cx - sw * 0.5, base), Vector2(sw, sh))
		var turn := f * 0.9
		var drop := Vector2(-f * r.size.x * 0.06, f * r.size.y * 0.12 + f * f * r.size.y * 0.1)
		var centre := box.get_center()
		ci.draw_set_transform_matrix(Transform2D(turn, centre + drop - centre.rotated(turn)))
		_stage(ci, box, dropped - 1, false, 1.0 - f / ROCKET_FALL)
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	if bool(d.get("labels", false)):
		for i in range(dropped, stages):
			var y := base - (i - dropped + 0.5) * sh
			ci.draw_line(Vector2(cx + sw * 0.6, y), Vector2(cx + sw * 1.1, y), Color(INK if dark < 0.5 else Color.WHITE, 0.6), 1.2)
			ci.draw_string(font, Vector2(cx + sw * 1.2, y + fs * 0.35), "stage %d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1,
				fs, INK if dark < 0.5 else Color.WHITE)
		var nose := base - (stages - dropped) * sh - sh * 0.3
		ci.draw_string(font, Vector2(cx + sw * 1.2, nose + fs * 0.35), "capsule", HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			ORANGE)


## One stage: a white body with its band; the first has fins, the top one the capsule's cone and window.
static func _stage(ci: CanvasItem, box: Rect2, index: int, top: bool, alpha: float = 1.0) -> void:
	var body := Color(Color("eef1f5"), alpha)
	var edge := Color(INK, alpha)
	ci.draw_rect(box, body)
	var bands: Array[Color] = [Color("d9433b"), Color("3a7be8"), Color("2fae4e")]
	ci.draw_rect(Rect2(box.position + Vector2(0, box.size.y * 0.42), Vector2(box.size.x, box.size.y * 0.16)),
		Color(bands[index % bands.size()], alpha))
	ci.draw_rect(box, edge, false, 1.5)
	if index == 0:
		for sx: float in [-1.0, 1.0]:
			var x := box.position.x if sx < 0.0 else box.end.x
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x, box.end.y - box.size.y * 0.45), Vector2(x, box.end.y),
				Vector2(x + sx * box.size.x * 0.45, box.end.y + box.size.y * 0.08)]), Color(Color("d9433b"), alpha))
	if top:
		var cone := PackedVector2Array([box.position, Vector2(box.end.x, box.position.y),
			Vector2(box.get_center().x, box.position.y - box.size.y * 0.6)])
		ci.draw_colored_polygon(cone, Color(ORANGE, alpha))
		ci.draw_polyline(PackedVector2Array([cone[0], cone[2], cone[1]]), edge, 1.5, true)
		ci.draw_circle(Vector2(box.get_center().x, box.position.y + box.size.y * 0.24), box.size.x * 0.17,
			Color(Color("7fd4ff"), alpha))


# --- Helpers -------------------------------------------------------------------------------------------------------

## A few still stars (the same every draw), fading in with `alpha`.
static func _stars(ci: CanvasItem, r: Rect2, count: int, alpha: float = 1.0) -> void:
	for i in count:
		var x := fposmod(i * 0.6180339 + 0.13, 1.0)
		var y := fposmod(i * 0.3819660 * 2.7 + 0.07, 1.0)
		ci.draw_circle(r.position + Vector2(x * r.size.x, y * r.size.y), 1.2 + (i % 3) * 0.4, Color(1, 1, 1, 0.7 * alpha))


static func _dashed_ellipse(ci: CanvasItem, c: Vector2, radii: Vector2, col: Color) -> void:
	var n := clampi(int((radii.x + radii.y) * 0.2), 16, 56)
	for i in n:
		var a0 := TAU * i / n
		var a1 := a0 + TAU / n * 0.55
		ci.draw_line(c + Vector2(cos(a0) * radii.x, sin(a0) * radii.y), c + Vector2(cos(a1) * radii.x, sin(a1) * radii.y),
			col, 1.5, true)


static func _dashed_circle(ci: CanvasItem, c: Vector2, rad: float, col: Color) -> void:
	var n := clampi(int(rad * 0.4), 12, 48)
	for i in n:
		var a := TAU * i / n
		ci.draw_arc(c, rad, a, a + TAU / n * 0.55, 4, col, 1.5, true)


## Half a disc: the left half (facing the Sun) or the right one.
static func _half_disc(ci: CanvasItem, c: Vector2, rad: float, left: bool, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * 0.5 + PI * i / 12.0 if left else -PI * 0.5 + PI * i / 12.0
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	ci.draw_colored_polygon(pts, col)


static func _arrow(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var dir := (b - a).normalized()
	if dir == Vector2.ZERO:
		return
	var head := w * 3.2
	ci.draw_line(a, b - dir * head * 0.8, col, w, true)
	_head(ci, b, dir, head, col)


static func _head(ci: CanvasItem, tip: Vector2, dir: Vector2, size: float, col: Color) -> void:
	var side := Vector2(-dir.y, dir.x) * size * 0.55
	ci.draw_colored_polygon(PackedVector2Array([tip, tip - dir * size + side, tip - dir * size - side]), col)


## Text centred on `center_base`, moved inside `r` when it would run off it.
static func _fit_text(ci: CanvasItem, font: Font, r: Rect2, center_base: Vector2, text: String, fs: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := clampf(center_base.x - w * 0.5, r.position.x, maxf(r.position.x, r.end.x - w))
	ci.draw_string(font, Vector2(x, center_base.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
