class_name ShortStyle
extends RefCounted
## EasyCraft Shorts' style guide (owner #96, spec §5.12b "High quality, with real tools"), as rules the checker applies
## to every Short and the player draws by. In words, for whoever writes the next Short:
## - **Colour:** the game's palette only (ShortRules.COLOURS: UiKit's and the School's colours), a topic's own colour on
##   its frame, its caption band's edge and its list row. Words stand on a sticker (`box`) or on a dark outline, so they
##   read on any background: text and what is behind it at least MIN_CONTRAST apart (WCAG AA), else the outline (and
##   then a sticker still STICKER_CONTRAST apart from its words).
## - **Letters:** one typeface family, the game's own font (UiKit's theme; no other font is ever loaded), at a few sizes
##   (LETTER_SIZES: a size in the data is drawn at the nearest), never under MIN_LETTER on the 360 × 640 stage (a phone
##   held upright shows it about 430 px wide: 16 units are 19 px). Captions at CAPTION_SIZES, the biggest that fits.
## - **Safe margins:** actors stay inside SAFE (8 units from the sides, under the progress bars at the top) and above the
##   caption's band (ShortRules.CAPTION_TOP), except while flying in or out.
## - **Motion:** arrivals ease out (a slide, a drop with its bounce), a pop overshoots a little (the "back" curve, under
##   15 %), nothing slides at a constant speed (no linear slides or moves: drifts use "smooth"), about 12-18 frames a
##   move (ARRIVALS: each entrance's seconds; MOVE_MIN), counts and slow zooms may run evenly.
## - **Pacing:** the voice reads each scene's `say` and the caption shows its words, both at most WORDS_PER_SECOND
##   (about 2.5 words a second: a child reads along); one idea a Short, 3-6 scenes, 20-60 s, a question at the end.
## Pure: ShortCheck applies it, ShortActor and ShortPlayer draw by it; tests/integration/test_short_quality.gd measures
## the drawn frames (every actor inside the frame, no two words over each other).

## At 30 frames a second, the rate the guide counts frames at.
const FPS := 30.0
const WORDS_PER_SECOND := 2.5
const LETTER_SIZES: Array[int] = [16, 20, 24, 28, 34, 40, 46, 56, 64, 80, 110]
const MIN_LETTER := 16
const CAPTION_SIZES: Array[int] = [30, 27, 24, 21, 18]
const MIN_CAPTION := 18
const SAFE := Rect2(8, 24, 344, 608)
const MIN_CONTRAST := 4.5
const STICKER_CONTRAST := 2.0
## The dark outline round words (and its width: a fifth of the letters, at least 4).
const OUTLINE := Color(0.05, 0.06, 0.1)
## Each entrance's (and the exit's) seconds, least and most: about 12-18 frames, a drop's bounces and a long line's
## drawing a little longer.
const ARRIVALS := {"pop": [0.3, 0.8], "slide": [0.35, 1.0], "drop": [0.5, 1.4], "out": [0.2, 0.7], "draw": [0.3, 2.5],
	"fade": [0.2, 1.5]}
const MOVE_MIN := 0.4
## Moves that go somewhere never at a constant speed.
const EASED: Array[String] = ["move", "slide"]


static func letter_size(v: Variant) -> int:
	var want := float(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else 32.0
	var best := LETTER_SIZES[0]
	for s in LETTER_SIZES:
		if absf(s - want) < absf(best - want):
			best = s
	return best


static func outline_of(letter: int) -> int:
	return maxi(4, letter / 5)


## Frames a move of `seconds` lasts (at FPS).
static func frames(seconds: float) -> int:
	return roundi(seconds * FPS)


## WCAG's contrast ratio of two colours (1 to 21).
static func contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _luminance(c: Color) -> float:
	var ch := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * float(ch.call(c.r)) + 0.7152 * float(ch.call(c.g)) + 0.0722 * float(ch.call(c.b))


## Words in `text` colour on `behind` (a sticker's colour, or null: the backdrop) need the dark outline.
static func needs_outline(text: Color, behind: Variant) -> bool:
	return not (behind is Color) or contrast(text, behind) < MIN_CONTRAST


## Words in `text` colour on `behind` read well: on their sticker (MIN_CONTRAST apart), or on their dark outline (then
## still at least STICKER_CONTRAST apart from a sticker: white on yellow is never used, even outlined).
static func legible(text: Color, behind: Variant) -> bool:
	if behind is Color:
		var c := contrast(text, behind)
		if c >= MIN_CONTRAST:
			return true
		if c < STICKER_CONTRAST:
			return false
	return contrast(text, OUTLINE) >= MIN_CONTRAST
