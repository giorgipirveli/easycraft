class_name ShortKinds
extends RefCounted
## The actor kinds a Short may use (owner #96: "implement visuals, video, animation tools": kinds are pluggable). Each
## kind has a check here (kind -> Callable(actor: Dictionary) -> String: "" when its fields are right) and a drawer on
## the UI side (ShortDrawers: kind -> ShortDrawer). The built-in kinds (ShortRules.ACTOR_KINDS) are checked by
## ShortCheck._kind_problem.
##
## A new kind: register its check in `_builtins()` below (or at run time with register()), its drawer in
## ShortDrawers._builtins(), and a sample Short in the tests. The Reel Studio's two (owner #96; core/shorts/studio/,
## ui/shorts/actors/, docs/devlog/parts/reel-studio.md):
## - `scene3d`: a 3D stage (StudioRules: the game's own rocket parts, planets and moons, the avatar, blocks, domes and
##   wonders in a lit studio, its camera moving) in the actor's box: Scene3DKind.problem, Scene3DDrawer;
## - `video`: a clip of a rendered reel (assets/reels/<file>.ogv, the reels pack on the web): VideoKind.problem,
##   VideoDrawer (its `update` seeks it to the scene's time so a seek stays exact).

static var _checks := {}
static var _loaded := false


## Adds (or replaces) a kind's check.
static func register(kind: String, check: Callable) -> void:
	_builtins()
	_checks[kind] = check


## Takes a kind away again (tests).
static func unregister(kind: String) -> void:
	_checks.erase(kind)


static func has(kind: String) -> bool:
	_builtins()
	return _checks.has(kind)


static func names() -> Array[String]:
	_builtins()
	var out: Array[String] = []
	for k: String in _checks:
		out.append(k)
	return out


## "" when `actor`'s fields are right for its kind.
static func problem(kind: String, actor: Dictionary) -> String:
	_builtins()
	var check: Variant = _checks.get(kind)
	return str((check as Callable).call(actor)) if check is Callable else "unknown actor kind '%s'" % kind


static func _builtins() -> void:
	if _loaded:
		return
	_loaded = true
	for k: String in ShortRules.ACTOR_KINDS:
		_checks[k] = func(a: Dictionary) -> String: return ShortCheck._kind_problem(k, a)
	# The Reel Studio's kinds (owner #96; core/shorts/studio/): a 3D stage in a scene, a clip of a rendered reel.
	_checks["scene3d"] = Scene3DKind.problem
	_checks["video"] = VideoKind.problem
	# MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): a photo of the album, the child's avatar, a wonder's stamp, a build.
	for k: String in MyShortRules.ACTOR_KINDS:
		_checks[k] = func(a: Dictionary) -> String: return MyShortRules.kind_problem(k, a)
