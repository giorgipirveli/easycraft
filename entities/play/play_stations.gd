class_name PlayStations
extends RefCounted
## Owner #122 (G0): the station for an exercise, by its mechanic (PlayMechanics): Make it, Sort it, Order it, Connect it,
## Fix it, Build it, Code it, Beat it, Mix it, Find it, Choose by doing, Test it. A unit whose play block names a built
## signature game (`game`, PlayMechanics.signature_games: G1-G5) plays each exercise the game expresses in the game's own
## station; any other keeps its mechanic's.


static func make(ex: Dictionary, game: String = "") -> PlayStation:
	var path := PlayMechanics.game_script(game) if game != "" else ""
	if path != "" and ResourceLoader.exists(path):
		var script := load(path) as GDScript
		if script != null and script.has_method(&"expresses") and bool(script.call(&"expresses", ex)):
			return script.new() as PlayStation
	match PlayMechanics.of_exercise(ex):
		"make":
			return MakeStation.new()
		"sort":
			return SortStation.new()
		"order":
			return OrderStation.new()
		"connect":
			return ConnectStation.new()
		"fix":
			return FixStation.new()
		"build":
			return BuildStation.new()
		"code":
			return CodeStation.new()
		"beat":
			return BeatStation.new()
		"mix":
			return MixStation.new()
		"find":
			return FindStation.new()
		"test":
			return TestStation.new()
	return ChooseStation.new()   # a choice, and the way any new type plays until it has its own
