extends GutTest
## Owner #86 (spec §21f): on the playful planets (Planet Boing, Rainbow Planet) a whole alien village with homes, a
## game and music: four homes round a square, four drum pads, the chief and three villagers strolling. The chief's game
## Echo: it plays a song on the drums, the child hops on them in the same order, one note longer each round; a wrong
## drum plays the round again; the whole song makes the chief a friend (a present, and it may come along).

const SEED := 12345
const BOING := 17
const RAINBOW := 18

var d: SpaceCreatures
var shape: SpaceShape
var child := Vector3.INF
var toasts: Array[String] = []
var marks: Array[Dictionary] = []
var steps: Array[StringName] = []


func before_each() -> void:
	toasts.clear()
	marks.clear()
	steps.clear()


func _director(u: int, planet: StringName) -> SpaceCreatures:
	shape = SpaceShape.new(SEED, planet)
	var pad := shape.spawn_column()
	child = Vector3(pad.x + 0.5, shape.height_at(pad.x, pad.y), pad.y + 0.5)
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	var c := SpaceCreatures.new()
	c.universe = u
	c.shape = shape
	c.world_seed = SEED
	c.ground_y = func(x: int, z: int) -> float: return float(shape.height_at(x, z))
	c.player_position = func() -> Vector3: return child
	c.player_forward = func() -> Vector3: return Vector3.FORWARD
	c.found = {}
	c.sights = UniverseRegistry.sights(u)
	c.profile = ProfileData.new()
	c.toast = func(text: String) -> void: toasts.append(text)
	c.mark = func(e: Dictionary) -> void: marks.append(e)
	c.ui_parent = layer
	c.players = func() -> Array[Vector3]: return [child] if child.is_finite() else [] as Array[Vector3]
	add_child_autofree(c)
	c.setup()
	c.village.echo_step.connect(func(r: StringName) -> void: steps.append(r))
	return c


## The chief finishes playing the round (frames of the village's clock).
func _let_the_chief_play() -> void:
	for i in 200:
		d.village._process(0.05)
		if not d.village.chief_playing():
			return


func _hop(pad: int) -> StringName:
	var p := d.village.pad_position(pad)
	child = Vector3(p.x + 0.1, p.y + AlienModels.PAD_TOP, p.z - 0.1)
	return d.village.check_feet()


func _step_off() -> void:
	var m := d.village.global_position
	child = Vector3(m.x, m.y, m.z)
	d.village.check_feet()


func test_boing_has_a_village_with_homes_drums_a_chief_and_villagers() -> void:
	d = _director(BOING, SpaceShape.BOING)
	assert_null(d.camp)
	var v := d.village
	assert_not_null(v)
	assert_eq(v.chief.display_name, "Bopsy")
	assert_eq(v.villagers.size(), 3)
	assert_eq(v.pads.size(), EchoGame.PADS)
	assert_eq(v.find_children("Home*", "MeshInstance3D", false, false).size(), 4, "four homes")
	for i in v.pads.size():
		var p := v.pad_position(i)
		assert_almost_eq(p.y, float(shape.height_at(floori(p.x), floori(p.z))), 0.01, "drum %d on the ground" % i)
	assert_eq(marks.size(), 1)
	assert_eq(marks[0].kind, &"village", "MY MAP draws it as a village")
	assert_eq(str(marks[0].name), "Boingaloo")
	assert_eq(d.robot.display_name, "Sprocket")


func test_rainbow_planet_has_its_own_village() -> void:
	d = _director(RAINBOW, SpaceShape.RAINBOW)
	assert_eq(d.village.chief.display_name, "Iri")
	assert_eq(str(marks[0].name), "Prismtown")


func test_echo_is_played_round_by_round_to_a_friendship() -> void:
	d = _director(BOING, SpaceShape.BOING)
	d.village.chief.tapped()
	assert_string_contains(" ".join(PackedStringArray(d.card.texts())), CreatureWords.HONEST)
	d.card.button_named(CreatureWords.PLAY_ECHO).pressed.emit()
	assert_true(d.village.playing)
	assert_false(d.card.is_open())
	assert_eq(_hop(d.village.game.song[0]), EchoGame.IDLE, "not the child's turn while the chief plays")
	_step_off()
	var rounds := 0
	while d.village.playing and rounds < 10:
		_let_the_chief_play()
		assert_eq(steps[-1], AlienVillage.YOUR_TURN)
		assert_true(toasts.has(CreatureWords.ECHO_YOUR_TURN))
		for note in d.village.game.round_song():
			_hop(note)
			_step_off()
		rounds += 1
	assert_eq(rounds, EchoGame.rounds())
	assert_eq(steps[-1], EchoGame.WON)
	assert_true(d.profile.creatures.is_friend(&"bopsy"), "the whole song: the chief is a friend")
	assert_true(d.profile.creatures.owns("gift_bopsy"), "its present")
	assert_true(d.card.is_open(), "may it come along?")
	assert_not_null(d.card.button_named(CreatureWords.COME))


func test_a_wrong_drum_plays_the_round_again() -> void:
	d = _director(BOING, SpaceShape.BOING)
	d.village.start_game(5)
	_let_the_chief_play()
	var right := d.village.game.song[0]
	assert_eq(_hop((right + 1) % EchoGame.PADS), EchoGame.NOT_YET)
	assert_true(toasts.has(CreatureWords.ECHO_NOT_YET))
	assert_true(d.village.chief_playing(), "the chief plays it again")
	assert_true(d.village.playing, "never a loss")
	_step_off()
	_let_the_chief_play()
	assert_eq(_hop(right), EchoGame.RIGHT)


func test_walking_away_ends_the_game_quietly() -> void:
	d = _director(BOING, SpaceShape.BOING)
	d.village.start_game(5)
	_let_the_chief_play()
	child = d.village.global_position + Vector3(AlienVillage.AWAY + 5, 0, 0)
	d.village.check_feet()
	assert_false(d.village.playing)
	assert_false(d.profile.creatures.is_friend(&"bopsy"))


func test_villagers_stroll_near_their_homes() -> void:
	d = _director(BOING, SpaceShape.BOING)
	child = Vector3.INF
	var v := d.village.villagers[0]
	var home := v.home
	for i in 400:
		v._process(0.05)
	assert_ne(v.global_position, home, "it went for a stroll")
	assert_lt(Vector2(v.global_position.x - home.x, v.global_position.z - home.z).length(), Alien.WANDER_R + 0.5,
		"never far")
	v.tapped()
	assert_true(v.bubble.visible, "a happy line")
