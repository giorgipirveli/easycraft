#!/usr/bin/env bash
# Owner #123's spike (docs/devlog/parts/same-version.md, first section): what can a pack loaded at run time change?
#
#   tools/android_update_spike.sh <empty work folder>
#
# Builds a tiny project twice (A, the "installed app", and B, the "newer game"), exports A's whole pack and B's patch
# against it (--export-patch ... --patches A.pck, Godot 4.4+), then starts A's pack headless the way an installed app
# starts (--main-pack) with and without the patch loaded by its first autoload, and prints every SPIKE line. What B
# changes: a script with a class_name, a new class_name script (the global class cache), the second autoload's script,
# a new autoload, a new input action and the version (project.binary), a scene, JSON data, a texture, a new file found
# by its uid, the first autoload's own script, and a file B deleted. Never touches the game: the work folder is yours.
set -euo pipefail

WORK="${1:?usage: tools/android_update_spike.sh <empty work folder>}"
mkdir -p "$WORK"
WORK="$(cd "$WORK" && pwd)"
GODOT="${GODOT:-godot}"
A="$WORK/proj_a"
B="$WORK/proj_b"
rm -rf "$A" "$B" "$WORK/out" "$WORK/xdg"
mkdir -p "$A/data" "$WORK/out" "$WORK/xdg"

# --- project A: the installed app ------------------------------------------------------------------------------------
cat > "$A/project.godot" <<'EOF'
config_version=5

[application]

config/name="UpdateSpike"
config/version="1.0.0"
run/main_scene="res://main.tscn"

[autoload]

First="*res://first.gd"
Second="*res://second.gd"
EOF

cat > "$A/export_presets.cfg" <<'EOF'
[preset.0]

name="Linux"
platform="Linux"
runnable=true
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="../out/a.x86_64"
patches=PackedStringArray()
encryption_include_filters=""
encryption_exclude_filters=""
seed=0
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

binary_format/embed_pck=false
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
binary_format/architecture="x86_64"
EOF

# The first autoload: the updater's stand-in. It loads the pack named by SPIKE_PATCH (replace_files = true) in _init,
# before the engine has loaded any later autoload's script, and reports what it sees.
cat > "$A/first.gd" <<'EOF'
extends Node


func _init() -> void:
	print("SPIKE first.gd: version A (the running first autoload)")
	print("SPIKE before the pack: second.gd loaded yet = %s, global classes = %s" % [
		ResourceLoader.has_cached("res://second.gd"), _classes()])
	var p := OS.get_environment("SPIKE_PATCH")
	if p != "":
		var t := Time.get_ticks_usec()
		var ok := ProjectSettings.load_resource_pack(p, true)
		print("SPIKE load_resource_pack(%s, true) = %s in %d us" % [p.get_file(), ok, Time.get_ticks_usec() - t])
	print("SPIKE after the pack: global classes = %s" % [_classes()])
	print("SPIKE ProjectSettings: version = %s, input/spike_jump = %s, autoload/Third = %s" % [
		ProjectSettings.get_setting("application/config/version"), ProjectSettings.has_setting("input/spike_jump"),
		ProjectSettings.has_setting("autoload/Third")])
	var pb := read_project_binary(FileAccess.get_file_as_bytes("res://project.binary"))
	print("SPIKE res://project.binary as a file now says: version = %s, input/spike_jump = %s, autoload/Third = %s" % [
		pb.get("application/config/version"), pb.has("input/spike_jump"), pb.has("autoload/Third")])
	if pb.has("input/spike_jump"):
		# Can the input map follow the pack's project.binary at run time?
		ProjectSettings.set_setting("input/spike_jump", pb["input/spike_jump"])
		InputMap.load_from_project_settings()
		print("SPIKE after set_setting + InputMap.load_from_project_settings(): has spike_jump = %s, events = %s" % [
			InputMap.has_action("spike_jump"), InputMap.action_get_events("spike_jump") if InputMap.has_action("spike_jump") else []])


func _classes() -> Array:
	return ProjectSettings.get_global_class_list().map(func(c: Dictionary) -> String: return c["class"])


