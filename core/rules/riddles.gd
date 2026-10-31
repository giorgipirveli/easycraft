class_name Riddles
extends RefCounted
## Words and pictures of the secrets (M2 Task 16, spec §12.16): the hints on riddle notes in hidden rooms,
## the picture order of a temple's plates, and the Wanderer's riddles. Children who can't read yet go by
## the pictures (the picture atlas data/secrets/pictures.png, drawn by tools/make_secret_pictures.gd);
## every text is short and simple, so it can be read aloud later.

# Pictures: tiles of the picture atlas, 8 per row (Pictures.texture(id)).
const SUN := 0
const MOON := 1
const STAR := 2
const CLOCK := 3
const TREE := 4
const FISH := 5
const APPLE := 6
const CLOUD := 7
const KEY := 8
const CAT := 9
const HOUSE := 10
const BALL := 11
const FLOWER := 12
const HEART := 13
const CHEST := 14
const MAP_X := 15
# One picture per kind of secret (the Secret Book), and a few for the notes.
const ROOM_DOOR := 16
const ISLAND := 17
const GOLDEN := 18
const TEMPLE := 19
const WANDERER := 20
const GEODE := 21
const NOTE := 22
const QUESTION := 23
const PICTURE_COUNT := 24

## The short word under a picture answer.
const WORDS := {
	SUN: "sun", MOON: "moon", STAR: "star", CLOCK: "clock", TREE: "tree", FISH: "fish", APPLE: "apple",
	CLOUD: "cloud", KEY: "key", CAT: "cat", HOUSE: "house", BALL: "ball", FLOWER: "flower", HEART: "heart",
}

## The pictures painted on a temple's three plates; its note shows them in the order to step on them.
const TEMPLE_SYMBOLS: Array[int] = [SUN, MOON, STAR]
const TEMPLE_TEXT := "Step on them in this order!"

## Hidden-room notes: a short hint about another secret, with its picture.
const ROOM_NOTES: Array[Dictionary] = [
	{"text": "Knock knock! Some walls are hollow.", "pictures": [KEY]},
	{"text": "Stars fall on some nights. Look up!", "pictures": [STAR]},
	{"text": "An X on the grass? Dig down!", "pictures": [MAP_X]},
	{"text": "Gold floats up in the sky.", "pictures": [ISLAND]},
	{"text": "Golden animals are shy. Chase them!", "pictures": [GOLDEN]},
	{"text": "A stranger comes at sunset.", "pictures": [WANDERER]},
	{"text": "Deep down, rocks hide crystal balls.", "pictures": [GEODE]},
	{"text": "Old temples have plates. Step in order!", "pictures": [TEMPLE]},
	# Owner 42: hints at the treasure pack (hidden rooms' and ruins' notes).
	{"text": "Old ships sleep on the beach.", "pictures": [TreasureRules.SHIPWRECK_PICTURE]},
	{"text": "A lantern on a pillar? Go down!", "pictures": [TreasureRules.VAULT_PICTURE]},
	{"text": "Walk behind a waterfall!", "pictures": [TreasureRules.WATERFALL_PICTURE]},
	{"text": "Friendly ghosts love riddles.", "pictures": [TreasureRules.GHOST]},
	{"text": "Rainbows end in gold.", "pictures": [TreasureRules.RAINBOW_PICTURE]},
	{"text": "Mine carts wait at tunnel ends.", "pictures": [TreasureRules.MINESHAFT_PICTURE]},
]

## The Wanderer's riddles: a short question and three picture answers; `answer` is the right one's index.
const WANDERER_RIDDLES: Array[Dictionary] = [
	{"question": "I shine all day. What am I?", "choices": [MOON, SUN, FISH], "answer": 1},
	{"question": "I twinkle at night. What am I?", "choices": [STAR, APPLE, CAT], "answer": 0},
	{"question": "I have hands, but I can't clap.", "choices": [TREE, FISH, CLOCK], "answer": 2},
	{"question": "I am red and crunchy. Yum!", "choices": [APPLE, CLOUD, KEY], "answer": 0},
	{"question": "I swim, but I have no legs.", "choices": [CAT, FISH, HOUSE], "answer": 1},
	{"question": "I have leaves, but I am no book.", "choices": [KEY, SUN, TREE], "answer": 2},
	{"question": "I open doors. What am I?", "choices": [KEY, MOON, BALL], "answer": 0},
	{"question": "I say meow!", "choices": [TREE, CAT, CLOCK], "answer": 1},
	{"question": "I float up high and bring rain.", "choices": [HOUSE, APPLE, CLOUD], "answer": 2},
	{"question": "You live inside me.", "choices": [HOUSE, STAR, FISH], "answer": 0},
	{"question": "I bounce and roll.", "choices": [TREE, BALL, MOON], "answer": 1},
	{"question": "Bees love me.", "choices": [KEY, CLOCK, FLOWER], "answer": 2},
]


static func room_note(variant: int) -> Dictionary:
	return ROOM_NOTES[posmod(variant, ROOM_NOTES.size())]


static func wanderer_riddle(index: int) -> Dictionary:
	return WANDERER_RIDDLES[posmod(index, WANDERER_RIDDLES.size())]


static func word(picture: int) -> String:
	return WORDS.get(picture, TreasureRules.word(picture))   # owner 42: the treasure pack's pictures too
