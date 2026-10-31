extends GutTest
## M7 (docs/devlog/parts/m7-shader-warmup.md): in a browser the menu says it is ready (`MENU ready`, the line the
## page's loading screen leaves on) once the warm-up's first part (what the menu and a first world show) is drawn,
## behind that screen; the rest goes on under the tree's root where a slow frame hurts nobody: on the menu while nobody
## touches it, behind a world's loading card, never in play. The Android app and the desktop (Vulkan) start as before.
## A child who picks REALISTIC later gets it first in the rest.

const PHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}

var _profile: ProfileData


func before_each() -> void:
	ShaderWarmup.menu_first = true   # these tests pin the menu-first design (the game: off, 2026-09-29)
	PlatformRules.shader_warmup = true
	_profile = Profile.data
	Profile.data = ProfileData.new()
	ShaderWarmup.done = false
	ShaderWarmup.warmed_styles.clear()


func after_each() -> void:
	ShaderWarmup.menu_first = false
	for n: Node in get_tree().get_nodes_in_group(ShaderWarmup.GROUP):
		if is_instance_valid(n) and n is ShaderWarmup and not n.is_queued_for_deletion():
			n.free()   # under the root: GUT does not free it
	PlatformRules.shader_warmup = true
	Profile.data = _profile
	PlatformRules.simulated = {}
	ShaderWarmup.done = false
	ShaderWarmup.warmed_styles.clear()
	get_viewport().disable_3d = false


