extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.10, §3.12, rulings 12, 19, 32): the garden remembers, on this
## device only, what voyages did: which are done (the board opens the next), each plant's state (the sunflower droops
## until its voyage, then stands in bloom; its scale gains two gold blocks a voyage while the soil's stays), the bud's
## fill kept when a child stops for now (never less), and the leaf journal (each idea shown, with or without help, and
## where). Nothing changes by itself (no clocks, no timers), and nothing personal is kept.

const PATH := "user://test_leaf_voyage.json"
const UNIT := "g5.science.plants_air_water"


func before_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func after_all() -> void:
	before_each()


func _beat(id: String, rule: String, kind: String) -> Dictionary:
	return {"id": id, "rule": rule, "passed": kind != SkillShown.HELPED, "kind": kind, "help": "", "note": id}


func test_a_new_garden_has_a_drooping_sunflower_and_the_first_voyage_open() -> void:
	var g := LeafProgress.open_at(PATH)
	assert_eq(g.done, [] as Array[String])
	assert_eq(str(g.plant("sunflower").stage), LeafProgress.DROOP, "the story's start")
	assert_eq(g.open_voyages(), ["5.1"] as Array[String], "the desert waits for the sunflower")
	assert_eq(int(g.plant("sunflower").blocks), LeafProgress.START_BLOCKS)
	assert_eq(int(g.soil_blocks("sunflower")), LeafProgress.SOIL_BLOCKS)


func test_finishing_a_voyage_blooms_its_plant_adds_two_gold_blocks_and_opens_the_next() -> void:
	var g := LeafProgress.open_at(PATH)
	g.finish("5.1", [_beat("C2", "cloud", SkillShown.SOLVED), _beat("Z2", "blaze", SkillShown.SOLVED)])
	assert_eq(g.done, ["5.1"] as Array[String])
	var s := g.plant("sunflower")
	assert_eq(str(s.stage), LeafProgress.BLOOM, "standing tall, the flower open")
	assert_eq(int(s.blocks), LeafProgress.START_BLOCKS + 2, "the plant got heavier")
	assert_eq(int(g.soil_blocks("sunflower")), LeafProgress.SOIL_BLOCKS, "the soil didn't")
	assert_almost_eq(float(s.bud), 1.0, 0.001)
	assert_eq(g.open_voyages(), ["5.1", "5.T1"] as Array[String])
	g.save()
	var again := LeafProgress.open_at(PATH)
	assert_eq(again.done, ["5.1"] as Array[String], "kept on this device")
	assert_eq(str(again.plant("sunflower").stage), LeafProgress.BLOOM)
	assert_eq(int(again.plant("sunflower").blocks), LeafProgress.START_BLOCKS + 2)
	again.finish("5.1", [])
	assert_eq(again.done, ["5.1"] as Array[String], "done once")
	assert_eq(int(again.plant("sunflower").blocks), LeafProgress.START_BLOCKS + 4, "each voyage builds a little more")


func test_the_cactus_flowers_after_the_desert_night() -> void:
	var g := LeafProgress.open_at(PATH)
	assert_false(g.has_plant("cactus"), "it arrives with its voyage")
	g.finish("5.1", [])
	g.finish("5.T1", [])
	assert_true(g.has_plant("cactus"))
	assert_eq(str(g.plant("cactus").stage), LeafProgress.BLOOM, "the white flower under the stars")


func test_stopping_for_now_keeps_the_bud_s_fill_and_never_less() -> void:
	var g := LeafProgress.open_at(PATH)
	g.keep("5.1", 0.5)
	assert_almost_eq(float(g.plant("sunflower").bud), 0.5, 0.001)
	g.keep("5.1", 0.3)
	assert_almost_eq(float(g.plant("sunflower").bud), 0.5, 0.001, "never less plant")
	assert_eq(g.done, [] as Array[String], "nothing finished")
	assert_eq(str(g.plant("sunflower").stage), LeafProgress.DROOP)


func test_the_journal_keeps_each_idea_shown_with_or_without_help_and_where() -> void:
	var g := LeafProgress.open_at(PATH)
	g.finish("5.1", [_beat("B1", "act1", SkillShown.SOLVED), _beat("C2", "cloud", SkillShown.SOLVED),
		_beat("Z2", "blaze", SkillShown.SOLVED), _beat("C3", "cloud", SkillShown.HELPED)])
	assert_eq(g.shown(LeafProgress.AIR_IN), 1, "doors opened for air when it was cool")
	assert_eq(g.helped(LeafProgress.AIR_IN), 1)
	assert_eq(g.shown(LeafProgress.WATER_OUT), 2, "doors shut to keep the water")
	g.finish("5.T1", [_beat("Night1", "night", SkillShown.NEW_SETTING), _beat("Dawn1", "dawn", SkillShown.NEW_SETTING)])
	assert_eq(g.shown(LeafProgress.AIR_IN), 2)
	assert_true(g.settings(LeafProgress.AIR_IN).has("the desert at night"), "where it was shown")


func test_nothing_changes_by_itself_and_nothing_personal_is_kept() -> void:
	var g := LeafProgress.open_at(PATH)
	g.finish("5.1", [_beat("C2", "cloud", SkillShown.SOLVED)])
	g.save()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var keys := saved.keys()
	keys.sort()
	assert_eq(keys, ["done", "journal", "plants", "version"], "no clock, no name, no id")
	var a := LeafProgress.open_at(PATH)
	var b := LeafProgress.open_at(PATH)
	assert_eq(JSON.stringify(a.to_dict()), JSON.stringify(b.to_dict()), "the same garden whenever it is opened")


func test_a_broken_file_starts_a_new_garden() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	var g := LeafProgress.open_at(PATH)
	assert_eq(g.done, [] as Array[String])
	assert_eq(str(g.plant("sunflower").stage), LeafProgress.DROOP)
