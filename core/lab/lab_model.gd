class_name LabModel
extends RefCounted
## Spec §23.1: the rules of one experiment's small scene (the Science Lab's step 2, TRY IT), with no nodes: its state,
## what each tap does, what just happened in a few words (`last`, the status line) and whether the child has seen what
## the experiment shows (`done`). Nothing can be failed and every step is a tap. The Lab's views (LabView) draw a
## model; LabModels makes one from a scene's data.

## The scene's kind (LabModels.KINDS) and its data (data/lab/<id>.json "scene").
var kind := ""
var scene: Dictionary
## What the last tap did ("The wood floats!"), "" before the first.
var last := ""


func _init(s: Dictionary = {}) -> void:
	scene = s
	kind = str(s.get("kind", ""))


## True once the child has seen what the experiment shows (then WHAT HAPPENED? opens).
func done() -> bool:
	return false


## A thing's name in a sentence: "the wood", "the iron nail".
static func the(name: String) -> String:
	return "the " + name.to_lower()


## `text` with a capital first letter.
static func sentence(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)
