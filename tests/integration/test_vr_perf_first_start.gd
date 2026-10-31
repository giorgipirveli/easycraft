extends GutTest
## P5 (owner #108): a new profile on the Quest APK starts on its headset's VR preset (`vr_plus` on a Quest 3 / 3S, `vr`
## on a Quest 2); a phone, a browser and the desktop keep their own first pick. Reads a profile file that never exists
## (Profile._read only reads: the shared profile file is never touched).

const QUEST_APK := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true, PlatformRules.QUEST: true}
const ANDROID := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}

var _path := ""


func before_each() -> void:
	_path = Profile.path
	Profile.path = "user://vrp5_no_profile_%d.json" % OS.get_process_id()


func after_each() -> void:
	Profile.path = _path
	PlatformRules.simulated = {}
	GraphicsPreset.headset = ""


func test_a_quest_3_starts_on_vr_plus_and_a_quest_2_on_vr() -> void:
	PlatformRules.simulated = QUEST_APK
	for model: String in ["Quest 3", "Quest 3S"]:
		GraphicsPreset.headset = model
		assert_eq(Profile._read().settings.graphics, "vr_plus", model)
	GraphicsPreset.headset = "Quest 2"
	assert_eq(Profile._read().settings.graphics, "vr")


func test_a_phone_keeps_its_own_first_pick() -> void:
	PlatformRules.simulated = ANDROID
	GraphicsPreset.headset = "Quest 3"
	assert_false(str(Profile._read().settings.graphics).begins_with("vr"), "a phone never starts on a VR preset")
