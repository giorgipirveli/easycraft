class_name ProgressPictures
extends RefCounted
## The pictures of the adventure board, the badges and the presents (M3 Task 12): children who can't
## read yet pick goals by their picture. Most come from pictures the game already has (the secrets'
## atlas, block and item icons, the slime, the coin, the HUD's camera); a few are drawn here in code,
## like HudIcons (a few shapes each, no textures, no materials). `draw` fits one into a square.

const INK := Color.WHITE
const DARK := Color(0.1, 0.12, 0.2, 0.95)

## name -> [source, what]: &"secret" (a Riddles picture), &"block" (a block or item id), &"hud" (a
## HudIcons symbol), &"texture" (&"monster" or &"coin"), &"draw" (drawn below).
const SOURCES := {
	&"cat": [&"secret", Riddles.CAT], &"geode": [&"secret", Riddles.GEODE], &"chest": [&"secret", Riddles.CHEST],
	&"room": [&"secret", Riddles.ROOM_DOOR], &"temple": [&"secret", Riddles.TEMPLE],
	&"island": [&"secret", Riddles.ISLAND], &"question": [&"secret", Riddles.QUESTION],
	&"golden": [&"secret", Riddles.GOLDEN], &"wanderer": [&"secret", Riddles.WANDERER],
	&"star": [&"secret", Riddles.STAR], &"map": [&"secret", Riddles.MAP_X], &"flower": [&"secret", Riddles.FLOWER],
	&"heart": [&"secret", Riddles.HEART],
	&"wand": [&"block", ItemIds.WAND], &"brick": [&"block", BlockIds.BRICK], &"lantern": [&"block", BlockIds.LANTERN],
	&"planks": [&"block", BlockIds.PLANKS],
	&"photo": [&"hud", &"photo"],
	&"monster": [&"texture", &"monster"], &"coin": [&"texture", &"coin"],
	&"dog": [&"draw", &"dog"], &"goblin": [&"draw", &"goblin"], &"totem": [&"draw", &"totem"],
	&"golem": [&"draw", &"golem"], &"flag": [&"draw", &"flag"], &"friends": [&"draw", &"friends"],
	&"board": [&"draw", &"board"], &"level": [&"draw", &"level"], &"gift": [&"draw", &"gift"],
	&"trophy": [&"draw", &"trophy"], &"lock": [&"draw", &"lock"],
	# Owner #45a: the new goals, the quest givers, their steps and keepsakes (QuestPictures draws &"quest" ones).
	&"house": [&"secret", Riddles.HOUSE], &"key": [&"secret", Riddles.KEY],
	&"shipwreck": [&"secret", TreasureRules.SHIPWRECK_PICTURE], &"vault": [&"secret", TreasureRules.VAULT_PICTURE],
	&"haunted": [&"secret", TreasureRules.HAUNTED_PICTURE], &"well": [&"secret", TreasureRules.WELL_PICTURE],
	&"rainbow": [&"secret", TreasureRules.RAINBOW_PICTURE], &"mineshaft": [&"secret", TreasureRules.MINESHAFT_PICTURE],
	&"ruins": [&"secret", TreasureRules.RUINS_PICTURE], &"hollow": [&"secret", TreasureRules.HOLLOW_PICTURE],
	&"camp": [&"secret", TreasureRules.CAMP_PICTURE],
	&"table": [&"block", BlockIds.CRAFTING_TABLE], &"glass": [&"block", BlockIds.GLASS],
	&"pickaxe_stone": [&"block", ItemIds.PICKAXE_STONE], &"sword_iron": [&"block", ItemIds.SWORD_IRON],
	&"treat": [&"block", ItemIds.TREAT_BISCUIT], &"ride": [&"hud", &"ride"],
	&"mummy": [&"quest", &"mummy"], &"scorpion": [&"quest", &"scorpion"], &"serpent": [&"quest", &"serpent"],
	&"pyramid": [&"quest", &"pyramid"], &"yeti": [&"quest", &"yeti"], &"bat": [&"quest", &"bat"],
	&"giant": [&"quest", &"giant"], &"gummy": [&"quest", &"gummy"], &"sneaker": [&"quest", &"sneaker"],
	&"cake": [&"quest", &"cake"], &"fox": [&"quest", &"fox"], &"parrot": [&"quest", &"parrot"],
	&"horse": [&"quest", &"horse"], &"camel": [&"quest", &"camel"], &"penguin": [&"quest", &"penguin"],
	&"medal": [&"quest", &"medal"], &"dragon": [&"quest", &"dragon"], &"scroll": [&"quest", &"scroll"],
	&"bell": [&"quest", &"bell"], &"star_jar": [&"quest", &"star_jar"], &"scarab": [&"quest", &"scarab"],
	&"compass": [&"quest", &"compass"], &"snow_globe": [&"quest", &"snow_globe"], &"ice_crown": [&"quest", &"ice_crown"],
	&"cupcake": [&"quest", &"cupcake"], &"recipe": [&"quest", &"recipe"], &"tilly": [&"quest", &"tilly"],
	&"zara": [&"quest", &"zara"], &"bram": [&"quest", &"bram"], &"mimi": [&"quest", &"mimi"],
	&"nell": [&"quest", &"nell"],   # owner #39's Dragon Realm helper
	&"mira": [&"quest", &"mira"],   # universe 6: the Glow Caves' helper, and its things
	&"spore_lamp": [&"block", BlockIds.SPORE_LAMP], &"pearl": [&"block", BlockIds.CAVE_PEARL],
	&"selenite": [&"block", BlockIds.SELENITE],
	&"lab": [&"block", BlockIds.LAB_BENCH],   # spec §23: the Science Lab (the book's LAB tab)
}


