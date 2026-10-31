extends GutTest
## Ambience (M1b Task 7) on a real world: the cave mood reaches the sun, the fog and the lantern,
## and nothing is written again while nothing changes (review M8: every write is a call into the
## RenderingServer, and in the open air nothing changes for minutes).

var world: WorldService
var ambience: Ambience


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	world.apply_graphics({"graphics": "medium", "view_distance": 96})
	var player := Player.new()          # not spawned: Ambience._process leaves it alone
	autofree(player)
	ambience = Ambience.new()
	ambience.world = world
	ambience.player = player
	add_child_autofree(ambience)


func _mood(underground: float) -> Dictionary:
	return AmbienceRules.mood(underground, 0.0, world.ambience_base)


func test_the_cave_mood_reaches_the_sun_the_fog_and_the_lantern() -> void:
	var m := _mood(1.0)
	ambience._apply(m)
	var env := world.environment()
	assert_almost_eq(world.sun().light_energy, m.sun as float, 0.001)
	assert_almost_eq(env.ambient_light_energy, m.ambient as float, 0.001)
	assert_true(env.fog_light_color.is_equal_approx(m.fog_color), "cave fog colour")
	assert_almost_eq(env.fog_depth_begin, m.fog_begin as float, 0.01)
	assert_almost_eq(env.fog_depth_end, m.fog_end as float, 0.01)
	assert_almost_eq(ambience._lantern.light_energy, m.lantern as float, 0.001)
	assert_true(ambience._lantern.visible, "the lantern is on")


func test_nothing_is_written_again_while_nothing_changes() -> void:
	ambience._apply(_mood(0.5))
	var before := ambience.writes
	for i in 3:
		ambience._apply(_mood(0.5))
	assert_eq(ambience.writes, before, "the same mood three more times: nothing written")
	ambience._apply(_mood(0.6))
	assert_gt(ambience.writes, before, "a new mood is written")


func test_a_fog_distance_set_elsewhere_is_put_back() -> void:
	ambience._apply(_mood(1.0))
	world.apply_graphics({"graphics": "medium", "view_distance": 64})   # writes the open-air fog
	var m := _mood(1.0)                                                  # the cave fog is the same
	ambience._apply(m)
	assert_almost_eq(world.environment().fog_depth_begin, m.fog_begin as float, 0.01, "the cave fog again")


## A LAN client whose host quit: the host's spawner frees the client's own player at once, and the
## client crashed in Ambience._process (docs/devlog/parts/m1-minors.md). It leaves a freed player alone.
func test_a_freed_player_is_left_alone() -> void:
	ambience.player.free()
	ambience._process(0.016)
	assert_true(true, "no crash, no error")


## Real water (M2 Task 14): under water every sound is muffled, and leaving the world (back to the
## menu) never leaves the menu muffled.
func test_the_muffle_follows_the_view_and_ends_with_the_world() -> void:
	ambience._set_muffled(true)
	assert_true(Audio.is_muffled())
	ambience._set_muffled(false)
	assert_false(Audio.is_muffled())
	ambience._set_muffled(true)
	remove_child(ambience)
	assert_false(Audio.is_muffled(), "the muffle goes with the world")
	Audio.set_muffled(false)
