class_name PlaySignature
extends RefCounted
## Owner #133, #134 (docs/design/future-lessons.md; the leaf's B2 brief; docs/devlog/parts/game-leaf-b.md B2.1): the
## registry for a deep game with its own host, built once for every deep game (Inside a Leaf first; Balance Altar and
## Fraction Bakery next). data/play/mechanics.json's "signature" table lists the deep games: G0's station games name a
## PlayStation "script" (PlayHost plays them, PlayMechanics), a game with its own scene names a "host":
##     "signature": {"leaf_voyage": {"name": "Size Magic Voyages: Inside a Leaf",
##                                   "host": "res://entities/play/leaf/leaf_voyage_host.gd"}}
## A host is a PlayHost subclass: the contract is PlayHost's own public face, which every caller already uses, so the
## School, DISCOVER and the menu treat a deep game exactly as a round (W1's room_open, the world held still, Back):
##     var host := PlaySignature.make_host(content)          # the game's own host, else G0's PlayHost
##     host.setup(unit_id, content, seed, stars, outline, count)   # the game reads its params from the play block
##     host.first_try_gold = ...                              # EarnRules: each challenge solved with no help, as it is judged
##     host.finished.connect(...)                            # the outcome: {right_first, total, world_task, shown, then}
##     host.stopped.connect(...)                             # STOP FOR NOW: nothing recorded
##     host.open(parent)                                     # in PlayHost.GROUP: PlayHost.any_open sees it
## `then` (optional): the game asks to be opened again on the same unit with these params (the leaf's "again" and its
## voyage board); the caller opens `with_params(content, then)` after recording (`then_of`).

## The deep games with a host of their own: id -> host script path.
static func hosts() -> Dictionary:
	var out := {}
	var games := PlayMechanics.signature_games()
	for id: Variant in games:
		var g: Variant = games[id]
		if g is Dictionary and (g as Dictionary).has("host"):
			out[str(id)] = str((g as Dictionary).host)
	return out


## The game the unit's play block names ("" for none or "generic").
static func game_of(content: Dictionary) -> String:
	var game := str(PlayBlock.of(content).get("game", ""))
	return "" if game == PlayBlock.GENERIC else game


## The host script the unit opens: its deep game's own, when the game is listed with a host that is a PlayHost ("" for
## G0's PlayHost).
static func host_for(content: Dictionary) -> String:
	var game := game_of(content)
	var path := str(hosts().get(game, ""))
	return path if path != "" and _is_host(path) else ""


## Why the unit falls back to G0's PlayHost against its play block ("" when it opens what it names: its game's host, or
## G0's place for no game, "generic" or a station game).
static func why_not(content: Dictionary) -> String:
	var game := game_of(content)
	if game == "" or (PlayMechanics.signature_games().has(game) and not hosts().has(game)):
		return ""
	if not PlayMechanics.signature_games().has(game):
		return "the play block names %s, which is no game in data/play/mechanics.json" % game
	var path := str(hosts()[game])
	if not ResourceLoader.exists(path):
		return "the host of %s (%s) is missing" % [game, path]
	if not _is_host(path):
		return "the host of %s (%s) is no PlayHost" % [game, path]
	return ""


## The host to open for the unit: its deep game's own, else G0's PlayHost (with a warning when the play block names a
## game that can't open: never a crash).
static func make_host(content: Dictionary) -> PlayHost:
	var path := host_for(content)
	if path != "":
		var h: Variant = (load(path) as GDScript).new()
		if h is PlayHost:
			return h
		if h is Node:
			(h as Node).free()
	var why := why_not(content)
	if why != "":
		push_warning("PlaySignature: %s; G0's play place opens instead" % why)
	return PlayHost.new()


## A deep game's host shows now somewhere in `tree` (G0's own PlayHost.any_open sees every host, games included).
static func any_open(tree: SceneTree) -> bool:
	if tree == null:
		return false
	for h in tree.get_nodes_in_group(PlayHost.GROUP):
		if h is PlayHost and not (h as PlayHost).closed and (h as PlayHost).get_script() != PlayHost:
			return true
	return false


## The params the game asked to be opened with next ({} for none).
static func then_of(outcome: Dictionary) -> Dictionary:
	var t: Variant = outcome.get("then", {})
	return (t as Dictionary).duplicate() if t is Dictionary else {}


## The unit's content with its play block's params changed by `params` (a copy: the unit itself is untouched).
static func with_params(content: Dictionary, params: Dictionary) -> Dictionary:
	var out := content.duplicate(true)
	var play: Dictionary = PlayBlock.of(out).duplicate(true)
	var p: Dictionary = PlayBlock.params(out).duplicate(true)
	p.merge(params, true)
	play.params = p
	out.play = play
	return out


## `path` is a script whose class is PlayHost or a subclass of it.
static func _is_host(path: String) -> bool:
	if not ResourceLoader.exists(path):
		return false
	var s := load(path) as Script
	while s != null:
		if s == PlayHost:
			return true
		s = s.get_base_script()
	return false
