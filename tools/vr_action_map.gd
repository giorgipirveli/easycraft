extends SceneTree
## Owner #101 (VR on the Meta Quest): writes res://openxr_action_map.tres, the OpenXR action map the Quest APK binds the
## Touch controllers with (xr/openxr/default_action_map). Godot 4.7.2's default action set ("godot": trigger, grip,
## primary = the thumbstick, ax_button, by_button, menu_button, the aim and grip poses, haptic...; the names VrInput
## reads) with explicit Touch bindings: oculus/touch_controller (Quest 2, and every Quest through the runtime's
## remapping), meta/touch_plus_controller (OpenXR 1.1: Quest 3 and 3S), meta/touch_controller_plus (its extension
## form), the generic controller and the simple one as fallbacks. Quest runtime support for khr/generic_controller is
## UNCONFIRMED (docs/devlog/parts/vr-research.md), hence the explicit ones. Pico's and hand interaction's are left out
## (no Pico build; controllers only until P4).
##
##   nice godot --headless --path . -s res://tools/vr_action_map.gd

const OUT := "res://openxr_action_map.tres"
const TOUCH := "/interaction_profiles/oculus/touch_controller"
const COPIES: Array[String] = ["/interaction_profiles/meta/touch_plus_controller",
	"/interaction_profiles/meta/touch_controller_plus"]
const KEEP: Array[String] = ["/interaction_profiles/khr/generic_controller", TOUCH]
const SIMPLE := "/interaction_profiles/khr/simple_controller"


func _init() -> void:
	var map := OpenXRActionMap.new()
	map.create_default_action_sets()
	var touch: OpenXRInteractionProfile = map.find_interaction_profile(TOUCH)
	for p: OpenXRInteractionProfile in map.interaction_profiles.duplicate():
		if not KEEP.has(p.interaction_profile_path):
			map.remove_interaction_profile(p)
	for path in COPIES:
		var copy := OpenXRInteractionProfile.new()
		copy.interaction_profile_path = path
		var bindings: Array = []
		for b: OpenXRIPBinding in touch.bindings:
			var nb := OpenXRIPBinding.new()
			nb.action = b.action
			nb.binding_path = b.binding_path
			bindings.append(nb)
		copy.bindings = bindings
		map.add_interaction_profile(copy)
	map.add_interaction_profile(_simple(map))
	var err := ResourceSaver.save(map, OUT)
	print("vr_action_map: %s (%s), profiles: %s" % [OUT, error_string(err),
		", ".join(map.interaction_profiles.map(func(p: OpenXRInteractionProfile) -> String: return p.interaction_profile_path))])
	quit(0 if err == OK else 1)


## The simple controller: select is the trigger, menu the menu button, the poses and the buzz.
func _simple(map: OpenXRActionMap) -> OpenXRInteractionProfile:
	var set: OpenXRActionSet = map.find_action_set("godot")
	var by_name := {}
	for a: OpenXRAction in set.actions:
		by_name[a.resource_name] = a
	var p := OpenXRInteractionProfile.new()
	p.interaction_profile_path = SIMPLE
	var bindings: Array = []
	for pair: Array in [["trigger_click", "input/select/click"], ["menu_button", "input/menu/click"],
			["aim_pose", "input/aim/pose"], ["grip_pose", "input/grip/pose"], ["default_pose", "input/aim/pose"],
			["haptic", "output/haptic"]]:
		for hand: String in ["left", "right"]:
			var b := OpenXRIPBinding.new()
			b.action = by_name[pair[0]]
			b.binding_path = "/user/hand/%s/%s" % [hand, pair[1]]
			bindings.append(b)
	p.bindings = bindings
	return p