## project.binary: "ECFG", u32 count, then for each setting u32 key length, the key, u32 value length, the value
## (encode_variant with objects).
static func read_project_binary(b: PackedByteArray) -> Dictionary:
	var out := {}
	if b.size() < 8 or b.slice(0, 4).get_string_from_ascii() != "ECFG":
		return out
	var count := b.decode_u32(4)
	var at := 8
	for i in count:
		var kl := b.decode_u32(at)
		var key := b.slice(at + 4, at + 4 + kl).get_string_from_utf8()
		at += 4 + kl
		var vl := b.decode_u32(at)
		out[key] = bytes_to_var_with_objects(b.slice(at + 4, at + 4 + vl))
		at += 4 + vl
	return out
EOF

cat > "$A/second.gd" <<'EOF'
extends Node


func _init() -> void:
	print("SPIKE second.gd (the second autoload): version A")


func who() -> String:
	return "Second A"
EOF

cat > "$A/foo.gd" <<'EOF'
class_name Foo
extends RefCounted


static func who() -> String:
	return "Foo A"
EOF

cat > "$A/main.gd" <<'EOF'
extends Node


func _ready() -> void:
	print("SPIKE main.gd: version A")
	report(self)
	get_tree().quit()


static func report(n: Node) -> void:
	print("SPIKE Foo.who() = %s" % Foo.who())
	print("SPIKE data/info.json = %s" % FileAccess.get_file_as_string("res://data/info.json").strip_edges())
	print("SPIKE icon.png width = %d" % (load("res://icon.png") as Texture2D).get_width())
	print("SPIKE sub.tscn children = %d" % (load("res://sub.tscn") as PackedScene).instantiate().get_child_count())
	print("SPIKE InputMap has spike_jump = %s" % InputMap.has_action("spike_jump"))
	print("SPIKE /root/Third exists = %s" % (n.get_node_or_null("/root/Third") != null))
	print("SPIKE /root/Second.who() = %s" % n.get_node("/root/Second").call("who"))
	print("SPIKE deleted_in_b.txt.json still there = %s" % FileAccess.file_exists("res://data/deleted_in_b.json"))
EOF

cat > "$A/main.tscn" <<'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://main.gd" id="1"]

[node name="Main" type="Node"]
script = ExtResource("1")
EOF

cat > "$A/sub.tscn" <<'EOF'
[gd_scene format=3]

[node name="Sub" type="Node"]

[node name="One" type="Node" parent="."]
EOF

echo '{"says": "data A"}' > "$A/data/info.json"
echo '{"gone": "in B"}' > "$A/data/deleted_in_b.json"
/usr/bin/python3 - "$A/icon.png" 16 <<'PY'
import struct, sys, zlib
path, size = sys.argv[1], int(sys.argv[2])
raw = b"".join(b"\x00" + b"\xff\x80\x00\xff" * size for _ in range(size))
def chunk(t, d):
    return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
                       + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
PY

# --- project B: the newer game -----------------------------------------------------------------------------------------
cp -a "$A" "$B"
rm -f "$B/data/deleted_in_b.json"
sed -i 's/config\/version="1.0.0"/config\/version="1.0.1"/' "$B/project.godot"
sed -i 's/^Second="\*res:\/\/second.gd"$/Second="*res:\/\/second.gd"\nThird="*res:\/\/third.gd"/' "$B/project.godot"
cat >> "$B/project.godot" <<'EOF'

[input]

spike_jump={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":74,"key_label":0,"unicode":106,"location":0,"echo":false,"script":null)]
}
EOF
sed -i 's/version A (the running first autoload)/version B (the running first autoload)/' "$B/first.gd"
sed -i 's/version A/version B/; s/"Second A"/"Second B"/' "$B/second.gd"
sed -i 's/"Foo A"/"Foo B"/' "$B/foo.gd"
cat > "$B/third.gd" <<'EOF'
extends Node


func _init() -> void:
	print("SPIKE third.gd (an autoload only B has) made")
EOF
cat > "$B/bar.gd" <<'EOF'
class_name Bar
extends RefCounted


static func who() -> String:
	return "Bar (a class only B has)"
EOF
cat > "$B/bar_user.gd" <<'EOF'
extends RefCounted


static func ask() -> String:
	return Bar.who()
EOF
cat > "$B/sub.tscn" <<'EOF'
[gd_scene format=3]

[node name="Sub" type="Node"]

[node name="One" type="Node" parent="."]

[node name="Two" type="Node" parent="."]

