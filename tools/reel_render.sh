#!/usr/bin/env bash
# The Reel Studio (owner #96, spec §5.12b): renders a cinematic reel's picture to a Theora video.
#
#   tools/reel_render.sh <id> [--size=540x960|720x1280] [--q=3] [--blur=0.4] [--full] [--keep] [--encode]
#
# 1. Godot's Movie Maker (a real window, --fixed-fps 30) films the reel's 3D stage frame by frame (tools/reel_render.gd;
#    --full: the captions and stickers too, for a review copy) into PNG frames under build/reel_render/<id>/.
# 2. ffmpeg makes assets/reels/<id>.ogv: Theora, silent (the game plays the reel's voice, captions and sounds live over
#    it), a keyframe every 2 s (a seek decodes at most 60 frames), quality --q (3: measured on the Seven Wonders, 6 MB for
#    54 s and clean in moving shots; 5 was 27 MB) after a slight blur (--blur, pixels: the blocks' pixel art shimmers
#    frame to frame at a distance and that shimmer, not what a child sees, cost most of the bytes). Then its still
#    (assets/reels/<id>.jpg: the reel's "still" second, else its poster moment, 360 x 640) and a frame sheet of the
#    video (a picture every half second) to review: build/reel_render/<id>/<id>_video_sheet.png.
# 3. The numbers the tests check go in assets/reels/reels.json: bytes, seconds, pixels, the frames' brightness at a
#    quarter, half and three quarters (never a black or blank frame).
# --keep keeps the PNG frames; --encode encodes kept frames again without filming (to try --q and --blur).
# Renders run under nice, one at a time (the PC is shared). Never edit this script while it runs (bash reads it as it goes).
set -euo pipefail
GAME="$(cd "$(dirname "$0")/.." && pwd)"
cd "$GAME"
id="${1:?usage: tools/reel_render.sh <id> [--size=WxH] [--q=N] [--blur=S] [--full] [--keep] [--encode]}"
shift
size="540x960"
q=3
blur=0.4
full=""
keep=""
encode_only=""
for a in "$@"; do
	case "$a" in
		--size=*) size="${a#--size=}" ;;
		--q=*) q="${a#--q=}" ;;
		--blur=*) blur="${a#--blur=}" ;;
		--full) full="--full" ;;
		--keep) keep=1 ;;
		--encode) encode_only=1 ;;
	esac
done
w="${size%x*}"
h="${size#*x}"
out="build/reel_render/$id"
mkdir -p assets/reels
if [[ -z "$encode_only" ]]; then
	rm -rf "$out"
	mkdir -p "$out"
	data="$(mktemp -d)"   # a private user:// (never the player's saves)
	# The Movie Maker takes its picture's size from the window the project opens (display/window/size/*_override,
	# 960 x 540 in project.godot), not from --resolution: a temporary override.cfg (never committed) opens it at the
	# video's size.
	if [[ -e override.cfg ]]; then
		echo "reel_render: override.cfg is in the way (another render running?)" >&2
		exit 1
	fi
	printf '[display]\n\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\n' "$w" "$h" > override.cfg
	trap 'rm -rf "$data" override.cfg' EXIT
	echo "reel_render: filming $id at $size"
	XDG_DATA_HOME="$data" timeout 1800 nice godot --path . --write-movie "$out/frame.png" --fixed-fps 30 \
		--resolution "$size" --disable-vsync --script res://tools/reel_render.gd -- --short="$id" --movie $full \
		2>&1 | grep -E "^RENDER|SCRIPT ERROR|Parse Error" || true
	rm -f override.cfg
	# The Movie Maker's first frame is drawn before the reel's first pose: the video starts at the reel's frame 0. (A
	# glob, not `ls | head`: with pipefail, ls dies of SIGPIPE once there are more frames than a pipe holds.)
	shopt -s nullglob
	shot=("$out"/frame*.png)
	shopt -u nullglob
	[[ ${#shot[@]} -gt 0 ]] && rm -f "${shot[0]}"
	rm -f "$out"/frame.wav
fi
frames=$(ls "$out"/frame*.png 2>/dev/null | wc -l)
if [[ "$frames" -lt 30 ]]; then
	echo "reel_render: only $frames frames in $out" >&2
	exit 1
fi
video="assets/reels/$id.ogv"
[[ -n "$full" ]] && video="$out/$id.full.ogv"
filter="null"
[[ "$blur" != "0" ]] && filter="gblur=sigma=$blur"
nice ffmpeg -hide_banner -loglevel error -y -framerate 30 -pattern_type glob -i "$out/frame*.png" -vf "$filter" \
	-c:v libtheora -q:v "$q" -g 60 -pix_fmt yuv420p "$video"
seconds=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video")
bytes=$(stat -c %s "$video")
still_at=$(python3 -c "
import json
d = json.load(open('data/shorts/cinematic/$id.json'))
s = d.get('still')
print(s if s is not None else round(d['scenes'][0]['seconds'] * 0.85, 2))")
if [[ -z "$full" ]]; then
	nice ffmpeg -hide_banner -loglevel error -y -ss "$still_at" -i "$video" -frames:v 1 -vf scale=360:640 -q:v 3 \
		"assets/reels/$id.jpg"
fi
cells=$(python3 -c "import math; print(math.ceil(float('$seconds') * 2))")
rows=$(( (cells + 11) / 12 ))
nice ffmpeg -hide_banner -loglevel error -y -i "$video" -vf "fps=2,scale=180:320,tile=12x${rows}" -frames:v 1 \
	"$out/${id}_video_sheet.png"
luma=()
for f in 0.25 0.5 0.75; do
	at=$(python3 -c "print(float('$seconds') * $f)")
	y=$(nice ffmpeg -hide_banner -ss "$at" -i "$video" -frames:v 1 -vf signalstats,metadata=print:key=lavfi.signalstats.YAVG \
		-f null - 2>&1 | grep -oE "YAVG=[0-9.]+" | head -1 | cut -d= -f2)
	luma+=("${y:-0}")
done
[[ -z "$keep" ]] && rm -f "$out"/frame*.png
if [[ -z "$full" ]]; then
	python3 - "$id" "$bytes" "$seconds" "$w" "$h" "$q" "$blur" "${luma[@]}" <<'PY'
import json, os, sys, datetime
rid, size, secs, w, h, q, blur = sys.argv[1], int(sys.argv[2]), float(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), \
    int(sys.argv[6]), float(sys.argv[7])
luma = [round(float(x), 1) for x in sys.argv[8:11]]
path = "assets/reels/reels.json"
data = json.load(open(path)) if os.path.exists(path) else {}
data[rid] = {"bytes": size, "seconds": round(secs, 2), "size": [w, h], "quality": q, "blur": blur, "luma": luma,
    "rendered": datetime.date.today().isoformat()}
json.dump(dict(sorted(data.items())), open(path, "w"), indent="\t")
PY
fi
echo "reel_render: $video $(( bytes / 1024 )) KiB, ${seconds} s, luma ${luma[*]}"
echo "reel_render: sheet $out/${id}_video_sheet.png"
