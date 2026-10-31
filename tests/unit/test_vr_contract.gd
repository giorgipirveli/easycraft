extends GutTest
## Owner #101 (VR on the Meta Quest): the lead's contract both VR agents build against. Off VR nothing changes: Vr is idle,
## its calls are no-ops, UiLayers adds a layer to its owner as before; a simulated session starts and ends with signals.


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)


func test_vr_is_an_autoload_that_is_idle_off_vr() -> void:
	assert_not_null(get_tree().root.get_node_or_null("Vr"), "the Vr autoload exists")
	assert_false(Vr.active(), "no headset, no session")
	assert_null(Vr.camera)
	assert_eq(Vr.hand_ray(), [], "no hands off VR")
	assert_null(Vr.ui_viewport(), "no VR canvas off VR")
	assert_false(Vr.ui_wants_pointer())


func test_vr_never_stops_with_the_tree() -> void:
	assert_eq(Vr.process_mode, Node.PROCESS_MODE_ALWAYS, "a paused game must never freeze the head")


func test_a_simulated_session_starts_and_ends_with_signals() -> void:
	watch_signals(Vr)
	Vr.simulate(true)
	assert_true(Vr.active())
	assert_true(Vr.simulated())
	assert_signal_emitted(Vr, "started")
	Vr.simulate(false)
	assert_false(Vr.active())
	assert_signal_emitted(Vr, "ended")


func test_start_refuses_an_unknown_kind_in_words() -> void:
	assert_ne(Vr.start(&"cardboard"), "", "plain words why not")


func test_anchor_remembers_its_kind_while_the_node_lives() -> void:
	var n := Node3D.new()
	add_child_autofree(n)
	Vr.anchor(n, &"seat")
	assert_eq(Vr.anchor_kind(), &"seat")
	Vr.anchor(null)
	assert_eq(Vr.anchor_kind(), &"")


func test_ui_layers_adds_a_layer_to_its_owner_off_vr() -> void:
	var owner := Node.new()
	add_child_autofree(owner)
	var layer := CanvasLayer.new()
	UiLayers.route(layer, owner)
	assert_eq(layer.get_parent(), owner, "off VR a layer is its owner's child, as before")


func test_the_comfort_defaults_are_the_plans_ruling() -> void:
	assert_eq(VrRules.setting({}, VrRules.TURN), "snap45", "snap turn 45 by default")
	assert_eq(VrRules.setting({}, VrRules.VIGNETTE), "light")
	assert_eq(VrRules.setting({}, VrRules.HEIGHT), "game", "the eye at the avatar's height")
	assert_eq(VrRules.setting({}, VrRules.BREAK_MINUTES), 30)
	assert_eq(VrRules.setting({VrRules.TURN: 7}, VrRules.TURN), "snap45", "a wrong type reads the default")
	assert_null(VrRules.setting({}, "vr_nonsense"))
	assert_eq(VrRules.snap_degrees("snap30"), 30.0)
	assert_eq(VrRules.snap_degrees("smooth"), 0.0)
	assert_eq(VrRules.pointing_hand(true), VrRules.LEFT, "a left-handed child points with the left hand")