static func knows(picture: StringName) -> bool:
	return SOURCES.has(picture)


## The picture as a texture, for the ones that have one (null for the drawn ones).
static func texture(picture: StringName) -> Texture2D:
	var s: Array = SOURCES.get(picture, [])
	if s.is_empty():
		return null
	match s[0]:
		&"secret":
			return Pictures.texture(int(s[1]))
		&"block":
			return BlockIcons.icon(int(s[1]))
		&"texture":
			return MonsterIcon.texture() if s[1] == &"monster" else CoinIcon.texture()
	return null


## Draws `picture` into the square `r` of `ci` (called from its _draw). `dim`: a locked badge's shadow.
static func draw(ci: CanvasItem, picture: StringName, r: Rect2, dim: bool = false) -> void:
	var s: Array = SOURCES.get(picture, [&"draw", &"lock"])
	var shade := Color(0, 0, 0, 0.75) if dim else Color.WHITE
	match s[0]:
		&"hud":
			HudIcons.draw(ci, s[1], r.grow(-r.size.x * 0.06), shade if dim else INK)
		&"draw":
			_drawn(ci, s[1], r, dim)
		&"quest":
			QuestPictures.draw(ci, s[1], r, dim)   # owner #45a
		_:
			var t := texture(picture)
			if t:
				ci.draw_texture_rect(t, r, false, shade)


