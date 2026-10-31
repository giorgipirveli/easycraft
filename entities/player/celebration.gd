class_name Celebration
extends RefCounted
## The victory celebration's confetti (M3 Task 9, spec §13.6): a burst of many-coloured cubes over a
## player's head, made with the shared particle material (Fx) and one shared colour gradient.

const COLORS: Array[Color] = [Color("ef5350"), Color("ffee58"), Color("66bb6a"), Color("42a5f5"), Color("ab47bc"),
	Color("ffa726"), Color("f06292")]

static var _confetti: Gradient


## Confetti bursting up and floating down around `pos` (a body `size` times the normal size).
static func confetti(parent: Node, pos: Vector3, size: float = 1.0) -> CPUParticles3D:
	var p := Fx.burst(parent, pos, Color.WHITE, 48, 6.5 * sqrt(size), 0.09 * size, 1.8, 5.0, 40.0)
	p.color_initial_ramp = confetti_colors()
	p.damping_min = 1.5
	p.damping_max = 3.0
	return p


static func confetti_colors() -> Gradient:
	if _confetti == null:
		_confetti = gradient(COLORS)
	return _confetti


## A gradient of hard steps (each particle picks one colour, never a blend).
static func gradient(colors: Array) -> Gradient:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in colors.size():
		offsets.append(float(i) / colors.size())
		cols.append(colors[i])
	g.offsets = offsets
	g.colors = cols
	return g
