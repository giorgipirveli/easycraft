class_name SpaceBookRules
extends RefCounted
## The Space Book (owner #72, #74; spec §21b.2): every body of the Star Map as a page of the book, its card's facts once
## the child opened it on the Star Map (WonderData.SEEN), a flag once they landed there (LANDED). Pure rules; the book's
## page is SpaceBookPage.


## "5 of 29 seen · landed on 2" (the landing part once there is one).
static func count_words(w: WonderData) -> String:
	var seen := 0
	var landed := 0
	for id: String in w.bodies:
		seen += 1
		if int(w.bodies[id]) & WonderData.LANDED:
			landed += 1
	var words := "%d of %d seen" % [seen, StarMap.bodies().size()]
	return words + (" · landed on %d" % landed if landed > 0 else "")


static func marks(w: WonderData, id: StringName) -> int:
	return int(w.bodies.get(str(id), 0))


## Where to find a body not seen yet.
static func clue(id: StringName) -> String:
	var b := StarMap.body(id)
	if str(b.get("kind", "")) in ["game", "universe"]:
		return "Fly up to space and look far away on the Star Map: tap it to learn about it."
	return "Fly up to space and find it on the Star Map: tap it to learn about it."
