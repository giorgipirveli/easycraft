class_name RobotModels
extends RefCounted
## The planets' robots, our own designs (owner #86, spec §21f, §3c: friendly, never scary): white shells with the
## brand's teal and orange trims, screen faces with round glowing eyes and a smile. Each model faces -Z and stands on
## y = 0; each part is one cached mesh (CreatureLook). The helper robot's pointing arm and the drone's rotors are
## meshes of their own (they move).
## - The helper robot (~1.7 tall): two treads, a round shell with a chest screen and the planet's badge, a screen face,
##   an antenna with an orange light; its right arm points the way.
## - The rover buddy (~1.1 long): six wheels, a white deck with a solar panel, a camera mast with two round eyes, a
##   little digging scoop in front.
## - The scout drone (~0.9 across): a round body with a teal dome and one wide eye, four arms with orange rotors.

const SHOULDER := Vector3(0.45, 0.98, 0.0)
const ROTORS: Array[Vector3] = [Vector3(0.36, 0.1, 0.36), Vector3(-0.36, 0.1, 0.36), Vector3(0.36, 0.1, -0.36),
	Vector3(-0.36, 0.1, -0.36)]


## The helper robot's body in world u's badge colour (the arm is arm()).
static func helper(badge: Color) -> ArrayMesh:
	return CreatureLook.mesh("robot_helper_%s" % badge.to_html(false), helper_parts(badge))


static func helper_parts(badge: Color) -> Array:
	var shell := CreatureWords.ROBOT_SHELL
	var face := -0.261
	var parts: Array = [
		[Vector3(-0.22, 0.16, 0), Vector3(0.22, 0.32, 0.74), CreatureWords.ROBOT_DARK],        # treads
		[Vector3(0.22, 0.16, 0), Vector3(0.22, 0.32, 0.74), CreatureWords.ROBOT_DARK],
		[Vector3(-0.22, 0.16, -0.38), Vector3(0.2, 0.2, 0.04), CreatureWords.ROBOT_ORANGE],     # their wheels' caps
		[Vector3(0.22, 0.16, -0.38), Vector3(0.2, 0.2, 0.04), CreatureWords.ROBOT_ORANGE],
		[Vector3(0, 0.36, 0), Vector3(0.62, 0.1, 0.5), CreatureWords.ROBOT_TEAL],               # the waist
	]
	parts.append_array(CreatureLook.round_box(Vector3(0, 0.68, 0), 0.34, 0.56, shell))   # a round shell
	parts.append_array([
		[Vector3(0, 0.72, face + 0.02), Vector3(0.36, 0.26, 0.02), CreatureWords.ROBOT_SCREEN],   # the chest screen
		[Vector3(0, 0.72, face + 0.005), Vector3(0.14, 0.14, 0.02), badge],          # the planet's badge
		[Vector3(0, 0.99, 0), Vector3(0.18, 0.1, 0.18), CreatureWords.ROBOT_DARK],               # the neck
		[Vector3(0, 1.24, 0), Vector3(0.64, 0.44, 0.5), shell],                     # the head
		[Vector3(0, 1.24, -0.2), Vector3(0.56, 0.4, 0.14), shell],
		[Vector3(0, 1.25, face), Vector3(0.5, 0.3, 0.02), CreatureWords.ROBOT_SCREEN],           # the screen face
		[Vector3(-0.12, 1.29, face - 0.012), Vector3(0.1, 0.12, 0.01), CreatureWords.ROBOT_EYES], # round eyes
		[Vector3(0.12, 1.29, face - 0.012), Vector3(0.1, 0.12, 0.01), CreatureWords.ROBOT_EYES],
		[Vector3(0, 1.15, face - 0.012), Vector3(0.16, 0.035, 0.01), CreatureWords.ROBOT_EYES],  # a smile
		[Vector3(-0.1, 1.17, face - 0.012), Vector3(0.04, 0.04, 0.01), CreatureWords.ROBOT_EYES],
		[Vector3(0.1, 1.17, face - 0.012), Vector3(0.04, 0.04, 0.01), CreatureWords.ROBOT_EYES],
		[Vector3(-0.35, 1.24, 0), Vector3(0.07, 0.18, 0.18), CreatureWords.ROBOT_ORANGE],        # ear bolts
		[Vector3(0.35, 1.24, 0), Vector3(0.07, 0.18, 0.18), CreatureWords.ROBOT_ORANGE],
		[Vector3(0, 1.56, 0), Vector3(0.05, 0.22, 0.05), CreatureWords.ROBOT_DARK],             # the antenna
		[Vector3(0, 1.71, 0), Vector3(0.12, 0.12, 0.12), CreatureWords.ROBOT_ORANGE],
		[Vector3(-0.45, 0.78, 0), Vector3(0.14, 0.42, 0.16), shell],                 # the left arm, resting
		[Vector3(-0.45, 0.52, 0), Vector3(0.17, 0.13, 0.19), CreatureWords.ROBOT_TEAL],
	])
	return parts


