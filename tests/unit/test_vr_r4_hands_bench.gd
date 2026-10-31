extends GutTest
## VR P5's follow-up (b), owner #101/#110 (docs/devlog/parts/vr-perf.md "For VR-RIG"): the headset's VR_BENCH line names
## the VR preset in use (vr or vr_plus, never a bool) and splits the scene's draws (every viewport's 3D and shadow
## draws: Meta's budget) from the canvases' (the HUD's tray is drawn every frame in VR).


func after_each() -> void:
	GraphicsPreset.vr_session = false


func test_the_line_names_the_preset_and_splits_the_draws() -> void:
	var l := VrBench.line({"fps": 72.0, "worst_ms": 20.0, "over": 0, "draws": 95, "draws_3d": 61, "draws_2d": 34,
		"primitives": 300000, "objects": 80, "process_ms": 5.0, "physics_ms": 1.0, "gpu_ms": 9.0},
		{"world": 1, "preset": "vr_plus", "renderer": "mobile"})
	assert_string_contains(l, "vr_preset=vr_plus")
	assert_string_contains(l, "draws=95")
	assert_string_contains(l, "draws_3d=61")
	assert_string_contains(l, "draws_2d=34")


func test_a_line_from_before_the_split_still_prints() -> void:
	var l := VrBench.line({"fps": 72.0, "worst_ms": 20.0, "over": 0, "draws": 95, "primitives": 1, "objects": 1,
		"process_ms": 5.0, "physics_ms": 1.0, "gpu_ms": 9.0}, {"world": 1, "preset": "vr", "renderer": "mobile"})
	assert_string_contains(l, "draws_3d=-1", "unknown: -1")


func test_the_preset_in_a_session_is_the_headsets_vr_preset_by_name() -> void:
	GraphicsPreset.vr_session = true
	var name := VrBench.preset_name({"graphics": "medium"})
	assert_true(name == "vr" or name == "vr_plus", "a phone preset reads as the headset's VR preset: %s" % name)
	assert_eq(VrBench.preset_name({"graphics": "vr_plus"}), "vr_plus", "the child's VR PLUS stays itself")
	GraphicsPreset.vr_session = false
	assert_eq(VrBench.preset_name({"graphics": "medium"}), "medium", "off a session: the child's own")


func test_the_split_reads_each_viewports_3d_shadow_and_canvas_draws() -> void:
	var split := VrBench.draw_split([get_tree().root])
	assert_true(split.has("draws_3d") and split.has("draws_2d"))
	assert_true(int(split.draws_3d) >= 0 and int(split.draws_2d) >= 0)
	assert_eq(VrBench.draw_split([null, get_tree().root]).size(), 2, "a freed viewport is skipped")


func test_a_bench_sample_carries_the_split_and_the_preset() -> void:
	var b := VrBench.new()
	add_child_autofree(b)
	b.every = 0.01
	b.sample(0.02)
	assert_eq(b.lines, 1)
	assert_true(b.last.has("draws_3d") and b.last.has("draws_2d"), "the split in the last numbers")
