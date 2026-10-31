class_name CactusDressing
extends Node3D
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5b, §3.8; the honesty table §9): voyage 5.T1's place, the
## leaf's inside re-dressed as the cactus's green stem. LeafPlace draws the rest from the cactus's layout (LeafSpace:
## its doors sunk in pits, its green outer cells under a thick waxy roof); the dressing adds what only a cactus has:
## big pale water-store cells you can see into, glass jars in their water (the vacuoles, where a cactus keeps the night's
## air as an acid, CAM) that fill with a soft violet-green glow as air comes in at night and empty into the workshops by
## day, and the desert's night sky (stars and the moon) over the white-hot day.

const JAR_HEIGHT := 0.74
const JAR_RADIUS := 0.26
const STORE := Color(0.9, 0.97, 0.94, 0.2)
const WATER := Color(0.72, 0.9, 1.0, 0.1)
const JAR_GLASS := Color(0.93, 0.98, 1.0, 0.22)
const FILL_LOW := Color("8c5cff")
const FILL_HIGH := Color("5cf0b0")

var place: LeafPlace
## The air kept in the jars, in sugars' worth (each jar holds one).
var kept := 0.0
var _fill: MultiMeshInstance3D
var _stars: MeshInstance3D
var _moon: MeshInstance3D
var _moon_halo: MeshInstance3D
var _night := false


func _init(leaf_place: LeafPlace) -> void:
	place = leaf_place
	name = "CactusDressing"


func _ready() -> void:
	_build_stores()
	_build_jars()
	_build_sky()
	set_night(false)


## The jars' fill from the simulation (LeafSim.jars of `cap`).
func show_jars(jars: float, _cap: float) -> void:
	kept = jars
	var space := place.space
	for k in space.jars.size():
		var f := clampf(jars - k, 0.0, 1.0)
		if f <= 0.01:
			_fill.multimesh.set_instance_transform(k, LeafKit.hidden())
			continue
		var at: Vector3 = space.jars[k]
		var h := JAR_HEIGHT * 0.86 * f
		var basis := Basis.from_scale(Vector3(JAR_RADIUS * 0.86, h, JAR_RADIUS * 0.86))
		_fill.multimesh.set_instance_transform(k, Transform3D(basis, at + Vector3(0, -JAR_HEIGHT * 0.5 + 0.04, 0)))
		_fill.multimesh.set_instance_color(k, FILL_LOW.lerp(FILL_HIGH, f))


## Day or night: the stars and the moon.
func set_night(on: bool) -> void:
	_night = on
	if _stars:
		_stars.visible = on
		_moon.visible = on
		_moon_halo.visible = on


func _build_stores() -> void:
	var m := LeafKit.Mesher.new()
	for c: Dictionary in place.space.cells:
		if str(c.kind) != "store":
			continue
		var r := float(c.radius)
		var xf := Transform3D(Basis(Vector3.UP, float(c.turn)).scaled(Vector3(1.0, float(c.squash), 1.0)), c.at)
		m.ball(xf, r, STORE.lightened(0.05), STORE, 22, 14, 0.05, float(c.turn), 0.0)
		m.ball(xf, r * 0.9, WATER, Color(WATER, 0.05), 18, 10)
	place.tint_with_weather(LeafKit.mesh(self, "WaterStores", m.commit(), LeafKit.glass()))


func _build_jars() -> void:
	var glass := LeafKit.Mesher.new()
	for at: Vector3 in place.space.jars:
		var foot := at - Vector3(0, JAR_HEIGHT * 0.5, 0)
		glass.tube(foot, foot + Vector3(0, JAR_HEIGHT, 0), JAR_RADIUS, JAR_RADIUS * 0.94, JAR_GLASS, JAR_GLASS, 16, true)
		glass.tube(foot + Vector3(0, JAR_HEIGHT, 0), foot + Vector3(0, JAR_HEIGHT + 0.08, 0), JAR_RADIUS * 0.7,
			JAR_RADIUS * 0.72, Color(0.85, 0.95, 1.0, 0.5), Color(0.85, 0.95, 1.0, 0.5), 16, true)
	place.tint_with_weather(LeafKit.mesh(self, "Jars", glass.commit(), LeafKit.glass()))
	var fill := LeafKit.Mesher.new()
	fill.tube(Vector3.ZERO, Vector3(0, 1, 0), 1.0, 1.0, Color(0.85, 0.85, 0.95), Color.WHITE, 14, true)
	var bounds := AABB(Vector3(-LeafPlace.HAZE, -1.0, -LeafPlace.HAZE), Vector3(LeafPlace.HAZE * 2.0, 12.0, LeafPlace.HAZE * 2.0))
	_fill = LeafKit.multimesh(self, "JarFill", fill.commit(), LeafKit.glow(), place.space.jars.size(), bounds)


func _build_sky() -> void:
	var m := LeafKit.Mesher.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	for k in 260:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.18, 1.0), rng.randf_range(-1, 1)).normalized()
		var at := Vector3(0, LeafSpace.ROOF, 0) + dir * 36.0
		var s := rng.randf_range(0.05, 0.16)
		var col := Color(1.0, 0.98, 0.9).lerp(Color("cfe0ff"), rng.randf())
		m.ball(Transform3D(Basis(), at), s, col, col, 4, 2)
	_stars = LeafKit.mesh(self, "Stars", m.commit(), LeafKit.glow())
	var moon_dir := Vector3(-0.45, 0.8, -0.4).normalized()
	var moon_at := Vector3(0, LeafSpace.ROOF, 0) + moon_dir * 33.0
	var d := LeafKit.Mesher.new()
	d.disc(Transform3D(LeafPlace._facing(-moon_dir), moon_at), 2.2, Color("fbf6dc"), Color("e8dfb4"), 24)
	_moon = LeafKit.mesh(self, "Moon", d.commit(), LeafKit.glow())
	_moon_halo = LeafKit.glow_disc(self, "MoonHalo", moon_at + moon_dir * 0.3, -moon_dir, 6.5, Color(0.78, 0.85, 1.0, 0.34))