## Until `w` has drawn everything (at most `seconds`). Not GUT's wait_for_signal: its signal watcher records every
## signal of the warm-up with its arguments (a node_drawn for each of ~150 draws), and a run hung after such a test.
func _until_finished(w: ShaderWarmup, seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while is_instance_valid(w) and (not w.is_inside_tree() or w.is_in_group(ShaderWarmup.RUNNING)) \
			and Time.get_ticks_msec() < until:   # added to the root a frame later
		await get_tree().process_frame


func _menu() -> Node:
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	return menu


func test_a_browser_s_menu_is_ready_after_the_first_part_and_the_rest_goes_on() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var menu := _menu()
	var warm: ShaderWarmup = menu.get("warmup")
	assert_not_null(warm, "a browser warms its shaders")
	assert_false(menu.get("announced"), "no MENU ready yet: the loading page stays up")
	assert_eq(warm.styles, ["blocky"] as Array[String], "a new player's BLOCKY")
	assert_true(get_viewport().disable_3d, "the game's view draws nothing behind the page, from the start")
	await wait_for_signal(warm.first_done, 20.0)
	await wait_process_frames(1)
	assert_true(menu.get("announced"), "MENU ready once the first part is drawn")
	assert_eq(warm.get_parent(), get_tree().root, "the rest outlives the menu")
	assert_true(warm.is_in_group(ShaderWarmup.RUNNING), "and goes on after it")
	assert_lt(warm.first_drawn, warm.drawn.size() + 1)


func test_the_android_app_and_the_desktop_announce_at_once() -> void:
	var menu := _menu()
	assert_null(menu.get("warmup"), "Vulkan compiles its pipelines itself")
	assert_true(menu.get("announced"))
	assert_false(ShaderWarmup.covers_prewarms(), "the world's own prewarms stay")


func test_the_warm_up_runs_once_a_run() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var first := _menu()
	var warm: ShaderWarmup = first.get("warmup")
	await wait_for_signal(warm.first_done, 20.0)
	var again := _menu()   # back from a world: the shaders are still compiled, the rest goes on where it was
	assert_null(again.get("warmup"))
	assert_true(again.get("announced"))


func test_the_rest_draws_on_an_idle_menu_waits_in_play_and_goes_on_behind_a_loading_card() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var menu := _menu()
	var warm: ShaderWarmup = menu.get("warmup")
	await wait_for_signal(warm.first_done, 20.0)
	var drawn := warm.drawn
	var at_menu := drawn.size()
	await wait_process_frames(6)
	assert_gt(drawn.size(), at_menu, "the menu, nobody touching it")
	menu.free()   # the world's scene: play, no card
	await wait_process_frames(2)
	var in_play := drawn.size()
	await wait_process_frames(6)
	assert_eq(drawn.size(), in_play, "never in play")
	var card := LoadingCard.new()
	add_child_autofree(card)
	# The rest pauses on the clock after each frame (rest_after, up to MAX_REST_MS): wait for its next draw, not a
	# number of frames (six headless frames could all fall inside the pause: flaky, 2026-09-29).
	await wait_until(func() -> bool: return drawn.size() > in_play, 3.0)
	assert_gt(drawn.size(), in_play, "behind a world's loading card")


func test_a_tap_on_the_menu_holds_the_rest_a_moment() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var menu := _menu()
	var warm: ShaderWarmup = menu.get("warmup")
	await wait_for_signal(warm.first_done, 20.0)
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	warm._input(tap)
	var drawn := warm.drawn
	var at_tap := drawn.size()
	await wait_process_frames(6)
	assert_eq(drawn.size(), at_tap, "the menu answers the tap first")


func test_a_realistic_player_warms_realistic_first_and_blocky_after_the_menu() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Profile.data.settings.style = "realistic"
	var menu := _menu()
	var warm: ShaderWarmup = menu.get("warmup")
	assert_eq(warm.styles, ["realistic", "blocky"] as Array[String],
		"what their worlds show first; BLOCKY for a device whose realistic pictures are still on their way")
	await wait_for_signal(warm.first_done, 20.0)
	var first := warm.drawn.slice(0, warm.first_total)
	assert_eq(first.size(), warm.first_total)
	assert_true(first.all(func(d: Dictionary) -> bool: return d.style == "realistic" and d.first), str(first))


func test_picking_realistic_later_puts_it_first_in_the_rest() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var menu := _menu()
	var warm: ShaderWarmup = menu.get("warmup")
	await wait_for_signal(warm.first_done, 20.0)
	assert_false(ShaderWarmup.warmed_styles.has("realistic"))
	Profile.data.settings.style = "realistic"
	Game.settings_applied.emit(Profile.data.settings)
	assert_has(warm.styles, "realistic", "into the running warm-up")
	await _until_finished(warm, 60.0)
	assert_has(ShaderWarmup.warmed_styles, "realistic")


func test_picking_realistic_after_everything_was_drawn_starts_the_rest_again() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var menu := _menu()
	var warm: ShaderWarmup = menu.get("warmup")
	await _until_finished(warm, 60.0)
	await wait_process_frames(ShaderWarmup.LINGER_FRAMES + 1)
	Profile.data.settings.style = "realistic"
	Game.settings_applied.emit(Profile.data.settings)
	await wait_process_frames(1)
	var late: ShaderWarmup = get_tree().get_first_node_in_group(ShaderWarmup.RUNNING)
	assert_not_null(late, "a new one, for the rest only")
	assert_eq(late.styles, ["realistic"] as Array[String])
	assert_false(late.first_part)
	await _until_finished(late, 60.0)
	assert_has(ShaderWarmup.warmed_styles, "realistic")
	Game.settings_applied.emit(Profile.data.settings)   # another setting changes (the volume): nothing again
	await wait_process_frames(1)
	assert_null(get_tree().get_first_node_in_group(ShaderWarmup.RUNNING), "warm already")


## The game's default (menu_first off): the menu says it is ready at once (the loading page leaves) and shows its 3D
## backdrop; the warm-up starts with what a first world needs, the menu's own draws included, and a world's loading
## card waits for that part.
func test_without_menu_first_the_menu_is_ready_at_once_and_the_card_waits_for_the_world_part() -> void:
	ShaderWarmup.menu_first = false
	PlatformRules.simulated = PHONE_BROWSER
	var menu := _menu()
	await wait_process_frames(3)
	assert_true(menu.get("announced"), "MENU ready at once")
	assert_false(get_viewport().disable_3d, "the menu's backdrop is drawn")
	var warm: ShaderWarmup = get_tree().get_first_node_in_group(ShaderWarmup.GROUP)
	assert_not_null(warm, "the warm-up still runs")
	if warm == null:
		return
	assert_eq(warm.first_total, 0)
	assert_gt(warm.world_left, 0, "a first world's part is queued for the loading card")