[node name="Three" type="Node" parent="."]
EOF
echo '{"says": "data B"}' > "$B/data/info.json"
/usr/bin/python3 - "$B/icon.png" 32 <<'PY'
import struct, sys, zlib
path, size = sys.argv[1], int(sys.argv[2])
raw = b"".join(b"\x00" + b"\x00\x80\xff\xff" * size for _ in range(size))
def chunk(t, d):
    return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
                       + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
PY
cp "$B/icon.png" "$B/new_icon.png"

export XDG_DATA_HOME="$WORK/xdg" XDG_CONFIG_HOME="$WORK/xdg" XDG_CACHE_HOME="$WORK/xdg"
nice "$GODOT" --headless --path "$A" --import >"$WORK/out/import_a.log" 2>&1 || true
nice "$GODOT" --headless --path "$B" --import >"$WORK/out/import_b.log" 2>&1 || true
uid="$(sed -n 's/^uid="\(uid:\/\/[a-z0-9]*\)"$/\1/p' "$B/new_icon.png.import")"
cat > "$B/main.gd" <<EOF
extends Node


func _ready() -> void:
	print("SPIKE main.gd: version B")
	report(self)
	var bar_user: Variant = load("res://bar_user.gd")
	print("SPIKE bar_user.gd (uses the new class Bar) loads = %s" % (bar_user != null and (bar_user as GDScript).can_instantiate()))
	if bar_user != null and (bar_user as GDScript).can_instantiate():
		print("SPIKE Bar.who() through bar_user.gd = %s" % bar_user.ask())
	print("SPIKE new_icon.png by its uid ($uid) loads = %s" % (ResourceLoader.exists("$uid") and load("$uid") != null))
	get_tree().quit()


static func report(n: Node) -> void:
	print("SPIKE Foo.who() = %s" % Foo.who())
	print("SPIKE data/info.json = %s" % FileAccess.get_file_as_string("res://data/info.json").strip_edges())
	print("SPIKE icon.png width = %d" % (load("res://icon.png") as Texture2D).get_width())
	print("SPIKE sub.tscn children = %d" % (load("res://sub.tscn") as PackedScene).instantiate().get_child_count())
	print("SPIKE InputMap has spike_jump = %s" % InputMap.has_action("spike_jump"))
	print("SPIKE /root/Third exists = %s" % (n.get_node_or_null("/root/Third") != null))
	print("SPIKE /root/Second.who() = %s" % n.get_node("/root/Second").call("who"))
	print("SPIKE deleted_in_b.txt.json still there = %s" % FileAccess.file_exists("res://data/deleted_in_b.json"))
EOF
nice "$GODOT" --headless --path "$B" --import >>"$WORK/out/import_b.log" 2>&1 || true

# --- export: A's whole pack, B's whole pack, and B's patch against A ---------------------------------------------------
nice "$GODOT" --headless --path "$A" --export-pack "Linux" "$WORK/out/a.pck" >"$WORK/out/export_a.log" 2>&1
nice "$GODOT" --headless --path "$B" --export-pack "Linux" "$WORK/out/b.pck" >"$WORK/out/export_b.log" 2>&1
nice "$GODOT" --headless --path "$B" --export-patch "Linux" "$WORK/out/b_patch.pck" --patches "$WORK/out/a.pck" \
	>"$WORK/out/export_patch.log" 2>&1
ls -l "$WORK/out/"*.pck
/usr/bin/python3 "$(dirname "$0")/pck_tool.py" list "$WORK/out/b_patch.pck" | sed 's/^/PATCH_FILE /'

run() {   # label, env assignment...
	local label="$1"; shift
	echo "=== $label"
	(cd "$WORK" && env "$@" nice "$GODOT" --headless --main-pack "$WORK/out/a.pck" 2>&1 | grep -E "SPIKE|ERROR|error" || true)
}
run "A alone (the installed app as it is)" SPIKE_PATCH=
run "A with B's patch loaded by the first autoload" SPIKE_PATCH="$WORK/out/b_patch.pck"
echo "=== B's whole pack as the main pack (what --main-pack would start)"
(cd "$WORK" && nice "$GODOT" --headless --main-pack "$WORK/out/b.pck" 2>&1 | grep -E "SPIKE|ERROR|error" || true)
