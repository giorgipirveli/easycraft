#!/usr/bin/env bash
# The browser version on GitHub Pages too (the owner's choice, 2026-09-28): https://giorgipirveli.github.io/easycraft/
#
#   tools/export_web.sh && tools/deploy_web_github.sh
#
# The repository giorgipirveli/easycraft (public: free Pages needs it) holds ONLY the exported web files, never the
# game's source. Its gh-pages branch is replaced by one fresh commit each time (no history of big files). GitHub Pages
# cannot send the thread headers (COOP/COEP): the page's service worker adds them and reloads once on the first visit
# (Godot's "ensure cross-origin isolation headers", web/shell.html). GitHub does not serve our .br/.gz files, so they
# stay out; a first visit there downloads more than from our own server. Needs `gh auth login` (the owner's account).
set -euo pipefail

GAME="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$GAME/build/web"
REPO="${EASYCRAFT_GH_REPO:-giorgipirveli/easycraft}"

[[ -f "$SRC/index.html" && -f "$SRC/packs.json" ]] || { echo "no web export in $SRC (tools/export_web.sh first)" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "not logged in to GitHub: gh auth login" >&2; exit 1; }

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
cp -a "$SRC/." "$stage/"
rm -f "$stage"/*.br "$stage"/*.gz
python3 "$GAME/tools/web_finish.py" "$stage"
touch "$stage/.nojekyll"
cat > "$stage/README.md" <<'EOF'
# EasyCraft — play in your browser

This repository only hosts the web version of EasyCraft for GitHub Pages: https://giorgipirveli.github.io/easycraft/
(the game's source is not here). Privacy policy: https://178-104-20-64.sslip.io/privacy
EOF

gh repo view "$REPO" >/dev/null 2>&1 || gh repo create "$REPO" --public \
	--description "EasyCraft: play in your browser (web build only)" --homepage "https://${REPO%%/*}.github.io/${REPO##*/}/"
gh auth setup-git >/dev/null 2>&1 || true

git -C "$stage" init -q -b gh-pages
git -C "$stage" add -A
git -C "$stage" -c user.name="EasyCraft deploy" -c user.email="noreply@users.noreply.github.com" commit -qm "EasyCraft web build $(date -Is)"
git -C "$stage" push -q -f "https://github.com/$REPO.git" gh-pages

# Turn Pages on (first time) from the gh-pages branch.
gh api "repos/$REPO/pages" >/dev/null 2>&1 || gh api -X POST "repos/$REPO/pages" -f "source[branch]=gh-pages" -f "source[path]=/" >/dev/null
echo "WEB_GITHUB pushed to $REPO gh-pages: https://${REPO%%/*}.github.io/${REPO##*/}/"
