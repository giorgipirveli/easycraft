class_name UiMotion
extends RefCounted
## Owner #94 (the animations brief §3): the one motion helper for the menus and the HUD, so every panel feels the same.
## - pop_in(control): a card, panel or page grows from its middle (0.86 -> 1, a little overshoot) and fades in.
## - squash_on_press(button): pressed, a button squashes (wider and flatter); let go, it springs back. Every
##   UiKit.big_button does it (and so every SchoolUi / OnlineUi button).
## - fly(host, from, target, count, kind): gold coins or stars fly from a point to their counter, which bumps as each
##   lands (UiFlyers, one pooled node per screen).
## - burst(host, at, count): a few stars burst from a point (a right answer).
## - glow(control): a level-up glows: it brightens and settles a few times, then is exactly itself again.
## Reduce motion calms all of it: a fade without growing, no squash, half the pieces, slower (UiFlyers).
## Tweens only: nothing runs per frame when nothing moves.

const POP_TIME := 0.24
const POP_FROM := 0.86
const FADE_TIME := 0.16
const SQUASH := Vector2(1.05, 0.9)
const SQUASH_TIME := 0.07
const SPRING_TIME := 0.22
const BUMP := 1.18
const GLOW_TIME := 0.5
const GLOW_PULSES := 3
const GLOW := Color(1.45, 1.4, 1.1)
const _TWEEN := &"ui_motion_tween"


static func calm() -> bool:
	return Profile.data != null and bool(Profile.data.settings.get("reduce_motion", false))


## Grows `c` from its middle and fades it in (a fade only with Reduce motion). Call it when it shows.
## Not yet in the tree: it pops when it enters.
static func pop_in(c: Control, delay: float = 0.0) -> Tween:
	if not c.is_inside_tree():
		if not c.has_meta(&"ui_pop_waits"):
			c.set_meta(&"ui_pop_waits", true)
			c.tree_entered.connect(func() -> void:
				c.remove_meta(&"ui_pop_waits")
				pop_in(c, delay), CONNECT_ONE_SHOT)
		return null
	var tw := _fresh(c)
	c.pivot_offset = c.size * 0.5
	c.modulate.a = 0.0
	if calm():
		c.scale = Vector2.ONE
		tw.tween_property(c, "modulate:a", 1.0, FADE_TIME).set_delay(delay)
		return tw
	c.scale = Vector2.ONE * POP_FROM
	tw.set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, FADE_TIME).set_delay(delay)
	var grow := func(k: float) -> void:   # the pivot follows the size (a container may lay it out after this)
		c.pivot_offset = c.size * 0.5
		c.scale = Vector2.ONE * k
	tw.tween_method(grow, POP_FROM, 1.0, POP_TIME).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tw


## A bounce hello from the bottom up (a stretch, a squash, settled): Professor Hoot greeting the child. Scale only, so
## a container's layout is never fought.
static func bounce(c: Control, delay: float = 0.0) -> Tween:
	if calm() or not c.is_inside_tree():
		return null
	var tw := _fresh(c)
	var foot := func() -> void: c.pivot_offset = Vector2(c.size.x * 0.5, c.size.y)
	foot.call()
	c.scale = Vector2.ONE
	tw.tween_interval(delay)
	tw.tween_callback(foot)
	tw.tween_property(c, "scale", Vector2(0.94, 1.12), 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2(1.08, 0.9), 0.1)
	tw.tween_property(c, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tw


## A quick bump (the counter a coin lands on).
static func bump(c: Control) -> void:
	if calm() or not c.is_inside_tree():
		return
	var tw := _fresh(c)
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2.ONE * BUMP
	tw.tween_property(c, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Brightens `c` and lets it settle GLOW_PULSES times (a level-up), then leaves it exactly as it was (white).
static func glow(c: Control) -> Tween:
	if not c.is_inside_tree():
		return null
	var tw := _fresh(c)
	c.modulate = Color.WHITE
	var pulses := 1 if calm() else GLOW_PULSES
	for i in pulses:
		tw.tween_property(c, "modulate", GLOW, GLOW_TIME * 0.4).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "modulate", Color.WHITE, GLOW_TIME * 0.6).set_trans(Tween.TRANS_SINE)
	return tw


## Makes `b` squash when pressed and spring back when let go (once, however often it is asked).
static func squash_on_press(b: BaseButton) -> void:
	if squashes(b):
		return
	b.set_meta(&"ui_squash", true)
	b.button_down.connect(_press_down.bind(b))
	b.button_up.connect(_press_up.bind(b))


static func squashes(b: BaseButton) -> bool:
	return b.has_meta(&"ui_squash")


static func _press_down(b: BaseButton) -> void:
	if calm() or not b.is_inside_tree():
		return
	var tw := _fresh(b)
	b.pivot_offset = b.size * 0.5
	tw.tween_property(b, "scale", SQUASH, SQUASH_TIME).set_ease(Tween.EASE_OUT)


static func _press_up(b: BaseButton) -> void:
	if not b.is_inside_tree() or b.scale == Vector2.ONE:
		return
	var tw := _fresh(b)
	tw.tween_property(b, "scale", Vector2.ONE, SPRING_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Sends `count` coins or stars (UiFlyers.COIN / STAR) from `from` (global, the screen) to `target`, which bumps as each
## lands. `host` is the screen they fly over (its pooled UiFlyers).
static func fly(host: Control, from: Vector2, target: Control, count: int, kind: StringName) -> UiFlyers:
	var f := flyers(host)
	f.fly(from, target, count, kind)
	return f


## A few stars burst from `at` (global) over `host`.
static func burst(host: Control, at: Vector2, count: int = 6, color: Color = UiFlyers.STAR_GOLD) -> UiFlyers:
	var f := flyers(host)
	f.burst(at, count, color)
	return f


## The screen's pooled flying-pieces node (made the first time).
static func flyers(host: Control) -> UiFlyers:
	var f := host.get_node_or_null(^"UiFlyers") as UiFlyers
	if f == null:
		f = UiFlyers.new()
		f.name = "UiFlyers"
		host.add_child(f)
	return f


## Ends `c`'s motion at once, at rest (its size, fully shown): a test or a picture tool that measures it now.
static func settle(c: Control) -> void:
	if c.has_meta(_TWEEN):
		var tw := c.get_meta(_TWEEN) as Tween
		if tw and tw.is_valid():
			tw.kill()
	c.scale = Vector2.ONE
	c.modulate = Color.WHITE


## The control's own tween, the last one stopped (a pop while popping starts again rather than fighting).
static func _fresh(c: Control) -> Tween:
	if c.has_meta(_TWEEN):
		var old := c.get_meta(_TWEEN) as Tween
		if old and old.is_valid():
			old.kill()
	var tw := c.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)   # menus open over a paused game too
	c.set_meta(_TWEEN, tw)
	return tw
