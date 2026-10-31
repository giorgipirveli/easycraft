#!/usr/bin/env bash
# Installs the official Nakama client for Godot 4 (Heroic Labs, nakama-godot, Apache-2.0) into
# addons/com.heroiclabs.nakama/ at a pinned commit, unmodified. Only the GDScript Nakama client is
# kept: the C# adapters (dotnet-utils/, need Godot .NET) and the Satori LiveOps client are left out.
# Why this commit and not the v3.4.0 release: docs/devlog/parts/m4-online-spike.md.
set -euo pipefail
COMMIT=6dc7b3951d98cc3807cafb3f1dbc9b44d9b98d21   # master, 2026-09-21
builtin cd "$(dirname "$0")/.."
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -sSfL "https://codeload.github.com/heroiclabs/nakama-godot/tar.gz/$COMMIT" | tar -xz -C "$tmp"
src="$tmp/nakama-godot-$COMMIT"
dest=addons/com.heroiclabs.nakama
rm -rf "$dest"
cp -r "$src/addons/com.heroiclabs.nakama" "$dest"
rm -rf "$dest/dotnet-utils" "$dest/Satori" "$dest/Satori.gd" "$dest/Satori.gd.uid"
cp "$src/LICENSE" "$dest/LICENSE"
cat > "$dest/SOURCE.md" <<EOF
# Nakama client for Godot 4

Official client by Heroic Labs: https://github.com/heroiclabs/nakama-godot (Apache License 2.0, see
LICENSE). Installed by \`tools/fetch_nakama_godot.sh\` from commit $COMMIT, unmodified.
Left out: \`dotnet-utils/\` (C# adapters, need Godot .NET) and the Satori LiveOps client.
EasyCraft uses it from \`net/nakama_link.gd\` only (no autoload).
EOF
echo "nakama-godot $COMMIT installed in $dest"
