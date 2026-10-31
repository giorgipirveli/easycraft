class_name PhotoFrames
extends RefCounted
## Photo frames (M3 §14.14), drawn by the UI over the picture (PhotoFrameOverlay) and saved with it.
## Sizes are fractions of the picture's height, so a frame looks the same on every screen.

enum Frame { NONE, PHOTO, FILM, STARS, GOLD }

const ORDER: Array[int] = [Frame.NONE, Frame.PHOTO, Frame.FILM, Frame.STARS, Frame.GOLD]
const LABELS := {Frame.NONE: "NONE", Frame.PHOTO: "PHOTO", Frame.FILM: "FILM", Frame.STARS: "STARS", Frame.GOLD: "GOLD"}

## [left/right, top, bottom] border of each frame, as fractions of the picture's height.
const BORDERS := {
	Frame.NONE: [0.0, 0.0, 0.0],
	Frame.PHOTO: [0.04, 0.04, 0.13],   # an instant photo: a wider strip at the bottom for the caption
	Frame.FILM: [0.0, 0.11, 0.11],     # film strip bars with holes
	Frame.STARS: [0.035, 0.035, 0.035],
	Frame.GOLD: [0.05, 0.05, 0.05],
}


## The part of a picture of `size` that the frame leaves free.
static func inner_rect(frame: int, size: Vector2) -> Rect2:
	var b: Array = BORDERS.get(frame, BORDERS[Frame.NONE])
	var side: float = b[0] * size.y
	var top: float = b[1] * size.y
	var bottom: float = b[2] * size.y
	return Rect2(side, top, size.x - side * 2.0, size.y - top - bottom)
