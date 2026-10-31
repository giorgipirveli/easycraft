class_name WishingWell
extends SecretThing
## A wishing well's opening (owner feedback #42, spec §12.16b): a tap tosses a coin (a free, pretend one) and
## asks the host (Session.request_wish), whose TreasureDirector gives the day's small fixed gift once per
## in-game day for each player. The well itself is blocks; this is its tap box and a bucket under its roof.


## data = {id, pos (the opening's cell, bottom middle), secret}
func setup(data: Dictionary) -> void:
	_base(data, Vector3(0.9, 0.9, 0.9), Vector3(0, 0.45, 0))
	var bucket := _mesh(TreasureModels.bucket())
	bucket.position = Vector3(0, 1.7, 0)


## A tap: toss a coin.
func use_tap(_hud: Node) -> bool:
	Session.request_wish(String(name))
	return true
