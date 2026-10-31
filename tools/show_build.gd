extends SceneTree
## Shows a build from a report (M4 Wave 3, agent I): a report about a present, a bottle or a showcase keeps
## the build as one text (report_build's "build": {"build": "<base64>", ...}); a person reviewing it in the
## Nakama console copies that text into a file and runs
##   godot --headless --path . --script res://tools/show_build.gd -- --file=<the file>
## (or -- --build=<the text>). It prints the size, how many of each block, and every layer from the ground
## up as letters (a legend first), so the reviewer can see what was built without the game.


func _initialize() -> void:
	var text := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--build="):
			text = a.trim_prefix("--build=")
		elif a.begins_with("--file="):
			text = FileAccess.get_file_as_string(a.trim_prefix("--file="))
	text = _only_build(text.strip_edges())
	var blocks := BuildCodec.decode(text, BuildCodec.SHOWCASE)
	if blocks.is_empty():
		print("SHOW_BUILD this is not a build (paste the text of \"build\" from the report)")
		quit(1)
		return
	var size := BuildCodec.size_of(text)
	print("SHOW_BUILD size %d x %d x %d, %d blocks" % [size.x, size.y, size.z, blocks.size()])
	var letters := {}
	var counts := {}
	for p: Vector3i in blocks:
		var id: int = blocks[p]
		counts[id] = int(counts.get(id, 0)) + 1
		if not letters.has(id):
			letters[id] = _letter(letters.size())
	for id: int in counts:
		print("  %s = %s (%d)" % [letters[id], BlockIds.display_name(id) if BlockIds.display_name(id) != "" else "block %d" % id, counts[id]])
	for y in size.y:
		var rows: Array[String] = []
		var any := false
		for z in size.z:
			var row := ""
			for x in size.x:
				var p := Vector3i(x, y, z)
				row += letters[blocks[p]] if blocks.has(p) else "."
				any = any or blocks.has(p)
			rows.append(row)
		if any:
			print("layer %d:" % y)
			for r in rows:
				print("  " + r)
	quit(0)


## The build text alone, from a report's JSON if that was pasted.
func _only_build(text: String) -> String:
	if not text.begins_with("{"):
		return text
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return text
	var d: Dictionary = json.data
	var b: Variant = d.get("build")
	if b is Dictionary:
		return str((b as Dictionary).get("build", ""))
	return str(b) if b is String else text


static func _letter(i: int) -> String:
	const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	return ALPHABET[i % ALPHABET.length()]
