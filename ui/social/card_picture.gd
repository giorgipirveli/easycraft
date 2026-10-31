class_name CardPicture
extends RefCounted
## Owner #81, #82, #85: a card the game draws (the Daily Mission's card, a postcard) as a picture to keep or share, the
## way photo mode's photos go (M3 §14.14, M7 spec §20.3): Android's gallery and share sheet (PhotoShare), a browser's
## download (and its share sheet for the words and the link: WebGlue.share), a desktop's photo folder. Headless runs
## draw nothing: render() gives null there and the pages say so kindly.

const BACKGROUND := Color("0f1a33")
const FAILED := "We couldn't make the picture here. COPY still works!"


## Draws `card` (it is freed after) centred on a picture of `px` pixels. Awaits one drawn frame. null when this device
## draws nothing (headless) or the drawing failed.
static func render(host: Node, card: Control, px: Vector2i) -> Image:
	if host == null or not host.is_inside_tree() or DisplayServer.get_name() == "headless":
		card.free()
		return null
	var vp := SubViewport.new()
	vp.size = px
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var back := ColorRect.new()
	back.color = BACKGROUND
	back.size = Vector2(px)
	vp.add_child(back)
	card.theme = UiKit.theme()
	vp.add_child(card)
	card.size = card.get_combined_minimum_size()
	card.position = (Vector2(px) - card.size) * 0.5
	host.add_child(vp)
	await RenderingServer.frame_post_draw
	var img: Image = null
	var tex := vp.get_texture()
	if tex:
		img = tex.get_image()
	vp.queue_free()
	return img if img != null and not img.is_empty() else null


static func png_of(img: Image) -> PackedByteArray:
	if img == null:
		return PackedByteArray()
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	return img.save_png_to_buffer()


## Keeps the picture where photos go here: {"text" (for the child), "path" ("" when nothing was written)}.
static func save_png(png: PackedByteArray) -> Dictionary:
	if png.is_empty():
		return {"text": FAILED, "path": ""}
	var way := PlatformRules.photo_save(PlatformRules.current())
	var t := Time.get_datetime_dict_from_system()
	if way == PlatformRules.PHOTO_DOWNLOAD:
		var ok := WebGlue.download(png, PhotoFiles.download_name(t), PhotoShare.MIME)
		return {"text": "Your picture is downloading!" if ok else FAILED, "path": ""}
	var gallery := way == PlatformRules.PHOTO_GALLERY
	var pictures := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES) if gallery else ""
	var path := PhotoFiles.write_png(png, PhotoFiles.folders(gallery, pictures), t)
	if path == "":
		return {"text": FAILED, "path": ""}
	return {"text": PhotoFiles.where_message(path, pictures, gallery), "path": path}


## The button that keeps the picture here: SAVE PICTURE, or DOWNLOAD in a browser.
static func save_label() -> String:
	return "DOWNLOAD" if PlatformRules.photo_save(PlatformRules.current()) == PlatformRules.PHOTO_DOWNLOAD else "SAVE PICTURE"


## Whether SHARE shows: a browser's share sheet (the words and the link), or Android's (the picture), where a grown-up's
## switch allows sharing (PhotoRules.may_share: on for 13+; age rules are off, so on for everyone now).
static func can_share(profile: ProfileData) -> bool:
	if not PhotoRules.may_share(profile.age_band, profile.photo_share):
		return false
	return WebGlue.can_share() or PlatformRules.photo_save(PlatformRules.current()) == PlatformRules.PHOTO_GALLERY


## SHARE: the browser's sheet with the words and the link, or Android's sheet with the picture. What happened, for the
## child ("" when the sheet opened).
static func share(text: String, url: String, png: PackedByteArray) -> String:
	if WebGlue.can_share():
		return "" if WebGlue.share(text, url) else "Sharing doesn't work here. COPY still works!"
	if png.is_empty():
		return FAILED
	var kept := save_png(png)
	match PhotoShare.share(png, str(kept.path)):
		&"sheet":
			return ""
		&"viewer":
			return "Tap Share on your picture!"
		&"folder":
			return "Your pictures folder is open"
		&"download":
			return "Your picture is downloading!"
	return "Sharing doesn't work here. Your picture is saved!"
