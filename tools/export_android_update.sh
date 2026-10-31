#!/usr/bin/env bash
# Owner #123: the Android apps follow the web (docs/devlog/parts/same-version.md; DEVELOPMENT.md "The Android apps
# follow the web"). From the commit the web is deployed from:
#
#   tools/export_android_update.sh [--kind phone|quest|all] [--dry-run]
#       every deploy: the newest game's whole pack for each kind (build/android/update/<kind>/game.pck), a patch against
#       each kept base (<kind>-<base>-<game>.pck, ETC2 and each app's features: the phone's "Android Phone" preset, the
#       Quest's "Quest"), the patch's check (a change it cannot carry says "NEEDS A NEW APK/AAB" and that base gets
#       none), and the signed manifest update.json. Then tools/deploy_android_update.sh puts them on the server.
#   tools/export_android_update.sh base <phone|quest> [<APK or pack>] [--dry-run]
#       when an APK/AAB with the updater goes out (the Play AAB, a phone APK, the Quest APK): keep that build as a base
#       (build/android/bases/<kind>/<commit>/). Give the APK itself (exact; the Play AAB's files are the phone APK's of
#       the same commit), or nothing: this commit's pack is exported (it must be the commit and build_info.json the APK
#       was exported with: run it before `tools/write_build_info.py --clean`).
#
# --dry-run prints what it would do (the bases it found, each export) and changes nothing. Places: EASYCRAFT_UPDATE_OUT
# (build/android/update), EASYCRAFT_UPDATE_BASES (build/android/bases), EASYCRAFT_UPDATE_KEY
# (~/.config/easycraft/update-signing.pem, made once by `python3 tools/android_update.py keygen`).
set -euo pipefail

GAME="$(cd "$(dirname "$0")/.." && pwd)"
cd "$GAME"
OUT="${EASYCRAFT_UPDATE_OUT:-$GAME/build/android/update}"
BASES="${EASYCRAFT_UPDATE_BASES:-$GAME/build/android/bases}"
KEY="${EASYCRAFT_UPDATE_KEY:-$HOME/.config/easycraft/update-signing.pem}"
GODOT="${GODOT:-godot}"
export JAVA_HOME="${JAVA_HOME:-$HOME/.local/jdk17}" ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
PY=(/usr/bin/python3 -B "$GAME/tools/android_update.py")

DRY=0
KINDS=(phone quest)
MODE=patches
BASE_KIND=""
BASE_FILE=""
args=("$@")
i=0
while (( i < ${#args[@]} )); do
	a="${args[$i]}"
	case "$a" in
		--dry-run) DRY=1 ;;
		--kind) i=$((i + 1)); k="${args[$i]:-}"; [[ "$k" == all ]] && KINDS=(phone quest) || KINDS=("$k") ;;
		base) MODE=base; i=$((i + 1)); BASE_KIND="${args[$i]:-}"
			if [[ -n "${args[$((i + 1))]:-}" && "${args[$((i + 1))]}" != --* ]]; then i=$((i + 1)); BASE_FILE="${args[$i]}"; fi ;;
		*) echo "unknown argument: $a" >&2; exit 2 ;;
	esac
	i=$((i + 1))
done

preset() { case "$1" in phone) echo "Android Phone" ;; quest) echo "Quest" ;; *) echo "no such kind: $1" >&2; exit 2 ;; esac; }
say() { echo "ANDROID_UPDATE $*"; }
run() { if (( DRY )); then say "would run: $*"; else "$@"; fi; }

ENGINE="$("$GODOT" --version | cut -d. -f1-4)"
COMMIT="$(git rev-parse --short=8 HEAD)"
say "commit $COMMIT, engine $ENGINE, out $OUT, bases $BASES$( (( DRY )) && echo ', DRY RUN: nothing changes')"

# The build's commit, date and online fingerprint (BuildInfo), as every export writes them; kept when it is this
# commit's already (the APK just exported carries that very file), and cleaned at the end only when written here.
wrote_info=0
info_commit="$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("commit",""))' data/build_info.json 2>/dev/null || true)"
if [[ "$info_commit" != "$COMMIT" ]]; then
	run /usr/bin/python3 tools/write_build_info.py
	wrote_info=1
fi
cleanup() { if (( wrote_info && ! DRY )); then /usr/bin/python3 tools/write_build_info.py --clean; fi; }
trap cleanup EXIT

godot_export() {   # what, out, export arguments...: the export's output goes to <out>.log
	local out="$2"
	shift 2
	if (( DRY )); then
		say "would run: nice $GODOT --headless --path . $*"
		return 0
	fi
	nice "$GODOT" --headless --path . "$@" >"$out.log" 2>&1 || {
		tail -5 "$out.log" >&2; echo "the export of $out failed (log: $out.log)" >&2; exit 1; }
}
export_pack() {   # preset, out
	godot_export pack "$2" --export-pack "$1" "$2"
}

if [[ "$MODE" == base ]]; then
	p="$(preset "$BASE_KIND")"
	if [[ -z "$BASE_FILE" ]]; then
		(( DRY )) || mkdir -p "$OUT/$BASE_KIND"
		BASE_FILE="$OUT/$BASE_KIND/base-$COMMIT.pck"
		export_pack "$p" "$BASE_FILE"
	fi
	run "${PY[@]}" base "$BASE_KIND" "$BASE_FILE" --bases "$BASES" --engine "$ENGINE"
	exit 0
fi

[[ -f "$KEY" ]] || { echo "no signing key $KEY: python3 tools/android_update.py keygen (once, on the deploying PC)" >&2; exit 1; }
for kind in "${KINDS[@]}"; do
	p="$(preset "$kind")"
	dest="$OUT/$kind"
	if (( ! DRY )); then rm -rf "$dest"; mkdir -p "$dest"; fi
	say "$kind: the newest game ($p) -> $dest/game.pck"
	export_pack "$p" "$dest/game.pck"
	found=0
	while IFS=$'\t' read -r b_commit b_version b_engine b_path; do
		[[ -n "$b_commit" ]] || continue
		found=$((found + 1))
		if [[ "$b_engine" != "$ENGINE" ]]; then
			say "$kind: base $b_commit (v$b_version) has engine $b_engine: no patch (that app keeps its own game)"
			continue
		fi
		if [[ "${b_commit:0:8}" == "$COMMIT" ]]; then
			say "$kind: base $b_commit is this commit: it already runs the newest game"
			continue
		fi
		patch="$dest/$kind-${b_commit:0:8}-$COMMIT.pck"
		say "$kind: base $b_commit (v$b_version) -> $(basename "$patch")"
		godot_export patch "$patch" --export-patch "$p" "$patch" --patches "$b_path"
		if (( ! DRY )); then
			if ! "${PY[@]}" check "$kind" "$b_path" "$dest/game.pck" "$patch"; then
				say "$kind: base $b_commit NEEDS A NEW APK/AAB (above): no patch for it; online play's check tells it to update"
				rm -f "$patch"
			else
				say "$kind: $(basename "$patch") $(stat -c %s "$patch") bytes"
			fi
		fi
	done < <("${PY[@]}" bases "$kind" --bases "$BASES")
	(( found )) || say "$kind: no bases kept yet (tools/export_android_update.sh base $kind, when an APK/AAB with the updater goes out)"
	run "${PY[@]}" manifest "$kind" "$dest/game.pck" "$dest" --bases "$BASES" --key "$KEY" --engine "$ENGINE"
done
say "done: tools/deploy_android_update.sh puts build/android/update/*/ on the server"
