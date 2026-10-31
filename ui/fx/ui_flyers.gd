class_name UiFlyers
extends Control
## Owner #94 (the animations brief §3): the flying pieces over a screen (UiMotion.fly, UiMotion.burst): gold coins and
## stars flying in an arc to their counter (which bumps as each lands), and stars bursting from a right answer. One
## pooled node per screen draws them all in one canvas item (UI draw calls, no new art); it processes only while
## something flies (asleep, it costs nothing). At most MAX pieces: a new one makes the oldest land at once.
## Reduce motion (UiMotion.calm): at most two coins, flying straight; half the stars, slower, not spinning.

signal arrived(kind: StringName)

const COIN := &"coin"
const STAR := &"star"
const STAR_GOLD := Color("ffd23f")
const RIM := Color("c99a12")
const EDGE := Color(0.12, 0.1, 0.05, 0.55)
const FLIGHT := 0.6
const STAGGER := 0.07
const MOST_AT_ONCE := 8
const BURST_LIFE := 0.75
const BURST_SPEED := 280.0
const GRAVITY := 520.0
const MAX := 24
const PIECE := 30.0


class Piece:
	var kind: StringName
	var burst := false
	var from := Vector2.ZERO
	var bend := Vector2.ZERO
	var to := Vector2.ZERO
	var target: Control
	var at := Vector2.ZERO
	var vel := Vector2.ZERO
	var age := 0.0          # < 0 while it waits its turn
	var life := FLIGHT
	var angle := 0.0
	var spin := 0.0
	var color := STAR_GOLD
	var size := PIECE


static var _star: PackedVector2Array
static var _star_edge: PackedVector2Array

var _pieces: Array[Piece] = []


func _init() -> void:
	top_level = true   # never laid out by a container; it draws in the screen's coordinates
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	process_mode = Node.PROCESS_MODE_ALWAYS   # over a paused game too


func _ready() -> void:
	set_process(not _pieces.is_empty())


## Pieces in the air (or waiting to start).
func alive() -> int:
	return _pieces.size()


## `count` (1-8) coins or stars from `from` (global) to `target`; each bumps it and says `arrived` as it lands.
func fly(from: Vector2, target: Control, count: int, kind: StringName) -> void:
	var calm := UiMotion.calm()
	var n := clampi(count, 1, 2 if calm else MOST_AT_ONCE)
	var to := target.get_global_rect().get_center()
	for i in n:
		var p := Piece.new()
		p.kind = kind
		p.from = from
		p.to = to
		p.target = target
		p.age = -i * STAGGER
		var side := (to - from).orthogonal().normalized() * (70.0 + 30.0 * (i % 3)) * (1.0 if i % 2 == 0 else -1.0)
		p.bend = from.lerp(to, 0.5) + (Vector2.ZERO if calm else side)
		p.size = PIECE if kind == COIN else PIECE * 1.1
		_add(p)
	_wake()


## `count` stars bursting from `at` (global), falling a little and fading.
func burst(at: Vector2, count: int, color: Color = STAR_GOLD) -> void:
	var calm := UiMotion.calm()
	var n := FeelRules.burst_amount(clampi(count, 1, 12), calm)
	for i in n:
		var p := Piece.new()
		p.kind = STAR
		p.burst = true
		p.at = at
		var a := -PI * 0.5 + TAU * i / n + 0.3 * sin(i * 2.3)
		p.vel = Vector2(cos(a), sin(a)) * BURST_SPEED * (0.8 + 0.2 * (i % 3)) * FeelRules.burst_speed_scale(calm)
		p.life = BURST_LIFE
		p.spin = 0.0 if calm else (5.0 if i % 2 == 0 else -5.0)
		p.color = color
		p.size = PIECE * 0.8
		_add(p)
	_wake()


func _add(p: Piece) -> void:
	while _pieces.size() >= MAX:
		_land(_pieces.pop_front())
	_pieces.append(p)


func _wake() -> void:
	if is_inside_tree():
		set_process(true)
		queue_redraw()


func _process(delta: float) -> void:
	step(delta)


## Moves every piece `delta` seconds on (tests step it by hand).
func step(delta: float) -> void:
	for i in range(_pieces.size() - 1, -1, -1):
		var p := _pieces[i]
		p.age += delta
		if p.age < 0.0:
			continue
		p.angle += p.spin * delta
		if p.burst:
			p.vel.y += GRAVITY * delta
			p.at += p.vel * delta
		else:
			if is_instance_valid(p.target) and p.target.is_visible_in_tree():
				p.to = p.target.get_global_rect().get_center()   # it may be laid out, or move, while they fly
			var k := smoothstep(0.0, 1.0, minf(p.age / p.life, 1.0))
			p.at = p.from.lerp(p.bend, k).lerp(p.bend.lerp(p.to, k), k)   # a curve through the bend
		if p.age >= p.life:
			_pieces.remove_at(i)
			if not p.burst:
				_land(p)
	queue_redraw()
	if _pieces.is_empty():
		set_process(false)


func _land(p: Piece) -> void:
	if p.burst:
		return
	if is_instance_valid(p.target):
		UiMotion.bump(p.target)
	arrived.emit(p.kind)


func _draw() -> void:
	for p in _pieces:
		if p.age < 0.0:
			continue
		var alpha := 1.0 - pow(p.age / p.life, 2.0) if p.burst else 1.0
		var grow := 1.0 if p.burst else lerpf(0.7, 1.0, minf(p.age / (p.life * 0.3), 1.0))
		if p.kind == COIN:
			var r := p.size * 0.5 * grow
			draw_circle(p.at, r, Color(RIM, alpha))
			draw_circle(p.at, r * 0.8, Color(STAR_GOLD, alpha))
			draw_arc(p.at, r * 0.55, 0.0, TAU, 16, Color(RIM, alpha), maxf(1.0, r * 0.1))
			draw_circle(p.at + Vector2(-r * 0.3, -r * 0.3), r * 0.16, Color(1, 1, 1, 0.6 * alpha))
		else:
			draw_set_transform(p.at, p.angle, Vector2.ONE * p.size * 0.5 * grow)
			draw_colored_polygon(star_shape(), Color(p.color, alpha))
			draw_polyline(_star_edge, Color(EDGE, EDGE.a * alpha), 0.12)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A five-pointed star of radius 1, made once (and its closed outline).
static func star_shape() -> PackedVector2Array:
	if _star.is_empty():
		for i in 10:
			var a := -PI / 2.0 + i * PI / 5.0
			_star.append(Vector2(cos(a), sin(a)) * (1.0 if i % 2 == 0 else 0.45))
		_star_edge = _star.duplicate()
		_star_edge.append(_star[0])
	return _star
