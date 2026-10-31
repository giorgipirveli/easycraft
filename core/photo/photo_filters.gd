class_name PhotoFilters
extends RefCounted
## Photo filters (M3 §14.14). Every filter is a set of parameters for one post-process shader
## (ui/photo/photo_filter.gdshader) on one long-lived material; NORMAL switches the pass off.

enum Filter { NORMAL, WARM, COOL, BW, COMIC }

const ORDER: Array[int] = [Filter.NORMAL, Filter.WARM, Filter.COOL, Filter.BW, Filter.COMIC]
const LABELS := {Filter.NORMAL: "NORMAL", Filter.WARM: "WARM", Filter.COOL: "COOL", Filter.BW: "B&W", Filter.COMIC: "COMIC"}
## The colour of each filter's chip in photo mode.
const SWATCHES := {Filter.NORMAL: Color("7d8799"), Filter.WARM: Color("f08a1c"), Filter.COOL: Color("3a9be8"),
	Filter.BW: Color("3b3b3b"), Filter.COMIC: Color("c040d0")}
const SHADER_PATH := "res://ui/photo/photo_filter.gdshader"

## The untouched picture. Every key is a uniform of the shader.
const IDENTITY := {
	"tint": Vector3(1, 1, 1),   # colour multiplier
	"saturation": 1.0,
	"contrast": 1.0,
	"brightness": 0.0,
	"levels": 0.0,              # flat colour steps (posterise); 0 = smooth
	"outline": 0.0,             # dark edges (comic ink), 0..1
	"vignette": 0.0,            # darker corners, 0..1
}

const _CHANGES := {
	Filter.WARM: {"tint": Vector3(1.1, 1.0, 0.82), "saturation": 1.1, "brightness": 0.02, "vignette": 0.3},
	Filter.COOL: {"tint": Vector3(0.86, 0.98, 1.12), "saturation": 0.95, "vignette": 0.3},
	Filter.BW: {"saturation": 0.0, "contrast": 1.15},
	Filter.COMIC: {"saturation": 1.35, "contrast": 1.1, "levels": 5.0, "outline": 1.0},
}


static func params(filter: int) -> Dictionary:
	var p := IDENTITY.duplicate()
	p.merge(_CHANGES.get(filter, {}), true)
	return p


## NORMAL costs nothing: the full-screen pass is only drawn for the other filters.
static func uses_shader(filter: int) -> bool:
	return _CHANGES.has(filter)
