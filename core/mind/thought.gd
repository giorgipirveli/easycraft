class_name Thought
extends RefCounted
## What a creature's thought bubble can show (M2 Task 18, spec §12.17): a picture, never words, so
## children who can't read yet can read a mind. The pictures are drawn by
## tools/make_thought_pictures.gd into data/minds/thoughts.png, one 16 px tile each, in this order.

const NONE := -1
const HEART := 0          # it likes a player near it
const QUESTION := 1       # curious
const ZZZ := 2            # sleepy
const FOOD := 3           # hungry (a drumstick)
const SWEAT := 4          # scared (a sweat drop)
const BULB := 5           # a friend learned something (a light bulb)
const COUNT := 6
const NAMES: Array[String] = ["heart", "question", "zzz", "food", "sweat", "bulb"]


static func valid(id: int) -> bool:
	return id >= 0 and id < COUNT
