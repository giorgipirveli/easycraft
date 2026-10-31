extends GutTest
## P5 (VR draws): in a headset session at most the VR preset's `fx_live` bursts are alive at once (each burst is a draw:
## a night's worth of defeats or a boss's fireworks would be dozens), the oldest ending early; off VR Fx.MAX_LIVE as
## before.


func before_each() -> void:
	Fx.reset_budget()


func after_each() -> void:
	GraphicsPreset.vr_session = false
	for n in get_children():
		if n is CPUParticles3D:
			n.free()
	Fx.reset_budget()


func _alive() -> int:
	var n := 0
	for c in get_children():
		if c is CPUParticles3D and not c.is_queued_for_deletion():
			n += 1
	return n


func test_a_headset_keeps_fewer_bursts_alive() -> void:
	GraphicsPreset.vr_session = true
	var cap := int(GraphicsPreset.params("vr").fx_live)
	assert_lt(cap, Fx.MAX_LIVE)
	var made: Array[CPUParticles3D] = []
	for i in cap + 4:
		made.append(Fx.burst(self, Vector3(i * 0.1, 0, 0), Color.RED))
	assert_eq(_alive(), cap)
	assert_true(made[0].is_queued_for_deletion(), "the oldest ends early")
	assert_false(made[-1].is_queued_for_deletion(), "the newest always shows")
	assert_eq(Fx.max_live(), cap)


func test_off_vr_as_before() -> void:
	assert_eq(Fx.max_live(), Fx.MAX_LIVE)
	for i in Fx.MAX_LIVE:
		Fx.burst(self, Vector3.ZERO, Color.RED)
	assert_eq(_alive(), Fx.MAX_LIVE)