static func _drawn(ci: CanvasItem, what: StringName, r: Rect2, dim: bool) -> void:
	var p := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var u := r.size.x
	var c := func(col: Color) -> Color: return Color(0, 0, 0, 0.75) if dim else col
	match what:
		&"dog":
			var fur: Color = c.call(Color("c8924e"))
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.14, 0.2), p.call(0.34, 0.16), p.call(0.3, 0.62),
				p.call(0.12, 0.56)]), c.call(Color("7a5230")))
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.86, 0.2), p.call(0.66, 0.16), p.call(0.7, 0.62),
				p.call(0.88, 0.56)]), c.call(Color("7a5230")))
			ci.draw_rect(Rect2(p.call(0.26, 0.2), Vector2(0.48, 0.56) * u), fur)
			ci.draw_rect(Rect2(p.call(0.34, 0.56), Vector2(0.32, 0.3) * u), c.call(Color("f3e3c3")))
			for x: float in [0.4, 0.6]:
				ci.draw_circle(p.call(x, 0.42), u * 0.05, c.call(DARK))
			ci.draw_circle(p.call(0.5, 0.62), u * 0.06, c.call(DARK))
		&"goblin":
			var skin: Color = c.call(Color("7cb342"))
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.06, 0.3), p.call(0.3, 0.4), p.call(0.28, 0.54)]), skin)
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.94, 0.3), p.call(0.7, 0.4), p.call(0.72, 0.54)]), skin)
			ci.draw_rect(Rect2(p.call(0.26, 0.2), Vector2(0.48, 0.6) * u), skin)
			for x: float in [0.4, 0.6]:
				ci.draw_circle(p.call(x, 0.44), u * 0.06, c.call(Color("fff59d")))
				ci.draw_circle(p.call(x, 0.45), u * 0.03, c.call(DARK))
			ci.draw_rect(Rect2(p.call(0.38, 0.62), Vector2(0.24, 0.06) * u), c.call(DARK))
		&"totem":
			var cols: Array[Color] = [Color("8d6e63"), Color("6d4c41"), Color("8d6e63")]
			for i in 3:
				ci.draw_rect(Rect2(p.call(0.3, 0.36 + 0.2 * i), Vector2(0.4, 0.18) * u), c.call(cols[i]))
				ci.draw_circle(p.call(0.42, 0.44 + 0.2 * i), u * 0.035, c.call(DARK))
				ci.draw_circle(p.call(0.58, 0.44 + 0.2 * i), u * 0.035, c.call(DARK))
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.04), p.call(0.64, 0.2), p.call(0.5, 0.34),
				p.call(0.36, 0.2)]), c.call(Color("ce93d8")))
		&"golem":
			ci.draw_rect(Rect2(p.call(0.18, 0.14), Vector2(0.64, 0.72) * u), c.call(Color("9e9e9e")))
			ci.draw_rect(Rect2(p.call(0.18, 0.14), Vector2(0.64, 0.14) * u), c.call(Color("757575")))
			for x: float in [0.36, 0.64]:
				ci.draw_rect(Rect2(p.call(x - 0.08, 0.38), Vector2(0.16, 0.1) * u), c.call(Color("ffb74d")))
			ci.draw_rect(Rect2(p.call(0.34, 0.62), Vector2(0.32, 0.08) * u), c.call(Color("616161")))
		&"flag":
			ci.draw_rect(Rect2(p.call(0.2, 0.08), Vector2(0.06, 0.86) * u), c.call(Color("8d6e63")))
			for i in 4:
				for j in 3:
					var black := (i + j) % 2 == 0
					ci.draw_rect(Rect2(p.call(0.26 + 0.14 * i, 0.12 + 0.12 * j), Vector2(0.14, 0.12) * u),
						c.call(DARK if black else INK))
		&"friends":
			for f: Array in [[0.32, Color("42a5f5")], [0.68, Color("ef5350")]]:
				ci.draw_circle(p.call(f[0], 0.28), u * 0.13, c.call(Color("ffcc80")))
				ci.draw_rect(Rect2(p.call(float(f[0]) - 0.15, 0.44), Vector2(0.3, 0.46) * u), c.call(f[1]))
		&"board":
			ci.draw_rect(Rect2(p.call(0.08, 0.14), Vector2(0.84, 0.72) * u), c.call(Color("a1887f")))
			ci.draw_rect(Rect2(p.call(0.14, 0.2), Vector2(0.72, 0.6) * u), c.call(Color("5d4037")))
			for i in 3:
				ci.draw_rect(Rect2(p.call(0.2 + 0.22 * i, 0.3), Vector2(0.16, 0.4) * u), c.call(Color("fff8e1")))
				ci.draw_circle(p.call(0.28 + 0.22 * i, 0.3), u * 0.03, c.call(Color("e53935")))
		&"level":
			_star(ci, p.call(0.5, 0.52), u * 0.46, u * 0.2, c.call(Color("ffd23f")))
			_star(ci, p.call(0.5, 0.52), u * 0.3, u * 0.13, c.call(Color("fff3c4")))
		&"gift":
			ci.draw_rect(Rect2(p.call(0.12, 0.36), Vector2(0.76, 0.54) * u), c.call(Color("ef5350")))
			ci.draw_rect(Rect2(p.call(0.08, 0.28), Vector2(0.84, 0.14) * u), c.call(Color("e53935")))
			ci.draw_rect(Rect2(p.call(0.44, 0.28), Vector2(0.12, 0.62) * u), c.call(Color("ffd23f")))
			ci.draw_circle(p.call(0.38, 0.2), u * 0.1, c.call(Color("ffd23f")))
			ci.draw_circle(p.call(0.62, 0.2), u * 0.1, c.call(Color("ffd23f")))
		&"trophy":
			var gold: Color = c.call(Color("ffd23f"))
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.24, 0.12), p.call(0.76, 0.12), p.call(0.66, 0.5),
				p.call(0.34, 0.5)]), gold)
			ci.draw_arc(p.call(0.24, 0.26), u * 0.12, PI * 0.5, PI * 1.5, 12, gold, u * 0.05)
			ci.draw_arc(p.call(0.76, 0.26), u * 0.12, -PI * 0.5, PI * 0.5, 12, gold, u * 0.05)
			ci.draw_rect(Rect2(p.call(0.45, 0.5), Vector2(0.1, 0.22) * u), gold)
			ci.draw_rect(Rect2(p.call(0.3, 0.72), Vector2(0.4, 0.14) * u), c.call(Color("8d6e63")))
		_:   # lock: an unknown picture, or a badge still to find
			ci.draw_arc(p.call(0.5, 0.4), u * 0.18, PI, TAU, 12, c.call(Color("b0bec5")), u * 0.08)
			ci.draw_rect(Rect2(p.call(0.26, 0.42), Vector2(0.48, 0.42) * u), c.call(Color("b0bec5")))
			ci.draw_circle(p.call(0.5, 0.6), u * 0.06, c.call(DARK))


static func _star(ci: CanvasItem, at: Vector2, outer: float, inner: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + PI * i / 5.0
		pts.append(at + Vector2(cos(a), sin(a)) * (outer if i % 2 == 0 else inner))
	ci.draw_colored_polygon(pts, col)

