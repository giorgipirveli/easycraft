#!/usr/bin/env bash
# Builds Voxel Tools for the browser (M7, spec §20.2): the same source as our 1.7 binaries (tag v1.7x, godot-cpp master of
# 2026-08-20), compiled with Emscripten 4.0.20 (the version Godot 4.7.2's web templates were built with) as a side module
# for Godot's "dlink" web templates. Its authors ship no web build.
#
#   tools/build_voxel_web.sh            # threads (the one the "Web" preset uses)
#   THREADS=no tools/build_voxel_web.sh # the no-threads variant
#
# Needs (see docs/DEVELOPMENT.md "Web"): ~/src/emsdk (4.0.20 active), ~/src/sconsenv (SCons), ~/src/godot-cpp,
# ~/src/godot_voxel. Copies the result into addons/zylann.voxel/bin/.
set -euo pipefail

SRC="${EASYCRAFT_SRC:-$HOME/src}"
THREADS="${THREADS:-yes}"
JOBS="${JOBS:-12}"
GAME="$(cd "$(dirname "$0")/.." && pwd)"
VOXEL_TAG="v1.7x"
GODOT_CPP_BEFORE="2026-08-20T22:00:00Z"
EM_VERSION="4.0.20"

# shellcheck disable=SC1091
source "$SRC/emsdk/emsdk_env.sh" >/dev/null 2>&1
if ! emcc --version | head -1 | grep -q " $EM_VERSION "; then
	echo "emcc is not $EM_VERSION: cd $SRC/emsdk && ./emsdk install $EM_VERSION && ./emsdk activate $EM_VERSION" >&2
	exit 1
fi

git -C "$SRC/godot_voxel" describe --tags --exact-match 2>/dev/null | grep -qx "$VOXEL_TAG" \
	|| git -C "$SRC/godot_voxel" rev-parse HEAD | grep -q "^75d3c6d" \
	|| { echo "godot_voxel is not at $VOXEL_TAG" >&2; exit 1; }
want_cpp="$(git -C "$SRC/godot-cpp" rev-list -n1 --before="$GODOT_CPP_BEFORE" master)"
[[ "$(git -C "$SRC/godot-cpp" rev-parse HEAD)" == "$want_cpp" ]] || { echo "godot-cpp is not at $want_cpp" >&2; exit 1; }

suffix="threads"
[[ "$THREADS" == "yes" ]] || suffix="nothreads"
cd "$SRC/godot_voxel"
GODOT_CPP_PATH="$SRC/godot-cpp" nice -n 15 "$SRC/sconsenv/bin/scons" -j"$JOBS" \
	platform=web arch=wasm32 target=template_release threads="$THREADS" precision=single dev_build=no \
	use_static_cpp=yes voxel_tests=no

# SCons links into the source's demo project: project/addons/zylann.voxel/bin/.
built="$(find project/addons/zylann.voxel/bin -name 'libvoxel.web.template_release.wasm32*.wasm' -newer SConstruct \
	-printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2)"
[[ -n "$built" ]] || { echo "no .wasm found under $SRC/godot_voxel/bin" >&2; exit 1; }
out="$GAME/addons/zylann.voxel/bin/libvoxel.web.template_release.wasm32.$suffix.wasm"
cp "$built" "$out"
echo "VOXEL_WEB $out $(stat -c %s "$out") bytes sha256 $(sha256sum "$out" | cut -c1-16)"