## The pointing arm: it hangs down from its shoulder (SHOULDER); turned PI/2 round x it points forward.
static func arm() -> ArrayMesh:
	return CreatureLook.mesh("robot_arm", [
		[Vector3(0, -0.2, 0), Vector3(0.14, 0.42, 0.16), CreatureWords.ROBOT_SHELL],
		[Vector3(0, -0.45, 0), Vector3(0.17, 0.13, 0.19), CreatureWords.ROBOT_TEAL],
		[Vector3(0, -0.56, 0), Vector3(0.05, 0.12, 0.05), CreatureWords.ROBOT_TEAL],             # the pointing finger
	])


static func rover() -> ArrayMesh:
	return CreatureLook.mesh("robot_rover", rover_parts())


static func rover_parts() -> Array:
	var parts: Array = [
		[Vector3(0, 0.42, 0), Vector3(0.74, 0.22, 1.0), CreatureWords.ROBOT_SHELL],             # the deck
		[Vector3(-0.375, 0.42, 0), Vector3(0.02, 0.08, 0.9), CreatureWords.ROBOT_TEAL],          # its stripes
		[Vector3(0.375, 0.42, 0), Vector3(0.02, 0.08, 0.9), CreatureWords.ROBOT_TEAL],
		[Vector3(0, 0.56, 0.08), Vector3(0.86, 0.04, 0.7), Color("2b4c7e")],          # the solar panel
		[Vector3(0, 0.585, 0.08), Vector3(0.02, 0.01, 0.7), Color("8fb3e0")],
		[Vector3(0, 0.585, 0.08), Vector3(0.86, 0.01, 0.02), Color("8fb3e0")],
		[Vector3(0, 0.76, -0.34), Vector3(0.06, 0.36, 0.06), CreatureWords.ROBOT_DARK],          # the camera mast
		[Vector3(0, 0.99, -0.34), Vector3(0.32, 0.16, 0.16), CreatureWords.ROBOT_ORANGE],        # its head
		[Vector3(-0.075, 1.0, -0.425), Vector3(0.08, 0.08, 0.01), CreatureWords.ROBOT_SCREEN],   # two round eyes
		[Vector3(0.075, 1.0, -0.425), Vector3(0.08, 0.08, 0.01), CreatureWords.ROBOT_SCREEN],
		[Vector3(-0.075, 1.0, -0.43), Vector3(0.04, 0.04, 0.01), CreatureWords.ROBOT_EYES],
		[Vector3(0.075, 1.0, -0.43), Vector3(0.04, 0.04, 0.01), CreatureWords.ROBOT_EYES],
		[Vector3(0, 0.36, -0.58), Vector3(0.06, 0.06, 0.24), CreatureWords.ROBOT_DARK],          # the digging arm ...
		[Vector3(0, 0.27, -0.72), Vector3(0.28, 0.12, 0.14), CreatureWords.ROBOT_ORANGE],        # ... and its scoop
	]
	for x: float in [-0.44, 0.44]:
		for z: float in [-0.36, 0.0, 0.36]:
			parts.append([Vector3(x, 0.17, z), Vector3(0.14, 0.3, 0.3), CreatureWords.ROBOT_DARK])   # six wheels
			parts.append([Vector3(x + signf(x) * 0.075, 0.17, z), Vector3(0.02, 0.12, 0.12), CreatureWords.ROBOT_TEAL])
	return parts


static func drone() -> ArrayMesh:
	return CreatureLook.mesh("robot_drone", drone_parts())


static func drone_parts() -> Array:
	var parts: Array = CreatureLook.round_box(Vector3(0, 0, 0), 0.26, 0.18, CreatureWords.ROBOT_SHELL)
	parts.append_array([
		[Vector3(0, 0.14, 0), Vector3(0.26, 0.12, 0.26), CreatureWords.ROBOT_TEAL],               # the dome
		[Vector3(0, 0.0, -0.265), Vector3(0.22, 0.09, 0.02), CreatureWords.ROBOT_SCREEN],        # one wide eye
		[Vector3(-0.05, 0.0, -0.277), Vector3(0.05, 0.05, 0.01), CreatureWords.ROBOT_EYES],
		[Vector3(0.05, 0.0, -0.277), Vector3(0.05, 0.05, 0.01), CreatureWords.ROBOT_EYES],
		[Vector3(0, 0.02, 0), Vector3(1.0, 0.05, 0.08), CreatureWords.ROBOT_DARK, Basis(Vector3.UP, PI / 4.0)],    # four arms
		[Vector3(0, 0.02, 0), Vector3(1.0, 0.05, 0.08), CreatureWords.ROBOT_DARK, Basis(Vector3.UP, -PI / 4.0)],
		[Vector3(-0.14, -0.14, 0), Vector3(0.04, 0.12, 0.3), CreatureWords.ROBOT_DARK],          # skids
		[Vector3(0.14, -0.14, 0), Vector3(0.04, 0.12, 0.3), CreatureWords.ROBOT_DARK],
	])
	for r in ROTORS:
		parts.append([Vector3(r.x, 0.05, r.z), Vector3(0.08, 0.08, 0.08), CreatureWords.ROBOT_ORANGE])   # the motors
	return parts


## One rotor's two blades (they spin round y).
static func rotor() -> ArrayMesh:
	return CreatureLook.mesh("robot_rotor", [
		[Vector3.ZERO, Vector3(0.44, 0.02, 0.07), CreatureWords.ROBOT_ORANGE],
		[Vector3.ZERO, Vector3(0.07, 0.02, 0.44), CreatureWords.ROBOT_ORANGE],
	])
